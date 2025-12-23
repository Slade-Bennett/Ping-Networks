# Ping-Networks

Ping-Networks is a PowerShell module that pings all hosts in specified networks from an Excel file and exports comprehensive results to Excel or CSV. It's designed to be a simple, efficient, and reliable tool for network administrators and engineers.

## Features

*   **Complete Network Scanning:** Calculates and pings ALL usable host addresses in each subnet (not just the first host).
*   **Universal CIDR Support:** Works with any standard CIDR notation (/8 through /30) - /24, /28, /16, etc.
*   **Accurate Subnet Calculations:** Uses bitwise operations for precise network address, broadcast address, and host range calculations.
*   **Parallel Execution:** Pings hosts concurrently using PowerShell background jobs for maximum speed (configurable batch size).
*   **DNS Resolution:** Automatically resolves hostnames for reachable hosts.
*   **Excel Integration:** Reads network definitions from Excel and exports results with color-coded status indicators.
*   **Clean Output:** Generates summary statistics plus detailed per-network worksheets (automatically removes default Excel sheets).
*   **CSV Export Option:** Alternative CSV output format for programmatic consumption.
*   **Modular Architecture:** Separated into reusable modules (subnet calculation, ping logic, Excel utilities).

## Requirements

*   PowerShell 5.0 or later.
*   Microsoft Excel installed.

## Usage

The main script `Ping-Networks.ps1` is located in the root directory. You can run it as follows:

```powershell
.\Ping-Networks.ps1 -InputPath '.\sample-data\NetworkData.xlsx' -OutputPath '.\PingResults.xlsx'
```

### Parameters

*   `InputPath`: The path to the input Excel file containing the network data. The file should have three columns: 'IP', 'SubnetMask', and 'CIDR'.
*   `OutputPath`: (Optional) The path to the output Excel file where the ping results will be saved. Defaults to a timestamped file in the user's Documents folder.
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

## Architecture

The project is organized into modular components for maintainability:

```
Ping-Networks/
├── modules/
│   ├── Ping-Networks.psm1   # Core functions: subnet calculation, parallel ping
│   └── ExcelUtils.psm1       # Excel COM automation utilities
├── sample-data/
│   └── NetworkData.xlsx      # Sample Excel input file
├── docs/
│   ├── README.md             # This file
│   └── ROADMAP.md            # Development roadmap
└── Ping-Networks.ps1         # Main entry point script
```

### Key Functions

*   **Get-UsableHosts:** Calculates all valid host IPs in a subnet using bitwise operations. Supports any CIDR from /8 to /30.
*   **Start-Ping:** Performs parallel ICMP pings using PowerShell background jobs with configurable batch sizes.
*   **Excel Utilities:** Suite of functions for COM automation (New-ExcelSession, Read-ExcelSheet, Write-ExcelSheet, etc.).

## Recent Improvements

### Version 1.1.0 (Latest)
*   **Fixed critical subnet calculation bug** that caused empty IP addresses to be generated
*   **Fixed ping execution** - replaced dummy/placeholder code with actual Test-Connection logic
*   **Added comprehensive inline documentation** explaining subnet calculations and parallel execution
*   **Improved verbose output** with informative progress messages instead of debug values
*   **Automatic cleanup** of default Excel sheets (Sheet1, Sheet2, etc.)
*   **Enhanced error handling** with better validation and user-friendly messages

All hosts in each subnet are now correctly calculated and pinged, not just the first address.