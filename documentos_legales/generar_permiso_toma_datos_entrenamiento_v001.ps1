$ErrorActionPreference = "Stop"

$base = Join-Path $PSScriptRoot "_docx_tmp_permiso_datos_v001"
$outputDocx = Join-Path $PSScriptRoot "SS-FRM-PERMISO-TOMA-DATOS-ENTRENAMIENTO-V001.docx"
$outputTxt = Join-Path $PSScriptRoot "SS-FRM-PERMISO-TOMA-DATOS-ENTRENAMIENTO-V001.txt"
$outputCsv = Join-Path $PSScriptRoot "SS-GUIA-CODIGOS-PRUEBA-ENTRENAMIENTO-V001.csv"
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

$body = New-Object System.Collections.Generic.List[string]

function Add-Paragraph([string]$text, [string]$style = "Normal", [string]$align = "") {
    $alignXml = if ($align) { "<w:jc w:val=`"$align`"/>" } else { "" }
    $safe = XmlText $text
    $body.Add("<w:p><w:pPr><w:pStyle w:val=`"$style`"/>$alignXml</w:pPr><w:r><w:t xml:space=`"preserve`">$safe</w:t></w:r></w:p>")
}

function Add-Check([string]$text) {
    Add-Paragraph "[ ] $text" "Check"
}

function Cell([string]$text, [int]$width = 4500, [bool]$header = $false) {
    $shade = if ($header) { '<w:shd w:fill="083044"/>' } else { '' }
    $color = if ($header) { '<w:color w:val="FFFFFF"/><w:b/>' } else { '' }
    $safe = XmlText $text
    return "<w:tc><w:tcPr><w:tcW w:w=`"$width`" w:type=`"dxa`"/>$shade</w:tcPr><w:p><w:r><w:rPr>$color</w:rPr><w:t xml:space=`"preserve`">$safe</w:t></w:r></w:p></w:tc>"
}

function Add-Table([array]$rows, [array]$widths, [bool]$firstHeader = $false) {
    $table = '<w:tbl><w:tblPr><w:tblW w:w="0" w:type="auto"/><w:tblBorders><w:top w:val="single" w:sz="6" w:space="0" w:color="9CB8C1"/><w:left w:val="single" w:sz="6" w:space="0" w:color="9CB8C1"/><w:bottom w:val="single" w:sz="6" w:space="0" w:color="9CB8C1"/><w:right w:val="single" w:sz="6" w:space="0" w:color="9CB8C1"/><w:insideH w:val="single" w:sz="4" w:space="0" w:color="D1E0E4"/><w:insideV w:val="single" w:sz="4" w:space="0" w:color="D1E0E4"/></w:tblBorders></w:tblPr>'
    for ($r = 0; $r -lt $rows.Count; $r++) {
        $table += '<w:tr>'
        for ($c = 0; $c -lt $rows[$r].Count; $c++) {
            $table += Cell ([string]$rows[$r][$c]) $widths[$c] ($firstHeader -and $r -eq 0)
        }
        $table += '</w:tr>'
    }
    $table += '</w:tbl>'
    $body.Add($table)
    Add-Paragraph "" "Normal"
}

Add-Paragraph "SAVE SWIMMER" "Brand" "center"
Add-Paragraph "PERMISO, CONFIDENCIALIDAD Y AUTORIZACION PARA TOMA DE DATOS" "Title" "center"
Add-Paragraph "Plan de entrenamiento, calibracion y pruebas de prototipo" "Subtitle" "center"

Add-Table @(
    @("Codigo", "SS-FRM-DATOS-ENTRENAMIENTO-001", "Version", "V001"),
    @("Fecha", "29/06/2026", "Estado", "Borrador operativo"),
    @("Proyecto", "Save Swimmer", "Responsable", "Victor Loza"),
    @("Contacto", "saveswimmer@gmail.com", "Telefono", "903 338 442")
) @(1700, 3200, 1600, 3000)

Add-Paragraph "NOTA IMPORTANTE" "Warning"
Add-Paragraph "Este documento ordena pruebas de investigacion y desarrollo. No reemplaza asesoria legal, protocolo medico, salvavidas, entrenador, supervision ni autorizaciones del lugar. Para pruebas con menores de edad, pruebas masivas, competencias, aguas abiertas o uso comercial, debe validarse con asesoria legal y un protocolo de seguridad especifico." "Normal"

Add-Paragraph "1. Participante" "Heading1"
Add-Table @(
    @("Nombre completo", "_______________________________________________"),
    @("DNI / CE / Pasaporte", "________________________", "Edad", "________"),
    @("Telefono / correo", "_______________________________________________"),
    @("Contacto emergencia", "________________________", "Telefono", "________________")
) @(2500, 2800, 1500, 2400)
Add-Paragraph "Si el participante es menor de edad, completa y firma el padre, madre o apoderado legal." "Normal"
Add-Table @(
    @("Nombre apoderado", "_______________________________________________"),
    @("DNI / CE", "________________________", "Vinculo", "________________")
) @(2500, 2800, 1500, 2400)

Add-Paragraph "2. Objeto del permiso" "Heading1"
Add-Paragraph "El participante autoriza a Save Swimmer a realizar una toma de datos asociada a una sesion de prueba, entrenamiento, calibracion o validacion tecnica del prototipo. La finalidad es mejorar la lectura de movimiento, rotacion dorsal, ritmo, impulso aparente, conectividad, GPS, energia y comportamiento del dispositivo en condiciones reales o controladas." "Normal"
Add-Paragraph "Cada prueba debe abrirse y cerrarse como sesion independiente. La regla de trabajo es: un codigo = una sesion = un archivo." "Normal"

Add-Paragraph "3. Modalidad de prueba" "Heading1"
Add-Paragraph "Marcar lo que corresponda:" "Normal"
Add-Check "QSEC: quieto seco con dispositivo colocado, antes de nadar."
Add-Check "QAGU: quieto en agua, flotando o sin avanzar."
Add-Check "BASE: nado natural del participante."
Add-Check "PRUEBA TECNICA: rotacion, mano y patada segun codigo."
Add-Check "CAMPO/GPS: prueba de ubicacion, mapa, comunicacion o bateria."
Add-Check "OTRO: ____________________________________________________________"
Add-Paragraph "Entorno: [ ] Piscina   [ ] Mar   [ ] Tierra   [ ] Otro: ____________________" "Normal"
Add-Paragraph "Lugar: ______________________________ Fecha: ____ / ____ / ______ Hora: ________" "Normal"

Add-Paragraph "4. Datos que pueden ser registrados" "Heading1"
Add-Table @(
    @("Categoria", "Ejemplos", "Uso previsto"),
    @("Datos de participante", "Nombre/codigo, edad, altura, peso si se declara", "Ordenar sesiones y comparar datos"),
    @("Datos de prueba", "Codigo, entorno, observaciones, duracion", "Trazabilidad de cada archivo"),
    @("Movimiento", "LR, FB, UD, MAG, pitch, roll, patrones de rotacion", "Analisis tecnico y calibracion"),
    @("Energia", "Voltaje, corriente, potencia, bateria estimada", "Autonomia y estabilidad"),
    @("Ubicacion", "GPS, ruta, distancia, calidad de fix si aplica", "Pruebas de mapa y comunicacion"),
    @("Imagen/video", "Grabacion de apoyo si se autoriza", "Contrastar datos contra movimiento real")
) @(2100, 3600, 3500) $true

Add-Paragraph "5. Confidencialidad" "Heading1"
Add-Paragraph "El participante se compromete a no divulgar detalles tecnicos no publicos del prototipo, firmware, software, funcionamiento interno, fallas, resultados de prueba, diseno, conexiones, pantallas internas o metodologia, salvo autorizacion expresa de Save Swimmer." "Normal"
Add-Paragraph "Save Swimmer se compromete a usar los datos de prueba para investigacion, desarrollo, validacion tecnica, mejora de producto y documentacion interna. Si se publican resultados, se procurara hacerlo en forma resumida o anonimizada, salvo autorizacion especifica." "Normal"

Add-Paragraph "6. Autorizaciones opcionales" "Heading1"
Add-Check "Autorizo uso interno de mis datos tecnicos para analisis y desarrollo."
Add-Check "Autorizo uso de imagen/video solo para analisis tecnico interno."
Add-Check "Autorizo uso de imagen/video para redes o comunicacion publica de Save Swimmer."
Add-Check "Autorizo que mis datos anonimizados se usen en graficos, documentos o presentaciones."
Add-Check "NO autorizo uso publico de imagen, video, nombre o datos personales."

Add-Paragraph "7. Riesgos y limites" "Heading1"
Add-Paragraph "El prototipo esta en etapa experimental. Puede fallar, desconectarse, perder datos, registrar valores incorrectos, perder GPS o no cerrar adecuadamente un archivo. Save Swimmer no reemplaza supervision humana ni sistemas formales de seguridad acuática." "Normal"
Add-Paragraph "El participante declara conocer sus propias condiciones fisicas y debe detener la prueba ante incomodidad, fatiga, dolor, dificultad respiratoria, mareo, frio, calambre o cualquier situacion insegura." "Normal"

Add-Paragraph "8. Guia de codigos de prueba" "Heading1"
Add-Table @(
    @("Codigo", "Significado"),
    @("QSEC", "Quieto seco con dispositivo colocado"),
    @("QAGU", "Quieto en agua, sin avanzar"),
    @("BASE", "Nado natural sin tecnica forzada"),
    @("EASP", "Rotacion exagerada / dedos abiertos / sin patada"),
    @("EACP", "Rotacion exagerada / dedos abiertos / con patada"),
    @("ECSP", "Rotacion exagerada / dedos cerrados / sin patada"),
    @("ECCP", "Rotacion exagerada / dedos cerrados / con patada"),
    @("SASP", "Sin rotacion / dedos abiertos / sin patada"),
    @("SACP", "Sin rotacion / dedos abiertos / con patada"),
    @("SCSP", "Sin rotacion / dedos cerrados / sin patada"),
    @("SCCP", "Sin rotacion / dedos cerrados / con patada"),
    @("NASP", "Rotacion normal / dedos abiertos / sin patada"),
    @("NACP", "Rotacion normal / dedos abiertos / con patada"),
    @("NCSP", "Rotacion normal / dedos cerrados / sin patada"),
    @("NCCP", "Rotacion normal / dedos cerrados / con patada")
) @(1900, 7200) $true

Add-Paragraph "9. Planilla rapida de campo" "Heading1"
Add-Table @(
    @("Sesion", "Codigo", "Inicio", "Fin", "OK/Descartar", "Observacion"),
    @("1", "", "", "", "", ""),
    @("2", "", "", "", "", ""),
    @("3", "", "", "", "", ""),
    @("4", "", "", "", "", ""),
    @("5", "", "", "", "", ""),
    @("6", "", "", "", "", "")
) @(1000, 1500, 1300, 1300, 1800, 3200) $true

Add-Paragraph "10. Firma" "Heading1"
Add-Paragraph "Declaro haber leido y entendido el presente documento. Acepto participar voluntariamente en la toma de datos indicada y autorizo el tratamiento de la informacion marcada en este formulario." "Normal"
Add-Paragraph "Participante: ______________________________ Firma: __________________ Fecha: ____ / ____ / ______" "Normal"
Add-Paragraph "Apoderado, si corresponde: __________________ Firma: __________________ Fecha: ____ / ____ / ______" "Normal"
Add-Paragraph "Responsable Save Swimmer: __________________ Firma: __________________ Fecha: ____ / ____ / ______" "Normal"

$styles = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:sz w:val="22"/></w:rPr><w:pPr><w:spacing w:after="120"/></w:pPr></w:style>
  <w:style w:type="paragraph" w:styleId="Brand"><w:name w:val="Brand"/><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:b/><w:sz w:val="34"/><w:color w:val="0A2A36"/></w:rPr><w:pPr><w:spacing w:after="80"/></w:pPr></w:style>
  <w:style w:type="paragraph" w:styleId="Title"><w:name w:val="Title"/><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:b/><w:sz w:val="28"/><w:color w:val="00A6C8"/></w:rPr><w:pPr><w:spacing w:after="80"/></w:pPr></w:style>
  <w:style w:type="paragraph" w:styleId="Subtitle"><w:name w:val="Subtitle"/><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:sz w:val="21"/><w:color w:val="455A64"/></w:rPr><w:pPr><w:spacing w:after="180"/></w:pPr></w:style>
  <w:style w:type="paragraph" w:styleId="Heading1"><w:name w:val="Heading 1"/><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:b/><w:sz w:val="25"/><w:color w:val="083044"/></w:rPr><w:pPr><w:spacing w:before="180" w:after="80"/></w:pPr></w:style>
  <w:style w:type="paragraph" w:styleId="Warning"><w:name w:val="Warning"/><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:b/><w:sz w:val="22"/><w:color w:val="C2410C"/></w:rPr><w:pPr><w:spacing w:before="120" w:after="80"/></w:pPr></w:style>
  <w:style w:type="paragraph" w:styleId="Check"><w:name w:val="Check"/><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:sz w:val="22"/></w:rPr><w:pPr><w:spacing w:after="70"/></w:pPr></w:style>
</w:styles>
'@

$document = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body>' + ($body -join "`n") + '<w:sectPr><w:pgSz w:w="12240" w:h="15840"/><w:pgMar w:top="900" w:right="900" w:bottom="900" w:left="900" w:header="720" w:footer="720" w:gutter="0"/></w:sectPr></w:body></w:document>'

[IO.File]::WriteAllText((Join-Path $base "[Content_Types].xml"), '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/><Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/></Types>', [Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText((Join-Path $base "_rels\.rels"), '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/></Relationships>', [Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText((Join-Path $base "word\_rels\document.xml.rels"), '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/></Relationships>', [Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText((Join-Path $base "word\document.xml"), $document, [Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText((Join-Path $base "word\styles.xml"), $styles, [Text.UTF8Encoding]::new($false))

if (Test-Path -LiteralPath $outputDocx) {
    Remove-Item -LiteralPath $outputDocx -Force
}
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($base, $outputDocx)
Remove-Item -LiteralPath $base -Recurse -Force

$txt = @"
SAVE SWIMMER
PERMISO, CONFIDENCIALIDAD Y AUTORIZACION PARA TOMA DE DATOS
Version V001 - 29/06/2026

Regla operativa:
1 codigo = 1 sesion = 1 archivo.

El participante autoriza voluntariamente una toma de datos asociada a una sesion de prueba, entrenamiento, calibracion o validacion tecnica del prototipo Save Swimmer.

Datos posibles:
- Identificacion basica o codigo.
- Codigo de prueba y contexto.
- Movimiento: LR, FB, UD, MAG, pitch, roll y patrones derivados.
- Energia: voltaje, corriente, potencia, bateria estimada.
- Ubicacion GPS solo si aplica.
- Imagen/video solo si se autoriza.

El prototipo esta en etapa experimental. Puede fallar, perder datos o registrar valores incorrectos. No reemplaza supervision, salvavidas, entrenador ni protocolo de seguridad.

Codigos:
QSEC = quieto seco con dispositivo colocado.
QAGU = quieto en agua, sin avanzar.
BASE = nado natural.
EASP = rotacion exagerada / dedos abiertos / sin patada.
EACP = rotacion exagerada / dedos abiertos / con patada.
ECSP = rotacion exagerada / dedos cerrados / sin patada.
ECCP = rotacion exagerada / dedos cerrados / con patada.
SASP = sin rotacion / dedos abiertos / sin patada.
SACP = sin rotacion / dedos abiertos / con patada.
SCSP = sin rotacion / dedos cerrados / sin patada.
SCCP = sin rotacion / dedos cerrados / con patada.
NASP = rotacion normal / dedos abiertos / sin patada.
NACP = rotacion normal / dedos abiertos / con patada.
NCSP = rotacion normal / dedos cerrados / sin patada.
NCCP = rotacion normal / dedos cerrados / con patada.

Firma participante: ____________________________
Firma apoderado, si corresponde: _______________
Firma responsable Save Swimmer: ________________
"@
$txt | Set-Content -LiteralPath $outputTxt -Encoding UTF8

$codes = @(
    [pscustomobject]@{codigo="QSEC";rotacion="";dedos="";patada="";descripcion="Quieto seco con dispositivo colocado"}
    [pscustomobject]@{codigo="QAGU";rotacion="";dedos="";patada="";descripcion="Quieto en agua sin avanzar"}
    [pscustomobject]@{codigo="BASE";rotacion="natural";dedos="natural";patada="natural";descripcion="Nado natural sin tecnica forzada"}
    [pscustomobject]@{codigo="EASP";rotacion="exagerada";dedos="abiertos";patada="sin";descripcion="Rotacion exagerada, dedos abiertos, sin patada"}
    [pscustomobject]@{codigo="EACP";rotacion="exagerada";dedos="abiertos";patada="con";descripcion="Rotacion exagerada, dedos abiertos, con patada"}
    [pscustomobject]@{codigo="ECSP";rotacion="exagerada";dedos="cerrados";patada="sin";descripcion="Rotacion exagerada, dedos cerrados, sin patada"}
    [pscustomobject]@{codigo="ECCP";rotacion="exagerada";dedos="cerrados";patada="con";descripcion="Rotacion exagerada, dedos cerrados, con patada"}
    [pscustomobject]@{codigo="SASP";rotacion="sin";dedos="abiertos";patada="sin";descripcion="Sin rotacion, dedos abiertos, sin patada"}
    [pscustomobject]@{codigo="SACP";rotacion="sin";dedos="abiertos";patada="con";descripcion="Sin rotacion, dedos abiertos, con patada"}
    [pscustomobject]@{codigo="SCSP";rotacion="sin";dedos="cerrados";patada="sin";descripcion="Sin rotacion, dedos cerrados, sin patada"}
    [pscustomobject]@{codigo="SCCP";rotacion="sin";dedos="cerrados";patada="con";descripcion="Sin rotacion, dedos cerrados, con patada"}
    [pscustomobject]@{codigo="NASP";rotacion="normal";dedos="abiertos";patada="sin";descripcion="Rotacion normal, dedos abiertos, sin patada"}
    [pscustomobject]@{codigo="NACP";rotacion="normal";dedos="abiertos";patada="con";descripcion="Rotacion normal, dedos abiertos, con patada"}
    [pscustomobject]@{codigo="NCSP";rotacion="normal";dedos="cerrados";patada="sin";descripcion="Rotacion normal, dedos cerrados, sin patada"}
    [pscustomobject]@{codigo="NCCP";rotacion="normal";dedos="cerrados";patada="con";descripcion="Rotacion normal, dedos cerrados, con patada"}
)
$codes | Export-Csv -LiteralPath $outputCsv -NoTypeInformation -Encoding UTF8

Write-Host "Creado: $outputDocx"
Write-Host "Creado: $outputTxt"
Write-Host "Creado: $outputCsv"
