# Test-DatabaseExport.ps1
# End-to-end testing for database export functionality

param(
    [string]$ConnectionString = "Server=localhost;Database=PingNetworks;Integrated Security=True",
    [string]$DatabaseType = "SQLServer"
)

Write-Host "=== Ping-Networks Database Export Test ===" -ForegroundColor Cyan
Write-Host ""

# Import required modules
$modulePath = Join-Path $PSScriptRoot "..\modules\DatabaseUtils.psm1"
Import-Module $modulePath -Force

# Test 1: Database Connection
Write-Host "[Test 1] Testing database connection..." -ForegroundColor Yellow
try {
    $connectionTest = Test-DatabaseConnection -ConnectionString $ConnectionString -DatabaseType $DatabaseType
    if ($connectionTest) {
        Write-Host "  [PASS] Database connection successful" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] Database connection failed" -ForegroundColor Red
        Write-Host ""
        Write-Host "Please ensure:" -ForegroundColor Yellow
        Write-Host "  1. SQL Server is installed and running" -ForegroundColor Yellow
        Write-Host "  2. Database 'PingNetworks' exists, or change connection string to use master" -ForegroundColor Yellow
        Write-Host "  3. You have appropriate permissions" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Example connection strings:" -ForegroundColor Cyan
        Write-Host "  LocalDB: Server=(localdb)\MSSQLLocalDB;Database=PingNetworks;Integrated Security=True" -ForegroundColor Gray
        Write-Host "  SQL Express: Server=.\SQLEXPRESS;Database=PingNetworks;Integrated Security=True" -ForegroundColor Gray
        Write-Host "  Full SQL: Server=localhost;Database=PingNetworks;Integrated Security=True" -ForegroundColor Gray
        exit 1
    }
} catch {
    Write-Host "  [FAIL] Exception: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Test 2: Database Schema Initialization
Write-Host "[Test 2] Testing database schema initialization..." -ForegroundColor Yellow
try {
    Initialize-DatabaseSchema -ConnectionString $ConnectionString -DatabaseType $DatabaseType
    Write-Host "  [PASS] Database schema initialized" -ForegroundColor Green
} catch {
    Write-Host "  [FAIL] Schema initialization failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Test 3: Export Mock Scan Results
Write-Host "[Test 3] Testing scan results export..." -ForegroundColor Yellow
try {
    # Create mock scan results
    $mockResults = @(
        [PSCustomObject]@{
            Network = "10.0.0.0/24"
            Host = "10.0.0.1"
            Status = "Reachable"
            Hostname = "gateway.local"
            ResponseTimeMin = 1
            ResponseTimeMax = 5
            ResponseTimeAvg = 3
            PacketLoss = 0
            PingsSent = 4
            PingsReceived = 4
        },
        [PSCustomObject]@{
            Network = "10.0.0.0/24"
            Host = "10.0.0.2"
            Status = "Unreachable"
            Hostname = $null
            ResponseTimeMin = $null
            ResponseTimeMax = $null
            ResponseTimeAvg = $null
            PacketLoss = 100
            PingsSent = 4
            PingsReceived = 0
        },
        [PSCustomObject]@{
            Network = "192.168.1.0/24"
            Host = "192.168.1.100"
            Status = "Reachable"
            Hostname = "workstation01.local"
            ResponseTimeMin = 2
            ResponseTimeMax = 8
            ResponseTimeAvg = 5
            PacketLoss = 0
            PingsSent = 4
            PingsReceived = 4
        }
    )

    # Create mock metadata
    $mockMetadata = @{
        ScanDate = Get-Date
        ScanStartTime = (Get-Date).AddMinutes(-2)
        ScanEndTime = Get-Date
        Duration = "00:02:00"
        NetworkCount = 2
        InputFile = "test-input.xlsx"
        OutputDirectory = "C:\Temp\TestScan"
        Throttle = 50
    }

    # Export to database
    $scanId = Export-DatabaseResults -Results $mockResults `
                                      -ScanMetadata $mockMetadata `
                                      -ConnectionString $ConnectionString `
                                      -DatabaseType $DatabaseType

    if ($scanId -gt 0) {
        Write-Host "  [PASS] Scan results exported successfully (ScanId: $scanId)" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] Export returned invalid ScanId" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "  [FAIL] Export failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Test 4: Verify Data in Database
Write-Host "[Test 4] Verifying exported data..." -ForegroundColor Yellow
try {
    $connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
    $connection.Open()

    # Check Scans table
    $cmdScans = $connection.CreateCommand()
    $cmdScans.CommandText = "SELECT COUNT(*) FROM [dbo].[Scans] WHERE ScanId = @ScanId"
    $cmdScans.Parameters.AddWithValue("@ScanId", $scanId) | Out-Null
    $scanCount = $cmdScans.ExecuteScalar()

    if ($scanCount -eq 1) {
        Write-Host "  [PASS] Scan metadata record found" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] Scan metadata not found" -ForegroundColor Red
    }

    # Check ScanResults table
    $cmdResults = $connection.CreateCommand()
    $cmdResults.CommandText = "SELECT COUNT(*) FROM [dbo].[ScanResults] WHERE ScanId = @ScanId"
    $cmdResults.Parameters.AddWithValue("@ScanId", $scanId) | Out-Null
    $resultCount = $cmdResults.ExecuteScalar()

    if ($resultCount -eq 3) {
        Write-Host "  [PASS] All scan results found ($resultCount records)" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] Expected 3 results, found $resultCount" -ForegroundColor Red
    }

    # Check reachable/unreachable counts
    $cmdReachable = $connection.CreateCommand()
    $cmdReachable.CommandText = "SELECT COUNT(*) FROM [dbo].[ScanResults] WHERE ScanId = @ScanId AND Status = 'Reachable'"
    $cmdReachable.Parameters.AddWithValue("@ScanId", $scanId) | Out-Null
    $reachableCount = $cmdReachable.ExecuteScalar()

    if ($reachableCount -eq 2) {
        Write-Host "  [PASS] Correct reachable count (2)" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] Expected 2 reachable, found $reachableCount" -ForegroundColor Red
    }

    $connection.Close()
} catch {
    Write-Host "  [FAIL] Verification failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Test 5: Query Sample Data
Write-Host "[Test 5] Querying sample data..." -ForegroundColor Yellow
try {
    $connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
    $connection.Open()

    $cmdQuery = $connection.CreateCommand()
    $cmdQuery.CommandText = @"
SELECT TOP 5
    s.ScanId,
    s.ScanDate,
    s.TotalHostsScanned,
    s.TotalHostsReachable,
    sr.Host,
    sr.Status,
    sr.ResponseTimeAvg
FROM [dbo].[Scans] s
INNER JOIN [dbo].[ScanResults] sr ON s.ScanId = sr.ScanId
ORDER BY s.ScanDate DESC, sr.Host
"@

    $reader = $cmdQuery.ExecuteReader()
    $rowCount = 0

    Write-Host ""
    Write-Host "  Sample Data from Database:" -ForegroundColor Cyan
    Write-Host "  " + ("-" * 80) -ForegroundColor Gray

    while ($reader.Read()) {
        $rowCount++
        Write-Host ("  ScanId: {0} | Host: {1,-15} | Status: {2,-12} | AvgRT: {3}ms" -f `
            $reader["ScanId"],
            $reader["Host"],
            $reader["Status"],
            $(if ($reader["ResponseTimeAvg"] -ne [DBNull]::Value) { $reader["ResponseTimeAvg"] } else { "N/A" })
        ) -ForegroundColor White
    }

    $reader.Close()
    $connection.Close()

    if ($rowCount -gt 0) {
        Write-Host "  " + ("-" * 80) -ForegroundColor Gray
        Write-Host "  [PASS] Successfully queried $rowCount records" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] No records found" -ForegroundColor Red
    }
} catch {
    Write-Host "  [FAIL] Query failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Summary
Write-Host "=== Test Summary ===" -ForegroundColor Cyan
Write-Host "All database export tests passed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Database: $ConnectionString" -ForegroundColor Gray
Write-Host "Test ScanId: $scanId" -ForegroundColor Gray
Write-Host ""
Write-Host "You can now use the database export feature by adding these parameters:" -ForegroundColor Yellow
Write-Host "  -DatabaseExport" -ForegroundColor White
Write-Host "  -DatabaseConnectionString `"$ConnectionString`"" -ForegroundColor White
Write-Host "  -DatabaseType $DatabaseType" -ForegroundColor White
Write-Host "  -InitializeDatabase (first time only)" -ForegroundColor White
Write-Host ""
