# Test Script: Alert Thresholds
# Tests configurable alert threshold features

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Testing Alert Threshold Features" -ForegroundColor Cyan
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

Write-Host "Test 1: Create baseline scan" -ForegroundColor Yellow
Write-Host "Running baseline scan with MaxPings 3..." -ForegroundColor Gray
.\Ping-Networks.ps1 -InputPath $inputFile `
    -OutputDirectory $testDir `
    -HistoryPath $historyDir `
    -MaxPings 3 -Html -Verbose

# Wait a moment and get baseline file
Start-Sleep -Seconds 2
$baselineFile = Get-ChildItem -Path $historyDir -Filter "ScanHistory_*.json" | Select-Object -First 1

if ($baselineFile) {
    Write-Host "✓ Baseline created: $($baselineFile.Name)" -ForegroundColor Green
} else {
    Write-Host "✗ FAILED: No baseline file created" -ForegroundColor Red
    exit 1
}

Write-Host "`nTest 2: MinChangesToAlert - Should NOT alert (threshold: 5)" -ForegroundColor Yellow
Write-Host "Simulating scan with minimal changes..." -ForegroundColor Gray
.\Ping-Networks.ps1 -InputPath $inputFile `
    -OutputDirectory $testDir `
    -CompareBaseline $baselineFile.FullName `
    -EmailOnChanges `
    -MinChangesToAlert 5 `
    -MaxPings 3 -Html -Verbose

Write-Host "`nCheck: Did you see 'Skipping email alert' messages in verbose output?" -ForegroundColor Cyan
Write-Host "Expected: YES (changes below threshold)" -ForegroundColor Gray

Write-Host "`nTest 3: MinChangesToAlert - Should alert (threshold: 1)" -ForegroundColor Yellow
Write-Host "Same scan but with threshold = 1..." -ForegroundColor Gray
.\Ping-Networks.ps1 -InputPath $inputFile `
    -OutputDirectory $testDir `
    -CompareBaseline $baselineFile.FullName `
    -EmailOnChanges `
    -MinChangesToAlert 1 `
    -MaxPings 3 -Html -Verbose

Write-Host "`nCheck: Alert threshold logic should be different" -ForegroundColor Cyan

Write-Host "`nTest 4: MinChangePercentage - 50% threshold" -ForegroundColor Yellow
Write-Host "Testing percentage-based threshold..." -ForegroundColor Gray
.\Ping-Networks.ps1 -InputPath $inputFile `
    -OutputDirectory $testDir `
    -CompareBaseline $baselineFile.FullName `
    -EmailOnChanges `
    -MinChangePercentage 50 `
    -MaxPings 3 -Html -Verbose

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Alert Threshold Tests Complete" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Review Results:" -ForegroundColor Yellow
Write-Host "1. Check verbose output for 'Skipping email alert' messages" -ForegroundColor White
Write-Host "2. Verify threshold logic worked correctly" -ForegroundColor White
Write-Host "3. Test directory: $testDir" -ForegroundColor White

Write-Host "`nCleanup test directory? (Y/N): " -ForegroundColor Yellow -NoNewline
$cleanup = Read-Host
if ($cleanup -eq 'Y' -or $cleanup -eq 'y') {
    Remove-Item $testDir -Recurse -Force
    Write-Host "✓ Test directory cleaned up" -ForegroundColor Green
}
