$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$baseDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent $baseDir
$photoPath = "C:\Users\Claudia\Downloads\WhatsApp Image 2026-06-17 at 5.37.05 PM (1).jpeg"
$mapPath = Join-Path $rootDir "assets\costa_verde_agua_dulce.jpg"
$logoPath = Join-Path $rootDir "android\SaveSwimmerFieldViewer\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png"
$outPath = Join-Path $baseDir "SS-POST-TELEMETRIA-EN-VIVO-V008.png"
$copyPath = Join-Path $baseDir "SS-POST-TELEMETRIA-EN-VIVO-COPY-V008.txt"

if (!(Test-Path $photoPath)) { throw "No encontre la foto base: $photoPath" }
if (!(Test-Path $mapPath)) { throw "No encontre el mapa base: $mapPath" }
if (!(Test-Path $logoPath)) { throw "No encontre el logo: $logoPath" }

function U([string]$text) {
  $pairs = @(
    @("{a_}", [string][char]0x00E1), @("{e_}", [string][char]0x00E9),
    @("{i_}", [string][char]0x00ED), @("{o_}", [string][char]0x00F3),
    @("{u_}", [string][char]0x00FA), @("{n_}", [string][char]0x00F1),
    @("{A_}", [string][char]0x00C1), @("{E_}", [string][char]0x00C9),
    @("{I_}", [string][char]0x00CD), @("{O_}", [string][char]0x00D3),
    @("{U_}", [string][char]0x00DA), @("{N_}", [string][char]0x00D1)
  )
  foreach ($pair in $pairs) { $text = $text.Replace($pair[0], $pair[1]) }
  return $text
}

function SaveUtf8Bom([string]$path, [string]$content) {
  [System.IO.File]::WriteAllText($path, (U $content), (New-Object System.Text.UTF8Encoding($true)))
}

function BrushC([string]$hex) {
  return New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml($hex))
}

function BrushA([string]$hex, [int]$alpha) {
  $c = [System.Drawing.ColorTranslator]::FromHtml($hex)
  return New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb($alpha, $c.R, $c.G, $c.B))
}

function PenC([string]$hex, [float]$width) {
  $p = New-Object System.Drawing.Pen ([System.Drawing.ColorTranslator]::FromHtml($hex), $width)
  $p.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $p.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
  return $p
}

function PenA([string]$hex, [int]$alpha, [float]$width) {
  $c = [System.Drawing.ColorTranslator]::FromHtml($hex)
  $p = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb($alpha, $c.R, $c.G, $c.B), $width)
  $p.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $p.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
  return $p
}

function FontC([float]$size, [System.Drawing.FontStyle]$style = [System.Drawing.FontStyle]::Regular) {
  return New-Object System.Drawing.Font("Arial", $size, $style, [System.Drawing.GraphicsUnit]::Pixel)
}

function DrawText($graphics, [string]$text, [float]$size, [string]$color, [float]$x, [float]$y, [System.Drawing.FontStyle]$style = [System.Drawing.FontStyle]::Regular) {
  $graphics.DrawString((U $text), (FontC $size $style), (BrushC $color), $x, $y)
}

function FillRound($graphics, $brush, [float]$x, [float]$y, [float]$width, [float]$height, [float]$radius) {
  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $d = $radius * 2
  $path.AddArc($x, $y, $d, $d, 180, 90)
  $path.AddArc($x + $width - $d, $y, $d, $d, 270, 90)
  $path.AddArc($x + $width - $d, $y + $height - $d, $d, $d, 0, 90)
  $path.AddArc($x, $y + $height - $d, $d, $d, 90, 90)
  $path.CloseFigure()
  $graphics.FillPath($brush, $path)
  $path.Dispose()
}

function DrawRound($graphics, $pen, [float]$x, [float]$y, [float]$width, [float]$height, [float]$radius) {
  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $d = $radius * 2
  $path.AddArc($x, $y, $d, $d, 180, 90)
  $path.AddArc($x + $width - $d, $y, $d, $d, 270, 90)
  $path.AddArc($x + $width - $d, $y + $height - $d, $d, $d, 0, 90)
  $path.AddArc($x, $y + $height - $d, $d, $d, 90, 90)
  $path.CloseFigure()
  $graphics.DrawPath($pen, $path)
  $path.Dispose()
}

function DrawImageCover($graphics, [System.Drawing.Image]$img, [int]$x, [int]$y, [int]$width, [int]$height) {
  $targetRatio = $width / $height
  $srcRatio = $img.Width / $img.Height
  if ($srcRatio -gt $targetRatio) {
    $cropH = $img.Height
    $cropW = [int]($img.Height * $targetRatio)
    $cropX = [int](($img.Width - $cropW) / 2)
    $cropY = 0
  } else {
    $cropW = $img.Width
    $cropH = [int]($img.Width / $targetRatio)
    $cropX = 0
    $cropY = [int](($img.Height - $cropH) / 2)
  }
  $srcRect = New-Object System.Drawing.Rectangle $cropX, $cropY, $cropW, $cropH
  $dstRect = New-Object System.Drawing.Rectangle $x, $y, $width, $height
  $graphics.DrawImage($img, $dstRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
}

function DrawPhone($graphics, [int]$x, [int]$y, [int]$w, [int]$h, [string]$title) {
  FillRound $graphics (BrushC "#050B10") $x $y $w $h 42
  DrawRound $graphics (PenA "#B8C8D0" 120 4) $x $y $w $h 42
  FillRound $graphics (BrushC "#071B25") ($x + 18) ($y + 26) ($w - 36) ($h - 52) 25
  FillRound $graphics (BrushC "#020A0F") ($x + [int]($w / 2) - 58) ($y + 14) 116 22 11
  DrawText $graphics $title 22 "#F4FAFC" ($x + 42) ($y + 48) ([System.Drawing.FontStyle]::Bold)
}

function DrawTinyMetric($graphics, [string]$label, [string]$value, [int]$x, [int]$y, [int]$w) {
  FillRound $graphics (BrushA "#0B2C3A" 235) $x $y $w 76 8
  DrawText $graphics $label 13 "#A8BBC2" ($x + 14) ($y + 12)
  DrawText $graphics $value 23 "#F4FAFC" ($x + 14) ($y + 38) ([System.Drawing.FontStyle]::Bold)
}

$W = 1920
$H = 1080
$bmp = New-Object System.Drawing.Bitmap $W, $H
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

$white = "#F4FAFC"
$cyan = "#2ED8EA"
$orange = "#FF6A00"
$muted = "#A8BBC2"
$green = "#55E69A"

$bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
  (New-Object System.Drawing.Rectangle 0, 0, $W, $H),
  [System.Drawing.ColorTranslator]::FromHtml("#02070C"),
  [System.Drawing.ColorTranslator]::FromHtml("#082A3A"),
  25
)
$g.FillRectangle($bg, 0, 0, $W, $H)

$photo = [System.Drawing.Image]::FromFile($photoPath)
DrawImageCover $g $photo 0 330 780 520
$photo.Dispose()
$g.FillRectangle((BrushA "#02070C" 112), 0, 330, 780, 520)

$logo = [System.Drawing.Image]::FromFile($logoPath)
$g.DrawImage($logo, 62, 58, 76, 76)
$logo.Dispose()

DrawText $g "TELEMETR{I_}A" 86 $white 154 48 ([System.Drawing.FontStyle]::Bold)
DrawText $g "EN VIVO" 86 $cyan 650 48 ([System.Drawing.FontStyle]::Bold)
DrawText $g "Prototipo Save Swimmer en desarrollo" 40 $white 70 155
$g.DrawLine((PenC $cyan 5), 75, 220, 165, 220)

DrawText $g "UBICACI{O_}N" 20 $white 154 278 ([System.Drawing.FontStyle]::Bold)
DrawText $g "EN TIEMPO REAL" 20 $white 154 305
DrawText $g "MONITOREO" 20 $white 400 278 ([System.Drawing.FontStyle]::Bold)
DrawText $g "DE MOVIMIENTO" 20 $white 400 305
DrawText $g "SEGURIDAD" 20 $white 650 278 ([System.Drawing.FontStyle]::Bold)
DrawText $g "CONECTADA" 20 $white 650 305
$g.DrawEllipse((PenC $cyan 6), 78, 272, 50, 50)
$g.DrawLine((PenC $cyan 5), 103, 286, 103, 306)
$g.DrawEllipse((PenC $cyan 3), 94, 284, 18, 18)
$g.DrawEllipse((PenC $cyan 5), 326, 272, 54, 54)
$g.DrawLine((PenC $cyan 4), 337, 299, 349, 299)
$g.DrawLine((PenC $cyan 4), 349, 299, 356, 285)
$g.DrawLine((PenC $cyan 4), 356, 285, 367, 313)
$g.DrawLine((PenC $cyan 4), 367, 313, 374, 299)
$shield = New-Object System.Drawing.Drawing2D.GraphicsPath
$shield.AddPolygon(@(
  (New-Object System.Drawing.Point 586,270),
  (New-Object System.Drawing.Point 622,284),
  (New-Object System.Drawing.Point 622,318),
  (New-Object System.Drawing.Point 586,338),
  (New-Object System.Drawing.Point 550,318),
  (New-Object System.Drawing.Point 550,284)
))
$g.DrawPath((PenC $orange 6), $shield)
$shield.Dispose()

FillRound $g (BrushA "#071B25" 220) 130 720 420 120 14
DrawText $g "DISPOSITIVO PROTOTIPO" 20 $orange 160 748 ([System.Drawing.FontStyle]::Bold)
DrawText $g "M{O_}dulo dorsal de prueba" 22 $white 160 778
DrawText $g "GPS + sensores + microSD" 22 $white 160 808
$g.DrawLine((PenC $orange 4), 265, 720, 265, 672)
$g.FillEllipse((BrushC $orange), 257, 662, 16, 16)

$sigPen = PenA $cyan 210 4
$sigPen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
$g.DrawBezier($sigPen, 620, 560, 790, 520, 875, 530, 970, 585)
$g.DrawArc((PenC $cyan 4), 940, 535, 70, 85, -45, 90)
$g.DrawArc((PenC $cyan 4), 970, 515, 100, 125, -45, 90)
$g.DrawArc((PenC $orange 4), 1265, 555, 70, 85, -45, 90)
$g.DrawArc((PenC $orange 4), 1295, 535, 100, 125, -45, 90)

DrawPhone $g 900 285 280 535 "GATEWAY ACTIVO"
$cx = 1040
$cy = 525
$g.DrawEllipse((PenA $cyan 80 2), $cx - 92, $cy - 92, 184, 184)
$g.DrawEllipse((PenA $cyan 120 2), $cx - 62, $cy - 62, 124, 124)
$g.DrawEllipse((PenC $cyan 3), $cx - 35, $cy - 35, 70, 70)
DrawText $g "Bluetooth" 26 $cyan 985 508 ([System.Drawing.FontStyle]::Bold)
DrawText $g "Enviando datos..." 19 $muted 973 650
$g.FillEllipse((BrushC $green), 982, 722, 12, 12)
DrawText $g "Se{n_}al estable" 16 $white 1002 718
DrawText $g "TEL{E_}FONO GATEWAY" 21 $cyan 900 852 ([System.Drawing.FontStyle]::Bold)
DrawText $g "Recibe datos por Bluetooth" 21 $white 900 882
DrawText $g "y los env{i_}a por datos m{o_}viles" 21 $white 900 912
$g.DrawLine((PenC $cyan 3), 1040, 820, 1040, 848)

DrawPhone $g 1330 110 410 740 "COACH EN VIVO"
FillRound $g (BrushA "#07131C" 255) 1370 188 330 66 8
DrawText $g "ATLETA ACTIVO" 13 $muted 1390 202
DrawText $g "Demo Agua Dulce" 21 $white 1390 226 ([System.Drawing.FontStyle]::Bold)
FillRound $g (BrushA "#07131C" 255) 1370 270 330 224 10
$map = [System.Drawing.Image]::FromFile($mapPath)
DrawImageCover $g $map 1382 282 306 200
$map.Dispose()
$g.FillRectangle((BrushA "#042030" 86), 1382, 282, 306, 200)
$route = PenC $cyan 6
$g.DrawBezier($route, 1410, 440, 1460, 385, 1530, 360, 1660, 315)
$g.FillEllipse((BrushC $green), 1400, 430, 22, 22)
$g.FillEllipse((BrushC $orange), 1650, 304, 22, 22)
DrawTinyMetric $g "DISTANCIA" "2.48 km" 1370 512 156
DrawTinyMetric $g "VELOCIDAD" "1.62 m/s" 1544 512 156
DrawTinyMetric $g "MOVIMIENTO" "Nataci{o_}n" 1370 606 156
DrawTinyMetric $g "ESTADO" "Normal" 1544 606 156
FillRound $g (BrushA "#07131C" 255) 1370 700 330 104 8
DrawText $g "MOVIMIENTO CORPORAL" 13 $muted 1390 712
$graphPen1 = PenC $cyan 3
$graphPen2 = PenC $orange 3
for ($i = 0; $i -lt 10; $i++) {
  $x1 = 1392 + ($i * 30)
  $x2 = 1392 + (($i + 1) * 30)
  $y1 = 760 + [math]::Sin($i * 1.2) * 23
  $y2 = 760 + [math]::Sin(($i + 1) * 1.2) * 23
  $g.DrawLine($graphPen1, $x1, $y1, $x2, $y2)
  $g.DrawLine($graphPen2, $x1, 768 + [math]::Cos($i * 1.4) * 8, $x2, 768 + [math]::Cos(($i + 1) * 1.4) * 8)
}
DrawText $g "DASHBOARD ENTRENADOR" 21 $orange 1356 882 ([System.Drawing.FontStyle]::Bold)
DrawText $g "Visualizaci{o_}n en tiempo real" 21 $white 1356 912
DrawText $g "desde cualquier lugar" 21 $white 1356 942
$g.DrawLine((PenC $orange 3), 1536, 852, 1536, 880)

FillRound $g (BrushA "#061D28" 235) 355 965 1210 70 14
DrawRound $g (PenA "#B8C8D0" 85 2) 355 965 1210 70 14
DrawText $g "MAYOR" 23 "#A8BBC2" 472 992 ([System.Drawing.FontStyle]::Bold)
DrawText $g "SEGURIDAD." 23 $cyan 555 992 ([System.Drawing.FontStyle]::Bold)
DrawText $g "M{A_}S" 23 "#A8BBC2" 705 992 ([System.Drawing.FontStyle]::Bold)
DrawText $g "CONEXI{O_}N." 23 $cyan 758 992 ([System.Drawing.FontStyle]::Bold)
DrawText $g "MEJOR ACOMPA{N_}AMIENTO." 23 "#A8BBC2" 910 992 ([System.Drawing.FontStyle]::Bold)
DrawText $g "Probamos hoy para proteger ma{n_}ana." 20 $white 1242 985 ([System.Drawing.FontStyle]::Bold)
DrawText $g "Save Swimmer" 21 $cyan 1242 1010 ([System.Drawing.FontStyle]::Bold)

$bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$bmp.Dispose()

$copy = @"
Save Swimmer sigue avanzando.

Estamos probando telemetr{i_}a en vivo: un prototipo dorsal registra movimiento y ubicaci{o_}n, el tel{e_}fono gateway recibe los datos por Bluetooth y el entrenador puede ver informaci{o_}n en tiempo real.

Todav{i_}a estamos en desarrollo, pero cada prueba nos acerca a un objetivo concreto: m{a_}s seguridad y mejor acompa{n_}amiento para quienes nadan en aguas abiertas.

Si nadas, entrenas u organizas actividades en mar abierto, segu{i_} el proyecto y contanos qu{e_} informaci{o_}n te resultar{i_}a realmente {u_}til.

Apoya el desarrollo:
https://startfund.pe/proyectos/save-swimmer-seguridad-para-nadadores-de-aguas-abiertas.php

@saveswimmer
"@
SaveUtf8Bom $copyPath $copy

Write-Host $outPath
Write-Host $copyPath
