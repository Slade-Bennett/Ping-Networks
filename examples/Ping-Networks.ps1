<#
.SYNOPSIS
    Pings a list of networks from an Excel file and exports the results to a new Excel file using COM automation.
.DESCRIPTION
    This script reads network information (IP, SubnetMask) from an Excel file, calculates the usable IP addresses for each network,
    pings those addresses in parallel to check for reachability, and resolves their hostnames. The results are then exported to a
    new Excel file, with a separate worksheet for each network and a summary worksheet.
.PARAMETER InputPath
    The path to the input Excel file containing the network data. The file should have three columns: 'IP', 'SubnetMask', and 'CIDR'.
.PARAMETER OutputPath
    The path to the output Excel file where the ping results will be saved.
.PARAMETER CsvPath
    (Optional) The path to the output CSV file where the ping results will be saved.
.PARAMETER MaxPings
    (Optional) The maximum number of hosts to ping per network. If not specified, all usable hosts will be pinged.
.PARAMETER Timeout
    (Optional) The timeout in seconds for each ping. The default is 1 second.
.PARAMETER Retries
    (Optional) The number of retries for each ping. The default is 0.
.EXAMPLE
    .\Ping-Networks.ps1 -InputPath 'C:\path\to\NetworkData.xlsx' -OutputPath 'C:\path\to\PingResults.xlsx'
.EXAMPLE
    .\Ping-Networks.ps1 -InputPath 'C:\path\to\NetworkData.xlsx' -OutputPath 'C:\path\to\PingResults.xlsx' -MaxPings 10
#>
[CmdletBinding(DefaultParameterSetName = 'Default')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'Process')]
    [string]$InputPath,

    [Parameter(Mandatory = $false, ParameterSetName = 'Process')]
    [string]$OutputPath,

    [Parameter(Mandatory = $false, ParameterSetName = 'Process')]
    [string]$CsvPath,

    [Parameter(Mandatory = $false, ParameterSetName = 'Process')]
    [int]$MaxPings,

    [Parameter(Mandatory = $false, ParameterSetName = 'Process')]
    [int]$Timeout = 1,

    [Parameter(Mandatory = $false, ParameterSetName = 'Process')]
    [int]$Retries = 0
)

if ($PSCmdlet.ParameterSetName -eq 'Default') {
    Write-Host @"
DESCRIPTION:
This script reads network information (IP, SubnetMask) from an Excel file, 
calculates the usable IP addresses for each network, pings those addresses 
in parallel to check for reachability, and resolves their hostnames. 
The results are then exported to a new Excel file, with a separate 
worksheet for each network and a summary worksheet.

PARAMETERS:
-InputPath      (Required) The path to the input Excel file containing the network data. 
                The file should have three columns: 'IP', 'SubnetMask', and 'CIDR'.
-OutputPath     (Optional) The path to the output Excel file where the ping results will be saved.
                Defaults to a timestamped file in the user's Documents folder.
-CsvPath        (Optional) The path to the output CSV file where the ping results will be saved.
-MaxPings       (Optional) The maximum number of hosts to ping per network. 
                If not specified, all usable hosts will be pinged.
-Timeout        (Optional) The timeout in seconds for each ping. Default is 1 second.
-Retries        (Optional) The number of retries for each ping. Default is 0.

EXAMPLE:
.\Ping-Networks.ps1 -InputPath 'C:\path\to\NetworkData.xlsx'
.\Ping-Networks.ps1 -InputPath 'C:\path\to\NetworkData.xlsx' -OutputPath 'C:\path\to\PingResults.xlsx' -CsvPath 'C:\path\to\PingResults.csv'
.\Ping-Networks.ps1 -InputPath 'C:\path\to\NetworkData.xlsx' -OutputPath 'C:\path\to\PingResults.xlsx' -MaxPings 10 -Timeout 2 -Retries 1
"@
    return
}

#region INITIALIZATION

# Import our custom functions
Import-Module (Join-Path $PSScriptRoot "..\Ping-Networks\ExcelUtils.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "..\Ping-Networks\Ping-Networks.psm1") -Force

# Get common variables for default paths
$documentsPath = [Environment]::GetFolderPath('MyDocuments')
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# Handle default OutputPath if not provided
if (-not $PSBoundParameters.ContainsKey('OutputPath')) {
    $OutputPath = Join-Path -Path $documentsPath -ChildPath "PingResults_$timestamp.xlsx"
}

# CsvPath is only used if explicitly provided; no default generation.

# Ensure absolute paths for the output files
if ($OutputPath) { # Check if OutputPath is set before processing
    $OutputPath = [System.IO.Path]::GetFullPath($OutputPath)
}
if ($CsvPath) { # Check if CsvPath is set before processing
    $CsvPath = [System.IO.Path]::GetFullPath($CsvPath)
}

#endregion

#region MAIN PROCESSING

$excel = $null
$inputWorkbook = $null
$outputWorkbook = $null
try {
    $excel = New-ExcelSession
    if (-not $excel) {
        throw "Failed to start Excel."
    }

    $inputWorkbook = Get-ExcelWorkbook -Path (Resolve-Path -Path $InputPath) -Excel $excel
    if (-not $inputWorkbook) {
        throw "Failed to open input workbook '$InputPath'."
    }
    
    $networks = Read-ExcelSheet -Workbook $inputWorkbook
    if (-not $networks) {
        throw "Failed to read networks from '$InputPath'."
    }

    $allResults = [System.Collections.Generic.List[pscustomobject]]::new()
    $summaryData = [System.Collections.Generic.List[pscustomobject]]::new()

    $networkCount = $networks.Count
    $networkIndex = 0

    foreach ($network in $networks) {
        $networkIndex++
        $networkIdentifier = "$($network.IP)/$($network.CIDR)"
        Write-Progress -Activity "Processing Networks" -Status "Processing network $networkIndex of $networkCount : $networkIdentifier" -PercentComplete (($networkIndex / $networkCount) * 100)

        # Validate network parameters before processing
        if ([string]::IsNullOrEmpty($network.IP) -or [string]::IsNullOrEmpty($network.SubnetMask) -or [string]::IsNullOrEmpty($network.CIDR)) {
            Write-Warning "Skipping network entry due to missing or empty IP, SubnetMask, or CIDR for network '$($network.IP)/$($network.CIDR)'."
            continue
        }

        # Get usable hosts
        $usableHosts = Get-UsableHosts -IP $network.IP -SubnetMask $network.SubnetMask
        if (-not $usableHosts) {
            continue
        }

        $hostsToPing = if ($PSBoundParameters.ContainsKey('MaxPings')) {
            $usableHosts | Select-Object -First $MaxPings
        }
        else {
            $usableHosts
        }

        $pingResults = Start-Ping -Hosts $hostsToPing -Timeout $Timeout -Retries $Retries
        
        $reachableCount = ($pingResults | Where-Object { $_.Reachable }).Count
        $unreachableCount = $hostsToPing.Count - $reachableCount

        $summaryData.Add([PSCustomObject]@{
            Network = $networkIdentifier
            'Total Hosts Scanned' = $hostsToPing.Count
            'Hosts Reachable' = $reachableCount
            'Hosts Unreachable' = $unreachableCount
        })

        # Add network information to each result
        $pingResults | ForEach-Object {
            $_ | Add-Member -MemberType NoteProperty -Name 'Network' -Value $networkIdentifier -Force
            $allResults.Add($_)
        }
    }

    #region EXPORT RESULTS

    if ($allResults.Count -gt 0) {
        if ($OutputPath) {
            try {
                Write-Information "Exporting results to '$OutputPath'..."
                $outputWorkbook = Get-ExcelWorkbook -Path $OutputPath -Excel $excel
                
                # Export the summary
                Write-ExcelSheet -Workbook $outputWorkbook -Data $summaryData -WorksheetName 'Summary'

                # Export the detailed results, grouped by network
                $allResults | Group-Object -Property Network | ForEach-Object {
                    $networkSheetName = $_.Name.Replace('/', '_').Replace('.', '_')
                    Write-ExcelSheet -Workbook $outputWorkbook -Data $_.Group -WorksheetName $networkSheetName
                }
                
                Close-ExcelWorkbook -Workbook $outputWorkbook -Path $OutputPath
                $outputWorkbook = $null # Set to null so we don't release it twice
                Write-Information "Successfully exported results to '$OutputPath'."
            }
            finally {
                if ($outputWorkbook) {
                    $outputWorkbook.Close($false)
                    [System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($outputWorkbook) | Out-Null
                }
            }
        }

        if ($CsvPath) {
            Write-Information "Exporting results to '$CsvPath'..."
            $allResults | Export-Csv -Path $CsvPath -NoTypeInformation
            Write-Information "Successfully exported results to '$CsvPath'."
        }
    }
    else {
        Write-Warning "No results to export."
    }

    #endregion
}
catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
}
finally {
    if ($inputWorkbook) {
        $inputWorkbook.Close($false)
        [System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($inputWorkbook) | Out-Null
    }
    if ($excel) {
        Close-ExcelSession -Excel $excel
    }
}

#endregion