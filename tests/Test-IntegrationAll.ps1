# Integration Test: All v1.8.0 Features
# Comprehensive test of all enhanced features working together

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Integration Test - All Features" -ForegroundColor Cyan
Write-Host "  Version 1.8.0 Enhanced Features" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Setup test environment
$testDir = "C:\Temp\PingNetworksTest"
$historyDir = Join-Path $testDir "History"
$inputFile = ".\sample-data\NetworkData.xlsx"

# Clean up from previous tests
if (Test-Path $testDir) {
    Remove-Item $testDir -Recurse -Force
}
New-Item -Path $testDir -ItemType Directory -Force | Out-Null
New-Item -Path $historyDir -ItemType Directory -Force | Out-Null

$testResults = @{
    TotalTests = 0
    Passed = 0
    Failed = 0
}

function Test-Feature {
    param(
        [string]$Name,
        [scriptblock]$Test
    )

    $script:testResults.TotalTests++
    Write-Host "`n--- Test: $Name ---" -ForegroundColor Yellow

    try {
        $result = & $Test
        if ($result -eq $true) {
            Write-Host "PASSED" -ForegroundColor Green
            $script:testResults.Passed++
        } else {
            Write-Host "FAILED" -ForegroundColor Red
            $script:testResults.Failed++
        }
    }
    catch {
        Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
        $script:testResults.Failed++
    }
}

# Phase 1: Build Scan History
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Phase 1: Building Scan History" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`nCreating 3 baseline scans..." -ForegroundColor White
for ($i = 1; $i -le 3; $i++) {
    Write-Host "  Scan $i/3..." -ForegroundColor Gray
    .\Ping-Networks.ps1 -InputPath $inputFile -OutputDirectory $testDir -HistoryPath $historyDir -MaxPings 3 -Html 2>&1 | Out-Null
    Start-Sleep -Seconds 1
}

Test-Feature "History Files Created" {
    $files = Get-ChildItem -Path $historyDir -Filter "ScanHistory_*.json"
    Write-Host "  Found $($files.Count) history files" -ForegroundColor Gray
    return ($files.Count -ge 3)
}

# Phase 2: Test Retention Policy
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Phase 2: Testing Retention Policy" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`nCreating fake old history files..." -ForegroundColor White
for ($i = 1; $i -le 3; $i++) {
    $daysOld = 40 + ($i * 5)
    $fakeDate = (Get-Date).AddDays(-$daysOld)
    $timestamp = $fakeDate.ToString("yyyyMMdd_HHmmss")
    $filepath = Join-Path $historyDir "ScanHistory_$timestamp.json"

    @{
        ScanMetadata = @{ ScanDate = $fakeDate.ToString("yyyy-MM-dd HH:mm:ss") }
        Results = @()
    } | ConvertTo-Json | Set-Content -Path $filepath

    (Get-Item $filepath).LastWriteTime = $fakeDate
    Write-Host "  Created file aged $daysOld days" -ForegroundColor Gray
}

$filesBefore = (Get-ChildItem -Path $historyDir -Filter "ScanHistory_*.json").Count

Write-Host "`nRunning scan with RetentionDays=30..." -ForegroundColor White
.\Ping-Networks.ps1 -InputPath $inputFile -OutputDirectory $testDir -HistoryPath $historyDir -RetentionDays 30 -MaxPings 2 -Html 2>&1 | Out-Null

Test-Feature "Retention Policy Applied" {
    $filesAfter = Get-ChildItem -Path $historyDir -Filter "ScanHistory_*.json"
    $deleted = $filesBefore - $filesAfter.Count
    Write-Host "  Files deleted: $deleted" -ForegroundColor Gray
    return ($deleted -eq 3)
}

# Phase 3: Test Trend Analysis
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Phase 3: Testing Trend Analysis" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`nGenerating trend report..." -ForegroundColor White
.\Ping-Networks.ps1 -InputPath $inputFile -OutputDirectory $testDir -HistoryPath $historyDir -GenerateTrendReport -TrendDays 30 -MaxPings 2 -Html 2>&1 | Out-Null

Test-Feature "Trend Report Generated" {
    $trendReport = Get-ChildItem -Path $testDir -Filter "TrendReport_*.json" -ErrorAction SilentlyContinue
    return ($null -ne $trendReport)
}

Test-Feature "Trend Data Structure Valid" {
    $trendReport = Get-ChildItem -Path $testDir -Filter "TrendReport_*.json" | Select-Object -First 1
    if (-not $trendReport) { return $false }

    $trendData = Get-Content $trendReport.FullName -Raw | ConvertFrom-Json

    $hasMetadata = $null -ne $trendData.ReportMetadata
    $hasSummary = $null -ne $trendData.Summary
    $hasHostTrends = $null -ne $trendData.HostTrends

    Write-Host "  Hosts tracked: $($trendData.ReportMetadata.UniqueHostsTracked)" -ForegroundColor Gray

    return ($hasMetadata -and $hasSummary -and $hasHostTrends)
}

# Phase 4: Test Alert Thresholds
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Phase 4: Testing Alert Thresholds" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$baselineFile = Get-ChildItem -Path $historyDir -Filter "ScanHistory_*.json" | Sort-Object LastWriteTime | Select-Object -First 1

Write-Host "`nTesting MinChangesToAlert threshold..." -ForegroundColor White
$output = .\Ping-Networks.ps1 -InputPath $inputFile -OutputDirectory $testDir -CompareBaseline $baselineFile.FullName -EmailOnChanges -MinChangesToAlert 999 -MaxPings 2 -Html -Verbose 2>&1

Test-Feature "MinChangesToAlert Threshold Works" {
    $skippedAlert = $output | Select-String "Skipping email alert" -Quiet
    Write-Host "  Found 'Skipping' message: $skippedAlert" -ForegroundColor Gray
    return $skippedAlert
}

# Phase 5: Test Output Formats
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Phase 5: Testing Output Formats" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`nGenerating all output formats..." -ForegroundColor White
.\Ping-Networks.ps1 -InputPath $inputFile -OutputDirectory $testDir -Excel -Html -Json -Xml -Csv -MaxPings 3 2>&1 | Out-Null

Test-Feature "All Output Formats Generated" {
    $excel = Get-ChildItem -Path $testDir -Filter "*.xlsx" -ErrorAction SilentlyContinue
    $html = Get-ChildItem -Path $testDir -Filter "PingResults_*.html" -ErrorAction SilentlyContinue
    $json = Get-ChildItem -Path $testDir -Filter "PingResults_*.json" -ErrorAction SilentlyContinue
    $xml = Get-ChildItem -Path $testDir -Filter "*.xml" -ErrorAction SilentlyContinue
    $csv = Get-ChildItem -Path $testDir -Filter "*.csv" -ErrorAction SilentlyContinue

    Write-Host "  Excel: $(if($excel){'YES'}else{'NO'})" -ForegroundColor $(if($excel){'Green'}else{'Red'})
    Write-Host "  HTML: $(if($html){'YES'}else{'NO'})" -ForegroundColor $(if($html){'Green'}else{'Red'})
    Write-Host "  JSON: $(if($json){'YES'}else{'NO'})" -ForegroundColor $(if($json){'Green'}else{'Red'})
    Write-Host "  XML: $(if($xml){'YES'}else{'NO'})" -ForegroundColor $(if($xml){'Green'}else{'Red'})
    Write-Host "  CSV: $(if($csv){'YES'}else{'NO'})" -ForegroundColor $(if($csv){'Green'}else{'Red'})

    return ($excel -and $html -and $json -and $xml -and $csv)
}

# Final Results
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Integration Test Results" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Total Tests: $($testResults.TotalTests)" -ForegroundColor White
Write-Host "Passed: $($testResults.Passed)" -ForegroundColor Green
Write-Host "Failed: $($testResults.Failed)" -ForegroundColor Red

$successRate = [math]::Round(($testResults.Passed / $testResults.TotalTests) * 100, 1)
Write-Host "`nSuccess Rate: $successRate%" -ForegroundColor $(
    if ($successRate -ge 90) { "Green" }
    elseif ($successRate -ge 70) { "Yellow" }
    else { "Red" }
)

if ($testResults.Failed -eq 0) {
    Write-Host "`nALL TESTS PASSED!" -ForegroundColor Green
    Write-Host "Version 1.8.0 enhanced features are working correctly." -ForegroundColor Green
} else {
    Write-Host "`nSOME TESTS FAILED" -ForegroundColor Yellow
    Write-Host "Review the output above for details." -ForegroundColor Yellow
}

Write-Host "`nTest artifacts saved to: $testDir" -ForegroundColor White
Write-Host "Cleanup test directory? (Y/N): " -ForegroundColor Yellow -NoNewline
$cleanup = Read-Host
if ($cleanup -eq 'Y' -or $cleanup -eq 'y') {
    Remove-Item $testDir -Recurse -Force
    Write-Host "Test directory cleaned up" -ForegroundColor Green
}
