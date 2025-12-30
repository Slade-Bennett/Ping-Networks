# Network Scanner

A comprehensive PowerShell network scanning and monitoring tool with parallel execution, multiple output formats, web dashboard, database integration, and enterprise features.

[![PowerShell](https://img.shields.io/badge/PowerShell-5.0+-blue.svg)](https://github.com/PowerShell/PowerShell)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

---

## 🚀 Quick Start

**1. Basic scan (creates Excel report):**
```powershell
.\Invoke-NetworkScan.ps1 -InputPath '.\sample-data\NetworkData.xlsx'
```

**2. Generate HTML report:**
```powershell
.\Invoke-NetworkScan.ps1 -InputPath '.\sample-data\NetworkData.csv' -Html
```

**3. Launch web dashboard:**
```powershell
.\Start-Dashboard.ps1
# Open browser to http://localhost:8080
```

**4. Launch GUI:**
```powershell
.\Ping-Networks-GUI.ps1
```

---

## 📋 Table of Contents

- [Features](#-features)
- [Requirements](#-requirements)
- [Installation](#-installation)
- [Usage Modes](#-usage-modes)
  - [Command Line](#command-line-mode)
  - [GUI](#gui-mode)
  - [Web Dashboard](#web-dashboard-mode)
- [Input Formats](#-input-formats)
- [Examples](#-examples)
- [Parameters Reference](#-parameters-reference)
- [Architecture](#-architecture)
- [Recent Updates](#-recent-updates)

---

## ✨ Features

### Core Capabilities
- **Complete Network Scanning** - Pings ALL usable hosts in each subnet (not just the first host)
- **High-Performance Parallel Execution** - Runspace-based (10-20x faster than background jobs)
- **Universal CIDR Support** - Works with any standard notation (/8 through /30)
- **Accurate Subnet Calculations** - Bitwise operations for precise network/broadcast/host ranges
- **DNS Resolution** - Automatic hostname resolution for reachable hosts

### Input Flexibility
- **CIDR Notation:** `10.0.0.0/24` (auto-calculates subnet mask)
- **IP Ranges:** `192.168.1.1-192.168.1.20` (scan specific range)
- **Single IPs:** `172.16.0.1` (scan individual hosts)
- **Multiple Formats:** Excel (.xlsx), CSV (.csv), Text (.txt)
- **Advanced Filtering:** Exclude IPs, scan odd/even addresses only

### Output Formats
- **Excel** - Color-coded results with summary statistics
- **HTML** - Interactive reports with charts and sortable tables
- **JSON** - Structured data for APIs and automation
- **XML** - Hierarchical format for integrations
- **CSV** - Simple tabular format
- **Database** - Direct export to SQL Server/MySQL/PostgreSQL

### User Interfaces
- **Command Line** - Full-featured PowerShell script
- **WPF GUI** - Point-and-click Windows interface
- **Web Dashboard** - Browser-based remote monitoring with REST API

### Advanced Features
- **Response Time Statistics** - Min/max/average latency tracking
- **Packet Loss Tracking** - Network quality analysis
- **Custom Ping Parameters** - Buffer size, TTL, retry logic
- **Checkpoint/Resume** - Save progress and resume interrupted scans
- **Pause/Resume Controls** - Interactive keyboard commands (P/R/S/Q)
- **Scan History & Baselines** - Track changes over time
- **Trend Analysis** - Availability statistics and uptime percentages
- **Email Notifications** - Alerts on completion or network changes
- **Scheduled Scanning** - Windows Task Scheduler integration
- **Database Integration** - Enterprise data persistence

---

## 💻 Requirements

- **PowerShell 5.0 or later**
- **Microsoft Excel** (only for .xlsx input/output files)
- **.NET Framework** (for GUI)
- **Pode module** (auto-installed for web dashboard)

---

## 📦 Installation

1. **Clone the repository:**
   ```powershell
   git clone https://github.com/yourusername/ping-networks.git
   cd ping-networks
   ```

2. **Run a test scan:**
   ```powershell
   .\Invoke-NetworkScan.ps1 -InputPath '.\sample-data\NetworkData.xlsx' -Html
   ```

3. **Optional: Install dependencies for web dashboard:**
   ```powershell
   Install-Module -Name Pode -Scope CurrentUser
   ```

---

## 🎯 Usage Modes

### Command Line Mode

The main script `Invoke-NetworkScan.ps1` provides full command-line access:

```powershell
# Basic scan with Excel output
.\Invoke-NetworkScan.ps1 -InputPath '.\sample-data\NetworkData.xlsx'

# Generate multiple formats
.\Invoke-NetworkScan.ps1 -InputPath '.\sample-data\NetworkData.csv' -Excel -Html -Json

# High-performance scan with 100 concurrent pings
.\Invoke-NetworkScan.ps1 -InputPath '.\sample-data\NetworkData.txt' -Throttle 100 -Html

# Scan with history tracking and baseline comparison
.\Invoke-NetworkScan.ps1 -InputPath '.\networks.xlsx' `
    -HistoryPath 'C:\ScanHistory' `
    -CompareBaseline 'C:\ScanHistory\ScanHistory_20251225_120000.json' `
    -Html -EmailOnChanges
```

### GUI Mode

Launch the graphical interface for point-and-click operation:

```powershell
.\Ping-Networks-GUI.ps1
```

**Features:**
- Browse buttons for file selection
- Checkboxes for output formats
- Visual progress monitoring
- Results grid with live updates
- Advanced options panel

### Web Dashboard Mode

Start the browser-based dashboard for remote monitoring:

```powershell
# Basic usage
.\Start-Dashboard.ps1

# With authentication
.\Start-Dashboard.ps1 -EnableAuth -Username "admin" -Password "secure123"

# With database integration
.\Start-Dashboard.ps1 -DatabaseConnectionString "Server=localhost;Database=PingNetworks;Integrated Security=True"
```

Then open: **http://localhost:8080**

**Features:**
- Real-time scan monitoring
- Start scans from browser
- Interactive charts (Chart.js)
- Historical data visualization
- RESTful API (`/api/docs`)
- Multi-user support
- Mobile-friendly responsive design

See [`dashboard/README.md`](dashboard/README.md) for complete documentation.

---

## 📁 Input Formats

### Excel (.xlsx)
```
Network
10.0.0.0/24
192.168.1.1-192.168.1.50
172.16.0.1
```

### CSV (.csv)
```csv
Network
10.0.0.0/24
192.168.1.1-192.168.1.50
172.16.0.1
```

### Text (.txt)
```
10.0.0.0/24
192.168.1.1-192.168.1.50
172.16.0.1
```

### Traditional Format (backward compatible)
```
IP          | Subnet Mask     | CIDR
10.0.0.0    | 255.255.255.0   | 24
192.168.1.0 | 255.255.255.240 | 28
```

---

## 📚 Examples

### Basic Scanning

**Scan networks from Excel:**
```powershell
.\Invoke-NetworkScan.ps1 -InputPath '.\sample-data\NetworkData.xlsx'
```

**Generate HTML report:**
```powershell
.\Invoke-NetworkScan.ps1 -InputPath '.\sample-data\NetworkData.csv' -Html
```

**Multiple output formats:**
```powershell
.\Invoke-NetworkScan.ps1 -InputPath '.\sample-data\NetworkData.txt' -Excel -Html -Json
```

### Advanced Filtering

**Exclude gateway IPs:**
```powershell
.\Invoke-NetworkScan.ps1 -InputPath '.\networks.xlsx' -Html -ExcludeIPs "10.0.0.1","10.0.0.254"
```

**Scan only odd IPs:**
```powershell
.\Invoke-NetworkScan.ps1 -InputPath '.\networks.xlsx' -Html -OddOnly
```

**Limit hosts per network:**
```powershell
.\Invoke-NetworkScan.ps1 -InputPath '.\networks.xlsx' -Html -MaxPings 20
```

### Network Monitoring

**Save scan history:**
```powershell
.\Invoke-NetworkScan.ps1 -InputPath '.\networks.xlsx' -HistoryPath 'C:\ScanHistory' -Html
```

**Compare against baseline:**
```powershell
.\Invoke-NetworkScan.ps1 -InputPath '.\networks.xlsx' `
    -CompareBaseline 'C:\ScanHistory\ScanHistory_20251225_120000.json' `
    -Html -EmailOnChanges
```

**Generate trend report:**
```powershell
.\Invoke-NetworkScan.ps1 -InputPath '.\networks.xlsx' `
    -HistoryPath 'C:\ScanHistory' `
    -GenerateTrendReport -TrendDays 90 `
    -Html
```

### Performance Tuning

**High-speed scanning:**
```powershell
.\Invoke-NetworkScan.ps1 -InputPath '.\networks.xlsx' -Throttle 100 -Html
```

**Detailed statistics (5 pings per host):**
```powershell
.\Invoke-NetworkScan.ps1 -InputPath '.\networks.xlsx' -Count 5 -Html
```

**MTU path testing:**
```powershell
.\Invoke-NetworkScan.ps1 -InputPath '.\networks.xlsx' -BufferSize 1500 -Count 3 -Html
```

### Checkpoint and Resume

**Enable checkpoints:**
```powershell
.\Invoke-NetworkScan.ps1 -InputPath '.\networks.xlsx' `
    -CheckpointPath 'C:\Checkpoints' -CheckpointInterval 50 `
    -Html
```

**Resume interrupted scan:**
```powershell
.\Invoke-NetworkScan.ps1 -ResumeCheckpoint 'C:\Checkpoints\Checkpoint_20251228_120000.json' -Html
```

**Interactive pause during scan:**
- Press **P** to pause
- Press **R** to resume
- Press **S** to save checkpoint and quit
- Press **Q** to quit without saving

### Email Notifications

**Scan with completion email:**
```powershell
.\Invoke-NetworkScan.ps1 -InputPath '.\networks.xlsx' -Html `
    -EmailOnCompletion `
    -EmailTo "admin@example.com" `
    -EmailFrom "scanner@example.com" `
    -SmtpServer "smtp.gmail.com" -SmtpPort 587 -UseSSL `
    -SmtpUsername "scanner@gmail.com" -SmtpPassword "app-password"
```

**Alert on network changes:**
```powershell
.\Invoke-NetworkScan.ps1 -InputPath '.\networks.xlsx' `
    -CompareBaseline 'baseline.json' `
    -EmailOnChanges -MinChangesToAlert 5 `
    -EmailTo "security@example.com" `
    -EmailFrom "scanner@example.com" `
    -SmtpServer "smtp.office365.com" -UseSSL
```

**Alert on new devices only:**
```powershell
.\Invoke-NetworkScan.ps1 -InputPath '.\networks.xlsx' `
    -CompareBaseline 'baseline.json' `
    -EmailOnChanges -AlertOnNewOnly `
    -EmailTo "security@example.com" `
    -EmailFrom "scanner@example.com" `
    -SmtpServer "smtp.gmail.com" -UseSSL
```

### Scheduled Scanning

**Create daily scheduled scan:**
```powershell
.\New-ScheduledScan.ps1 -InputPath 'C:\Networks\data.xlsx' `
    -Schedule Daily -Time "03:00" `
    -OutputDirectory 'C:\NetworkScans' `
    -HistoryPath 'C:\NetworkScans\History' `
    -EmailOnCompletion -EmailOnChanges `
    -EmailTo "admin@example.com" `
    -EmailFrom "scanner@example.com" `
    -SmtpServer "smtp.gmail.com" -UseSSL
```

### Database Export

**Initialize database and export:**
```powershell
# First time: create tables
.\Invoke-NetworkScan.ps1 -InputPath '.\networks.xlsx' `
    -DatabaseExport -InitializeDatabase `
    -DatabaseConnectionString "Server=localhost;Database=PingNetworks;Integrated Security=True" `
    -Excel -Html

# Subsequent scans
.\Invoke-NetworkScan.ps1 -InputPath '.\networks.xlsx' `
    -DatabaseExport `
    -DatabaseConnectionString "Server=localhost;Database=PingNetworks;Integrated Security=True" `
    -Html
```

**Connection string examples:**
- **SQL Express:** `Server=.\SQLEXPRESS;Database=PingNetworks;Integrated Security=True`
- **LocalDB:** `Server=(localdb)\MSSQLLocalDB;Database=PingNetworks;Integrated Security=True`
- **Remote:** `Server=sqlserver.domain.com;Database=PingNetworks;User ID=scanner;Password=pass`

### Comprehensive Monitoring

**Full enterprise setup:**
```powershell
.\Invoke-NetworkScan.ps1 -InputPath '.\networks.xlsx' `
    -HistoryPath 'C:\NetworkMonitoring' -RetentionDays 60 `
    -CompareBaseline 'C:\NetworkMonitoring\ScanHistory_20251220_030000.json' `
    -GenerateTrendReport -TrendDays 60 `
    -EmailOnChanges -MinChangesToAlert 3 `
    -EmailTo "ops@example.com","security@example.com" `
    -EmailFrom "netmonitor@example.com" `
    -SmtpServer "smtp.gmail.com" -UseSSL `
    -DatabaseExport `
    -DatabaseConnectionString "Server=localhost;Database=PingNetworks;Integrated Security=True" `
    -Html -Json
```

---

## 🔧 Parameters Reference

### Required
- **`-InputPath`** - Path to input file (.xlsx, .csv, .txt)

### Output Formats
- **`-Excel`** - Generate Excel output with color-coding
- **`-Html`** - Generate interactive HTML report
- **`-Json`** - Generate JSON output
- **`-Xml`** - Generate XML output
- **`-Csv`** - Generate CSV output
- **`-OutputDirectory`** - Custom output directory (default: Documents)

### Filtering
- **`-ExcludeIPs`** - Array of IPs or ranges to exclude
- **`-OddOnly`** - Scan only odd IPs (.1, .3, .5, etc.)
- **`-EvenOnly`** - Scan only even IPs (.2, .4, .6, etc.)
- **`-MaxPings`** - Maximum hosts to ping per network

### Performance
- **`-Throttle`** - Concurrent ping operations (default: 50, range: 20-100)
- **`-Timeout`** - Ping timeout in seconds (default: 1)
- **`-Retries`** - Retry attempts with exponential backoff (default: 0)

### Ping Customization
- **`-Count`** - Pings per host for statistics (default: 1)
- **`-BufferSize`** - ICMP packet size in bytes (default: 32, range: 1-65500)
- **`-TimeToLive`** - TTL value (default: 128, range: 1-255)

### History & Monitoring
- **`-HistoryPath`** - Directory for scan history
- **`-CompareBaseline`** - Path to baseline scan for comparison
- **`-GenerateTrendReport`** - Generate availability trend analysis
- **`-TrendDays`** - Days of history for trend analysis (default: 30)
- **`-RetentionDays`** - Auto-delete history older than N days (default: 0)

### Checkpoints
- **`-CheckpointPath`** - Directory for checkpoint files
- **`-CheckpointInterval`** - Save checkpoint every N hosts (default: 50)
- **`-ResumeCheckpoint`** - Resume from checkpoint file

### Email Notifications
- **`-EmailTo`** - Array of recipient addresses
- **`-EmailFrom`** - Sender address
- **`-SmtpServer`** - SMTP server address
- **`-SmtpPort`** - SMTP port (default: 587)
- **`-SmtpUsername`** - SMTP username
- **`-SmtpPassword`** - SMTP password
- **`-UseSSL`** - Use SSL/TLS encryption
- **`-EmailOnCompletion`** - Send email on scan completion
- **`-EmailOnChanges`** - Send email on baseline changes
- **`-MinChangesToAlert`** - Minimum changes to trigger alert (default: 1)
- **`-MinChangePercentage`** - Percentage threshold for alerts (0-100)
- **`-AlertOnNewOnly`** - Alert only on new devices
- **`-AlertOnOfflineOnly`** - Alert only on offline devices

### Database Export
- **`-DatabaseExport`** - Enable database export
- **`-DatabaseConnectionString`** - Database connection string
- **`-DatabaseType`** - Database type (SQLServer/MySQL/PostgreSQL, default: SQLServer)
- **`-InitializeDatabase`** - Create database schema (first run only)

See [docs/README.md](docs/README.md) for comprehensive parameter documentation.

---

## 🏗️ Architecture

```
ping-networks/
├── modules/
│   ├── NetworkScanner.psm1   # Core: subnet calculation, parallel ping
│   ├── ExcelUtils.psm1       # Excel COM automation
│   ├── ReportUtils.psm1      # Report generation (HTML, JSON, XML)
│   └── DatabaseUtils.psm1    # Database export (SQL Server, MySQL, PostgreSQL)
├── dashboard/
│   ├── static/               # Web dashboard assets (CSS, JS)
│   └── README.md             # Dashboard documentation
├── sample-data/
│   ├── NetworkData.xlsx      # Sample Excel input
│   ├── NetworkData.csv       # Sample CSV input
│   ├── NetworkData.txt       # Sample text input
│   └── README.md             # Sample data documentation
├── tests/
│   ├── Run-UnitTests.ps1     # Master test runner
│   ├── Test-*.ps1            # Unit and integration tests
│   └── README.md             # Testing documentation
├── docs/
│   ├── README.md             # Detailed documentation
│   ├── ROADMAP.md            # Development roadmap
│   ├── CODE_QUALITY.md       # Code quality improvements
│   └── *.md                  # Additional documentation
├── Invoke-NetworkScan.ps1    # Main CLI script
├── Ping-Networks-GUI.ps1     # WPF graphical interface
├── Start-Dashboard.ps1       # Web dashboard server
└── New-ScheduledScan.ps1     # Scheduled task helper
```

### Key Modules

**NetworkScanner.psm1** - Core functions:
- `Get-UsableHosts` - Subnet calculations with bitwise operations
- `Invoke-HostPing` - Parallel ping execution using runspaces
- `ConvertFrom-NetworkInput` - Network notation parsing (CIDR, ranges, traditional)
- `Get-IPRange` - IP range expansion

**ExcelUtils.psm1** - Excel automation:
- `New-ExcelSession` - COM object creation and management
- `Read-ExcelSheet` - Read network data from Excel
- `Write-ExcelSheet` - Write color-coded results
- `Close-ExcelSession` - Proper COM cleanup

**ReportUtils.psm1** - Report generation:
- `Export-HtmlReport` - Interactive HTML with Chart.js
- `Export-JsonReport` - Structured JSON output
- `Export-XmlReport` - Well-formed XML documents
- `Send-EmailNotification` - SMTP email delivery

**DatabaseUtils.psm1** - Database integration:
- `Test-DatabaseConnection` - Connectivity validation
- `Initialize-DatabaseSchema` - Table creation with indexes
- `Export-DatabaseResults` - Batch insert operations

---

## 📈 Recent Updates

### Version 2.3.0 (Current)
- **Renamed to PowerShell Standards:** Main script → `Invoke-NetworkScan.ps1`, Module → `NetworkScanner.psm1`
- **Single IP Support:** Accept single IP addresses as input (e.g., `172.16.0.1`)
- **Enhanced Error Messages:** Detailed validation errors with examples and troubleshooting
- **Comprehensive Testing:** 45 unit/integration tests (100% pass rate)
- **Sample Data Files:** 8 sample files covering edge cases, mixed formats, and error handling
- **Improved Documentation:** Error handling guide, code quality summaries, renaming guide

### Version 2.2 (Web Dashboard)
- **Browser-Based Interface:** Pode web framework for remote monitoring
- **Real-Time Updates:** Live scan progress with automatic polling
- **Interactive Charts:** Chart.js visualizations for history and trends
- **RESTful API:** Complete REST API (`/api/status`, `/api/scan/start`, `/api/history`)
- **Authentication:** Optional form-based auth with session management
- **Multi-User Support:** Multiple concurrent users
- **Database Integration:** Automatic querying from SQL Server
- **Responsive Design:** Mobile-friendly for tablets and smartphones

### Version 2.1 (Database Export)
- **DatabaseUtils Module:** Enterprise data persistence
- **SQL Server Support:** Native integration with parameterized queries
- **Automatic Schema:** Creates tables, indexes, foreign keys on first run
- **Batch Processing:** Efficient bulk insert (100 records/batch)
- **GUI Integration:** Database controls in WPF advanced options
- **MySQL/PostgreSQL Ready:** Architecture supports future implementations

### Version 2.0 (GUI)
- **WPF Interface:** Windows Presentation Foundation graphical UI
- **Point-and-Click:** Browse buttons, checkboxes, visual progress
- **Real-Time Results:** DataGrid with live scan updates
- **Advanced Options:** Collapsible panel for all parameters
- **Background Jobs:** Non-blocking scan execution

### Version 1.9 (Checkpoints)
- **Checkpoint System:** Automatic progress saving during scans
- **Resume Capability:** Restart interrupted scans from last checkpoint
- **Interactive Controls:** Pause/Resume/Save/Quit keyboard commands (P/R/S/Q)
- **State Preservation:** Full scan state including results and remaining work

See [docs/README.md](docs/README.md) and [ROADMAP.md](docs/ROADMAP.md) for complete version history.

---

## 🧪 Testing

Run the comprehensive test suite:

```powershell
.\tests\Run-UnitTests.ps1
```

**Test Coverage:**
- ConvertFrom-NetworkInput: 10 tests
- Get-UsableHosts: 12 tests
- Get-IPRange: 10 tests
- Invoke-HostPing: 8 tests
- Integration: 5 tests
- **Total: 45 tests** ✅

See [tests/README.md](tests/README.md) for testing documentation.

---

## 📖 Documentation

- **[Comprehensive Guide](docs/README.md)** - Detailed documentation with all features
- **[Development Roadmap](docs/ROADMAP.md)** - Project roadmap and future plans
- **[Dashboard Guide](dashboard/README.md)** - Web dashboard documentation
- **[Sample Data](sample-data/README.md)** - Sample file descriptions and usage
- **[Testing Guide](tests/README.md)** - Test suite documentation
- **[Code Quality](docs/CODE_QUALITY_IMPROVEMENTS_SUMMARY.md)** - Refactoring and improvements

---

## 🤝 Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](docs/CONTRIBUTING.md) for guidelines.

---

## 📝 License

This project is licensed under the MIT License.

---

## 🌟 Key Highlights

- ⚡ **10-20x Faster** than traditional PowerShell background jobs
- 🎯 **100% Accurate** subnet calculations using bitwise operations
- 📊 **5 Output Formats** for maximum flexibility
- 🖥️ **3 User Interfaces** (CLI, GUI, Web Dashboard)
- 🔄 **Checkpoint/Resume** for long-running scans
- 📧 **Email Alerts** with configurable thresholds
- 💾 **Database Integration** for enterprise deployments
- 📈 **Trend Analysis** with availability statistics
- 🧪 **45 Tests** with 100% pass rate
- 📚 **Comprehensive Documentation** with 50+ examples

---

**Made with PowerShell** 💙
