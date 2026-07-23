$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.IO.Compression.FileSystem

$baseDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$output = Join-Path $baseDir "SS-ENCUESTA-BREVE-EVENTO-AGUAS-ABIERTAS-V003.docx"

function XmlText($value) {
    if ($null -eq $value) { return "" }
    $s = [string]$value
    $s = $s -replace "[\x00-\x08\x0B\x0C\x0E-\x1F]", ""
    return [System.Security.SecurityElement]::Escape($s)
}

function WriteText($path, $content) {
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($path, $content, $utf8)
}

function P($text, $style = "", $bold = $false, $size = 20) {
    $styleXml = if ($style) { "<w:pPr><w:pStyle w:val=""$style""/></w:pPr>" } else { "" }
    $boldXml = if ($bold) { "<w:b/>" } else { "" }
    return "<w:p>$styleXml<w:r><w:rPr>$boldXml<w:sz w:val=""$size""/></w:rPr><w:t xml:space=""preserve"">$(XmlText $text)</w:t></w:r></w:p>"
}

function Question($text) {
    return P $text "" $true 20
}

$body = New-Object System.Text.StringBuilder
[void]$body.Append((P "SAVE SWIMMER" "Title" $true 32))
[void]$body.Append((P "ENCUESTA BREVE - AGUAS ABIERTAS" "Subtitle" $true 24))
[void]$body.Append((P "Save Swimmer es un prototipo dorsal en desarrollo para apoyar la seguridad de nadadores de aguas abiertas. Queremos conocer tu experiencia. Completarla toma menos de 2 minutos." "" $false 18))

[void]$body.Append((Question "1. Tu relacion con aguas abiertas:"))
[void]$body.Append((P "[ ] Nadador/a   [ ] Entrenador/a   [ ] Organizador/a   [ ] Familiar   [ ] Otro: __________________"))

[void]$body.Append((Question "2. ¿Con que frecuencia participas o entrenas en aguas abiertas?"))
[void]$body.Append((P "[ ] Primera vez   [ ] Ocasionalmente   [ ] Mensualmente   [ ] Semanalmente"))

[void]$body.Append((Question "3. ¿Que situaciones te preocupan mas? Marca hasta 3."))
[void]$body.Append((P "[ ] Desorientacion   [ ] Corriente/oleaje   [ ] Quedar rezagado/a"))
[void]$body.Append((P "[ ] No ser visible   [ ] Inmovilidad o dificultad   [ ] Salir lejos del punto esperado"))
[void]$body.Append((P "[ ] Que nadie confirme mi regreso   [ ] Otra: __________________________"))

[void]$body.Append((Question "4. ¿Que informacion seria mas util durante un nado? Marca hasta 3."))
[void]$body.Append((P "[ ] Ubicacion aproximada   [ ] Movimiento / sin movimiento   [ ] Distancia a la costa/base"))
[void]$body.Append((P "[ ] Salida de zona segura   [ ] Tiempo transcurrido   [ ] Confirmacion de salida del agua"))
[void]$body.Append((P "[ ] Alerta al entrenador/familia   [ ] Otra: __________________________"))

[void]$body.Append((Question "5. ¿Usarias un dispositivo dorsal pequeno durante el nado?"))
[void]$body.Append((P "[ ] Si   [ ] Tal vez   [ ] No"))
[void]$body.Append((P "Lo mas importante para usarlo seria: __________________________________________"))

[void]$body.Append((Question "6. ¿Que podria hacer que no lo uses?"))
[void]$body.Append((P "[ ] Incomodidad   [ ] Tamano/peso   [ ] Precio   [ ] Privacidad   [ ] Falsas alertas   [ ] Otro: __________"))

[void]$body.Append((Question "7. ¿Que problema de seguridad en aguas abiertas te gustaria que una herramienta como esta ayudara a resolver?"))
[void]$body.Append((P "________________________________________________________________________________"))
[void]$body.Append((P "________________________________________________________________________________"))

[void]$body.Append((P "Contacto opcional para recibir avances o participar en pruebas:" "" $true 19))
[void]$body.Append((P "Nombre: ______________________________  WhatsApp/correo: ______________________________"))
[void]$body.Append((P "[ ] Autorizo que Save Swimmer me contacte sobre avances y pruebas. Puedo solicitar dejar de recibir mensajes." "" $false 16))
[void]$body.Append((P "Instagram/TikTok/Facebook: @saveswimmer   |   saveswimmer@gmail.com" "" $true 16))

$documentXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    $body
    <w:sectPr>
      <w:pgSz w:w="11906" w:h="16838"/>
      <w:pgMar w:top="650" w:right="700" w:bottom="650" w:left="700" w:header="300" w:footer="300" w:gutter="0"/>
    </w:sectPr>
  </w:body>
</w:document>
"@

$contentTypes = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
</Types>
"@

$rels = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>
"@

$documentRels = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"/>
"@

$styles = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:style w:type="paragraph" w:default="1" w:styleId="Normal">
    <w:name w:val="Normal"/>
    <w:rPr><w:rFonts w:ascii="Arial" w:hAnsi="Arial"/><w:sz w:val="20"/></w:rPr>
    <w:pPr><w:spacing w:after="55" w:line="230" w:lineRule="auto"/></w:pPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Title">
    <w:name w:val="Title"/>
    <w:rPr><w:rFonts w:ascii="Arial" w:hAnsi="Arial"/><w:b/><w:color w:val="00A7C7"/><w:sz w:val="32"/></w:rPr>
    <w:pPr><w:spacing w:after="20"/></w:pPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Subtitle">
    <w:name w:val="Subtitle"/>
    <w:rPr><w:rFonts w:ascii="Arial" w:hAnsi="Arial"/><w:b/><w:sz w:val="24"/></w:rPr>
    <w:pPr><w:spacing w:after="90"/></w:pPr>
  </w:style>
</w:styles>
"@

$temp = Join-Path $env:TEMP ("ss_encuesta_" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $temp | Out-Null
New-Item -ItemType Directory -Path (Join-Path $temp "_rels") | Out-Null
New-Item -ItemType Directory -Path (Join-Path $temp "word") | Out-Null
New-Item -ItemType Directory -Path (Join-Path $temp "word\_rels") | Out-Null

WriteText (Join-Path $temp "[Content_Types].xml") $contentTypes
WriteText (Join-Path $temp "_rels\.rels") $rels
WriteText (Join-Path $temp "word\document.xml") $documentXml
WriteText (Join-Path $temp "word\styles.xml") $styles
WriteText (Join-Path $temp "word\_rels\document.xml.rels") $documentRels

if (Test-Path $output) { Remove-Item -LiteralPath $output -Force }
[System.IO.Compression.ZipFile]::CreateFromDirectory($temp, $output)
Remove-Item -LiteralPath $temp -Recurse -Force

Write-Output "Creado: $output"
