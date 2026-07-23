$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.IO.Compression.FileSystem

$baseDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$docId = "SS-FICHA-LECTURA-ATLETA-CAMPO-V001"
$txtPath = Join-Path $baseDir "$docId.txt"
$htmlPath = Join-Path $baseDir "$docId.html"
$docxPath = Join-Path $baseDir "$docId.docx"
$tmpDir = Join-Path $baseDir "_docx_tmp_ficha_lectura_atleta_v001"

function Escape-Xml([string]$Text) {
  return [System.Security.SecurityElement]::Escape($Text)
}

function Escape-Html([string]$Text) {
  return [System.Net.WebUtility]::HtmlEncode($Text)
}

$sections = @(
  @{
    Title = "Datos de la sesión";
    Lines = @(
      "Atleta: ________________________________    Edad: ______",
      "Fecha: ____ / ____ / ______    Lugar: ________________________________",
      "Tipo de prueba: Piscina / Mar / Caminata / Laboratorio",
      "Código o modo usado: ________________________________",
      "Dispositivo: SS-LT-000001    Firmware: ________________________________",
      "Archivo CSV: ________________________________    Duración: ______ min"
    )
  },
  @{
    Title = "Resumen simple para el atleta";
    Lines = @(
      "Rotación: ________________________________________________",
      "Alineación corporal: ______________________________________",
      "Impulso: _________________________________________________",
      "Ritmo: ____________________________________________________",
      "Avance / ubicación: _______________________________________",
      "Tu mejor tramo fue entre el minuto ______ y ______ porque: ________________________________"
    )
  },
  @{
    Title = "Lectura Save Swimmer";
    Lines = @(
      "Qué vimos: ________________________________________________________________________________",
      "Qué puede significar: _____________________________________________________________________",
      "Qué conviene repetir en la próxima prueba: _________________________________________________",
      "Dato importante: esta lectura es técnica/deportiva experimental. No es diagnóstico médico ni reemplaza supervisión profesional."
    )
  },
  @{
    Title = "Métricas de referencia";
    Lines = @(
      "Rotación derecha promedio: ______°    Rotación izquierda promedio: ______°",
      "Diferencia derecha/izquierda: ______°    Clasificación: Baja / Correcta / Excesiva / Asimétrica",
      "Alineación promedio: ______°    Variación observada: Baja / Media / Alta",
      "Impulso promedio: ______    Picos de impulso: ______",
      "Ritmo promedio por ciclo: ______ s    Cantidad estimada de brazadas/ciclos: ______",
      "GPS inicial: ____________________    GPS final: ____________________    Distancia GPS: ______"
    )
  },
  @{
    Title = "Observación por tramo";
    Lines = @(
      "Inicio: ____________________________________________________________________________________",
      "Mitad: _____________________________________________________________________________________",
      "Final: _____________________________________________________________________________________",
      "Cambios detectados: ________________________________________________________________________"
    )
  },
  @{
    Title = "Seguridad y señal";
    Lines = @(
      "Tiempo con señal BLE: ______    Cortes BLE: ______",
      "GPS válido: Sí / Parcial / No    Tiempo hasta primer GPS: ______",
      "Registro microSD: Completo / Parcial / Error",
      "Observación de seguridad: _________________________________________________________________"
    )
  },
  @{
    Title = "Próxima acción";
    Lines = @(
      "Repetir misma prueba: Sí / No",
      "Cambiar técnica observada: ________________________________________________________________",
      "Nueva prueba sugerida: ____________________________________________________________________",
      "Firma atleta: __________________________    Firma responsable SS: __________________________"
    )
  }
)

$plain = New-Object System.Collections.Generic.List[string]
$plain.Add("SAVE SWIMMER")
$plain.Add("FICHA DE LECTURA PARA ATLETA - PRUEBA DE CAMPO")
$plain.Add("Versión: V001 | Fecha documento: 2026-07-08")
$plain.Add("")
$plain.Add("Objetivo: entregar una lectura simple de la sesión registrada por el prototipo Save Swimmer.")
$plain.Add("Uso: completar después de cargar el CSV o revisar la sesión desde la app.")
$plain.Add("")
foreach ($section in $sections) {
  $plain.Add($section.Title.ToUpperInvariant())
  foreach ($line in $section.Lines) { $plain.Add($line) }
  $plain.Add("")
}
[System.IO.File]::WriteAllLines($txtPath, $plain, [System.Text.UTF8Encoding]::new($true))

$sectionHtml = New-Object System.Text.StringBuilder
foreach ($section in $sections) {
  [void]$sectionHtml.AppendLine("<section class='card'>")
  [void]$sectionHtml.AppendLine("<h2>$(Escape-Html $section.Title)</h2>")
  foreach ($line in $section.Lines) {
    [void]$sectionHtml.AppendLine("<p>$(Escape-Html $line)</p>")
  }
  [void]$sectionHtml.AppendLine("</section>")
}

$html = @"
<!doctype html>
<html lang="es-PE">
<head>
  <meta charset="utf-8">
  <title>$docId</title>
  <style>
    :root { --dark:#071822; --cyan:#00c2e0; --orange:#ff6a00; --line:#b9c7ce; --text:#10212b; }
    * { box-sizing: border-box; }
    body { margin: 0; background: #eef4f6; color: var(--text); font-family: Calibri, Arial, sans-serif; }
    .page { width: 210mm; min-height: 297mm; margin: 0 auto; padding: 16mm; background: white; }
    header { border-bottom: 3px solid var(--cyan); padding-bottom: 10px; margin-bottom: 14px; }
    h1 { margin: 0; letter-spacing: 3px; font-size: 28px; color: var(--dark); }
    .subtitle { margin-top: 5px; font-size: 18px; font-weight: 700; color: var(--cyan); letter-spacing: 1px; }
    .meta { margin-top: 8px; color: #60737c; font-size: 12px; }
    .notice { border-left: 5px solid var(--orange); padding: 8px 12px; background: #fff7ef; margin: 12px 0; font-size: 13px; }
    .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; }
    .card { border: 1px solid var(--line); border-radius: 8px; padding: 10px 12px; break-inside: avoid; }
    .card h2 { margin: 0 0 8px; font-size: 16px; color: var(--dark); border-bottom: 1px solid #d8e3e8; padding-bottom: 5px; }
    .card p { margin: 6px 0; font-size: 12.5px; line-height: 1.25; }
    footer { margin-top: 16px; padding-top: 8px; border-top: 1px solid #d8e3e8; color: #60737c; font-size: 11px; display:flex; justify-content:space-between; }
    @media print { body { background:white; } .page { margin:0; width:auto; min-height:auto; } }
  </style>
</head>
<body>
  <main class="page">
    <header>
      <h1>SAVE SWIMMER</h1>
      <div class="subtitle">FICHA DE LECTURA PARA ATLETA</div>
      <div class="meta">Prueba de campo | Documento $docId | 2026-07-08</div>
    </header>
    <div class="notice">
      Esta ficha resume datos técnicos de movimiento, GPS y registro local para uso deportivo experimental. No es diagnóstico médico ni reemplaza supervisión profesional.
    </div>
    <div class="grid">
      $sectionHtml
    </div>
    <footer>
      <span>@saveswimmer | saveswimmer@gmail.com</span>
      <span>Probamos hoy para proteger mañana.</span>
    </footer>
  </main>
</body>
</html>
"@
[System.IO.File]::WriteAllText($htmlPath, $html, [System.Text.UTF8Encoding]::new($true))

if (Test-Path -LiteralPath $tmpDir) {
  Remove-Item -LiteralPath $tmpDir -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $tmpDir, (Join-Path $tmpDir "_rels"), (Join-Path $tmpDir "word"), (Join-Path $tmpDir "word\_rels"), (Join-Path $tmpDir "docProps") | Out-Null

function Add-ParagraphXml([System.Collections.Generic.List[string]]$Body, [string]$Text, [string]$Style = "Normal") {
  $safe = Escape-Xml $Text
  $Body.Add("<w:p><w:pPr><w:pStyle w:val=`"$Style`"/></w:pPr><w:r><w:t xml:space=`"preserve`">$safe</w:t></w:r></w:p>")
}

$body = New-Object System.Collections.Generic.List[string]
Add-ParagraphXml $body "SAVE SWIMMER" "Brand"
Add-ParagraphXml $body "FICHA DE LECTURA PARA ATLETA - PRUEBA DE CAMPO" "Title"
Add-ParagraphXml $body "Versión: V001 | Fecha documento: 2026-07-08" "Subtitle"
Add-ParagraphXml $body "Objetivo: entregar una lectura simple de la sesión registrada por el prototipo Save Swimmer." "Normal"
Add-ParagraphXml $body "Esta ficha es técnica/deportiva experimental. No es diagnóstico médico ni reemplaza supervisión profesional." "Warning"
Add-ParagraphXml $body "" "Normal"
foreach ($section in $sections) {
  Add-ParagraphXml $body $section.Title "Heading1"
  foreach ($line in $section.Lines) {
    Add-ParagraphXml $body $line "Normal"
  }
  Add-ParagraphXml $body "" "Normal"
}

$styles = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:lang w:val="es-PE"/><w:sz w:val="22"/></w:rPr><w:pPr><w:spacing w:after="90"/></w:pPr></w:style>
  <w:style w:type="paragraph" w:styleId="Brand"><w:name w:val="Brand"/><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:b/><w:sz w:val="38"/><w:color w:val="071822"/><w:lang w:val="es-PE"/></w:rPr><w:pPr><w:spacing w:after="40"/></w:pPr></w:style>
  <w:style w:type="paragraph" w:styleId="Title"><w:name w:val="Title"/><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:b/><w:sz w:val="28"/><w:color w:val="00A6C8"/><w:lang w:val="es-PE"/></w:rPr><w:pPr><w:spacing w:after="80"/></w:pPr></w:style>
  <w:style w:type="paragraph" w:styleId="Subtitle"><w:name w:val="Subtitle"/><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:sz w:val="20"/><w:color w:val="607D8B"/><w:lang w:val="es-PE"/></w:rPr><w:pPr><w:spacing w:after="180"/></w:pPr></w:style>
  <w:style w:type="paragraph" w:styleId="Heading1"><w:name w:val="Heading1"/><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:b/><w:sz w:val="24"/><w:color w:val="071822"/><w:lang w:val="es-PE"/></w:rPr><w:pPr><w:spacing w:before="100" w:after="60"/></w:pPr></w:style>
  <w:style w:type="paragraph" w:styleId="Warning"><w:name w:val="Warning"/><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:i/><w:sz w:val="20"/><w:color w:val="9A4A00"/><w:lang w:val="es-PE"/></w:rPr><w:pPr><w:spacing w:after="160"/></w:pPr></w:style>
</w:styles>
'@

$document = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body>' + ($body -join "`n") + '<w:sectPr><w:pgSz w:w="12240" w:h="15840"/><w:pgMar w:top="720" w:right="720" w:bottom="720" w:left="720" w:header="720" w:footer="720" w:gutter="0"/></w:sectPr></w:body></w:document>'
$utf8 = [System.Text.UTF8Encoding]::new($false)
[IO.File]::WriteAllText((Join-Path $tmpDir "[Content_Types].xml"), '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/><Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/><Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/><Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/></Types>', $utf8)
[IO.File]::WriteAllText((Join-Path $tmpDir "_rels\.rels"), '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/><Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/><Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/></Relationships>', $utf8)
[IO.File]::WriteAllText((Join-Path $tmpDir "word\_rels\document.xml.rels"), '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/></Relationships>', $utf8)
[IO.File]::WriteAllText((Join-Path $tmpDir "word\document.xml"), $document, $utf8)
[IO.File]::WriteAllText((Join-Path $tmpDir "word\styles.xml"), $styles, $utf8)
[IO.File]::WriteAllText((Join-Path $tmpDir "docProps\core.xml"), '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/"><dc:title>Save Swimmer - Ficha de lectura para atleta V001</dc:title><dc:creator>Save Swimmer</dc:creator></cp:coreProperties>', $utf8)
[IO.File]::WriteAllText((Join-Path $tmpDir "docProps\app.xml"), '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties"><Application>Save Swimmer</Application></Properties>', $utf8)

if (Test-Path -LiteralPath $docxPath) { Remove-Item -LiteralPath $docxPath -Force }
[System.IO.Compression.ZipFile]::CreateFromDirectory($tmpDir, $docxPath)
Remove-Item -LiteralPath $tmpDir -Recurse -Force

Write-Host "Generado:"
Write-Host $docxPath
Write-Host $htmlPath
Write-Host $txtPath

