# Master Test Runner
# Runs all test scripts for Ping-Networks v1.8.0

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Ping-Networks v1.8.0" -ForegroundColor Cyan
Write-Host "  Master Test Suite" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$testScripts = @(
    @{
        Name = "Alert Thresholds"
        Script = "Test-AlertThresholds.ps1"
        Description = "Tests configurable alert threshold features"
        Duration = "~2 minutes"
    },
    @{
        Name = "Retention Policy"
        Script = "Test-RetentionPolicy.ps1"
        Description = "Tests automatic cleanup of old scan history"
        Duration = "~1 minute"
    },
    @{
        Name = "Trend Analysis"
        Script = "Test-TrendAnalysis.ps1"
        Description = "Tests trend reporting and availability statistics"
        Duration = "~3 minutes"
    },
    @{
        Name = "Graceful Abort"
        Script = "Test-GracefulAbort.ps1"
        Description = "Tests Ctrl+C handling (requires manual intervention)"
        Duration = "~1 minute + manual"
    },
    @{
        Name = "Integration (All Features)"
        Script = "Test-IntegrationAll.ps1"
        Description = "Comprehensive test of all v1.8.0 features"
        Duration = "~5 minutes"
    }
)

Write-Host "Available Tests:" -ForegroundColor Yellow
for ($i = 0; $i -lt $testScripts.Count; $i++) {
    $test = $testScripts[$i]
    Write-Host "`n$($i + 1). $($test.Name)" -ForegroundColor White
    Write-Host "   Script: $($test.Script)" -ForegroundColor Gray
    Write-Host "   $($test.Description)" -ForegroundColor Gray
    Write-Host "   Estimated duration: $($test.Duration)" -ForegroundColor Gray
}

Write-Host "`n========================================`n" -ForegroundColor Cyan

# Menu selection
Write-Host "Select test to run:" -ForegroundColor Yellow
Write-Host "  1-5: Run individual test" -ForegroundColor White
Write-Host "  A: Run ALL tests (automated only)" -ForegroundColor White
Write-Host "  F: Run FULL suite (including manual tests)" -ForegroundColor White
Write-Host "  Q: Quit" -ForegroundColor White

Write-Host "`nYour choice: " -ForegroundColor Yellow -NoNewline
$choice = Read-Host

switch ($choice.ToUpper()) {
    'Q' {
        Write-Host "Exiting..." -ForegroundColor Gray
        exit
    }
    'A' {
        Write-Host "`nRunning automated tests only (skipping manual tests)...`n" -ForegroundColor Cyan
        $testsToRun = $testScripts | Where-Object { $_.Name -ne "Graceful Abort" }

        foreach ($test in $testsToRun) {
            Write-Host "`n========================================" -ForegroundColor Cyan
            Write-Host "Running: $($test.Name)" -ForegroundColor Cyan
            Write-Host "========================================`n" -ForegroundColor Cyan

            $scriptPath = Join-Path $PSScriptRoot $test.Script
            & $scriptPath
            Write-Host "`nPress ENTER to continue to next test..." -ForegroundColor Yellow
            Read-Host
        }

        Write-Host "`n✓ All automated tests completed!" -ForegroundColor Green
    }
    'F' {
        Write-Host "`nRunning FULL test suite (including manual tests)...`n" -ForegroundColor Cyan

        foreach ($test in $testScripts) {
            Write-Host "`n========================================" -ForegroundColor Cyan
            Write-Host "Running: $($test.Name)" -ForegroundColor Cyan
            Write-Host "========================================`n" -ForegroundColor Cyan

            if ($test.Name -eq "Graceful Abort") {
                Write-Host "⚠ This test requires manual intervention (Ctrl+C)" -ForegroundColor Yellow
                Write-Host "Press ENTER to start, or S to skip..." -ForegroundColor Yellow -NoNewline
                $skip = Read-Host
                if ($skip.ToUpper() -eq 'S') {
                    Write-Host "Skipping manual test..." -ForegroundColor Gray
                    continue
                }
            }

            $scriptPath = Join-Path $PSScriptRoot $test.Script
            & $scriptPath
            Write-Host "`nPress ENTER to continue to next test..." -ForegroundColor Yellow
            Read-Host
        }

        Write-Host "`n✓ Full test suite completed!" -ForegroundColor Green
    }
    {$_ -match '^[1-5]$'} {
        $index = [int]$choice - 1
        $test = $testScripts[$index]

        Write-Host "`nRunning: $($test.Name)`n" -ForegroundColor Cyan

        $scriptPath = Join-Path $PSScriptRoot $test.Script
        & $scriptPath

        Write-Host "`n✓ Test completed!" -ForegroundColor Green
    }
    default {
        Write-Host "Invalid selection. Exiting..." -ForegroundColor Red
    }
}

Write-Host "`nThank you for testing Ping-Networks v1.8.0!" -ForegroundColor Cyan
