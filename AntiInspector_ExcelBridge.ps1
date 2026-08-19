[CmdletBinding()]
param(
    [switch]$NoExcel,
    [switch]$Once,
    [string]$InputFile,
    [string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'
$exportHeader = "Name`tClass`tBuild`tStatus"
$lastHash = $null
$lastError = $null

Add-Type -AssemblyName System.Windows.Forms

function Get-DefaultOutputDirectory {
    $addonDirectory = $PSScriptRoot
    $gameDirectory = [System.IO.Path]::GetFullPath((Join-Path $addonDirectory '..\..\..'))
    return (Join-Path $gameDirectory 'AntiInspector_Exports')
}

function Initialize-OutputDirectory {
    param([string]$RequestedDirectory)

    if ([string]::IsNullOrWhiteSpace($RequestedDirectory)) {
        $RequestedDirectory = Get-DefaultOutputDirectory
    } else {
        $RequestedDirectory = [System.IO.Path]::GetFullPath($RequestedDirectory)
    }

    try {
        New-Item -ItemType Directory -Path $RequestedDirectory -Force | Out-Null
        return $RequestedDirectory
    } catch {
        $fallback = Join-Path $PSScriptRoot 'Exports'
        New-Item -ItemType Directory -Path $fallback -Force | Out-Null
        Write-Warning "Cannot write to the WoW root. Using: $fallback"
        return $fallback
    }
}

function Get-TextHash {
    param([string]$Text)

    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
        $hashBytes = $sha.ComputeHash($bytes)
        return [System.BitConverter]::ToString($hashBytes)
    } finally {
        $sha.Dispose()
    }
}

function Repair-WowCyrillicEncoding {
    param([string]$Text)

    if ([string]::IsNullOrEmpty($Text)) {
        return $Text
    }

    # The 3.3.5a client puts CP1251 bytes on the Windows clipboard.  Windows
    # exposes those bytes to PowerShell as Windows-1252 characters, producing
    # strings such as "Ðûöàðü" instead of "Рыцарь".  Only repair text that has
    # the characteristic Latin-1 pattern and no meaningful Cyrillic already.
    $latin1Count = [System.Text.RegularExpressions.Regex]::Matches($Text, '[\u00C0-\u00FF]').Count
    $cyrillicCount = [System.Text.RegularExpressions.Regex]::Matches($Text, '[\u0400-\u04FF]').Count
    if ($latin1Count -lt 3 -or $latin1Count -le ($cyrillicCount * 2)) {
        return $Text
    }

    $windows1252 = [System.Text.Encoding]::GetEncoding(1252)
    $windows1251 = [System.Text.Encoding]::GetEncoding(1251)
    $originalBytes = $windows1252.GetBytes($Text)
    return $windows1251.GetString($originalBytes)
}

function Set-UnicodeClipboardText {
    param([string]$Text)

    [System.Windows.Forms.Clipboard]::SetText(
        $Text,
        [System.Windows.Forms.TextDataFormat]::UnicodeText
    )
}

function Write-Utf8Tsv {
    param(
        [string]$Text,
        [string]$Path
    )

    $utf8WithBom = New-Object System.Text.UTF8Encoding($true)
    [System.IO.File]::WriteAllText($Path, $Text, $utf8WithBom)
}

function Convert-TsvToXlsx {
    param(
        [string]$Text,
        [string]$Path
    )

    $excel = $null
    $workbook = $null
    $worksheet = $null
    $range = $null

    try {
        $rows = @($Text.Replace("`r", '').Split("`n"))
        while ($rows.Count -gt 0 -and [string]::IsNullOrEmpty($rows[$rows.Count - 1])) {
            if ($rows.Count -eq 1) {
                $rows = @()
            } else {
                $rows = @($rows[0..($rows.Count - 2)])
            }
        }
        if ($rows.Count -eq 0) {
            throw 'The export contains no rows.'
        }

        $firstFields = @($rows[0].Split("`t"))
        $columnCount = $firstFields.Count
        $rowCount = $rows.Count
        $matrix = [System.Array]::CreateInstance([object], @($rowCount, $columnCount))

        for ($rowIndex = 0; $rowIndex -lt $rowCount; $rowIndex++) {
            $fields = @($rows[$rowIndex].Split("`t"))
            for ($columnIndex = 0; $columnIndex -lt $columnCount; $columnIndex++) {
                $value = if ($columnIndex -lt $fields.Count) { $fields[$columnIndex] } else { '' }
                $matrix.SetValue($value, $rowIndex, $columnIndex)
            }
        }

        $excel = New-Object -ComObject Excel.Application
        $excel.Visible = $false
        $excel.DisplayAlerts = $false
        $workbook = $excel.Workbooks.Add()
        $worksheet = $workbook.Worksheets.Item(1)
        $worksheet.Name = 'AntiInspector'

        $startCell = $worksheet.Cells.Item(1, 1)
        $endCell = $worksheet.Cells.Item($rowCount, $columnCount)
        $range = $worksheet.Range($startCell, $endCell)
        $range.NumberFormat = '@'
        $range.Value2 = $matrix
        $worksheet.Rows.Item(1).Font.Bold = $true
        $worksheet.Rows.Item(1).Interior.ColorIndex = 15
        $range.AutoFilter() | Out-Null
        $range.EntireColumn.AutoFit() | Out-Null

        for ($column = 1; $column -le $columnCount; $column++) {
            $excelColumn = $worksheet.Columns.Item($column)
            if ($excelColumn.ColumnWidth -gt 45) {
                $excelColumn.ColumnWidth = 45
            }
            [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($excelColumn)
        }

        $workbook.SaveAs($Path, 51)
        $workbook.Close($false)
        $workbook = $null
        $excel.Quit()
        $excel = $null
        return $true
    } catch {
        Write-Warning "XLSX was not created: $($_.Exception.Message)"
        return $false
    } finally {
        if ($workbook -ne $null) {
            try { $workbook.Close($false) } catch {}
        }
        if ($excel -ne $null) {
            try { $excel.Quit() } catch {}
        }
        foreach ($comObject in @($range, $worksheet, $workbook, $excel)) {
            if ($comObject -ne $null -and [System.Runtime.InteropServices.Marshal]::IsComObject($comObject)) {
                [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($comObject)
            }
        }
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
    }
}

function Export-RaidAudit {
    param(
        [string]$Text,
        [string]$Directory
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
    $baseName = "AntiInspector_$timestamp"
    $tsvPath = Join-Path $Directory ($baseName + '.tsv')
    $latestTsvPath = Join-Path $Directory 'AntiInspector_latest.tsv'

    Write-Utf8Tsv -Text $Text -Path $tsvPath
    try {
        Write-Utf8Tsv -Text $Text -Path $latestTsvPath
    } catch {
        Write-Warning "latest.tsv is probably open in Excel. Timestamped TSV was still created."
    }

    Write-Host "TSV:  $tsvPath" -ForegroundColor Green

    if (-not $NoExcel) {
        $xlsxPath = Join-Path $Directory ($baseName + '.xlsx')
        if (Convert-TsvToXlsx -Text $Text -Path $xlsxPath) {
            Write-Host "XLSX: $xlsxPath" -ForegroundColor Green
            $latestXlsxPath = Join-Path $Directory 'AntiInspector_latest.xlsx'
            try {
                [System.IO.File]::Copy($xlsxPath, $latestXlsxPath, $true)
            } catch {
                Write-Warning "latest.xlsx is probably open in Excel. Timestamped XLSX was still created."
            }
        }
    }
}

$resolvedOutputDirectory = Initialize-OutputDirectory -RequestedDirectory $OutputDirectory
Write-Host 'AntiInspector - Excel bridge' -ForegroundColor Cyan
Write-Host "Output: $resolvedOutputDirectory"
if ($InputFile) {
    Write-Host "Reading test/input file: $InputFile"
} else {
    Write-Host 'Waiting for an /enchinsp export copied with Ctrl+C...'
    Write-Host 'Direct paste mode is active: the clipboard will be repaired for Excel automatically.' -ForegroundColor Yellow
    Write-Host 'Keep this window open. Press Ctrl+C here to stop the helper.'
}

do {
    try {
        if ($InputFile) {
            $clipboardText = [System.IO.File]::ReadAllText([System.IO.Path]::GetFullPath($InputFile))
        } else {
            $clipboardText = Get-Clipboard -Raw -ErrorAction Stop
        }

        if ($clipboardText -and $clipboardText.StartsWith($exportHeader, [System.StringComparison]::Ordinal)) {
            $originalClipboardText = $clipboardText
            $clipboardText = Repair-WowCyrillicEncoding -Text $clipboardText
            if (-not $InputFile -and $clipboardText -cne $originalClipboardText) {
                Set-UnicodeClipboardText -Text $clipboardText
                Write-Host 'Clipboard repaired: Ctrl+V into Excel will now preserve Cyrillic.' -ForegroundColor Green
            }
            $currentHash = Get-TextHash -Text $clipboardText
            if ($currentHash -ne $lastHash) {
                Export-RaidAudit -Text $clipboardText -Directory $resolvedOutputDirectory
                $lastHash = $currentHash
                $lastError = $null
                if (-not $Once -and -not $InputFile) {
                    Write-Host 'Waiting for the next copied raid export...'
                }
            }
        }
    } catch {
        $message = $_.Exception.Message
        if ($message -ne $lastError) {
            Write-Warning $message
            $lastError = $message
        }
    }

    if (-not $Once -and -not $InputFile) {
        Start-Sleep -Milliseconds 100
    }
} while (-not $Once -and -not $InputFile)
