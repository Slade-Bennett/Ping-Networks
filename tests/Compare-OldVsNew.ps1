# Compare-OldVsNew.ps1
# Direct performance comparison: Background Jobs vs Runspaces

[CmdletBinding()]
param()

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Performance Comparison" -ForegroundColor Cyan
Write-Host "  Background Jobs vs Runspaces" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Test with different host counts
$testSizes = @(10, 25, 50, 100)

# Old Method: Background Jobs
function Test-BackgroundJobs {
    param([string[]]$Hosts, [int]$Throttle = 20)

    $results = @()
    $batchSize = $Throttle

    for ($i = 0; $i -lt $Hosts.Count; $i += $batchSize) {
        $batch = $Hosts[$i..([math]::Min($i + $batchSize - 1, $Hosts.Count - 1))]
        $jobs = @()

        foreach ($h in $batch) {
            $jobs += Start-Job -ScriptBlock {
                param($TargetHost)
                try {
                    $pingResult = Test-Connection -ComputerName $TargetHost -Count 1 -Quiet -ErrorAction Stop
                    $hostname = if ($pingResult) {
                        try { [System.Net.Dns]::GetHostEntry($TargetHost).HostName } catch { "N/A" }
                    } else { "N/A" }

                    [PSCustomObject]@{
                        Host = $TargetHost
                        Reachable = $pingResult
                        Hostname = $hostname
                    }
                } catch {
                    [PSCustomObject]@{
                        Host = $TargetHost
                        Reachable = $false
                        Hostname = "N/A"
                    }
                }
            } -ArgumentList $h
        }

        Wait-Job -Job $jobs | Out-Null
        $results += $jobs | ForEach-Object {
            Receive-Job -Job $_
            Remove-Job -Job $_ -Force
        }
    }

    return $results
}

# New Method: Runspaces
function Test-Runspaces {
    param([string[]]$Hosts, [int]$Throttle = 50)

    $results = [System.Collections.Generic.List[pscustomobject]]::new()

    # Create runspace pool
    $runspacePool = [runspacefactory]::CreateRunspacePool(1, $Throttle)
    $runspacePool.Open()

    $pingScriptBlock = {
        param($TargetHost)
        try {
            $pingResult = Test-Connection -ComputerName $TargetHost -Count 1 -Quiet -ErrorAction Stop
            $hostname = if ($pingResult) {
                try { [System.Net.Dns]::GetHostEntry($TargetHost).HostName } catch { "N/A" }
            } else { "N/A" }

            [PSCustomObject]@{
                Host = $TargetHost
                Reachable = $pingResult
                Hostname = $hostname
            }
        } catch {
            [PSCustomObject]@{
                Host = $TargetHost
                Reachable = $false
                Hostname = "N/A"
            }
        }
    }

    # Create runspaces
    $runspaces = [System.Collections.Generic.List[hashtable]]::new()
    foreach ($h in $Hosts) {
        $powershell = [powershell]::Create()
        $powershell.RunspacePool = $runspacePool
        [void]$powershell.AddScript($pingScriptBlock).AddArgument($h)

        $runspaces.Add(@{
            PowerShell = $powershell
            Handle = $powershell.BeginInvoke()
            Completed = $false
        })
    }

    # Collect results
    $completedCount = 0
    while ($completedCount -lt $Hosts.Count) {
        for ($i = 0; $i -lt $runspaces.Count; $i++) {
            $runspace = $runspaces[$i]
            if ($runspace.Completed) { continue }

            if ($runspace.Handle.IsCompleted) {
                try {
                    $result = $runspace.PowerShell.EndInvoke($runspace.Handle)
                    $results.Add($result)
                } catch {
                    $results.Add([PSCustomObject]@{
                        Host = "Error"
                        Reachable = $false
                        Hostname = "N/A"
                    })
                }
                $runspace.PowerShell.Dispose()
                $runspace.Completed = $true
                $completedCount++
            }
        }
        Start-Sleep -Milliseconds 10
    }

    $runspacePool.Close()
    $runspacePool.Dispose()

    return $results
}

# Generate test IPs
function Generate-TestIPs {
    param([int]$Count)
    $ips = @()
    for ($i = 1; $i -le $Count; $i++) {
        $ips += "10.0.0.$i"
    }
    return $ips
}

# Run comparison tests
$comparisonResults = @()

foreach ($size in $testSizes) {
    Write-Host "`nTesting with $size hosts:" -ForegroundColor Yellow
    Write-Host ("-" * 50)

    $testIPs = Generate-TestIPs -Count $size

    # Test Background Jobs
    Write-Host "  Background Jobs (Throttle=20)..." -NoNewline
    $jobStart = Get-Date
    $jobResults = Test-BackgroundJobs -Hosts $testIPs -Throttle 20
    $jobEnd = Get-Date
    $jobDuration = ($jobEnd - $jobStart).TotalSeconds
    Write-Host " $([math]::Round($jobDuration, 2))s" -ForegroundColor Red

    # Test Runspaces
    Write-Host "  Runspaces (Throttle=50)..." -NoNewline
    $runspaceStart = Get-Date
    $runspaceResults = Test-Runspaces -Hosts $testIPs -Throttle 50
    $runspaceEnd = Get-Date
    $runspaceDuration = ($runspaceEnd - $runspaceStart).TotalSeconds
    Write-Host " $([math]::Round($runspaceDuration, 2))s" -ForegroundColor Green

    # Calculate improvement
    $speedup = [math]::Round($jobDuration / $runspaceDuration, 2)
    $percentFaster = [math]::Round((($jobDuration - $runspaceDuration) / $jobDuration) * 100, 1)

    Write-Host "  Speed Improvement: " -NoNewline
    Write-Host "${speedup}x faster " -ForegroundColor Cyan -NoNewline
    Write-Host "($percentFaster% faster)" -ForegroundColor Cyan

    $comparisonResults += [PSCustomObject]@{
        Hosts = $size
        'Background Jobs (s)' = [math]::Round($jobDuration, 2)
        'Runspaces (s)' = [math]::Round($runspaceDuration, 2)
        'Speedup' = "${speedup}x"
        'Improvement' = "$percentFaster%"
    }
}

# Display summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Summary Results" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$comparisonResults | Format-Table -AutoSize

# Calculate averages
$avgJobTime = ($comparisonResults | Measure-Object -Property 'Background Jobs (s)' -Average).Average
$avgRunspaceTime = ($comparisonResults | Measure-Object -Property 'Runspaces (s)' -Average).Average
$avgSpeedup = [math]::Round($avgJobTime / $avgRunspaceTime, 2)

Write-Host "`nAverage Performance:" -ForegroundColor Yellow
Write-Host "  Background Jobs: $([math]::Round($avgJobTime, 2))s" -ForegroundColor Red
Write-Host "  Runspaces: $([math]::Round($avgRunspaceTime, 2))s" -ForegroundColor Green
Write-Host "  Average Speedup: " -NoNewline
Write-Host "${avgSpeedup}x faster" -ForegroundColor Cyan

Write-Host "`n========================================`n" -ForegroundColor Cyan

return $comparisonResults
