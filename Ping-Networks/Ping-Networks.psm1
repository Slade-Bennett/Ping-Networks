# Ping-Networks.psm1
# Helper functions for the Ping-Networks script.

#region Internal Functions

function ConvertTo-Bytes($ip) {
    return [System.Net.IPAddress]::Parse($ip).GetAddressBytes()
}

function BytesToUInt32($bytes) {
    # Bytes must be reversed for BitConverter to work correctly on big-endian network bytes
    return [BitConverter]::ToUInt32(($bytes[3], $bytes[2], $bytes[1], $bytes[0]), 0)
}

#endregion

#region Exported Functions

function Get-UsableHosts {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidatePattern('^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$')]
        [string]$IP,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidatePattern('^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$')]
        [string]$SubnetMask
    )

    try {
        $ipBytes = ConvertTo-Bytes $IP
        $maskBytes = ConvertTo-Bytes $SubnetMask

        $networkBytes = for ($i = 0; $i -lt 4; $i++) {
            $ipBytes[$i] -band $maskBytes[$i]
        }

        $invertedMaskBytes = $maskBytes | ForEach-Object { -bnot $_ }
        $broadcastBytes = for ($i = 0; $i -lt 4; $i++) {
            $networkBytes[$i] -bor $invertedMaskBytes[$i]
        }

        $firstUsable = (BytesToUInt32 $networkBytes) + 1
        $lastUsable = (BytesToUInt32 $broadcastBytes) - 1

        if ($firstUsable -gt $lastUsable) {
            Write-Warning "No usable hosts in network $IP with subnet mask $SubnetMask."
            return # Return nothing
        }
        
        for ($i = $firstUsable; $i -le $lastUsable; $i++) {
            $bytes = [BitConverter]::GetBytes($i)
            # Reverse the bytes again to get the correct IP address
            yield [System.Net.IPAddress](@($bytes[3], $bytes[2], $bytes[1], $bytes[0])).IPAddressToString
        }
    }
    catch {
        Write-Error "Failed to calculate usable hosts for IP '$IP' and SubnetMask '$SubnetMask'. Error: $_"
        return # Return nothing
    }
}

function Start-Ping {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Hosts,

        [Parameter(Mandatory = $false)]
        [int]$Throttle = 20,

        [Parameter(Mandatory = $false)]
        [int]$Timeout = 1,

        [Parameter(Mandatory = $false)]
        [int]$Retries = 0
    )

    $runspacePool = [runspacefactory]::CreateRunspacePool(1, $Throttle)
    $runspacePool.Open()

    $tasks = @()
    foreach ($currentHost in $Hosts) {
        $powershell = [powershell]::Create()
        $powershell.AddScript({
            param($TargetHost, $Timeout, $Retries)
            
            $pingResult = $false
            for ($i = 0; $i -le $Retries; $i++) {
                try {
                    if (Test-Connection -ComputerName $TargetHost -Count 1 -Quiet -ErrorAction Stop -TimeoutSeconds $Timeout) {
                        $pingResult = $true
                        break
                    }
                } catch {
                    Write-Warning "Ping failed for '$TargetHost': $_"
                }
            }

            $hostname = if ($pingResult) {
                try {
                    ([System.Net.Dns]::GetHostEntry($TargetHost)).HostName
                }
                catch {
                    "N/A"
                }
            }
            else {
                "N/A"
            }

            [PSCustomObject]@{
                Host = $TargetHost
                Reachable = $pingResult
                Hostname = $hostname
            }
        })
        $powershell.AddArgument($currentHost) | Out-Null
        $powershell.AddArgument($Timeout) | Out-Null
        $powershell.AddArgument($Retries) | Out-Null
        $powershell.RunspacePool = $runspacePool
        
        $tasks += [PSCustomObject]@{
            Instance = $powershell
            Handle = $powershell.BeginInvoke()
        }
    }

    while ($tasks.Handle.IsCompleted -contains $false) {
        $completedCount = ($tasks.Handle | Where-Object { $_.IsCompleted }).Count
        Write-Progress -Activity "Pinging Hosts" -Status "Completed $completedCount of $($tasks.Count)" -PercentComplete (($completedCount / $tasks.Count) * 100)
        Start-Sleep -Milliseconds 100
    }

    $results = @()
    foreach($task in $tasks){
        $results += $task.Instance.EndInvoke($task.Handle)
        $task.Instance.Dispose()
    }
    
    $runspacePool.Close()
    $runspacePool.Dispose()

    return $results
}

#endregion

Export-ModuleMember -Function Get-UsableHosts, Start-Ping
