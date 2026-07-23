$ErrorActionPreference = "Stop"

$baseDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$mdPath = Join-Path $baseDir "SS-DIAGRAMA-CONEXION-PROTOTIPO-V001.md"
$txtPath = Join-Path $baseDir "SS-DIAGRAMA-CONEXION-PROTOTIPO-V001.txt"
$docxPath = Join-Path $baseDir "SS-DIAGRAMA-CONEXION-PROTOTIPO-V001.docx"
$tmpDir = Join-Path $baseDir "_docx_tmp_diagrama_conexion"

if (!(Test-Path $mdPath)) {
  throw "No existe el archivo fuente: $mdPath"
}

Copy-Item -LiteralPath $mdPath -Destination $txtPath -Force

if (Test-Path $tmpDir) {
  Remove-Item -LiteralPath $tmpDir -Recurse -Force
}

New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $tmpDir "_rels") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $tmpDir "word") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $tmpDir "word\_rels") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $tmpDir "docProps") | Out-Null

function Escape-XmlText {
  param([string]$Text)
  return [System.Security.SecurityElement]::Escape($Text)
}

function Clean-Line {
  param([string]$Line)
  $clean = $Line
  $clean = $clean -replace '^#{1,6}\s*', ''
  $clean = $clean -replace '^\s*-\s+', '- '
  $clean = $clean -replace '^\s*\|\s*', '| '
  $clean = $clean -replace '\*\*', ''
  $clean = $clean -replace [char]96, ''
  return $clean
}

$lines = Get-Content -LiteralPath $mdPath -Encoding UTF8
$body = New-Object System.Text.StringBuilder
$inCode = $false

foreach ($line in $lines) {
  if ($line.Trim().StartsWith('```')) {
    $inCode = -not $inCode
    continue
  }

  $text = if ($inCode) { $line } else { Clean-Line $line }

  if ([string]::IsNullOrWhiteSpace($text)) {
    [void]$body.AppendLine('<w:p/>')
    continue
  }

  $style = ""
  if ($line -match '^# ') {
    $style = '<w:pPr><w:pStyle w:val="Title"/></w:pPr>'
  } elseif ($line -match '^## ') {
    $style = '<w:pPr><w:pStyle w:val="Heading1"/></w:pPr>'
  } elseif ($line -match '^### ') {
    $style = '<w:pPr><w:pStyle w:val="Heading2"/></w:pPr>'
  }

  $runPr = ""
  if ($inCode -or $line -match '^\s*\|') {
    $runPr = '<w:rPr><w:rFonts w:ascii="Consolas" w:hAnsi="Consolas"/><w:sz w:val="18"/></w:rPr>'
  }

  $escapedText = Escape-XmlText -Text $text
  [void]$body.AppendLine('<w:p>' + $style + '<w:r>' + $runPr + '<w:t xml:space="preserve">' + $escapedText + '</w:t></w:r></w:p>')
}

$documentXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:wpc="http://schemas.microsoft.com/office/word/2010/wordprocessingCanvas" xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:wp14="http://schemas.microsoft.com/office/word/2010/wordprocessingDrawing" xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" xmlns:w10="urn:schemas-microsoft-com:office:word" xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:w14="http://schemas.microsoft.com/office/word/2010/wordml" xmlns:w15="http://schemas.microsoft.com/office/word/2012/wordml" mc:Ignorable="w14 w15 wp14">
  <w:body>
$body
    <w:sectPr>
      <w:pgSz w:w="12240" w:h="15840"/>
      <w:pgMar w:top="720" w:right="720" w:bottom="720" w:left="720" w:header="720" w:footer="720" w:gutter="0"/>
    </w:sectPr>
  </w:body>
</w:document>
"@

$stylesXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:style w:type="paragraph" w:styleId="Normal"><w:name w:val="Normal"/></w:style>
  <w:style w:type="paragraph" w:styleId="Title"><w:name w:val="Title"/><w:basedOn w:val="Normal"/><w:rPr><w:b/><w:sz w:val="32"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="Heading1"><w:name w:val="heading 1"/><w:basedOn w:val="Normal"/><w:rPr><w:b/><w:sz w:val="26"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="Heading2"><w:name w:val="heading 2"/><w:basedOn w:val="Normal"/><w:rPr><w:b/><w:sz w:val="22"/></w:rPr></w:style>
</w:styles>
"@

$contentTypesXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
  <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
</Types>
"@

$relsXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>
"@

$wordRelsXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>
"@

$coreXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <dc:title>Save Swimmer - Diagrama de conexion prototipo V001</dc:title>
  <dc:creator>Save Swimmer</dc:creator>
  <cp:lastModifiedBy>Save Swimmer</cp:lastModifiedBy>
</cp:coreProperties>
"@

$appXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">
  <Application>Save Swimmer</Application>
</Properties>
"@

Set-Content -LiteralPath (Join-Path $tmpDir "[Content_Types].xml") -Value $contentTypesXml -Encoding UTF8
Set-Content -LiteralPath (Join-Path $tmpDir "_rels\.rels") -Value $relsXml -Encoding UTF8
Set-Content -LiteralPath (Join-Path $tmpDir "word\document.xml") -Value $documentXml -Encoding UTF8
Set-Content -LiteralPath (Join-Path $tmpDir "word\styles.xml") -Value $stylesXml -Encoding UTF8
Set-Content -LiteralPath (Join-Path $tmpDir "word\_rels\document.xml.rels") -Value $wordRelsXml -Encoding UTF8
Set-Content -LiteralPath (Join-Path $tmpDir "docProps\core.xml") -Value $coreXml -Encoding UTF8
Set-Content -LiteralPath (Join-Path $tmpDir "docProps\app.xml") -Value $appXml -Encoding UTF8

if (Test-Path $docxPath) {
  Remove-Item -LiteralPath $docxPath -Force
}

$zipPath = "$docxPath.zip"
if (Test-Path $zipPath) {
  Remove-Item -LiteralPath $zipPath -Force
}

Compress-Archive -Path (Join-Path $tmpDir "*") -DestinationPath $zipPath -Force
Move-Item -LiteralPath $zipPath -Destination $docxPath -Force
Remove-Item -LiteralPath $tmpDir -Recurse -Force

Write-Host "Generado:"
Write-Host $docxPath
Write-Host $txtPath
