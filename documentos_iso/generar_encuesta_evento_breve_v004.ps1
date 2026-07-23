$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.IO.Compression.FileSystem

$baseDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$output = Join-Path $baseDir "SS-ENCUESTA-BREVE-EVENTO-AGUAS-ABIERTAS-V004.docx"

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

function P($text, $style = "", $bold = $false, $size = 19) {
    $styleXml = if ($style) { "<w:pPr><w:pStyle w:val=""$style""/></w:pPr>" } else { "" }
    $boldXml = if ($bold) { "<w:b/>" } else { "" }
    return "<w:p>$styleXml<w:r><w:rPr>$boldXml<w:sz w:val=""$size""/></w:rPr><w:t xml:space=""preserve"">$(XmlText $text)</w:t></w:r></w:p>"
}

function Question($text) {
    return P $text "" $true 19
}

$body = New-Object System.Text.StringBuilder
[void]$body.Append((P "SAVE SWIMMER" "Title" $true 32))
[void]$body.Append((P "ENCUESTA BREVE - EVENTO DE AGUAS ABIERTAS" "Subtitle" $true 23))
[void]$body.Append((P "Save Swimmer es un prototipo dorsal en desarrollo para acompanamiento de seguridad temprana en aguas abiertas. No reemplaza rescate, salvavidas ni supervision humana. Tu respuesta toma menos de 2 minutos." "" $false 17))

[void]$body.Append((Question "1. Tu relacion principal con aguas abiertas:"))
[void]$body.Append((P "[ ] Nadador/a   [ ] Entrenador/a   [ ] Familiar   [ ] Organizador/a   [ ] Otro: __________________"))

[void]$body.Append((Question "2. Frecuencia aproximada:"))
[void]$body.Append((P "[ ] Primera vez   [ ] Ocasional   [ ] Mensual   [ ] Semanal   [ ] 2+ veces por semana"))

[void]$body.Append((Question "3. En un nado real, que te preocupa mas? Marca hasta 3."))
[void]$body.Append((P "[ ] Desorientacion   [ ] Corriente/oleaje   [ ] Quedar rezagado/a   [ ] No ser visible"))
[void]$body.Append((P "[ ] Inmovilidad/dificultad   [ ] Salir de zona segura   [ ] Nadie confirma mi regreso"))
[void]$body.Append((P "[ ] Emergencia medica   [ ] Perdida de senal/contacto   [ ] Otra: __________________"))

[void]$body.Append((Question "4. Que informacion deberia ver tu contacto/familia durante la sesion? Marca hasta 3."))
[void]$body.Append((P "[ ] Ubicacion aproximada   [ ] Ultima senal recibida   [ ] Ruta/mapa simple"))
[void]$body.Append((P "[ ] Salida de zona segura   [ ] Detenido/sin avance   [ ] Confirmacion de salida del agua"))
[void]$body.Append((P "[ ] Boton/SOS manual   [ ] Estado de bateria/senal   [ ] Otra: __________________"))

[void]$body.Append((Question "5. Si entrenas, que beneficio tecnico te interesaria para uso diario? Marca hasta 2."))
[void]$body.Append((P "[ ] Ritmo/regularidad   [ ] Simetria corporal   [ ] Cambios por fatiga"))
[void]$body.Append((P "[ ] Resumen para entrenador   [ ] Comparar sesiones   [ ] No me interesa la parte tecnica"))

[void]$body.Append((Question "6. Usarias un dispositivo dorsal pequeno si no molesta al nadar?"))
[void]$body.Append((P "[ ] Si   [ ] Tal vez   [ ] No"))
[void]$body.Append((P "Lo que mas condiciona mi respuesta es: [ ] comodidad [ ] tamano/peso [ ] sujecion [ ] privacidad [ ] falsas alertas [ ] precio"))

[void]$body.Append((Question "7. Modelo de pago que te pareceria razonable si incluye app de atleta y contacto familiar activo:"))
[void]$body.Append((P "Dispositivo una vez: [ ] S/299   [ ] S/399   [ ] S/499   [ ] S/599   [ ] No compraria"))
[void]$body.Append((P "Membresia mensual: [ ] S/29   [ ] S/39   [ ] S/49   [ ] S/69   [ ] No pagaria mensual"))

[void]$body.Append((Question "8. Quien deberia recibir una alerta en una sesion normal?"))
[void]$body.Append((P "[ ] Familiar/contacto de emergencia   [ ] Entrenador solo si autorizo   [ ] Organizador/rescate en evento"))
[void]$body.Append((P "[ ] Nadie, solo yo   [ ] Otro: __________________"))

[void]$body.Append((Question "9. En una frase: que tendria que lograr Save Swimmer para que lo recomiendes?"))
[void]$body.Append((P "________________________________________________________________________________"))
[void]$body.Append((P "________________________________________________________________________________"))

[void]$body.Append((P "Contacto opcional para recibir avances o participar en pruebas tecnicas:" "" $true 18))
[void]$body.Append((P "Nombre: __________________________  WhatsApp/correo: __________________________"))
[void]$body.Append((P "[ ] Autorizo que Save Swimmer me contacte sobre avances y pruebas. Puedo solicitar dejar de recibir mensajes." "" $false 15))
[void]$body.Append((P "Instagram/TikTok/Facebook: @saveswimmer   |   saveswimmer@gmail.com" "" $true 15))

$documentXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    $body
    <w:sectPr>
      <w:pgSz w:w="11906" w:h="16838"/>
      <w:pgMar w:top="500" w:right="620" w:bottom="500" w:left="620" w:header="250" w:footer="250" w:gutter="0"/>
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
    <w:rPr><w:rFonts w:ascii="Arial" w:hAnsi="Arial"/><w:sz w:val="19"/></w:rPr>
    <w:pPr><w:spacing w:after="42" w:line="215" w:lineRule="auto"/></w:pPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Title">
    <w:name w:val="Title"/>
    <w:rPr><w:rFonts w:ascii="Arial" w:hAnsi="Arial"/><w:b/><w:color w:val="00A7C7"/><w:sz w:val="32"/></w:rPr>
    <w:pPr><w:spacing w:after="8"/></w:pPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Subtitle">
    <w:name w:val="Subtitle"/>
    <w:rPr><w:rFonts w:ascii="Arial" w:hAnsi="Arial"/><w:b/><w:sz w:val="23"/></w:rPr>
    <w:pPr><w:spacing w:after="58"/></w:pPr>
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
