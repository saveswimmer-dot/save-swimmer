Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$outDir = Join-Path $root "campana_financiamiento"
$output = Join-Path $outDir "post_avance_plin_1080x1080_v002.png"
$copyOut = Join-Path $outDir "post_avance_plin_copy_v001.txt"
$logoPath = "C:\Users\Claudia\Desktop\ss png.png"
$photoPath = "C:\Users\Claudia\Downloads\WhatsApp Image 2026-05-28 at 4.26.39 PM.jpeg"

$W = 1080
$H = 1080
$bmp = New-Object System.Drawing.Bitmap $W, $H
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

function Brush($hex) {
  return New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml($hex))
}

function PenC($hex, $w = 1) {
  return New-Object System.Drawing.Pen ([System.Drawing.ColorTranslator]::FromHtml($hex)), $w
}

function FontS($name, $size, $style = [System.Drawing.FontStyle]::Regular) {
  return New-Object System.Drawing.Font($name, $size, $style, [System.Drawing.GraphicsUnit]::Pixel)
}

function Draw-RoundedRect($graphics, $brush, $x, $y, $w, $h, $r) {
  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $d = $r * 2
  $path.AddArc($x, $y, $d, $d, 180, 90)
  $path.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
  $path.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
  $path.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
  $path.CloseFigure()
  $graphics.FillPath($brush, $path)
  $path.Dispose()
}

function Draw-Text($graphics, $text, $font, $brush, $x, $y, $w, $h, $align = "Near") {
  $sf = New-Object System.Drawing.StringFormat
  $sf.Alignment = [System.Drawing.StringAlignment]::$align
  $sf.LineAlignment = [System.Drawing.StringAlignment]::Near
  $sf.Trimming = [System.Drawing.StringTrimming]::EllipsisWord
  $rect = New-Object System.Drawing.RectangleF($x, $y, $w, $h)
  $graphics.DrawString($text, $font, $brush, $rect, $sf)
  $sf.Dispose()
}

function Draw-CoverImage($graphics, $image, $x, $y, $w, $h) {
  $srcRatio = $image.Width / [double]$image.Height
  $dstRatio = $w / [double]$h
  if ($srcRatio -gt $dstRatio) {
    $srcH = $image.Height
    $srcW = [int]($srcH * $dstRatio)
    $srcX = [int](($image.Width - $srcW) / 2)
    $srcY = 0
  } else {
    $srcW = $image.Width
    $srcH = [int]($srcW / $dstRatio)
    $srcX = 0
    $srcY = [int](($image.Height - $srcH) / 2)
  }
  $src = New-Object System.Drawing.Rectangle($srcX, $srcY, $srcW, $srcH)
  $dst = New-Object System.Drawing.Rectangle($x, $y, $w, $h)
  $graphics.DrawImage($image, $dst, $src, [System.Drawing.GraphicsUnit]::Pixel)
}

$bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
  (New-Object System.Drawing.Point(0, 0)),
  (New-Object System.Drawing.Point($W, $H)),
  ([System.Drawing.ColorTranslator]::FromHtml("#041017")),
  ([System.Drawing.ColorTranslator]::FromHtml("#082532"))
)
$g.FillRectangle($bg, 0, 0, $W, $H)
$bg.Dispose()

$cyan = Brush "#2fd3e6"
$cyanDark = Brush "#0b2f3b"
$white = Brush "#f4fbff"
$muted = Brush "#a8bcc4"
$orange = Brush "#ff6a00"
$green = Brush "#5fe08b"
$card = Brush "#0d2a35"
$card2 = Brush "#071d25"
$linePen = New-Object System.Drawing.Pen ([System.Drawing.ColorTranslator]::FromHtml("#1f5663")), 2

if (Test-Path $logoPath) {
  $logo = [System.Drawing.Image]::FromFile($logoPath)
  $g.DrawImage($logo, 52, 48, 92, 92)
  $logo.Dispose()
}

$fontBrand = FontS "Arial" 48 ([System.Drawing.FontStyle]::Bold)
$fontSub = FontS "Arial" 22 ([System.Drawing.FontStyle]::Regular)
$fontBig = FontS "Arial" 58 ([System.Drawing.FontStyle]::Bold)
$fontMid = FontS "Arial" 31 ([System.Drawing.FontStyle]::Bold)
$fontText = FontS "Arial" 24 ([System.Drawing.FontStyle]::Regular)
$fontSmall = FontS "Arial" 19 ([System.Drawing.FontStyle]::Regular)
$fontTiny = FontS "Arial" 17 ([System.Drawing.FontStyle]::Regular)

Draw-Text $g "SAVE SWIMMER" $fontBrand $white 165 52 850 58
Draw-Text $g "seguridad conectada para aguas abiertas" $fontSub $cyan 168 112 820 35

Draw-Text $g "Prototipo real" $fontBig $white 52 195 520 68
Draw-Text $g "en pruebas" $fontBig $white 52 255 520 76
Draw-Text $g "Ya estamos validando movimiento, microSD, BLE, app movil y vista Coach Live." $fontText $muted 56 340 500 82

Draw-RoundedRect $g (Brush "#0a1d25") 610 58 420 355 18
if (Test-Path $photoPath) {
  $photo = [System.Drawing.Image]::FromFile($photoPath)
  Draw-CoverImage $g $photo 628 76 384 319
  $photo.Dispose()
}
$photoPen = New-Object System.Drawing.Pen ([System.Drawing.ColorTranslator]::FromHtml("#2fd3e6")), 3
$g.DrawRectangle($photoPen, 628, 76, 384, 319)
$photoPen.Dispose()

Draw-RoundedRect $g $card 50 460 980 318 18
Draw-Text $g "AVANCE ACTUAL" (FontS "Arial" 24 ([System.Drawing.FontStyle]::Bold)) $cyan 78 488 400 35

$items = @(
  @("App BLE", "datos en vivo desde ESP32"),
  @("microSD", "sesiones reales registradas"),
  @("Coach Live", "ubicacion + lectura remota"),
  @("Rotacion dorsal", "grafico en grados para tecnica"),
  @("Siguiente etapa", "GPS, sensor de agua y carcasa")
)

$y = 538
foreach ($it in $items) {
  $g.FillEllipse($green, 82, $y + 7, 13, 13)
  Draw-Text $g $it[0] (FontS "Arial" 25 ([System.Drawing.FontStyle]::Bold)) $white 112 $y 260 32
  Draw-Text $g $it[1] $fontSmall $muted 382 ($y + 2) 570 30
  $y += 43
}

Draw-RoundedRect $g $card2 50 810 980 190 18
Draw-Text $g "APOYA EL DESARROLLO" (FontS "Arial" 27 ([System.Drawing.FontStyle]::Bold)) $white 78 836 500 38
Draw-Text $g "Aporte por Plin" $fontText $muted 78 880 280 36
Draw-Text $g "903 338 442" (FontS "Arial" 58 ([System.Drawing.FontStyle]::Bold)) $cyan 78 915 520 70

Draw-RoundedRect $g $orange 676 852 285 84 12
Draw-Text $g "PLIN" (FontS "Arial" 42 ([System.Drawing.FontStyle]::Bold)) $white 676 870 285 55 "Center"
Draw-Text $g "Tambien puedes apoyar en StartFund: Save Swimmer" $fontTiny $muted 78 978 820 28

$g.DrawLine($linePen, 50, 792, 1030, 792)

$bmp.Save($output, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$bmp.Dispose()

$copy = @"
Save Swimmer sigue avanzando.

Estamos desarrollando en Peru un prototipo de seguridad para nadadores de aguas abiertas. Ya estamos probando lectura corporal, registro en microSD, conexion BLE, app movil y una vista Coach Live para monitoreo.

Cada aporte ayuda a comprar modulos, sensores, baterias, materiales de carcasa y seguir haciendo pruebas reales.

Aporte por Plin: 903 338 442
Campana StartFund: https://startfund.pe/proyectos/save-swimmer-seguridad-para-nadadores-de-aguas-abiertas.php

Gracias por apoyar tecnologia hecha desde cero para cuidar a quienes nadan en aguas abiertas.
"@

Set-Content -LiteralPath $copyOut -Value $copy -Encoding UTF8

Write-Host "Imagen creada: $output"
Write-Host "Copy creado: $copyOut"
