# Start-Dashboard.ps1
# Web-based dashboard for Ping-Networks using Pode framework
#
# This script starts a web server that provides:
# - Browser-based interface for scan monitoring
# - Real-time scan execution and monitoring
# - Historical data visualization with charts
# - RESTful API for programmatic access
# - Responsive design for mobile/tablet access

<#
.SYNOPSIS
    Starts the Ping-Networks web dashboard.
.DESCRIPTION
    Launches a web server on the specified port providing a browser-based interface
    for network scanning, monitoring, and historical data analysis.
.PARAMETER Port
    Port number for the web server. Default is 8080.
.PARAMETER DatabaseConnectionString
    Database connection string for accessing historical scan data.
.PARAMETER DatabaseType
    Type of database. Valid values: 'SQLServer', 'MySQL', 'PostgreSQL'. Default is 'SQLServer'.
.PARAMETER EnableAuth
    Enable basic authentication for the dashboard.
.PARAMETER Username
    Username for dashboard authentication (requires EnableAuth).
.PARAMETER Password
    Password for dashboard authentication (requires EnableAuth).
.EXAMPLE
    .\Start-Dashboard.ps1
    Starts the dashboard on http://localhost:8080
.EXAMPLE
    .\Start-Dashboard.ps1 -Port 9000 -EnableAuth -Username "admin" -Password "secure123"
    Starts the dashboard with authentication on port 9000
.EXAMPLE
    .\Start-Dashboard.ps1 -DatabaseConnectionString "Server=localhost;Database=PingNetworks;Integrated Security=True"
    Starts the dashboard with database integration for historical data
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [int]$Port = 8080,

    [Parameter(Mandatory = $false)]
    [string]$DatabaseConnectionString,

    [Parameter(Mandatory = $false)]
    [ValidateSet('SQLServer', 'MySQL', 'PostgreSQL')]
    [string]$DatabaseType = 'SQLServer',

    [Parameter(Mandatory = $false)]
    [switch]$EnableAuth,

    [Parameter(Mandatory = $false)]
    [string]$Username,

    [Parameter(Mandatory = $false)]
    [string]$Password
)

# Check if Pode module is installed
if (-not (Get-Module -ListAvailable -Name Pode)) {
    Write-Host "Pode module not found. Installing..." -ForegroundColor Yellow
    try {
        Install-Module -Name Pode -Scope CurrentUser -Force -AllowClobber
        Write-Host "Pode module installed successfully." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to install Pode module: $($_.Exception.Message)"
        Write-Host ""
        Write-Host "Please install manually using: Install-Module -Name Pode -Scope CurrentUser" -ForegroundColor Yellow
        exit 1
    }
}

# Import required modules
Import-Module Pode -Force
Import-Module (Join-Path $PSScriptRoot "modules\Ping-Networks.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "modules\ExcelUtils.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "modules\ReportUtils.psm1") -Force

# Import DatabaseUtils if connection string is provided
if ($DatabaseConnectionString) {
    Import-Module (Join-Path $PSScriptRoot "modules\DatabaseUtils.psm1") -Force
}

# Start Pode server
Start-PodeServer -Threads 2 {
    # Store configuration in Pode state
    Set-PodeState -Name 'Config' -Value @{
        Port = $Port
        EnableAuth = $EnableAuth.IsPresent
        Username = $Username
        Password = $Password
        DatabaseConnectionString = $DatabaseConnectionString
        DatabaseType = $DatabaseType
        ScriptRoot = $PSScriptRoot
    }

    # Initialize scan state
    Set-PodeState -Name 'ActiveScans' -Value @{}
    Set-PodeState -Name 'ScanHistory' -Value @()

    # Set port
    Add-PodeEndpoint -Address localhost -Port $Port -Protocol Http

    # Enable logging
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    # Enable sessions for authentication
    Enable-PodeSessionMiddleware -Duration 3600 -Extend

    # Get config
    $config = Get-PodeState -Name 'Config'

    # Authentication (if enabled)
    if ($config.EnableAuth) {
        New-PodeAuthScheme -Form | Add-PodeAuth -Name 'Login' -ScriptBlock {
            param($username, $password)

            $config = Get-PodeState -Name 'Config'
            if ($username -eq $config.Username -and $password -eq $config.Password) {
                return @{ User = @{ ID = $username; Name = $username; Type = 'Admin' } }
            }
            return $null
        }
    }

    # Static content (CSS, JS, images)
    Add-PodeStaticRoute -Path '/static' -Source (Join-Path $PSScriptRoot 'dashboard\static')

    #region Web Pages

    # Login page (if auth enabled)
    $config = Get-PodeState -Name 'Config'
    if ($config.EnableAuth) {
        Add-PodeRoute -Method Get -Path '/login' -ScriptBlock {
            Write-PodeHtmlResponse -Value @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login - Ping-Networks Dashboard</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; display: flex; align-items: center; justify-content: center; }
        .login-container { background: white; padding: 40px; border-radius: 10px; box-shadow: 0 10px 40px rgba(0,0,0,0.1); width: 100%; max-width: 400px; }
        h1 { margin-bottom: 30px; color: #333; text-align: center; }
        .form-group { margin-bottom: 20px; }
        label { display: block; margin-bottom: 5px; color: #555; font-weight: 500; }
        input[type="text"], input[type="password"] { width: 100%; padding: 12px; border: 1px solid #ddd; border-radius: 5px; font-size: 14px; }
        input[type="text"]:focus, input[type="password"]:focus { outline: none; border-color: #667eea; }
        button { width: 100%; padding: 12px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; border: none; border-radius: 5px; font-size: 16px; font-weight: 600; cursor: pointer; transition: transform 0.2s; }
        button:hover { transform: translateY(-2px); }
        .error { color: #e74c3c; margin-top: 10px; text-align: center; }
    </style>
</head>
<body>
    <div class="login-container">
        <h1>🌐 Ping-Networks</h1>
        <form method="post" action="/login">
            <div class="form-group">
                <label for="username">Username</label>
                <input type="text" id="username" name="username" required>
            </div>
            <div class="form-group">
                <label for="password">Password</label>
                <input type="password" id="password" name="password" required>
            </div>
            <button type="submit">Login</button>
        </form>
    </div>
</body>
</html>
"@
        }

        Add-PodeRoute -Method Post -Path '/login' -ScriptBlock {
            $result = Invoke-PodeAuth -Name 'Login'
            if ($result.Success) {
                Move-PodeResponseUrl -Url '/'
            }
            else {
                Move-PodeResponseUrl -Url '/login?error=1'
            }
        }
    }

    # Home/Dashboard page
    Add-PodeRoute -Method Get -Path '/' -ScriptBlock {
        # Check authentication
        if ((Get-PodeState -Name 'Config').EnableAuth) {
            $session = Get-PodeAuth -Name 'Login'
            if (!$session) {
                Move-PodeResponseUrl -Url '/login'
                return
            }
        }

        Write-PodeHtmlResponse -Value @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Ping-Networks Dashboard</title>
    <link rel="stylesheet" href="/static/dashboard.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
</head>
<body>
    <nav class="navbar">
        <div class="nav-container">
            <h1>🌐 Ping-Networks Dashboard</h1>
            <div class="nav-links">
                <a href="/" class="active">Dashboard</a>
                <a href="/history">History</a>
                <a href="/api/docs">API</a>
                $(if ((Get-PodeState -Name 'Config').EnableAuth) { '<a href="/logout">Logout</a>' } else { '' })
            </div>
        </div>
    </nav>

    <div class="container">
        <!-- Summary Cards -->
        <div class="cards-grid">
            <div class="card">
                <div class="card-header">
                    <h3>Active Scans</h3>
                    <span class="icon">🔄</span>
                </div>
                <div class="card-body">
                    <div class="metric" id="activeScans">0</div>
                </div>
            </div>

            <div class="card">
                <div class="card-header">
                    <h3>Total Scans</h3>
                    <span class="icon">📊</span>
                </div>
                <div class="card-body">
                    <div class="metric" id="totalScans">-</div>
                </div>
            </div>

            <div class="card">
                <div class="card-header">
                    <h3>Hosts Scanned</h3>
                    <span class="icon">💻</span>
                </div>
                <div class="card-body">
                    <div class="metric" id="hostsScanned">-</div>
                </div>
            </div>

            <div class="card">
                <div class="card-header">
                    <h3>Reachable Rate</h3>
                    <span class="icon">✅</span>
                </div>
                <div class="card-body">
                    <div class="metric" id="reachableRate">-</div>
                </div>
            </div>
        </div>

        <!-- New Scan Section -->
        <div class="section">
            <h2>Start New Scan</h2>
            <form id="scanForm" class="scan-form">
                <div class="form-row">
                    <div class="form-group">
                        <label for="networkInput">Network (CIDR or Range)</label>
                        <input type="text" id="networkInput" placeholder="e.g., 192.168.1.0/24 or 10.0.0.1-10.0.0.20" required>
                    </div>
                    <div class="form-group">
                        <label for="throttle">Throttle</label>
                        <input type="number" id="throttle" value="50" min="1" max="200">
                    </div>
                    <div class="form-group">
                        <label for="maxPings">Max Pings</label>
                        <input type="number" id="maxPings" placeholder="All hosts" min="1">
                    </div>
                </div>
                <button type="submit" class="btn btn-primary">Start Scan</button>
            </form>
        </div>

        <!-- Active Scans -->
        <div class="section">
            <h2>Active Scans</h2>
            <div id="activeScansList" class="scans-list">
                <p class="empty-state">No active scans</p>
            </div>
        </div>

        <!-- Recent Results Chart -->
        <div class="section">
            <h2>Recent Scan Results</h2>
            <canvas id="recentScansChart"></canvas>
        </div>
    </div>

    <script src="/static/dashboard.js"></script>
</body>
</html>
"@
    }

    # History page
    Add-PodeRoute -Method Get -Path '/history' -ScriptBlock {
        if ((Get-PodeState -Name 'Config').EnableAuth) {
            $session = Get-PodeAuth -Name 'Login'
            if (!$session) {
                Move-PodeResponseUrl -Url '/login'
                return
            }
        }

        Write-PodeHtmlResponse -Value @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Scan History - Ping-Networks Dashboard</title>
    <link rel="stylesheet" href="/static/dashboard.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
</head>
<body>
    <nav class="navbar">
        <div class="nav-container">
            <h1>🌐 Ping-Networks Dashboard</h1>
            <div class="nav-links">
                <a href="/">Dashboard</a>
                <a href="/history" class="active">History</a>
                <a href="/api/docs">API</a>
                $(if ((Get-PodeState -Name 'Config').EnableAuth) { '<a href="/logout">Logout</a>' } else { '' })
            </div>
        </div>
    </nav>

    <div class="container">
        <h2>Scan History</h2>

        <!-- Filters -->
        <div class="filters">
            <input type="date" id="startDate" placeholder="Start Date">
            <input type="date" id="endDate" placeholder="End Date">
            <button onclick="loadHistory()" class="btn btn-secondary">Filter</button>
        </div>

        <!-- History Table -->
        <div class="table-container">
            <table id="historyTable">
                <thead>
                    <tr>
                        <th>Date</th>
                        <th>Networks</th>
                        <th>Hosts Scanned</th>
                        <th>Reachable</th>
                        <th>Unreachable</th>
                        <th>Duration</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody id="historyBody">
                    <tr><td colspan="7" class="empty-state">Loading...</td></tr>
                </tbody>
            </table>
        </div>

        <!-- Trend Chart -->
        <div class="section">
            <h3>Availability Trend</h3>
            <canvas id="trendChart"></canvas>
        </div>
    </div>

    <script src="/static/history.js"></script>
</body>
</html>
"@
    }

    # API Documentation page
    Add-PodeRoute -Method Get -Path '/api/docs' -ScriptBlock {
        Write-PodeHtmlResponse -Value @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>API Documentation - Ping-Networks</title>
    <link rel="stylesheet" href="/static/dashboard.css">
</head>
<body>
    <nav class="navbar">
        <div class="nav-container">
            <h1>🌐 Ping-Networks Dashboard</h1>
            <div class="nav-links">
                <a href="/">Dashboard</a>
                <a href="/history">History</a>
                <a href="/api/docs" class="active">API</a>
                $(if ((Get-PodeState -Name 'Config').EnableAuth) { '<a href="/logout">Logout</a>' } else { '' })
            </div>
        </div>
    </nav>

    <div class="container">
        <h2>API Documentation</h2>

        <div class="api-section">
            <h3>GET /api/status</h3>
            <p>Get dashboard status and statistics</p>
            <pre><code>{
  "activeScans": 0,
  "totalScans": 142,
  "hostsScanned": 15234,
  "reachableRate": 87.5
}</code></pre>
        </div>

        <div class="api-section">
            <h3>POST /api/scan/start</h3>
            <p>Start a new network scan</p>
            <strong>Request Body:</strong>
            <pre><code>{
  "network": "192.168.1.0/24",
  "throttle": 50,
  "maxPings": null,
  "timeout": 1,
  "count": 1
}</code></pre>
            <strong>Response:</strong>
            <pre><code>{
  "scanId": "scan_20251228_120000",
  "status": "running",
  "message": "Scan started successfully"
}</code></pre>
        </div>

        <div class="api-section">
            <h3>GET /api/scan/{scanId}</h3>
            <p>Get status and results of a specific scan</p>
            <pre><code>{
  "scanId": "scan_20251228_120000",
  "status": "completed",
  "progress": 100,
  "results": [...]
}</code></pre>
        </div>

        <div class="api-section">
            <h3>GET /api/history</h3>
            <p>Get scan history with optional filters</p>
            <strong>Query Parameters:</strong>
            <ul>
                <li><code>startDate</code> - Filter by start date (ISO 8601)</li>
                <li><code>endDate</code> - Filter by end date (ISO 8601)</li>
                <li><code>limit</code> - Limit number of results (default: 100)</li>
            </ul>
        </div>

        <div class="api-section">
            <h3>GET /api/networks</h3>
            <p>Get list of all scanned networks</p>
        </div>
    </div>
</body>
</html>
"@
    }

    # Logout
    if ((Get-PodeState -Name 'Config').EnableAuth) {
        Add-PodeRoute -Method Get -Path '/logout' -ScriptBlock {
            Remove-PodeAuth -Name 'Login'
            Move-PodeResponseUrl -Url '/login'
        }
    }

    #endregion

    #region API Endpoints

    # Get dashboard status
    Add-PodeRoute -Method Get -Path '/api/status' -ScriptBlock {
        $totalScans = (Get-PodeState -Name 'ScanHistory').Count
        $hostsScanned = ((Get-PodeState -Name 'ScanHistory') | Measure-Object -Property HostsScanned -Sum).Sum
        $reachableRate = 0

        # Try to get stats from database if configured
        if ((Get-PodeState -Name 'Config').DatabaseConnectionString) {
            try {
                $connection = New-Object System.Data.SqlClient.SqlConnection((Get-PodeState -Name 'Config').DatabaseConnectionString)
                $connection.Open()

                $query = @"
SELECT
    COUNT(*) as TotalScans,
    SUM(TotalHostsScanned) as HostsScanned,
    SUM(TotalHostsReachable) as HostsReachable
FROM [dbo].[Scans]
"@

                $command = $connection.CreateCommand()
                $command.CommandText = $query
                $reader = $command.ExecuteReader()

                if ($reader.Read()) {
                    $totalScans = $reader["TotalScans"]
                    $hostsScanned = if ($reader["HostsScanned"] -ne [DBNull]::Value) { $reader["HostsScanned"] } else { 0 }
                    $hostsReachable = if ($reader["HostsReachable"] -ne [DBNull]::Value) { $reader["HostsReachable"] } else { 0 }

                    if ($hostsScanned -gt 0) {
                        $reachableRate = [Math]::Round(($hostsReachable / $hostsScanned) * 100, 1)
                    }
                }

                $reader.Close()
                $connection.Close()
            }
            catch {
                Write-Host "Database stats query failed: $($_.Exception.Message)" -ForegroundColor Yellow
                # Fall back to in-memory stats
                if ((Get-PodeState -Name 'ScanHistory').Count -gt 0) {
                    $total = ((Get-PodeState -Name 'ScanHistory') | Measure-Object -Property hostsScanned -Sum).Sum
                    $reachable = ((Get-PodeState -Name 'ScanHistory') | Measure-Object -Property hostsReachable -Sum).Sum
                    $reachableRate = if ($total -gt 0) { [Math]::Round(($reachable / $total) * 100, 1) } else { 0 }
                }
            }
        }
        else {
            # Use in-memory stats
            if ((Get-PodeState -Name 'ScanHistory').Count -gt 0) {
                $total = ((Get-PodeState -Name 'ScanHistory') | Measure-Object -Property hostsScanned -Sum).Sum
                $reachable = ((Get-PodeState -Name 'ScanHistory') | Measure-Object -Property hostsReachable -Sum).Sum
                $reachableRate = if ($total -gt 0) { [Math]::Round(($reachable / $total) * 100, 1) } else { 0 }
            }
        }

        $status = @{
            activeScans = (Get-PodeState -Name 'ActiveScans').Count
            totalScans = $totalScans
            hostsScanned = $hostsScanned
            reachableRate = $reachableRate
            uptime = (Get-Date) - (Get-Process -Id $PID).StartTime
        }

        Write-PodeJsonResponse -Value $status
    }

    # Start new scan
    Add-PodeRoute -Method Post -Path '/api/scan/start' -ScriptBlock {
        $body = $WebEvent.Data

        # Validate required parameters
        if (-not $body.network) {
            Write-PodeJsonResponse -Value @{ error = 'Network is required' } -StatusCode 400
            return
        }

        $scanId = "scan_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

        # Set defaults for optional parameters
        $throttle = if ($body.throttle) { [int]$body.throttle } else { 50 }
        $maxPings = if ($body.maxPings) { [int]$body.maxPings } else { $null }
        $timeout = if ($body.timeout) { [int]$body.timeout } else { 1 }
        $count = if ($body.count) { [int]$body.count } else { 1 }

        # Create scan job
        $scan = @{
            ScanId = $scanId
            Network = $body.network
            Status = 'running'
            Progress = 0
            StartTime = Get-Date
            Results = @()
        }

        # Store scan in active scans
        $activeScans = Get-PodeState -Name 'ActiveScans'
        $activeScans[$scanId] = $scan

        # Start background job
        $config = Get-PodeState -Name 'Config'
        $job = Start-Job -ScriptBlock {
            param($Network, $Throttle, $MaxPings, $Timeout, $Count, $ScriptRoot)

            try {
                # Import module
                $modulePath = Join-Path $ScriptRoot "modules\Ping-Networks.psm1"
                Import-Module $modulePath -Force -ErrorAction Stop

                # Parse network and execute scan
                $networkData = Parse-NetworkInput -NetworkInput $Network

                if (-not $networkData) {
                    throw "Failed to parse network input: $Network"
                }

                $hosts = Get-UsableHosts -NetworkAddress $networkData.NetworkAddress -CIDR $networkData.CIDR

                if ($MaxPings -and $MaxPings -gt 0) {
                    $hosts = $hosts | Select-Object -First $MaxPings
                }

                if ($hosts.Count -eq 0) {
                    throw "No hosts found in network: $Network"
                }

                $results = Start-Ping -Hosts $hosts -Network $Network -Throttle $Throttle -Timeout $Timeout -Count $Count

                return $results
            }
            catch {
                # Return error information
                return @{
                    Error = $_.Exception.Message
                    StackTrace = $_.ScriptStackTrace
                }
            }
        } -ArgumentList $body.network, $throttle, $maxPings, $timeout, $count, $config.ScriptRoot

        $scan.Job = $job

        Write-PodeJsonResponse -Value @{
            scanId = $scanId
            status = 'running'
            message = 'Scan started successfully'
        }
    }

    # Get scan status
    Add-PodeRoute -Method Get -Path '/api/scan/:scanId' -ScriptBlock {
        $scanId = $WebEvent.Parameters['scanId']

        $activeScans = Get-PodeState -Name 'ActiveScans'
        if ($activeScans.ContainsKey($scanId)) {
            $scan = $activeScans[$scanId]

            # Check job status
            if ($scan.Job) {
                $jobState = $scan.Job.State

                if ($jobState -eq 'Completed') {
                    # Receive job output once (calling it twice loses data)
                    $jobResults = Receive-Job -Job $scan.Job -Keep -ErrorAction SilentlyContinue

                    # Check if the job returned an error object
                    if ($jobResults -and $jobResults[0] -is [hashtable] -and $jobResults[0].Error) {
                        $scan.Status = 'failed'
                        $scan.Progress = 0
                        $scan.Error = $jobResults[0].Error
                        $scan.Results = @()
                    }
                    else {
                        # Ensure results are in array format
                        $scan.Results = if ($jobResults) { @($jobResults) } else { @() }
                        $scan.Status = 'completed'
                        $scan.Progress = 100
                        $scan.EndTime = Get-Date

                        # Move to history (use lowercase for consistency with API responses)
                        $scanHistory = Get-PodeState -Name 'ScanHistory'
                        $newEntry = @{
                            scanId = $scan.ScanId
                            network = $scan.Network
                            startTime = $scan.StartTime
                            endTime = $scan.EndTime
                            hostsScanned = $scan.Results.Count
                            hostsReachable = ($scan.Results | Where-Object { $_.Status -eq 'Reachable' }).Count
                            hostsUnreachable = ($scan.Results | Where-Object { $_.Status -eq 'Unreachable' }).Count
                        }
                        $updatedHistory = @($scanHistory) + @($newEntry)
                        Set-PodeState -Name 'ScanHistory' -Value $updatedHistory
                    }

                    Remove-Job -Job $scan.Job -Force
                    $scan.Remove('Job')  # Remove job object before serializing
                }
                elseif ($jobState -eq 'Running') {
                    $scan.Status = 'running'
                    $scan.Progress = 50  # Show some progress while running
                }
                elseif ($jobState -eq 'Failed') {
                    $scan.Status = 'failed'
                    $scan.Progress = 0
                    Remove-Job -Job $scan.Job -Force
                    $scan.Remove('Job')
                }
            }

            # Return response without Job object to avoid serialization issues
            # Use lowercase property names for JSON/JavaScript convention
            $response = @{
                scanId = $scan.ScanId
                network = $scan.Network
                status = $scan.Status
                progress = $scan.Progress
                startTime = $scan.StartTime
                endTime = if ($scan.EndTime) { $scan.EndTime } else { $null }
                results = if ($scan.Results) { $scan.Results } else { @() }
            }

            # Add error if present
            if ($scan.Error) {
                $response.error = $scan.Error
            }

            Write-PodeJsonResponse -Value $response
        }
        else {
            Write-PodeJsonResponse -Value @{ error = 'Scan not found' } -StatusCode 404
        }
    }

    # Get scan history
    Add-PodeRoute -Method Get -Path '/api/history' -ScriptBlock {
        # Try to get from database first if connection is configured
        if ((Get-PodeState -Name 'Config').DatabaseConnectionString) {
            try {
                $connection = New-Object System.Data.SqlClient.SqlConnection((Get-PodeState -Name 'Config').DatabaseConnectionString)
                $connection.Open()

                $limit = if ($WebEvent.Query['limit']) { [int]$WebEvent.Query['limit'] } else { 100 }

                $query = @"
SELECT TOP $limit
    s.ScanId,
    s.ScanDate as StartTime,
    s.ScanEndTime as EndTime,
    s.Duration,
    s.NetworkCount,
    s.TotalHostsScanned as HostsScanned,
    s.TotalHostsReachable as HostsReachable,
    s.TotalHostsUnreachable as HostsUnreachable,
    s.InputFile,
    COUNT(DISTINCT sr.Network) as Networks
FROM [dbo].[Scans] s
LEFT JOIN [dbo].[ScanResults] sr ON s.ScanId = sr.ScanId
GROUP BY s.ScanId, s.ScanDate, s.ScanEndTime, s.Duration, s.NetworkCount,
         s.TotalHostsScanned, s.TotalHostsReachable, s.TotalHostsUnreachable, s.InputFile
ORDER BY s.ScanDate DESC
"@

                $command = $connection.CreateCommand()
                $command.CommandText = $query
                $reader = $command.ExecuteReader()

                $history = @()
                while ($reader.Read()) {
                    $history += @{
                        scanId = $reader["ScanId"]
                        startTime = $reader["StartTime"]
                        endTime = if ($reader["EndTime"] -ne [DBNull]::Value) { $reader["EndTime"] } else { $null }
                        duration = if ($reader["Duration"] -ne [DBNull]::Value) { $reader["Duration"] } else { "N/A" }
                        network = if ($reader["InputFile"] -ne [DBNull]::Value) { $reader["InputFile"] } else { "Multiple Networks" }
                        hostsScanned = $reader["HostsScanned"]
                        hostsReachable = $reader["HostsReachable"]
                        hostsUnreachable = $reader["HostsUnreachable"]
                    }
                }

                $reader.Close()
                $connection.Close()

                Write-PodeJsonResponse -Value $history
                return
            }
            catch {
                Write-Host "Database query failed, falling back to in-memory history: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }

        # Fallback to in-memory history
        $history = (Get-PodeState -Name 'ScanHistory') | Sort-Object -Property startTime -Descending

        if ($WebEvent.Query['limit']) {
            $history = $history | Select-Object -First ([int]$WebEvent.Query['limit'])
        }

        Write-PodeJsonResponse -Value $history
    }

    #endregion

    # Server started message
    $config = Get-PodeState -Name 'Config'
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "  Ping-Networks Web Dashboard Started" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  URL: http://localhost:$($config.Port)" -ForegroundColor White
    if ($config.EnableAuth) {
        Write-Host "  Authentication: Enabled" -ForegroundColor Yellow
        Write-Host "  Username: $($config.Username)" -ForegroundColor Gray
    }
    else {
        Write-Host "  Authentication: Disabled" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "  Press Ctrl+C to stop the server" -ForegroundColor Gray
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
}
