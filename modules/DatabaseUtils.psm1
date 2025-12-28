# DatabaseUtils.psm1
# Database Export and Management Utilities
#
# This module provides functions for exporting scan results to various database backends
# including SQL Server, MySQL, and PostgreSQL.

<#
.SYNOPSIS
    Tests database connectivity.
.DESCRIPTION
    Attempts to connect to the specified database server and returns true if successful.
.PARAMETER ConnectionString
    Database connection string
.PARAMETER DatabaseType
    Type of database: 'SQLServer', 'MySQL', or 'PostgreSQL'
.OUTPUTS
    Boolean indicating connection success
.EXAMPLE
    Test-DatabaseConnection -ConnectionString "Server=localhost;Database=PingNetworks;Integrated Security=True" -DatabaseType "SQLServer"
#>
function Test-DatabaseConnection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConnectionString,

        [Parameter(Mandatory = $true)]
        [ValidateSet('SQLServer', 'MySQL', 'PostgreSQL')]
        [string]$DatabaseType
    )

    try {
        switch ($DatabaseType) {
            'SQLServer' {
                $connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
                $connection.Open()
                $connection.Close()
                return $true
            }
            'MySQL' {
                # MySQL support requires MySQL.Data.dll
                Write-Warning "MySQL support requires MySQL Connector/NET to be installed."
                return $false
            }
            'PostgreSQL' {
                # PostgreSQL support requires Npgsql.dll
                Write-Warning "PostgreSQL support requires Npgsql to be installed."
                return $false
            }
        }
    }
    catch {
        Write-Error "Database connection failed: $($_.Exception.Message)"
        return $false
    }
}

<#
.SYNOPSIS
    Initializes database schema for Ping-Networks.
.DESCRIPTION
    Creates the necessary tables in the database if they don't exist.
    Tables created:
    - Scans: Metadata about each scan
    - ScanResults: Individual host ping results
.PARAMETER ConnectionString
    Database connection string
.PARAMETER DatabaseType
    Type of database: 'SQLServer', 'MySQL', or 'PostgreSQL'
.OUTPUTS
    None
.EXAMPLE
    Initialize-DatabaseSchema -ConnectionString "Server=localhost;Database=PingNetworks;Integrated Security=True" -DatabaseType "SQLServer"
#>
function Initialize-DatabaseSchema {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConnectionString,

        [Parameter(Mandatory = $true)]
        [ValidateSet('SQLServer', 'MySQL', 'PostgreSQL')]
        [string]$DatabaseType
    )

    Write-Verbose "Initializing database schema for $DatabaseType"

    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
        $connection.Open()

        # Create Scans table
        $createScansTable = @"
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Scans]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Scans] (
        [ScanId] INT IDENTITY(1,1) PRIMARY KEY,
        [ScanDate] DATETIME NOT NULL,
        [ScanStartTime] DATETIME NULL,
        [ScanEndTime] DATETIME NULL,
        [Duration] VARCHAR(50) NULL,
        [NetworkCount] INT NOT NULL,
        [TotalHostsScanned] INT NOT NULL,
        [TotalHostsReachable] INT NOT NULL,
        [TotalHostsUnreachable] INT NOT NULL,
        [InputFile] VARCHAR(500) NULL,
        [OutputDirectory] VARCHAR(500) NULL,
        [Throttle] INT NULL,
        [CreatedDate] DATETIME DEFAULT GETDATE()
    )
END
"@

        $command = $connection.CreateCommand()
        $command.CommandText = $createScansTable
        $command.ExecuteNonQuery() | Out-Null
        Write-Verbose "Scans table created or already exists"

        # Create ScanResults table
        $createResultsTable = @"
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ScanResults]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[ScanResults] (
        [ResultId] INT IDENTITY(1,1) PRIMARY KEY,
        [ScanId] INT NOT NULL,
        [Network] VARCHAR(100) NOT NULL,
        [Host] VARCHAR(50) NOT NULL,
        [Status] VARCHAR(20) NOT NULL,
        [Hostname] VARCHAR(255) NULL,
        [ResponseTimeMin] INT NULL,
        [ResponseTimeMax] INT NULL,
        [ResponseTimeAvg] INT NULL,
        [PacketLoss] DECIMAL(5,2) NULL,
        [PingsSent] INT NULL,
        [PingsReceived] INT NULL,
        [CreatedDate] DATETIME DEFAULT GETDATE(),
        FOREIGN KEY ([ScanId]) REFERENCES [dbo].[Scans]([ScanId])
    )
    CREATE INDEX IX_ScanResults_ScanId ON [dbo].[ScanResults]([ScanId])
    CREATE INDEX IX_ScanResults_Network ON [dbo].[ScanResults]([Network])
    CREATE INDEX IX_ScanResults_Status ON [dbo].[ScanResults]([Status])
END
"@

        $command.CommandText = $createResultsTable
        $command.ExecuteNonQuery() | Out-Null
        Write-Verbose "ScanResults table created or already exists"

        $connection.Close()
        Write-Host "Database schema initialized successfully" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to initialize database schema: $($_.Exception.Message)"
        throw
    }
}

<#
.SYNOPSIS
    Exports scan results to a database.
.DESCRIPTION
    Inserts scan metadata and results into the database tables.
.PARAMETER Results
    Array of scan result objects
.PARAMETER ScanMetadata
    Hashtable containing scan metadata
.PARAMETER ConnectionString
    Database connection string
.PARAMETER DatabaseType
    Type of database: 'SQLServer', 'MySQL', or 'PostgreSQL'
.OUTPUTS
    Integer ScanId of the inserted scan
.EXAMPLE
    Export-DatabaseResults -Results $results -ScanMetadata $metadata -ConnectionString $connString -DatabaseType "SQLServer"
#>
function Export-DatabaseResults {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Results,

        [Parameter(Mandatory = $true)]
        [hashtable]$ScanMetadata,

        [Parameter(Mandatory = $true)]
        [string]$ConnectionString,

        [Parameter(Mandatory = $true)]
        [ValidateSet('SQLServer', 'MySQL', 'PostgreSQL')]
        [string]$DatabaseType
    )

    Write-Verbose "Exporting scan results to $DatabaseType database"

    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
        $connection.Open()

        # Insert scan metadata
        $insertScan = @"
INSERT INTO [dbo].[Scans] (
    [ScanDate], [ScanStartTime], [ScanEndTime], [Duration], [NetworkCount],
    [TotalHostsScanned], [TotalHostsReachable], [TotalHostsUnreachable],
    [InputFile], [OutputDirectory], [Throttle]
)
VALUES (
    @ScanDate, @ScanStartTime, @ScanEndTime, @Duration, @NetworkCount,
    @TotalHostsScanned, @TotalHostsReachable, @TotalHostsUnreachable,
    @InputFile, @OutputDirectory, @Throttle
);
SELECT CAST(SCOPE_IDENTITY() AS INT);
"@

        $command = $connection.CreateCommand()
        $command.CommandText = $insertScan

        # Add parameters
        $command.Parameters.AddWithValue("@ScanDate", $ScanMetadata.ScanDate) | Out-Null
        $command.Parameters.AddWithValue("@ScanStartTime", $(if ($ScanMetadata.ScanStartTime) { $ScanMetadata.ScanStartTime } else { [DBNull]::Value })) | Out-Null
        $command.Parameters.AddWithValue("@ScanEndTime", $(if ($ScanMetadata.ScanEndTime) { $ScanMetadata.ScanEndTime } else { [DBNull]::Value })) | Out-Null
        $command.Parameters.AddWithValue("@Duration", $(if ($ScanMetadata.Duration) { $ScanMetadata.Duration } else { [DBNull]::Value })) | Out-Null
        $command.Parameters.AddWithValue("@NetworkCount", $(if ($ScanMetadata.NetworkCount) { $ScanMetadata.NetworkCount } else { 0 })) | Out-Null
        $command.Parameters.AddWithValue("@TotalHostsScanned", $Results.Count) | Out-Null

        $reachableCount = ($Results | Where-Object { $_.Status -eq "Reachable" }).Count
        $command.Parameters.AddWithValue("@TotalHostsReachable", $reachableCount) | Out-Null
        $command.Parameters.AddWithValue("@TotalHostsUnreachable", ($Results.Count - $reachableCount)) | Out-Null

        $command.Parameters.AddWithValue("@InputFile", $(if ($ScanMetadata.InputFile) { $ScanMetadata.InputFile } else { [DBNull]::Value })) | Out-Null
        $command.Parameters.AddWithValue("@OutputDirectory", $(if ($ScanMetadata.OutputDirectory) { $ScanMetadata.OutputDirectory } else { [DBNull]::Value })) | Out-Null
        $command.Parameters.AddWithValue("@Throttle", $(if ($ScanMetadata.Throttle) { $ScanMetadata.Throttle } else { [DBNull]::Value })) | Out-Null

        # Execute and get ScanId
        $scanId = $command.ExecuteScalar()
        Write-Verbose "Inserted scan with ScanId: $scanId"

        # Insert scan results in batches for performance
        $batchSize = 100
        $totalResults = $Results.Count
        $processedCount = 0

        Write-Progress -Activity "Exporting to Database" -Status "Inserting scan results..." -PercentComplete 0

        for ($i = 0; $i -lt $totalResults; $i += $batchSize) {
            $batch = $Results[$i..[Math]::Min($i + $batchSize - 1, $totalResults - 1)]

            foreach ($result in $batch) {
                $insertResult = @"
INSERT INTO [dbo].[ScanResults] (
    [ScanId], [Network], [Host], [Status], [Hostname],
    [ResponseTimeMin], [ResponseTimeMax], [ResponseTimeAvg],
    [PacketLoss], [PingsSent], [PingsReceived]
)
VALUES (
    @ScanId, @Network, @Host, @Status, @Hostname,
    @ResponseTimeMin, @ResponseTimeMax, @ResponseTimeAvg,
    @PacketLoss, @PingsSent, @PingsReceived
);
"@

                $cmdResult = $connection.CreateCommand()
                $cmdResult.CommandText = $insertResult

                $cmdResult.Parameters.AddWithValue("@ScanId", $scanId) | Out-Null
                $cmdResult.Parameters.AddWithValue("@Network", $result.Network) | Out-Null
                $cmdResult.Parameters.AddWithValue("@Host", $result.Host) | Out-Null
                $cmdResult.Parameters.AddWithValue("@Status", $result.Status) | Out-Null
                $cmdResult.Parameters.AddWithValue("@Hostname", $(if ($result.Hostname) { $result.Hostname } else { [DBNull]::Value })) | Out-Null
                $cmdResult.Parameters.AddWithValue("@ResponseTimeMin", $(if ($result.ResponseTimeMin) { $result.ResponseTimeMin } else { [DBNull]::Value })) | Out-Null
                $cmdResult.Parameters.AddWithValue("@ResponseTimeMax", $(if ($result.ResponseTimeMax) { $result.ResponseTimeMax } else { [DBNull]::Value })) | Out-Null
                $cmdResult.Parameters.AddWithValue("@ResponseTimeAvg", $(if ($result.ResponseTimeAvg) { $result.ResponseTimeAvg } else { [DBNull]::Value })) | Out-Null
                $cmdResult.Parameters.AddWithValue("@PacketLoss", $(if ($result.PacketLoss) { $result.PacketLoss } else { [DBNull]::Value })) | Out-Null
                $cmdResult.Parameters.AddWithValue("@PingsSent", $(if ($result.PingsSent) { $result.PingsSent } else { [DBNull]::Value })) | Out-Null
                $cmdResult.Parameters.AddWithValue("@PingsReceived", $(if ($result.PingsReceived) { $result.PingsReceived } else { [DBNull]::Value })) | Out-Null

                $cmdResult.ExecuteNonQuery() | Out-Null
                $processedCount++
            }

            $percentComplete = [Math]::Round(($processedCount / $totalResults) * 100)
            Write-Progress -Activity "Exporting to Database" -Status "Inserting scan results... ($processedCount/$totalResults)" -PercentComplete $percentComplete
        }

        Write-Progress -Activity "Exporting to Database" -Completed

        $connection.Close()

        Write-Host "Exported $totalResults scan results to database (ScanId: $scanId)" -ForegroundColor Green
        return $scanId
    }
    catch {
        Write-Error "Failed to export to database: $($_.Exception.Message)"
        throw
    }
}

# Export module members
Export-ModuleMember -Function Test-DatabaseConnection, Initialize-DatabaseSchema, Export-DatabaseResults
