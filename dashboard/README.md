# Ping-Networks Web Dashboard

Browser-based interface for remote network scanning, monitoring, and historical data visualization.

## Features

- **Real-time Monitoring:** Live scan progress with automatic updates
- **Network Scanning:** Start scans directly from the web interface
- **Historical Analysis:** Interactive charts and trend visualization
- **RESTful API:** Programmatic access to all dashboard functionality
- **Database Integration:** Automatic querying of historical data from SQL Server
- **Responsive Design:** Works on desktop, tablet, and mobile devices
- **Authentication:** Optional user authentication for secure access
- **Multi-user Support:** Multiple users can monitor scans simultaneously

## Requirements

- PowerShell 5.0 or later
- Pode PowerShell module (auto-installed on first run)
- Modern web browser (Chrome, Firefox, Edge, Safari)
- Optional: SQL Server for historical data persistence

## Quick Start

### Basic Usage (No Authentication)

```powershell
.\Start-Dashboard.ps1
```

Then open your browser to: **http://localhost:8080**

### With Custom Port

```powershell
.\Start-Dashboard.ps1 -Port 9000
```

### With Authentication

```powershell
.\Start-Dashboard.ps1 -EnableAuth -Username "admin" -Password "secure123"
```

### With Database Integration

```powershell
.\Start-Dashboard.ps1 -DatabaseConnectionString "Server=localhost;Database=PingNetworks;Integrated Security=True"
```

This enables querying historical scan data from SQL Server for charts and statistics.

### Full Configuration

```powershell
.\Start-Dashboard.ps1 `
    -Port 8080 `
    -EnableAuth `
    -Username "admin" `
    -Password "MySecurePassword123!" `
    -DatabaseConnectionString "Server=localhost;Database=PingNetworks;Integrated Security=True" `
    -DatabaseType "SQLServer"
```

## Dashboard Pages

### 1. Home Dashboard
- Summary cards showing active scans, total scans, hosts scanned, and reachability rate
- Start new scan form with network input and parameters
- Active scans list with real-time progress bars
- Recent scan results chart (last 10 scans)

### 2. Scan History
- Filterable table of all historical scans
- Sortable columns (date, networks, hosts, duration)
- Availability trend chart showing reachability over time
- View scan details (coming soon)

### 3. API Documentation
- Complete REST API reference
- Example requests and responses
- Interactive API testing (coming soon)

## REST API Endpoints

### GET /api/status
Get dashboard status and statistics.

**Response:**
```json
{
  "activeScans": 0,
  "totalScans": 142,
  "hostsScanned": 15234,
  "reachableRate": 87.5,
  "uptime": "2.15:23:45.1234567"
}
```

### POST /api/scan/start
Start a new network scan.

**Request Body:**
```json
{
  "network": "192.168.1.0/24",
  "throttle": 50,
  "maxPings": null,
  "timeout": 1,
  "count": 1
}
```

**Response:**
```json
{
  "scanId": "scan_20251228_120000",
  "status": "running",
  "message": "Scan started successfully"
}
```

### GET /api/scan/{scanId}
Get status and results of a specific scan.

**Response:**
```json
{
  "scanId": "scan_20251228_120000",
  "status": "completed",
  "progress": 100,
  "results": [...]
}
```

### GET /api/history
Get scan history with optional filters.

**Query Parameters:**
- `limit` - Limit number of results (default: 100)
- `startDate` - Filter by start date (ISO 8601)
- `endDate` - Filter by end date (ISO 8601)

**Response:**
```json
[
  {
    "scanId": 1,
    "startTime": "2025-12-28T12:00:00",
    "endTime": "2025-12-28T12:05:00",
    "hostsScanned": 254,
    "hostsReachable": 187,
    "hostsUnreachable": 67
  }
]
```

## Database Integration

When a database connection string is provided, the dashboard will:
- Query scan history from the Scans table
- Display summary statistics from all historical scans
- Enable historical trend analysis with Chart.js visualizations
- Fallback to in-memory data if database is unavailable

**Supported Databases:**
- SQL Server (all editions)
- SQL Server Express
- LocalDB
- MySQL (planned)
- PostgreSQL (planned)

## Architecture

The dashboard uses:
- **Pode** - Lightweight PowerShell web framework
- **Chart.js** - Interactive data visualization
- **Vanilla JavaScript** - No heavy frontend frameworks
- **REST API** - Clean separation of frontend and backend
- **WebSockets** - Real-time updates (planned enhancement)

### File Structure

```
dashboard/
├── static/
│   ├── dashboard.css      # Main stylesheet
│   ├── dashboard.js       # Dashboard page JavaScript
│   └── history.js         # History page JavaScript
└── README.md              # This file

Start-Dashboard.ps1        # Dashboard server script
```

## Security Considerations

### Authentication
- Basic form-based authentication
- Session-based with configurable timeout (default: 1 hour)
- Passwords are compared in-memory (not hashed for demo purposes)
- **Production Recommendation:** Use HTTPS and implement proper password hashing

### HTTPS
Currently runs on HTTP only. For production use:
1. Generate SSL certificate
2. Update Pode endpoint to use HTTPS:
   ```powershell
   Add-PodeEndpoint -Address localhost -Port 8443 -Protocol Https -Certificate ./cert.pfx
   ```

### Network Access
- Default: Localhost only (not accessible from other machines)
- To allow remote access, change address:
   ```powershell
   Add-PodeEndpoint -Address * -Port 8080 -Protocol Http
   ```
- **Warning:** Only expose to trusted networks

## Troubleshooting

### Pode Module Installation Fails
```powershell
Install-Module -Name Pode -Scope CurrentUser -Force
```

### Port Already in Use
```powershell
# Use a different port
.\Start-Dashboard.ps1 -Port 9000
```

### Database Connection Fails
- Verify SQL Server is running
- Check connection string format
- Test connectivity: `Test-Connection -ComputerName sqlserver -Port 1433`
- Verify database exists and user has permissions

### Charts Not Displaying
- Ensure internet connection (Chart.js loads from CDN)
- Check browser console for JavaScript errors
- Verify scan history contains data

## Planned Enhancements

- [ ] WebSocket support for real-time scan updates
- [ ] Scan detail view with individual host results
- [ ] Network topology visualization
- [ ] Export reports directly from dashboard
- [ ] Dark mode toggle
- [ ] User management and role-based access
- [ ] Scheduled scan configuration from UI
- [ ] Email notification configuration
- [ ] Advanced filtering and search
- [ ] Scan comparison tool

## Contributing

Issues and pull requests welcome! Please ensure:
- Code follows PowerShell best practices
- JavaScript is vanilla (no framework dependencies)
- Responsive design maintained
- API endpoints documented

## License

Same license as Ping-Networks project.
