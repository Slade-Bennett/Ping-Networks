# Test-EndToEnd.ps1
# End-to-end integration tests for complete workflows

[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'
$testsPassed = 0
$testsFailed = 0
$startTime = Get-Date

$projectRoot = Split-Path $PSScriptRoot -Parent
$mainScript = Join-Path $projectRoot "Ping-Networks.ps1"
$testOutputDir = Join-Path $PSScriptRoot "test-output"

# Create test output directory
if (-not (Test-Path $testOutputDir)) {
    New-Item -Path $testOutputDir -ItemType Directory -Force | Out-Null
}

function Test-EndToEnd {
    param(
        [string]$Name,
        [scriptblock]$Test
    )

    try {
        $result = & $Test
        if ($result) {
            Write-Host "  [PASS] $Name" -ForegroundColor Green
            $script:testsPassed++
        } else {
            Write-Host "  [FAIL] $Name" -ForegroundColor Red
            $script:testsFailed++
        }
    }
    catch {
        Write-Host "  [FAIL] $Name - Exception: $_" -ForegroundColor Red
        $script:testsFailed++
    }
}

# Test complete workflow: CSV → HTML
Test-EndToEnd "Complete workflow: CSV input → HTML output" {
    $params = @{
        InputPath = Join-Path $projectRoot "sample-data\NetworkData.csv"
        OutputDirectory = $testOutputDir
        Html = $true
        MaxPings = 3
    }

    $output = & $mainScript @params -ErrorAction Stop 2>&1

    $htmlFile = Get-ChildItem -Path $testOutputDir -Filter "*.html" | Select-Object -First 1

    if ($htmlFile) {
        $content = Get-Content -Path $htmlFile.FullName -Raw
        # Verify HTML contains expected elements
        ($content -match "Network Scan Report") -and
        ($content -match "Total Hosts") -and
        ($content -match "Reachable")
    } else {
        $false
    }
}

# Cleanup
Remove-Item "$testOutputDir\*" -Force -ErrorAction SilentlyContinue

# Test complete workflow: TXT → Excel + JSON
Test-EndToEnd "Complete workflow: TXT input → Excel + JSON output" {
    $params = @{
        InputPath = Join-Path $projectRoot "sample-data\NetworkData.txt"
        OutputDirectory = $testOutputDir
        Excel = $true
        Json = $true
        MaxPings = 3
    }

    $output = & $mainScript @params -ErrorAction Stop 2>&1

    $excelFile = Get-ChildItem -Path $testOutputDir -Filter "*.xlsx" | Select-Object -First 1
    $jsonFile = Get-ChildItem -Path $testOutputDir -Filter "*.json" | Select-Object -First 1

    if ($excelFile -and $jsonFile) {
        # Verify JSON contains expected structure
        $jsonContent = Get-Content -Path $jsonFile.FullName -Raw | ConvertFrom-Json
        ($null -ne $jsonContent.ScanMetadata) -and
        ($null -ne $jsonContent.Results) -and
        ($jsonContent.Results.Count -gt 0)
    } else {
        $false
    }
}

# Cleanup
Remove-Item "$testOutputDir\*" -Force -ErrorAction SilentlyContinue

# Test CIDR notation end-to-end
Test-EndToEnd "CIDR notation: Parse → Scan → Report" {
    # Create temporary test file
    $tempFile = Join-Path $testOutputDir "test-cidr.txt"
    "10.0.0.0/30" | Out-File -FilePath $tempFile -Encoding UTF8

    $params = @{
        InputPath = $tempFile
        OutputDirectory = $testOutputDir
        Html = $true
        MaxPings = 5
    }

    $output = & $mainScript @params -ErrorAction Stop 2>&1

    $htmlFile = Get-ChildItem -Path $testOutputDir -Filter "*.html" | Select-Object -First 1

    if ($htmlFile) {
        $content = Get-Content -Path $htmlFile.FullName -Raw
        # /30 network has 2 usable hosts
        ($content -match "10\.0\.0") -and ($output -match "Successfully")
    } else {
        $false
    }
}

# Cleanup
Remove-Item "$testOutputDir\*" -Force -ErrorAction SilentlyContinue

# Test IP range end-to-end
Test-EndToEnd "IP range: Parse → Scan → Report" {
    # Create temporary test file
    $tempFile = Join-Path $testOutputDir "test-range.txt"
    "192.168.1.1-192.168.1.5" | Out-File -FilePath $tempFile -Encoding UTF8

    $params = @{
        InputPath = $tempFile
        OutputDirectory = $testOutputDir
        Json = $true
        MaxPings = 10
    }

    $output = & $mainScript @params -ErrorAction Stop 2>&1

    $jsonFile = Get-ChildItem -Path $testOutputDir -Filter "*.json" | Select-Object -First 1

    if ($jsonFile) {
        $jsonContent = Get-Content -Path $jsonFile.FullName -Raw | ConvertFrom-Json
        # Range has 5 IPs
        ($jsonContent.ScanMetadata.TotalHosts -eq 5) -and
        ($jsonContent.Results.Count -eq 5)
    } else {
        $false
    }
}

# Cleanup
Remove-Item "$testOutputDir\*" -Force -ErrorAction SilentlyContinue

# Test backward compatibility with traditional format
Test-EndToEnd "Backward compatibility: Traditional IP/Subnet/CIDR format" {
    $params = @{
        InputPath = Join-Path $projectRoot "sample-data\NetworkData.xlsx"
        OutputDirectory = $testOutputDir
        Html = $true
        MaxPings = 3
    }

    $output = & $mainScript @params -ErrorAction Stop 2>&1

    $htmlFile = Get-ChildItem -Path $testOutputDir -Filter "*.html" | Select-Object -First 1

    ($null -ne $htmlFile) -and ($output -match "Successfully")
}

# Final cleanup
Remove-Item -Path $testOutputDir -Recurse -Force -ErrorAction SilentlyContinue

# Return results
$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds

return [PSCustomObject]@{
    Passed = $testsPassed
    Failed = $testsFailed
    Total = $testsPassed + $testsFailed
    Duration = [math]::Round($duration, 2)
}
