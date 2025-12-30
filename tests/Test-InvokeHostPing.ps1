# Test-InvokeHostPing.ps1
# Functional tests for Invoke-HostPing function
# Note: These are functional tests, not pure unit tests, as they perform actual network operations

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Testing Invoke-HostPing Function" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Import the module
$modulePath = Join-Path $PSScriptRoot "..\modules\NetworkScanner.psm1"
Import-Module $modulePath -Force -Verbose:$false

$script:testsPassed = 0
$script:testsFailed = 0
$script:testResults = @()

function Test-HostPing {
    param(
        [string]$Description,
        [scriptblock]$Test
    )

    Write-Host "Testing: $Description" -ForegroundColor Yellow
    try {
        $result = & $Test

        if ($result.Passed) {
            $script:testsPassed++
            Write-Host "  PASS" -ForegroundColor Green
            $script:testResults += [PSCustomObject]@{
                Test = $Description
                Status = "PASS"
                Details = $result.Message
            }
        } else {
            $script:testsFailed++
            Write-Host "  FAIL - $($result.Message)" -ForegroundColor Red
            $script:testResults += [PSCustomObject]@{
                Test = $Description
                Status = "FAIL"
                Details = $result.Message
            }
        }
    }
    catch {
        $script:testsFailed++
        Write-Host "  FAIL - Exception: $_" -ForegroundColor Red
        $script:testResults += [PSCustomObject]@{
            Test = $Description
            Status = "FAIL"
            Details = "Exception: $_"
        }
    }
}

#region Test Cases

# Test 1: Output structure validation
Test-HostPing -Description "Output structure has all required properties" -Test {
    $result = Invoke-HostPing -Hosts @("127.0.0.1") -Throttle 1 -Timeout 1 -Count 1

    if (-not $result) {
        return @{ Passed = $false; Message = "No result returned" }
    }

    $requiredProps = @('Host', 'Reachable', 'Hostname', 'ResponseTime', 'MinResponseTime', 'MaxResponseTime', 'PacketLoss', 'PingsSent', 'PingsReceived')
    $missingProps = $requiredProps | Where-Object { -not ($result[0].PSObject.Properties.Name -contains $_) }

    if ($missingProps) {
        return @{ Passed = $false; Message = "Missing properties: $($missingProps -join ', ')" }
    }

    return @{ Passed = $true; Message = "All properties present" }
}

# Test 2: Single host ping (localhost)
Test-HostPing -Description "Single host ping returns one result" -Test {
    $result = Invoke-HostPing -Hosts @("127.0.0.1") -Throttle 1 -Timeout 1 -Count 1

    if ($result.Count -ne 1) {
        return @{ Passed = $false; Message = "Expected 1 result, got $($result.Count)" }
    }

    if ($result[0].Host -ne "127.0.0.1") {
        return @{ Passed = $false; Message = "Expected host '127.0.0.1', got '$($result[0].Host)'" }
    }

    return @{ Passed = $true; Message = "Single result for single host" }
}

# Test 3: Multiple hosts
Test-HostPing -Description "Multiple hosts return correct count" -Test {
    $hosts = @("127.0.0.1", "localhost", "8.8.8.8")
    $result = Invoke-HostPing -Hosts $hosts -Throttle 10 -Timeout 1 -Count 1

    if ($result.Count -ne 3) {
        return @{ Passed = $false; Message = "Expected 3 results, got $($result.Count)" }
    }

    return @{ Passed = $true; Message = "Correct count for multiple hosts" }
}

# Test 4: Localhost should be reachable
Test-HostPing -Description "Localhost (127.0.0.1) is reachable" -Test {
    $result = Invoke-HostPing -Hosts @("127.0.0.1") -Throttle 1 -Timeout 2 -Count 1

    if (-not $result[0].Reachable) {
        return @{ Passed = $false; Message = "Localhost not reachable (unexpected)" }
    }

    return @{ Passed = $true; Message = "Localhost is reachable" }
}

# Test 5: Unreachable host (invalid IP)
Test-HostPing -Description "Invalid IP (192.0.2.1) is unreachable" -Test {
    # 192.0.2.0/24 is TEST-NET-1, reserved for documentation, should be unreachable
    $result = Invoke-HostPing -Hosts @("192.0.2.1") -Throttle 1 -Timeout 1 -Count 1

    if ($result[0].Reachable) {
        return @{ Passed = $false; Message = "Test network IP reported as reachable (unexpected)" }
    }

    if ($result[0].PacketLoss -ne 100) {
        return @{ Passed = $false; Message = "Expected 100% packet loss, got $($result[0].PacketLoss)%" }
    }

    return @{ Passed = $true; Message = "Unreachable host correctly reported" }
}

# Test 6: Response time statistics (multiple pings)
Test-HostPing -Description "Multiple pings generate statistics" -Test {
    $result = Invoke-HostPing -Hosts @("127.0.0.1") -Throttle 1 -Timeout 1 -Count 3

    if ($result[0].PingsSent -ne 3) {
        return @{ Passed = $false; Message = "Expected 3 pings sent, got $($result[0].PingsSent)" }
    }

    if ($result[0].MinResponseTime -gt $result[0].MaxResponseTime) {
        return @{ Passed = $false; Message = "Min response time ($($result[0].MinResponseTime)) > Max ($($result[0].MaxResponseTime))" }
    }

    return @{ Passed = $true; Message = "Statistics correctly generated" }
}

# Test 7: Throttle parameter (10 concurrent)
Test-HostPing -Description "Throttle parameter works with 10 hosts" -Test {
    $hosts = 1..10 | ForEach-Object { "127.0.0.$_" }
    $result = Invoke-HostPing -Hosts $hosts -Throttle 10 -Timeout 1 -Count 1

    if ($result.Count -ne 10) {
        return @{ Passed = $false; Message = "Expected 10 results, got $($result.Count)" }
    }

    return @{ Passed = $true; Message = "Throttle handled 10 hosts" }
}

# Test 8: Packet loss calculation
Test-HostPing -Description "Packet loss calculation for unreachable host" -Test {
    $result = Invoke-HostPing -Hosts @("192.0.2.254") -Throttle 1 -Timeout 1 -Count 2

    if ($result[0].PacketLoss -ne 100) {
        return @{ Passed = $false; Message = "Expected 100% packet loss, got $($result[0].PacketLoss)%" }
    }

    if ($result[0].PingsReceived -ne 0) {
        return @{ Passed = $false; Message = "Expected 0 pings received, got $($result[0].PingsReceived)" }
    }

    return @{ Passed = $true; Message = "Packet loss correctly calculated" }
}

#endregion

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total Tests: $($script:testsPassed + $script:testsFailed)" -ForegroundColor White
Write-Host "Passed:      $script:testsPassed" -ForegroundColor Green
Write-Host "Failed:      $script:testsFailed" -ForegroundColor $(if ($script:testsFailed -gt 0) { "Red" } else { "Green" })
Write-Host "`nTest Results:" -ForegroundColor Cyan
$script:testResults | Format-Table -AutoSize -Wrap

if ($script:testsFailed -eq 0) {
    Write-Host "`nAll tests passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nSome tests failed!" -ForegroundColor Red
    exit 1
}
