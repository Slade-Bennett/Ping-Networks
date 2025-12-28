# Ping-Networks Test Suite

This directory contains comprehensive test scripts for validating the v1.8.0 enhanced features of Ping-Networks.

## Quick Start

### Run All Tests (Recommended)
```powershell
.\Run-AllTests.ps1
```

This master script provides an interactive menu to run individual tests or the entire suite.

### Run Individual Tests
```powershell
.\Test-AlertThresholds.ps1    # Test alert threshold features
.\Test-RetentionPolicy.ps1    # Test history retention cleanup
.\Test-TrendAnalysis.ps1      # Test trend analysis and statistics
.\Test-GracefulAbort.ps1      # Test Ctrl+C handling (manual)
.\Test-IntegrationAll.ps1     # Comprehensive integration test
```

## Test Descriptions

### 1. Test-AlertThresholds.ps1
**Purpose:** Validates configurable alert threshold features

**What it tests:**
- `MinChangesToAlert` - minimum number of changes to trigger alerts
- `MinChangePercentage` - percentage-based alert thresholds
- Alert threshold logic and verbose output

**Duration:** ~2 minutes

**Expected Results:**
- Baseline scan created successfully
- Alert thresholds properly prevent/allow email alerts
- Verbose output shows "Skipping email alert" messages when below threshold

---

### 2. Test-RetentionPolicy.ps1
**Purpose:** Validates automatic cleanup of old scan history files

**What it tests:**
- `RetentionDays` parameter functionality
- Automatic deletion of files older than retention period
- Both ScanHistory and ChangeReport file cleanup

**Duration:** ~1 minute

**Expected Results:**
- Creates fake old files (10, 20, 30, 40, 50 days old)
- Runs scan with 25-day retention
- Deletes 5 files (those older than 25 days)
- No files older than retention period remain

**Success Criteria:**
- ✓ Exactly 5 files deleted
- ✓ All remaining files within retention period

---

### 3. Test-TrendAnalysis.ps1
**Purpose:** Validates trend reporting and availability statistics

**What it tests:**
- `GenerateTrendReport` functionality
- Historical data analysis across multiple scans
- Uptime percentage calculations
- Response time statistics
- Host categorization (Always/Mostly/Intermittent/Never Reachable)

**Duration:** ~3 minutes

**Expected Results:**
- Creates 5 baseline scans with intervals
- Generates comprehensive trend report
- Report contains valid metadata, summary, and host trends
- Uptime percentages are valid (0-100%)
- Category counts sum to total unique hosts

**Success Criteria:**
- ✓ Trend report JSON file created
- ✓ All validation checks pass (4/4)

---

### 4. Test-GracefulAbort.ps1
**Purpose:** Validates Ctrl+C handling and partial result saving

**What it tests:**
- Graceful abort functionality
- Partial results preservation
- All output formats generated on interrupt

**Duration:** ~1 minute + manual intervention

**Manual Steps Required:**
1. Test starts a network scan
2. Wait for progress to show (several hosts scanned)
3. Press **Ctrl+C** to interrupt
4. Verify partial results were saved

**Expected Results:**
- Scan can be interrupted with Ctrl+C
- Excel, HTML, and JSON files are generated
- Partial results contain scanned host data

**Success Criteria:**
- ✓ All output formats created (Excel, HTML, JSON)
- ✓ JSON contains Results array with host data

**Note:** This is a **MANUAL** test requiring user intervention.

---

### 5. Test-IntegrationAll.ps1
**Purpose:** Comprehensive integration test of all v1.8.0 features

**What it tests:**
- Complete workflow of all enhanced features
- Feature interactions and compatibility
- Multiple scans with history building
- Retention policy + trend analysis + alert thresholds
- All output format generation

**Duration:** ~5 minutes

**Test Phases:**
1. **Phase 1:** Build scan history (3 scans)
2. **Phase 2:** Test retention policy with fake old files
3. **Phase 3:** Generate and validate trend analysis
4. **Phase 4:** Test alert thresholds (MinChangesToAlert, MinChangePercentage)
5. **Phase 5:** Verify all output formats

**Expected Results:**
- 10-12 individual test checks
- High success rate (90%+)
- All features working together correctly

**Success Criteria:**
- ✓ All 10+ validation checks pass
- ✓ 100% or near-100% success rate

---

## Test Artifacts

All tests create temporary files in: `C:\Temp\PingNetworksTest`

Tests offer cleanup at completion. If you choose not to cleanup, you can:
- Review generated reports
- Inspect JSON/XML output structure
- Verify Excel formatting
- Check HTML report rendering

## Requirements

- PowerShell 5.0 or later
- Microsoft Excel installed (for Excel output tests)
- Network connectivity (tests use sample-data/NetworkData.xlsx)
- ~100 MB free disk space for test artifacts

## Troubleshooting

### "Input file not found"
Ensure you're running tests from the project root directory:
```powershell
cd "C:\Users\Slade\Documents\Visual Studio 2022\Ping-Networks"
.\tests\Run-AllTests.ps1
```

### Excel COM errors
- Ensure Excel is installed
- Close any open Excel instances
- Run PowerShell as Administrator

### Test failures
1. Check verbose output for error details
2. Review test artifacts in `C:\Temp\PingNetworksTest`
3. Ensure sample-data/NetworkData.xlsx exists
4. Verify network connectivity for ping operations

## Test Development

### Adding New Tests
1. Create `Test-FeatureName.ps1` in this directory
2. Follow existing test structure:
   - Clear header with test purpose
   - Setup test environment
   - Run feature with validation
   - Check results and report pass/fail
   - Offer cleanup
3. Add to `Run-AllTests.ps1` menu

### Test Best Practices
- Use `C:\Temp\PingNetworksTest` for artifacts
- Always offer cleanup option
- Provide clear pass/fail indicators (✓/✗)
- Include verbose output for debugging
- Document manual intervention requirements

## Version History

### v1.8.0 (2025-12-28)
- Initial test suite creation
- 5 comprehensive test scripts
- Master test runner
- Tests for: Alert Thresholds, Retention Policy, Trend Analysis, Graceful Abort, Full Integration

---

For questions or issues, please refer to the main project README or ROADMAP.
