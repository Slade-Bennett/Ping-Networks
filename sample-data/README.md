# Sample Network Data Files

This directory contains sample input files for testing the Ping-Networks script with various network configurations and edge cases.

---

## File Descriptions

### 1. NetworkData.xlsx (Excel Format)
**Purpose:** Basic example using Excel format with traditional IP/Subnet Mask columns
**Use Case:** Standard production usage, legacy format support
**Networks:** 3-5 networks in traditional format (IP, Subnet Mask, CIDR columns)

**Example Usage:**
```powershell
.\Invoke-NetworkScan.ps1 -InputPath '.\sample-data\NetworkData.xlsx' -Excel
```

---

### 2. NetworkData-CIDR.xlsx (Excel Format - CIDR Notation)
**Purpose:** Example using simplified "Network" column with CIDR notation
**Use Case:** Modern format, cleaner input
**Networks:** CIDR notation (/24, /28) and IP ranges

**Example Usage:**
```powershell
.\Invoke-NetworkScan.ps1 -InputPath '.\sample-data\NetworkData-CIDR.xlsx' -Excel -Html
```

---

### 3. NetworkData.csv (CSV Format)
**Purpose:** CSV input format example
**Use Case:** Integration with other tools, lightweight alternative to Excel
**Networks:** Basic CIDR and range formats

**Example Usage:**
```powershell
.\Invoke-NetworkScan.ps1 -InputPath '.\sample-data\NetworkData.csv' -Html
```

---

### 4. NetworkData.txt (Text Format)
**Purpose:** Plain text input, one network per line
**Use Case:** Quick ad-hoc scans, scripted input generation
**Networks:** CIDR and range notation

**Example Usage:**
```powershell
.\Invoke-NetworkScan.ps1 -InputPath '.\sample-data\NetworkData.txt' -Json
```

---

### 5. NetworkData-EdgeCases.csv (Edge Case Testing)
**Purpose:** Test edge cases and boundary conditions
**Use Case:** Validation testing, quality assurance

**Networks Included:**
- Single IP: `10.0.0.1`
- Point-to-point (/30): `192.168.1.0/30` (2 usable hosts)
- Host address (/32): `172.16.0.0/32` (0 usable hosts)
- Small range: `10.1.1.1-10.1.1.5` (5 hosts)
- Single IP range: `192.168.100.100-192.168.100.100` (1 host)
- Point-to-point link (/31): `10.10.10.0/31` (0 usable hosts per RFC 3021)
- Small subnet (/28): `172.20.0.0/28` (14 usable hosts)

**Example Usage:**
```powershell
.\Invoke-NetworkScan.ps1 -InputPath '.\sample-data\NetworkData-EdgeCases.csv' -Html -Verbose
```

**Expected Behavior:**
- /32 networks should show 0 usable hosts (network = broadcast)
- /31 networks should show 0 usable hosts (no host IPs by default)
- Single IP and single IP range should handle correctly
- /30 networks should show exactly 2 usable hosts

---

### 6. NetworkData-Mixed.txt (Mixed Format Testing)
**Purpose:** Test parsing of various input formats in text file
**Use Case:** Format flexibility validation

**Formats Included:**
- CIDR notation: `10.0.0.0/24`
- IP ranges: `192.168.1.1-192.168.1.50`
- Small subnets: `/28`, `/27`, `/30`
- Single IP: `172.20.1.1`

**Example Usage:**
```powershell
.\Invoke-NetworkScan.ps1 -InputPath '.\sample-data\NetworkData-Mixed.txt' -Html -MaxPings 10
```

---

### 7. NetworkData-Large.csv (Performance Testing)
**Purpose:** Test performance with multiple networks
**Use Case:** Stress testing, performance benchmarking

**Networks:** 20 networks across multiple subnets
- 10x /24 networks (254 hosts each = 2,540 hosts)
- 4x /28 networks (14 hosts each = 56 hosts)
- 4x /27 networks (30 hosts each = 120 hosts)
- 2x IP ranges (50 hosts each = 100 hosts)
- **Total: ~2,816 hosts** (without MaxPings limit)

**Example Usage (with limit):**
```powershell
.\Invoke-NetworkScan.ps1 -InputPath '.\sample-data\NetworkData-Large.csv' -Html -MaxPings 20 -Throttle 100
```

**Example Usage (full scan - may take several minutes):**
```powershell
.\Invoke-NetworkScan.ps1 -InputPath '.\sample-data\NetworkData-Large.csv' -Excel -Throttle 100
```

**Performance Notes:**
- Use `-MaxPings` to limit hosts per network for testing
- Increase `-Throttle` (default 50) to 100+ for faster scans
- Full scan of all 2,816 hosts takes approximately 3-5 minutes at default throttle

---

### 8. NetworkData-Invalid.csv (Error Handling Testing)
**Purpose:** Test error handling and validation
**Use Case:** Quality assurance, error message validation

⚠️ **WARNING:** This file contains intentionally invalid data and will produce errors!

**Invalid Entries Included:**
- Valid network: `10.0.0.0/24` (control)
- CIDR out of range: `192.168.1.0/33` (max is /32)
- Invalid format: `invalid-format`
- Invalid IP in range: `10.0.0.1-999.999.999.999`
- Invalid IP address: `256.256.256.256/24` (octets > 255)
- Negative CIDR: `10.0.0.0/-5`

**Example Usage:**
```powershell
.\Invoke-NetworkScan.ps1 -InputPath '.\sample-data\NetworkData-Invalid.csv' -Html -Verbose
```

**Expected Behavior:**
- Script should display improved error messages for each invalid entry
- Valid networks should still be processed
- Errors should show examples of correct formats
- Script should continue processing valid entries after encountering errors

**Error Messages to Verify:**
1. "Invalid CIDR value '33'. Must be between 0 and 32 (e.g., /24 for Class C network)"
2. "Invalid network string format: 'invalid-format'" (with format examples)
3. "Invalid IP address in range..." (with guidance)

---

## Testing Workflows

### Basic Functionality Test
```powershell
.\Invoke-NetworkScan.ps1 -InputPath '.\sample-data\NetworkData.csv' -Html
```

### Edge Case Validation
```powershell
.\Invoke-NetworkScan.ps1 -InputPath '.\sample-data\NetworkData-EdgeCases.csv' -Html -Verbose
```

### Error Handling Test
```powershell
.\Invoke-NetworkScan.ps1 -InputPath '.\sample-data\NetworkData-Invalid.csv' -Html -Verbose
```

### Performance Benchmark
```powershell
Measure-Command {
    .\Invoke-NetworkScan.ps1 -InputPath '.\sample-data\NetworkData-Large.csv' -Html -MaxPings 50 -Throttle 100
}
```

### Multi-Format Test
```powershell
# Test all formats
.\Invoke-NetworkScan.ps1 -InputPath '.\sample-data\NetworkData.xlsx' -Excel
.\Invoke-NetworkScan.ps1 -InputPath '.\sample-data\NetworkData.csv' -Csv
.\Invoke-NetworkScan.ps1 -InputPath '.\sample-data\NetworkData.txt' -Json
```

---

## Creating Custom Sample Files

### CSV Format Template
```csv
Network
10.0.0.0/24
192.168.1.1-192.168.1.50
172.16.0.0/28
```

### Text Format Template
```
10.0.0.0/24
192.168.1.1-192.168.1.50
172.16.0.0/28
10.1.1.1
```

### Excel Format (Traditional)
| IP | Subnet Mask | CIDR |
|----|-------------|------|
| 10.0.0.0 | 255.255.255.0 | 24 |
| 192.168.1.0 | 255.255.255.240 | 28 |

### Excel Format (Simplified)
| Network |
|---------|
| 10.0.0.0/24 |
| 192.168.1.1-192.168.1.50 |

---

## Supported Network Formats

1. **CIDR Notation:** `10.0.0.0/24`, `192.168.1.0/28`
2. **IP Ranges:** `10.0.0.1-10.0.0.50`, `192.168.1.1-192.168.1.254`
3. **Single IP:** `172.16.0.1` (treated as single host)
4. **Traditional Object:** `{ IP: "10.0.0.0", "Subnet Mask": "255.255.255.0" }`

---

## Notes

- All sample files are safe to run on isolated networks
- IP addresses use RFC 1918 private ranges (10.x.x.x, 192.168.x.x, 172.16-31.x.x)
- No sample files will ping external/public IPs
- Use `-MaxPings` parameter to limit scan size during testing
- Use `-Verbose` to see detailed processing information
