# Ping-Networks.psm1
# Helper functions for network scanning and ping operations.
# This module provides subnet calculation and parallel ping functionality.

#region Internal Functions

<#
.SYNOPSIS
    Converts an IP address string to a byte array.
.DESCRIPTION
    Internal helper function that parses an IP address string and returns
    its byte representation. Network addresses are stored in big-endian format.
.PARAMETER ip
    The IP address string to convert (e.g., "192.168.1.0").
.OUTPUTS
    [byte[]] A 4-byte array representing the IP address.
#>
function ConvertTo-Bytes($ip) {
    return [System.Net.IPAddress]::Parse($ip).GetAddressBytes()
}

<#
.SYNOPSIS
    Converts a byte array to an unsigned 32-bit integer.
.DESCRIPTION
    Internal helper function that converts a 4-byte array (representing an IP address)
    to a 32-bit unsigned integer for arithmetic operations.
    Bytes must be reversed because network byte order (big-endian) differs from
    BitConverter's expected order (little-endian on most systems).
.PARAMETER bytes
    A 4-byte array representing an IP address.
.OUTPUTS
    [uint32] The 32-bit integer representation of the IP address.
#>
function BytesToUInt32($bytes) {
    # Reverse bytes: network order (big-endian) to little-endian for BitConverter
    return [BitConverter]::ToUInt32(($bytes[3], $bytes[2], $bytes[1], $bytes[0]), 0)
}

#endregion

#region Exported Functions

<#
.SYNOPSIS
    Calculates all usable host IP addresses within a given IP network and subnet mask.
.DESCRIPTION
    This function performs subnet calculations to determine all valid host addresses
    within a network range. It supports any standard CIDR notation (/8 through /30).

    SUBNET CALCULATION METHODOLOGY:
    1. Convert IP and subnet mask to byte arrays
    2. Calculate network address using bitwise AND (IP & Mask)
       - Example: 192.168.1.100 & 255.255.255.0 = 192.168.1.0
    3. Calculate broadcast address using bitwise OR with inverted mask
       - Inverted mask: NOT(255.255.255.0) = 0.0.0.255
       - Broadcast: 192.168.1.0 OR 0.0.0.255 = 192.168.1.255
    4. Convert addresses to 32-bit integers for enumeration
    5. Generate all IPs between network+1 and broadcast-1 (usable hosts)

    This approach works for ANY CIDR:
    - /24 (255.255.255.0): 254 usable hosts (.1 to .254)
    - /28 (255.255.255.240): 14 usable hosts
    - /30 (255.255.255.252): 2 usable hosts (point-to-point links)
    - /16 (255.255.0.0): 65,534 usable hosts

.PARAMETER IP
    The IP address of the network (e.g., "192.168.1.0" or any IP in the subnet).
.PARAMETER SubnetMask
    The subnet mask in dotted-decimal notation (e.g., "255.255.255.0").
.OUTPUTS
    [string[]]
    Returns an array of all usable IP addresses in the subnet, excluding
    network and broadcast addresses. Returns $null if no usable hosts exist.
.EXAMPLE
    Get-UsableHosts -IP "192.168.1.0" -SubnetMask "255.255.255.0"
    # Returns 254 IPs from 192.168.1.1 to 192.168.1.254 (/24 network)
.EXAMPLE
    Get-UsableHosts -IP "10.0.0.0" -SubnetMask "255.255.255.240"
    # Returns 14 IPs from 10.0.0.1 to 10.0.0.14 (/28 network)
.EXAMPLE
    Get-UsableHosts -IP "172.16.5.100" -SubnetMask "255.255.255.252"
    # Returns 2 IPs for a /30 point-to-point network
.NOTES
    Author: Refactored from archive.ps1
    Uses bitwise operations for accurate subnet calculations.
    Supports all standard IPv4 CIDR notations.
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
        # Step 1: Convert IP and subnet mask to byte arrays (4 bytes each)
        $ipBytes = ConvertTo-Bytes $IP
        $maskBytes = ConvertTo-Bytes $SubnetMask

        # Step 2: Calculate network address using bitwise AND operation
        # Example: 192.168.1.100 AND 255.255.255.0 = 192.168.1.0
        $networkBytes = for ($i = 0; $i -lt 4; $i++) {
            $ipBytes[$i] -band $maskBytes[$i]
        }

        # Step 3: Calculate inverted mask (host bits)
        # Example: NOT 255.255.255.0 = 0.0.0.255
        $invertedMaskBytes = $maskBytes | ForEach-Object { -bnot $_ -band 0xFF }

        # Step 4: Calculate broadcast address using bitwise OR
        # Example: 192.168.1.0 OR 0.0.0.255 = 192.168.1.255
        $broadcastBytes = for ($i = 0; $i -lt 4; $i++) {
            $networkBytes[$i] -bor $invertedMaskBytes[$i]
        }

        # Step 5: Convert to 32-bit integers for easy enumeration
        # First usable host = network address + 1
        # Last usable host = broadcast address - 1
        $firstUsable = (BytesToUInt32 $networkBytes) + 1
        $lastUsable = (BytesToUInt32 $broadcastBytes) - 1

        # Validate that we have usable hosts (e.g., /31 or /32 have none)
        if ($firstUsable -gt $lastUsable) {
            Write-Warning "No usable hosts in network $IP/$SubnetMask (subnet too small)."
            return $null
        }

        # Step 6: Generate all IP addresses in the usable range
        $usable = @()
        for ($i = $firstUsable; $i -le $lastUsable; $i++) {
            # Convert integer back to IP address
            $bytes = [BitConverter]::GetBytes($i)
            # Reverse bytes to convert from little-endian to network order
            # Use .new() method to properly construct IPAddress from byte array
            $usable += [System.Net.IPAddress]::new(($bytes[3], $bytes[2], $bytes[1], $bytes[0])).IPAddressToString
        }

        Write-Verbose "Calculated $($usable.Count) usable hosts for $IP/$SubnetMask"
        return $usable
    }
    catch {
        Write-Error "Failed to calculate usable hosts for IP '$IP' and SubnetMask '$SubnetMask'. Error: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Pings a list of host IP addresses in parallel using PowerShell jobs.
.DESCRIPTION
    This function performs parallel ICMP ping tests on multiple hosts using PowerShell jobs
    for concurrency. For each host, it attempts to:
    1. Ping the host using Test-Connection
    2. If reachable, resolve the hostname using DNS
    3. Return a structured result object

    PARALLEL EXECUTION:
    - Hosts are processed in batches to prevent system overload
    - Each batch creates PowerShell background jobs
    - Default batch size is 20 concurrent jobs
    - Jobs are waited upon and results collected before next batch

    DIFFERENCES FROM ARCHIVE.PS1:
    - Removed debug logging (simplified code)
    - Maintained batch processing for scalability
    - Uses same ping logic: Test-Connection + DNS resolution
    - Returns same result structure for compatibility

.PARAMETER Hosts
    An array of IP addresses (strings) to be pinged.
.PARAMETER Throttle
    The maximum number of concurrent pings (batch size). Defaults to 20.
    Larger values = faster but more system resource usage.
.PARAMETER Timeout
    (Reserved for future use) Timeout in seconds for each ping. Defaults to 1.
.PARAMETER Retries
    (Reserved for future use) Number of retry attempts. Defaults to 0.
.OUTPUTS
    [PSCustomObject[]]
    Returns an array of custom objects, each with properties:
    - Host (string): The IP address that was pinged.
    - Reachable (boolean): True if the host responded to ping, False otherwise.
    - Hostname (string): The resolved hostname if reachable, "N/A" otherwise.
.EXAMPLE
    Start-Ping -Hosts @("192.168.1.1", "192.168.1.10", "8.8.8.8") -Throttle 10
    # Pings three hosts with a batch size of 10
.EXAMPLE
    $hostList = Get-UsableHosts -IP "172.16.0.0" -SubnetMask "255.255.255.0"
    $results = Start-Ping -Hosts $hostList
    $results | Where-Object Reachable | Format-Table -AutoSize
    # Pings all hosts in 172.16.0.0/24 and shows only reachable ones
.NOTES
    Author: Refactored from archive.ps1
    Uses Test-Connection for ICMP and System.Net.Dns for hostname resolution.
    Requires PowerShell 5.1+ for background job functionality.
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

    $allResults = @()
    $batchSize = $Throttle

    # Start timing for scan rate calculation
    $startTime = Get-Date

    Write-Verbose "Start-Ping: Beginning ping of $($Hosts.Count) hosts with batch size $batchSize"

    # Process hosts in batches to avoid overwhelming the system
    for ($i = 0; $i -lt $Hosts.Count; $i += $batchSize) {
        # Calculate batch range
        $batch = $Hosts[$i..([math]::Min($i + $batchSize - 1, $Hosts.Count - 1))]
        $jobs = @()

        Write-Verbose "Start-Ping: Processing batch $([math]::Floor($i/$batchSize) + 1) with $($batch.Count) hosts"

        # Create a background job for each host in the batch
        foreach ($h in $batch) {
            $jobs += Start-Job -ScriptBlock {
                param($TargetHost)

                # Initialize result variables
                $pingResult = $false
                $hostname = "N/A"

                # Attempt to ping the host
                # Test-Connection -Quiet returns $true/$false
                # ErrorAction Stop ensures errors don't display
                try {
                    $pingResult = Test-Connection -ComputerName $TargetHost -Count 1 -Quiet -ErrorAction Stop
                }
                catch {
                    # Ping failed - keep $pingResult as $false
                }

                # If ping succeeded, attempt DNS hostname resolution
                if ($pingResult) {
                    try {
                        $hostname = [System.Net.Dns]::GetHostEntry($TargetHost).HostName
                    }
                    catch {
                        # DNS resolution failed - keep hostname as "N/A"
                    }
                }

                # Return structured result object
                return [PSCustomObject]@{
                    Host      = $TargetHost
                    Reachable = $pingResult
                    Hostname  = $hostname
                }
            } -ArgumentList $h
        }

        # Calculate scan statistics
        $hostsCompleted = $i
        $elapsedTime = (Get-Date) - $startTime
        $elapsedSeconds = $elapsedTime.TotalSeconds

        # Calculate scan rate (hosts per second)
        $scanRate = if ($elapsedSeconds -gt 0) {
            [math]::Round($hostsCompleted / $elapsedSeconds, 2)
        } else {
            0
        }

        # Calculate ETA
        $hostsRemaining = $Hosts.Count - $hostsCompleted
        $etaSeconds = if ($scanRate -gt 0) {
            [math]::Round($hostsRemaining / $scanRate)
        } else {
            0
        }
        $etaTimeSpan = [TimeSpan]::FromSeconds($etaSeconds)
        $etaFormatted = if ($etaSeconds -gt 0) {
            "{0:D2}:{1:D2}:{2:D2}" -f $etaTimeSpan.Hours, $etaTimeSpan.Minutes, $etaTimeSpan.Seconds
        } else {
            "Calculating..."
        }

        # Show enhanced progress to user (as child progress bar)
        $percentComplete = [math]::Min(100, ($hostsCompleted / $Hosts.Count) * 100)
        $statusMessage = "Scanned: $hostsCompleted/$($Hosts.Count) | Rate: $scanRate hosts/sec | ETA: $etaFormatted"

        Write-Progress -Id 2 -ParentId 1 -Activity "Pinging Hosts" `
                       -Status $statusMessage `
                       -PercentComplete $percentComplete

        # Wait for all jobs in this batch to complete
        Wait-Job -Job $jobs | Out-Null

        # Collect results and clean up jobs
        $batchResults = $jobs | ForEach-Object {
            Receive-Job -Job $_
            Remove-Job -Job $_ -Force
        }

        $allResults += $batchResults
        Write-Verbose "Start-Ping: Completed batch. Total results collected: $($allResults.Count)"
    }

    # Clear progress bar
    Write-Progress -Id 2 -Activity "Pinging Hosts" -Completed

    Write-Verbose "Start-Ping: Finished pinging all $($Hosts.Count) hosts"
    return $allResults
}

#endregion

Export-ModuleMember -Function Get-UsableHosts, Start-Ping
