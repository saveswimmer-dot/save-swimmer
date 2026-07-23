$ErrorActionPreference = "Stop"

$output = Join-Path $PSScriptRoot "SS-REGISTRO-PRUEBA-MICROSD-ENERGIA-V002.docx"
$temp = Join-Path $PSScriptRoot "_docx_tmp_registro_sd_v001"
$workspace = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$resolvedTemp = [System.IO.Path]::GetFullPath($temp)
if (-not $resolvedTemp.StartsWith($workspace, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Ruta temporal fuera del workspace."
}
if (Test-Path -LiteralPath $temp) {
    Remove-Item -LiteralPath $temp -Recurse -Force
}
New-Item -ItemType Directory -Path $temp, (Join-Path $temp "_rels"), (Join-Path $temp "word"), (Join-Path $temp "word\_rels") | Out-Null

function X([string]$text) {
    return [System.Security.SecurityElement]::Escape($text)
}

$body = New-Object System.Collections.Generic.List[string]

function Add-P([string]$text, [string]$style = "Normal", [string]$align = "") {
    $alignXml = if ($align) { "<w:jc w:val=`"$align`"/>" } else { "" }
    $body.Add("<w:p><w:pPr><w:pStyle w:val=`"$style`"/>$alignXml</w:pPr><w:r><w:t xml:space=`"preserve`">$(X $text)</w:t></w:r></w:p>")
}

function Cell([string]$text, [int]$width, [bool]$header = $false) {
    $shade = if ($header) { '<w:shd w:fill="083044"/>' } else { '' }
    $font = if ($header) { '<w:color w:val="FFFFFF"/><w:b/>' } else { '' }
    return "<w:tc><w:tcPr><w:tcW w:w=`"$width`" w:type=`"dxa`"/>$shade</w:tcPr><w:p><w:r><w:rPr>$font</w:rPr><w:t xml:space=`"preserve`">$(X $text)</w:t></w:r></w:p></w:tc>"
}

function Add-Table([array]$rows, [array]$widths, [bool]$header = $false) {
    $xml = '<w:tbl><w:tblPr><w:tblBorders><w:top w:val="single" w:sz="6" w:color="9CB8C1"/><w:left w:val="single" w:sz="6" w:color="9CB8C1"/><w:bottom w:val="single" w:sz="6" w:color="9CB8C1"/><w:right w:val="single" w:sz="6" w:color="9CB8C1"/><w:insideH w:val="single" w:sz="4" w:color="D1E0E4"/><w:insideV w:val="single" w:sz="4" w:color="D1E0E4"/></w:tblBorders></w:tblPr>'
    for ($r = 0; $r -lt $rows.Count; $r++) {
        $xml += '<w:tr>'
        for ($c = 0; $c -lt $rows[$r].Count; $c++) {
            $xml += Cell ([string]$rows[$r][$c]) $widths[$c] ($header -and $r -eq 0)
        }
        $xml += '</w:tr>'
    }
    $xml += '</w:tbl>'
    $body.Add($xml)
    Add-P ""
}

Add-P "SAVE SWIMMER" "Brand" "center"
Add-P "REGISTRO DE PRUEBA - MICROSD, ENERGIA Y EVOLUCION APP" "Title" "center"
Add-P "Validacion funcional del prototipo Data Logger y actualizacion documental" "Subtitle" "center"

Add-Table @(
    @("Codigo", "SS-PR-20260526-SD-001", "Version", "V002"),
    @("Fecha base", "26/05/2026", "Actualizacion", "03/06/2026"),
    @("Responsable", "Vittorio King", "Proyecto", "Save Swimmer Lite"),
    @("Firmware", "SS-LITE-BLE-SD-V1-029", "Dispositivo", "SS-LT-000001")
) @(1750, 3000, 1650, 2900)

Add-P "1. Objetivo" "Heading1"
Add-P "Confirmar que el prototipo puede registrar multiples sesiones consecutivas en microSD, asociadas a perfiles enviados desde la aplicacion BLE, funcionando con alimentacion portatil y sin depender de cable USB."

Add-P "2. Configuracion evaluada" "Heading1"
Add-Table @(
    @("Bloque", "Configuracion observada"),
    @("Control principal", "ESP32-S3 DevKit N16R8"),
    @("Sensor", "MPU6050 activo, datos IMU presentes en CSV"),
    @("Almacenamiento", "Modulo microSD SPI, CS 10 / MOSI 11 / SCK 12 / MISO 13"),
    @("Alimentacion de microSD", "VCC conectado a 5 V"),
    @("Alimentacion general", "Bateria con elevador MT3608; ESP sin conexion USB durante prueba"),
    @("Aplicacion", "Field Viewer BLE para perfil e inicio/detencion de sesion")
) @(2750, 6500) $true

Add-P "3. Antecedente de falla y correccion aplicada" "Heading1"
Add-P "En pruebas previas, el modulo microSD fue alimentado a 3.3 V y se observaron fallas de inicio, archivos cortados y contenido corrupto. El modulo empleado dispone de adaptacion/regulacion para uso con alimentacion de 5 V. Al cambiar VCC de la microSD a 5 V y utilizar firmware V029, la grabacion de sesiones consecutivas produjo archivos CSV legibles."
Add-P "Criterio tecnico actual: mantener el modulo microSD de prototipo alimentado a 5 V; conservar GND comun y pines SPI definidos. Esta validacion no reemplaza futuras pruebas de regulacion, autonomia ni PCB integrada." "Note"

Add-P "4. Resultados obtenidos" "Heading1"
Add-Table @(
    @("Archivo", "Perfil", "Inicio local", "Duracion", "Muestras", "Bytes", "Resultado"),
    @("SS000001.CSV", "vitto", "09:40:18", "26.67 s", "232", "19,394", "VALIDA"),
    @("SS000002.CSV", "vittoka", "09:40:55", "25.17 s", "242", "20,313", "VALIDA"),
    @("SS000003.CSV", "vprueba 3", "09:41:32", "30.55 s", "304", "25,452", "VALIDA"),
    @("SS000004.CSV", "5 minutos", "09:47:35", "236.89 s", "2,276", "191,692", "VALIDA"),
    @("SS000005.CSV", "2 minutos ms app", "09:52:54", "93.71 s", "908", "76,481", "VALIDA")
) @(1500, 1250, 1450, 1150, 950, 1100, 1200) $true

Add-P "Archivos de control observados:" "Heading2"
Add-Table @(
    @("Archivo", "Bytes", "Validacion"),
    @("BOOT.CSV", "28", "Legible; registra firmware V029. Fecha FAT 1980 esperable antes de sincronizar hora."),
    @("INDEX.CSV", "38", "Legible; contiene secuencia de sesiones 1 a 5.")
) @(1700, 1100, 6500) $true

Add-P "5. Verificaciones de integridad realizadas" "Heading1"
Add-Table @(
    @("Control", "Resultado"),
    @("Lectura de encabezado CSV", "Correcta en las cinco sesiones"),
    @("Perfil por sesion", "Perfiles diferenciados y asociados al archivo correcto"),
    @("Fecha/hora desde telefono", "Presente y coherente en las sesiones"),
    @("Datos MPU6050", "Presentes en filas LR, FB, UD y MAG"),
    @("Caracteres corruptos / bytes nulos", "No observados en BOOT, INDEX ni archivos de sesion"),
    @("Numeracion consecutiva", "Correcta: SS000001 a SS000005")
) @(3250, 6050) $true

Add-P "6. Conclusion de la prueba" "Heading1"
Add-P "RESULTADO: APROBADA PARA EL ALCANCE EVALUADO." "Result"
Add-P "El prototipo registro correctamente tres sesiones cortas consecutivas y dos sesiones adicionales utilizando bateria, BLE, MPU6050 y microSD alimentada a 5 V. La cuarta sesion sostuvo casi cuatro minutos de registro SD. Queda validado el flujo basico: enviar perfil, iniciar sesion, guardar CSV independiente, detener y repetir con otro perfil."

Add-P "7. Comparacion entre registro de app y microSD" "Heading1"
Add-P "La sesion SS000005.CSV corresponde al archivo exportado desde la app ss_2_minutos_ms_app_test_nado_20260526_095423.csv: ambos comparten el perfil '2 minutos ms app' y el inicio local 09:52:54."
Add-Table @(
    @("Metrica", "App BLE", "MicroSD dispositivo", "Interpretacion"),
    @("Muestras", "178", "908", "La SD conserva aproximadamente 5.1 veces mas informacion"),
    @("Duracion observada", "89.15 s", "93.46 s", "La app dejo de guardar antes del cierre final en SD"),
    @("Frecuencia aproximada", "1.99 Hz", "9.70 Hz", "BLE sirve para vivo; SD para analisis tecnico"),
    @("UD maximo", "17.90", "17.93", "Pico principal consistente"),
    @("MAG maximo", "18.50", "20.25", "La SD capta picos entre envios BLE")
) @(1900, 1450, 1900, 4050) $true
Add-P "La comparacion temporal arrojo diferencias pequenas para FB, UD y MAG (RMSE aproximado 0.15, 0.36 y 0.27). LR tiene mayor diferencia aproximada (1.00) porque cambia con rapidez y el BLE recibe cerca de una de cada cinco muestras que quedan guardadas en la SD."

Add-P "8. Alcances no validados aun" "Heading1"
Add-Table @(
    @("Pendiente", "Prueba requerida"),
    @("Grabacion continua prolongada", "Sesion de 15 minutos y luego de 30 minutos con bateria"),
    @("Repeticion intensiva", "Varias sesiones seguidas sin retirar tarjeta"),
    @("Autonomia real", "Medir duracion de bateria con BLE y microSD activos"),
    @("Estabilidad energetica", "Agregar capacitor cercano a microSD y comparar resultados"),
    @("Uso acuatico", "No aprobado aun; requiere carcasa y protocolo de sellado/seguridad")
) @(3250, 6050) $true

Add-P "9. Actualizacion documental 2026-06-03" "Heading1"
Add-P "Posterior a la validacion microSD inicial, el proyecto avanzo en la organizacion del flujo de apps y de las premisas de seguridad. Esta actualizacion no modifica los resultados de la prueba SD original; agrega trazabilidad sobre la direccion funcional del prototipo y los documentos de apoyo generados."

Add-Table @(
    @("Elemento", "Actualizacion"),
    @("Field Viewer", "App tecnica para telefono A depurada a FIELD V0.3.34; conserva BLE, perfil, SD, gateway y grafico unico de rotacion dorsal en vivo."),
    @("Coach Live", "App monitor para telefono B evolucionada a COACH-LIVE V0.1.12; prioriza mapa, lista/estado y rotacion dorsal autorizada en vivo."),
    @("Rotacion dorsal", "La lectura tecnica deja de expresarse como LR crudo y se traduce a grados; objetivo referencial 32-45 grados por lado y sobre-rotacion desde 50 grados."),
    @("Datos crudos", "La SD/dispositivo conserva la fuente oficial de datos; la app en vivo es apoyo operativo y visual."),
    @("Base conceptual", "Se crea SS-BASE-CONCEPTUAL-PRODUCTO-V001 con premisa madre de rescate, alcance acuatico, coach como monitor, geocerca, cierre de sesion y permisos de datos."),
    @("Excel", "Se generan versiones XLSX reales de las tablas CSV principales para lectura correcta en Excel.")
) @(2400, 6900) $true

Add-P "10. Premisas de seguridad incorporadas" "Heading1"
Add-Table @(
    @("Premisa", "Criterio tecnico"),
    @("Finalidad principal", "Save Swimmer existe para rescate, atencion primaria y reduccion del tiempo de respuesta en agua."),
    @("Alcance", "El sistema es para seguridad acuatico; no debe prometer monitoreo terrestre en arena, malecon o ciudad."),
    @("Coach", "La app Coach es monitor. No descarga datos crudos completos ni ve historial privado salvo autorizacion del atleta."),
    @("Emergencia grupal", "En nado grupal o entrenamiento con coach, el primer contacto ante emergencia es el coach."),
    @("Geocerca", "En sesion con coach, el coach puede definir geocerca/tiempo/distancia y los atletas se unen aceptando ese contexto de seguridad."),
    @("Cierre de sesion", "Cada atleta debe quedar cerrado seguro o pendiente de verificacion al finalizar una sesion grupal o competencia."),
    @("Salida fuera de punto", "Si sensor de agua pasa a seco durante sesion activa lejos del punto esperado, se registra incidencia de seguridad y se solicita verificacion.")
) @(2500, 6800) $true

Add-P "11. Documentos asociados" "Heading1"
Add-Table @(
    @("Documento", "Uso"),
    @("save_swimmer_premisas.md", "Base narrativa de producto y criterios de decision."),
    @("SS-BASE-CONCEPTUAL-PRODUCTO-V001.xlsx", "Tabla estructurada de premisas, alcance y reglas de producto."),
    @("SS-BITACORA-PRUEBAS-PROTOTIPO-V001.xlsx", "Bitacora de pruebas y cambios compilados."),
    @("SS-PENDIENTES-FIRMWARE-APP-V001.xlsx", "Pendientes tecnicos firmware/app."),
    @("SS-INVESTIGACION-MERCADO-RESPUESTAS-V001.xlsx", "Respuestas e insights de comunidad/mercado.")
) @(3300, 6000) $true

Add-P "12. Evidencia y trazabilidad" "Heading1"
Add-P "Los archivos fuente fueron copiados desde la microSD al proyecto para preservar evidencia. BOOT.CSV, INDEX.CSV y las sesiones 1 a 3 se conservan en datasets/evidencia/SS-PR-20260526-SD-001. Las sesiones 4 y 5, junto al CSV exportado por la app y la tabla comparativa, se conservan en datasets/evidencia/SS-PR-20260526-SD-002."
Add-P "Cada carpeta contiene SHA256.csv con las huellas digitales de los archivos copiados. Registros tabulares asociados: SS-BITACORA-PRUEBAS-PROTOTIPO-V001.xlsx y SS-BASE-CONCEPTUAL-PRODUCTO-V001.xlsx."

Add-Table @(
    @("Revision", "Fecha", "Descripcion", "Responsable"),
    @("V001", "26/05/2026", "Validacion microSD a 5 V, bateria, cinco sesiones con V029 y comparacion app/SD.", "Save Swimmer / Vittorio King"),
    @("V002", "03/06/2026", "Actualiza direccion de apps Field/Coach, rotacion dorsal en grados, alcance acuatico y base conceptual de seguridad.", "Save Swimmer / Vittorio King")
) @(1300, 1700, 4400, 1900) $true

$documentXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <w:body>
    $($body -join "`n")
    <w:sectPr>
      <w:footerReference w:type="default" r:id="rId1"/>
      <w:pgSz w:w="11906" w:h="16838"/>
      <w:pgMar w:top="1000" w:right="850" w:bottom="1000" w:left="850" w:footer="500"/>
    </w:sectPr>
  </w:body>
</w:document>
"@

$stylesXml = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:docDefaults><w:rPrDefault><w:rPr><w:rFonts w:ascii="Aptos" w:hAnsi="Aptos"/><w:sz w:val="19"/><w:color w:val="16313A"/></w:rPr></w:rPrDefault></w:docDefaults>
  <w:style w:type="paragraph" w:styleId="Normal"><w:name w:val="Normal"/><w:pPr><w:spacing w:after="110" w:line="250" w:lineRule="auto"/></w:pPr></w:style>
  <w:style w:type="paragraph" w:styleId="Brand"><w:name w:val="Brand"/><w:rPr><w:b/><w:sz w:val="36"/><w:color w:val="052337"/><w:spacing w:val="65"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="Title"><w:name w:val="Title"/><w:pPr><w:spacing w:before="70" w:after="100"/></w:pPr><w:rPr><w:b/><w:sz w:val="28"/><w:color w:val="083044"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="Subtitle"><w:name w:val="Subtitle"/><w:pPr><w:spacing w:after="230"/></w:pPr><w:rPr><w:sz w:val="20"/><w:color w:val="00A8CD"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="Heading1"><w:name w:val="Heading 1"/><w:pPr><w:spacing w:before="210" w:after="80"/></w:pPr><w:rPr><w:b/><w:sz w:val="24"/><w:color w:val="083044"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="Heading2"><w:name w:val="Heading 2"/><w:pPr><w:spacing w:before="130" w:after="70"/></w:pPr><w:rPr><w:b/><w:sz w:val="21"/><w:color w:val="00A8CD"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="Result"><w:name w:val="Result"/><w:pPr><w:spacing w:before="90" w:after="90"/><w:shd w:fill="D9F5EE"/></w:pPr><w:rPr><w:b/><w:sz w:val="22"/><w:color w:val="00765B"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="Note"><w:name w:val="Note"/><w:pPr><w:spacing w:before="90" w:after="90"/><w:shd w:fill="E6F7FB"/></w:pPr><w:rPr><w:sz w:val="19"/><w:color w:val="075873"/></w:rPr></w:style>
</w:styles>
'@

$footerXml = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:ftr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:p><w:pPr><w:jc w:val="center"/></w:pPr><w:r><w:rPr><w:sz w:val="16"/><w:color w:val="6A8790"/></w:rPr><w:t>Save Swimmer | SS-PR-20260526-SD-001 | Registro de prototipo | V002</w:t></w:r></w:p>
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

$rels = @'
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

Set-Content -LiteralPath (Join-Path $temp "[Content_Types].xml") -Value $contentTypes -Encoding UTF8
Set-Content -LiteralPath (Join-Path $temp "_rels\.rels") -Value $rels -Encoding UTF8
Set-Content -LiteralPath (Join-Path $temp "word\document.xml") -Value $documentXml -Encoding UTF8
Set-Content -LiteralPath (Join-Path $temp "word\styles.xml") -Value $stylesXml -Encoding UTF8
Set-Content -LiteralPath (Join-Path $temp "word\footer1.xml") -Value $footerXml -Encoding UTF8
Set-Content -LiteralPath (Join-Path $temp "word\_rels\document.xml.rels") -Value $documentRels -Encoding UTF8

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
if (Test-Path -LiteralPath $output) {
    Remove-Item -LiteralPath $output -Force
}
$zip = [System.IO.Compression.ZipFile]::Open($output, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    Get-ChildItem -LiteralPath $temp -Recurse -File | ForEach-Object {
        $relative = $_.FullName.Substring($temp.Length + 1).Replace("\", "/")
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $_.FullName, $relative) | Out-Null
    }
} finally {
    $zip.Dispose()
}

Remove-Item -LiteralPath $temp -Recurse -Force
Write-Output $output
