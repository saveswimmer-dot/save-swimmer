$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$baseDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$photoPath = "C:\Users\Claudia\Downloads\WhatsApp Image 2026-06-17 at 5.37.05 PM (1).jpeg"
$outPath = Join-Path $baseDir "SS-POST-AVANCE-REAL-PROTOTIPO-V002.png"

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

function FillRoundedRect($graphics, $brush, [float]$x, [float]$y, [float]$width, [float]$height, [float]$radius) {
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

function DrawRoundedRect($graphics, $pen, [float]$x, [float]$y, [float]$width, [float]$height, [float]$radius) {
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

# Background
$bgRect = New-Object System.Drawing.Rectangle 0, 0, $w, $h
$bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
  $bgRect,
  [System.Drawing.ColorTranslator]::FromHtml("#020B10"),
  [System.Drawing.ColorTranslator]::FromHtml("#073142"),
  90
)
$g.FillRectangle($bgBrush, $bgRect)

# Subtle map/grid lines
for ($i = 0; $i -lt 9; $i++) {
  $x = 70 + $i * 120
  $g.DrawLine((PenC "#0D4657" 1), $x, 0, $x - 260, $h)
}
for ($i = 0; $i -lt 8; $i++) {
  $y = 120 + $i * 115
  $g.DrawLine((PenC "#0B3948" 1), 0, $y, $w, $y + 55)
}

$white = "#F4FAFC"
$cyan = "#2ED8EA"
$orange = "#FF6A00"
$muted = "#A8BBC2"
$card = "#0A2633"

# Header
$g.DrawString("SAVE SWIMMER", (FontC 62 ([System.Drawing.FontStyle]::Bold)), (BrushC $white), 62, 58)
$g.DrawString("PROTOTIPO REAL EN DESARROLLO", (FontC 30 ([System.Drawing.FontStyle]::Bold)), (BrushC $cyan), 66, 132)
$g.DrawString("Ordenando modulos para pruebas de campo", (FontC 25), (BrushC $muted), 68, 178)

# Actual photo card
$photo = [System.Drawing.Image]::FromFile($photoPath)
$cardX = 62
$cardY = 250
$cardW = 956
$cardH = 535
FillRoundedRect $g (BrushC "#061A23") $cardX $cardY $cardW $cardH 16
DrawRoundedRect $g (PenC "#1C6070" 3) $cardX $cardY $cardW $cardH 16

# Cover-crop photo into card
$srcW = $photo.Width
$srcH = $photo.Height
$targetRatio = $cardW / $cardH
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
$dstRect = New-Object System.Drawing.Rectangle ($cardX + 14), ($cardY + 14), ($cardW - 28), ($cardH - 28)
$g.DrawImage($photo, $dstRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)

# Dark overlay for readability
$overlay = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(78, 0, 12, 18))
$g.FillRectangle($overlay, $dstRect)

# Photo label
FillRoundedRect $g (BrushC "#04151D") 90 285 330 58 10
$g.DrawString("PROTOTIPO EN BANCO", (FontC 24 ([System.Drawing.FontStyle]::Bold)), (BrushC $cyan), 112, 302)

# Signal/status chips
$chips = @(
  @("GPS", 96, 825, $cyan),
  @("BLE", 255, 825, $cyan),
  @("MICROSD", 410, 825, $cyan),
  @("ENERGIA", 625, 825, $orange)
)
foreach ($c in $chips) {
  FillRoundedRect $g (BrushC "#0B2A36") $c[1] $c[2] 130 54 8
  $g.FillEllipse((BrushC $c[3]), ([int]$c[1] + 18), ([int]$c[2] + 18), 16, 16)
  $g.DrawString($c[0], (FontC 22 ([System.Drawing.FontStyle]::Bold)), (BrushC $white), ([int]$c[1] + 43), ([int]$c[2] + 15))
}

# Main message block
$g.DrawString("Cada cable ordenado acerca el prototipo a una prueba mas confiable.", (FontC 31 ([System.Drawing.FontStyle]::Bold)), (BrushC $white), 74, 908)
$g.DrawString("Save Swimmer registra movimiento, ubicacion y energia para transformar datos en seguridad en aguas abiertas.", (FontC 23), (BrushC $muted), 76, 954)

# Footer accent
$g.DrawLine((PenC $cyan 5), 74, 1030, 330, 1030)
$g.DrawLine((PenC $orange 5), 345, 1030, 440, 1030)
$g.DrawString("@saveswimmer", (FontC 22 ([System.Drawing.FontStyle]::Bold)), (BrushC $cyan), 785, 1014)

$photo.Dispose()
$bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$bmp.Dispose()

Write-Host $outPath
