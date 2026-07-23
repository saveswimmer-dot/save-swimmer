$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$baseDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$photoPath = "C:\Users\Claudia\Downloads\WhatsApp Image 2026-06-17 at 5.37.05 PM (1).jpeg"
$outPath = Join-Path $baseDir "SS-POST-PRUEBAS-CAMPO-V004.png"

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

function DrawPill($graphics, [string]$text, [float]$x, [float]$y, [float]$width, [string]$stroke, [string]$fill) {
  FillRound $graphics (BrushC $fill) $x $y $width 44 22
  DrawRound $graphics (PenC $stroke 2) $x $y $width 44 22
  $graphics.DrawString($text, (FontC 19 ([System.Drawing.FontStyle]::Bold)), (BrushC "#F4FAFC"), ($x + 20), ($y + 11))
}

function DrawCallout($graphics, [string]$title, [string]$body, [float]$x, [float]$y, [float]$toX, [float]$toY, [string]$color) {
  FillRound $graphics (BrushC "#04151D") $x $y 230 76 10
  DrawRound $graphics (PenC "#1B6070" 2) $x $y 230 76 10
  $graphics.DrawString($title, (FontC 20 ([System.Drawing.FontStyle]::Bold)), (BrushC $color), ($x + 14), ($y + 12))
  $graphics.DrawString($body, (FontC 17), (BrushC "#A8BBC2"), ($x + 14), ($y + 42))
  $graphics.DrawLine((PenC $color 3), ($x + 115), ($y + 76), $toX, $toY)
  $graphics.FillEllipse((BrushC $color), ($toX - 7), ($toY - 7), 14, 14)
}

$white = "#F4FAFC"
$cyan = "#2ED8EA"
$orange = "#FF6A00"
$muted = "#A8BBC2"
$navy = "#061A23"

$bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
  (New-Object System.Drawing.Rectangle 0, 0, $w, $h),
  [System.Drawing.ColorTranslator]::FromHtml("#020B10"),
  [System.Drawing.ColorTranslator]::FromHtml("#062A39"),
  90
)
$g.FillRectangle($bg, 0, 0, $w, $h)

$g.DrawString("SAVE SWIMMER", (FontC 56 ([System.Drawing.FontStyle]::Bold)), (BrushC $white), 58, 46)
$g.DrawString("PRUEBAS DE CAMPO", (FontC 44 ([System.Drawing.FontStyle]::Bold)), (BrushC $cyan), 58, 112)
$g.DrawString("Cada sesion nos ayuda a convertir movimiento real en seguridad conectada.", (FontC 24), (BrushC $muted), 60, 170)

DrawPill $g "GPS" 60 214 102 $cyan "#082633"
DrawPill $g "BLE" 178 214 96 $cyan "#082633"
DrawPill $g "MICROSD" 290 214 148 $cyan "#082633"
DrawPill $g "DATOS REALES" 454 214 204 $orange "#2A1608"

$photo = [System.Drawing.Image]::FromFile($photoPath)
$photoX = 56
$photoY = 285
$photoW = 968
$photoH = 490
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

$overlay = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(72, 0, 10, 16))
$g.FillRectangle($overlay, $dstRect)

DrawCallout $g "ORDEN INTERNO" "menos ruido, mas control" 90 332 195 535 $cyan
DrawCallout $g "GPS REAL" "ubicacion del prototipo" 620 330 650 535 $cyan
DrawCallout $g "ENERGIA" "consumo y autonomia" 760 542 790 560 $orange

$g.DrawRectangle((PenC "#2ED8EA99" 4), 78, 292, 924, 476)
$g.DrawString("prototipo funcional en etapa de orden y medicion", (FontC 22 ([System.Drawing.FontStyle]::Bold)), (BrushC $cyan), 88, 736)

$panelY = 815
FillRound $g (BrushC "#092937") 58 $panelY 964 164 14
DrawRound $g (PenC "#1B6070" 2) 58 $panelY 964 164 14

$g.DrawString("LO QUE ESTAMOS VALIDANDO", (FontC 28 ([System.Drawing.FontStyle]::Bold)), (BrushC $white), 88, ($panelY + 28))
$g.DrawLine((PenC $cyan 4), 88, ($panelY + 68), 360, ($panelY + 68))

$items = @(
  @("1", "Movimiento dorsal", "rotacion, ritmo e impulso"),
  @("2", "Ubicacion", "GPS para ruta y zona segura"),
  @("3", "Autonomia", "consumo real del sistema")
)

for ($i = 0; $i -lt 3; $i++) {
  $x = 88 + ($i * 306)
  $numColor = $(if ($i -eq 2) { $orange } else { $cyan })
  $g.FillEllipse((BrushC $numColor), $x, ($panelY + 88), 34, 34)
  $g.DrawString($items[$i][0], (FontC 20 ([System.Drawing.FontStyle]::Bold)), (BrushC "#021018"), ($x + 11), ($panelY + 93))
  $g.DrawString($items[$i][1], (FontC 23 ([System.Drawing.FontStyle]::Bold)), (BrushC $white), ($x + 46), ($panelY + 84))
  $g.DrawString($items[$i][2], (FontC 18), (BrushC $muted), ($x + 46), ($panelY + 114))
}

$g.DrawString("Del prototipo de mesa a datos de campo.", (FontC 26 ([System.Drawing.FontStyle]::Bold)), (BrushC $white), 60, 1010)
$g.DrawString("@saveswimmer", (FontC 23 ([System.Drawing.FontStyle]::Bold)), (BrushC $cyan), 828, 1014)

$photo.Dispose()
$bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$bmp.Dispose()

Write-Host $outPath
