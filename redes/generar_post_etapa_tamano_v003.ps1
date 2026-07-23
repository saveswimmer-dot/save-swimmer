$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$baseDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$photoPath = "C:\Users\Claudia\Downloads\WhatsApp Image 2026-06-17 at 5.37.05 PM (1).jpeg"
$outPath = Join-Path $baseDir "SS-POST-ETAPA-TAMANO-V003.png"

if (!(Test-Path $photoPath)) {
  throw "No encontre la foto base: $photoPath"
}

$w = 1080
$h = 1080
$bmp = New-Object System.Drawing.Bitmap $w, $h
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

function BrushC([string]$hex) {
  return New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml($hex))
}

function PenC([string]$hex, [float]$width) {
  $p = New-Object System.Drawing.Pen ([System.Drawing.ColorTranslator]::FromHtml($hex), $width)
  $p.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $p.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
  return $p
}

function FontC([float]$size, [System.Drawing.FontStyle]$style = [System.Drawing.FontStyle]::Regular) {
  return New-Object System.Drawing.Font("Arial", $size, $style, [System.Drawing.GraphicsUnit]::Pixel)
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

function DrawLabel($graphics, [string]$text, [int]$x, [int]$y, [int]$toX, [int]$toY, [string]$color) {
  FillRound $graphics (BrushC "#04151D") $x $y 190 42 8
  $graphics.DrawString($text, (FontC 18 ([System.Drawing.FontStyle]::Bold)), (BrushC "#F4FAFC"), ($x + 14), ($y + 11))
  $graphics.DrawLine((PenC $color 3), ($x + 95), ($y + 42), $toX, $toY)
  $graphics.FillEllipse((BrushC $color), ($toX - 7), ($toY - 7), 14, 14)
}

$white = "#F4FAFC"
$cyan = "#2ED8EA"
$orange = "#FF6A00"
$muted = "#A8BBC2"
$navy = "#061A23"

# Background
$bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
  (New-Object System.Drawing.Rectangle 0, 0, $w, $h),
  [System.Drawing.ColorTranslator]::FromHtml("#020B10"),
  [System.Drawing.ColorTranslator]::FromHtml("#062A39"),
  90
)
$g.FillRectangle($bg, 0, 0, $w, $h)

# Header
$g.DrawString("SAVE SWIMMER", (FontC 54 ([System.Drawing.FontStyle]::Bold)), (BrushC $white), 62, 48)
$g.DrawString("ENTRAMOS EN ETAPA DE TAMANO", (FontC 38 ([System.Drawing.FontStyle]::Bold)), (BrushC $cyan), 62, 118)
$g.DrawString("Ya no es solo probar sensores: ahora ordenamos espacio, posicion y conexion interna.", (FontC 24), (BrushC $muted), 64, 171)

# Photo area
$photo = [System.Drawing.Image]::FromFile($photoPath)
$photoX = 58
$photoY = 240
$photoW = 964
$photoH = 540
FillRound $g (BrushC $navy) $photoX $photoY $photoW $photoH 18
DrawRound $g (PenC "#1F6070" 3) $photoX $photoY $photoW $photoH 18

$srcW = $photo.Width
$srcH = $photo.Height
$targetRatio = $photoW / $photoH
$srcRatio = $srcW / $srcH
if ($srcRatio -gt $targetRatio) {
  $cropH = $srcH
  $cropW = [int]($srcH * $targetRatio)
  $cropX = [int](($srcW - $cropW) / 2)
  $cropY = 0
} else {
  $cropW = $srcW
  $cropH = [int]($srcW / $targetRatio)
  $cropX = 0
  $cropY = [int](($srcH - $cropH) / 2)
}
$srcRect = New-Object System.Drawing.Rectangle $cropX, $cropY, $cropW, $cropH
$dstRect = New-Object System.Drawing.Rectangle ($photoX + 12), ($photoY + 12), ($photoW - 24), ($photoH - 24)
$g.DrawImage($photo, $dstRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)

# Overlay for labels
$overlay = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(62, 0, 10, 16))
$g.FillRectangle($overlay, $dstRect)

# Context labels on the real photo
DrawLabel $g "ESP32" 92 305 185 545 $cyan
DrawLabel $g "ENERGIA" 285 330 350 515 $orange
DrawLabel $g "MICROSD" 455 288 565 392 $cyan
DrawLabel $g "GPS" 650 312 650 535 $cyan
DrawLabel $g "MEDICION" 780 390 790 535 $orange
DrawLabel $g "SENSOR" 730 650 865 584 $cyan

# Measurement frame
$g.DrawRectangle((PenC "#2ED8EA99" 4), 78, 245, 924, 528)
$g.DrawString("maqueta interna / distribucion de volumen", (FontC 22 ([System.Drawing.FontStyle]::Bold)), (BrushC $cyan), 86, 744)

# Bottom concept cards
$cardY = 820
$cards = @(
  @("1", "Reducir cables", "orden para evitar fallas"),
  @("2", "Definir ubicacion", "GPS, bateria, SD y sensor"),
  @("3", "Medir consumo", "autonomia real del prototipo")
)
for ($i = 0; $i -lt 3; $i++) {
  $x = 62 + ($i * 334)
  FillRound $g (BrushC "#092937") $x $cardY 304 135 12
  DrawRound $g (PenC "#1B6070" 2) $x $cardY 304 135 12
  $g.FillEllipse((BrushC $(if ($i -eq 2) { $orange } else { $cyan })), ($x + 20), ($cardY + 22), 38, 38)
  $g.DrawString($cards[$i][0], (FontC 22 ([System.Drawing.FontStyle]::Bold)), (BrushC "#021018"), ($x + 33), ($cardY + 28))
  $g.DrawString($cards[$i][1], (FontC 25 ([System.Drawing.FontStyle]::Bold)), (BrushC $white), ($x + 72), ($cardY + 24))
  $g.DrawString($cards[$i][2], (FontC 20), (BrushC $muted), ($x + 24), ($cardY + 78))
}

# Footer
$g.DrawLine((PenC $cyan 5), 62, 1005, 320, 1005)
$g.DrawLine((PenC $orange 5), 335, 1005, 435, 1005)
$g.DrawString("Del prototipo funcional al dispositivo compacto.", (FontC 25 ([System.Drawing.FontStyle]::Bold)), (BrushC $white), 62, 1018)
$g.DrawString("@saveswimmer", (FontC 22 ([System.Drawing.FontStyle]::Bold)), (BrushC $cyan), 825, 1019)

$photo.Dispose()
$bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$bmp.Dispose()

Write-Host $outPath
