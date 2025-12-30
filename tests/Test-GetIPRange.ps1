# Test-GetIPRange.ps1
# Comprehensive unit tests for Get-IPRange function

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Testing Get-IPRange Function" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Import the module
$modulePath = Join-Path $PSScriptRoot "..\modules\NetworkScanner.psm1"
Import-Module $modulePath -Force -Verbose:$false

$script:testsPassed = 0
$script:testsFailed = 0
$script:testResults = @()

function Test-IPRange {
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
            $reason = "Expected $ExpectedCount IPs, got $($result.Count)"
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

# Test 1: Small range (5 IPs)
Test-IPRange -Description "Small range: 192.168.1.1 to 192.168.1.5" -Test {
    Get-IPRange -StartIP "192.168.1.1" -EndIP "192.168.1.5"
} -ExpectedCount 5 -ExpectedFirst "192.168.1.1" -ExpectedLast "192.168.1.5"

# Test 2: Single IP range
Test-IPRange -Description "Single IP: 10.0.0.1 to 10.0.0.1" -Test {
    Get-IPRange -StartIP "10.0.0.1" -EndIP "10.0.0.1"
} -ExpectedCount 1 -ExpectedFirst "10.0.0.1" -ExpectedLast "10.0.0.1"

# Test 3: Range across /24 boundary
Test-IPRange -Description "Range across subnet: 192.168.1.250 to 192.168.2.5" -Test {
    Get-IPRange -StartIP "192.168.1.250" -EndIP "192.168.2.5"
} -ExpectedCount 12 -ExpectedFirst "192.168.1.250" -ExpectedLast "192.168.2.5"

# Test 4: Large range (256 IPs)
Test-IPRange -Description "Large range: 10.0.0.0 to 10.0.0.255" -Test {
    Get-IPRange -StartIP "10.0.0.0" -EndIP "10.0.0.255"
} -ExpectedCount 256 -ExpectedFirst "10.0.0.0" -ExpectedLast "10.0.0.255"

# Test 5: Range with consecutive IPs
Test-IPRange -Description "Consecutive IPs: 172.16.0.10 to 172.16.0.12" -Test {
    Get-IPRange -StartIP "172.16.0.10" -EndIP "172.16.0.12"
} -ExpectedCount 3 -ExpectedFirst "172.16.0.10" -ExpectedLast "172.16.0.12"

# Test 6: Range within same /28 subnet
Test-IPRange -Description "Within /28: 192.168.1.16 to 192.168.1.30" -Test {
    Get-IPRange -StartIP "192.168.1.16" -EndIP "192.168.1.30"
} -ExpectedCount 15 -ExpectedFirst "192.168.1.16" -ExpectedLast "192.168.1.30"

# Test 7: Range with different third octet
Test-IPRange -Description "Different third octet: 10.1.0.1 to 10.1.1.1" -Test {
    Get-IPRange -StartIP "10.1.0.1" -EndIP "10.1.1.1"
} -ExpectedCount 257 -ExpectedFirst "10.1.0.1" -ExpectedLast "10.1.1.1"

# Test 8: Range spanning multiple subnets
Test-IPRange -Description "Multi-subnet: 172.16.5.200 to 172.16.7.50" -Test {
    Get-IPRange -StartIP "172.16.5.200" -EndIP "172.16.7.50"
} -ExpectedCount 363 -ExpectedFirst "172.16.5.200" -ExpectedLast "172.16.7.50"

# Test 9: Two consecutive IPs
Test-IPRange -Description "Two IPs: 192.168.1.100 to 192.168.1.101" -Test {
    Get-IPRange -StartIP "192.168.1.100" -EndIP "192.168.1.101"
} -ExpectedCount 2 -ExpectedFirst "192.168.1.100" -ExpectedLast "192.168.1.101"

# Test 10: Range with larger address space
Test-IPRange -Description "Larger range: 10.0.0.1 to 10.0.1.255" -Test {
    Get-IPRange -StartIP "10.0.0.1" -EndIP "10.0.1.255"
} -ExpectedCount 511 -ExpectedFirst "10.0.0.1" -ExpectedLast "10.0.1.255"

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
