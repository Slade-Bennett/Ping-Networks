# ExcelUtils.psm1
# A module for working with Excel using COM objects.

function New-ExcelSession {
    [CmdletBinding()]
    param(
        [switch]$Visible
    )

    try {
        $excel = New-Object -ComObject Excel.Application -ErrorAction Stop
        $excel.Visible = $Visible.IsPresent
        return $excel
    }
    catch {
        Write-Error "Failed to create Excel session: $_"
        return $null
    }
}

function Close-ExcelSession {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Excel
    )

    try {
        $Excel.Quit()
    }
    catch {
        Write-Error "Failed to quit Excel session: $_"
    }
    finally {
        [System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($Excel) | Out-Null
        [GC]::Collect()
        [GC]::WaitForPendingFinalizers()
    }
}

function Get-ExcelWorkbook {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        $Excel
    )

    $workbook = $null
    try {
        if (Test-Path $Path) {
            $workbook = $Excel.Workbooks.Open($Path)
        } else {
            $workbook = $Excel.Workbooks.Add()
        }
        return $workbook
    }
    catch {
        Write-Error "Failed to get workbook for path '$Path': $_"
        if ($workbook) {
            [System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($workbook) | Out-Null
        }
        return $null
    }
}

function Read-ExcelSheet {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Workbook,

        [Parameter(Mandatory = $false)]
        [int]$SheetIndex = 1
    )

    $sheet = $null
    try {
        $sheet = $Workbook.Sheets.Item($SheetIndex)
        $usedRange = $sheet.UsedRange
        $rowCount = $usedRange.Rows.Count
        $colCount = $usedRange.Columns.Count

        $data = for ($row = 2; $row -le $rowCount; $row++) {
            $rowObject = New-Object PSObject
            for ($col = 1; $col -le $colCount; $col++) {
                $header = $usedRange.Cells.Item(1, $col).Text
                $value = $usedRange.Cells.Item($row, $col).Text
                $rowObject | Add-Member -MemberType NoteProperty -Name $header -Value $value
            }
            $rowObject
        }
        return $data
    }
    catch {
        Write-Error "Failed to read data from sheet: $_"
        return $null
    }
    finally {
        if ($sheet) {
            [System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($sheet) | Out-Null
        }
    }
}

function Write-ExcelSheet {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Workbook,

        [Parameter(Mandatory = $true)]
        [object[]]$Data,

        [Parameter(Mandatory = $false)]
        [string]$WorksheetName = 'Sheet1'
    )

    $sheet = $null
    try {
        try {
            $sheet = $Workbook.Sheets.Item($WorksheetName)
            $sheet.Cells.Clear()
        } catch {
            $sheet = $Workbook.Sheets.Add()
            $sheet.Name = $WorksheetName
        }

        # Write headers
        if ($Data.Count -gt 0) {
            $headers = $Data[0].PSObject.Properties.Name
            for ($i = 0; $i -lt $headers.Length; $i++) {
                $sheet.Cells.Item(1, $i + 1) = $headers[$i]
            }
            $headerRange = $sheet.Range("A1", $sheet.Cells.Item(1, $headers.Length))
            $headerRange.Font.Bold = $true
            $headerRange.Interior.ColorIndex = 15
            $headerRange.Borders.LineStyle = 1

            # Write data
            for ($row = 0; $row -lt $Data.Length; $row++) {
                for ($col = 0; $col -lt $headers.Length; $col++) {
                    $sheet.Cells.Item($row + 2, $col + 1) = $Data[$row].($headers[$col])
                }
            }
            
            $sheet.Columns.AutoFit()
        }
    }
    catch {
        Write-Error "Failed to write data to sheet '$WorksheetName': $_"
    }
    finally {
        if ($sheet) {
            [System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($sheet) | Out-Null
        }
    }
}

function Close-ExcelWorkbook {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Workbook,

        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    try {
        $Workbook.SaveAs($Path)
        $Workbook.Close()
    }
    catch {
        Write-Error "Failed to close workbook: $_"
    }
    finally {
        [System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($Workbook) | Out-Null
    }
}

Export-ModuleMember -Function New-ExcelSession, Close-ExcelSession, Get-ExcelWorkbook, Read-ExcelSheet, Write-ExcelSheet, Close-ExcelWorkbook