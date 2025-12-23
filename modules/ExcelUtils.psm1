# ExcelUtils.psm1
# Excel COM Automation Utilities
#
# This module provides PowerShell functions for working with Excel workbooks
# using COM automation. It handles common operations like:
# - Creating and closing Excel sessions
# - Opening/creating workbooks
# - Reading data from worksheets
# - Writing data to worksheets with formatting
# - Proper COM object cleanup to prevent Excel process leaks
#
# All functions use proper error handling and COM object disposal.

#region Excel Color Constants
[int]$ExcelColorGreen = 5296274 # A common green color
[int]$ExcelColorRed   = 255     # Red
#endregion

<#
.SYNOPSIS
    Creates and returns a new Excel Application COM object.
.DESCRIPTION
    This function initializes a new instance of the Excel application.
    It allows control over the visibility of the Excel window.
.PARAMETER Visible
    Specifies if the Excel application window should be visible. If omitted, Excel runs in the background.
.OUTPUTS
    [Microsoft.Office.Interop.Excel.Application]
    Returns an Excel Application COM object. Returns $null if an error occurs.
.EXAMPLE
    $excelApp = New-ExcelSession -Visible
    # Creates a visible Excel application instance.
.EXAMPLE
    $excelApp = New-ExcelSession
    # Creates a hidden Excel application instance.
#>
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

<#
.SYNOPSIS
    Quits an Excel Application COM object and releases its resources.
.DESCRIPTION
    This function properly closes an Excel application instance and
    ensures that its COM objects are released from memory, preventing
    lingering Excel processes.
.PARAMETER Excel
    The Excel Application COM object to close.
.EXAMPLE
    Close-ExcelSession -Excel $excelApp
    # Quits the Excel application and cleans up COM objects.
#>
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

<#
.SYNOPSIS
    Opens an existing Excel workbook or creates a new one.
.DESCRIPTION
    This function takes an Excel Application COM object and a path.
    If the path exists, it opens the workbook. Otherwise, it creates a new workbook.
.PARAMETER Path
    The full path to the Excel workbook to open or create.
.PARAMETER Excel
    The Excel Application COM object.
.OUTPUTS
    [Microsoft.Office.Interop.Excel.Workbook]
    Returns an Excel Workbook COM object. Returns $null if an error occurs.
.EXAMPLE
    $workbook = Get-ExcelWorkbook -Path "C:\Data\MyWorkbook.xlsx" -Excel $excelApp
    # Opens MyWorkbook.xlsx if it exists, otherwise creates a new one.
#>
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
        # Ensure an absolute path is used for Excel COM object
        $absolutePath = [System.IO.Path]::GetFullPath($Path)

        if (Test-Path $absolutePath) {
            $workbook = $Excel.Workbooks.Open($absolutePath)
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

<#
.SYNOPSIS
    Reads data from a specified worksheet in an Excel workbook.
.DESCRIPTION
    This function reads data from a specific sheet within an Excel workbook,
    starting from the second row (assuming the first row contains headers).
    It returns the data as an array of PSCustomObjects, where property names
    are derived from the header row.
.PARAMETER Workbook
    The Excel Workbook COM object to read from.
.PARAMETER SheetIndex
    The 1-based index of the worksheet to read. Defaults to 1 (the first sheet).
.OUTPUTS
    [PSCustomObject[]]
    Returns an array of PSCustomObjects representing the data in the sheet.
    Returns $null if an error occurs or no data is found (excluding headers).
.EXAMPLE
    $data = Read-ExcelSheet -Workbook $workbook -SheetIndex 1
    # Reads data from the first sheet.
.EXAMPLE
    $networkData = Read-ExcelSheet -Workbook $inputWorkbook -SheetIndex 1 | Where-Object { $_.IP -like "192.168.*" }
    # Reads data and filters it.
#>
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

<#
.SYNOPSIS
    Writes an array of PSCustomObjects to a specified worksheet in an Excel workbook.
.DESCRIPTION
    This function writes data from an array of PSCustomObjects to an Excel worksheet.
    It automatically uses the property names of the first object as headers.
    Optionally, it can apply color formatting to cells in a specified column
    based on a provided color map.
.PARAMETER Workbook
    The Excel Workbook COM object to write to.
.PARAMETER Data
    An array of PSCustomObjects to write to the worksheet. Each object's properties
    will become columns in Excel.
.PARAMETER WorksheetName
    The name of the worksheet to write to. If the sheet exists, its content will be cleared.
    If it does not exist, a new sheet with this name will be created. Defaults to 'Sheet1'.
.PARAMETER ColorColumn
    (Optional) The name of the column whose cells should be colored based on their values.
    Defaults to 'Status'.
.PARAMETER ColorMap
    (Optional) A hashtable where keys are cell values (strings) and values are Excel
    color codes (integers). Used in conjunction with -ColorColumn to apply specific colors.
    Defaults to mapping 'Reachable' to green and 'Unreachable' to red.
.EXAMPLE
    $data = @(
        [PSCustomObject]@{ Host = "192.168.1.1"; Status = "Reachable" },
        [PSCustomObject]@{ Host = "192.168.1.2"; Status = "Unreachable" }
    )
    Write-ExcelSheet -Workbook $workbook -Data $data -WorksheetName "Ping Results"
    # Writes data to a new sheet named "Ping Results" with default coloring.
.EXAMPLE
    $customMap = @{ "SUCCESS" = 65535; "FAILURE" = 255 } # Yellow and Red
    Write-ExcelSheet -Workbook $workbook -Data $otherData -WorksheetName "Custom Status" -ColorColumn "Result" -ColorMap $customMap
    # Writes data and applies custom coloring based on the 'Result' column.
#>
function Write-ExcelSheet {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Workbook,

        [Parameter(Mandatory = $true)]
        [object[]]$Data,

        [Parameter(Mandatory = $false)]
        [string]$WorksheetName = 'Sheet1',

        [Parameter(Mandatory = $false)]
        [string]$ColorColumn = 'Status',

        [Parameter(Mandatory = $false)]
        [hashtable]$ColorMap = @{
            'Reachable'   = $ExcelColorGreen
            'Unreachable' = $ExcelColorRed
        }
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
            Write-Verbose "Write-ExcelSheet: Writing headers: ($($headers -join ', ')) to sheet '$WorksheetName'."
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
                                $cell = $sheet.Cells.Item($row + 2, $col + 1)
                                $value = $Data[$row].($headers[$col])
                                
                                # Explicitly convert value to string to avoid casting issues with Excel COM
                                $cell.Value = [string]$value
                    # Apply color if this is the designated column and value is in ColorMap
                    if (($headers[$col] -eq $ColorColumn) -and $ColorMap.ContainsKey($value)) {
                        $cell.Interior.Color = $ColorMap[$value]
                    }
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

<#
.SYNOPSIS
    Saves and closes an Excel workbook.
.DESCRIPTION
    This function saves the specified Excel workbook to a given path and then closes it.
    It also releases the workbook's COM object.
.PARAMETER Workbook
    The Excel Workbook COM object to save and close.
.PARAMETER Path
    The full path where the workbook should be saved.
.EXAMPLE
    Close-ExcelWorkbook -Workbook $workbook -Path "C:\Results\MyPingResults.xlsx"
    # Saves the workbook and closes it.
#>
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