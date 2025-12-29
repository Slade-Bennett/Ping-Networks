# Quick integration test for refactored Parse-NetworkInput
Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host "Quick Integration Test - Refactored Code" -ForegroundColor Cyan
Write-Host "==========================================`n" -ForegroundColor Cyan

# Import module
$modulePath = Join-Path $PSScriptRoot "..\modules\Ping-Networks.psm1"
Import-Module $modulePath -Force -Verbose:$false

# Test 1: Parse CIDR notation
Write-Host "Test 1: Parsing CIDR notation '10.0.0.0/30'..." -ForegroundColor Yellow
$network = Parse-NetworkInput -NetworkInput "10.0.0.0/30"

if ($network) {
    Write-Host "  PASS - Network parsed successfully" -ForegroundColor Green
    Write-Host "    Format: $($network.Format)" -ForegroundColor White
    Write-Host "    IP: $($network.IP)" -ForegroundColor White
    Write-Host "    SubnetMask: $($network.SubnetMask)" -ForegroundColor White
    Write-Host "    CIDR: $($network.CIDR)" -ForegroundColor White
} else {
    Write-Host "  FAIL - Parse-NetworkInput returned null" -ForegroundColor Red
    exit 1
}

# Test 2: Calculate usable hosts
Write-Host "`nTest 2: Calculating usable hosts for /30 network..." -ForegroundColor Yellow
$hosts = Get-UsableHosts -IP $network.IP -SubnetMask $network.SubnetMask

if ($hosts -and $hosts.Count -eq 2) {
    Write-Host "  PASS - Found $($hosts.Count) usable hosts (expected 2 for /30)" -ForegroundColor Green
    Write-Host "    Hosts: $($hosts -join ', ')" -ForegroundColor White
} else {
    Write-Host "  FAIL - Expected 2 hosts, got $($hosts.Count)" -ForegroundColor Red
    exit 1
}

# Test 3: Perform ping scan
Write-Host "`nTest 3: Performing ping scan on $($hosts.Count) hosts..." -ForegroundColor Yellow
$results = Start-Ping -Hosts $hosts -Throttle 10 -Timeout 1 -Count 1 -Verbose:$false

if ($results -and $results.Count -eq $hosts.Count) {
    Write-Host "  PASS - Scan completed successfully" -ForegroundColor Green
    Write-Host "`n  Results:" -ForegroundColor Cyan
    $results | Format-Table Host, Reachable, Hostname, ResponseTime -AutoSize

    $reachable = ($results | Where-Object { $_.Reachable }).Count
    $unreachable = ($results | Where-Object { -not $_.Reachable }).Count
    Write-Host "  Summary: $reachable reachable, $unreachable unreachable" -ForegroundColor White
} else {
    Write-Host "  FAIL - Scan returned $($results.Count) results, expected $($hosts.Count)" -ForegroundColor Red
    exit 1
}

# Test 4: Test IP Range parsing
Write-Host "`nTest 4: Parsing IP Range '192.168.1.1-192.168.1.5'..." -ForegroundColor Yellow
$rangeNetwork = Parse-NetworkInput -NetworkInput "192.168.1.1-192.168.1.5"

if ($rangeNetwork -and $rangeNetwork.Format -eq "Range") {
    Write-Host "  PASS - IP Range parsed successfully" -ForegroundColor Green
    Write-Host "    Format: $($rangeNetwork.Format)" -ForegroundColor White
    Write-Host "    Range: $($rangeNetwork.Range -join ' to ')" -ForegroundColor White
} else {
    Write-Host "  FAIL - IP Range parsing failed" -ForegroundColor Red
    exit 1
}

# Test 5: Calculate hosts for IP range
Write-Host "`nTest 5: Calculating hosts for IP range..." -ForegroundColor Yellow
$rangeHosts = Get-IPRange -StartIP $rangeNetwork.Range[0] -EndIP $rangeNetwork.Range[1]

if ($rangeHosts -and $rangeHosts.Count -eq 5) {
    Write-Host "  PASS - Generated $($rangeHosts.Count) hosts from range (expected 5)" -ForegroundColor Green
    Write-Host "    Hosts: $($rangeHosts -join ', ')" -ForegroundColor White
} else {
    Write-Host "  FAIL - Expected 5 hosts, got $($rangeHosts.Count)" -ForegroundColor Red
    exit 1
}

# Summary
Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host "Integration Test Summary" -ForegroundColor Cyan
Write-Host "==========================================`n" -ForegroundColor Cyan
Write-Host "All 5 tests passed!" -ForegroundColor Green
Write-Host "- CIDR parsing: PASS" -ForegroundColor Green
Write-Host "- Usable host calculation: PASS" -ForegroundColor Green
Write-Host "- Ping scan execution: PASS" -ForegroundColor Green
Write-Host "- IP range parsing: PASS" -ForegroundColor Green
Write-Host "- IP range generation: PASS`n" -ForegroundColor Green

Write-Host "Refactored code is working correctly!" -ForegroundColor Cyan
exit 0
