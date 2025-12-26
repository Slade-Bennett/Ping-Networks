# Test-InputFormats.ps1
# Tests for different input file formats (Excel, CSV, TXT)

[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'
$testsPassed = 0
$testsFailed = 0
$startTime = Get-Date

$projectRoot = Split-Path $PSScriptRoot -Parent
$mainScript = Join-Path $projectRoot "Ping-Networks.ps1"

function Test-InputFormat {
    param(
        [string]$Name,
        [string]$InputFile,
        [int]$ExpectedNetworkCount
    )

    try {
        # Run script with minimal pings
        $output = & $mainScript -InputPath $InputFile -Html -MaxPings 2 -ErrorAction Stop 2>&1 | Out-String

        # Check if HTML was generated (indicates success)
        if ($output -match "Successfully") {
            Write-Host "  [PASS] $Name" -ForegroundColor Green
            $script:testsPassed++
        } else {
            Write-Host "  [FAIL] $Name - No output generated" -ForegroundColor Red
            Write-Host "    Output: $output" -ForegroundColor DarkGray
            $script:testsFailed++
        }
    }
    catch {
        Write-Host "  [FAIL] $Name - Exception: $_" -ForegroundColor Red
        $script:testsFailed++
    }
}

# Test Excel input (traditional format)
Test-InputFormat -Name "Excel input (.xlsx) - Traditional format" `
    -InputFile (Join-Path $projectRoot "sample-data\NetworkData.xlsx") `
    -ExpectedNetworkCount 2

# Test Excel input (CIDR/Range format)
Test-InputFormat -Name "Excel input (.xlsx) - CIDR/Range format" `
    -InputFile (Join-Path $projectRoot "sample-data\NetworkData-CIDR.xlsx") `
    -ExpectedNetworkCount 4

# Test CSV input
Test-InputFormat -Name "CSV input (.csv)" `
    -InputFile (Join-Path $projectRoot "sample-data\NetworkData.csv") `
    -ExpectedNetworkCount 3

# Test TXT input
Test-InputFormat -Name "Text input (.txt)" `
    -InputFile (Join-Path $projectRoot "sample-data\NetworkData.txt") `
    -ExpectedNetworkCount 4

# Return results
$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds

return [PSCustomObject]@{
    Passed = $testsPassed
    Failed = $testsFailed
    Total = $testsPassed + $testsFailed
    Duration = [math]::Round($duration, 2)
}
