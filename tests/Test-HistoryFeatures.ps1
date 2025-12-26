# Test-HistoryFeatures.ps1
# Tests for scan history and baseline comparison features

[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'
$testsPassed = 0
$testsFailed = 0
$startTime = Get-Date

$projectRoot = Split-Path $PSScriptRoot -Parent
$mainScript = Join-Path $projectRoot "Ping-Networks.ps1"
$testHistoryDir = Join-Path $PSScriptRoot "test-history"
$testOutputDir = Join-Path $PSScriptRoot "test-output"

# Cleanup function
function Cleanup-TestDirectories {
    if (Test-Path $testHistoryDir) {
        Remove-Item $testHistoryDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path $testOutputDir) {
        Remove-Item $testOutputDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Cleanup before tests
Cleanup-TestDirectories

function Test-HistorySaving {
    param([string]$Name)

    try {
        Write-Host "  Testing: $Name" -ForegroundColor Yellow

        # Run scan with history saving
        $output = & $mainScript `
            -InputPath (Join-Path $projectRoot "sample-data\NetworkData.txt") `
            -HistoryPath $testHistoryDir `
            -MaxPings 3 `
            -Verbose 2>&1 | Out-String

        # Check if history directory was created
        if (-not (Test-Path $testHistoryDir)) {
            Write-Host "  [FAIL] $Name - History directory not created" -ForegroundColor Red
            $script:testsFailed++
            return
        }

        # Check if history file exists
        $historyFiles = Get-ChildItem -Path $testHistoryDir -Filter "ScanHistory_*.json"
        if ($historyFiles.Count -eq 0) {
            Write-Host "  [FAIL] $Name - No history file created" -ForegroundColor Red
            $script:testsFailed++
            return
        }

        # Verify history file content
        $historyContent = Get-Content -Path $historyFiles[0].FullName -Raw | ConvertFrom-Json
        if (-not $historyContent.ScanMetadata) {
            Write-Host "  [FAIL] $Name - History file missing ScanMetadata" -ForegroundColor Red
            $script:testsFailed++
            return
        }

        if (-not $historyContent.Results) {
            Write-Host "  [FAIL] $Name - History file missing Results" -ForegroundColor Red
            $script:testsFailed++
            return
        }

        Write-Host "  [PASS] $Name" -ForegroundColor Green
        $script:testsPassed++
    }
    catch {
        Write-Host "  [FAIL] $Name - Exception: $_" -ForegroundColor Red
        $script:testsFailed++
    }
}

function Test-BaselineComparison {
    param([string]$Name)

    try {
        Write-Host "  Testing: $Name" -ForegroundColor Yellow

        # Get the baseline file from previous test
        $historyFiles = Get-ChildItem -Path $testHistoryDir -Filter "ScanHistory_*.json"
        if ($historyFiles.Count -eq 0) {
            Write-Host "  [FAIL] $Name - No baseline file available" -ForegroundColor Red
            $script:testsFailed++
            return
        }

        $baselineFile = $historyFiles[0].FullName

        # Run scan with baseline comparison
        $output = & $mainScript `
            -InputPath (Join-Path $projectRoot "sample-data\NetworkData.txt") `
            -CompareBaseline $baselineFile `
            -OutputDirectory $testOutputDir `
            -MaxPings 3 `
            -Verbose 2>&1 | Out-String

        # Check if change report was created
        $changeReportFiles = Get-ChildItem -Path $testOutputDir -Filter "ChangeReport_*.json" -ErrorAction SilentlyContinue
        if ($changeReportFiles.Count -eq 0) {
            Write-Host "  [FAIL] $Name - No change report created" -ForegroundColor Red
            $script:testsFailed++
            return
        }

        # Verify change report content
        $changeReport = Get-Content -Path $changeReportFiles[0].FullName -Raw | ConvertFrom-Json
        if (-not $changeReport.ComparisonMetadata) {
            Write-Host "  [FAIL] $Name - Change report missing ComparisonMetadata" -ForegroundColor Red
            $script:testsFailed++
            return
        }

        if (-not $changeReport.Summary) {
            Write-Host "  [FAIL] $Name - Change report missing Summary" -ForegroundColor Red
            $script:testsFailed++
            return
        }

        Write-Host "  [PASS] $Name" -ForegroundColor Green
        $script:testsPassed++
    }
    catch {
        Write-Host "  [FAIL] $Name - Exception: $_" -ForegroundColor Red
        $script:testsFailed++
    }
}

function Test-HistoryWithMultipleFormats {
    param([string]$Name)

    try {
        Write-Host "  Testing: $Name" -ForegroundColor Yellow

        # Cleanup from previous test
        if (Test-Path $testHistoryDir) {
            Remove-Item $testHistoryDir -Recurse -Force
        }

        # Run scan with history and multiple output formats
        $output = & $mainScript `
            -InputPath (Join-Path $projectRoot "sample-data\NetworkData.csv") `
            -HistoryPath $testHistoryDir `
            -OutputDirectory $testOutputDir `
            -Html -Json `
            -MaxPings 2 `
            -Verbose 2>&1 | Out-String

        # Verify history was saved
        $historyFiles = Get-ChildItem -Path $testHistoryDir -Filter "ScanHistory_*.json" -ErrorAction SilentlyContinue
        if ($historyFiles.Count -eq 0) {
            Write-Host "  [FAIL] $Name - History not saved" -ForegroundColor Red
            $script:testsFailed++
            return
        }

        # Verify output formats were created
        $htmlFiles = Get-ChildItem -Path $testOutputDir -Filter "*.html" -ErrorAction SilentlyContinue
        $jsonFiles = Get-ChildItem -Path $testOutputDir -Filter "PingResults_*.json" -ErrorAction SilentlyContinue

        if ($htmlFiles.Count -eq 0) {
            Write-Host "  [FAIL] $Name - HTML output not created" -ForegroundColor Red
            $script:testsFailed++
            return
        }

        if ($jsonFiles.Count -eq 0) {
            Write-Host "  [FAIL] $Name - JSON output not created" -ForegroundColor Red
            $script:testsFailed++
            return
        }

        Write-Host "  [PASS] $Name" -ForegroundColor Green
        $script:testsPassed++
    }
    catch {
        Write-Host "  [FAIL] $Name - Exception: $_" -ForegroundColor Red
        $script:testsFailed++
    }
}

# Run tests
Write-Host "`nTesting Scan History Features" -ForegroundColor Cyan
Write-Host "=" * 40 -ForegroundColor Cyan

Test-HistorySaving -Name "History saving to directory"
Test-BaselineComparison -Name "Baseline comparison with change detection"
Test-HistoryWithMultipleFormats -Name "History with multiple output formats"

# Cleanup after tests
Cleanup-TestDirectories

# Return results
$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds

return [PSCustomObject]@{
    Passed = $testsPassed
    Failed = $testsFailed
    Total = $testsPassed + $testsFailed
    Duration = [math]::Round($duration, 2)
}
