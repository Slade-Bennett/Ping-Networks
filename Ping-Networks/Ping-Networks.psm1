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

<#
.SYNOPSIS
    Calculates all usable host IP addresses within a given IP network and subnet mask.
.DESCRIPTION
    This function takes an IP address and its corresponding subnet mask, and
    returns a list of all usable IP addresses within that network range.
    It excludes the network address and broadcast address.
.PARAMETER IP
    The IP address of the network (e.g., "192.168.1.0").
.PARAMETER SubnetMask
    The subnet mask of the network (e.g., "255.255.255.0").
.OUTPUTS
    [string[]]
    Returns an array of strings, each representing a usable IP address.
.EXAMPLE
    Get-UsableHosts -IP "192.168.1.0" -SubnetMask "255.255.255.0"
    # Returns all IPs from 192.168.1.1 to 192.168.1.254
.EXAMPLE
    "10.0.0.0", "10.0.0.255" | ForEach-Object { Get-UsableHosts -IP $_ -SubnetMask "255.255.255.128" }
.NOTES
    Uses bitwise operations to calculate network and broadcast addresses.
    Requires valid IPv4 addresses for input.
#>
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

        $invertedMaskBytes = $maskBytes | ForEach-Object { -bnot $_ -band 0xFF }
        $broadcastBytes = for ($i = 0; $i -lt 4; $i++) {
            $networkBytes[$i] -bor $invertedMaskBytes[$i]
        }

        $firstUsable = (BytesToUInt32 $networkBytes) + 1
        $lastUsable = (BytesToUInt32 $broadcastBytes) - 1

        if ($firstUsable -gt $lastUsable) {
            Write-Warning "No usable hosts in network $IP with subnet mask $SubnetMask."
            return # Return nothing - this returns $null
        }
        
        $usable = @() # Initialize an array
        for ($i = $firstUsable; $i -le $lastUsable; $i++) {
            $bytes = [BitConverter]::GetBytes($i)
            # Reverse the bytes again to get the correct IP address
            $usable += [System.Net.IPAddress](@($bytes[3], $bytes[2], $bytes[1], $bytes[0])).IPAddressToString
        }
        return $usable # Returns the array
    }
    catch {
        Write-Error "Failed to calculate usable hosts for IP '$IP' and SubnetMask '$SubnetMask'. Error: $_"
        return # Return nothing
    }
}

<#
.SYNOPSIS
    Pings a list of host IP addresses in parallel using PowerShell jobs.
.DESCRIPTION
    This function takes an array of host IP addresses and pings them concurrently.
    It returns a custom object for each host, indicating whether it's reachable
    and attempting to resolve its hostname if reachable.
    Parallel execution is managed using PowerShell Runspace Pools.
.PARAMETER Hosts
    An array of IP addresses (strings) to be pinged.
.PARAMETER Throttle
    The maximum number of concurrent pings to perform. Defaults to 20.
.PARAMETER Timeout
    The timeout in seconds for each individual ping attempt. Defaults to 1.
.PARAMETER Retries
    The number of times to retry a ping attempt before marking a host as unreachable. Defaults to 0.
.OUTPUTS
    [PSCustomObject[]]
    Returns an array of custom objects, each with properties:
    - Host (string): The IP address that was pinged.
    - Reachable (boolean): True if the host responded to ping, False otherwise.
    - Hostname (string): The resolved hostname if reachable, "N/A" otherwise.
.EXAMPLE
    Start-Ping -Hosts @("192.168.1.1", "192.168.1.10", "8.8.8.8") -Throttle 10
.EXAMPLE
    $hostList = Get-UsableHosts -IP "172.16.0.0" -SubnetMask "255.255.255.0"
    $results = Start-Ping -Hosts $hostList -Timeout 2 -Retries 1
    $results | Format-Table -AutoSize
.NOTES
    Uses Test-Connection and System.Net.Dns.GetHostEntry.
    Requires PowerShell 5.1 for RunspacePool functionality.
#>
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
                                                Write-Warning "Ping attempt $($i+1) for '$TargetHost' failed: $($_.Exception.Message)"
                                            }
                                        }            $hostname = if ($pingResult) {
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
