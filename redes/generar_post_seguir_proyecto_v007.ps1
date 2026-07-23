$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$baseDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$photoPath = "C:\Users\Claudia\Downloads\WhatsApp Image 2026-06-17 at 5.37.05 PM (1).jpeg"
$logoPath = Join-Path (Split-Path -Parent $baseDir) "android\SaveSwimmerFieldViewer\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png"
$outPath = Join-Path $baseDir "SS-POST-SEGUIR-PROYECTO-V007.png"
$copyPath = Join-Path $baseDir "SS-POST-SEGUIR-PROYECTO-COPY-V007.txt"

if (!(Test-Path $photoPath)) {
  throw "No encontre la foto base: $photoPath"
}
if (!(Test-Path $logoPath)) {
  throw "No encontre el logo: $logoPath"
}

function U([string]$text) {
  $pairs = @(
    @("{a_}", [string][char]0x00E1),
    @("{e_}", [string][char]0x00E9),
    @("{i_}", [string][char]0x00ED),
    @("{o_}", [string][char]0x00F3),
    @("{u_}", [string][char]0x00FA),
    @("{n_}", [string][char]0x00F1),
    @("{A_}", [string][char]0x00C1),
    @("{E_}", [string][char]0x00C9),
    @("{I_}", [string][char]0x00CD),
    @("{O_}", [string][char]0x00D3),
    @("{U_}", [string][char]0x00DA),
    @("{N_}", [string][char]0x00D1)
  )
  foreach ($pair in $pairs) {
    $text = $text.Replace($pair[0], $pair[1])
  }
  return $text
}

function SaveUtf8NoBom([string]$path, [string]$content) {
  $encoding = New-Object System.Text.UTF8Encoding($true)
  [System.IO.File]::WriteAllText($path, (U $content), $encoding)
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

function DrawBadge($graphics, [string]$text, [float]$x, [float]$y, [float]$width, [string]$color) {
  FillRound $graphics (BrushA "#082633" 235) $x $y $width 42 21
  DrawRound $graphics (PenC $color 2) $x $y $width 42 21
  DrawText $graphics $text 18 "#F4FAFC" ($x + 18) ($y + 11) ([System.Drawing.FontStyle]::Bold)
}

function DrawMetric($graphics, [string]$title, [string]$value, [float]$x, [float]$y, [float]$width, [string]$accent) {
  FillRound $graphics (BrushA "#071F2A" 242) $x $y $width 96 12
  DrawRound $graphics (PenA "#1B6070" 210 2) $x $y $width 96 12
  DrawText $graphics $title 17 "#A8BBC2" ($x + 18) ($y + 16)
  DrawText $graphics $value 29 $accent ($x + 18) ($y + 45) ([System.Drawing.FontStyle]::Bold)
}

$w = 1080
$h = 1080
$bmp = New-Object System.Drawing.Bitmap $w, $h
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
  (New-Object System.Drawing.Rectangle 0, 0, $w, $h),
  [System.Drawing.ColorTranslator]::FromHtml("#020A0F"),
  [System.Drawing.ColorTranslator]::FromHtml("#062A39"),
  90
)
$g.FillRectangle($bg, 0, 0, $w, $h)

for ($i = 0; $i -lt 12; $i++) {
  $x = 30 + ($i * 92)
  $g.DrawLine((PenA "#2ED8EA" 26 1), $x, 0, ($x + 280), $h)
}

$logo = [System.Drawing.Image]::FromFile($logoPath)
$g.DrawImage($logo, 58, 48, 86, 86)
$logo.Dispose()

DrawText $g "SAVE SWIMMER" 53 $white 160 50 ([System.Drawing.FontStyle]::Bold)
DrawText $g "SEGURIDAD CONECTADA PARA AGUAS ABIERTAS" 23 $cyan 164 112 ([System.Drawing.FontStyle]::Bold)
DrawText $g "Estado actual del proyecto" 25 $muted 60 155

DrawBadge $g "GPS" 60 202 92 $cyan
DrawBadge $g "BLE" 166 202 88 $cyan
DrawBadge $g "MICROSD" 268 202 138 $cyan
DrawBadge $g "SENSORES" 420 202 140 $cyan
DrawBadge $g "APP" 574 202 82 $orange

$photo = [System.Drawing.Image]::FromFile($photoPath)
$photoX = 58
$photoY = 270
$photoW = 964
$photoH = 452
FillRound $g (BrushA "#04151D" 255) $photoX $photoY $photoW $photoH 20
DrawRound $g (PenA "#2ED8EA" 170 3) $photoX $photoY $photoW $photoH 20

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
$photo.Dispose()
$g.FillRectangle((BrushA "#021018" 58), $dstRect)

FillRound $g (BrushA "#021018" 210) 72 650 920 62 10
DrawText $g "PROTOTIPO REAL EN DESARROLLO" 21 $cyan 88 660 ([System.Drawing.FontStyle]::Bold)
DrawText $g "Hardware ordenado, energia medida, GPS activo y pruebas en agua como siguiente paso." 18 $white 88 688

$panelY = 752
DrawMetric $g "Ya funciona" "sensores + GPS" 58 $panelY 300 $green
DrawMetric $g "Registro local" "microSD" 390 $panelY 250 $cyan
DrawMetric $g "Siguiente paso" "pruebas en agua" 672 $panelY 350 $orange

FillRound $g (BrushA "#082633" 245) 58 880 964 116 16
DrawRound $g (PenA "#1B6070" 230 2) 58 880 964 116 16
DrawText $g "HACIA DONDE VAMOS" 25 $white 88 900 ([System.Drawing.FontStyle]::Bold)
$g.DrawLine((PenC $cyan 4), 88, 938, 330, 938)
DrawText $g "alerta temprana + ubicaci{o_}n + contexto del nado" 26 $cyan 88 952 ([System.Drawing.FontStyle]::Bold)
DrawText $g "Seguinos, opin{a_} y aport{a_} si pod{e_}s. Cada prueba acerca el dispositivo al agua." 18 $muted 88 982

DrawText $g "@saveswimmer" 24 $cyan 60 1032 ([System.Drawing.FontStyle]::Bold)
DrawText $g "saveswimmer@gmail.com" 22 $white 770 1034 ([System.Drawing.FontStyle]::Bold)

$bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$bmp.Dispose()

$copy = @"
Hola, somos Save Swimmer.

Estamos desarrollando en Per{u_} un dispositivo dorsal de seguridad para nadadores de aguas abiertas.

Estado actual:
- Prototipo real funcionando.
- Lectura de movimiento corporal.
- GPS integrado.
- Registro en microSD.
- App de pruebas para visualizar datos.

Ahora seguimos avanzando hacia pruebas en agua para validar lo m{a_}s importante: ubicaci{o_}n, movimiento, zona segura y alertas tempranas.

Si nadas, entrenas, organizas eventos o tienes familia que nada en aguas abiertas, nos ayuda mucho que sigas el proyecto, comentes qu{e_} informaci{o_}n te ser{i_}a {u_}til y compartas la publicaci{o_}n.

Tambi{e_}n puedes apoyar el desarrollo desde StartFund:
https://startfund.pe/proyectos/save-swimmer-seguridad-para-nadadores-de-aguas-abiertas.php

Instagram / Facebook / TikTok: @saveswimmer
Contacto: saveswimmer@gmail.com
"@
SaveUtf8NoBom $copyPath $copy

Write-Host $outPath
Write-Host $copyPath
