# Run-Tests.ps1
# Main test runner for Ping-Networks project
# Executes all test suites and reports results

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$testResults = @()
$totalTests = 0
$passedTests = 0
$failedTests = 0

# Test suite configuration
$testSuites = @(
    @{ Name = "Core Functions"; Script = "Test-CoreFunctions.ps1" }
    @{ Name = "Input Formats"; Script = "Test-InputFormats.ps1" }
    @{ Name = "Output Formats"; Script = "Test-OutputFormats.ps1" }
    @{ Name = "End-to-End"; Script = "Test-EndToEnd.ps1" }
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Ping-Networks Test Suite" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$startTime = Get-Date

foreach ($suite in $testSuites) {
    Write-Host "Running: $($suite.Name)" -ForegroundColor Yellow
    Write-Host ("=" * 40) -ForegroundColor Yellow

    $testScript = Join-Path $PSScriptRoot $suite.Script

    if (-not (Test-Path $testScript)) {
        Write-Host "  [SKIP] Test script not found: $testScript" -ForegroundColor DarkGray
        continue
    }

    try {
        # Execute test script and capture results
        $result = & $testScript

        $testResults += [PSCustomObject]@{
            Suite = $suite.Name
            Passed = $result.Passed
            Failed = $result.Failed
            Total = $result.Total
            Duration = $result.Duration
        }

        $totalTests += $result.Total
        $passedTests += $result.Passed
        $failedTests += $result.Failed

        if ($result.Failed -eq 0) {
            Write-Host "  [PASS] All $($result.Passed) tests passed`n" -ForegroundColor Green
        } else {
            Write-Host "  [FAIL] $($result.Failed) of $($result.Total) tests failed`n" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "  [ERROR] Test suite crashed: $_`n" -ForegroundColor Red
        $failedTests++
        $totalTests++
    }
}

$endTime = Get-Date
$totalDuration = $endTime - $startTime

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Test Summary" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Total Tests:  $totalTests"
Write-Host "Passed:       $passedTests" -ForegroundColor Green
Write-Host "Failed:       $failedTests" -ForegroundColor $(if ($failedTests -eq 0) { "Green" } else { "Red" })
Write-Host "Duration:     $($totalDuration.TotalSeconds) seconds"

if ($testResults.Count -gt 0) {
    Write-Host "`nDetailed Results:" -ForegroundColor Cyan
    $testResults | Format-Table -AutoSize
}

# Exit with appropriate code
if ($failedTests -eq 0) {
    Write-Host "`nALL TESTS PASSED" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nTESTS FAILED" -ForegroundColor Red
    exit 1
}
