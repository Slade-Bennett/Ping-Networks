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
    The path to the input file containing the network data.
    Supported formats:
    - Excel (.xlsx): Single "Network" column with CIDR/Range notation, or traditional IP/Subnet Mask/CIDR columns
    - CSV (.csv): Same formats as Excel (with header row)
    - Text (.txt): One network per line in CIDR or Range notation (e.g., "10.0.0.0/24" or "192.168.1.1-192.168.1.50")
.PARAMETER OutputDirectory
    (Optional) The directory where output files will be saved. Defaults to the user's Documents folder.
    All output files will use timestamped filenames (e.g., PingResults_20251224_235900.xlsx)
.PARAMETER Excel
    (Optional) Generate Excel output with color-coded results and summary statistics.
.PARAMETER Html
    (Optional) Generate interactive HTML report with charts and sortable tables.
.PARAMETER Json
    (Optional) Generate JSON output for programmatic consumption.
.PARAMETER Xml
    (Optional) Generate XML output for integration with other tools.
.PARAMETER Csv
    (Optional) Generate CSV output for simple tabular data.
.PARAMETER ExcludeIPs
    (Optional) Array of IP addresses to exclude from scanning. Supports individual IPs or ranges.
    Example: -ExcludeIPs "192.168.1.1","192.168.1.100-192.168.1.110"
.PARAMETER OddOnly
    (Optional) Scan only odd IP addresses (e.g., .1, .3, .5). Useful for certain network designs.
.PARAMETER EvenOnly
    (Optional) Scan only even IP addresses (e.g., .2, .4, .6). Useful for certain network designs.
.PARAMETER HistoryPath
    (Optional) Directory path where scan history will be saved as timestamped JSON files.
    If not specified, no history is saved. Example: "C:\ScanHistory"
.PARAMETER CompareBaseline
    (Optional) Path to a previous scan result file (JSON) to compare against current scan.
    Generates a change detection report showing new devices, offline devices, and status changes.
.PARAMETER MaxPings
    (Optional) The maximum number of hosts to ping per network. If not specified, all usable hosts will be pinged.
.PARAMETER Timeout
    (Optional) The timeout in seconds for each ping. The default is 1 second.
.PARAMETER Retries
    (Optional) The number of retries for each ping. The default is 0.
.EXAMPLE
    .\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.xlsx'
    # Basic usage with Excel file - generates Excel output in Documents folder by default
.EXAMPLE
    .\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.csv' -Html
    # Use CSV file input and generate HTML report
.EXAMPLE
    .\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.txt' -Excel -Json
    # Use text file input (one network per line) and generate Excel and JSON reports
.EXAMPLE
    .\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.xlsx' -Excel -Html -Json
    # Generate multiple output formats simultaneously
.EXAMPLE
    .\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.xlsx' -OutputDirectory 'C:\Reports' -Excel -Html
    # Generate Excel and HTML reports in custom directory
.EXAMPLE
    .\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.csv' -Html -MaxPings 20
    # Generate HTML report with maximum 20 hosts per network from CSV input
.EXAMPLE
    .\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.txt' -Html -ExcludeIPs "10.0.0.1","10.0.0.254"
    # Scan networks but exclude gateway and broadcast IPs
.EXAMPLE
    .\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.xlsx' -Html -OddOnly
    # Scan only odd IP addresses (useful for dual-stack networks)
.EXAMPLE
    .\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.csv' -Html -ExcludeIPs "192.168.1.100-192.168.1.110"
    # Exclude an entire range of IPs from scanning
#>
[CmdletBinding(DefaultParameterSetName = 'Default')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'Process')]
    [string]$InputPath,

    [Parameter(Mandatory = $false, ParameterSetName = 'Process')]
    [string]$OutputDirectory,

    [Parameter(Mandatory = $false, ParameterSetName = 'Process')]
    [switch]$Excel,

    [Parameter(Mandatory = $false, ParameterSetName = 'Process')]
    [switch]$Html,

    [Parameter(Mandatory = $false, ParameterSetName = 'Process')]
    [switch]$Json,

    [Parameter(Mandatory = $false, ParameterSetName = 'Process')]
    [switch]$Xml,

    [Parameter(Mandatory = $false, ParameterSetName = 'Process')]
    [switch]$Csv,

    [Parameter(Mandatory = $false, ParameterSetName = 'Process')]
    [string[]]$ExcludeIPs,

    [Parameter(Mandatory = $false, ParameterSetName = 'Process')]
    [switch]$OddOnly,

    [Parameter(Mandatory = $false, ParameterSetName = 'Process')]
    [switch]$EvenOnly,

    [Parameter(Mandatory = $false, ParameterSetName = 'Process')]
    [string]$HistoryPath,

    [Parameter(Mandatory = $false, ParameterSetName = 'Process')]
    [string]$CompareBaseline,

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
-InputPath         (Required) The path to the input file containing network data.
                   Supported formats:
                   • Excel (.xlsx): "Network" column with CIDR/Range, or IP/Subnet Mask/CIDR columns
                   • CSV (.csv): Same as Excel with header row
                   • Text (.txt): One network per line (CIDR or Range format)
-OutputDirectory   (Optional) The directory where output files will be saved.
                   Defaults to the user's Documents folder.
                   All files use timestamped filenames (e.g., PingResults_20251224_235900.xlsx)
-Excel             (Switch) Generate Excel output with color-coded results.
-Html              (Switch) Generate interactive HTML report with charts and tables.
-Json              (Switch) Generate JSON output for programmatic consumption.
-Xml               (Switch) Generate XML output for integration with other tools.
-Csv               (Switch) Generate CSV output for simple tabular data.
-MaxPings          (Optional) The maximum number of hosts to ping per network.
                   If not specified, all usable hosts will be pinged.
-Timeout           (Optional) The timeout in seconds for each ping. Default is 1 second.
-Retries           (Optional) The number of retries for each ping. Default is 0.

EXAMPLES:
.\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.xlsx'
# Basic usage with Excel file - generates Excel in Documents folder by default

.\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.csv' -Html
# Use CSV file input and generate HTML report

.\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.txt' -Excel -Json
# Use text file input (one network per line) and generate Excel/JSON reports

.\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.xlsx' -OutputDirectory 'C:\Reports' -Excel -Html
# Generate Excel and HTML in custom directory

.\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.csv' -Html -MaxPings 20
# Generate HTML report with max 20 hosts per network from CSV
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
$baseFilename = "PingResults_$timestamp"

# Handle default OutputDirectory if not provided
if (-not $PSBoundParameters.ContainsKey('OutputDirectory')) {
    $OutputDirectory = $documentsPath
} else {
    # Ensure absolute path
    $OutputDirectory = [System.IO.Path]::GetFullPath($OutputDirectory)

    # Create directory if it doesn't exist
    if (-not (Test-Path -Path $OutputDirectory)) {
        New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
        Write-Verbose "Created output directory: $OutputDirectory"
    }
}

# If no format switches specified, default to Excel for backward compatibility
if (-not ($Excel -or $Html -or $Json -or $Xml -or $Csv)) {
    $Excel = $true
    Write-Verbose "No output format specified, defaulting to Excel"
}

# Generate full paths for each requested format
$OutputPath = if ($Excel) { Join-Path -Path $OutputDirectory -ChildPath "$baseFilename.xlsx" } else { $null }
$HtmlPath = if ($Html) { Join-Path -Path $OutputDirectory -ChildPath "$baseFilename.html" } else { $null }
$JsonPath = if ($Json) { Join-Path -Path $OutputDirectory -ChildPath "$baseFilename.json" } else { $null }
$XmlPath = if ($Xml) { Join-Path -Path $OutputDirectory -ChildPath "$baseFilename.xml" } else { $null }
$CsvPath = if ($Csv) { Join-Path -Path $OutputDirectory -ChildPath "$baseFilename.csv" } else { $null }

# Load baseline data if comparison requested
$baselineData = $null
if ($CompareBaseline) {
    try {
        if (-not (Test-Path -Path $CompareBaseline)) {
            Write-Warning "Baseline file not found: $CompareBaseline. Comparison will be skipped."
        } else {
            Write-Verbose "Loading baseline data from: $CompareBaseline"
            $baselineJson = Get-Content -Path $CompareBaseline -Raw -Encoding UTF8
            $baselineData = $baselineJson | ConvertFrom-Json
            Write-Verbose "Baseline loaded: $($baselineData.Results.Count) hosts from scan on $($baselineData.ScanMetadata.ScanDate)"
        }
    }
    catch {
        Write-Warning "Failed to load baseline file: $($_.Exception.Message). Comparison will be skipped."
        $baselineData = $null
    }
}

#endregion

#region MAIN PROCESSING

$excelApp = $null
$inputWorkbook = $null
$outputWorkbook = $null
try {
    # Detect input file type and read networks accordingly
    $inputExtension = [System.IO.Path]::GetExtension($InputPath).ToLower()

    switch ($inputExtension) {
        '.xlsx' {
            # Excel file input
            $excelApp = New-ExcelSession
            if (-not $excelApp) {
                throw "Failed to start Excel."
            }

            $inputWorkbook = Get-ExcelWorkbook -Path (Resolve-Path -Path $InputPath) -Excel $excelApp
            if (-not $inputWorkbook) {
                throw "Failed to open input workbook '$InputPath'."
            }

            $networks = Read-ExcelSheet -Workbook $inputWorkbook
            if (-not $networks) {
                throw "Failed to read networks from '$InputPath'."
            }
        }
        '.csv' {
            # CSV file input
            Write-Verbose "Reading networks from CSV file: $InputPath"
            $networks = Import-Csv -Path $InputPath
            if (-not $networks) {
                throw "Failed to read networks from CSV file '$InputPath'."
            }
        }
        '.txt' {
            # Text file input (one network per line)
            Write-Verbose "Reading networks from text file: $InputPath"
            $networkLines = Get-Content -Path $InputPath | Where-Object { $_ -match '\S' }  # Filter out empty lines
            if (-not $networkLines) {
                throw "Failed to read networks from text file '$InputPath'."
            }

            # Convert text lines to objects with Network property
            $networks = $networkLines | ForEach-Object {
                [PSCustomObject]@{ Network = $_.Trim() }
            }
        }
        default {
            throw "Unsupported input file format: '$inputExtension'. Supported formats: .xlsx, .csv, .txt"
        }
    }

    Write-Verbose "Read $($networks.Count) network(s) from input file ($inputExtension)"

    $allResults = [System.Collections.Generic.List[pscustomobject]]::new()
    $summaryData = [System.Collections.Generic.List[pscustomobject]]::new()

    $networkCount = $networks.Count
    $networkIndex = 0

    if ($networkCount -eq 0) {
        throw "No networks found in input file. Please ensure the Excel file has data rows."
    }

    foreach ($networkInput in $networks) {
        $networkIndex++

        # Parse and normalize network input (supports CIDR, ranges, traditional format)
        $network = Parse-NetworkInput -NetworkInput $networkInput
        if (-not $network) {
            Write-Warning "Skipping network entry $networkIndex due to invalid format."
            continue
        }

        # Create network identifier for display
        $networkIdentifier = if ($network.Format -eq "Range") {
            "$($network.Range[0])-$($network.Range[1])"
        } elseif ($network.CIDR) {
            "$($network.IP)/$($network.CIDR)"
        } else {
            "$($network.IP)"
        }

        Write-Verbose "Processing network $networkIndex of $networkCount : $networkIdentifier (Format: $($network.Format))"

        # Display current network being scanned with enhanced details
        $percentComplete = if ($networkCount -gt 0) { ($networkIndex / $networkCount) * 100 } else { 0 }
        $networkStatus = "Network $networkIndex of $networkCount : $networkIdentifier"
        Write-Progress -Id 1 -Activity "Scanning Networks" -Status $networkStatus -PercentComplete $percentComplete

        # Get list of hosts to ping based on format
        $usableHosts = if ($network.Format -eq "Range") {
            # IP Range format: generate all IPs between start and end
            Get-IPRange -StartIP $network.Range[0] -EndIP $network.Range[1]
        } else {
            # CIDR or Traditional format: calculate from subnet
            Get-UsableHosts -IP $network.IP -SubnetMask $network.SubnetMask
        }

        if (-not $usableHosts) {
            Write-Warning "No usable hosts found for network '$networkIdentifier'. Skipping ping."
            continue
        }

        # Apply filtering options
        $filteredHosts = $usableHosts

        # Filter: Exclude specific IPs
        if ($ExcludeIPs) {
            $excludeList = @()
            foreach ($exclude in $ExcludeIPs) {
                if ($exclude -match '^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})-(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})$') {
                    # IP range to exclude
                    $excludeRange = Get-IPRange -StartIP $matches[1] -EndIP $matches[2]
                    $excludeList += $excludeRange
                } else {
                    # Single IP to exclude
                    $excludeList += $exclude
                }
            }
            $filteredHosts = $filteredHosts | Where-Object { $_ -notin $excludeList }
            Write-Verbose "Excluded $($excludeList.Count) IP(s). Remaining: $($filteredHosts.Count)"
        }

        # Filter: Odd IPs only
        if ($OddOnly) {
            $filteredHosts = $filteredHosts | Where-Object {
                $lastOctet = ([System.Net.IPAddress]$_).GetAddressBytes()[3]
                ($lastOctet % 2) -eq 1
            }
            Write-Verbose "Filtered to odd IPs only. Remaining: $($filteredHosts.Count)"
        }

        # Filter: Even IPs only
        if ($EvenOnly) {
            $filteredHosts = $filteredHosts | Where-Object {
                $lastOctet = ([System.Net.IPAddress]$_).GetAddressBytes()[3]
                ($lastOctet % 2) -eq 0
            }
            Write-Verbose "Filtered to even IPs only. Remaining: $($filteredHosts.Count)"
        }

        $hostsToPing = if ($PSBoundParameters.ContainsKey('MaxPings')) {
            $filteredHosts | Select-Object -First $MaxPings
        }
        else {
            $filteredHosts
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

    #region BASELINE COMPARISON

    $changeReport = $null
    if ($baselineData) {
        Write-Verbose "Performing baseline comparison..."

        # Create lookup dictionaries for fast comparison
        $baselineHosts = @{}
        foreach ($result in $baselineData.Results) {
            $key = "$($result.Network)|$($result.Host)"
            $baselineHosts[$key] = $result
        }

        $currentHosts = @{}
        foreach ($result in $allResults) {
            $key = "$($result.Network)|$($result.Host)"
            $currentHosts[$key] = $result
        }

        # Identify changes
        $newDevices = [System.Collections.Generic.List[pscustomobject]]::new()
        $offlineDevices = [System.Collections.Generic.List[pscustomobject]]::new()
        $recoveredDevices = [System.Collections.Generic.List[pscustomobject]]::new()
        $statusChanged = [System.Collections.Generic.List[pscustomobject]]::new()

        # Find new devices (in current scan but not in baseline)
        foreach ($key in $currentHosts.Keys) {
            if (-not $baselineHosts.ContainsKey($key)) {
                $newDevices.Add($currentHosts[$key])
            }
        }

        # Find offline/recovered/changed devices
        foreach ($key in $baselineHosts.Keys) {
            $baselineHost = $baselineHosts[$key]

            if (-not $currentHosts.ContainsKey($key)) {
                # Device was in baseline but not scanned this time (network may have been excluded)
                continue
            }

            $currentHost = $currentHosts[$key]

            # Check for status changes
            if ($baselineHost.Status -ne $currentHost.Status) {
                if ($baselineHost.Status -eq "Reachable" -and $currentHost.Status -eq "Unreachable") {
                    # Device went offline
                    $offlineDevices.Add([PSCustomObject]@{
                        Network = $currentHost.Network
                        Host = $currentHost.Host
                        PreviousStatus = $baselineHost.Status
                        CurrentStatus = $currentHost.Status
                        PreviousHostname = $baselineHost.Hostname
                    })
                }
                elseif ($baselineHost.Status -eq "Unreachable" -and $currentHost.Status -eq "Reachable") {
                    # Device came back online
                    $recoveredDevices.Add([PSCustomObject]@{
                        Network = $currentHost.Network
                        Host = $currentHost.Host
                        PreviousStatus = $baselineHost.Status
                        CurrentStatus = $currentHost.Status
                        CurrentHostname = $currentHost.Hostname
                    })
                }
            }
        }

        # Create change report
        $changeReport = [PSCustomObject]@{
            ComparisonMetadata = @{
                BaselineScanDate = $baselineData.ScanMetadata.ScanDate
                CurrentScanDate = $scanStartTime.ToString("yyyy-MM-dd HH:mm:ss")
                BaselineTotalHosts = $baselineData.Results.Count
                CurrentTotalHosts = $allResults.Count
            }
            Summary = @{
                NewDevices = $newDevices.Count
                OfflineDevices = $offlineDevices.Count
                RecoveredDevices = $recoveredDevices.Count
            }
            NewDevices = $newDevices
            OfflineDevices = $offlineDevices
            RecoveredDevices = $recoveredDevices
        }

        # Display change summary
        Write-Host "`n=== Baseline Comparison Summary ===" -ForegroundColor Cyan
        Write-Host "Baseline scan: $($baselineData.ScanMetadata.ScanDate)" -ForegroundColor Gray
        Write-Host "New devices detected: $($newDevices.Count)" -ForegroundColor $(if ($newDevices.Count -gt 0) { "Yellow" } else { "Gray" })
        Write-Host "Devices now offline: $($offlineDevices.Count)" -ForegroundColor $(if ($offlineDevices.Count -gt 0) { "Red" } else { "Gray" })
        Write-Host "Devices recovered: $($recoveredDevices.Count)" -ForegroundColor $(if ($recoveredDevices.Count -gt 0) { "Green" } else { "Gray" })
        Write-Host "==================================`n" -ForegroundColor Cyan
    }

    #endregion

    #region EXPORT RESULTS

    if ($allResults.Count -gt 0) {
        if ($OutputPath) {
            try {
                # Initialize Excel if needed for output (in case input was CSV/TXT)
                if (-not $excelApp) {
                    $excelApp = New-ExcelSession
                    if (-not $excelApp) {
                        throw "Failed to start Excel for output."
                    }
                }

                Write-Verbose "Exporting results to '$OutputPath'..."
                $outputWorkbook = Get-ExcelWorkbook -Path $OutputPath -Excel $excelApp

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

        if ($JsonPath) {
            Write-Verbose "Generating JSON report: $JsonPath"

            # Calculate scan duration
            $scanEndTime = Get-Date
            $scanDuration = $scanEndTime - $scanStartTime
            $durationFormatted = "{0:D2}:{1:D2}:{2:D2}" -f $scanDuration.Hours, $scanDuration.Minutes, $scanDuration.Seconds

            # Prepare scan metadata
            $metadata = @{
                ScanDate = $scanStartTime.ToString("yyyy-MM-dd HH:mm:ss")
                Duration = $durationFormatted
            }

            # Generate JSON report
            Export-JsonReport -Results $allResults -OutputPath $JsonPath -ScanMetadata $metadata
            Write-Host "Successfully generated JSON report: $JsonPath" -ForegroundColor Green
        }

        if ($XmlPath) {
            Write-Verbose "Generating XML report: $XmlPath"

            # Calculate scan duration
            $scanEndTime = Get-Date
            $scanDuration = $scanEndTime - $scanStartTime
            $durationFormatted = "{0:D2}:{1:D2}:{2:D2}" -f $scanDuration.Hours, $scanDuration.Minutes, $scanDuration.Seconds

            # Prepare scan metadata
            $metadata = @{
                ScanDate = $scanStartTime.ToString("yyyy-MM-dd HH:mm:ss")
                Duration = $durationFormatted
            }

            # Generate XML report
            Export-XmlReport -Results $allResults -OutputPath $XmlPath -ScanMetadata $metadata
            Write-Host "Successfully generated XML report: $XmlPath" -ForegroundColor Green
        }

        # Save scan history if HistoryPath is specified
        if ($HistoryPath) {
            try {
                Write-Verbose "Saving scan history to: $HistoryPath"

                # Ensure history directory exists
                if (-not (Test-Path -Path $HistoryPath)) {
                    New-Item -Path $HistoryPath -ItemType Directory -Force | Out-Null
                    Write-Verbose "Created history directory: $HistoryPath"
                }

                # Calculate scan duration
                $scanEndTime = Get-Date
                $scanDuration = $scanEndTime - $scanStartTime
                $durationFormatted = "{0:D2}:{1:D2}:{2:D2}" -f $scanDuration.Hours, $scanDuration.Minutes, $scanDuration.Seconds

                # Create history data structure
                $historyData = @{
                    ScanMetadata = @{
                        ScanDate = $scanStartTime.ToString("yyyy-MM-dd HH:mm:ss")
                        Duration = $durationFormatted
                        InputFile = $InputPath
                        TotalNetworks = $networkCount
                        TotalHostsScanned = $allResults.Count
                        ReachableHosts = ($allResults | Where-Object { $_.Status -eq "Reachable" }).Count
                        UnreachableHosts = ($allResults | Where-Object { $_.Status -eq "Unreachable" }).Count
                    }
                    Summary = $summaryData
                    Results = $allResults
                }

                # Save to timestamped JSON file in history directory
                $historyFilename = "ScanHistory_$timestamp.json"
                $historyFilePath = Join-Path -Path $HistoryPath -ChildPath $historyFilename
                $historyData | ConvertTo-Json -Depth 10 | Set-Content -Path $historyFilePath -Encoding UTF8
                Write-Host "Successfully saved scan history to: $historyFilePath" -ForegroundColor Green
            }
            catch {
                Write-Warning "Failed to save scan history: $($_.Exception.Message)"
            }
        }

        # Export change report if baseline comparison was performed
        if ($changeReport) {
            try {
                # Generate change report filename
                $changeReportFilename = "ChangeReport_$timestamp.json"
                $changeReportPath = Join-Path -Path $OutputDirectory -ChildPath $changeReportFilename

                Write-Verbose "Exporting change report to: $changeReportPath"
                $changeReport | ConvertTo-Json -Depth 10 | Set-Content -Path $changeReportPath -Encoding UTF8
                Write-Host "Successfully exported change report to: $changeReportPath" -ForegroundColor Green

                # Also save to history directory if HistoryPath is specified
                if ($HistoryPath) {
                    $historyChangeReportPath = Join-Path -Path $HistoryPath -ChildPath $changeReportFilename
                    $changeReport | ConvertTo-Json -Depth 10 | Set-Content -Path $historyChangeReportPath -Encoding UTF8
                    Write-Verbose "Change report also saved to history: $historyChangeReportPath"
                }
            }
            catch {
                Write-Warning "Failed to export change report: $($_.Exception.Message)"
            }
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
    if ($excelApp) {
        Close-ExcelSession -Excel $excelApp
    }
}

#endregion