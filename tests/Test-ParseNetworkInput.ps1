# Test-ParseNetworkInput.ps1
# Comprehensive tests for Parse-NetworkInput refactoring

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Testing Parse-NetworkInput Refactoring" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Import the module
$modulePath = Join-Path $PSScriptRoot "..\modules\Ping-Networks.psm1"
Import-Module $modulePath -Force

$script:testsPassed = 0
$script:testsFailed = 0
$script:testResults = @()

function Test-NetworkParsing {
    param([string]$Description, [scriptblock]$Test)

    Write-Host "Testing: $Description" -ForegroundColor Yellow
    try {
        $result = & $Test
        if ($result) {
            $script:testsPassed++
            Write-Host "  PASS" -ForegroundColor Green
            $script:testResults += [PSCustomObject]@{ Test = $Description; Status = "PASS"; Format = $result.Format }
        } else {
            $script:testsFailed++
            Write-Host "  FAIL - Returned null" -ForegroundColor Red
            $script:testResults += [PSCustomObject]@{ Test = $Description; Status = "FAIL"; Format = "null" }
        }
    }
    catch {
        $script:testsFailed++
        Write-Host "  FAIL - Exception: $_" -ForegroundColor Red
        $script:testResults += [PSCustomObject]@{ Test = $Description; Status = "FAIL"; Format = "Exception" }
    }
}

# Test 1: CIDR Notation
Test-NetworkParsing -Description "CIDR notation: 10.0.0.0/24" -Test {
    $result = Parse-NetworkInput -NetworkInput "10.0.0.0/24"
    if ($result.Format -eq "CIDR" -and $result.CIDR -eq 24) { return $result }
    return $null
}

# Test 2: CIDR with /28
Test-NetworkParsing -Description "CIDR notation: 192.168.1.0/28" -Test {
    $result = Parse-NetworkInput -NetworkInput "192.168.1.0/28"
    if ($result.Format -eq "CIDR" -and $result.CIDR -eq 28) { return $result }
    return $null
}

# Test 3: IP Range
Test-NetworkParsing -Description "IP Range: 10.0.0.1-10.0.0.50" -Test {
    $result = Parse-NetworkInput -NetworkInput "10.0.0.1-10.0.0.50"
    if ($result.Format -eq "Range") { return $result }
    return $null
}

# Test 4: Traditional object
Test-NetworkParsing -Description "Traditional object: IP + Subnet Mask" -Test {
    $input = [PSCustomObject]@{ IP = "172.16.0.0"; 'Subnet Mask' = "255.255.255.0" }
    $result = Parse-NetworkInput -NetworkInput $input
    if ($result.Format -eq "Traditional") { return $result }
    return $null
}

# Test 5: Traditional with CIDR
Test-NetworkParsing -Description "Traditional object: IP + CIDR" -Test {
    $input = [PSCustomObject]@{ IP = "172.16.0.0"; CIDR = "24" }
    $result = Parse-NetworkInput -NetworkInput $input
    if ($result.Format -eq "Traditional") { return $result }
    return $null
}

# Test 6: Simplified Network property (CIDR)
Test-NetworkParsing -Description "Simplified object: Network property (CIDR)" -Test {
    $input = [PSCustomObject]@{ Network = "10.0.0.0/24" }
    $result = Parse-NetworkInput -NetworkInput $input
    if ($result.Format -eq "CIDR") { return $result }
    return $null
}

# Test 7: Simplified Network property (Range)
Test-NetworkParsing -Description "Simplified object: Network property (Range)" -Test {
    $input = [PSCustomObject]@{ Network = "192.168.1.1-192.168.1.100" }
    $result = Parse-NetworkInput -NetworkInput $input
    if ($result.Format -eq "Range") { return $result }
    return $null
}

# Test 8: Edge case /32
Test-NetworkParsing -Description "Edge case: /32 CIDR" -Test {
    $result = Parse-NetworkInput -NetworkInput "10.0.0.1/32"
    if ($result.Format -eq "CIDR" -and $result.CIDR -eq 32) { return $result }
    return $null
}

# Test 9: Edge case /8
Test-NetworkParsing -Description "Edge case: /8 CIDR" -Test {
    $result = Parse-NetworkInput -NetworkInput "10.0.0.0/8"
    if ($result.Format -eq "CIDR" -and $result.CIDR -eq 8) { return $result }
    return $null
}

# Test 10: Validate subnet mask calculation
Test-NetworkParsing -Description "Subnet mask validation: /24 = 255.255.255.0" -Test {
    $result = Parse-NetworkInput -NetworkInput "10.0.0.0/24"
    if ($result.SubnetMask -eq "255.255.255.0") { return $result }
    return $null
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total Tests: $($script:testsPassed + $script:testsFailed)" -ForegroundColor White
Write-Host "Passed:      $script:testsPassed" -ForegroundColor Green
Write-Host "Failed:      $script:testsFailed" -ForegroundColor $(if ($script:testsFailed -gt 0) { "Red" } else { "Green" })
Write-Host "`nTest Results:" -ForegroundColor Cyan
$script:testResults | Format-Table -AutoSize

if ($script:testsFailed -eq 0) {
    Write-Host "`nAll tests passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nSome tests failed!" -ForegroundColor Red
    exit 1
}
