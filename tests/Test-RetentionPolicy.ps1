# Test Script: Retention Policy
# Tests automatic cleanup of old scan history files

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Testing Retention Policy Features" -ForegroundColor Cyan
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

Write-Host "Test 1: Create multiple history files with different dates" -ForegroundColor Yellow

# Create fake old history files
Write-Host "Creating 5 fake history files with different ages..." -ForegroundColor Gray

for ($i = 1; $i -le 5; $i++) {
    $daysOld = $i * 10  # 10, 20, 30, 40, 50 days old
    $fakeDate = (Get-Date).AddDays(-$daysOld)
    $timestamp = $fakeDate.ToString("yyyyMMdd_HHmmss")
    $filename = "ScanHistory_$timestamp.json"
    $filepath = Join-Path $historyDir $filename

    # Create minimal JSON content
    $fakeData = @{
        ScanMetadata = @{
            ScanDate = $fakeDate.ToString("yyyy-MM-dd HH:mm:ss")
        }
        Results = @()
    } | ConvertTo-Json

    $fakeData | Set-Content -Path $filepath

    # Set the file's LastWriteTime to match the fake date
    (Get-Item $filepath).LastWriteTime = $fakeDate

    Write-Host "  Created: $filename (Age: $daysOld days)" -ForegroundColor Gray
}

# Also create some fake change reports
Write-Host "`nCreating 3 fake change report files..." -ForegroundColor Gray
for ($i = 1; $i -le 3; $i++) {
    $daysOld = $i * 15  # 15, 30, 45 days old
    $fakeDate = (Get-Date).AddDays(-$daysOld)
    $timestamp = $fakeDate.ToString("yyyyMMdd_HHmmss")
    $filename = "ChangeReport_$timestamp.json"
    $filepath = Join-Path $historyDir $filename

    $fakeData = @{
        ComparisonMetadata = @{
            CurrentScanDate = $fakeDate.ToString("yyyy-MM-dd HH:mm:ss")
        }
    } | ConvertTo-Json

    $fakeData | Set-Content -Path $filepath
    (Get-Item $filepath).LastWriteTime = $fakeDate

    Write-Host "  Created: $filename (Age: $daysOld days)" -ForegroundColor Gray
}

Write-Host "`nBefore retention policy:" -ForegroundColor Yellow
$filesBefore = Get-ChildItem $historyDir | Sort-Object LastWriteTime
Write-Host "  Total files: $($filesBefore.Count)" -ForegroundColor White
foreach ($file in $filesBefore) {
    $age = ((Get-Date) - $file.LastWriteTime).Days
    Write-Host "  - $($file.Name) (Age: $age days)" -ForegroundColor Gray
}

Write-Host "`nTest 2: Run scan with RetentionDays = 25" -ForegroundColor Yellow
Write-Host "Expected: Files older than 25 days should be deleted" -ForegroundColor Gray
Write-Host "Running scan..." -ForegroundColor Gray

.\Ping-Networks.ps1 -InputPath $inputFile `
    -OutputDirectory $testDir `
    -HistoryPath $historyDir `
    -RetentionDays 25 `
    -MaxPings 2 -Html

Write-Host "`nAfter retention policy:" -ForegroundColor Yellow
$filesAfter = Get-ChildItem $historyDir | Sort-Object LastWriteTime
Write-Host "  Total files: $($filesAfter.Count)" -ForegroundColor White
foreach ($file in $filesAfter) {
    $age = ((Get-Date) - $file.LastWriteTime).Days
    $color = if ($age -gt 25) { "Red" } else { "Green" }
    Write-Host "  - $($file.Name) (Age: $age days)" -ForegroundColor $color
}

# Verify results
$deletedCount = $filesBefore.Count - $filesAfter.Count
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Retention Policy Test Results" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Files before: $($filesBefore.Count)" -ForegroundColor White
Write-Host "Files after: $($filesAfter.Count)" -ForegroundColor White
Write-Host "Files deleted: $deletedCount" -ForegroundColor Yellow

# Expected: Should delete files older than 25 days
# We created files at: 10, 20, 30, 40, 50 days (5 history files)
# And: 15, 30, 45 days (3 change reports)
# Expected deletions: 30, 40, 50, 30, 45 = 5 files
$expectedDeletions = 5

if ($deletedCount -eq $expectedDeletions) {
    Write-Host "`n✓ SUCCESS: Retention policy worked correctly!" -ForegroundColor Green
    Write-Host "  Expected $expectedDeletions deletions, got $deletedCount" -ForegroundColor Green
} else {
    Write-Host "`n✗ WARNING: Unexpected deletion count" -ForegroundColor Yellow
    Write-Host "  Expected $expectedDeletions deletions, got $deletedCount" -ForegroundColor Yellow
}

# Verify no files older than 25 days remain
$oldFiles = $filesAfter | Where-Object { ((Get-Date) - $_.LastWriteTime).Days -gt 25 }
if ($oldFiles.Count -eq 0) {
    Write-Host "✓ No files older than 25 days remaining" -ForegroundColor Green
} else {
    Write-Host "✗ FAILED: Found $($oldFiles.Count) files older than retention period" -ForegroundColor Red
}

Write-Host "`nCleanup test directory? (Y/N): " -ForegroundColor Yellow -NoNewline
$cleanup = Read-Host
if ($cleanup -eq 'Y' -or $cleanup -eq 'y') {
    Remove-Item $testDir -Recurse -Force
    Write-Host "✓ Test directory cleaned up" -ForegroundColor Green
}
