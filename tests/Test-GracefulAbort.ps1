# Test Script: Graceful Abort
# Tests Ctrl+C handling and partial result saving
# NOTE: This test requires manual intervention (pressing Ctrl+C)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Testing Graceful Abort Features" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Setup test environment
$testDir = "C:\Temp\PingNetworksTest"
$inputFile = ".\sample-data\NetworkData.xlsx"

# Clean up from previous tests
if (Test-Path $testDir) {
    Remove-Item $testDir -Recurse -Force
}
New-Item -Path $testDir -ItemType Directory -Force | Out-Null

Write-Host "This test requires MANUAL intervention!" -ForegroundColor Yellow
Write-Host "`nTest Procedure:" -ForegroundColor Cyan
Write-Host "1. A network scan will start" -ForegroundColor White
Write-Host "2. Wait for 'Scanned: X hosts' to show some progress" -ForegroundColor White
Write-Host "3. Press Ctrl+C to interrupt the scan" -ForegroundColor White
Write-Host "4. Check that partial results are saved" -ForegroundColor White

Write-Host "`nPress ENTER to start the scan..." -ForegroundColor Yellow
Read-Host

Write-Host "`nStarting scan - Press Ctrl+C after you see some hosts scanned!`n" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Gray

try {
    # Run a scan without MaxPings to ensure it takes longer
    .\Ping-Networks.ps1 -InputPath $inputFile `
        -OutputDirectory $testDir `
        -Excel -Html -Json `
        -Throttle 10 `
        -Verbose

    Write-Host "`n✗ Scan completed normally (not interrupted)" -ForegroundColor Yellow
    Write-Host "  This means you didn't press Ctrl+C" -ForegroundColor Gray
    $interrupted = $false
}
catch {
    Write-Host "`n✓ Scan was interrupted" -ForegroundColor Green
    $interrupted = $true
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Checking Results" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Check what files were created
$excelFiles = Get-ChildItem -Path $testDir -Filter "*.xlsx" -ErrorAction SilentlyContinue
$htmlFiles = Get-ChildItem -Path $testDir -Filter "*.html" -ErrorAction SilentlyContinue
$jsonFiles = Get-ChildItem -Path $testDir -Filter "PingResults_*.json" -ErrorAction SilentlyContinue

Write-Host "Files created:" -ForegroundColor Yellow
if ($excelFiles) {
    Write-Host "  ✓ Excel: $($excelFiles.Name)" -ForegroundColor Green
} else {
    Write-Host "  ✗ No Excel file" -ForegroundColor Red
}

if ($htmlFiles) {
    Write-Host "  ✓ HTML: $($htmlFiles.Name)" -ForegroundColor Green
} else {
    Write-Host "  ✗ No HTML file" -ForegroundColor Red
}

if ($jsonFiles) {
    Write-Host "  ✓ JSON: $($jsonFiles.Name)" -ForegroundColor Green

    # Analyze JSON to see how many hosts were scanned
    $jsonContent = Get-Content $jsonFiles[0].FullName -Raw | ConvertFrom-Json
    $hostsScanned = $jsonContent.Results.Count
    Write-Host "`nPartial Results:" -ForegroundColor Cyan
    Write-Host "  Hosts scanned: $hostsScanned" -ForegroundColor White

    if ($hostsScanned -gt 0) {
        Write-Host "  ✓ Partial data was saved!" -ForegroundColor Green
    } else {
        Write-Host "  ✗ No host data in results" -ForegroundColor Red
    }
} else {
    Write-Host "  ✗ No JSON file" -ForegroundColor Red
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Test Summary" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

if ($excelFiles -and $htmlFiles -and $jsonFiles) {
    Write-Host "✓ SUCCESS: All output formats generated" -ForegroundColor Green
    if ($interrupted) {
        Write-Host "✓ Graceful abort worked - partial results saved" -ForegroundColor Green
    } else {
        Write-Host "! Note: Scan completed normally (wasn't interrupted)" -ForegroundColor Yellow
    }
} else {
    Write-Host "✗ Some output files missing" -ForegroundColor Yellow
}

Write-Host "`nManual Verification:" -ForegroundColor Yellow
Write-Host "1. Open the Excel file and check if data exists: $testDir" -ForegroundColor White
Write-Host "2. Open the HTML file in a browser to view results" -ForegroundColor White
Write-Host "3. Verify JSON contains the Results array with host data" -ForegroundColor White

Write-Host "`nOpen output directory? (Y/N): " -ForegroundColor Yellow -NoNewline
$open = Read-Host
if ($open -eq 'Y' -or $open -eq 'y') {
    Start-Process explorer.exe -ArgumentList $testDir
}

Write-Host "`nCleanup test directory? (Y/N): " -ForegroundColor Yellow -NoNewline
$cleanup = Read-Host
if ($cleanup -eq 'Y' -or $cleanup -eq 'y') {
    Remove-Item $testDir -Recurse -Force
    Write-Host "✓ Test directory cleaned up" -ForegroundColor Green
}
