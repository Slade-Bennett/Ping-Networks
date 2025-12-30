# Run-UnitTests.ps1
# Master test runner for all unit and functional tests

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "  Ping-Networks - Unit Test Suite Runner" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

$testFiles = @(
    "Test-ParseNetworkInput.ps1",
    "Test-GetUsableHosts.ps1",
    "Test-GetIPRange.ps1",
    "Test-InvokeHostPing.ps1",
    "Test-Integration-Quick.ps1"
)

$totalPassed = 0
$totalFailed = 0
$testResults = @()

foreach ($testFile in $testFiles) {
    $testPath = Join-Path $PSScriptRoot $testFile

    if (-not (Test-Path $testPath)) {
        Write-Host "⚠ Test file not found: $testFile" -ForegroundColor Yellow
        continue
    }

    Write-Host "`nRunning: $testFile" -ForegroundColor Magenta
    Write-Host ("=" * 50) -ForegroundColor Gray

    try {
        $output = & $testPath 2>&1
        $exitCode = $LASTEXITCODE

        if ($exitCode -eq 0) {
            $totalPassed++
            $testResults += [PSCustomObject]@{
                TestFile = $testFile
                Status = "PASS"
                ExitCode = $exitCode
            }
            Write-Host "[PASS] $testFile" -ForegroundColor Green
        } else {
            $totalFailed++
            $testResults += [PSCustomObject]@{
                TestFile = $testFile
                Status = "FAIL"
                ExitCode = $exitCode
            }
            Write-Host "[FAIL] $testFile" -ForegroundColor Red
        }
    }
    catch {
        $totalFailed++
        $testResults += [PSCustomObject]@{
            TestFile = $testFile
            Status = "ERROR"
            ExitCode = -1
        }
        Write-Host "[ERROR] $testFile - $_" -ForegroundColor Red
    }
}

# Summary
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "  Test Suite Summary" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Total Test Files: $($testFiles.Count)" -ForegroundColor White
Write-Host "Passed:           $totalPassed" -ForegroundColor Green
Write-Host "Failed:           $totalFailed" -ForegroundColor $(if ($totalFailed -gt 0) { "Red" } else { "Green" })

Write-Host "`nDetailed Results:" -ForegroundColor Cyan
$testResults | Format-Table -AutoSize

if ($totalFailed -eq 0) {
    Write-Host "`nAll test suites passed!" -ForegroundColor Green
    Write-Host "`nTest Coverage:" -ForegroundColor Cyan
    Write-Host "  - ConvertFrom-NetworkInput: 10 tests" -ForegroundColor White
    Write-Host "  - Get-UsableHosts:          12 tests" -ForegroundColor White
    Write-Host "  - Get-IPRange:              10 tests" -ForegroundColor White
    Write-Host "  - Invoke-HostPing:           8 tests" -ForegroundColor White
    Write-Host "  - Integration:               5 tests" -ForegroundColor White
    Write-Host "  ---------------------------------------" -ForegroundColor Gray
    Write-Host "  Total:                      45 tests`n" -ForegroundColor White
    exit 0
} else {
    Write-Host "`nSome test suites failed!" -ForegroundColor Red
    exit 1
}
