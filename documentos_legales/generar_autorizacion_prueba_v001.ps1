$ErrorActionPreference = "Stop"

$base = Join-Path $PSScriptRoot "_docx_tmp_autorizacion_v001"
$output = Join-Path $PSScriptRoot "SS-FRM-CONFIDENCIALIDAD-AUTORIZACION-PRUEBA-V001.docx"
$workspace = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$resolvedBase = [System.IO.Path]::GetFullPath($base)
if (-not $resolvedBase.StartsWith($workspace, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Ruta temporal fuera del workspace."
}
if (Test-Path -LiteralPath $base) {
    Remove-Item -LiteralPath $base -Recurse -Force
}
New-Item -ItemType Directory -Path $base, (Join-Path $base "_rels"), (Join-Path $base "word"), (Join-Path $base "word\_rels") | Out-Null

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

function Add-PageBreak {
    $body.Add('<w:p><w:r><w:br w:type="page"/></w:r></w:p>')
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
Add-Paragraph "CONFIDENCIALIDAD Y AUTORIZACION PARA PRUEBA DE DISPOSITIVO Y TOMA DE DATOS" "Title" "center"
Add-Paragraph "Formulario de prototipo - etapa de investigacion y desarrollo" "Subtitle" "center"

Add-Table @(
    @("Codigo", "SS-FRM-PRUEBA-DATOS-001", "Version", "V001"),
    @("Fecha de emision", "25/05/2026", "Estado", "Borrador operativo"),
    @("Proyecto", "Save Swimmer Lite", "Responsable", "Vittorio King"),
    @("Contacto", "saveswimmer@gmail.com", "Lugar de firma", "________________________")
) @(1800, 2850, 1750, 2850)

Add-Paragraph "IMPORTANTE" "Warning"
Add-Paragraph "Este documento ha sido preparado para ordenar las pruebas iniciales del prototipo Save Swimmer. Antes de realizar pruebas comerciales, pruebas acuaticas con terceros, tratamiento sistematico de geolocalizacion o pruebas con menores de edad, debe ser validado por asesoria legal en Peru y acompañado por un protocolo de seguridad correspondiente." "Normal"

Add-Paragraph "1. Identificacion de las partes" "Heading1"
Add-Paragraph "Responsable de la prueba y del tratamiento inicial de datos:" "Heading2"
Add-Table @(
    @("Proyecto / Responsable", "Save Swimmer - Vittorio King"),
    @("Documento de identidad / RUC", "_______________________________________________"),
    @("Domicilio", "_______________________________________________"),
    @("Correo de contacto", "saveswimmer@gmail.com")
) @(3000, 6200)

Add-Paragraph "Participante:" "Heading2"
Add-Table @(
    @("Nombres y apellidos", "_______________________________________________"),
    @("DNI / CE / Pasaporte", "________________________", "Fecha de nacimiento", "____ / ____ / ______"),
    @("Telefono / correo", "_______________________________________________"),
    @("Edad", "________", "Si es menor: apoderado", "________________________________")
) @(2300, 2450, 2300, 2150)

Add-Paragraph "Si el participante es menor de 18 anos, completa y firma tambien su padre, madre o apoderado legal:" "Normal"
Add-Table @(
    @("Nombre del apoderado", "_______________________________________________"),
    @("DNI / CE", "________________________", "Vinculo", "________________________"),
    @("Telefono / correo", "_______________________________________________")
) @(2700, 2500, 1800, 2200)

Add-Paragraph "2. Objeto de la autorizacion" "Heading1"
Add-Paragraph "El participante autoriza voluntariamente su participacion en una prueba del prototipo Save Swimmer, dispositivo dorsal experimental orientado al analisis referencial del movimiento durante actividades compatibles con nado y al futuro desarrollo de funciones contextuales de seguridad acuática." "Normal"
Add-Paragraph "La prueba tiene por finalidad recopilar informacion tecnica para evaluar funcionamiento del sensor, conectividad, aplicacion movil, registro de sesiones, patrones de movimiento y futuras metricas de ritmo, rotacion corporal e impulso aparente." "Normal"

Add-Paragraph "3. Modalidad de prueba autorizada" "Heading1"
Add-Paragraph "Marcar exclusivamente la modalidad que corresponda a esta sesion:" "Normal"
Add-Check "Prueba en seco / tierra: postura, giros, caminata o simulacion de brazada fuera del agua."
Add-Check "Prueba en piscina controlada, con supervision presencial y condiciones de seguridad definidas."
Add-Check "Prueba en playa o aguas abiertas controladas. Requiere anexo de seguridad, supervision y plan de respuesta firmado antes del ingreso al agua."
Add-Check "Otro alcance especifico: _______________________________________________________________"
Add-Paragraph "Lugar: ____________________________________   Fecha: ____ / ____ / ______   Hora inicio: ________   Hora fin: ________" "Normal"

Add-Paragraph "4. Datos que pueden ser capturados" "Heading1"
Add-Paragraph "Segun el alcance marcado, Save Swimmer podra recopilar los siguientes datos vinculados al participante o a la sesion:" "Normal"
Add-Table @(
    @("Categoria", "Ejemplos", "Uso previsto"),
    @("Identificacion basica", "Nombre o codigo, edad, altura, peso, modalidad", "Asociar correctamente la prueba y ajustar interpretaciones"),
    @("Telemetria del prototipo", "LR, FB, UD, MAG, tiempo, numero de dispositivo, firmware", "Evaluar postura, movimiento, ciclos y calidad del sensor"),
    @("Datos de sesion", "Fecha, duracion, lugar general, observaciones", "Trazabilidad y comparacion entre pruebas"),
    @("Ubicacion, solo si esta habilitada", "GPS, recorrido, geocerco", "Validar mapas y seguridad contextual"),
    @("Imagen o video, solo con permiso opcional", "Fotos o grabaciones de la colocacion/prueba", "Documentar ergonomia o comunicacion autorizada")
) @(2200, 3900, 3000) $true

Add-Paragraph "5. Consentimiento para tratamiento de datos personales" "Heading1"
Add-Paragraph "Declaro haber sido informado de manera previa, clara y comprensible sobre la recopilacion y uso de mis datos en esta prueba. Autorizo el tratamiento de los datos indispensables marcados a continuacion para las finalidades de investigacion, validacion tecnica y mejora del prototipo descritas en este documento." "Normal"
Add-Check "AUTORIZO el registro de mis datos de identificacion basica y contexto de la prueba."
Add-Check "AUTORIZO el registro de telemetria del sensor y archivos de sesion vinculados a mi codigo o nombre."
Add-Check "AUTORIZO la captura de ubicacion y recorrido, unicamente cuando la prueba use GPS o funciones de mapa/geocerco."
Add-Check "AUTORIZO que datos tecnicos anonimizados o seudonimizados sean utilizados para comparar patrones y mejorar algoritmos o visualizaciones del producto."
Add-Check "AUTORIZO, de manera opcional, el uso interno de fotografias o videos para documentacion del desarrollo."
Add-Check "AUTORIZO, de manera opcional y separada, el uso de imagen en presentaciones o comunicaciones de Save Swimmer: SI [ ]  NO [ ]"

Add-Paragraph "La negativa a autorizar imagenes de comunicacion o marketing no impide participar en una prueba tecnica. Para realizar una prueba con telemetria, la autorizacion de captura tecnica de datos resulta necesaria." "Normal"

Add-Paragraph "6. Finalidades, conservacion y derechos del participante" "Heading1"
Add-Paragraph "Los datos seran usados para: (a) verificar funcionamiento del hardware y software; (b) analizar telemetria y patrones referenciales de movimiento; (c) corregir fallas y mejorar metricas; (d) mantener trazabilidad de pruebas; y (e) validar, cuando corresponda, funciones de seguridad contextual." "Normal"
Add-Paragraph "Durante la etapa de prototipo, los datos se conservaran por un plazo referencial de hasta veinticuatro (24) meses desde la prueba, salvo que el participante solicite su supresion cuando legal y tecnicamente proceda, o que sea necesario conservar registros bloqueados para atender responsabilidades o incidentes documentados." "Normal"
Add-Paragraph "El participante puede solicitar informacion, acceso, actualizacion, rectificacion, cancelacion/supresion u oposicion, asi como revocar autorizaciones opcionales, escribiendo a saveswimmer@gmail.com e identificando la sesion o participante. La revocacion no invalida el tratamiento efectuado antes de recibirla." "Normal"
Add-Paragraph "Los datos no seran vendidos. Podran ser procesados mediante la aplicacion, computadora o servicios tecnologicos necesarios para la prueba bajo medidas razonables de seguridad y confidencialidad. No se comunicaran a terceros, salvo autorizacion expresa, obligacion legal, atencion de un incidente o emergencia real, o uso de proveedores tecnicos necesarios bajo deber de confidencialidad." "Normal"

Add-Paragraph "7. Naturaleza experimental y seguridad de la prueba" "Heading1"
Add-Paragraph "El participante declara entender y aceptar lo siguiente:" "Normal"
Add-Check "Save Swimmer se encuentra en fase de prototipo y sus lecturas pueden ser incompletas, imprecisas o interrumpirse."
Add-Check "El dispositivo no es, en esta etapa, un equipo medico, salvavidas, sistema de rescate certificado ni garantia de deteccion o atencion de emergencias."
Add-Check "La funcion prioritaria probada en esta etapa es referencial de movimiento/nado; una lectura tecnica no constituye diagnostico medico ni evaluacion profesional definitiva."
Add-Check "Una prueba en agua solo se realizara con medidas de seguridad, supervision humana adecuada y autorizacion especifica del responsable de la prueba."
Add-Check "El participante puede detener la prueba en cualquier momento, sin penalidad, si siente incomodidad, inseguridad o simplemente decide no continuar."
Add-Paragraph "Save Swimmer se compromete a realizar la prueba de manera diligente, informar su alcance real, proteger los datos recopilados y registrar cualquier incidente relevante. La presente autorizacion no elimina responsabilidades que correspondan legalmente." "Normal"

Add-Paragraph "8. Confidencialidad del prototipo" "Heading1"
Add-Paragraph "Durante la prueba, el participante puede observar un prototipo no comercial, su aplicacion, configuraciones, graficos, piezas, procesos o conceptos de desarrollo de Save Swimmer. El participante se compromete a no publicar, reproducir, entregar a terceros ni utilizar con fines comerciales informacion tecnica no publica, fotografias detalladas del prototipo, pantallas internas o archivos de telemetria sin autorizacion previa y escrita de Save Swimmer." "Normal"
Add-Paragraph "Esta obligacion no comprende informacion que ya sea publica, que el participante conociera legitimamente antes de la prueba, o que deba comunicar por exigencia legal o para reportar una situacion de seguridad. La confidencialidad se mantendra por dos (2) anos contados desde la fecha de firma, salvo que la informacion se haga publica legitimamente antes." "Normal"

Add-Paragraph "9. Declaracion de consentimiento" "Heading1"
Add-Paragraph "He leido o me han explicado este documento, pude realizar preguntas y recibi respuestas comprensibles. Entiendo el caracter experimental del dispositivo, las finalidades de la toma de datos, mis derechos y los limites de la prueba. Con mi firma autorizo voluntariamente mi participacion y los tratamientos que haya marcado." "Normal"

Add-Table @(
    @("PARTICIPANTE", "RESPONSABLE SAVE SWIMMER"),
    @("Nombre: _______________________________", "Nombre: Vittorio King"),
    @("DNI/CE: _______________________________", "DNI/RUC: ______________________________"),
    @("Firma: ________________________________", "Firma: _________________________________"),
    @("Fecha: ____ / ____ / ______", "Fecha: ____ / ____ / ______")
) @(4700, 4700) $true

Add-Table @(
    @("PADRE, MADRE O APODERADO LEGAL (solo si aplica)", "ASENTIMIENTO DEL MENOR (recomendado)"),
    @("Nombre: _______________________________", "Nombre: _______________________________"),
    @("DNI/CE: _______________________________", "Firma: _________________________________"),
    @("Firma: ________________________________", "Fecha: ____ / ____ / ______")
) @(4700, 4700) $true

Add-PageBreak
Add-Paragraph "ANEXO A - FICHA DE TRAZABILIDAD DE LA PRUEBA" "Title" "center"
Add-Paragraph "Este anexo debe completarse por cada sesion para asociar autorizacion, dispositivo y archivo de datos." "Normal"
Add-Table @(
    @("Codigo de sesion", "SS-TEST-__________________", "Fecha", "____ / ____ / ______"),
    @("Participante / codigo", "_________________________", "Operador", "_________________________"),
    @("Dispositivo / serial", "_________________________", "Firmware", "_________________________"),
    @("App / version", "_________________________", "Archivo CSV", "_________________________"),
    @("Lugar", "_________________________", "Modalidad", "Seco [ ] Piscina [ ] Playa [ ]"),
    @("Inicio / fin", "________ / ________", "Duracion", "_________________________")
) @(2100, 2800, 1800, 2700)

Add-Paragraph "Variables capturadas" "Heading2"
Add-Check "Telemetria IMU: LR / FB / UD / MAG / tiempo."
Add-Check "Perfil basico del participante."
Add-Check "GPS / ubicacion / recorrido / geocerco."
Add-Check "Registro BLE o conectividad."
Add-Check "Fotos o video autorizado."
Add-Check "Observaciones adicionales: _____________________________________________________________"

Add-Paragraph "Controles de seguridad aplicados" "Heading2"
Add-Check "Prueba fuera del agua."
Add-Check "Supervision presencial identificada: _________________________________________________"
Add-Check "Zona delimitada / geocerco definido."
Add-Check "Medio de comunicacion disponible."
Add-Check "Plan de interrupcion o asistencia revisado antes de iniciar."
Add-Check "No aplica por tratarse de prueba tecnica de escritorio."

Add-Paragraph "Resultado y observaciones" "Heading2"
Add-Paragraph "__________________________________________________________________________________________" "Normal"
Add-Paragraph "__________________________________________________________________________________________" "Normal"
Add-Paragraph "__________________________________________________________________________________________" "Normal"
Add-Table @(
    @("Incidente o alerta durante la prueba", "NO [ ]   SI [ ]   Detalle / registro: ___________________________"),
    @("Datos validos para analisis", "SI [ ]   PARCIAL [ ]   NO [ ]"),
    @("Responsable de registro", "_________________________", "Firma", "_________________________")
) @(3200, 6000)

Add-PageBreak
Add-Paragraph "ANEXO B - BASE NORMATIVA Y CONTROL DE REVISION" "Title" "center"
Add-Paragraph "Referencia normativa considerada para este borrador" "Heading1"
Add-Paragraph "1. Ley N. 29733, Ley de Proteccion de Datos Personales, Peru. Su objeto es garantizar el derecho fundamental a la proteccion de datos personales mediante su adecuado tratamiento." "Normal"
Add-Paragraph "2. Decreto Supremo N. 016-2024-JUS, Reglamento de la Ley N. 29733, publicado el 30 de noviembre de 2024. Contempla datos de localizacion, movimientos y elaboracion de perfiles dentro de las categorias relevantes para el tratamiento de datos personales." "Normal"
Add-Paragraph "Fuentes oficiales:" "Heading2"
Add-Paragraph "https://www.gob.pe/institucion/congreso-de-la-republica/normas-legales/243470-29733" "Normal"
Add-Paragraph "https://www.gob.pe/institucion/anpd/normas-legales/6554453-n-016-2024-jus" "Normal"

Add-Paragraph "Pendientes antes de pilotos abiertos o uso comercial" "Heading1"
Add-Check "Revision legal final del formulario y politica de privacidad."
Add-Check "Definir titular/responsable formal del banco de datos y domicilio legal."
Add-Check "Determinar obligaciones de registro, seguridad y atencion de derechos ante la ANPD."
Add-Check "Preparar protocolo especifico de pruebas acuaticas y gestion de incidentes."
Add-Check "Preparar autorizacion separada para menores y para uso de imagen comercial."
Add-Check "Definir retencion definitiva, proveedores cloud y acceso por roles."

Add-Table @(
    @("Version", "Fecha", "Descripcion del cambio", "Responsable"),
    @("V001", "25/05/2026", "Emision inicial para pruebas de prototipo y toma de datos.", "Save Swimmer / Vittorio King"),
    @("V____", "____ / ____ / ______", "________________________________________________", "________________")
) @(1200, 1900, 4400, 1800) $true

$documentXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    $($body -join "`n")
    <w:sectPr>
      <w:footerReference w:type="default" r:id="rId1" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"/>
      <w:pgSz w:w="11906" w:h="16838"/>
      <w:pgMar w:top="1100" w:right="980" w:bottom="1100" w:left="980" w:header="600" w:footer="600" w:gutter="0"/>
    </w:sectPr>
  </w:body>
</w:document>
"@

$stylesXml = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:docDefaults><w:rPrDefault><w:rPr><w:rFonts w:ascii="Aptos" w:hAnsi="Aptos"/><w:sz w:val="20"/><w:color w:val="16313A"/></w:rPr></w:rPrDefault></w:docDefaults>
  <w:style w:type="paragraph" w:styleId="Normal"><w:name w:val="Normal"/><w:pPr><w:spacing w:after="120" w:line="270" w:lineRule="auto"/></w:pPr></w:style>
  <w:style w:type="paragraph" w:styleId="Brand"><w:name w:val="Brand"/><w:pPr><w:spacing w:after="80"/></w:pPr><w:rPr><w:rFonts w:ascii="Arial" w:hAnsi="Arial"/><w:b/><w:sz w:val="38"/><w:color w:val="052337"/><w:spacing w:val="70"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="Title"><w:name w:val="Title"/><w:pPr><w:spacing w:before="90" w:after="120"/></w:pPr><w:rPr><w:b/><w:sz w:val="29"/><w:color w:val="083044"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="Subtitle"><w:name w:val="Subtitle"/><w:pPr><w:spacing w:after="260"/></w:pPr><w:rPr><w:sz w:val="20"/><w:color w:val="00A8CD"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="Heading1"><w:name w:val="Heading 1"/><w:pPr><w:spacing w:before="240" w:after="100"/></w:pPr><w:rPr><w:b/><w:sz w:val="25"/><w:color w:val="083044"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="Heading2"><w:name w:val="Heading 2"/><w:pPr><w:spacing w:before="150" w:after="70"/></w:pPr><w:rPr><w:b/><w:sz w:val="21"/><w:color w:val="00A8CD"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="Check"><w:name w:val="Check"/><w:pPr><w:ind w:left="220"/><w:spacing w:after="75" w:line="250" w:lineRule="auto"/></w:pPr><w:rPr><w:sz w:val="20"/><w:color w:val="16313A"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="Warning"><w:name w:val="Warning"/><w:pPr><w:spacing w:before="150" w:after="70"/><w:shd w:fill="E6F7FB"/></w:pPr><w:rPr><w:b/><w:sz w:val="22"/><w:color w:val="007FA3"/></w:rPr></w:style>
</w:styles>
'@

$footerXml = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:ftr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:p>
    <w:pPr><w:jc w:val="center"/></w:pPr>
    <w:r><w:rPr><w:sz w:val="17"/><w:color w:val="6A8790"/></w:rPr><w:t>Save Swimmer | SS-FRM-PRUEBA-DATOS-001 | V001 | Documento confidencial de prototipo</w:t></w:r>
  </w:p>
</w:ftr>
'@

$contentTypes = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
  <Override PartName="/word/footer1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml"/>
</Types>
'@

$packageRels = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>
'@

$documentRels = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/footer" Target="footer1.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>
'@

[System.IO.File]::WriteAllText((Join-Path $base "[Content_Types].xml"), $contentTypes, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $base "_rels\.rels"), $packageRels, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $base "word\document.xml"), $documentXml, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $base "word\styles.xml"), $stylesXml, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $base "word\footer1.xml"), $footerXml, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $base "word\_rels\document.xml.rels"), $documentRels, [System.Text.UTF8Encoding]::new($false))

$zip = [System.IO.Path]::ChangeExtension($output, ".zip")
if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }
if (Test-Path -LiteralPath $output) { Remove-Item -LiteralPath $output -Force }
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::Open($zip, [System.IO.Compression.ZipArchiveMode]::Create)
$entries = @(
    @("[Content_Types].xml", "[Content_Types].xml"),
    @("_rels\.rels", "_rels/.rels"),
    @("word\document.xml", "word/document.xml"),
    @("word\styles.xml", "word/styles.xml"),
    @("word\footer1.xml", "word/footer1.xml"),
    @("word\_rels\document.xml.rels", "word/_rels/document.xml.rels")
)
foreach ($entry in $entries) {
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
        $archive,
        (Join-Path $base $entry[0]),
        $entry[1],
        [System.IO.Compression.CompressionLevel]::Optimal
    ) | Out-Null
}
$archive.Dispose()
Move-Item -LiteralPath $zip -Destination $output
Remove-Item -LiteralPath $base -Recurse -Force
Write-Output $output
