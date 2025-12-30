# Test-GetUsableHosts.ps1
# Comprehensive unit tests for Get-UsableHosts function

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Testing Get-UsableHosts Function" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Import the module
$modulePath = Join-Path $PSScriptRoot "..\modules\NetworkScanner.psm1"
Import-Module $modulePath -Force -Verbose:$false

$script:testsPassed = 0
$script:testsFailed = 0
$script:testResults = @()

function Test-UsableHosts {
    param(
        [string]$Description,
        [scriptblock]$Test,
        [int]$ExpectedCount = -1,
        [string]$ExpectedFirst = $null,
        [string]$ExpectedLast = $null
    )

    Write-Host "Testing: $Description" -ForegroundColor Yellow
    try {
        $result = & $Test

        $passed = $true
        $reason = ""

        # Check if result exists
        if (-not $result -and $ExpectedCount -ne 0) {
            $passed = $false
            $reason = "Returned null"
        }
        # Check expected count
        elseif ($ExpectedCount -ge 0 -and $result.Count -ne $ExpectedCount) {
            $passed = $false
            $reason = "Expected $ExpectedCount hosts, got $($result.Count)"
        }
        # Check first IP
        elseif ($ExpectedFirst -and $result[0] -ne $ExpectedFirst) {
            $passed = $false
            $reason = "Expected first IP '$ExpectedFirst', got '$($result[0])'"
        }
        # Check last IP
        elseif ($ExpectedLast -and $result[-1] -ne $ExpectedLast) {
            $passed = $false
            $reason = "Expected last IP '$ExpectedLast', got '$($result[-1])'"
        }

        if ($passed) {
            $script:testsPassed++
            Write-Host "  PASS" -ForegroundColor Green
            $script:testResults += [PSCustomObject]@{
                Test = $Description
                Status = "PASS"
                Count = if ($result) { $result.Count } else { 0 }
            }
        } else {
            $script:testsFailed++
            Write-Host "  FAIL - $reason" -ForegroundColor Red
            $script:testResults += [PSCustomObject]@{
                Test = $Description
                Status = "FAIL"
                Count = if ($result) { $result.Count } else { 0 }
            }
        }
    }
    catch {
        $script:testsFailed++
        Write-Host "  FAIL - Exception: $_" -ForegroundColor Red
        $script:testResults += [PSCustomObject]@{
            Test = $Description
            Status = "FAIL"
            Count = "Exception"
        }
    }
}

#region Test Cases

# Test 1: /24 network (most common)
Test-UsableHosts -Description "/24 network (192.168.1.0/24)" -Test {
    Get-UsableHosts -IP "192.168.1.0" -SubnetMask "255.255.255.0"
} -ExpectedCount 254 -ExpectedFirst "192.168.1.1" -ExpectedLast "192.168.1.254"

# Test 2: /28 network (small subnet)
Test-UsableHosts -Description "/28 network (10.0.0.0/28)" -Test {
    Get-UsableHosts -IP "10.0.0.0" -SubnetMask "255.255.255.240"
} -ExpectedCount 14 -ExpectedFirst "10.0.0.1" -ExpectedLast "10.0.0.14"

# Test 3: /30 network (point-to-point)
Test-UsableHosts -Description "/30 network (172.16.0.0/30)" -Test {
    Get-UsableHosts -IP "172.16.0.0" -SubnetMask "255.255.255.252"
} -ExpectedCount 2 -ExpectedFirst "172.16.0.1" -ExpectedLast "172.16.0.2"

# Test 4: /16 network (large subnet)
Test-UsableHosts -Description "/16 network (10.0.0.0/16)" -Test {
    Get-UsableHosts -IP "10.0.0.0" -SubnetMask "255.255.0.0"
} -ExpectedCount 65534 -ExpectedFirst "10.0.0.1" -ExpectedLast "10.0.255.254"

# Test 5: /20 network (moderate size - 4094 hosts)
Test-UsableHosts -Description "/20 network (172.16.0.0/20)" -Test {
    Get-UsableHosts -IP "172.16.0.0" -SubnetMask "255.255.240.0"
} -ExpectedCount 4094 -ExpectedFirst "172.16.0.1" -ExpectedLast "172.16.15.254"

# Test 6: /32 network (single host - should return null or 0 hosts)
Test-UsableHosts -Description "/32 network (no usable hosts)" -Test {
    Get-UsableHosts -IP "192.168.1.1" -SubnetMask "255.255.255.255"
} -ExpectedCount 0

# Test 7: /31 network (no usable hosts)
Test-UsableHosts -Description "/31 network (no usable hosts)" -Test {
    Get-UsableHosts -IP "192.168.1.0" -SubnetMask "255.255.255.254"
} -ExpectedCount 0

# Test 8: Network with IP not at network address
Test-UsableHosts -Description "IP in middle of subnet (192.168.1.100/24)" -Test {
    Get-UsableHosts -IP "192.168.1.100" -SubnetMask "255.255.255.0"
} -ExpectedCount 254 -ExpectedFirst "192.168.1.1" -ExpectedLast "192.168.1.254"

# Test 9: /27 network
Test-UsableHosts -Description "/27 network (192.168.1.32/27)" -Test {
    Get-UsableHosts -IP "192.168.1.32" -SubnetMask "255.255.255.224"
} -ExpectedCount 30 -ExpectedFirst "192.168.1.33" -ExpectedLast "192.168.1.62"

# Test 10: /25 network
Test-UsableHosts -Description "/25 network (172.16.1.0/25)" -Test {
    Get-UsableHosts -IP "172.16.1.0" -SubnetMask "255.255.255.128"
} -ExpectedCount 126 -ExpectedFirst "172.16.1.1" -ExpectedLast "172.16.1.126"

# Test 11: /29 network (8 addresses, 6 usable)
Test-UsableHosts -Description "/29 network (192.168.1.8/29)" -Test {
    Get-UsableHosts -IP "192.168.1.8" -SubnetMask "255.255.255.248"
} -ExpectedCount 6 -ExpectedFirst "192.168.1.9" -ExpectedLast "192.168.1.14"

# Test 12: /26 network
Test-UsableHosts -Description "/26 network (10.1.1.64/26)" -Test {
    Get-UsableHosts -IP "10.1.1.64" -SubnetMask "255.255.255.192"
} -ExpectedCount 62 -ExpectedFirst "10.1.1.65" -ExpectedLast "10.1.1.126"

#endregion

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
