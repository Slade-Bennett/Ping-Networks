# Ping-Networks

Ping-Networks is a PowerShell module that pings a list of networks from an Excel file and exports the results to a new Excel or CSV file. It's designed to be a simple and efficient tool for network administrators and engineers.

## Features

*   Reads network information from an Excel file.
*   Calculates the usable IP addresses for each network.
*   Pings hosts in parallel for fast and efficient scanning.
*   Resolves the hostname of reachable hosts.
*   Exports ping results to an Excel or CSV file.
*   Creates a summary worksheet with statistics for each network.
*   Creates a separate worksheet for each network with detailed results.

## Requirements

*   PowerShell 5.0 or later.
*   Microsoft Excel installed.

## Usage

The `Ping-Networks.ps1` script is located in the `examples` directory. You can run it from the root of the project as follows:

```powershell
.\examples\Ping-Networks.ps1 -InputPath '.\examples\sample-data\NetworkData.xlsx' -OutputPath '.\PingResults.xlsx'
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
.\examples\Ping-Networks.ps1 -InputPath '.\examples\sample-data\NetworkData.xlsx'
```

This will ping all the networks in the `NetworkData.xlsx` file and create a new Excel file in your Documents folder with the results.

### Specify Output Path

```powershell
.\examples\Ping-Networks.ps1 -InputPath '.\examples\sample-data\NetworkData.xlsx' -OutputPath 'C:\Temp\PingResults.xlsx'
```

This will create the `PingResults.xlsx` file in the `C:\Temp` directory.

### Specify Max Pings

```powershell
.\examples\Ping-Networks.ps1 -InputPath '.\examples\sample-data\NetworkData.xlsx' -MaxPings 10
```

This will only ping the first 10 usable hosts in each network.