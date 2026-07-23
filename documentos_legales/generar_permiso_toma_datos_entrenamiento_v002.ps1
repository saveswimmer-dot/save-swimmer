$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.IO.Compression.FileSystem

$base = Join-Path $PSScriptRoot "_docx_tmp_permiso_datos_v002"
$outputDocx = Join-Path $PSScriptRoot "SS-FRM-PERMISO-TOMA-DATOS-ENTRENAMIENTO-V002.docx"
$sourceTxt = Join-Path $PSScriptRoot "SS-FRM-PERMISO-TOMA-DATOS-ENTRENAMIENTO-V002.txt"
$workspace = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$resolvedBase = [System.IO.Path]::GetFullPath($base)

if (-not $resolvedBase.StartsWith($workspace, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Ruta temporal fuera del workspace."
}
if (Test-Path -LiteralPath $base) {
    Remove-Item -LiteralPath $base -Recurse -Force
}

New-Item -ItemType Directory -Force -Path $base, (Join-Path $base "_rels"), (Join-Path $base "word"), (Join-Path $base "word\_rels") | Out-Null

function XmlText([string]$text) {
    return [System.Security.SecurityElement]::Escape($text)
}

function AddParagraph([System.Collections.Generic.List[string]]$body, [string]$text, [string]$style = "Normal") {
    $safe = XmlText $text
    $body.Add("<w:p><w:pPr><w:pStyle w:val=`"$style`"/></w:pPr><w:r><w:t xml:space=`"preserve`">$safe</w:t></w:r></w:p>")
}

$body = New-Object System.Collections.Generic.List[string]
$lines = Get-Content -LiteralPath $sourceTxt -Encoding UTF8

foreach ($line in $lines) {
    if ($line -eq "SAVE SWIMMER") {
        AddParagraph $body $line "Brand"
    } elseif ($line -match "^PERMISO,") {
        AddParagraph $body $line "Title"
    } elseif ($line -match "^[0-9]+\. " -or $line -eq "REGLA OPERATIVA") {
        AddParagraph $body $line "Heading1"
    } elseif ($line -match "^\[ \]" -or $line -match "^- ") {
        AddParagraph $body $line "Check"
    } elseif ([string]::IsNullOrWhiteSpace($line)) {
        AddParagraph $body "" "Normal"
    } else {
        AddParagraph $body $line "Normal"
    }
}

$styles = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:sz w:val="22"/></w:rPr><w:pPr><w:spacing w:after="110"/></w:pPr></w:style>
  <w:style w:type="paragraph" w:styleId="Brand"><w:name w:val="Brand"/><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:b/><w:sz w:val="34"/><w:color w:val="0A2A36"/></w:rPr><w:pPr><w:jc w:val="center"/><w:spacing w:after="80"/></w:pPr></w:style>
  <w:style w:type="paragraph" w:styleId="Title"><w:name w:val="Title"/><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:b/><w:sz w:val="27"/><w:color w:val="00A6C8"/></w:rPr><w:pPr><w:jc w:val="center"/><w:spacing w:after="180"/></w:pPr></w:style>
  <w:style w:type="paragraph" w:styleId="Heading1"><w:name w:val="Heading 1"/><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:b/><w:sz w:val="25"/><w:color w:val="083044"/></w:rPr><w:pPr><w:spacing w:before="180" w:after="80"/></w:pPr></w:style>
  <w:style w:type="paragraph" w:styleId="Check"><w:name w:val="Check"/><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:sz w:val="22"/></w:rPr><w:pPr><w:spacing w:after="60"/></w:pPr></w:style>
</w:styles>
'@

$document = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body>' + ($body -join "`n") + '<w:sectPr><w:pgSz w:w="12240" w:h="15840"/><w:pgMar w:top="900" w:right="900" w:bottom="900" w:left="900" w:header="720" w:footer="720" w:gutter="0"/></w:sectPr></w:body></w:document>'

$utf8 = New-Object System.Text.UTF8Encoding($false)
[IO.File]::WriteAllText((Join-Path $base "[Content_Types].xml"), '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/><Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/></Types>', $utf8)
[IO.File]::WriteAllText((Join-Path $base "_rels\.rels"), '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/></Relationships>', $utf8)
[IO.File]::WriteAllText((Join-Path $base "word\_rels\document.xml.rels"), '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/></Relationships>', $utf8)
[IO.File]::WriteAllText((Join-Path $base "word\document.xml"), $document, $utf8)
[IO.File]::WriteAllText((Join-Path $base "word\styles.xml"), $styles, $utf8)

if (Test-Path -LiteralPath $outputDocx) {
    try {
        Remove-Item -LiteralPath $outputDocx -Force
    } catch {
        $outputDocx = Join-Path $PSScriptRoot "SS-FRM-PERMISO-TOMA-DATOS-ENTRENAMIENTO-V002-20SESIONES.docx"
        if (Test-Path -LiteralPath $outputDocx) {
            Remove-Item -LiteralPath $outputDocx -Force
        }
    }
}
[System.IO.Compression.ZipFile]::CreateFromDirectory($base, $outputDocx)
Remove-Item -LiteralPath $base -Recurse -Force

Write-Host "Creado: $outputDocx"
