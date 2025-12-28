<#
.SYNOPSIS
    Creates a Windows Scheduled Task for automated network scanning.

.DESCRIPTION
    This helper script creates a Windows Scheduled Task that runs Ping-Networks.ps1
    on a recurring schedule. Supports daily, weekly, and monthly schedules with
    optional email notifications.

.PARAMETER TaskName
    Name for the scheduled task. Default: "Ping-Networks-Scan"

.PARAMETER ScriptPath
    Path to the Ping-Networks.ps1 script. Default: Current directory

.PARAMETER InputPath
    Path to the network data input file (.xlsx, .csv, or .txt)

.PARAMETER Schedule
    Schedule frequency: Daily, Weekly, or Monthly. Default: Daily

.PARAMETER Time
    Time to run the scan (24-hour format). Default: "03:00" (3 AM)

.PARAMETER DayOfWeek
    Day of week for weekly scans (Monday-Sunday). Only used if Schedule is Weekly.

.PARAMETER DayOfMonth
    Day of month for monthly scans (1-31). Only used if Schedule is Monthly. Default: 1

.PARAMETER OutputDirectory
    Directory where scan results will be saved. Default: C:\NetworkScans

.PARAMETER HistoryPath
    Directory where scan history will be saved. Default: C:\NetworkScans\History

.PARAMETER RetentionDays
    Number of days to retain scan history files. Older files will be automatically deleted.
    Default: 0 (no automatic cleanup)

.PARAMETER CompareBaseline
    Path to baseline file for comparison. Optional.

.PARAMETER EmailTo
    Email addresses to send reports to (comma-separated). Optional.

.PARAMETER EmailFrom
    Email address to send from. Optional.

.PARAMETER SmtpServer
    SMTP server address. Optional.

.PARAMETER SmtpPort
    SMTP server port. Default: 587

.PARAMETER SmtpUsername
    SMTP username for authentication. Optional.

.PARAMETER SmtpPassword
    SMTP password for authentication. Optional.

.PARAMETER UseSSL
    Use SSL/TLS for SMTP connection.

.PARAMETER EmailOnCompletion
    Send email when scan completes.

.PARAMETER EmailOnChanges
    Send email alert when baseline changes are detected.

.PARAMETER MinChangesToAlert
    Minimum number of total changes required to trigger email alert. Default: 1

.PARAMETER MinChangePercentage
    Minimum percentage of network changes required to trigger alert (0-100). Default: 0

.PARAMETER AlertOnNewOnly
    Only send alerts when new devices are detected.

.PARAMETER AlertOnOfflineOnly
    Only send alerts when devices go offline.

.PARAMETER RunAsUser
    User account to run the task as. Default: Current user

.EXAMPLE
    .\New-ScheduledScan.ps1 -InputPath "C:\Networks\data.xlsx" -Schedule Daily -Time "02:00"
    # Creates a daily scan at 2 AM

.EXAMPLE
    .\New-ScheduledScan.ps1 -InputPath "C:\Networks\data.xlsx" -Schedule Weekly -DayOfWeek Monday -Time "03:00" `
        -EmailTo "admin@example.com" -EmailFrom "scanner@example.com" -SmtpServer "smtp.gmail.com" `
        -SmtpUsername "scanner@gmail.com" -SmtpPassword "app-password" -UseSSL -EmailOnCompletion
    # Creates a weekly scan every Monday at 3 AM with email notifications

.NOTES
    Requires administrator privileges to create scheduled tasks.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$TaskName = "Ping-Networks-Scan",

    [Parameter(Mandatory = $false)]
    [string]$ScriptPath = (Join-Path $PSScriptRoot "Ping-Networks.ps1"),

    [Parameter(Mandatory = $true)]
    [string]$InputPath,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Daily", "Weekly", "Monthly")]
    [string]$Schedule = "Daily",

    [Parameter(Mandatory = $false)]
    [string]$Time = "03:00",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")]
    [string]$DayOfWeek = "Monday",

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 31)]
    [int]$DayOfMonth = 1,

    [Parameter(Mandatory = $false)]
    [string]$OutputDirectory = "C:\NetworkScans",

    [Parameter(Mandatory = $false)]
    [string]$HistoryPath = "C:\NetworkScans\History",

    [Parameter(Mandatory = $false)]
    [int]$RetentionDays = 0,

    [Parameter(Mandatory = $false)]
    [string]$CompareBaseline,

    [Parameter(Mandatory = $false)]
    [string[]]$EmailTo,

    [Parameter(Mandatory = $false)]
    [string]$EmailFrom,

    [Parameter(Mandatory = $false)]
    [string]$SmtpServer,

    [Parameter(Mandatory = $false)]
    [int]$SmtpPort = 587,

    [Parameter(Mandatory = $false)]
    [string]$SmtpUsername,

    [Parameter(Mandatory = $false)]
    [string]$SmtpPassword,

    [Parameter(Mandatory = $false)]
    [switch]$UseSSL,

    [Parameter(Mandatory = $false)]
    [switch]$EmailOnCompletion,

    [Parameter(Mandatory = $false)]
    [switch]$EmailOnChanges,

    [Parameter(Mandatory = $false)]
    [int]$MinChangesToAlert = 1,

    [Parameter(Mandatory = $false)]
    [ValidateRange(0, 100)]
    [int]$MinChangePercentage = 0,

    [Parameter(Mandatory = $false)]
    [switch]$AlertOnNewOnly,

    [Parameter(Mandatory = $false)]
    [switch]$AlertOnOfflineOnly,

    [Parameter(Mandatory = $false)]
    [string]$RunAsUser = $env:USERNAME
)

# Check for administrator privileges
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Error "This script requires administrator privileges. Please run as administrator."
    exit 1
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Create Scheduled Network Scan" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Verify script path exists
if (-not (Test-Path $ScriptPath)) {
    Write-Error "Ping-Networks.ps1 not found at: $ScriptPath"
    exit 1
}

# Verify input path exists
if (-not (Test-Path $InputPath)) {
    Write-Error "Input file not found: $InputPath"
    exit 1
}

# Create output directories if they don't exist
if (-not (Test-Path $OutputDirectory)) {
    New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
    Write-Host "Created output directory: $OutputDirectory" -ForegroundColor Green
}

if ($HistoryPath -and -not (Test-Path $HistoryPath)) {
    New-Item -Path $HistoryPath -ItemType Directory -Force | Out-Null
    Write-Host "Created history directory: $HistoryPath" -ForegroundColor Green
}

# Build PowerShell command
$scriptArgs = @(
    "-ExecutionPolicy Bypass"
    "-File `"$ScriptPath`""
    "-InputPath `"$InputPath`""
    "-OutputDirectory `"$OutputDirectory`""
    "-Excel"
    "-Html"
)

if ($HistoryPath) {
    $scriptArgs += "-HistoryPath `"$HistoryPath`""
    if ($RetentionDays -gt 0) {
        $scriptArgs += "-RetentionDays $RetentionDays"
    }
}

if ($CompareBaseline) {
    $scriptArgs += "-CompareBaseline `"$CompareBaseline`""
}

if ($EmailTo -and $EmailFrom -and $SmtpServer) {
    $scriptArgs += "-EmailTo $($EmailTo -join ',')"
    $scriptArgs += "-EmailFrom `"$EmailFrom`""
    $scriptArgs += "-SmtpServer `"$SmtpServer`""
    $scriptArgs += "-SmtpPort $SmtpPort"

    if ($SmtpUsername) { $scriptArgs += "-SmtpUsername `"$SmtpUsername`"" }
    if ($SmtpPassword) { $scriptArgs += "-SmtpPassword `"$SmtpPassword`"" }
    if ($UseSSL) { $scriptArgs += "-UseSSL" }
    if ($EmailOnCompletion) { $scriptArgs += "-EmailOnCompletion" }
    if ($EmailOnChanges) {
        $scriptArgs += "-EmailOnChanges"
        if ($MinChangesToAlert -ne 1) { $scriptArgs += "-MinChangesToAlert $MinChangesToAlert" }
        if ($MinChangePercentage -gt 0) { $scriptArgs += "-MinChangePercentage $MinChangePercentage" }
        if ($AlertOnNewOnly) { $scriptArgs += "-AlertOnNewOnly" }
        if ($AlertOnOfflineOnly) { $scriptArgs += "-AlertOnOfflineOnly" }
    }
}

$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument ($scriptArgs -join " ")

# Create trigger based on schedule
switch ($Schedule) {
    "Daily" {
        $trigger = New-ScheduledTaskTrigger -Daily -At $Time
        Write-Host "Schedule: Daily at $Time" -ForegroundColor Yellow
    }
    "Weekly" {
        $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $DayOfWeek -At $Time
        Write-Host "Schedule: Weekly on $DayOfWeek at $Time" -ForegroundColor Yellow
    }
    "Monthly" {
        # Monthly trigger requires different approach
        $trigger = New-ScheduledTaskTrigger -Daily -At $Time
        # We'll modify it after creation to be monthly
        Write-Host "Schedule: Monthly on day $DayOfMonth at $Time" -ForegroundColor Yellow
    }
}

# Create task settings
$settings = New-ScheduledTaskSettings

 -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

# Create the principal (user context)
$principal = New-ScheduledTaskPrincipal -UserId $RunAsUser -LogonType ServiceAccount -RunLevel Highest

# Register the scheduled task
try {
    Write-Host "`nCreating scheduled task: $TaskName..." -NoNewline

    $task = Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force

    # For monthly, we need to modify the trigger via XML
    if ($Schedule -eq "Monthly") {
        $xml = [xml](Export-ScheduledTask -TaskName $TaskName)
        $xml.Task.Triggers.CalendarTrigger.ScheduleByMonth.DaysOfMonth.Day = $DayOfMonth.ToString()
        $xml.Task.Triggers.CalendarTrigger.Repetition = $null
        Register-ScheduledTask -TaskName $TaskName -Xml $xml.OuterXml -Force | Out-Null
    }

    Write-Host " Done!" -ForegroundColor Green

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  Task Created Successfully" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan

    Write-Host "Task Name: $TaskName"
    Write-Host "Schedule: $Schedule"
    Write-Host "Next Run: $(Get-ScheduledTask -TaskName $TaskName | Get-ScheduledTaskInfo | Select-Object -ExpandProperty NextRunTime)"
    Write-Host "`nTo view task: Get-ScheduledTask -TaskName '$TaskName'"
    Write-Host "To run now: Start-ScheduledTask -TaskName '$TaskName'"
    Write-Host "To remove: Unregister-ScheduledTask -TaskName '$TaskName' -Confirm:`$false`n"

} catch {
    Write-Host " Failed!" -ForegroundColor Red
    Write-Error "Failed to create scheduled task: $_"
    exit 1
}
