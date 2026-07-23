$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$baseDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent (Split-Path -Parent $baseDir)
$logoPath = Join-Path $rootDir "android\SaveSwimmerFieldViewer\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png"
$frontPath = Join-Path $baseDir "SS-TARJETA-PRESENTACION-FRENTE-V001.png"
$backPath = Join-Path $baseDir "SS-TARJETA-PRESENTACION-DORSO-V001.png"

if (!(Test-Path $logoPath)) {
  throw "No encontre logo base: $logoPath"
}

# 90 x 55 mm a 300 dpi aprox: 1063 x 650 px
$w = 1063
$h = 650

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

function DrawLetterSpaced($g, [string]$text, $font, $brush, [float]$x, [float]$y, [float]$spacing) {
  $cursor = $x
  for ($i = 0; $i -lt $text.Length; $i++) {
    $char = $text.Substring($i, 1)
    $g.DrawString($char, $font, $brush, $cursor, $y)
    $size = $g.MeasureString($char, $font)
    $cursor += $size.Width + $spacing
  }
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

function NewCanvas() {
  $bmp = New-Object System.Drawing.Bitmap $w, $h
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    (New-Object System.Drawing.Rectangle 0, 0, $w, $h),
    [System.Drawing.ColorTranslator]::FromHtml("#020A0F"),
    [System.Drawing.ColorTranslator]::FromHtml("#062D3C"),
    0
  )
  $g.FillRectangle($bg, 0, 0, $w, $h)
  $bg.Dispose()

  # Zona segura / borde sutil
  DrawRound $g (PenC "#164E5F" 4) 38 38 ($w - 76) ($h - 76) 22
  $g.DrawLine((PenC "#2ED8EA" 5), 74, ($h - 76), 322, ($h - 76))
  $g.DrawLine((PenC "#FF6A00" 5), 340, ($h - 76), 430, ($h - 76))
  return @($bmp, $g)
}

$white = "#F4FAFC"
$cyan = "#2ED8EA"
$orange = "#FF6A00"
$muted = "#A8BBC2"

# Frente
$pair = NewCanvas
$front = $pair[0]
$g = $pair[1]
$logo = [System.Drawing.Image]::FromFile($logoPath)
$g.DrawImage($logo, 88, 122, 132, 132)

DrawLetterSpaced $g "SAVE" (FontC 70 ([System.Drawing.FontStyle]::Bold)) (BrushC $white) 260 110 16
DrawLetterSpaced $g "SWIMMER" (FontC 34 ([System.Drawing.FontStyle]::Bold)) (BrushC $cyan) 266 200 12
$g.DrawString("CONNECTED SAFETY FOR OPEN WATER", (FontC 25 ([System.Drawing.FontStyle]::Bold)), (BrushC $white), 268, 276)
$g.DrawString("Seguridad conectada para aguas abiertas", (FontC 25), (BrushC $cyan), 268, 316)

$g.DrawLine((PenC "#164E5F" 3), 88, 406, 934, 406)
$g.DrawString("PROTOTIPO EN DESARROLLO", (FontC 24 ([System.Drawing.FontStyle]::Bold)), (BrushC $orange), 88, 444)
$g.DrawString("Wearable dorsal para registro de movimiento, ubicacion y contexto acuatico.", (FontC 25), (BrushC $muted), 88, 486)
$g.DrawString("@saveswimmer", (FontC 24 ([System.Drawing.FontStyle]::Bold)), (BrushC $cyan), 782, 552)

$front.Save($frontPath, [System.Drawing.Imaging.ImageFormat]::Png)
$logo.Dispose()
$g.Dispose()
$front.Dispose()

# Dorso
$pair = NewCanvas
$back = $pair[0]
$g = $pair[1]

$g.DrawString("VICTOR LOZA", (FontC 56 ([System.Drawing.FontStyle]::Bold)), (BrushC $white), 86, 94)
$g.DrawString("Responsable del proyecto Save Swimmer", (FontC 30 ([System.Drawing.FontStyle]::Bold)), (BrushC $cyan), 88, 164)
$g.DrawString("Investigacion, prototipo y validacion de seguridad contextual", (FontC 23), (BrushC $muted), 88, 218)
$g.DrawString("para natacion en aguas abiertas.", (FontC 23), (BrushC $muted), 88, 248)

$g.DrawLine((PenC "#164E5F" 3), 88, 300, 934, 300)

$g.DrawString("Correo", (FontC 23 ([System.Drawing.FontStyle]::Bold)), (BrushC $cyan), 88, 342)
$g.DrawString("saveswimmer@gmail.com", (FontC 30 ([System.Drawing.FontStyle]::Bold)), (BrushC $white), 88, 374)

$g.DrawString("Redes", (FontC 23 ([System.Drawing.FontStyle]::Bold)), (BrushC $cyan), 88, 438)
$g.DrawString("@saveswimmer", (FontC 30 ([System.Drawing.FontStyle]::Bold)), (BrushC $white), 88, 470)

$g.DrawString("Lima, Peru", (FontC 25), (BrushC $muted), 88, 548)
$g.DrawString("save swimmer", (FontC 25 ([System.Drawing.FontStyle]::Bold)), (BrushC $orange), 780, 548)

$back.Save($backPath, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$back.Dispose()

Write-Host $frontPath
Write-Host $backPath
