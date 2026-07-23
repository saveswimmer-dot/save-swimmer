$ErrorActionPreference = "Stop"

$output = Join-Path $PSScriptRoot "SS-REGISTRO-PRUEBA-MICROSD-ENERGIA-V003.docx"
$temp = Join-Path $PSScriptRoot "_docx_tmp_registro_sd_v003"
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
Add-P "REGISTRO DE PRUEBA - MICROSD, ENERGIA, BLE Y GPS" "Title" "center"
Add-P "Actualizacion V003 con hallazgos de V045, optimizacion V046 e integracion GPS V047" "Subtitle" "center"

Add-Table @(
    @("Codigo", "SS-PR-20260526-SD-001 / SS-PR-20260615", "Version", "V003"),
    @("Fecha base", "26/05/2026", "Actualizacion", "15/06/2026"),
    @("Responsable", "Victor Loza", "Proyecto", "Save Swimmer Lite"),
    @("Dispositivo", "SS-LT-000001", "Firmware actual", "SS-LITE-BLE-SD-V1-047")
) @(2600, 3700, 1650, 2600)

Add-P "1. Objetivo" "Heading1"
Add-P "Mantener trazabilidad de la evolucion del prototipo: registro microSD, medicion energetica con INA219, transferencia BLE, resumen rapido y geolocalizacion GPS. Este documento consolida el estado al 15 de junio de 2026."

Add-P "2. Configuracion actual del prototipo" "Heading1"
Add-Table @(
    @("Bloque", "Configuracion"),
    @("Control principal", "ESP32-S3 DevKit N16R8"),
    @("Movimiento", "MPU6050 por I2C, direccion 0x68"),
    @("Energia", "INA219 por I2C, direccion 0x40; mide consumo despues del MT3608"),
    @("Almacenamiento", "microSD SPI: CS 10, MOSI 11, SCK 12, MISO 13"),
    @("GPS", "NEO-M9N/GY-GPS6MV2 por UART1: RX GPIO17, TX GPIO18, 38400 baudios"),
    @("BLE", "Field Viewer Android para perfil, inicio/detencion, descarga resumen y diagnostico"),
    @("Resumen rapido", "Archivo SMxxxxxx.CSV con muestra representativa cada 5 segundos")
) @(2600, 6800) $true

Add-P "3. Resultado V045 - energia y descarga BLE cruda" "Heading1"
Add-Table @(
    @("Metrica", "Resultado"),
    @("Archivo evaluado", "SS000008.CSV"),
    @("Duracion registrada", "3380.88 s / 56.35 min"),
    @("Filas guardadas", "26,615"),
    @("Tamano archivo", "2,793,548 bytes"),
    @("Tiempo descarga BLE", "35 minutos"),
    @("Velocidad BLE efectiva", "1.33 KB/s"),
    @("Captura efectiva estimada", "78.72% de muestras esperadas a 10 Hz"),
    @("Pausas SD", "93 marcadores #SD_GAP/#SD_RESUME"),
    @("Corriente promedio", "104.83 mA"),
    @("Corriente maxima", "160.8 mA"),
    @("Potencia promedio", "521.02 mW"),
    @("Consumo del test", "98.45 mAh despues del MT3608")
) @(3000, 6400) $true
Add-P "Conclusion V045: el archivo llego completo y cerrado, pero la descarga cruda por BLE no es viable como experiencia final. Ademas, la verificacion posterior a cada lote SD generaba pausas periodicas. El dato es valioso porque separa claramente uso de ingenieria y uso de producto." "Note"

Add-P "4. Decision V046 - resumen rapido" "Heading1"
Add-Table @(
    @("Cambio", "Motivo"),
    @("Elimina readback pesado por lote", "Priorizar continuidad de muestreo durante la sesion."),
    @("Validacion fuerte al cierre", "Confirmar integridad cuando ya no se esta midiendo en vivo."),
    @("Archivo SSxxxxxx.CSV", "Conserva telemetria cruda completa para ingenieria y respaldo."),
    @("Archivo SMxxxxxx.CSV", "Resumen liviano para descarga normal por BLE."),
    @("Field Viewer FIELD V0.3.35", "Boton principal descarga resumen rapido; CSV completo queda como diagnostico lento.")
) @(3000, 6400) $true

Add-P "5. Resultado GPS previo a integracion" "Heading1"
Add-Table @(
    @("Parametro", "Resultado confirmado"),
    @("Test", "SS-GPS-TEST-V002"),
    @("Baudios", "38400"),
    @("Fix quality", "1"),
    @("Satelites", "12"),
    @("HDOP", "0.92"),
    @("Latitud", "-12.120702"),
    @("Longitud", "-77.014175"),
    @("Velocidad", "0.10 km/h"),
    @("Estado", "Aprobado para integracion inicial")
) @(3000, 6400) $true

Add-P "6. Integracion V047" "Heading1"
Add-P "La V047 integra GPS dentro del firmware principal sin librerias externas, usando UART1 a 38400 baudios. Los datos GPS quedan disponibles en Serial JSON, STATUS?, CSV crudo y resumen rapido."
Add-Table @(
    @("Campo agregado", "Uso"),
    @("gps_status", "Indica FIX, NO_RECENT_FIX o NO_GPS_DATA."),
    @("gps_fix", "1 si hay posicion valida; 0 si no hay fix."),
    @("gps_sats", "Cantidad de satelites reportados por GGA."),
    @("gps_hdop", "Calidad geometrica de posicion; menor es mejor."),
    @("gps_lat/gps_lon", "Coordenada decimal para mapa y trazabilidad."),
    @("gps_speed_kmh", "Velocidad GPS estimada."),
    @("gps_course", "Rumbo GPS si esta disponible."),
    @("gps_age_ms", "Edad del ultimo fix; evita tratar coordenadas viejas como actuales.")
) @(3000, 6400) $true

Add-P "7. Prueba siguiente recomendada" "Heading1"
Add-Table @(
    @("Paso", "Accion"),
    @("1", "Cargar SS-LITE-BLE-SD-V1-047."),
    @("2", "Esperar GPS_STATUS=FIX o GPS_FIX=1."),
    @("3", "Iniciar sesion de 5 a 10 minutos con Field Viewer."),
    @("4", "Detener sesion."),
    @("5", "Descargar resumen rapido SM por BLE y medir tiempo."),
    @("6", "Revisar microSD para comparar SS crudo, SM resumen y cantidad de #SD_GAP."),
    @("7", "Si el resumen descarga rapido y el CSV crudo reduce pausas, V047 queda como base de campo.")
) @(1000, 8400) $true

Add-P "8. Criterio de producto" "Heading1"
Add-P "La descarga normal al salir del agua no debe ser el CSV crudo. La app debe recibir primero un resumen util: inicio, cierre, duracion, ubicacion, movimiento, energia, incidencias y trazabilidad GPS. El CSV completo queda para desarrollo, auditoria tecnica o descarga por otro canal mas rapido."

Add-P "9. Trazabilidad documental" "Heading1"
Add-Table @(
    @("Documento/archivo", "Estado"),
    @("SS-BITACORA-PRUEBAS-PROTOTIPO-V001.csv/xlsx", "Actualizado con V046 y V047."),
    @("SS-MAPA-MAESTRO-DOCUMENTAL-V001.csv/html/xlsx", "Regenerado para incluir documentos nuevos."),
    @("SaveSwimmer_Lite_BLE_Viewer_V047.ino", "Compilado correctamente."),
    @("PRUEBA_V047_GPS_SD_RESUMEN.txt", "Guia operativa creada."),
    @("SaveSwimmer_FieldViewer_FIELD_V0_3_35.apk", "App compilada con descarga de resumen rapido.")
) @(3600, 5800) $true

Add-Table @(
    @("Revision", "Fecha", "Descripcion", "Responsable"),
    @("V001", "26/05/2026", "Validacion microSD inicial con sesiones independientes.", "Save Swimmer / Victor Loza"),
    @("V002", "03/06/2026", "Actualiza direccion de apps, rotacion dorsal y base conceptual de seguridad.", "Save Swimmer / Victor Loza"),
    @("V003", "15/06/2026", "Agrega INA219, autonomia, cuello de botella BLE, resumen rapido V046 e integracion GPS V047.", "Save Swimmer / Victor Loza")
) @(1300, 1700, 4600, 1900) $true

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
  <w:style w:type="paragraph" w:styleId="Result"><w:name w:val="Result"/><w:pPr><w:spacing w:before="90" w:after="90"/><w:shd w:fill="D9F5EE"/></w:pPr><w:rPr><w:b/><w:sz w:val="22"/><w:color w:val="00765B"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="Note"><w:name w:val="Note"/><w:pPr><w:spacing w:before="90" w:after="90"/><w:shd w:fill="E6F7FB"/></w:pPr><w:rPr><w:sz w:val="19"/><w:color w:val="075873"/></w:rPr></w:style>
</w:styles>
'@

$footerXml = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:ftr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:p><w:pPr><w:jc w:val="center"/></w:pPr><w:r><w:rPr><w:sz w:val="16"/><w:color w:val="6A8790"/></w:rPr><w:t>Save Swimmer | Registro de prototipo | MicroSD, energia, BLE y GPS | V003</w:t></w:r></w:p>
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

if (Test-Path -LiteralPath $output) {
    Remove-Item -LiteralPath $output -Force
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($temp, $output)
Remove-Item -LiteralPath $temp -Recurse -Force

Write-Host "Creado: $output"
