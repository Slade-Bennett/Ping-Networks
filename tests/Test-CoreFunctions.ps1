# Test-CoreFunctions.ps1
# Unit tests for core Ping-Networks functions

[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'
$testsPassed = 0
$testsFailed = 0
$startTime = Get-Date

# Import module
Import-Module (Join-Path $PSScriptRoot "..\modules\Ping-Networks.psm1") -Force

function Test-Function {
    param(
        [string]$Name,
        [scriptblock]$Test
    )

    try {
        $result = & $Test
        if ($result) {
            Write-Host "  [PASS] $Name" -ForegroundColor Green
            $script:testsPassed++
        } else {
            Write-Host "  [FAIL] $Name" -ForegroundColor Red
            $script:testsFailed++
        }
    }
    catch {
        Write-Host "  [FAIL] $Name - Exception: $_" -ForegroundColor Red
        $script:testsFailed++
    }
}

# Test Parse-NetworkInput with CIDR notation
Test-Function "Parse-NetworkInput: CIDR notation" {
    $result = Parse-NetworkInput -NetworkInput "10.0.0.0/24"
    ($result.IP -eq "10.0.0.0") -and
    ($result.SubnetMask -eq "255.255.255.0") -and
    ($result.CIDR -eq 24) -and
    ($result.Format -eq "CIDR")
}

# Test Parse-NetworkInput with IP range
Test-Function "Parse-NetworkInput: IP range" {
    $result = Parse-NetworkInput -NetworkInput "192.168.1.1-192.168.1.5"
    ($result.IP -eq "192.168.1.1") -and
    ($result.Format -eq "Range") -and
    ($result.Range[0] -eq "192.168.1.1") -and
    ($result.Range[1] -eq "192.168.1.5")
}

# Test Parse-NetworkInput with Network property
Test-Function "Parse-NetworkInput: Object with Network property" {
    $obj = [PSCustomObject]@{ Network = "172.16.0.0/28" }
    $result = Parse-NetworkInput -NetworkInput $obj
    ($result.IP -eq "172.16.0.0") -and
    ($result.CIDR -eq 28)
}

# Test Parse-NetworkInput with traditional format
Test-Function "Parse-NetworkInput: Traditional format" {
    $obj = [PSCustomObject]@{
        IP = "10.0.0.0"
        'Subnet Mask' = "255.255.255.0"
        CIDR = 24
    }
    $result = Parse-NetworkInput -NetworkInput $obj
    ($result.IP -eq "10.0.0.0") -and
    ($result.SubnetMask -eq "255.255.255.0") -and
    ($result.Format -eq "Traditional")
}

# Test Get-UsableHosts for /24 network
Test-Function "Get-UsableHosts: /24 network" {
    $hosts = Get-UsableHosts -IP "192.168.1.0" -SubnetMask "255.255.255.0"
    ($hosts.Count -eq 254) -and
    ($hosts[0] -eq "192.168.1.1") -and
    ($hosts[-1] -eq "192.168.1.254")
}

# Test Get-UsableHosts for /28 network
Test-Function "Get-UsableHosts: /28 network" {
    $hosts = Get-UsableHosts -IP "10.0.0.0" -SubnetMask "255.255.255.240"
    ($hosts.Count -eq 14) -and
    ($hosts[0] -eq "10.0.0.1") -and
    ($hosts[-1] -eq "10.0.0.14")
}

# Test Get-UsableHosts for /30 network (point-to-point)
Test-Function "Get-UsableHosts: /30 network" {
    $hosts = Get-UsableHosts -IP "10.0.0.0" -SubnetMask "255.255.255.252"
    ($hosts.Count -eq 2) -and
    ($hosts[0] -eq "10.0.0.1") -and
    ($hosts[1] -eq "10.0.0.2")
}

# Test Get-IPRange
Test-Function "Get-IPRange: Small range" {
    $ips = Get-IPRange -StartIP "192.168.1.1" -EndIP "192.168.1.5"
    ($ips.Count -eq 5) -and
    ($ips[0] -eq "192.168.1.1") -and
    ($ips[-1] -eq "192.168.1.5")
}

# Test Get-IPRange with single IP
Test-Function "Get-IPRange: Single IP" {
    $ips = Get-IPRange -StartIP "10.0.0.1" -EndIP "10.0.0.1"
    ($ips.Count -eq 1) -and
    ($ips[0] -eq "10.0.0.1")
}

# Return results
$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds

return [PSCustomObject]@{
    Passed = $testsPassed
    Failed = $testsFailed
    Total = $testsPassed + $testsFailed
    Duration = [math]::Round($duration, 2)
}
