# Test-Performance.ps1
# Performance comparison test for runspace-based implementation
# Compares scan times with different throttle values

[CmdletBinding()]
param()

$projectRoot = Split-Path $PSScriptRoot -Parent
$mainScript = Join-Path $projectRoot "Ping-Networks.ps1"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Performance Comparison Test" -ForegroundColor Cyan
Write-Host "  Testing Runspace Implementation" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Test configuration
$testSizes = @(
    @{ Name = "Small (10 hosts)"; MaxPings = 10 }
    @{ Name = "Medium (20 hosts)"; MaxPings = 20 }
    @{ Name = "Large (50 hosts)"; MaxPings = 50 }
)

$throttleValues = @(20, 50, 100)

$results = @()

foreach ($size in $testSizes) {
    Write-Host "`nTesting: $($size.Name)" -ForegroundColor Yellow
    Write-Host ("=" * 50) -ForegroundColor Yellow

    foreach ($throttle in $throttleValues) {
        Write-Host "  Throttle: $throttle concurrent runspaces..." -NoNewline

        # Run the scan and measure time
        $startTime = Get-Date

        $output = & $mainScript `
            -InputPath (Join-Path $projectRoot "sample-data\NetworkData.txt") `
            -MaxPings $size.MaxPings `
            -Throttle $throttle `
            -Verbose 2>&1 | Out-String

        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalSeconds

        # Extract scan rate from output if available
        $scanRate = if ($output -match "Rate: ([\d.]+) hosts/sec") {
            [decimal]$matches[1]
        } else {
            [decimal]($size.MaxPings * 4 / $duration)  # Estimate: 4 networks
        }

        Write-Host " $([math]::Round($duration, 2))s" -ForegroundColor Green

        $results += [PSCustomObject]@{
            TestSize = $size.Name
            MaxPings = $size.MaxPings
            Throttle = $throttle
            Duration = [math]::Round($duration, 2)
            HostsPerSecond = [math]::Round($scanRate, 2)
        }
    }
}

# Display results
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Performance Results" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$results | Format-Table -AutoSize

# Calculate performance improvement
Write-Host "`nPerformance Analysis:" -ForegroundColor Cyan
foreach ($size in $testSizes) {
    $sizeResults = $results | Where-Object { $_.TestSize -eq $size.Name }
    $baseline = ($sizeResults | Where-Object { $_.Throttle -eq 20 }).Duration
    $optimal = ($sizeResults | Where-Object { $_.Throttle -eq 100 }).Duration

    if ($baseline -and $optimal) {
        $improvement = [math]::Round((($baseline - $optimal) / $baseline) * 100, 1)
        Write-Host "  $($size.Name): " -NoNewline
        Write-Host "$improvement% faster " -ForegroundColor Green -NoNewline
        Write-Host "with Throttle=100 vs Throttle=20"
    }
}

Write-Host "`n========================================`n" -ForegroundColor Cyan

# Recommendations
Write-Host "Recommendations:" -ForegroundColor Yellow
Write-Host "  - Small networks (< 50 hosts): Throttle=20-50 is sufficient"
Write-Host "  - Medium networks (50-254 hosts): Throttle=50-100 recommended"
Write-Host "  - Large networks (> 254 hosts): Throttle=100-200 for maximum performance"
Write-Host "  - Adjust based on system resources and network conditions`n"

return $results
