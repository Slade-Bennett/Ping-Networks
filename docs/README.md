# Ping-Networks

Ping-Networks is a PowerShell module that pings all hosts in specified networks from an Excel file and exports comprehensive results to Excel or CSV. It's designed to be a simple, efficient, and reliable tool for network administrators and engineers.

## Features

*   **Complete Network Scanning:** Calculates and pings ALL usable host addresses in each subnet (not just the first host).
*   **Universal CIDR Support:** Works with any standard CIDR notation (/8 through /30) - /24, /28, /16, etc.
*   **Accurate Subnet Calculations:** Uses bitwise operations for precise network address, broadcast address, and host range calculations.
*   **Parallel Execution:** Pings hosts concurrently using PowerShell background jobs for maximum speed (configurable batch size).
*   **DNS Resolution:** Automatically resolves hostnames for reachable hosts.
*   **Multiple Output Formats:**
    *   **Excel:** Color-coded results with summary statistics and per-network worksheets
    *   **HTML:** Interactive web reports with charts, sortable tables, and search functionality
    *   **JSON:** Structured data format ideal for APIs and programmatic processing
    *   **XML:** Hierarchical format compatible with most XML parsers and integration tools
    *   **CSV:** Simple tabular format for spreadsheet import
*   **Enhanced Progress Reporting:** Real-time scan statistics including ETA, scan rate (hosts/sec), and network progress.
*   **Modular Architecture:** Separated into reusable modules (subnet calculation, ping logic, Excel utilities, report generation).

## Requirements

*   PowerShell 5.0 or later.
*   Microsoft Excel installed.

## Usage

The main script `Ping-Networks.ps1` is located in the root directory. You can run it as follows:

```powershell
.\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.xlsx' -OutputPath '.\PingResults.xlsx'
```

### Parameters

*   `InputPath`: (Required) The path to the input Excel file containing the network data. The file should have three columns: 'IP', 'SubnetMask', and 'CIDR'.
*   `OutputPath`: (Optional) The path to the output Excel file where the ping results will be saved. Defaults to a timestamped file in the user's Documents folder.
*   `HtmlPath`: (Optional) The path to the output HTML report. Creates an interactive web report with charts, sortable tables, and professional styling.
*   `JsonPath`: (Optional) The path to the output JSON file. Structured JSON format ideal for APIs, automation, and programmatic processing.
*   `XmlPath`: (Optional) The path to the output XML file. Structured XML format compatible with most XML parsers and integration tools.
*   `CsvPath`: (Optional) The path to the output CSV file where the ping results will be saved.
*   `MaxPings`: (Optional) The maximum number of hosts to ping per network. If not specified, all usable hosts will be pinged.
*   `Timeout`: (Optional) The timeout in seconds for each ping. Default is 1 second.
*   `Retries`: (Optional) The number of retries for each ping. Default is 0.

## Examples

### Basic Usage

```powershell
.\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.xlsx'
```

This will ping all the networks in the `NetworkData.xlsx` file and create a new Excel file in your Documents folder with the results.

### Specify Output Path

```powershell
.\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.xlsx' -OutputPath 'C:\Temp\PingResults.xlsx'
```

This will create the `PingResults.xlsx` file in the `C:\Temp` directory.

### Specify Max Pings

```powershell
.\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.xlsx' -MaxPings 10
```

This will only ping the first 10 usable hosts in each network.

### Generate HTML Report

```powershell
.\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.xlsx' -HtmlPath 'C:\Temp\NetworkReport.html'
```

Creates an interactive HTML report with charts, sortable tables, and search functionality.

### Export to JSON/XML

```powershell
.\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.xlsx' -JsonPath 'C:\Temp\results.json' -XmlPath 'C:\Temp\results.xml'
```

Exports scan results in JSON and XML formats for programmatic consumption and integration with other tools.

### Multiple Output Formats

```powershell
.\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.xlsx' -OutputPath 'results.xlsx' -HtmlPath 'report.html' -JsonPath 'data.json' -XmlPath 'data.xml'
```

Generate all output formats simultaneously from a single scan.

## Architecture

The project is organized into modular components for maintainability:

```
Ping-Networks/
├── modules/
│   ├── Ping-Networks.psm1   # Core functions: subnet calculation, parallel ping
│   ├── ExcelUtils.psm1       # Excel COM automation utilities
│   └── ReportUtils.psm1      # Report generation (HTML, JSON, XML)
├── sample-data/
│   └── NetworkData.xlsx      # Sample Excel input file
├── docs/
│   ├── README.md             # This file
│   └── ROADMAP.md            # Development roadmap
└── Ping-Networks.ps1         # Main entry point script
```

### Key Functions

*   **Get-UsableHosts:** Calculates all valid host IPs in a subnet using bitwise operations. Supports any CIDR from /8 to /30.
*   **Start-Ping:** Performs parallel ICMP pings using PowerShell background jobs with configurable batch sizes. Includes real-time progress tracking with ETA and scan rate calculations.
*   **Excel Utilities:** Suite of functions for COM automation (New-ExcelSession, Read-ExcelSheet, Write-ExcelSheet, etc.).
*   **Report Generation:**
    *   **Export-HtmlReport:** Creates interactive HTML reports with Chart.js visualizations, sortable tables, and search functionality
    *   **Export-JsonReport:** Generates structured JSON output with scan metadata and statistics
    *   **Export-XmlReport:** Produces well-formed XML documents using XmlWriter for proper formatting

## Recent Improvements

### Version 1.2.0 (Latest)
*   **Enhanced Progress Reporting:**
    *   Real-time ETA calculations based on scan throughput
    *   Scan rate display (hosts/second)
    *   Current network display in progress bar
    *   Nested progress bars for network and host-level tracking
*   **Interactive HTML Reports:**
    *   Professional web-based reports with modern gradient design
    *   Chart.js pie charts for visual statistics
    *   Sortable and searchable data tables
    *   Scan metadata (date, duration, statistics)
*   **Multiple Export Formats:**
    *   JSON export with structured metadata and results
    *   XML export with proper hierarchical formatting
    *   Support for simultaneous export to multiple formats
*   **New ReportUtils Module:**
    *   Modular report generation system
    *   Export-HtmlReport, Export-JsonReport, Export-XmlReport functions
    *   Reusable metadata calculation across all formats

### Version 1.1.0
*   **Fixed critical subnet calculation bug** that caused empty IP addresses to be generated
*   **Fixed ping execution** - replaced dummy/placeholder code with actual Test-Connection logic
*   **Added comprehensive inline documentation** explaining subnet calculations and parallel execution
*   **Improved verbose output** with informative progress messages instead of debug values
*   **Automatic cleanup** of default Excel sheets (Sheet1, Sheet2, etc.)
*   **Enhanced error handling** with better validation and user-friendly messages