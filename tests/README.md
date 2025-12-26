# Ping-Networks Testing Suite

Automated test suite for the Ping-Networks project. Run these tests before committing changes to ensure all features work correctly.

## Quick Start

```powershell
# Run all tests
.\tests\Run-Tests.ps1

# Run with verbose output
.\tests\Run-Tests.ps1 -Verbose
```

## Test Suites

### 1. Core Functions (`Test-CoreFunctions.ps1`)
Unit tests for fundamental functions:
- `Parse-NetworkInput` - CIDR, Range, Traditional, Object parsing
- `Get-UsableHosts` - Subnet calculation for /24, /28, /30
- `Get-IPRange` - IP range expansion

**What it tests:**
- CIDR notation parsing (`10.0.0.0/24`)
- IP range parsing (`192.168.1.1-192.168.1.5`)
- Subnet mask calculations
- Host enumeration accuracy

### 2. Input Formats (`Test-InputFormats.ps1`)
Integration tests for file input:
- Excel (.xlsx) - Traditional format
- Excel (.xlsx) - CIDR/Range format
- CSV (.csv)
- Text (.txt)

**What it tests:**
- File reading for each format
- Successful network extraction
- Output generation from each input type

### 3. Output Formats (`Test-OutputFormats.ps1`)
Integration tests for output generation:
- Excel (.xlsx)
- HTML (.html)
- JSON (.json)
- XML (.xml)
- CSV (.csv)
- Multiple formats simultaneously

**What it tests:**
- File creation for each output format
- File size validation (files aren't empty)
- Multiple format generation at once

### 4. End-to-End (`Test-EndToEnd.ps1`)
Full workflow tests:
- CSV → HTML complete workflow
- TXT → Excel + JSON complete workflow
- CIDR notation: Parse → Scan → Report
- IP range: Parse → Scan → Report
- Backward compatibility with traditional format

**What it tests:**
- Complete execution from input to output
- JSON structure validation
- HTML content validation
- Data accuracy across workflows

## Test Results

Tests return:
- **Exit Code 0**: All tests passed
- **Exit Code 1**: One or more tests failed

Output includes:
- Pass/Fail status for each test
- Test count summary
- Duration per suite
- Detailed failure messages

## Example Output

```
========================================
  Ping-Networks Test Suite
========================================

Running: Core Functions
========================================
  [PASS] Parse-NetworkInput: CIDR notation
  [PASS] Parse-NetworkInput: IP range
  [PASS] Get-UsableHosts: /24 network
  [PASS] All 9 tests passed

Running: Input Formats
========================================
  [PASS] Excel input (.xlsx) - Traditional format
  [PASS] CSV input (.csv)
  [PASS] All 4 tests passed

...

========================================
  Test Summary
========================================

Total Tests:  24
Passed:       24
Failed:       0
Duration:     45.3 seconds

ALL TESTS PASSED
```

## Running Individual Tests

```powershell
# Run only core function tests
.\tests\Test-CoreFunctions.ps1

# Run only output format tests
.\tests\Test-OutputFormats.ps1
```

## Pre-Commit Workflow

**Recommended workflow before committing:**

```powershell
# 1. Run all tests
.\tests\Run-Tests.ps1

# 2. If all pass, commit changes
git add .
git commit -m "Your commit message"

# 3. Push to remote
git push
```

## Test Configuration

Tests use:
- **MaxPings = 2-5**: Fast execution (pings only first few hosts)
- **Test Output Directory**: `tests/test-output/` (auto-cleaned)
- **Sample Data**: Uses files from `sample-data/` directory

## Troubleshooting

**Tests failing after code changes?**
1. Check error messages in test output
2. Run individual test suites to isolate the issue
3. Use `-Verbose` flag for detailed debugging

**Excel tests failing?**
- Ensure Microsoft Excel is installed
- Check Excel COM object permissions

**Slow test execution?**
- Tests are optimized with MaxPings to run quickly
- Full suite should complete in under 60 seconds

## Adding New Tests

To add a new test:

1. Edit the appropriate test file (`Test-*.ps1`)
2. Use the `Test-Function` or `Test-EndToEnd` helper
3. Follow existing test patterns
4. Run `Run-Tests.ps1` to verify

Example:
```powershell
Test-Function "My new test" {
    # Your test logic here
    $result = SomeFunction -Parameter "value"
    ($result -eq "expected")  # Return true/false
}
```

## Continuous Integration

Test suite is designed to work with CI/CD pipelines:
- Returns proper exit codes
- Outputs parseable results
- Cleans up after itself

Example GitHub Actions:
```yaml
- name: Run Tests
  run: |
    powershell -File tests/Run-Tests.ps1
```
