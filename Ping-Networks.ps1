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
.PARAMETER RetentionDays
    (Optional) Number of days to retain scan history files. Older files will be automatically deleted.
    Default is 0 (no automatic cleanup). Example: -RetentionDays 30 (keep last 30 days of history)
.PARAMETER GenerateTrendReport
    (Optional) Generate a comprehensive trend analysis report from all scan history files.
    Analyzes host availability patterns, uptime statistics, and response time trends over time.
    Requires HistoryPath to be specified with existing history files.
.PARAMETER TrendDays
    (Optional) Number of days of history to include in trend analysis. Default is 30 days.
    Example: -TrendDays 90 (analyze last 90 days of scan history)
.PARAMETER CompareBaseline
    (Optional) Path to a previous scan result file (JSON) to compare against current scan.
    Generates a change detection report showing new devices, offline devices, and status changes.
.PARAMETER Throttle
    (Optional) The maximum number of concurrent ping operations (runspace pool size). Default is 50.
    Higher values = faster scans but more CPU/memory usage. Recommended range: 20-100.
    Increase for large networks or fast connections, decrease for resource-constrained systems.
.PARAMETER MaxPings
    (Optional) The maximum number of hosts to ping per network. If not specified, all usable hosts will be pinged.
.PARAMETER Timeout
    (Optional) The timeout in seconds for each ping. The default is 1 second.
.PARAMETER Retries
    (Optional) The number of retries for each ping with exponential backoff (1s, 2s, 4s). The default is 0.
.PARAMETER Count
    (Optional) The number of ping attempts per host for response time statistics. The default is 1.
    Higher values provide more accurate statistics but increase scan time.
.PARAMETER BufferSize
    (Optional) The size of the ICMP packet buffer in bytes (1-65500). The default is 32.
    Useful for MTU testing and detecting path MTU issues. Common values: 32, 64, 1500.
.PARAMETER TimeToLive
    (Optional) The Time To Live (TTL) value for ping packets (1-255). The default is 128.
    Useful for testing maximum hop count and detecting routing loops.
.PARAMETER EmailTo
    (Optional) Array of email addresses to send reports to. Required if EmailOnCompletion or EmailOnChanges is used.
    Example: -EmailTo "admin@example.com","team@example.com"
.PARAMETER EmailFrom
    (Optional) Email address to send from. Required if email notifications are enabled.
.PARAMETER SmtpServer
    (Optional) SMTP server address for sending emails. Required if email notifications are enabled.
    Example: -SmtpServer "smtp.gmail.com" or "smtp.office365.com"
.PARAMETER SmtpPort
    (Optional) SMTP server port. Default is 587 (TLS). Use 25 for unencrypted or 465 for SSL.
.PARAMETER SmtpUsername
    (Optional) Username for SMTP authentication. Required for most email providers.
.PARAMETER SmtpPassword
    (Optional) Password for SMTP authentication. Use app-specific passwords for Gmail/Outlook.
.PARAMETER UseSSL
    (Optional) Use SSL/TLS encryption for SMTP connection. Recommended for port 587 or 465.
.PARAMETER EmailOnCompletion
    (Optional) Send email notification when scan completes with summary and attached reports.
.PARAMETER EmailOnChanges
    (Optional) Send email alert when baseline comparison detects network changes (new/offline/recovered devices).
.PARAMETER MinChangesToAlert
    (Optional) Minimum number of total changes required to trigger email alert. Default is 1 (alert on any change).
    Example: -MinChangesToAlert 5 (only alert if 5 or more devices changed)
.PARAMETER MinChangePercentage
    (Optional) Minimum percentage of network changes required to trigger alert (0-100). Default is 0 (no threshold).
    Example: -MinChangePercentage 10 (only alert if 10% or more of the network changed)
.PARAMETER AlertOnNewOnly
    (Optional) Only send alerts when new devices are detected. Ignores offline and recovered devices.
.PARAMETER AlertOnOfflineOnly
    (Optional) Only send alerts when devices go offline. Ignores new and recovered devices.
.PARAMETER CheckpointPath
    (Optional) Directory path where checkpoint files will be saved during scanning.
    Checkpoints allow resuming interrupted scans from the last saved state.
    Example: -CheckpointPath "C:\ScanCheckpoints"
.PARAMETER CheckpointInterval
    (Optional) Save checkpoint after every N hosts scanned. Default is 50 hosts.
    Lower values = more frequent saves (less data loss) but slightly slower scans.
    Example: -CheckpointInterval 25 (save every 25 hosts)
.PARAMETER ResumeCheckpoint
    (Optional) Path to a checkpoint file to resume an interrupted scan from.
    The scan will skip already-scanned hosts and continue with remaining networks.
    Example: -ResumeCheckpoint "C:\ScanCheckpoints\Checkpoint_20251228_120000.json"
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
    [Parameter(Mandatory = $false, ParameterSetName = 'Process')]
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
    [int]$RetentionDays = 0,

    [Parameter(Mandatory = $false, ParameterSetName = 'Process')]
    [switch]$GenerateTrendReport,

    [Parameter(Mandatory = $false, ParameterSetName = 'Process')]
    [int]$TrendDays = 30,

    [Parameter(Mandatory = $false, ParameterSetName = 'Process')]
    [string]$CompareBaseline,

    [Parameter(Mandatory = $false, ParameterSetName = 'Process')]
    [int]$Throttle = 50,

    [Parameter(Mandatory = $false, ParameterSetName = 'Process')]
    [int]$MaxPings,

    [Parameter(Mandatory = $false, ParameterSetName = 'Process')]
    [int]$Timeout = 1,

    [Parameter(Mandatory = $false, ParameterSetName = 'Process')]
    [int]$Retries = 0,

    [Parameter(Mandatory = $false, ParameterSetName = 'Process')]
    [int]$Count = 1,

    [Parameter(Mandatory = $false, ParameterSetName = 'Process')]
    [ValidateRange(1, 65500)]
    [int]$BufferSize = 32,

    [Parameter(Mandatory = $false, ParameterSetName = 'Process')]
    [ValidateRange(1, 255)]
    [int]$TimeToLive = 128,

    [Parameter(Mandatory = $false, ParameterSetName = 'Process')]
    [string[]]$EmailTo,

    [Parameter(Mandatory = $false, ParameterSetName = 'Process')]
    [string]$EmailFrom,

    [Parameter(Mandatory = $false, ParameterSetName = 'Process')]
    [string]$SmtpServer,

    [Parameter(Mandatory = $false, ParameterSetName = 'Process')]
    [int]$SmtpPort = 587,

    [Parameter(Mandatory = $false, ParameterSetName = 'Process')]
    [string]$SmtpUsername,

    [Parameter(Mandatory = $false, ParameterSetName = 'Process')]
    [string]$SmtpPassword,

    [Parameter(Mandatory = $false, ParameterSetName = 'Process')]
    [switch]$UseSSL,

    [Parameter(Mandatory = $false, ParameterSetName = 'Process')]
    [switch]$EmailOnCompletion,

    [Parameter(Mandatory = $false, ParameterSetName = 'Process')]
    [switch]$EmailOnChanges,

    [Parameter(Mandatory = $false, ParameterSetName = 'Process')]
    [int]$MinChangesToAlert = 1,

    [Parameter(Mandatory = $false, ParameterSetName = 'Process')]
    [ValidateRange(0, 100)]
    [int]$MinChangePercentage = 0,

    [Parameter(Mandatory = $false, ParameterSetName = 'Process')]
    [switch]$AlertOnNewOnly,

    [Parameter(Mandatory = $false, ParameterSetName = 'Process')]
    [switch]$AlertOnOfflineOnly,

    [Parameter(Mandatory = $false, ParameterSetName = 'Process')]
    [string]$CheckpointPath,

    [Parameter(Mandatory = $false, ParameterSetName = 'Process')]
    [int]$CheckpointInterval = 50,

    [Parameter(Mandatory = $false, ParameterSetName = 'Process')]
    [string]$ResumeCheckpoint,

    [Parameter(Mandatory = $false, ParameterSetName = 'Process')]
    [string]$DatabaseConnectionString,

    [Parameter(Mandatory = $false, ParameterSetName = 'Process')]
    [ValidateSet('SQLServer', 'MySQL', 'PostgreSQL')]
    [string]$DatabaseType = 'SQLServer',

    [Parameter(Mandatory = $false, ParameterSetName = 'Process')]
    [switch]$DatabaseExport,

    [Parameter(Mandatory = $false, ParameterSetName = 'Process')]
    [switch]$InitializeDatabase
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
                   * Excel (.xlsx): "Network" column with CIDR/Range, or IP/Subnet Mask/CIDR columns
                   * CSV (.csv): Same as Excel with header row
                   * Text (.txt): One network per line (CIDR or Range format)
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
Import-Module (Join-Path $PSScriptRoot "modules\DatabaseUtils.psm1") -Force

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

# Initialize checkpoint system
$checkpointData = $null
$resumingFromCheckpoint = $false

if ($CheckpointPath) {
    # Create checkpoint directory if it doesn't exist
    if (-not (Test-Path -Path $CheckpointPath)) {
        New-Item -Path $CheckpointPath -ItemType Directory -Force | Out-Null
        Write-Verbose "Created checkpoint directory: $CheckpointPath"
    }
}

# Validate parameters: either InputPath or ResumeCheckpoint must be provided
if (-not $InputPath -and -not $ResumeCheckpoint) {
    throw "Either -InputPath or -ResumeCheckpoint must be specified."
}

# Load checkpoint if resuming
if ($ResumeCheckpoint) {
    try {
        if (-not (Test-Path -Path $ResumeCheckpoint)) {
            Write-Warning "Checkpoint file not found: $ResumeCheckpoint. Starting fresh scan."
        } else {
            Write-Host "Resuming from checkpoint: $ResumeCheckpoint" -ForegroundColor Cyan
            $checkpointJson = Get-Content -Path $ResumeCheckpoint -Raw -Encoding UTF8
            $checkpointData = $checkpointJson | ConvertFrom-Json
            $resumingFromCheckpoint = $true

            Write-Verbose "Checkpoint loaded: $($checkpointData.CheckpointMetadata.TotalHostsScanned) hosts already scanned"
            Write-Verbose "Progress: $($checkpointData.CheckpointMetadata.ProgressPercentage)% complete"

            # Restore InputPath from checkpoint if not provided
            if (-not $InputPath -and $checkpointData.CheckpointMetadata.ScanParameters.InputPath) {
                $InputPath = $checkpointData.CheckpointMetadata.ScanParameters.InputPath
                Write-Verbose "Restored InputPath from checkpoint: $InputPath"
            }

            # Restore other scan parameters from checkpoint if not explicitly provided
            if (-not $PSBoundParameters.ContainsKey('Throttle') -and $checkpointData.CheckpointMetadata.ScanParameters.Throttle) {
                $Throttle = $checkpointData.CheckpointMetadata.ScanParameters.Throttle
            }
            if (-not $PSBoundParameters.ContainsKey('MaxPings') -and $checkpointData.CheckpointMetadata.ScanParameters.MaxPings) {
                $MaxPings = $checkpointData.CheckpointMetadata.ScanParameters.MaxPings
            }
            if (-not $PSBoundParameters.ContainsKey('Timeout') -and $checkpointData.CheckpointMetadata.ScanParameters.Timeout) {
                $Timeout = $checkpointData.CheckpointMetadata.ScanParameters.Timeout
            }
            if (-not $PSBoundParameters.ContainsKey('Retries') -and $checkpointData.CheckpointMetadata.ScanParameters.Retries) {
                $Retries = $checkpointData.CheckpointMetadata.ScanParameters.Retries
            }
            if (-not $PSBoundParameters.ContainsKey('Count') -and $checkpointData.CheckpointMetadata.ScanParameters.Count) {
                $Count = $checkpointData.CheckpointMetadata.ScanParameters.Count
            }
            if (-not $PSBoundParameters.ContainsKey('BufferSize') -and $checkpointData.CheckpointMetadata.ScanParameters.BufferSize) {
                $BufferSize = $checkpointData.CheckpointMetadata.ScanParameters.BufferSize
            }
            if (-not $PSBoundParameters.ContainsKey('TimeToLive') -and $checkpointData.CheckpointMetadata.ScanParameters.TimeToLive) {
                $TimeToLive = $checkpointData.CheckpointMetadata.ScanParameters.TimeToLive
            }
        }
    }
    catch {
        Write-Warning "Failed to load checkpoint file: $($_.Exception.Message). Starting fresh scan."
        $checkpointData = $null
        $resumingFromCheckpoint = $false
    }
}

# Function to save checkpoint
function Save-Checkpoint {
    param(
        [System.Collections.Generic.List[pscustomobject]]$AllResults,
        [System.Collections.Generic.List[pscustomobject]]$SummaryData,
        [array]$RemainingNetworks,
        [int]$ProcessedNetworkCount,
        [int]$TotalNetworkCount,
        [hashtable]$ScanParameters
    )

    if (-not $CheckpointPath) {
        return  # Checkpoints not enabled
    }

    try {
        $checkpointTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $checkpointFilename = "Checkpoint_$checkpointTimestamp.json"
        $checkpointFilePath = Join-Path -Path $CheckpointPath -ChildPath $checkpointFilename

        $progressPct = if ($TotalNetworkCount -gt 0) {
            [math]::Round(($ProcessedNetworkCount / $TotalNetworkCount) * 100, 1)
        } else { 0 }

        $checkpointObj = [PSCustomObject]@{
            CheckpointMetadata = @{
                ScanStartTime = $scanStartTime.ToString("yyyy-MM-dd HH:mm:ss")
                CheckpointTime = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                TotalNetworks = $TotalNetworkCount
                ProcessedNetworks = $ProcessedNetworkCount
                TotalHostsScanned = $AllResults.Count
                ProgressPercentage = $progressPct
                ScanParameters = $ScanParameters
            }
            CompletedResults = $AllResults
            SummaryData = $SummaryData
            RemainingNetworks = $RemainingNetworks
        }

        $checkpointObj | ConvertTo-Json -Depth 10 | Set-Content -Path $checkpointFilePath -Encoding UTF8
        Write-Verbose "Checkpoint saved: $checkpointFilePath ($progressPct% complete, $($AllResults.Count) hosts)"
    }
    catch {
        Write-Warning "Failed to save checkpoint: $($_.Exception.Message)"
    }
}

#endregion

#region MAIN PROCESSING

# Global variables for graceful abort handling
$script:ScanInterrupted = $false
$script:PartialResults = $false
$script:ScanPaused = $false

# Register Ctrl+C handler for graceful abort
$null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    if ($script:ScanInterrupted) {
        Write-Host "`n`nScan was interrupted. Partial results have been saved." -ForegroundColor Yellow
    }
}

# Trap handler for unexpected termination
trap {
    $script:ScanInterrupted = $true
    Write-Warning "Scan interrupted: $_"
    Write-Host "`nAttempting to save partial results..." -ForegroundColor Yellow
    $script:PartialResults = $true
    continue
}

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

    # Resume from checkpoint if available
    if ($resumingFromCheckpoint -and $checkpointData) {
        Write-Host "Restoring scan state from checkpoint..." -ForegroundColor Cyan

        # Restore completed results and summary data
        if ($checkpointData.CompletedResults) {
            foreach ($result in $checkpointData.CompletedResults) {
                $allResults.Add($result)
            }
            Write-Verbose "Restored $($allResults.Count) completed scan results"
        }

        if ($checkpointData.SummaryData) {
            foreach ($summary in $checkpointData.SummaryData) {
                $summaryData.Add($summary)
            }
            Write-Verbose "Restored $($summaryData.Count) network summaries"
        }

        # Filter networks to only remaining networks
        if ($checkpointData.RemainingNetworks -and $checkpointData.RemainingNetworks.Count -gt 0) {
            $originalCount = $networks.Count
            $networks = $checkpointData.RemainingNetworks
            $processedCount = $originalCount - $networks.Count
            Write-Host "Skipping $processedCount already-scanned network(s), continuing with $($networks.Count) remaining" -ForegroundColor Yellow
        }
    }

    $networkCount = $networks.Count
    $networkIndex = if ($resumingFromCheckpoint) { $checkpointData.CheckpointMetadata.ProcessedNetworks } else { 0 }
    $totalNetworkCount = if ($resumingFromCheckpoint) { $checkpointData.CheckpointMetadata.TotalNetworks } else { $networkCount }

    if ($networkCount -eq 0) {
        if ($resumingFromCheckpoint) {
            Write-Host "Checkpoint scan was already complete. No remaining networks to scan." -ForegroundColor Green
            $networkCount = $totalNetworkCount  # Use total count for report generation
        } else {
            throw "No networks found in input file. Please ensure the Excel file has data rows."
        }
    }

    # Store scan parameters for checkpoint
    $scanParameters = @{
        InputPath = $InputPath
        Throttle = $Throttle
        MaxPings = $MaxPings
        Timeout = $Timeout
        Retries = $Retries
        Count = $Count
        BufferSize = $BufferSize
        TimeToLive = $TimeToLive
    }

    # Track hosts scanned since last checkpoint
    $hostsSinceCheckpoint = 0

    # Display interactive controls information
    Write-Host "`n💡 TIP: Press 'P' at any time to pause the scan" -ForegroundColor Cyan

    foreach ($networkInput in $networks) {
        $networkIndex++

        # Check for pause request (P key) - only in interactive console
        try {
            if ([Console]::KeyAvailable) {
                $key = [Console]::ReadKey($true)
                if ($key.Key -eq 'P') {
                    $script:ScanPaused = $true
                    Write-Host "`n`n⏸ SCAN PAUSED" -ForegroundColor Yellow
                    Write-Host "Press 'R' to Resume, 'S' to Save checkpoint and quit, or 'Q' to Quit without saving" -ForegroundColor Cyan

                    # Wait for resume, save, or quit command
                    $waitingForCommand = $true
                    while ($waitingForCommand) {
                        if ([Console]::KeyAvailable) {
                            $resumeKey = [Console]::ReadKey($true)
                            switch ($resumeKey.Key) {
                                'R' {
                                    Write-Host "▶ Resuming scan...`n" -ForegroundColor Green
                                    $script:ScanPaused = $false
                                    $waitingForCommand = $false
                                }
                                'S' {
                                    Write-Host "`nSaving checkpoint and exiting..." -ForegroundColor Yellow
                                    if ($CheckpointPath) {
                                        $remainingNetworksList = $networks[($networkIndex - 1)..$networks.Count]
                                        Save-Checkpoint -AllResults $allResults `
                                                       -SummaryData $summaryData `
                                                       -RemainingNetworks $remainingNetworksList `
                                                       -ProcessedNetworkCount ($networkIndex - 1) `
                                                       -TotalNetworkCount $totalNetworkCount `
                                                       -ScanParameters $scanParameters
                                        Write-Host "Checkpoint saved successfully." -ForegroundColor Green
                                    } else {
                                        Write-Warning "CheckpointPath not specified. Cannot save checkpoint."
                                    }
                                    $script:ScanInterrupted = $true
                                    throw "Scan paused and saved by user"
                                }
                                'Q' {
                                    Write-Host "`nQuitting without saving..." -ForegroundColor Red
                                    $script:ScanInterrupted = $true
                                    throw "Scan cancelled by user"
                                }
                            }
                        }
                        Start-Sleep -Milliseconds 100
                    }
                }
            }
        }
        catch {
            # Console input not available (redirected or non-interactive) - skip pause functionality
        }

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

        Write-Verbose "Processing network $networkIndex of $totalNetworkCount : $networkIdentifier (Format: $($network.Format))"

        # Display current network being scanned with enhanced details
        $percentComplete = if ($totalNetworkCount -gt 0) { ($networkIndex / $totalNetworkCount) * 100 } else { 0 }
        # Cap at 100% to avoid Write-Progress errors
        if ($percentComplete -gt 100) { $percentComplete = 100 }
        $networkStatus = "Network $networkIndex of $totalNetworkCount : $networkIdentifier"
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

        # Ping all hosts in this network with advanced parameters
        $pingResults = Start-Ping -Hosts $hostsToPing -Throttle $Throttle -Count $Count -BufferSize $BufferSize -TimeToLive $TimeToLive -Timeout $Timeout -Retries $Retries
        
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

        # Track hosts for checkpoint interval
        $hostsSinceCheckpoint += $pingResultsProcessed.Count

        # Save checkpoint if enabled and interval reached
        if ($CheckpointPath -and $hostsSinceCheckpoint -ge $CheckpointInterval) {
            # Calculate remaining networks
            $remainingNetworksList = $networks[($networkIndex)..$networks.Count]

            Save-Checkpoint -AllResults $allResults `
                           -SummaryData $summaryData `
                           -RemainingNetworks $remainingNetworksList `
                           -ProcessedNetworkCount $networkIndex `
                           -TotalNetworkCount $totalNetworkCount `
                           -ScanParameters $scanParameters

            $hostsSinceCheckpoint = 0  # Reset counter
        }
    }

    # Save final checkpoint before completing scan
    if ($CheckpointPath) {
        Write-Verbose "Saving final checkpoint..."
        Save-Checkpoint -AllResults $allResults `
                       -SummaryData $summaryData `
                       -RemainingNetworks @() `
                       -ProcessedNetworkCount $totalNetworkCount `
                       -TotalNetworkCount $totalNetworkCount `
                       -ScanParameters $scanParameters
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

    # Notify user about scan status
    if ($script:ScanInterrupted) {
        Write-Host "`n========================================" -ForegroundColor Yellow
        Write-Host "  SCAN INTERRUPTED - SAVING PARTIAL RESULTS" -ForegroundColor Yellow
        Write-Host "========================================" -ForegroundColor Yellow
        Write-Host "Scanned: $($allResults.Count) hosts" -ForegroundColor White
        Write-Host "Saving available results...`n" -ForegroundColor White
    }
    else {
        Write-Host "`nGenerating output files..." -ForegroundColor Cyan
    }

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

                # Apply retention policy if specified
                if ($RetentionDays -gt 0) {
                    Write-Verbose "Applying retention policy: keeping last $RetentionDays days of history"
                    $cutoffDate = (Get-Date).AddDays(-$RetentionDays)

                    # Find and delete old scan history files
                    $oldHistoryFiles = Get-ChildItem -Path $HistoryPath -Filter "ScanHistory_*.json" |
                                       Where-Object { $_.LastWriteTime -lt $cutoffDate }

                    if ($oldHistoryFiles) {
                        $deletedCount = 0
                        foreach ($file in $oldHistoryFiles) {
                            try {
                                Remove-Item -Path $file.FullName -Force
                                Write-Verbose "Deleted old history file: $($file.Name)"
                                $deletedCount++
                            }
                            catch {
                                Write-Warning "Failed to delete old history file $($file.Name): $($_.Exception.Message)"
                            }
                        }
                        Write-Host "Retention policy applied: deleted $deletedCount old history file(s)" -ForegroundColor Yellow
                    }

                    # Find and delete old change report files
                    $oldChangeReports = Get-ChildItem -Path $HistoryPath -Filter "ChangeReport_*.json" |
                                        Where-Object { $_.LastWriteTime -lt $cutoffDate }

                    if ($oldChangeReports) {
                        $deletedCount = 0
                        foreach ($file in $oldChangeReports) {
                            try {
                                Remove-Item -Path $file.FullName -Force
                                Write-Verbose "Deleted old change report: $($file.Name)"
                                $deletedCount++
                            }
                            catch {
                                Write-Warning "Failed to delete old change report $($file.Name): $($_.Exception.Message)"
                            }
                        }
                        if ($deletedCount -gt 0) {
                            Write-Host "Retention policy applied: deleted $deletedCount old change report(s)" -ForegroundColor Yellow
                        }
                    }
                }
            }
            catch {
                Write-Warning "Failed to save scan history: $($_.Exception.Message)"
            }
        }

        #region TREND ANALYSIS
        $trendReport = $null
        if ($GenerateTrendReport -and $HistoryPath) {
            try {
                Write-Host "`nGenerating trend analysis report..." -ForegroundColor Cyan
                Write-Verbose "Analyzing scan history from: $HistoryPath"

                # Ensure history directory exists
                if (-not (Test-Path -Path $HistoryPath)) {
                    Write-Warning "History path does not exist: $HistoryPath. Cannot generate trend report."
                }
                else {
                    # Calculate cutoff date for trend analysis
                    $trendCutoffDate = (Get-Date).AddDays(-$TrendDays)

                    # Load all history files within the trend period
                    $historyFiles = Get-ChildItem -Path $HistoryPath -Filter "ScanHistory_*.json" |
                                    Where-Object { $_.LastWriteTime -ge $trendCutoffDate } |
                                    Sort-Object LastWriteTime

                    if (-not $historyFiles -or $historyFiles.Count -lt 2) {
                        Write-Warning "Insufficient history data for trend analysis. Found $($historyFiles.Count) scan(s), need at least 2."
                    }
                    else {
                        Write-Verbose "Found $($historyFiles.Count) scan history files for trend analysis"

                        # Load and parse all history data
                        $allScans = @()
                        foreach ($file in $historyFiles) {
                            try {
                                $scanData = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
                                $allScans += [PSCustomObject]@{
                                    ScanDate = [DateTime]::Parse($scanData.ScanMetadata.ScanDate)
                                    Results = $scanData.Results
                                }
                            }
                            catch {
                                Write-Warning "Failed to load history file $($file.Name): $($_.Exception.Message)"
                            }
                        }

                        if ($allScans.Count -ge 2) {
                            # Build host availability tracking
                            $hostTracking = @{}

                            foreach ($scan in $allScans) {
                                foreach ($result in $scan.Results) {
                                    $hostKey = $result.Host

                                    if (-not $hostTracking.ContainsKey($hostKey)) {
                                        $hostTracking[$hostKey] = @{
                                            Host = $hostKey
                                            Network = $result.Network
                                            FirstSeen = $scan.ScanDate
                                            LastSeen = $scan.ScanDate
                                            TotalScans = 0
                                            ReachableCount = 0
                                            UnreachableCount = 0
                                            ResponseTimes = @()
                                            LastStatus = $null
                                            LastHostname = $null
                                        }
                                    }

                                    $tracking = $hostTracking[$hostKey]
                                    $tracking.TotalScans++
                                    $tracking.LastSeen = $scan.ScanDate
                                    $tracking.LastStatus = $result.Status

                                    if ($result.Status -eq "Reachable") {
                                        $tracking.ReachableCount++
                                        if ($result.Hostname -and $result.Hostname -ne "N/A") {
                                            $tracking.LastHostname = $result.Hostname
                                        }
                                        if ($result.ResponseTime -and $result.ResponseTime -gt 0) {
                                            $tracking.ResponseTimes += $result.ResponseTime
                                        }
                                    }
                                    else {
                                        $tracking.UnreachableCount++
                                    }
                                }
                            }

                            # Calculate statistics for each host
                            $trendData = @()
                            foreach ($hostKey in $hostTracking.Keys) {
                                $tracking = $hostTracking[$hostKey]

                                $uptimePercentage = if ($tracking.TotalScans -gt 0) {
                                    [math]::Round(($tracking.ReachableCount / $tracking.TotalScans) * 100, 2)
                                } else { 0 }

                                $avgResponseTime = if ($tracking.ResponseTimes.Count -gt 0) {
                                    [math]::Round(($tracking.ResponseTimes | Measure-Object -Average).Average, 2)
                                } else { 0 }

                                $minResponseTime = if ($tracking.ResponseTimes.Count -gt 0) {
                                    ($tracking.ResponseTimes | Measure-Object -Minimum).Minimum
                                } else { 0 }

                                $maxResponseTime = if ($tracking.ResponseTimes.Count -gt 0) {
                                    ($tracking.ResponseTimes | Measure-Object -Maximum).Maximum
                                } else { 0 }

                                $trendData += [PSCustomObject]@{
                                    Host = $tracking.Host
                                    Network = $tracking.Network
                                    Hostname = if ($tracking.LastHostname) { $tracking.LastHostname } else { "N/A" }
                                    FirstSeen = $tracking.FirstSeen.ToString("yyyy-MM-dd HH:mm:ss")
                                    LastSeen = $tracking.LastSeen.ToString("yyyy-MM-dd HH:mm:ss")
                                    CurrentStatus = $tracking.LastStatus
                                    TotalScans = $tracking.TotalScans
                                    ReachableCount = $tracking.ReachableCount
                                    UnreachableCount = $tracking.UnreachableCount
                                    UptimePercentage = $uptimePercentage
                                    AvgResponseTime = $avgResponseTime
                                    MinResponseTime = $minResponseTime
                                    MaxResponseTime = $maxResponseTime
                                }
                            }

                            # Sort by uptime percentage (descending) then by host
                            $trendData = $trendData | Sort-Object @{Expression={$_.UptimePercentage}; Descending=$true}, Host

                            # Create trend report
                            $trendReport = [PSCustomObject]@{
                                ReportMetadata = @{
                                    GeneratedDate = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                                    TrendPeriodDays = $TrendDays
                                    AnalysisStartDate = $allScans[0].ScanDate.ToString("yyyy-MM-dd HH:mm:ss")
                                    AnalysisEndDate = $allScans[-1].ScanDate.ToString("yyyy-MM-dd HH:mm:ss")
                                    TotalScansAnalyzed = $allScans.Count
                                    UniqueHostsTracked = $trendData.Count
                                }
                                Summary = @{
                                    AlwaysReachable = ($trendData | Where-Object { $_.UptimePercentage -eq 100 }).Count
                                    MostlyReachable = ($trendData | Where-Object { $_.UptimePercentage -ge 80 -and $_.UptimePercentage -lt 100 }).Count
                                    Intermittent = ($trendData | Where-Object { $_.UptimePercentage -gt 0 -and $_.UptimePercentage -lt 80 }).Count
                                    AlwaysUnreachable = ($trendData | Where-Object { $_.UptimePercentage -eq 0 }).Count
                                    AvgUptimePercentage = [math]::Round(($trendData | Measure-Object -Property UptimePercentage -Average).Average, 2)
                                }
                                HostTrends = $trendData
                            }

                            # Export trend report
                            $trendReportFilename = "TrendReport_$timestamp.json"
                            $trendReportPath = Join-Path -Path $OutputDirectory -ChildPath $trendReportFilename
                            $trendReport | ConvertTo-Json -Depth 10 | Set-Content -Path $trendReportPath -Encoding UTF8
                            Write-Host "Successfully generated trend analysis report: $trendReportPath" -ForegroundColor Green

                            # Also save to history directory
                            $historyTrendReportPath = Join-Path -Path $HistoryPath -ChildPath $trendReportFilename
                            $trendReport | ConvertTo-Json -Depth 10 | Set-Content -Path $historyTrendReportPath -Encoding UTF8
                            Write-Verbose "Trend report also saved to history: $historyTrendReportPath"

                            # Display summary
                            Write-Host "`nTrend Analysis Summary:" -ForegroundColor Cyan
                            Write-Host "  Analysis Period: $TrendDays days ($($allScans.Count) scans)" -ForegroundColor White
                            Write-Host "  Unique Hosts Tracked: $($trendData.Count)" -ForegroundColor White
                            Write-Host "  Always Reachable (100%): $($trendReport.Summary.AlwaysReachable)" -ForegroundColor Green
                            Write-Host "  Mostly Reachable (80-99%): $($trendReport.Summary.MostlyReachable)" -ForegroundColor Yellow
                            Write-Host "  Intermittent (1-79%): $($trendReport.Summary.Intermittent)" -ForegroundColor Magenta
                            Write-Host "  Always Unreachable (0%): $($trendReport.Summary.AlwaysUnreachable)" -ForegroundColor Red
                            Write-Host "  Average Uptime: $($trendReport.Summary.AvgUptimePercentage)%" -ForegroundColor White
                        }
                    }
                }
            }
            catch {
                Write-Warning "Failed to generate trend analysis: $($_.Exception.Message)"
            }
        }
        #endregion

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

        #region DATABASE EXPORT

        # Export to database if configured
        if ($DatabaseExport -and $DatabaseConnectionString) {
            try {
                Write-Host "`nExporting scan results to database..." -ForegroundColor Cyan

                # Initialize database schema if requested
                if ($InitializeDatabase) {
                    Write-Verbose "Initializing database schema"
                    Initialize-DatabaseSchema -ConnectionString $DatabaseConnectionString -DatabaseType $DatabaseType
                }

                # Test database connection
                $connectionTest = Test-DatabaseConnection -ConnectionString $DatabaseConnectionString -DatabaseType $DatabaseType
                if (-not $connectionTest) {
                    Write-Warning "Database connection test failed. Skipping database export."
                }
                else {
                    # Calculate scan duration
                    $scanEndTime = Get-Date
                    $scanDuration = $scanEndTime - $scanStartTime
                    $durationFormatted = "{0:D2}:{1:D2}:{2:D2}" -f $scanDuration.Hours, $scanDuration.Minutes, $scanDuration.Seconds

                    # Prepare scan metadata for database
                    $dbMetadata = @{
                        ScanDate = $scanStartTime
                        ScanStartTime = $scanStartTime
                        ScanEndTime = $scanEndTime
                        Duration = $durationFormatted
                        NetworkCount = $networkCount
                        InputFile = $InputPath
                        OutputDirectory = $OutputDirectory
                        Throttle = $Throttle
                    }

                    # Export to database
                    $scanId = Export-DatabaseResults -Results $allResults `
                                                     -ScanMetadata $dbMetadata `
                                                     -ConnectionString $DatabaseConnectionString `
                                                     -DatabaseType $DatabaseType

                    Write-Host "Database export completed successfully (ScanId: $scanId)" -ForegroundColor Green
                }
            }
            catch {
                Write-Warning "Database export failed: $($_.Exception.Message)"
                Write-Verbose $_.Exception.StackTrace
            }
        }

        #endregion

        #region EMAIL NOTIFICATIONS

        # Send email notifications if configured
        if (($EmailOnCompletion -or $EmailOnChanges) -and $EmailTo -and $EmailFrom -and $SmtpServer) {

            # Determine if we should send email
            $shouldSendEmail = $false
            $emailSubject = ""
            $emailBodyParts = @()

            # Check if we should send completion notification
            if ($EmailOnCompletion) {
                $shouldSendEmail = $true
                $emailSubject = "Network Scan Completed - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"

                # Build completion email body
                $scanEndTime = Get-Date
                $scanDuration = $scanEndTime - $scanStartTime
                $durationFormatted = "{0:D2}:{1:D2}:{2:D2}" -f $scanDuration.Hours, $scanDuration.Minutes, $scanDuration.Seconds

                $totalScanned = $allResults.Count
                $reachable = ($allResults | Where-Object { $_.Status -eq "Reachable" }).Count
                $unreachable = ($allResults | Where-Object { $_.Status -eq "Unreachable" }).Count

                $emailBodyParts += @"
<h2>Network Scan Summary</h2>
<p><strong>Scan Date:</strong> $($scanStartTime.ToString("yyyy-MM-dd HH:mm:ss"))</p>
<p><strong>Duration:</strong> $durationFormatted</p>
<p><strong>Input File:</strong> $InputPath</p>
<p><strong>Networks Scanned:</strong> $networkCount</p>

<h3>Results</h3>
<ul>
    <li><strong>Total Hosts Scanned:</strong> $totalScanned</li>
    <li><strong style="color: green;">Reachable Hosts:</strong> $reachable</li>
    <li><strong style="color: red;">Unreachable Hosts:</strong> $unreachable</li>
</ul>
"@
            }

            # Check if we should send change alert
            if ($EmailOnChanges -and $changeReport) {
                $newCount = $changeReport.Summary.NewDevices
                $offlineCount = $changeReport.Summary.OfflineDevices
                $recoveredCount = $changeReport.Summary.RecoveredDevices
                $totalChanges = $newCount + $offlineCount + $recoveredCount

                # Apply alert thresholds
                $meetsThreshold = $true

                # Check minimum changes threshold
                if ($totalChanges -lt $MinChangesToAlert) {
                    $meetsThreshold = $false
                    Write-Verbose "Changes ($totalChanges) below minimum threshold ($MinChangesToAlert). Skipping email alert."
                }

                # Check percentage threshold if specified
                if ($meetsThreshold -and $MinChangePercentage -gt 0) {
                    $totalHosts = $allResults.Count
                    $changePercentage = if ($totalHosts -gt 0) { ($totalChanges / $totalHosts) * 100 } else { 0 }
                    if ($changePercentage -lt $MinChangePercentage) {
                        $meetsThreshold = $false
                        Write-Verbose "Change percentage ($([math]::Round($changePercentage, 2))%) below minimum threshold ($MinChangePercentage%). Skipping email alert."
                    }
                }

                # Check alert type filters
                if ($meetsThreshold -and $AlertOnNewOnly -and $newCount -eq 0) {
                    $meetsThreshold = $false
                    Write-Verbose "AlertOnNewOnly specified but no new devices detected. Skipping email alert."
                }

                if ($meetsThreshold -and $AlertOnOfflineOnly -and $offlineCount -eq 0) {
                    $meetsThreshold = $false
                    Write-Verbose "AlertOnOfflineOnly specified but no offline devices detected. Skipping email alert."
                }

                # Send alert if thresholds are met
                if ($meetsThreshold) {
                    $shouldSendEmail = $true
                    if (-not $emailSubject) {
                        $emailSubject = "Network Changes Detected - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
                    } else {
                        $emailSubject = "Network Scan & Changes Detected - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
                    }
                }

                $changesColor = if (($newCount + $offlineCount) -gt 0) { "orange" } else { "green" }

                $emailBodyParts += @"
<h2 style="color: $changesColor;">Network Changes Detected</h2>
<p><strong>Baseline Scan:</strong> $($changeReport.ComparisonMetadata.BaselineScanDate)</p>
<p><strong>Current Scan:</strong> $($changeReport.ComparisonMetadata.CurrentScanDate)</p>

<h3>Change Summary</h3>
<ul>
    <li><strong style="color: $(if ($newCount -gt 0) { 'orange' } else { 'gray' });">New Devices:</strong> $newCount</li>
    <li><strong style="color: $(if ($offlineCount -gt 0) { 'red' } else { 'gray' });">Devices Offline:</strong> $offlineCount</li>
    <li><strong style="color: $(if ($recoveredCount -gt 0) { 'green' } else { 'gray' });">Devices Recovered:</strong> $recoveredCount</li>
</ul>
"@

                # Add details if changes detected
                if ($newCount -gt 0) {
                    $emailBodyParts += "<h4>New Devices:</h4><ul>"
                    foreach ($device in $changeReport.NewDevices | Select-Object -First 10) {
                        $emailBodyParts += "<li>$($device.Host) - $($device.Network)</li>"
                    }
                    if ($newCount -gt 10) {
                        $emailBodyParts += "<li><em>... and $($newCount - 10) more</em></li>"
                    }
                    $emailBodyParts += "</ul>"
                }

                if ($offlineCount -gt 0) {
                    $emailBodyParts += "<h4>Devices Now Offline:</h4><ul>"
                    foreach ($device in $changeReport.OfflineDevices | Select-Object -First 10) {
                        $emailBodyParts += "<li>$($device.Host) - $($device.Network) (was: $($device.PreviousHostname))</li>"
                    }
                    if ($offlineCount -gt 10) {
                        $emailBodyParts += "<li><em>... and $($offlineCount - 10) more</em></li>"
                    }
                    $emailBodyParts += "</ul>"
                }
            }

            # Send email if conditions are met
            if ($shouldSendEmail) {
                try {
                    # Build complete HTML email body
                    $emailBody = @"
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; }
        h2 { color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 5px; }
        h3 { color: #34495e; }
        ul { padding-left: 20px; }
        p { margin: 5px 0; }
    </style>
</head>
<body>
    <h1>Ping-Networks Scan Report</h1>
    $($emailBodyParts -join "`n")
    <hr>
    <p style="color: gray; font-size: 12px;">Generated by Ping-Networks v1.6.0</p>
</body>
</html>
"@

                    # Collect attachments
                    $attachments = @()
                    if ($OutputPath -and (Test-Path $OutputPath)) { $attachments += $OutputPath }
                    if ($HtmlPath -and (Test-Path $HtmlPath)) { $attachments += $HtmlPath }
                    if ($JsonPath -and (Test-Path $JsonPath)) { $attachments += $JsonPath }
                    if ($changeReport -and $changeReportPath -and (Test-Path $changeReportPath)) {
                        $attachments += $changeReportPath
                    }

                    # Send email
                    $emailParams = @{
                        EmailTo = $EmailTo
                        EmailFrom = $EmailFrom
                        Subject = $emailSubject
                        Body = $emailBody
                        SmtpServer = $SmtpServer
                        SmtpPort = $SmtpPort
                        UseSSL = $UseSSL
                        IsBodyHtml = $true
                    }

                    if ($SmtpUsername -and $SmtpPassword) {
                        $emailParams.SmtpUsername = $SmtpUsername
                        $emailParams.SmtpPassword = $SmtpPassword
                    }

                    if ($attachments.Count -gt 0) {
                        $emailParams.Attachments = $attachments
                    }

                    Send-EmailNotification @emailParams

                } catch {
                    Write-Warning "Failed to send email notification: $($_.Exception.Message)"
                }
            }
        }
        elseif (($EmailOnCompletion -or $EmailOnChanges) -and (-not $EmailTo -or -not $EmailFrom -or -not $SmtpServer)) {
            Write-Warning "Email notification requested but missing required parameters (EmailTo, EmailFrom, or SmtpServer)"
        }

        #endregion
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