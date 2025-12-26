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
*   Microsoft Excel installed (only required for .xlsx input/output files).

## Usage

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
*   `Retries`: (Optional) The number of retries for each ping. Default is 0.
*   `EmailTo`: (Optional) Array of email addresses to send reports to. Example: `-EmailTo "admin@example.com","team@example.com"`
*   `EmailFrom`: (Optional) Email address to send from. Required if email notifications are enabled.
*   `SmtpServer`: (Optional) SMTP server address (e.g., "smtp.gmail.com" or "smtp.office365.com")
*   `SmtpPort`: (Optional) SMTP port. Default is 587 (TLS).
*   `SmtpUsername`: (Optional) Username for SMTP authentication.
*   `SmtpPassword`: (Optional) Password for SMTP authentication (use app-specific passwords for Gmail/Outlook).
*   `UseSSL`: (Optional) Use SSL/TLS encryption for SMTP connection.
*   `EmailOnCompletion`: (Optional) Send email notification when scan completes with summary and attachments.
*   `EmailOnChanges`: (Optional) Send email alert when baseline comparison detects network changes.

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

### Version 1.6.0 (Latest)
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