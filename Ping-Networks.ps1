<#
.SYNOPSIS
    Network scanning tool that pings all hosts in specified subnets and exports results to Excel.

.DESCRIPTION
    This script performs comprehensive network scanning by:
    1. Reading network definitions (IP, Subnet Mask, CIDR) from an input Excel file
    2. Calculating ALL usable host addresses in each subnet (supports any CIDR /8 to /30)
    3. Pinging hosts in parallel using PowerShell background jobs
    4. Resolving hostnames for reachable hosts via DNS
    5. Exporting results to Excel with color-coded status and summary statistics

    ARCHITECTURE:
    - Ping-Networks.psm1: Core functions (subnet calculation, parallel ping)
    - ExcelUtils.psm1: Excel COM automation utilities
    - Ping-Networks.ps1: Main orchestration script (this file)

    KEY FEATURES:
    - Supports ANY standard CIDR notation (/24, /28, /16, etc.)
    - Parallel execution for speed (configurable batch size)
    - Separate Excel worksheets per network + summary tab
    - Color-coded status cells (green=reachable, red=unreachable)
    - Hostname resolution for network documentation
.PARAMETER InputPath
    The path to the input Excel file containing the network data. The file should have three columns: 'IP', 'SubnetMask', and 'CIDR'.
.PARAMETER OutputPath
    The path to the output Excel file where the ping results will be saved.
.PARAMETER CsvPath
    (Optional) The path to the output CSV file where the ping results will be saved.
.PARAMETER HtmlPath
    (Optional) The path to the output HTML report file. Creates an interactive web-based report with charts and sortable tables.
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
.EXAMPLE
    .\Ping-Networks.ps1 -InputPath 'C:\path\to\NetworkData.xlsx' -HtmlPath 'C:\path\to\Report.html'
    # Generate an interactive HTML report with charts and sortable tables
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
    [string]$HtmlPath,

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
-HtmlPath       (Optional) The path to the output HTML report. Creates an interactive web report
                with charts, sortable tables, and professional styling.
-MaxPings       (Optional) The maximum number of hosts to ping per network. 
                If not specified, all usable hosts will be pinged.
-Timeout        (Optional) The timeout in seconds for each ping. Default is 1 second.
-Retries        (Optional) The number of retries for each ping. Default is 0.

EXAMPLE:
.\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.xlsx'
.\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.xlsx' -OutputPath 'C:\Temp\PingResults.xlsx'
.\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.xlsx' -HtmlPath 'C:\Temp\Report.html'
.\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.xlsx' -MaxPings 10 -Timeout 2 -Retries 1
"@
    return
}

#region INITIALIZATION

# Import our custom functions
# Set verbose preference for modules if parent script is verbose
if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose')) {
    $VerbosePreference = 'Continue'
}
Import-Module (Join-Path $PSScriptRoot "modules\ExcelUtils.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "modules\Ping-Networks.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "modules\ReportUtils.psm1") -Force

# Track scan timing for metadata
$scanStartTime = Get-Date

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

    Write-Verbose "Read $($networks.Count) network(s) from Excel file"

    $allResults = [System.Collections.Generic.List[pscustomobject]]::new()
    $summaryData = [System.Collections.Generic.List[pscustomobject]]::new()

    $networkCount = $networks.Count
    $networkIndex = 0

    if ($networkCount -eq 0) {
        throw "No networks found in input file. Please ensure the Excel file has data rows."
    }

    foreach ($network in $networks) {
        $networkIndex++
        $networkIdentifier = "$($network.IP)/$($network.CIDR)"
        Write-Verbose "Processing network $networkIndex of $networkCount : $networkIdentifier"

        # Display current network being scanned with enhanced details
        $percentComplete = if ($networkCount -gt 0) { ($networkIndex / $networkCount) * 100 } else { 0 }
        $networkStatus = "Network $networkIndex of $networkCount : $networkIdentifier"
        Write-Progress -Id 1 -Activity "Scanning Networks" -Status $networkStatus -PercentComplete $percentComplete

        # Validate network parameters before processing
        if ([string]::IsNullOrEmpty($network.IP) -or [string]::IsNullOrEmpty($network.'Subnet Mask') -or [string]::IsNullOrEmpty($network.CIDR)) {
            Write-Warning "Skipping network entry due to missing or empty IP, SubnetMask, or CIDR for network '$($network.IP)/$($network.CIDR)'."
            continue
        }

        $usableHosts = Get-UsableHosts -IP $network.IP -SubnetMask $network.'Subnet Mask'
        if (-not $usableHosts) {
            Write-Warning "No usable hosts found for network '$networkIdentifier'. Skipping ping."
            continue
        }

        $hostsToPing = if ($PSBoundParameters.ContainsKey('MaxPings')) {
            $usableHosts | Select-Object -First $MaxPings
        }
        else {
            $usableHosts
        }

        # Validate $hostsToPing before calling Start-Ping
        if (-not $hostsToPing -or $hostsToPing.Count -eq 0) {
            Write-Warning "No hosts selected for ping in network '$networkIdentifier'. Skipping ping."
            continue
        }

        # Ping all hosts in this network
        $pingResults = Start-Ping -Hosts $hostsToPing -Timeout $Timeout -Retries $Retries
        
        $reachableCount = ($pingResults | Where-Object { $_.Reachable }).Count
        $unreachableCount = $hostsToPing.Count - $reachableCount

        $summaryData.Add([PSCustomObject]@{
            Network = $networkIdentifier
            'Total Hosts Scanned' = $hostsToPing.Count
            'Hosts Reachable' = $reachableCount
            'Hosts Unreachable' = $unreachableCount
        })

        # Process ping results
        [System.Management.Automation.PSObject[]]$pingResultsProcessed = $pingResults | ForEach-Object {
            [PSCustomObject]@{
                Network  = $networkIdentifier
                Host     = $_.Host
                Status   = if ($_.Reachable) { "Reachable" } else { "Unreachable" }
                Hostname = $_.Hostname
            }
        }
        $allResults.AddRange($pingResultsProcessed)
    }

    # Clear network scanning progress bar
    Write-Progress -Id 1 -Activity "Scanning Networks" -Completed

    #region EXPORT RESULTS

    if ($allResults.Count -gt 0) {
        if ($OutputPath) {
            try {
                Write-Verbose "Exporting results to '$OutputPath'..."
                $outputWorkbook = Get-ExcelWorkbook -Path $OutputPath -Excel $excel

                # Export the summary
                Write-Verbose "Creating Summary sheet..."
                Write-ExcelSheet -Workbook $outputWorkbook -Data $summaryData -WorksheetName 'Summary' | Out-Null

                # Export the detailed results, grouped by network
                $allResults | Group-Object -Property Network | ForEach-Object {
                    $networkSheetName = $_.Name.Replace('/', '_').Replace('.', '_')
                    Write-Verbose "Creating detail sheet: $networkSheetName"
                    Write-ExcelSheet -Workbook $outputWorkbook -Data $_.Group -WorksheetName $networkSheetName | Out-Null
                }

                # Remove any unused default sheets (Sheet1, Sheet2, etc.)
                Write-Verbose "Cleaning up unused default sheets..."
                $sheetsToDelete = @()
                foreach ($sheet in $outputWorkbook.Sheets) {
                    if ($sheet.Name -match '^Sheet\d+$') {
                        $sheetsToDelete += $sheet
                    }
                }

                foreach ($sheet in $sheetsToDelete) {
                    Write-Verbose "Deleting unused sheet: $($sheet.Name)"
                    $sheet.Delete()
                }

                Close-ExcelWorkbook -Workbook $outputWorkbook -Path $OutputPath
                $outputWorkbook = $null # Set to null so we don't release it twice
                Write-Host "Successfully exported results to: $OutputPath" -ForegroundColor Green
            }
            finally {
                if ($outputWorkbook) {
                    $outputWorkbook.Close($false)
                    [System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($outputWorkbook) | Out-Null
                }
            }
        }

        if ($CsvPath) {
            Write-Verbose "Exporting results to CSV: $CsvPath"
            $allResults | Export-Csv -Path $CsvPath -NoTypeInformation
            Write-Host "Successfully exported results to: $CsvPath" -ForegroundColor Green
        }

        if ($HtmlPath) {
            Write-Verbose "Generating HTML report: $HtmlPath"

            # Calculate scan duration
            $scanEndTime = Get-Date
            $scanDuration = $scanEndTime - $scanStartTime
            $durationFormatted = "{0:D2}:{1:D2}:{2:D2}" -f $scanDuration.Hours, $scanDuration.Minutes, $scanDuration.Seconds

            # Prepare scan metadata
            $metadata = @{
                ScanDate = $scanStartTime.ToString("yyyy-MM-dd HH:mm:ss")
                Duration = $durationFormatted
            }

            # Generate HTML report
            Export-HtmlReport -Results $allResults -OutputPath $HtmlPath -ScanMetadata $metadata
            Write-Host "Successfully generated HTML report: $HtmlPath" -ForegroundColor Green
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