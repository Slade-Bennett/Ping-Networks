# ReportUtils.psm1
# Report Generation Utilities
#
# This module provides functions for generating various report formats
# including HTML, JSON, and XML from network scan results.

<#
.SYNOPSIS
    Generates a professional HTML report from network scan results.
.DESCRIPTION
    Creates an interactive HTML report with:
    - Summary statistics and metadata (scan date, time, duration)
    - Sortable results table with all scan data
    - Visual pie chart showing reachable vs unreachable hosts
    - Professional CSS styling for easy sharing
    - Self-contained single-file output
.PARAMETER Results
    Array of scan result objects with Network, Host, Status, and Hostname properties.
.PARAMETER OutputPath
    Full path where the HTML report should be saved.
.PARAMETER ScanMetadata
    Optional hashtable with scan metadata (StartTime, EndTime, NetworkCount, etc.)
.OUTPUTS
    None. Creates an HTML file at the specified OutputPath.
.EXAMPLE
    $results = @(
        [PSCustomObject]@{Network="10.0.0.0/24"; Host="10.0.0.1"; Status="Reachable"; Hostname="router.local"}
        [PSCustomObject]@{Network="10.0.0.0/24"; Host="10.0.0.2"; Status="Unreachable"; Hostname="N/A"}
    )
    Export-HtmlReport -Results $results -OutputPath "C:\Reports\scan.html"
.NOTES
    Generates a self-contained HTML file with embedded CSS and JavaScript.
    Compatible with all modern browsers.
#>
function Export-HtmlReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Results,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [hashtable]$ScanMetadata = @{}
    )

    # Calculate summary statistics
    $totalHosts = $Results.Count
    $reachableHosts = ($Results | Where-Object { $_.Status -eq "Reachable" }).Count
    $unreachableHosts = $totalHosts - $reachableHosts
    $reachablePercent = if ($totalHosts -gt 0) { [math]::Round(($reachableHosts / $totalHosts) * 100, 1) } else { 0 }
    $unreachablePercent = if ($totalHosts -gt 0) { [math]::Round(($unreachableHosts / $totalHosts) * 100, 1) } else { 0 }

    # Get unique networks
    $networks = ($Results | Select-Object -ExpandProperty Network -Unique)
    $networkCount = $networks.Count

    # Extract metadata with defaults
    $scanDate = if ($ScanMetadata.ContainsKey('ScanDate')) { $ScanMetadata.ScanDate } else { Get-Date -Format "yyyy-MM-dd HH:mm:ss" }
    $duration = if ($ScanMetadata.ContainsKey('Duration')) { $ScanMetadata.Duration } else { "N/A" }

    # Generate HTML content
    $htmlContent = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Network Scan Report - $scanDate</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 20px;
            min-height: 100vh;
        }

        .container {
            max-width: 1400px;
            margin: 0 auto;
            background: white;
            border-radius: 12px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
            overflow: hidden;
        }

        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 40px;
            text-align: center;
        }

        .header h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
        }

        .header p {
            font-size: 1.1em;
            opacity: 0.9;
        }

        .metadata {
            background: #f8f9fa;
            padding: 20px 40px;
            border-bottom: 1px solid #e0e0e0;
            display: flex;
            justify-content: space-around;
            flex-wrap: wrap;
        }

        .metadata-item {
            text-align: center;
            padding: 10px;
        }

        .metadata-label {
            font-size: 0.85em;
            color: #666;
            text-transform: uppercase;
            letter-spacing: 1px;
        }

        .metadata-value {
            font-size: 1.3em;
            font-weight: bold;
            color: #333;
            margin-top: 5px;
        }

        .summary {
            padding: 40px;
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
        }

        .stat-card {
            background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
            padding: 25px;
            border-radius: 8px;
            text-align: center;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
            transition: transform 0.2s;
        }

        .stat-card:hover {
            transform: translateY(-5px);
        }

        .stat-card.success {
            background: linear-gradient(135deg, #84fab0 0%, #8fd3f4 100%);
        }

        .stat-card.danger {
            background: linear-gradient(135deg, #fa709a 0%, #fee140 100%);
        }

        .stat-number {
            font-size: 2.5em;
            font-weight: bold;
            color: #333;
        }

        .stat-label {
            font-size: 0.9em;
            color: #555;
            margin-top: 5px;
            text-transform: uppercase;
            letter-spacing: 1px;
        }

        .chart-container {
            padding: 40px;
            text-align: center;
        }

        .chart-wrapper {
            max-width: 400px;
            margin: 0 auto;
        }

        .table-container {
            padding: 0 40px 40px 40px;
        }

        .table-controls {
            margin-bottom: 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 10px;
        }

        .search-box {
            padding: 10px 15px;
            border: 2px solid #e0e0e0;
            border-radius: 6px;
            font-size: 1em;
            width: 300px;
            transition: border-color 0.3s;
        }

        .search-box:focus {
            outline: none;
            border-color: #667eea;
        }

        .filter-buttons {
            display: flex;
            gap: 10px;
        }

        .filter-btn {
            padding: 10px 20px;
            border: 2px solid #667eea;
            background: white;
            color: #667eea;
            border-radius: 6px;
            cursor: pointer;
            transition: all 0.3s;
            font-weight: 600;
        }

        .filter-btn:hover, .filter-btn.active {
            background: #667eea;
            color: white;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            background: white;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            border-radius: 8px;
            overflow: hidden;
        }

        thead {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }

        th {
            padding: 15px;
            text-align: left;
            font-weight: 600;
            cursor: pointer;
            user-select: none;
            position: relative;
        }

        th:hover {
            background: rgba(255,255,255,0.1);
        }

        th::after {
            content: ' ⇅';
            opacity: 0.5;
        }

        th.sort-asc::after {
            content: ' ↑';
            opacity: 1;
        }

        th.sort-desc::after {
            content: ' ↓';
            opacity: 1;
        }

        td {
            padding: 12px 15px;
            border-bottom: 1px solid #f0f0f0;
        }

        tr:hover {
            background: #f8f9fa;
        }

        .status-badge {
            display: inline-block;
            padding: 5px 12px;
            border-radius: 20px;
            font-size: 0.85em;
            font-weight: 600;
        }

        .status-reachable {
            background: #d4edda;
            color: #155724;
        }

        .status-unreachable {
            background: #f8d7da;
            color: #721c24;
        }

        .footer {
            background: #f8f9fa;
            padding: 20px;
            text-align: center;
            color: #666;
            font-size: 0.9em;
        }

        canvas {
            max-width: 100%;
            height: auto;
        }
    </style>
</head>
<body>
    <div class="container">
        <!-- Header -->
        <div class="header">
            <h1>🌐 Network Scan Report</h1>
            <p>Comprehensive Network Analysis Results</p>
        </div>

        <!-- Metadata -->
        <div class="metadata">
            <div class="metadata-item">
                <div class="metadata-label">Scan Date</div>
                <div class="metadata-value">$scanDate</div>
            </div>
            <div class="metadata-item">
                <div class="metadata-label">Networks Scanned</div>
                <div class="metadata-value">$networkCount</div>
            </div>
            <div class="metadata-item">
                <div class="metadata-label">Duration</div>
                <div class="metadata-value">$duration</div>
            </div>
        </div>

        <!-- Summary Statistics -->
        <div class="summary">
            <div class="stat-card">
                <div class="stat-number">$totalHosts</div>
                <div class="stat-label">Total Hosts Scanned</div>
            </div>
            <div class="stat-card success">
                <div class="stat-number">$reachableHosts</div>
                <div class="stat-label">Reachable ($reachablePercent%)</div>
            </div>
            <div class="stat-card danger">
                <div class="stat-number">$unreachableHosts</div>
                <div class="stat-label">Unreachable ($unreachablePercent%)</div>
            </div>
        </div>

        <!-- Chart -->
        <div class="chart-container">
            <h2 style="margin-bottom: 30px; color: #333;">Host Status Distribution</h2>
            <div class="chart-wrapper">
                <canvas id="statusChart"></canvas>
            </div>
        </div>

        <!-- Results Table -->
        <div class="table-container">
            <h2 style="margin-bottom: 20px; color: #333;">Detailed Scan Results</h2>

            <div class="table-controls">
                <input type="text" id="searchBox" class="search-box" placeholder="Search by network, host, or hostname...">
                <div class="filter-buttons">
                    <button class="filter-btn active" data-filter="all">All</button>
                    <button class="filter-btn" data-filter="reachable">Reachable</button>
                    <button class="filter-btn" data-filter="unreachable">Unreachable</button>
                </div>
            </div>

            <table id="resultsTable">
                <thead>
                    <tr>
                        <th data-column="network">Network</th>
                        <th data-column="host">Host</th>
                        <th data-column="status">Status</th>
                        <th data-column="hostname">Hostname</th>
                    </tr>
                </thead>
                <tbody>
"@

    # Add table rows
    foreach ($result in $Results) {
        $statusClass = if ($result.Status -eq "Reachable") { "status-reachable" } else { "status-unreachable" }
        $htmlContent += @"
                    <tr data-status="$($result.Status.ToLower())">
                        <td>$($result.Network)</td>
                        <td>$($result.Host)</td>
                        <td><span class="status-badge $statusClass">$($result.Status)</span></td>
                        <td>$($result.Hostname)</td>
                    </tr>
"@
    }

    # Complete the HTML with JavaScript
    $htmlContent += @"
                </tbody>
            </table>
        </div>

        <!-- Footer -->
        <div class="footer">
            Generated by Ping-Networks v1.2.0 | <a href="https://github.com/Slade-Bennett/Ping-Networks" style="color: #667eea; text-decoration: none;">GitHub Repository</a>
        </div>
    </div>

    <!-- Chart.js CDN -->
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>

    <script>
        // Create pie chart
        const ctx = document.getElementById('statusChart').getContext('2d');
        new Chart(ctx, {
            type: 'pie',
            data: {
                labels: ['Reachable', 'Unreachable'],
                datasets: [{
                    data: [$reachableHosts, $unreachableHosts],
                    backgroundColor: [
                        'rgba(132, 250, 176, 0.8)',
                        'rgba(250, 112, 154, 0.8)'
                    ],
                    borderColor: [
                        'rgba(132, 250, 176, 1)',
                        'rgba(250, 112, 154, 1)'
                    ],
                    borderWidth: 2
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: true,
                plugins: {
                    legend: {
                        position: 'bottom',
                        labels: {
                            font: { size: 14 },
                            padding: 20
                        }
                    },
                    tooltip: {
                        callbacks: {
                            label: function(context) {
                                const label = context.label || '';
                                const value = context.parsed || 0;
                                const total = context.dataset.data.reduce((a, b) => a + b, 0);
                                const percentage = ((value / total) * 100).toFixed(1);
                                return label + ': ' + value + ' (' + percentage + '%)';
                            }
                        }
                    }
                }
            }
        });

        // Table sorting functionality
        const table = document.getElementById('resultsTable');
        const headers = table.querySelectorAll('th');
        let sortDirection = {};

        headers.forEach(header => {
            const column = header.dataset.column;
            sortDirection[column] = 'asc';

            header.addEventListener('click', () => {
                const rows = Array.from(table.querySelectorAll('tbody tr'));
                const currentDir = sortDirection[column];
                const newDir = currentDir === 'asc' ? 'desc' : 'asc';

                // Remove sort classes from all headers
                headers.forEach(h => h.classList.remove('sort-asc', 'sort-desc'));

                // Add sort class to current header
                header.classList.add('sort-' + newDir);
                sortDirection[column] = newDir;

                // Sort rows
                rows.sort((a, b) => {
                    const aValue = a.children[Array.from(headers).indexOf(header)].textContent.trim();
                    const bValue = b.children[Array.from(headers).indexOf(header)].textContent.trim();

                    if (newDir === 'asc') {
                        return aValue.localeCompare(bValue, undefined, { numeric: true });
                    } else {
                        return bValue.localeCompare(aValue, undefined, { numeric: true });
                    }
                });

                // Re-append sorted rows
                const tbody = table.querySelector('tbody');
                rows.forEach(row => tbody.appendChild(row));
            });
        });

        // Search functionality
        const searchBox = document.getElementById('searchBox');
        searchBox.addEventListener('input', filterTable);

        // Filter buttons
        const filterButtons = document.querySelectorAll('.filter-btn');
        let activeFilter = 'all';

        filterButtons.forEach(btn => {
            btn.addEventListener('click', () => {
                filterButtons.forEach(b => b.classList.remove('active'));
                btn.classList.add('active');
                activeFilter = btn.dataset.filter;
                filterTable();
            });
        });

        function filterTable() {
            const searchTerm = searchBox.value.toLowerCase();
            const rows = table.querySelectorAll('tbody tr');

            rows.forEach(row => {
                const network = row.children[0].textContent.toLowerCase();
                const host = row.children[1].textContent.toLowerCase();
                const hostname = row.children[3].textContent.toLowerCase();
                const status = row.dataset.status;

                const matchesSearch = network.includes(searchTerm) ||
                                     host.includes(searchTerm) ||
                                     hostname.includes(searchTerm);

                const matchesFilter = activeFilter === 'all' || status === activeFilter;

                if (matchesSearch && matchesFilter) {
                    row.style.display = '';
                } else {
                    row.style.display = 'none';
                }
            });
        }
    </script>
</body>
</html>
"@

    # Write HTML to file
    try {
        $htmlContent | Out-File -FilePath $OutputPath -Encoding UTF8 -Force
        Write-Verbose "HTML report generated successfully: $OutputPath"
    }
    catch {
        Write-Error "Failed to create HTML report at '$OutputPath': $_"
    }
}

<#
.SYNOPSIS
    Exports network scan results to JSON format.
.DESCRIPTION
    Creates a well-formatted JSON file containing scan results and metadata.
    The JSON output includes:
    - Scan metadata (date, duration, summary statistics)
    - Detailed results array with all scanned hosts
    - Structured format suitable for programmatic consumption
.PARAMETER Results
    Array of scan result objects with Network, Host, Status, and Hostname properties.
.PARAMETER OutputPath
    Full path where the JSON file should be saved.
.PARAMETER ScanMetadata
    Optional hashtable with scan metadata (StartTime, EndTime, NetworkCount, etc.)
.OUTPUTS
    None. Creates a JSON file at the specified OutputPath.
.EXAMPLE
    $results = @(
        [PSCustomObject]@{Network="10.0.0.0/24"; Host="10.0.0.1"; Status="Reachable"; Hostname="router.local"}
    )
    Export-JsonReport -Results $results -OutputPath "C:\Reports\scan.json"
.NOTES
    Uses ConvertTo-Json with -Depth parameter to ensure complete serialization.
    Output is formatted with proper indentation for readability.
#>
function Export-JsonReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Results,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [hashtable]$ScanMetadata = @{}
    )

    try {
        # Calculate summary statistics
        $totalHosts = $Results.Count
        $reachableHosts = ($Results | Where-Object { $_.Status -eq "Reachable" }).Count
        $unreachableHosts = $totalHosts - $reachableHosts
        $reachablePercent = if ($totalHosts -gt 0) { [math]::Round(($reachableHosts / $totalHosts) * 100, 2) } else { 0 }

        # Get unique networks
        $networks = ($Results | Select-Object -ExpandProperty Network -Unique)
        $networkCount = $networks.Count

        # Extract metadata with defaults
        $scanDate = if ($ScanMetadata.ContainsKey('ScanDate')) { $ScanMetadata.ScanDate } else { Get-Date -Format "yyyy-MM-dd HH:mm:ss" }
        $duration = if ($ScanMetadata.ContainsKey('Duration')) { $ScanMetadata.Duration } else { "N/A" }

        # Create structured JSON object
        $jsonObject = [PSCustomObject]@{
            ScanMetadata = [PSCustomObject]@{
                ScanDate = $scanDate
                Duration = $duration
                NetworksScanned = $networkCount
                TotalHosts = $totalHosts
                ReachableHosts = $reachableHosts
                UnreachableHosts = $unreachableHosts
                ReachablePercent = $reachablePercent
            }
            Networks = $networks
            Results = $Results
        }

        # Convert to JSON with proper formatting
        $jsonContent = $jsonObject | ConvertTo-Json -Depth 10

        # Write to file
        $jsonContent | Out-File -FilePath $OutputPath -Encoding UTF8 -Force
        Write-Verbose "JSON report generated successfully: $OutputPath"
    }
    catch {
        Write-Error "Failed to create JSON report at '$OutputPath': $_"
    }
}

<#
.SYNOPSIS
    Exports network scan results to XML format.
.DESCRIPTION
    Creates a well-structured XML file containing scan results and metadata.
    The XML output includes:
    - Root element with scan metadata attributes
    - Summary statistics element
    - Results collection with individual host entries
    - Proper XML schema for easy parsing
.PARAMETER Results
    Array of scan result objects with Network, Host, Status, and Hostname properties.
.PARAMETER OutputPath
    Full path where the XML file should be saved.
.PARAMETER ScanMetadata
    Optional hashtable with scan metadata (StartTime, EndTime, NetworkCount, etc.)
.OUTPUTS
    None. Creates an XML file at the specified OutputPath.
.EXAMPLE
    $results = @(
        [PSCustomObject]@{Network="10.0.0.0/24"; Host="10.0.0.1"; Status="Reachable"; Hostname="router.local"}
    )
    Export-XmlReport -Results $results -OutputPath "C:\Reports\scan.xml"
.NOTES
    Uses XmlWriter for proper XML formatting and encoding.
    Compatible with most XML parsers and tools.
#>
function Export-XmlReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Results,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [hashtable]$ScanMetadata = @{}
    )

    try {
        # Calculate summary statistics
        $totalHosts = $Results.Count
        $reachableHosts = ($Results | Where-Object { $_.Status -eq "Reachable" }).Count
        $unreachableHosts = $totalHosts - $reachableHosts
        $reachablePercent = if ($totalHosts -gt 0) { [math]::Round(($reachableHosts / $totalHosts) * 100, 2) } else { 0 }

        # Get unique networks
        $networks = ($Results | Select-Object -ExpandProperty Network -Unique)
        $networkCount = $networks.Count

        # Extract metadata with defaults
        $scanDate = if ($ScanMetadata.ContainsKey('ScanDate')) { $ScanMetadata.ScanDate } else { Get-Date -Format "yyyy-MM-dd HH:mm:ss" }
        $duration = if ($ScanMetadata.ContainsKey('Duration')) { $ScanMetadata.Duration } else { "N/A" }

        # Create XML writer with proper settings
        $xmlSettings = New-Object System.Xml.XmlWriterSettings
        $xmlSettings.Indent = $true
        $xmlSettings.IndentChars = "  "
        $xmlSettings.Encoding = [System.Text.Encoding]::UTF8

        $xmlWriter = [System.Xml.XmlWriter]::Create($OutputPath, $xmlSettings)

        # Write XML document
        $xmlWriter.WriteStartDocument()

        # Root element with metadata attributes
        $xmlWriter.WriteStartElement("NetworkScanReport")
        $xmlWriter.WriteAttributeString("ScanDate", $scanDate)
        $xmlWriter.WriteAttributeString("Duration", $duration)

        # Summary element
        $xmlWriter.WriteStartElement("Summary")
        $xmlWriter.WriteElementString("NetworksScanned", $networkCount.ToString())
        $xmlWriter.WriteElementString("TotalHosts", $totalHosts.ToString())
        $xmlWriter.WriteElementString("ReachableHosts", $reachableHosts.ToString())
        $xmlWriter.WriteElementString("UnreachableHosts", $unreachableHosts.ToString())
        $xmlWriter.WriteElementString("ReachablePercent", $reachablePercent.ToString())
        $xmlWriter.WriteEndElement() # Summary

        # Networks element
        $xmlWriter.WriteStartElement("Networks")
        foreach ($network in $networks) {
            $xmlWriter.WriteElementString("Network", $network)
        }
        $xmlWriter.WriteEndElement() # Networks

        # Results element
        $xmlWriter.WriteStartElement("Results")
        foreach ($result in $Results) {
            $xmlWriter.WriteStartElement("Host")
            $xmlWriter.WriteElementString("Network", $result.Network)
            $xmlWriter.WriteElementString("IPAddress", $result.Host)
            $xmlWriter.WriteElementString("Status", $result.Status)
            $xmlWriter.WriteElementString("Hostname", $result.Hostname)
            $xmlWriter.WriteEndElement() # Host
        }
        $xmlWriter.WriteEndElement() # Results

        $xmlWriter.WriteEndElement() # NetworkScanReport
        $xmlWriter.WriteEndDocument()
        $xmlWriter.Flush()
        $xmlWriter.Close()

        Write-Verbose "XML report generated successfully: $OutputPath"
    }
    catch {
        Write-Error "Failed to create XML report at '$OutputPath': $_"
    }
    finally {
        if ($xmlWriter) {
            $xmlWriter.Dispose()
        }
    }
}

Export-ModuleMember -Function Export-HtmlReport, Export-JsonReport, Export-XmlReport
