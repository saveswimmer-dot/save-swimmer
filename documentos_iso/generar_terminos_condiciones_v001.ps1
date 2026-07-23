$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.IO.Compression.FileSystem

$baseDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$output = Join-Path $baseDir "SS-TERMINOS-CONDICIONES-SERVICIO-V001.docx"

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

function P($text, $style = "") {
    $styleXml = if ($style) { "<w:pPr><w:pStyle w:val=""$style""/></w:pPr>" } else { "" }
    return "<w:p>$styleXml<w:r><w:t xml:space=""preserve"">$(XmlText $text)</w:t></w:r></w:p>"
}

function Bullet($text) {
    return "<w:p><w:pPr><w:numPr><w:ilvl w:val=""0""/><w:numId w:val=""1""/></w:numPr></w:pPr><w:r><w:t xml:space=""preserve"">$(XmlText $text)</w:t></w:r></w:p>"
}

function SectionTitle($text) {
    return P $text "Heading1"
}

$paragraphs = New-Object System.Text.StringBuilder

[void]$paragraphs.Append((P "SAVE SWIMMER" "Title"))
[void]$paragraphs.Append((P "TERMINOS Y CONDICIONES DEL SERVICIO" "Subtitle"))
[void]$paragraphs.Append((P "Version: V001"))
[void]$paragraphs.Append((P "Fecha: 2026-06-04"))
[void]$paragraphs.Append((P "Estado: Borrador interno para etapa de prototipo y validacion. Requiere revision legal antes de uso comercial publico."))

[void]$paragraphs.Append((SectionTitle "1. Identificacion del servicio"))
[void]$paragraphs.Append((P "Save Swimmer es un sistema tecnologico orientado a seguridad contextual para nadadores de aguas abiertas. El ecosistema puede incluir dispositivo wearable, aplicaciones moviles, backend, panel interno, visualizacion de ubicacion, alertas, historiales y servicios asociados."))
[void]$paragraphs.Append((P "El servicio esta en etapa de prototipo, validacion y mejora continua. Las funciones disponibles pueden variar segun version del dispositivo, plan contratado, conectividad, sensores instalados, firmware, app y cobertura."))

[void]$paragraphs.Append((SectionTitle "2. Finalidad principal"))
[void]$paragraphs.Append((P "La finalidad principal de Save Swimmer es apoyar la seguridad, el seguimiento contextual y la reduccion del tiempo de respuesta ante posibles situaciones de riesgo en agua. Las funciones deportivas o tecnicas, como ritmo, rotacion dorsal, movimiento o historial, son complementarias y no reemplazan la finalidad de seguridad."))

[void]$paragraphs.Append((SectionTitle "3. Alcance y limites del servicio"))
[void]$paragraphs.Append((Bullet "Save Swimmer no garantiza rescate automatico, ubicacion perfecta ni prevencion absoluta de accidentes."))
[void]$paragraphs.Append((Bullet "La disponibilidad del servicio depende de bateria, conectividad, cobertura celular, funcionamiento del telefono gateway cuando aplique, sensores, estado del dispositivo y condiciones ambientales."))
[void]$paragraphs.Append((Bullet "El dispositivo y las apps no reemplazan supervisores, entrenadores, guardavidas, protocolos de seguridad, boya de seguridad, criterio personal ni normas locales."))
[void]$paragraphs.Append((Bullet "Las alertas deben interpretarse como apoyo operativo, no como diagnostico medico ni garantia de emergencia real."))

[void]$paragraphs.Append((SectionTitle "4. Uso del dispositivo"))
[void]$paragraphs.Append((P "El usuario debe usar el dispositivo conforme a las instrucciones tecnicas, carga, sellado, posicion recomendada y condiciones de uso indicadas por Save Swimmer. El uso incorrecto, manipulacion no autorizada, apertura del dispositivo, golpes, carga inadecuada o exposicion fuera de especificaciones puede afectar su funcionamiento."))

[void]$paragraphs.Append((SectionTitle "5. Membresia y activacion"))
[void]$paragraphs.Append((P "Algunas funciones requieren membresia activa, incluyendo seguimiento remoto, acceso familiar, Coach Live, alertas remotas, backend, historial cloud, soporte activo y servicios de conectividad cuando correspondan."))
[void]$paragraphs.Append((Bullet "Estado activo: el usuario mantiene acceso a funciones del plan contratado."))
[void]$paragraphs.Append((Bullet "Por vencer: el sistema puede avisar con anticipacion, por ejemplo 7 dias y 2 dias antes."))
[void]$paragraphs.Append((Bullet "Periodo de gracia: Save Swimmer podra otorgar un margen operativo despues del vencimiento, por ejemplo 3 dias para Lite y 5 a 7 dias para planes Pro o Coach."))
[void]$paragraphs.Append((Bullet "Suspendido: vencido el periodo de gracia, las funciones remotas podran suspenderse hasta regularizar el pago."))
[void]$paragraphs.Append((P "Las funciones locales de seguridad disponibles en el dispositivo, como identificacion, registro local o SOS local si existieran, no deberian quedar bloqueadas por falta de pago cuando tecnicamente sea posible mantenerlas activas."))

[void]$paragraphs.Append((SectionTitle "6. Pagos, comprobantes y datos fiscales"))
[void]$paragraphs.Append((P "La venta del dispositivo, accesorios y membresias podra generar boleta o factura segun corresponda. Save Swimmer podra solicitar datos fiscales, datos de contacto, DNI/RUC, correo, direccion y datos necesarios para comprobantes, soporte, activacion y control de membresia."))
[void]$paragraphs.Append((P "Los precios pueden incluir impuestos, comisiones de pasarela, costos de conectividad, backend, soporte, garantia y otros costos operativos. Los planes, precios y beneficios podran modificarse previa comunicacion segun politica comercial vigente."))

[void]$paragraphs.Append((SectionTitle "7. Aplicacion Atleta"))
[void]$paragraphs.Append((P "La app Atleta es la interfaz principal del usuario. Permite vincular dispositivo, iniciar o revisar sesiones, consultar historial, configurar contactos, administrar permisos, compartir sesiones y revisar informacion del plan. El historial deportivo y tecnico pertenece al atleta, salvo permisos otorgados a coach, familia u otros terceros."))

[void]$paragraphs.Append((SectionTitle "8. Aplicacion Familia"))
[void]$paragraphs.Append((P "La app Familia esta pensada como acceso simple y gratuito para contactos autorizados. Su objetivo es mostrar estado general, ultima senal, ubicacion autorizada, inicio o salida del agua y alertas. No esta orientada a datos tecnicos ni deportivos."))
[void]$paragraphs.Append((P "El atleta podra autorizar contactos familiares para recibir avisos automaticos cuando inicia una sesion, cuando sale del agua o cuando se genera una alerta."))

[void]$paragraphs.Append((SectionTitle "9. Aplicacion Coach"))
[void]$paragraphs.Append((P "La app Coach funciona como monitor de entrenamiento y seguridad. La version gratuita podra incluir alertas criticas y SOS siempre, ademas de visualizacion limitada de atletas autorizados. Las funciones Pro podran incluir grupos, historiales, reportes, geocercas, descargas y analisis avanzado."))
[void]$paragraphs.Append((P "El coach no adquiere propiedad sobre los datos historicos del atleta. El acceso a datos tecnicos, historiales o reportes dependera del permiso del atleta y del plan correspondiente."))

[void]$paragraphs.Append((SectionTitle "10. Contactos de emergencia"))
[void]$paragraphs.Append((P "Save Swimmer recomienda configurar al menos 2 contactos de emergencia y no mas de 5 para evitar dilucion de responsabilidad. El contacto principal debe ser una persona capaz de actuar o coordinar ayuda. En entrenamientos grupales, el coach o responsable de grupo puede ser considerado primer contacto operativo."))

[void]$paragraphs.Append((SectionTitle "11. Alertas, SOS y respuesta"))
[void]$paragraphs.Append((P "Las alertas pueden generarse por SOS manual, falta de avance, salida de zona, tiempo excedido, perdida de senal, patron anormal de movimiento u otros criterios futuros. Una alerta no confirma por si sola una emergencia real, pero debe ser tratada con prioridad segun contexto."))
[void]$paragraphs.Append((P "Save Swimmer no reemplaza a autoridades, servicios medicos, guardavidas ni protocolos de rescate. Cualquier integracion con autoridades requerira validacion, acuerdos y procesos formales."))

[void]$paragraphs.Append((SectionTitle "12. Datos recolectados"))
[void]$paragraphs.Append((P "Segun version y permisos, Save Swimmer puede recolectar o procesar datos como identificacion de usuario, serial del dispositivo, perfil deportivo, ubicacion, hora, sensores, movimiento, estado de agua, bateria, firmware, sesiones, alertas, contactos de emergencia, permisos, datos fiscales y registros de soporte."))
[void]$paragraphs.Append((P "Los datos se usaran para prestar el servicio, seguridad, soporte, mejora del producto, mantenimiento, facturacion, activacion de membresia, investigacion interna y cumplimiento legal cuando corresponda."))

[void]$paragraphs.Append((SectionTitle "13. Ubicacion y panel interno"))
[void]$paragraphs.Append((P "Save Swimmer podra contar con un panel interno para visualizar dispositivos activos, inactivos, ultima ubicacion conocida, ultima senal, estado de membresia, firmware, alertas y datos operativos necesarios para soporte y seguridad. El acceso interno debe ser limitado, justificado y auditable."))
[void]$paragraphs.Append((P "El usuario reconoce que la ubicacion y telemetria operativa pueden ser necesarias para prestar servicios de seguimiento, alertas, soporte y seguridad."))

[void]$paragraphs.Append((SectionTitle "14. Privacidad y permisos"))
[void]$paragraphs.Append((P "El atleta controla con quien comparte su informacion. Familia, coach u otros terceros solo podran acceder a datos autorizados. Algunos accesos podran ser temporales, por QR, enlace o invitacion."))
[void]$paragraphs.Append((P "Los datos fiscales, datos de seguridad, datos deportivos y datos operativos deberian mantenerse separados logicamente para reducir riesgos de privacidad y facilitar cumplimiento."))

[void]$paragraphs.Append((SectionTitle "15. Exportacion de datos"))
[void]$paragraphs.Append((P "Save Swimmer podra ofrecer exportaciones como resumen PDF, CSV tecnico o GPX cuando corresponda. La exportacion de datos crudos no sera necesariamente una funcion principal del producto y podra limitarse a soporte, beta, analisis tecnico o planes avanzados."))

[void]$paragraphs.Append((SectionTitle "16. Fallas, reclamos y bajas"))
[void]$paragraphs.Append((P "El usuario podra solicitar soporte por fallas, errores de lectura, problemas de conectividad, membresia, facturacion o dispositivo. Save Swimmer debera registrar reclamos, bajas, vencimientos, activaciones, cambios de plan y soporte asociado al serial del dispositivo."))
[void]$paragraphs.Append((P "La baja de membresia podra suspender funciones remotas al finalizar el periodo pagado y la gracia correspondiente. Algunas funciones locales podran mantenerse disponibles segun capacidad tecnica."))

[void]$paragraphs.Append((SectionTitle "17. Prototipos y pruebas"))
[void]$paragraphs.Append((P "Durante etapa de prueba, el usuario o tester reconoce que el producto puede presentar fallas, reinicios, errores de sensor, limitaciones de bateria, conectividad, precision o registro. Las pruebas deben realizarse bajo supervision y sin depender exclusivamente del dispositivo para seguridad personal."))

[void]$paragraphs.Append((SectionTitle "18. Actualizaciones"))
[void]$paragraphs.Append((P "Save Swimmer podra actualizar firmware, apps, backend, politicas, planes y funcionalidades para mejorar seguridad, estabilidad, compatibilidad o cumplimiento. Algunas funciones pueden modificarse, pausarse o reemplazarse durante la evolucion del producto."))

[void]$paragraphs.Append((SectionTitle "19. Aceptacion"))
[void]$paragraphs.Append((P "El uso del dispositivo, apps o servicios Save Swimmer implica aceptacion de estos terminos en su version vigente, sin perjuicio de documentos adicionales como autorizaciones de prueba, politicas de privacidad, garantias, contratos comerciales o consentimientos especificos."))

[void]$paragraphs.Append((SectionTitle "20. Nota legal"))
[void]$paragraphs.Append((P "Este documento es un borrador operativo inicial y no reemplaza asesoria legal. Antes de comercializar, publicar en tiendas, vender membresias o procesar datos personales a escala, debe ser revisado y adaptado por profesional legal competente en Peru y mercados objetivo."))

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("ss_docx_" + [guid]::NewGuid().ToString("N"))
$wordDir = Join-Path $tempRoot "word"
$relsDir = Join-Path $tempRoot "_rels"
$wordRelsDir = Join-Path $wordDir "_rels"
New-Item -ItemType Directory -Force -Path $wordDir, $relsDir, $wordRelsDir | Out-Null

WriteText (Join-Path $tempRoot "[Content_Types].xml") @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
  <Override PartName="/word/numbering.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.numbering+xml"/>
</Types>
"@

WriteText (Join-Path $relsDir ".rels") @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>
"@

WriteText (Join-Path $wordRelsDir "document.xml.rels") @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"/>
"@

WriteText (Join-Path $wordDir "styles.xml") @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/><w:rPr><w:sz w:val="22"/><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="Title"><w:name w:val="Title"/><w:rPr><w:b/><w:sz w:val="40"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="Subtitle"><w:name w:val="Subtitle"/><w:rPr><w:b/><w:color w:val="0AAED0"/><w:sz w:val="28"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="Heading1"><w:name w:val="heading 1"/><w:basedOn w:val="Normal"/><w:next w:val="Normal"/><w:rPr><w:b/><w:color w:val="0A5B73"/><w:sz w:val="28"/></w:rPr><w:pPr><w:spacing w:before="220" w:after="80"/></w:pPr></w:style>
</w:styles>
"@

WriteText (Join-Path $wordDir "numbering.xml") @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:numbering xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:abstractNum w:abstractNumId="0">
    <w:lvl w:ilvl="0"><w:start w:val="1"/><w:numFmt w:val="bullet"/><w:lvlText w:val="•"/><w:lvlJc w:val="left"/><w:pPr><w:ind w:left="720" w:hanging="360"/></w:pPr></w:lvl>
  </w:abstractNum>
  <w:num w:numId="1"><w:abstractNumId w:val="0"/></w:num>
</w:numbering>
"@

WriteText (Join-Path $wordDir "document.xml") @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    $paragraphs
    <w:sectPr><w:pgSz w:w="12240" w:h="15840"/><w:pgMar w:top="1440" w:right="1200" w:bottom="1440" w:left="1200"/></w:sectPr>
  </w:body>
</w:document>
"@

if (Test-Path $output) { Remove-Item -LiteralPath $output -Force }
[System.IO.Compression.ZipFile]::CreateFromDirectory($tempRoot, $output)
Remove-Item -LiteralPath $tempRoot -Recurse -Force
Write-Host "Creado: $output"
