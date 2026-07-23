$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$baseDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$outPath = Join-Path $baseDir "SS-POST-AVANCE-PROTOTIPO-V001.png"

$w = 1080
$h = 1080
$bmp = New-Object System.Drawing.Bitmap $w, $h
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

function Brush([string]$hex) {
  return New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml($hex))
}

function PenC([string]$hex, [float]$width) {
  $p = New-Object System.Drawing.Pen ([System.Drawing.ColorTranslator]::FromHtml($hex), $width)
  $p.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $p.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
  return $p
}

function FontC([string]$name, [float]$size, [System.Drawing.FontStyle]$style = [System.Drawing.FontStyle]::Regular) {
  return New-Object System.Drawing.Font($name, $size, $style, [System.Drawing.GraphicsUnit]::Pixel)
}

$bgRect = New-Object System.Drawing.Rectangle 0, 0, $w, $h
$bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
  $bgRect,
  [System.Drawing.ColorTranslator]::FromHtml("#031019"),
  [System.Drawing.ColorTranslator]::FromHtml("#082938"),
  90
)
$g.FillRectangle($bgBrush, $bgRect)

# Ocean bands
$oceanBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
  (New-Object System.Drawing.Rectangle 0, 560, $w, 520),
  [System.Drawing.ColorTranslator]::FromHtml("#083948"),
  [System.Drawing.ColorTranslator]::FromHtml("#021018"),
  90
)
$g.FillRectangle($oceanBrush, 0, 560, $w, 520)

$cyan = "#28D6E8"
$deepCyan = "#08A9C9"
$orange = "#FF6A00"
$white = "#F4FAFC"
$muted = "#9BB4BE"
$card = "#0C2B36"

# Soft horizon
$g.DrawLine((PenC "#1B5464" 2), 0, 555, $w, 525)
for ($i = 0; $i -lt 9; $i++) {
  $y = 610 + ($i * 45)
  $pen = PenC "#114A5A" 2
  $g.DrawBezier($pen, -60, $y, 220, $y - 35, 550, $y + 35, 1140, $y - 20)
}

# Title block
$fontTitle = FontC "Arial" 66 ([System.Drawing.FontStyle]::Bold)
$fontSub = FontC "Arial" 34 ([System.Drawing.FontStyle]::Bold)
$fontSmall = FontC "Arial" 26 ([System.Drawing.FontStyle]::Regular)
$fontTiny = FontC "Arial" 22 ([System.Drawing.FontStyle]::Regular)

$g.DrawString("SAVE SWIMMER", $fontTitle, (Brush $white), 70, 70)
$g.DrawString("PROTOTIPO EN DESARROLLO", $fontSub, (Brush $cyan), 74, 150)
$g.DrawString("Seguridad conectada para aguas abiertas", $fontSmall, (Brush $muted), 76, 205)

# Minimal logo mark
$logoX = 795
$logoY = 72
$g.DrawArc((PenC $orange 16), $logoX + 58, $logoY, 130, 70, 205, 130)
$g.DrawArc((PenC $orange 12), $logoX + 82, $logoY + 48, 82, 46, 205, 130)
$g.DrawEllipse((PenC $cyan 14), $logoX + 95, $logoY + 120, 55, 55)
$g.FillEllipse((Brush $cyan), $logoX + 114, $logoY + 140, 18, 18)
$wavePen = PenC $cyan 18
$g.DrawBezier($wavePen, $logoX + 20, $logoY + 225, $logoX + 95, $logoY + 155, $logoX + 190, $logoY + 290, $logoX + 278, $logoY + 215)
$g.DrawBezier((PenC "#0A6C95" 18), $logoX + 58, $logoY + 310, $logoX + 125, $logoY + 390, $logoX + 210, $logoY + 300, $logoX + 270, $logoY + 260)

# Swimmer silhouette/back
$skin = Brush "#2C5660"
$suit = Brush "#04151F"
$outline = PenC "#154B58" 4
$bodyPath = New-Object System.Drawing.Drawing2D.GraphicsPath
$bodyPath.AddBezier(375, 400, 290, 505, 260, 760, 360, 920)
$bodyPath.AddBezier(360, 920, 470, 1020, 620, 1018, 725, 915)
$bodyPath.AddBezier(725, 915, 830, 755, 780, 500, 690, 400)
$bodyPath.AddBezier(690, 400, 590, 455, 480, 455, 375, 400)
$g.FillPath($suit, $bodyPath)
$g.DrawPath($outline, $bodyPath)

# Head/swim cap
$g.FillEllipse((Brush "#081B25"), 448, 300, 205, 160)
$g.DrawEllipse((PenC "#1A5966" 4), 448, 300, 205, 160)

# Dorsal device
$deviceRect = New-Object System.Drawing.Rectangle 474, 530, 130, 180
$radius = 26
$devicePath = New-Object System.Drawing.Drawing2D.GraphicsPath
$devicePath.AddArc($deviceRect.X, $deviceRect.Y, $radius, $radius, 180, 90)
$devicePath.AddArc($deviceRect.Right - $radius, $deviceRect.Y, $radius, $radius, 270, 90)
$devicePath.AddArc($deviceRect.Right - $radius, $deviceRect.Bottom - $radius, $radius, $radius, 0, 90)
$devicePath.AddArc($deviceRect.X, $deviceRect.Bottom - $radius, $radius, $radius, 90, 90)
$devicePath.CloseFigure()
$g.FillPath((Brush "#081923"), $devicePath)
$g.DrawPath((PenC "#1B6575" 4), $devicePath)
$g.DrawLine((PenC $cyan 10), 500, 680, 578, 680)
$g.DrawArc((PenC $orange 6), 515, 560, 50, 28, 205, 130)
$g.DrawEllipse((PenC $cyan 5), 526, 592, 28, 28)
$g.FillEllipse((Brush $cyan), 536, 603, 8, 8)

# Signal arcs
$signalPen = PenC "#28D6E880" 4
$g.DrawArc($signalPen, 390, 455, 300, 240, 210, 120)
$g.DrawArc($signalPen, 345, 415, 390, 320, 210, 120)
$g.DrawArc((PenC "#FF6A0080" 4), 300, 370, 480, 410, 210, 120)

# Dashboard card
$cardBrush = Brush $card
$g.FillRectangle($cardBrush, 72, 790, 370, 190)
$g.DrawRectangle((PenC "#1F6070" 2), 72, 790, 370, 190)
$g.DrawString("GPS + BLE + SD", (FontC "Arial" 26 ([System.Drawing.FontStyle]::Bold)), (Brush $cyan), 100, 820)
$g.DrawString("Datos reales del prototipo", $fontTiny, (Brush $muted), 100, 858)
$g.DrawLine((PenC $cyan 5), 105, 925, 170, 895)
$g.DrawLine((PenC $cyan 5), 170, 895, 260, 920)
$g.DrawLine((PenC $cyan 5), 260, 920, 385, 865)
$g.FillEllipse((Brush $orange), 96, 916, 18, 18)
$g.FillEllipse((Brush $cyan), 376, 856, 22, 22)

# Feature badges
$badgeFont = FontC "Arial" 24 ([System.Drawing.FontStyle]::Bold)
$badges = @(
  @("UBICACION", 690, 800, $cyan),
  @("MOVIMIENTO", 690, 858, $cyan),
  @("ALERTA TEMPRANA", 690, 916, $orange)
)
foreach ($b in $badges) {
  $g.FillEllipse((Brush $b[3]), [int]$b[1], [int]$b[2], 18, 18)
  $g.DrawString($b[0], $badgeFont, (Brush $white), [int]$b[1] + 34, [int]$b[2] - 5)
}

# Footer
$g.DrawString("Etapa actual: ordenamiento interno, GPS y medicion de consumo", $fontTiny, (Brush "#B7CAD0"), 70, 1015)

$bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$bmp.Dispose()

Write-Host $outPath
