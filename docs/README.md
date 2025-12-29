# Ping-Networks

Ping-Networks is a PowerShell module that pings all hosts in specified networks from an Excel file and exports comprehensive results to Excel or CSV. It's designed to be a simple, efficient, and reliable tool for network administrators and engineers.

## Features

*   **Complete Network Scanning:** Calculates and pings ALL usable host addresses in each subnet (not just the first host).
*   **Flexible Input Formats:**
    *   **CIDR Notation:** `10.0.0.0/24` (auto-calculates subnet mask)
    *   **IP Ranges:** `192.168.1.1-192.168.1.20` (scans specific range)
    *   **Multiple File Types:** Excel (.xlsx), CSV (.csv), Text (.txt)
    *   **Traditional Format:** Backward compatible with IP/Subnet Mask/CIDR columns
*   **Advanced Filtering:**
    *   **Exclude IPs:** Skip specific IPs or ranges (e.g., gateways, reserved IPs)
    *   **Odd/Even Filter:** Scan only odd or even IP addresses
    *   **Flexible Exclusion:** Works with individual IPs or IP ranges
*   **Universal CIDR Support:** Works with any standard CIDR notation (/8 through /30) - /24, /28, /16, etc.
*   **Accurate Subnet Calculations:** Uses bitwise operations for precise network address, broadcast address, and host range calculations.
*   **High-Performance Parallel Execution:** Uses runspaces for optimal performance (10-20x faster than background jobs) with configurable concurrency control.
*   **DNS Resolution:** Automatically resolves hostnames for reachable hosts.
*   **Advanced Ping Customization:**
    *   **Response Time Statistics:** Min, max, and average response times for each host
    *   **Packet Loss Tracking:** Percentage of packets lost during multi-ping tests
    *   **Custom Packet Size:** Configurable buffer size (1-65500 bytes) for MTU testing
    *   **TTL Configuration:** Custom Time To Live values for hop count testing
    *   **Adaptive Retry Logic:** Exponential backoff retry mechanism for unreliable hosts
*   **Multiple Output Formats:**
    *   **Excel:** Color-coded results with summary statistics and per-network worksheets
    *   **HTML:** Interactive web reports with charts, sortable tables, and search functionality
    *   **JSON:** Structured data format ideal for APIs and programmatic processing
    *   **XML:** Hierarchical format compatible with most XML parsers and integration tools
    *   **CSV:** Simple tabular format for spreadsheet import
*   **Database Export (NEW in v2.1):** Direct export of scan results to SQL Server, MySQL, or PostgreSQL databases with automatic schema initialization and batch processing.
*   **Enhanced Progress Reporting:** Real-time scan statistics including ETA, scan rate (hosts/sec), and network progress.
*   **Checkpoint and Resume System:** Save scan progress periodically and resume interrupted scans from checkpoints. Interactive pause/resume controls with keyboard commands.
*   **Graphical User Interface (v2.0):** Windows WPF GUI for point-and-click network scanning with visual progress monitoring and results display.
*   **Web-Based Dashboard (NEW in v2.2):** Browser-based interface for remote access, multi-user monitoring, historical data visualization, and RESTful API.
*   **Modular Architecture:** Separated into reusable modules (subnet calculation, ping logic, Excel utilities, database export, report generation).

## Requirements

*   PowerShell 5.0 or later.
*   Microsoft Excel installed (only required for .xlsx input/output files).
*   .NET Framework (for GUI)

## Usage

### GUI Mode (v2.0)

For a user-friendly graphical interface, launch the GUI:

```powershell
.\Ping-Networks-GUI.ps1
```

The GUI provides:
- Browse buttons for file selection
- Checkboxes for output formats
- Input fields for all scan parameters
- Real-time progress visualization
- Results grid with scan data
- Start/Stop/Clear controls

### Web Dashboard Mode (v2.2)

For browser-based remote access and multi-user monitoring, launch the web dashboard:

```powershell
# Basic usage (no authentication)
.\Start-Dashboard.ps1

# With authentication
.\Start-Dashboard.ps1 -EnableAuth -Username "admin" -Password "secure123"

# With database integration
.\Start-Dashboard.ps1 -DatabaseConnectionString "Server=localhost;Database=PingNetworks;Integrated Security=True"
```

Then open your browser to: **http://localhost:8080**

The Web Dashboard provides:
- Real-time scan monitoring with live progress updates
- Start scans directly from the browser
- Interactive charts and historical data visualization
- RESTful API for programmatic access (see `/api/docs`)
- Database integration for persistent historical data
- Responsive design for desktop, tablet, and mobile
- Optional authentication for secure access
- Multi-user support

See `dashboard/README.md` for complete documentation.

### Command Line Mode

The main script `Ping-Networks.ps1` is located in the root directory. You can run it as follows:

```powershell
.\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.xlsx' -Excel -Html
```

### Input File Formats

The script supports multiple input file formats for maximum flexibility:

**Excel (.xlsx)**
- Single "Network" column with CIDR notation (`10.0.0.0/24`) or IP ranges (`192.168.1.1-192.168.1.20`)
- Traditional format with separate `IP`, `Subnet Mask`, and `CIDR` columns (backward compatible)

**CSV (.csv)**
- Same formats as Excel with header row
- Lightweight alternative when Excel is not installed

**Text (.txt)**
- One network per line in CIDR or Range format
- Simplest format for quick scans
- Example:
  ```
  10.0.0.0/24
  192.168.1.1-192.168.1.20
  172.16.0.0/28
  ```

### Parameters

*   `InputPath`: (Required) The path to the input file (.xlsx, .csv, or .txt) containing the network data.
*   `OutputDirectory`: (Optional) The directory where all output files will be saved. Defaults to the user's Documents folder. All files use timestamped filenames (e.g., PingResults_20251224_235900.xlsx).
*   `Excel`: (Switch) Generate Excel output with color-coded results and summary statistics.
*   `Html`: (Switch) Generate interactive HTML report with charts and sortable tables.
*   `Json`: (Switch) Generate JSON output for programmatic consumption.
*   `Xml`: (Switch) Generate XML output for integration with other tools.
*   `Csv`: (Switch) Generate CSV output for simple tabular data.
*   `ExcludeIPs`: (Optional) Array of IP addresses or ranges to exclude from scanning. Example: `-ExcludeIPs "192.168.1.1","192.168.1.100-192.168.1.110"`
*   `OddOnly`: (Switch) Scan only odd IP addresses (.1, .3, .5, etc.). Useful for specific network designs.
*   `EvenOnly`: (Switch) Scan only even IP addresses (.2, .4, .6, etc.). Useful for specific network designs.
*   `HistoryPath`: (Optional) Directory path where scan history will be saved as timestamped JSON files. If not specified, no history is saved. Example: `-HistoryPath "C:\ScanHistory"`
*   `CompareBaseline`: (Optional) Path to a previous scan result file (JSON) to compare against current scan. Generates a change detection report showing new devices, offline devices, and status changes. Example: `-CompareBaseline "C:\ScanHistory\ScanHistory_20251225_120000.json"`
*   `Throttle`: (Optional) The maximum number of concurrent ping operations (runspace pool size). Default is 50. Higher values = faster scans but more CPU/memory usage. Recommended range: 20-100. Example: `-Throttle 100`
*   `MaxPings`: (Optional) The maximum number of hosts to ping per network. If not specified, all usable hosts will be pinged.
*   `Timeout`: (Optional) The timeout in seconds for each ping. Default is 1 second.
*   `Retries`: (Optional) The number of retries for each ping with exponential backoff (1s, 2s, 4s). Default is 0.
*   `Count`: (Optional) The number of ping attempts per host for response time statistics. Default is 1. Higher values provide more accurate statistics but increase scan time.
*   `BufferSize`: (Optional) The size of the ICMP packet buffer in bytes (1-65500). Default is 32. Useful for MTU testing and detecting path MTU issues. Common values: 32, 64, 1500.
*   `TimeToLive`: (Optional) The Time To Live (TTL) value for ping packets (1-255). Default is 128. Useful for testing maximum hop count and detecting routing loops.
*   `EmailTo`: (Optional) Array of email addresses to send reports to. Example: `-EmailTo "admin@example.com","team@example.com"`
*   `EmailFrom`: (Optional) Email address to send from. Required if email notifications are enabled.
*   `SmtpServer`: (Optional) SMTP server address (e.g., "smtp.gmail.com" or "smtp.office365.com")
*   `SmtpPort`: (Optional) SMTP port. Default is 587 (TLS).
*   `SmtpUsername`: (Optional) Username for SMTP authentication.
*   `SmtpPassword`: (Optional) Password for SMTP authentication (use app-specific passwords for Gmail/Outlook).
*   `UseSSL`: (Optional) Use SSL/TLS encryption for SMTP connection.
*   `EmailOnCompletion`: (Optional) Send email notification when scan completes with summary and attachments.
*   `EmailOnChanges`: (Optional) Send email alert when baseline comparison detects network changes.
*   `MinChangesToAlert`: (Optional) Minimum number of total changes required to trigger email alert. Default is 1. Example: `-MinChangesToAlert 5`
*   `MinChangePercentage`: (Optional) Minimum percentage of network changes required to trigger alert (0-100). Default is 0. Example: `-MinChangePercentage 10`
*   `AlertOnNewOnly`: (Optional) Only send alerts when new devices are detected.
*   `AlertOnOfflineOnly`: (Optional) Only send alerts when devices go offline.
*   `RetentionDays`: (Optional) Number of days to retain scan history files. Older files are automatically deleted. Default is 0 (no cleanup). Example: `-RetentionDays 30`
*   `GenerateTrendReport`: (Optional) Generate comprehensive trend analysis report from all scan history files. Analyzes host availability patterns and uptime statistics over time.
*   `TrendDays`: (Optional) Number of days of history to include in trend analysis. Default is 30. Example: `-TrendDays 90`
*   `CheckpointPath`: (Optional) Directory path where checkpoint files will be saved during scanning. Checkpoints allow resuming interrupted scans from the last saved state. Example: `-CheckpointPath "C:\ScanCheckpoints"`
*   `CheckpointInterval`: (Optional) Save checkpoint after every N hosts scanned. Default is 50. Lower values = more frequent saves but slightly slower scans. Example: `-CheckpointInterval 25`
*   `ResumeCheckpoint`: (Optional) Path to a checkpoint file to resume an interrupted scan from. The scan will skip already-scanned hosts and continue with remaining networks. Example: `-ResumeCheckpoint "C:\ScanCheckpoints\Checkpoint_20251228_120000.json"`
*   `DatabaseExport`: (Switch) Export scan results to a database. Requires `DatabaseConnectionString` parameter.
*   `DatabaseConnectionString`: (Optional) Database connection string for exporting results. Example: `-DatabaseConnectionString "Server=localhost;Database=PingNetworks;Integrated Security=True"`
*   `DatabaseType`: (Optional) Type of database to export to. Valid values: 'SQLServer', 'MySQL', 'PostgreSQL'. Default is 'SQLServer'. Example: `-DatabaseType "SQLServer"`
*   `InitializeDatabase`: (Switch) Initialize database schema (create tables and indexes) before exporting results. Only needs to be run once when first setting up the database.

**Note:** If no output format switches are specified, Excel output is generated by default for backward compatibility.

## Examples

### Basic Usage

```powershell
.\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.xlsx'
```

This will ping all the networks in the `NetworkData.xlsx` file and create a new Excel file in your Documents folder with the results (default behavior).

### Use CSV Input

```powershell
.\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.csv' -Html
```

Read networks from CSV file and generate HTML report. CSV format is useful when Excel is not installed.

### Use Text File Input

```powershell
.\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.txt' -Excel -Json
```

Read networks from text file (one network per line) and generate Excel and JSON reports. Simplest format for quick scans.

### Generate Multiple Formats

```powershell
.\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.xlsx' -Excel -Html -Json
```

Generate Excel, HTML, and JSON reports simultaneously in the Documents folder. All files will have the same timestamp.

### Custom Output Directory

```powershell
.\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.xlsx' -OutputDirectory 'C:\Reports' -Excel -Html
```

Create Excel and HTML reports in a custom directory (`C:\Reports`).

### Limit Hosts Per Network

```powershell
.\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.xlsx' -Html -MaxPings 10
```

Generate HTML report scanning only the first 10 usable hosts in each network.

### All Output Formats

```powershell
.\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.xlsx' -OutputDirectory 'C:\Reports' -Excel -Html -Json -Xml -Csv
```

Generate all available output formats in a custom directory from a single scan.

### Exclude Specific IPs

```powershell
.\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.txt' -Html -ExcludeIPs "10.0.0.1","10.0.0.254"
```

Scan networks but exclude gateway IPs (commonly .1 and .254).

### Exclude IP Range

```powershell
.\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.csv' -Html -ExcludeIPs "192.168.1.100-192.168.1.110"
```

Exclude an entire range of IPs from scanning (useful for reserved DHCP ranges).

### Scan Only Odd IPs

```powershell
.\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.xlsx' -Html -OddOnly
```

Scan only odd IP addresses. Useful for dual-stack networks or specific network designs.

### Save Scan History

```powershell
.\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.xlsx' -HistoryPath 'C:\ScanHistory' -Html
```

Scan networks and save the results to a history directory. Each scan is saved as a timestamped JSON file for future comparison and trend analysis.

### Compare Against Baseline

```powershell
.\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.xlsx' -CompareBaseline 'C:\ScanHistory\ScanHistory_20251225_120000.json' -Html
```

Scan networks and compare results against a previous scan. Generates a change detection report showing new devices, offline devices, and recovered devices.

### History with Baseline Comparison

```powershell
.\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.xlsx' -HistoryPath 'C:\ScanHistory' -CompareBaseline 'C:\ScanHistory\ScanHistory_20251225_120000.json' -Html -Json
```

Scan networks, save the current results to history, and compare against a previous baseline. Generates both scan results and a change detection report in HTML and JSON formats.

### High-Performance Scanning

```powershell
.\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.xlsx' -Throttle 100 -Html
```

Scan networks with maximum concurrency (100 simultaneous pings) for fastest performance. Ideal for large networks or fast connections.

### Resource-Constrained Scanning

```powershell
.\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.xlsx' -Throttle 20 -Html
```

Scan networks with lower concurrency to reduce CPU and memory usage. Useful for resource-constrained systems or slower connections.

### Email Notifications on Completion

```powershell
.\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.xlsx' -Html `
    -EmailOnCompletion `
    -EmailTo "admin@example.com" -EmailFrom "scanner@example.com" `
    -SmtpServer "smtp.gmail.com" -SmtpPort 587 -UseSSL `
    -SmtpUsername "scanner@gmail.com" -SmtpPassword "your-app-password"
```

Scan networks and send email notification when complete with summary statistics and attached reports.

### Email Alerts for Network Changes

```powershell
.\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.xlsx' `
    -HistoryPath 'C:\ScanHistory' `
    -CompareBaseline 'C:\ScanHistory\ScanHistory_20251225_120000.json' `
    -EmailOnChanges `
    -EmailTo "security@example.com" -EmailFrom "scanner@example.com" `
    -SmtpServer "smtp.office365.com" -SmtpPort 587 -UseSSL `
    -SmtpUsername "scanner@company.com" -SmtpPassword "your-password"
```

Scan networks, compare against baseline, and send email alert if changes are detected (new devices, offline devices, or recovered devices).

### Scheduled Automated Scanning

```powershell
.\New-ScheduledScan.ps1 -InputPath 'C:\Networks\data.xlsx' `
    -Schedule Daily -Time "03:00" `
    -OutputDirectory 'C:\NetworkScans' `
    -HistoryPath 'C:\NetworkScans\History' `
    -EmailOnCompletion -EmailOnChanges `
    -EmailTo "admin@example.com" -EmailFrom "scanner@example.com" `
    -SmtpServer "smtp.gmail.com" -SmtpUsername "scanner@gmail.com" -SmtpPassword "app-password" -UseSSL
```

Create a Windows Scheduled Task to automatically scan networks daily at 3 AM with email notifications. Requires administrator privileges.

### Database Export (v2.1)

```powershell
# First time: Initialize database schema
.\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.xlsx' `
    -DatabaseExport -InitializeDatabase `
    -DatabaseConnectionString "Server=localhost;Database=PingNetworks;Integrated Security=True" `
    -DatabaseType "SQLServer" `
    -Excel -Html

# Subsequent scans: Export to existing database
.\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.xlsx' `
    -DatabaseExport `
    -DatabaseConnectionString "Server=localhost;Database=PingNetworks;Integrated Security=True" `
    -Excel
```

Export scan results to SQL Server database for long-term storage, analysis, and integration with monitoring systems. The `-InitializeDatabase` switch creates the required tables and indexes on first run.

**Connection String Examples:**
- **SQL Server Express:** `Server=.\SQLEXPRESS;Database=PingNetworks;Integrated Security=True`
- **LocalDB:** `Server=(localdb)\MSSQLLocalDB;Database=PingNetworks;Integrated Security=True`
- **Remote SQL Server:** `Server=sqlserver.domain.com;Database=PingNetworks;User ID=scanner;Password=your-password`

### Advanced Ping with Response Time Statistics

```powershell
.\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.xlsx' -Count 5 -Html
```

Ping each host 5 times and calculate response time statistics (min, max, average) and packet loss percentage. Provides more reliable latency measurements.

### MTU Path Testing

```powershell
.\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.xlsx' -BufferSize 1500 -Count 3 -Html
```

Test network paths with larger packets (1500 bytes) to identify MTU issues. Useful for diagnosing packet fragmentation problems.

### Custom TTL for Hop Testing

```powershell
.\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.xlsx' -TimeToLive 64 -Html
```

Use custom TTL value to test maximum hop count or detect routing loops. Lower TTL values can help identify routing issues.

### Comprehensive Ping Diagnostics

```powershell
.\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.xlsx' `
    -Count 10 -BufferSize 1472 -TimeToLive 64 -Retries 2 `
    -Throttle 100 -Html -Json
```

Full diagnostic scan with 10 pings per host, large packets for MTU testing, custom TTL, adaptive retry logic, and high concurrency. Generates comprehensive statistics for network quality analysis.

### Configurable Alert Thresholds

```powershell
.\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.xlsx' `
    -HistoryPath 'C:\ScanHistory' `
    -CompareBaseline 'C:\ScanHistory\ScanHistory_20251225_120000.json' `
    -EmailOnChanges -MinChangesToAlert 5 `
    -EmailTo "admin@example.com" -EmailFrom "scanner@example.com" `
    -SmtpServer "smtp.gmail.com" -SmtpUsername "user" -SmtpPassword "pass" -UseSSL
```

Only send email alerts when 5 or more devices change status. Prevents alert fatigue from minor network fluctuations.

### Percentage-Based Alerting

```powershell
.\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.xlsx' `
    -CompareBaseline 'baseline.json' -EmailOnChanges -MinChangePercentage 10 `
    -EmailTo "security@example.com" -EmailFrom "scanner@example.com" `
    -SmtpServer "smtp.office365.com" -UseSSL
```

Only alert when 10% or more of the network changes. Ideal for large networks where absolute thresholds are too sensitive.

### Alert on New Devices Only

```powershell
.\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.xlsx' `
    -CompareBaseline 'baseline.json' -EmailOnChanges -AlertOnNewOnly `
    -EmailTo "security@example.com" -EmailFrom "scanner@example.com" `
    -SmtpServer "smtp.gmail.com" -UseSSL
```

Security-focused scanning that only alerts when unauthorized devices join the network. Ignores normal offline/online fluctuations.

### Automated History Retention

```powershell
.\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.xlsx' `
    -HistoryPath 'C:\ScanHistory' -RetentionDays 30 -Html
```

Scan networks, save history, and automatically delete scan files older than 30 days. Keeps history directory clean and manageable.

### Trend Analysis Report

```powershell
.\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.xlsx' `
    -HistoryPath 'C:\ScanHistory' -GenerateTrendReport -TrendDays 90 -Html
```

Analyze 90 days of scan history to identify availability patterns. Shows uptime percentages, response time trends, and categorizes hosts as "Always Reachable", "Mostly Reachable", "Intermittent", or "Always Unreachable".

### Comprehensive Monitoring Setup

```powershell
.\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.xlsx' `
    -HistoryPath 'C:\NetworkMonitoring' -RetentionDays 60 `
    -CompareBaseline 'C:\NetworkMonitoring\ScanHistory_20251220_030000.json' `
    -GenerateTrendReport -TrendDays 60 `
    -EmailOnChanges -MinChangesToAlert 3 `
    -EmailTo "ops@example.com","security@example.com" `
    -EmailFrom "netmonitor@example.com" `
    -SmtpServer "smtp.gmail.com" -SmtpUsername "netmonitor@gmail.com" `
    -SmtpPassword "app-password" -UseSSL -Html -Json
```

Full enterprise monitoring: saves 60 days of history, generates trend analysis, alerts on 3+ changes, sends reports to multiple recipients, and produces HTML/JSON outputs.

### Checkpoint and Resume Large Scans

```powershell
.\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.xlsx' `
    -CheckpointPath 'C:\ScanCheckpoints' -CheckpointInterval 50 -Html
```

Save checkpoint every 50 hosts scanned. If the scan is interrupted (Ctrl+C, power loss, etc.), you can resume from the last checkpoint:

```powershell
.\Ping-Networks.ps1 -ResumeCheckpoint 'C:\ScanCheckpoints\Checkpoint_20251228_120000.json' -Html
```

The resumed scan skips already-scanned hosts and continues where it left off, preserving all previous results.

### Interactive Pause and Resume

```powershell
.\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.xlsx' `
    -CheckpointPath 'C:\ScanCheckpoints' -Html
```

During the scan, press **'P'** to pause:
- **'R'** to resume scanning
- **'S'** to save checkpoint and quit
- **'Q'** to quit without saving

This allows interactive control of long-running scans without losing progress.

## Architecture

The project is organized into modular components for maintainability:

```
Ping-Networks/
├── modules/
│   ├── Ping-Networks.psm1   # Core functions: subnet calculation, parallel ping
│   ├── ExcelUtils.psm1       # Excel COM automation utilities
│   ├── ReportUtils.psm1      # Report generation (HTML, JSON, XML)
│   └── DatabaseUtils.psm1    # Database export (SQL Server, MySQL, PostgreSQL)
├── dashboard/
│   ├── static/
│   │   ├── dashboard.css     # Dashboard stylesheet
│   │   ├── dashboard.js      # Dashboard page JavaScript
│   │   └── history.js        # History page JavaScript
│   └── README.md             # Dashboard documentation
├── sample-data/
│   └── NetworkData.xlsx      # Sample Excel input file
├── tests/
│   └── Test-DatabaseExport.ps1 # End-to-end database testing script
├── docs/
│   ├── README.md             # This file
│   └── ROADMAP.md            # Development roadmap
├── Ping-Networks.ps1         # Main entry point script
├── Ping-Networks-GUI.ps1     # WPF graphical user interface
└── Start-Dashboard.ps1       # Web dashboard server
```

### Key Functions

*   **Get-UsableHosts:** Calculates all valid host IPs in a subnet using bitwise operations. Supports any CIDR from /8 to /30.
*   **Start-Ping:** Performs parallel ICMP pings using PowerShell background jobs with configurable batch sizes. Includes real-time progress tracking with ETA and scan rate calculations.
*   **Excel Utilities:** Suite of functions for COM automation (New-ExcelSession, Read-ExcelSheet, Write-ExcelSheet, etc.).
*   **Report Generation:**
    *   **Export-HtmlReport:** Creates interactive HTML reports with Chart.js visualizations, sortable tables, and search functionality
    *   **Export-JsonReport:** Generates structured JSON output with scan metadata and statistics
    *   **Export-XmlReport:** Produces well-formed XML documents using XmlWriter for proper formatting
*   **Database Utilities (v2.1):**
    *   **Test-DatabaseConnection:** Validates database connectivity and authentication
    *   **Initialize-DatabaseSchema:** Creates required tables (Scans, ScanResults) with proper indexes and relationships
    *   **Export-DatabaseResults:** Batch inserts scan results with metadata tracking and progress reporting

## Recent Improvements

### Version 2.2 (Latest)
*   **Web-Based Dashboard:**
    *   **Pode Web Framework:** Lightweight PowerShell web server for browser-based access
    *   **Remote Monitoring:** Access scans from any device with a web browser
    *   **Real-Time Updates:** Live scan progress with automatic polling every 2 seconds
    *   **Interactive Charts:** Chart.js visualizations for scan history and trends
    *   **RESTful API:** Complete REST API for programmatic access (/api/status, /api/scan/start, /api/history)
    *   **Authentication:** Optional form-based authentication with session management
    *   **Multi-User Support:** Multiple users can monitor scans simultaneously
    *   **Database Integration:** Automatic querying from SQL Server for historical data
    *   **Responsive Design:** Mobile-friendly interface for tablets and smartphones
    *   **API Documentation:** Interactive API docs at /api/docs endpoint

### Version 2.1
*   **Database Export:**
    *   **DatabaseUtils Module:** Complete database integration module for enterprise data persistence
    *   **SQL Server Support:** Native support for Microsoft SQL Server (Express, Standard, Enterprise)
    *   **Automatic Schema Initialization:** Creates tables, indexes, and foreign key relationships on first use
    *   **Batch Processing:** Efficient bulk insert of scan results (100 records per batch)
    *   **Database Parameters:** DatabaseExport, DatabaseConnectionString, DatabaseType, InitializeDatabase
    *   **Dual-Table Schema:** Scans table for metadata, ScanResults table for individual host results
    *   **GUI Integration:** Database export controls in WPF GUI advanced options panel
    *   **MySQL/PostgreSQL Ready:** Architecture supports future MySQL and PostgreSQL implementations
    *   **Test Suite:** Comprehensive end-to-end testing script for database functionality

### Version 2.0
*   **Graphical User Interface:**
    *   **WPF-based GUI:** Windows Presentation Foundation interface for point-and-click operation
    *   **File browsers:** Browse buttons for input file and output directory selection
    *   **Visual parameter configuration:** Checkboxes, text boxes, and dropdowns for all parameters
    *   **Real-time progress:** Visual progress bar with status updates
    *   **Results grid:** DataGrid showing scan results in real-time
    *   **Advanced options:** Collapsible panel for advanced parameters (Buffer Size, TTL, History, etc.)
    *   **Job control:** Start, Stop, Clear, and Exit buttons
    *   **Input validation:** Automatic validation of required fields and file paths
    *   **Background execution:** Scans run in PowerShell background jobs without blocking UI
    *   **User-friendly:** Eliminates need to memorize command-line parameters

### Version 1.9.0
*   **Checkpoint and Resume System:**
    *   **CheckpointPath:** Save scan progress periodically during execution
    *   **CheckpointInterval:** Configure how often checkpoints are saved (default: every 50 hosts)
    *   **ResumeCheckpoint:** Resume interrupted scans from the last checkpoint
    *   Automatic parameter restoration from checkpoint (Throttle, MaxPings, etc.)
    *   Prevents data loss on large network scans (power failures, interruptions)
    *   Full scan state preservation including completed results and remaining networks
*   **Interactive Pause/Resume Controls:**
    *   Press **'P'** during scan to pause execution
    *   **'R'** to resume from pause
    *   **'S'** to save checkpoint and exit gracefully
    *   **'Q'** to quit without saving
    *   Works in interactive console sessions
    *   Allows manual intervention during long-running scans
*   **Enhanced Robustness:**
    *   Fixed progress calculation for resumed scans
    *   Graceful handling of non-interactive console scenarios
    *   Improved error messages and user feedback

### Version 1.8.0
*   **Configurable Alert Thresholds:**
    *   **MinChangesToAlert:** Set minimum number of changes to trigger alerts (prevents alert fatigue)
    *   **MinChangePercentage:** Set percentage threshold for network-wide changes (0-100%)
    *   **AlertOnNewOnly:** Only alert when new devices are detected (security monitoring)
    *   **AlertOnOfflineOnly:** Only alert when devices go offline (availability monitoring)
*   **Automated History Management:**
    *   **RetentionDays:** Automatic cleanup of old scan history files
    *   Configurable retention period (e.g., keep last 30, 60, or 90 days)
    *   Cleans both scan history and change report files
    *   Keeps history directories manageable and organized
*   **Trend Analysis & Availability Statistics:**
    *   **GenerateTrendReport:** Comprehensive historical analysis of host availability
    *   Uptime percentage tracking per host (100%, 80-99%, 1-79%, 0%)
    *   Response time trends (min, max, average over time)
    *   First seen / last seen date tracking
    *   Categorization: Always Reachable, Mostly Reachable, Intermittent, Always Unreachable
    *   Network-wide uptime statistics and averages
*   **Graceful Abort & Partial Results:**
    *   Ctrl+C handling saves partial results instead of losing data
    *   Interrupted scans automatically export collected data
    *   Clear visual indication when scan is interrupted
    *   All export formats supported (Excel, HTML, JSON, XML)
*   **Enhanced Reliability:**
    *   Better error handling for network interruptions
    *   Robust cleanup on unexpected termination
    *   Data preservation during failures

### Version 1.7.0
*   **Advanced Ping Customization:**
    *   **Response Time Statistics:** Track min, max, and average response times for each host
    *   **Packet Loss Tracking:** Calculate packet loss percentage during multi-ping tests
    *   **Custom Ping Count:** Configure number of ping attempts per host (1-N pings)
    *   **Custom Packet Size:** Set ICMP buffer size (1-65500 bytes) for MTU testing
    *   **Custom TTL:** Configure Time To Live values (1-255) for hop limit testing
    *   **Adaptive Retry Logic:** Exponential backoff retry mechanism (1s, 2s, 4s delays)
*   **Enhanced Network Diagnostics:**
    *   Detailed ping statistics in all output formats (Excel, HTML, JSON, XML)
    *   Network quality analysis with response time trends
    *   MTU path discovery capabilities
    *   Hop count testing and routing loop detection
*   **Improved Results:**
    *   All ping results include ResponseTime, MinResponseTime, MaxResponseTime
    *   PacketLoss percentage for reliability assessment
    *   PingsSent and PingsReceived counts for transparency

### Version 1.6.0
*   **Email Notifications:**
    *   Send email notifications on scan completion with summary and attachments
    *   Send email alerts when baseline changes are detected
    *   Support for Gmail, Outlook/Office365, and custom SMTP servers
    *   HTML-formatted emails with professional styling
    *   Automatic attachment of scan reports (Excel, HTML, JSON)
*   **Scheduled Scanning:**
    *   New `New-ScheduledScan.ps1` helper script for easy task creation
    *   Support for Daily, Weekly, and Monthly schedules
    *   Integrated email notifications in scheduled tasks
    *   Automatic output directory creation
    *   Administrative task creation with proper permissions
*   **Change Alerts:**
    *   Email alerts include detailed change information
    *   New devices, offline devices, and recovered devices highlighted
    *   Color-coded alerts (orange=new, red=offline, green=recovered)
    *   Up to 10 device details per category in email
*   **Automation Features:**
    *   Full SMTP authentication support (username/password)
    *   SSL/TLS encryption for secure email transmission
    *   Configurable SMTP ports (25, 587, 465)
    *   Multiple email recipients supported

### Version 1.5.0
*   **Runspace-Based Parallel Execution:**
    *   Replaced PowerShell background jobs with runspace pool for 10-20x performance improvement
    *   All pings execute within same process (no process creation overhead)
    *   Minimal startup overhead: ~5-10ms per runspace vs ~1-2 seconds per job
    *   Memory efficient: ~1-2 MB per runspace vs ~50-100 MB per background job
*   **Configurable Concurrency:**
    *   New `-Throttle` parameter to control runspace pool size (default: 50)
    *   Higher throttle = faster scans, lower throttle = less resource usage
    *   Recommended range: 20-100 concurrent operations
*   **Performance Optimizations:**
    *   Reduced memory footprint for large network scans
    *   Faster scan completion on networks with many reachable hosts
    *   No serialization overhead - results stay in memory
*   **Backwards Compatibility:**
    *   Maintains PowerShell 5.0+ compatibility
    *   Same result format and functionality as previous versions
    *   Drop-in replacement for existing scripts

### Version 1.4.0
*   **Scan History & Baseline Tracking:**
    *   Save scan results to history directory with `-HistoryPath` parameter
    *   Each scan saved as timestamped JSON file with full metadata
    *   Automatic retention of historical scan data for trend analysis
*   **Baseline Comparison:**
    *   Compare current scan against previous baseline with `-CompareBaseline` parameter
    *   Automatic detection of new devices appearing on network
    *   Identification of devices that went offline since baseline
    *   Detection of recovered devices (unreachable to reachable)
    *   Change detection report with summary statistics
*   **Change Detection Reports:**
    *   JSON change reports with detailed comparison metadata
    *   Console summary showing new/offline/recovered device counts
    *   Color-coded change summary (yellow=new, red=offline, green=recovered)
    *   Automatic export to both output directory and history directory
*   **Historical Data Management:**
    *   Structured JSON format for long-term data storage
    *   Scan metadata includes date, duration, input file, and statistics
    *   Compatible with future trend analysis and reporting features

### Version 1.2.0
*   **Advanced Filtering Options:**
    *   Exclude specific IPs or ranges from scans (`-ExcludeIPs`)
    *   Scan only odd IPs (`-OddOnly`) or even IPs (`-EvenOnly`)
    *   Supports both individual IP exclusion and range exclusion
    *   Useful for skipping gateways, DHCP ranges, or reserved IPs
*   **Multiple Input Sources:**
    *   CSV file support (.csv) - lightweight alternative to Excel
    *   Text file support (.txt) - one network per line for quick scans
    *   Excel remains fully supported (.xlsx)
    *   Excel no longer required for CSV/TXT workflows
*   **Flexible Network Notation:**
    *   CIDR notation support (`10.0.0.0/24`)
    *   IP range support (`192.168.1.1-192.168.1.20`)
    *   Auto-calculation of subnet masks from CIDR
    *   Backward compatible with traditional IP/Subnet Mask/CIDR format
*   **Simplified Parameter System:**
    *   Single `-OutputDirectory` parameter for all output files
    *   Format switches (`-Excel`, `-Html`, `-Json`, `-Xml`, `-Csv`) for output selection
    *   Automatic timestamped filenames (e.g., PingResults_20251224_235900.xlsx)
    *   Default to Excel when no format specified (backward compatible)
    *   Support for generating multiple formats simultaneously
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