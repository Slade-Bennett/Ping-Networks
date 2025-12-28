# Test Script: Trend Analysis
# Tests trend reporting and availability statistics

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Testing Trend Analysis Features" -ForegroundColor Cyan
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

Write-Host "Test 1: Create multiple scans to build history" -ForegroundColor Yellow
Write-Host "Running 5 scans with 2-second intervals..." -ForegroundColor Gray

for ($i = 1; $i -le 5; $i++) {
    Write-Host "`nScan $i of 5..." -ForegroundColor White
    .\Ping-Networks.ps1 -InputPath $inputFile `
        -OutputDirectory $testDir `
        -HistoryPath $historyDir `
        -MaxPings 3 -Html -Quiet

    if ($i -lt 5) {
        Write-Host "  Waiting 2 seconds before next scan..." -ForegroundColor Gray
        Start-Sleep -Seconds 2
    }
}

# Verify history files created
$historyFiles = Get-ChildItem -Path $historyDir -Filter "ScanHistory_*.json"
Write-Host "`nHistory files created: $($historyFiles.Count)" -ForegroundColor White

if ($historyFiles.Count -lt 2) {
    Write-Host "✗ FAILED: Need at least 2 scans for trend analysis" -ForegroundColor Red
    exit 1
}

foreach ($file in $historyFiles | Sort-Object LastWriteTime) {
    Write-Host "  - $($file.Name)" -ForegroundColor Gray
}

Write-Host "`nTest 2: Generate trend report (30-day analysis)" -ForegroundColor Yellow
Write-Host "Running trend analysis..." -ForegroundColor Gray

.\Ping-Networks.ps1 -InputPath $inputFile `
    -OutputDirectory $testDir `
    -HistoryPath $historyDir `
    -GenerateTrendReport `
    -TrendDays 30 `
    -MaxPings 2 -Html

# Check for trend report
$trendReport = Get-ChildItem -Path $testDir -Filter "TrendReport_*.json" | Select-Object -First 1

if ($trendReport) {
    Write-Host "`n✓ Trend report created: $($trendReport.Name)" -ForegroundColor Green

    # Load and analyze trend report
    Write-Host "`nAnalyzing trend report..." -ForegroundColor Yellow
    $trendData = Get-Content $trendReport.FullName -Raw | ConvertFrom-Json

    Write-Host "`nReport Metadata:" -ForegroundColor Cyan
    Write-Host "  Generated: $($trendData.ReportMetadata.GeneratedDate)" -ForegroundColor White
    Write-Host "  Analysis Period: $($trendData.ReportMetadata.TrendPeriodDays) days" -ForegroundColor White
    Write-Host "  Scans Analyzed: $($trendData.ReportMetadata.TotalScansAnalyzed)" -ForegroundColor White
    Write-Host "  Hosts Tracked: $($trendData.ReportMetadata.UniqueHostsTracked)" -ForegroundColor White

    Write-Host "`nSummary Statistics:" -ForegroundColor Cyan
    Write-Host "  Always Reachable (100%): $($trendData.Summary.AlwaysReachable)" -ForegroundColor Green
    Write-Host "  Mostly Reachable (80-99%): $($trendData.Summary.MostlyReachable)" -ForegroundColor Yellow
    Write-Host "  Intermittent (1-79%): $($trendData.Summary.Intermittent)" -ForegroundColor Magenta
    Write-Host "  Always Unreachable (0%): $($trendData.Summary.AlwaysUnreachable)" -ForegroundColor Red
    Write-Host "  Average Uptime: $($trendData.Summary.AvgUptimePercentage)%" -ForegroundColor White

    # Show sample host trends
    Write-Host "`nSample Host Trends (Top 5 by uptime):" -ForegroundColor Cyan
    $topHosts = $trendData.HostTrends | Select-Object -First 5
    foreach ($host in $topHosts) {
        Write-Host "`n  Host: $($host.Host)" -ForegroundColor White
        Write-Host "    Network: $($host.Network)" -ForegroundColor Gray
        Write-Host "    Uptime: $($host.UptimePercentage)%" -ForegroundColor $(
            if ($host.UptimePercentage -eq 100) { "Green" }
            elseif ($host.UptimePercentage -ge 80) { "Yellow" }
            elseif ($host.UptimePercentage -gt 0) { "Magenta" }
            else { "Red" }
        )
        Write-Host "    Scans: $($host.ReachableCount)/$($host.TotalScans) reachable" -ForegroundColor Gray
        if ($host.AvgResponseTime -gt 0) {
            Write-Host "    Avg Response: $($host.AvgResponseTime) ms" -ForegroundColor Gray
        }
    }

    # Validation checks
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  Validation Checks" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan

    $checks = 0
    $passed = 0

    # Check 1: Total scans analyzed should match history count
    $checks++
    if ($trendData.ReportMetadata.TotalScansAnalyzed -eq $historyFiles.Count) {
        Write-Host "✓ Scan count matches ($($historyFiles.Count))" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "✗ Scan count mismatch: expected $($historyFiles.Count), got $($trendData.ReportMetadata.TotalScansAnalyzed)" -ForegroundColor Red
    }

    # Check 2: Host trends should exist
    $checks++
    if ($trendData.HostTrends.Count -gt 0) {
        Write-Host "✓ Host trends generated ($($trendData.HostTrends.Count) hosts)" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "✗ No host trends found" -ForegroundColor Red
    }

    # Check 3: Each host should have valid uptime percentage
    $checks++
    $invalidUptimes = $trendData.HostTrends | Where-Object { $_.UptimePercentage -lt 0 -or $_.UptimePercentage -gt 100 }
    if ($invalidUptimes.Count -eq 0) {
        Write-Host "✓ All uptime percentages valid (0-100%)" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "✗ Found $($invalidUptimes.Count) invalid uptime percentages" -ForegroundColor Red
    }

    # Check 4: Summary categories should sum to total hosts
    $checks++
    $categoriesSum = $trendData.Summary.AlwaysReachable + $trendData.Summary.MostlyReachable +
                     $trendData.Summary.Intermittent + $trendData.Summary.AlwaysUnreachable
    if ($categoriesSum -eq $trendData.ReportMetadata.UniqueHostsTracked) {
        Write-Host "✓ Category counts sum correctly ($categoriesSum)" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "✗ Category sum mismatch: $categoriesSum vs $($trendData.ReportMetadata.UniqueHostsTracked)" -ForegroundColor Red
    }

    Write-Host "`nTest Result: $passed/$checks checks passed" -ForegroundColor $(if ($passed -eq $checks) { "Green" } else { "Yellow" })

} else {
    Write-Host "`n✗ FAILED: No trend report created" -ForegroundColor Red
}

# Check if trend report also saved to history
$historyTrendReport = Get-ChildItem -Path $historyDir -Filter "TrendReport_*.json" -ErrorAction SilentlyContinue
if ($historyTrendReport) {
    Write-Host "✓ Trend report also saved to history directory" -ForegroundColor Green
} else {
    Write-Host "✗ Trend report not found in history directory" -ForegroundColor Yellow
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Trend Analysis Test Complete" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Test directory: $testDir" -ForegroundColor White
Write-Host "`nCleanup test directory? (Y/N): " -ForegroundColor Yellow -NoNewline
$cleanup = Read-Host
if ($cleanup -eq 'Y' -or $cleanup -eq 'y') {
    Remove-Item $testDir -Recurse -Force
    Write-Host "✓ Test directory cleaned up" -ForegroundColor Green
}
