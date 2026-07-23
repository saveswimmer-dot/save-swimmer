$ErrorActionPreference = "Stop"
$src = Join-Path $PSScriptRoot "SS-PCB-LITE-CONCEPT-V001.csv"
$dst = Join-Path $PSScriptRoot "SS-PCB-LITE-CONCEPT-V001.xlsx"

Add-Type -AssemblyName System.IO.Compression.FileSystem

function XmlText($value) {
    if ($null -eq $value) { return "" }
    $s = [string]$value
    $s = $s -replace "[\x00-\x08\x0B\x0C\x0E-\x1F]", ""
    return [System.Security.SecurityElement]::Escape($s)
}

function ColumnName([int]$index) {
    $name = ""
    while ($index -gt 0) {
        $mod = ($index - 1) % 26
        $name = [char](65 + $mod) + $name
        $index = [math]::Floor(($index - 1) / 26)
    }
    return $name
}

function WriteText($path, $content) {
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($path, $content, $utf8)
}

$rows = @(Import-Csv -Path $src -Delimiter "," -Encoding UTF8)
$headers = @($rows[0].PSObject.Properties.Name)
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("ss_hw_xlsx_" + [guid]::NewGuid().ToString("N"))
$xlDir = Join-Path $tempRoot "xl"
$relsDir = Join-Path $tempRoot "_rels"
$xlRelsDir = Join-Path $xlDir "_rels"
$wsDir = Join-Path $xlDir "worksheets"
New-Item -ItemType Directory -Force -Path $relsDir, $xlRelsDir, $wsDir | Out-Null

$lastCol = ColumnName $headers.Count
$lastRow = $rows.Count + 1
$range = "A1:$lastCol$lastRow"

$sheetData = New-Object System.Text.StringBuilder
[void]$sheetData.Append("<row r=""1"">")
for ($c = 0; $c -lt $headers.Count; $c++) {
    $ref = (ColumnName ($c + 1)) + "1"
    [void]$sheetData.Append("<c r=""$ref"" t=""inlineStr"" s=""1""><is><t>")
    [void]$sheetData.Append((XmlText $headers[$c]))
    [void]$sheetData.Append("</t></is></c>")
}
[void]$sheetData.Append("</row>")

$rIndex = 2
foreach ($row in $rows) {
    [void]$sheetData.Append("<row r=""$rIndex"">")
    for ($c = 0; $c -lt $headers.Count; $c++) {
        $ref = (ColumnName ($c + 1)) + $rIndex
        [void]$sheetData.Append("<c r=""$ref"" t=""inlineStr""><is><t>")
        [void]$sheetData.Append((XmlText $row.($headers[$c])))
        [void]$sheetData.Append("</t></is></c>")
    }
    [void]$sheetData.Append("</row>")
    $rIndex++
}

WriteText (Join-Path $tempRoot "[Content_Types].xml") @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
  <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
</Types>
"@
WriteText (Join-Path $relsDir ".rels") @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>
"@
WriteText (Join-Path $xlRelsDir "workbook.xml.rels") @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>
"@
WriteText (Join-Path $xlDir "workbook.xml") @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheets><sheet name="PCB Lite Concept V001" sheetId="1" r:id="rId1"/></sheets>
</workbook>
"@
WriteText (Join-Path $xlDir "styles.xml") @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <fonts count="2"><font><sz val="11"/><name val="Calibri"/></font><font><b/><sz val="11"/><name val="Calibri"/></font></fonts>
  <fills count="2"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill></fills>
  <borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>
  <cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
  <cellXfs count="2"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/><xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0"/></cellXfs>
</styleSheet>
"@
WriteText (Join-Path $wsDir "sheet1.xml") @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <sheetViews><sheetView workbookViewId="0"><pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews>
  <cols><col min="1" max="7" width="32" customWidth="1"/></cols>
  <sheetData>$sheetData</sheetData>
  <autoFilter ref="$range"/>
</worksheet>
"@

if (Test-Path $dst) { Remove-Item -LiteralPath $dst -Force }
[System.IO.Compression.ZipFile]::CreateFromDirectory($tempRoot, $dst)
Remove-Item -LiteralPath $tempRoot -Recurse -Force
Write-Host "Creado: $dst"
