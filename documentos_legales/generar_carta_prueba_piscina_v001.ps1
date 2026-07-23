$ErrorActionPreference = "Stop"

$baseDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$outPath = Join-Path $baseDir "SS-CARTA-SOLICITUD-PRUEBA-PISCINA-V001.docx"
$tmpRoot = Join-Path $baseDir "_tmp_docx_piscina_v001"
$logoSrc = Join-Path (Split-Path -Parent $baseDir) "android\SaveSwimmerFieldViewer\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png"

if (Test-Path $tmpRoot) {
  Remove-Item -LiteralPath $tmpRoot -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $tmpRoot | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $tmpRoot "_rels") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $tmpRoot "word") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $tmpRoot "word\_rels") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $tmpRoot "word\media") | Out-Null

Copy-Item -LiteralPath $logoSrc -Destination (Join-Path $tmpRoot "word\media\logo.png") -Force

$contentTypes = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Default Extension="png" ContentType="image/png"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
</Types>
'@

$rels = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>
'@

$docRels = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rIdLogo" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/logo.png"/>
</Relationships>
'@

$styles = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:style w:type="paragraph" w:default="1" w:styleId="Normal">
    <w:name w:val="Normal"/>
    <w:qFormat/>
    <w:rPr>
      <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/>
      <w:sz w:val="22"/>
      <w:color w:val="1F2933"/>
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="TitleSS">
    <w:name w:val="Save Swimmer Title"/>
    <w:qFormat/>
    <w:pPr><w:spacing w:after="60"/></w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/>
      <w:b/>
      <w:sz w:val="32"/>
      <w:color w:val="0B2530"/>
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="HeadingSS">
    <w:name w:val="Save Swimmer Heading"/>
    <w:qFormat/>
    <w:pPr><w:spacing w:before="160" w:after="80"/></w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/>
      <w:b/>
      <w:sz w:val="24"/>
      <w:color w:val="00A8C8"/>
    </w:rPr>
  </w:style>
</w:styles>
'@

function P([string]$text, [string]$style = "") {
  $escaped = [System.Security.SecurityElement]::Escape($text)
  $styleXml = ""
  if ($style.Length -gt 0) {
    $styleXml = "<w:pPr><w:pStyle w:val=`"$style`"/></w:pPr>"
  }
  return "<w:p>$styleXml<w:r><w:t xml:space=`"preserve`">$escaped</w:t></w:r></w:p>"
}

function Bullet([string]$text) {
  $escaped = [System.Security.SecurityElement]::Escape($text)
  return "<w:p><w:pPr><w:ind w:left=`"420`" w:hanging=`"220`"/></w:pPr><w:r><w:t xml:space=`"preserve`">• $escaped</w:t></w:r></w:p>"
}

function Signature([string]$label) {
  $escaped = [System.Security.SecurityElement]::Escape($label)
  return "<w:p><w:pPr><w:spacing w:before=`"260`" w:after=`"0`"/></w:pPr><w:r><w:t>________________________________________</w:t></w:r></w:p><w:p><w:r><w:t>$escaped</w:t></w:r></w:p>"
}

$logoDrawing = @'
<w:r>
  <w:drawing>
    <wp:inline distT="0" distB="0" distL="0" distR="0" xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing">
      <wp:extent cx="720000" cy="720000"/>
      <wp:effectExtent l="0" t="0" r="0" b="0"/>
      <wp:docPr id="1" name="Save Swimmer Logo"/>
      <wp:cNvGraphicFramePr>
        <a:graphicFrameLocks noChangeAspect="1" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"/>
      </wp:cNvGraphicFramePr>
      <a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">
        <a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">
          <pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">
            <pic:nvPicPr><pic:cNvPr id="0" name="logo.png"/><pic:cNvPicPr/></pic:nvPicPr>
            <pic:blipFill><a:blip r:embed="rIdLogo"/><a:stretch><a:fillRect/></a:stretch></pic:blipFill>
            <pic:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="720000" cy="720000"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></pic:spPr>
          </pic:pic>
        </a:graphicData>
      </a:graphic>
    </wp:inline>
  </w:drawing>
</w:r>
'@

$body = ""
$body += "<w:p><w:pPr><w:spacing w:after=`"80`"/></w:pPr>$logoDrawing<w:r><w:t xml:space=`"preserve`">   </w:t></w:r><w:r><w:rPr><w:b/><w:sz w:val=`"34`"/><w:color w:val=`"0B2530`"/></w:rPr><w:t>SAVE SWIMMER</w:t></w:r><w:r><w:br/><w:t xml:space=`"preserve`">   Seguridad conectada para aguas abiertas</w:t></w:r></w:p>"
$body += "<w:p><w:pPr><w:pBdr><w:bottom w:val=`"single`" w:sz=`"8`" w:space=`"8`" w:color=`"00A8C8`"/></w:pBdr><w:spacing w:after=`"240`"/></w:pPr></w:p>"

$body += P "Lima, ____ de __________________ de 2026"
$body += P "Señores:"
$body += P "Administración / Coordinación de piscina o club"
$body += P "Presente.-"
$body += P "Asunto: Solicitud de autorización para prueba controlada de prototipo Save Swimmer" "TitleSS"

$body += P "De mi consideración:"
$body += P "Por medio de la presente, me dirijo a ustedes en calidad de responsable del proyecto Save Swimmer, actualmente en etapa de investigación, desarrollo y validación técnica de un dispositivo dorsal orientado al registro de movimiento y seguridad contextual para nadadores."
$body += P "Solicito autorización para realizar una prueba controlada dentro de sus instalaciones, con un nadador voluntario previamente informado, durante una sesión de nado normal y sin interferir con el funcionamiento regular de la piscina."

$body += P "Descripción de la prueba" "HeadingSS"
$body += P "La prueba consiste en colocar un prototipo en la espalda alta del nadador, entre las escápulas, con el objetivo de registrar datos de movimiento corporal y comportamiento del dispositivo durante el nado. El equipo opera con batería interna, sin cables externos durante el uso."
$body += Bullet "No se registrará audio."
$body += Bullet "No se registrará video, salvo autorización expresa y separada."
$body += Bullet "No se tomarán datos de terceros."
$body += Bullet "No se modificará la operación normal de la piscina."
$body += Bullet "La prueba no reemplaza supervisión, normas internas, salvavidas ni protocolos de seguridad de la instalación."

$body += P "Datos técnicos que podrían registrarse" "HeadingSS"
$body += Bullet "Movimiento corporal: aceleración, orientación, rotación, magnitud y patrones derivados."
$body += Bullet "Energía del prototipo: voltaje, corriente y consumo estimado."
$body += Bullet "Identificación básica de sesión: nombre o código del participante, fecha, hora y modo de prueba."
$body += Bullet "Ubicación GPS solo si aplica y si la prueba lo requiere."

$body += P "Condiciones de seguridad y responsabilidad" "HeadingSS"
$body += P "El prototipo se encuentra en etapa experimental y puede presentar fallas, pérdida de datos o lecturas incorrectas. Su finalidad durante esta prueba es exclusivamente técnica y de validación. Save Swimmer no solicitará a la instalación asumir responsabilidad por el desempeño técnico del dispositivo."
$body += P "El participante voluntario firmará una autorización de toma de datos y será informado previamente sobre el alcance de la prueba. En caso de tratarse de un menor de edad, se requerirá autorización de madre, padre o apoderado."

$body += P "Solicitud" "HeadingSS"
$body += P "Solicito se sirvan autorizar una prueba controlada en fecha y horario a coordinar, bajo las condiciones que la administración considere pertinentes."
$body += P "Agradezco de antemano su atención y quedo a disposición para ampliar información técnica del prototipo o adecuarme a sus procedimientos internos."

$body += P "Atentamente,"
$body += Signature "Victor Loza"
$body += P "Responsable del proyecto Save Swimmer"
$body += P "Correo: saveswimmer@gmail.com"
$body += P "Redes: @saveswimmer"

$body += "<w:p><w:pPr><w:pBdr><w:top w:val=`"single`" w:sz=`"6`" w:space=`"8`" w:color=`"D9E2E8`"/></w:pBdr><w:spacing w:before=`"260`"/></w:pPr></w:p>"
$body += P "Uso interno Save Swimmer" "HeadingSS"
$body += P "Documento: SS-CARTA-SOLICITUD-PRUEBA-PISCINA-V001"
$body += P "Versión: V001"
$body += P "Fecha de emisión: 01/07/2026"
$body += P "Proyecto: Save Swimmer Lite / etapa prototipo"

$document = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:wpc="http://schemas.microsoft.com/office/word/2010/wordprocessingCanvas"
  xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
  xmlns:o="urn:schemas-microsoft-com:office:office"
  xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
  xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math"
  xmlns:v="urn:schemas-microsoft-com:vml"
  xmlns:wp14="http://schemas.microsoft.com/office/word/2010/wordprocessingDrawing"
  xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
  xmlns:w10="urn:schemas-microsoft-com:office:word"
  xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
  xmlns:w14="http://schemas.microsoft.com/office/word/2010/wordml"
  xmlns:wpg="http://schemas.microsoft.com/office/word/2010/wordprocessingGroup"
  xmlns:wpi="http://schemas.microsoft.com/office/word/2010/wordprocessingInk"
  xmlns:wne="http://schemas.microsoft.com/office/word/2006/wordml"
  xmlns:wps="http://schemas.microsoft.com/office/word/2010/wordprocessingShape"
  mc:Ignorable="w14 wp14">
  <w:body>
    $body
    <w:sectPr>
      <w:pgSz w:w="12240" w:h="15840"/>
      <w:pgMar w:top="1080" w:right="1080" w:bottom="1080" w:left="1080" w:header="720" w:footer="720" w:gutter="0"/>
      <w:cols w:space="720"/>
      <w:docGrid w:linePitch="360"/>
    </w:sectPr>
  </w:body>
</w:document>
"@

Set-Content -LiteralPath (Join-Path $tmpRoot "[Content_Types].xml") -Value $contentTypes -Encoding UTF8
Set-Content -LiteralPath (Join-Path $tmpRoot "_rels\.rels") -Value $rels -Encoding UTF8
Set-Content -LiteralPath (Join-Path $tmpRoot "word\_rels\document.xml.rels") -Value $docRels -Encoding UTF8
Set-Content -LiteralPath (Join-Path $tmpRoot "word\styles.xml") -Value $styles -Encoding UTF8
Set-Content -LiteralPath (Join-Path $tmpRoot "word\document.xml") -Value $document -Encoding UTF8

if (Test-Path $outPath) {
  Remove-Item -LiteralPath $outPath -Force
}

$zipPath = "$outPath.zip"
if (Test-Path $zipPath) {
  Remove-Item -LiteralPath $zipPath -Force
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($tmpRoot, $zipPath)
Move-Item -LiteralPath $zipPath -Destination $outPath -Force
Remove-Item -LiteralPath $tmpRoot -Recurse -Force

Write-Host $outPath
