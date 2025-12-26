# Test-OutputFormats.ps1
# Tests for different output formats (Excel, HTML, JSON, XML, CSV)

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

function Test-OutputFormat {
    param(
        [string]$Name,
        [string]$FormatSwitch,
        [string]$ExpectedExtension
    )

    try {
        # Build parameters
        $params = @{
            InputPath = Join-Path $projectRoot "sample-data\NetworkData.csv"
            OutputDirectory = $testOutputDir
            MaxPings = 2
        }

        # Add format switch dynamically
        $params[$FormatSwitch] = $true

        # Run script
        $output = & $mainScript @params -ErrorAction Stop 2>&1

        # Check if file was created
        $outputFile = Get-ChildItem -Path $testOutputDir -Filter "*$ExpectedExtension" | Select-Object -First 1

        if ($outputFile) {
            Write-Host "  [PASS] $Name ($(([math]::Round($outputFile.Length / 1KB, 2))) KB)" -ForegroundColor Green
            $script:testsPassed++
        } else {
            Write-Host "  [FAIL] $Name - Output file not found" -ForegroundColor Red
            $script:testsFailed++
        }
    }
    catch {
        Write-Host "  [FAIL] $Name - Exception: $_" -ForegroundColor Red
        $script:testsFailed++
    }
}

# Test Excel output
Test-OutputFormat -Name "Excel output (.xlsx)" -FormatSwitch "Excel" -ExpectedExtension ".xlsx"

# Clean up before next test
Remove-Item "$testOutputDir\*" -Force -ErrorAction SilentlyContinue

# Test HTML output
Test-OutputFormat -Name "HTML output (.html)" -FormatSwitch "Html" -ExpectedExtension ".html"

# Clean up before next test
Remove-Item "$testOutputDir\*" -Force -ErrorAction SilentlyContinue

# Test JSON output
Test-OutputFormat -Name "JSON output (.json)" -FormatSwitch "Json" -ExpectedExtension ".json"

# Clean up before next test
Remove-Item "$testOutputDir\*" -Force -ErrorAction SilentlyContinue

# Test XML output
Test-OutputFormat -Name "XML output (.xml)" -FormatSwitch "Xml" -ExpectedExtension ".xml"

# Clean up before next test
Remove-Item "$testOutputDir\*" -Force -ErrorAction SilentlyContinue

# Test CSV output
Test-OutputFormat -Name "CSV output (.csv)" -FormatSwitch "Csv" -ExpectedExtension ".csv"

# Test multiple formats simultaneously
try {
    $params = @{
        InputPath = Join-Path $projectRoot "sample-data\NetworkData.csv"
        OutputDirectory = $testOutputDir
        Excel = $true
        Html = $true
        Json = $true
        MaxPings = 2
    }

    & $mainScript @params -ErrorAction Stop | Out-Null

    $excelFile = Get-ChildItem -Path $testOutputDir -Filter "*.xlsx"
    $htmlFile = Get-ChildItem -Path $testOutputDir -Filter "*.html"
    $jsonFile = Get-ChildItem -Path $testOutputDir -Filter "*.json"

    if ($excelFile -and $htmlFile -and $jsonFile) {
        Write-Host "  [PASS] Multiple formats simultaneously" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host "  [FAIL] Multiple formats simultaneously - Missing files" -ForegroundColor Red
        $testsFailed++
    }
}
catch {
    Write-Host "  [FAIL] Multiple formats simultaneously - Exception: $_" -ForegroundColor Red
    $testsFailed++
}

# Cleanup test output directory
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
