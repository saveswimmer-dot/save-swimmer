$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$outDir = Join-Path $PSScriptRoot "output"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$outPath = Join-Path $outDir "SS-POST-VALIDACION-PISCINA-V001.png"

$w = 1920
$h = 1080
$bmp = New-Object System.Drawing.Bitmap $w, $h
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit

function Brush($hex, [int]$alpha = 255) {
    $hex = $hex.TrimStart("#")
    $r = [Convert]::ToInt32($hex.Substring(0,2),16)
    $gg = [Convert]::ToInt32($hex.Substring(2,2),16)
    $b = [Convert]::ToInt32($hex.Substring(4,2),16)
    return New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb($alpha,$r,$gg,$b))
}

function Pen($hex, [float]$width = 1, [int]$alpha = 255) {
    $hex = $hex.TrimStart("#")
    $r = [Convert]::ToInt32($hex.Substring(0,2),16)
    $gg = [Convert]::ToInt32($hex.Substring(2,2),16)
    $b = [Convert]::ToInt32($hex.Substring(4,2),16)
    return New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb($alpha,$r,$gg,$b)), $width
}

function FontObj($size, [System.Drawing.FontStyle]$style = [System.Drawing.FontStyle]::Regular) {
    return New-Object System.Drawing.Font ("Montserrat", [float]$size, $style, [System.Drawing.GraphicsUnit]::Pixel)
}

function DrawText($text, $x, $y, $size, $color, [System.Drawing.FontStyle]$style = [System.Drawing.FontStyle]::Regular, $alpha = 255) {
    $font = FontObj $size $style
    $brush = Brush $color $alpha
    $g.DrawString($text, $font, $brush, [float]$x, [float]$y)
    $font.Dispose()
    $brush.Dispose()
}

function DrawTextBox($text, $x, $y, $ww, $hh, $size, $color, [System.Drawing.FontStyle]$style = [System.Drawing.FontStyle]::Regular, $alpha = 255) {
    $font = FontObj $size $style
    $brush = Brush $color $alpha
    $format = New-Object System.Drawing.StringFormat
    $format.Trimming = [System.Drawing.StringTrimming]::EllipsisWord
    $format.FormatFlags = 0
    $rectF = New-Object System.Drawing.RectangleF ([float]$x), ([float]$y), ([float]$ww), ([float]$hh)
    $g.DrawString($text, $font, $brush, $rectF, $format)
    $format.Dispose()
    $font.Dispose()
    $brush.Dispose()
}

function FillRoundRect($x,$y,$ww,$hh,$radius,$color,$alpha=255) {
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $radius * 2
    $path.AddArc($x,$y,$d,$d,180,90)
    $path.AddArc($x+$ww-$d,$y,$d,$d,270,90)
    $path.AddArc($x+$ww-$d,$y+$hh-$d,$d,$d,0,90)
    $path.AddArc($x,$y+$hh-$d,$d,$d,90,90)
    $path.CloseFigure()
    $brush = Brush $color $alpha
    $g.FillPath($brush,$path)
    $brush.Dispose()
    $path.Dispose()
}

function StrokeRoundRect($x,$y,$ww,$hh,$radius,$color,$alpha=255,$line=1) {
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $radius * 2
    $path.AddArc($x,$y,$d,$d,180,90)
    $path.AddArc($x+$ww-$d,$y,$d,$d,270,90)
    $path.AddArc($x+$ww-$d,$y+$hh-$d,$d,$d,0,90)
    $path.AddArc($x,$y+$hh-$d,$d,$d,90,90)
    $path.CloseFigure()
    $pen = Pen $color $line $alpha
    $g.DrawPath($pen,$path)
    $pen.Dispose()
    $path.Dispose()
}

# Background gradient
$rect = New-Object System.Drawing.Rectangle 0,0,$w,$h
$bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect, ([System.Drawing.Color]::FromArgb(255,3,13,20)), ([System.Drawing.Color]::FromArgb(255,5,35,48)), 35
$g.FillRectangle($bg,$rect)
$bg.Dispose()

# Ocean-like bands
for ($i=0; $i -lt 14; $i++) {
    $pen = Pen "#00C2E0" 1 (18 + ($i % 3)*8)
    $yy = 130 + $i * 58
    $pts = New-Object 'System.Drawing.PointF[]' 5
    $pts[0] = New-Object System.Drawing.PointF 0, ($yy + [Math]::Sin($i)*20)
    $pts[1] = New-Object System.Drawing.PointF 420, ($yy + 20 + [Math]::Cos($i)*24)
    $pts[2] = New-Object System.Drawing.PointF 850, ($yy - 10)
    $pts[3] = New-Object System.Drawing.PointF 1300, ($yy + 26)
    $pts[4] = New-Object System.Drawing.PointF 1920, ($yy - 8)
    $g.DrawCurve($pen,$pts,0.35)
    $pen.Dispose()
}

# Main layout panels
FillRoundRect 48 54 640 250 16 "#061C29" 188
StrokeRoundRect 48 54 640 250 16 "#1B6D80" 155 2
FillRoundRect 720 54 1150 250 16 "#061C29" 158
StrokeRoundRect 720 54 1150 250 16 "#1B6D80" 120 2
FillRoundRect 48 342 780 520 18 "#061C29" 150
StrokeRoundRect 48 342 780 520 18 "#1B6D80" 120 2
FillRoundRect 870 342 1000 520 18 "#061C29" 150
StrokeRoundRect 870 342 1000 520 18 "#1B6D80" 120 2
FillRoundRect 48 890 1822 145 18 "#061C29" 180
StrokeRoundRect 48 890 1822 145 18 "#1B6D80" 120 2

# Header
DrawText "SAVE SWIMMER" 88 78 54 "#F4F7F8" ([System.Drawing.FontStyle]::Bold)
DrawText "VALIDACION EN CAMPO" 88 144 38 "#00C2E0" ([System.Drawing.FontStyle]::Bold)
DrawText "Prototipo en pruebas reales." 88 203 25 "#D7E6EA"
DrawText "SEGURIDAD CONECTADA PARA AGUAS ABIERTAS" 88 252 22 "#FF6A00" ([System.Drawing.FontStyle]::Bold)

# Technical mini blocks top right
$topItems = @(
    @("GPS","Ubicacion y ruta."),
    @("MICROSD","Registro completo."),
    @("APP ATLETA","Lectura + CSV."),
    @("PISCINA","Piscina controlada.")
)
for ($i=0; $i -lt 4; $i++) {
    $x = 760 + ($i * 270)
    FillRoundRect $x 98 238 150 12 "#092838" 210
    StrokeRoundRect $x 98 238 150 12 "#00C2E0" 110 1
    DrawTextBox ($topItems[$i][0]) ($x+20) 124 198 34 23 "#00C2E0" ([System.Drawing.FontStyle]::Bold)
    DrawTextBox ($topItems[$i][1]) ($x+20) 174 198 42 18 "#D7E6EA"
}

# Product mockup body
$bodyBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush (New-Object System.Drawing.Rectangle 118,430,470,280), ([System.Drawing.Color]::FromArgb(255,14,18,22)), ([System.Drawing.Color]::FromArgb(255,35,45,52)), 70
$g.FillEllipse($bodyBrush,118,430,470,280)
$bodyBrush.Dispose()
$penC = Pen "#00C2E0" 5 220
$g.DrawArc($penC,160,460,390,215,12,160)
$g.DrawArc($penC,160,460,390,215,192,145)
$penC.Dispose()
FillRoundRect 282 618 145 32 14 "#00C2E0" 240
DrawText "SAVE" 272 500 44 "#F4F7F8" ([System.Drawing.FontStyle]::Bold)
DrawText "SWIMMER" 275 550 28 "#00C2E0" ([System.Drawing.FontStyle]::Bold)
$orange = Pen "#FF6A00" 7 240
$g.DrawArc($orange,315,392,80,70,205,130)
$g.DrawArc($orange,292,365,125,110,205,130)
$orange.Dispose()
DrawText "Dispositivo dorsal compacto" 105 742 30 "#F4F7F8" ([System.Drawing.FontStyle]::Bold)
DrawText "Objetivo actual: validar lectura corporal y registro confiable." 105 790 23 "#D7E6EA"

# Swimmer silhouette/map idea on right panel
$cyanPen = Pen "#00C2E0" 5 230
$whitePen = Pen "#EAF5F8" 4 160
$orangePen = Pen "#FF6A00" 4 235
$g.DrawLine($cyanPen,960,520,1430,450)
$g.DrawLine($cyanPen,1430,450,1715,560)
$g.DrawLine($cyanPen,960,645,1260,610)
$g.DrawLine($cyanPen,1260,610,1740,710)
$g.DrawEllipse($cyanPen,1360,405,70,70)
$g.DrawEllipse($orangePen,910,505,42,42)
$g.DrawEllipse($orangePen,1718,690,42,42)
for ($i=0; $i -lt 12; $i++) {
    $x = 970 + $i*66
    $g.DrawLine($whitePen,$x,745,$x,760)
}
$cyanPen.Dispose(); $whitePen.Dispose(); $orangePen.Dispose()
DrawText "Lectura corporal" 930 380 36 "#F4F7F8" ([System.Drawing.FontStyle]::Bold)
DrawText "Rotacion | Alineacion | Impulso | Ritmo" 930 430 25 "#00C2E0" ([System.Drawing.FontStyle]::Bold)
DrawText "La app convierte datos del sensor en lenguaje util para atleta y entrenador." 930 790 23 "#D7E6EA"

# Simulated phone cards
FillRoundRect 1465 390 300 330 28 "#020C12" 245
StrokeRoundRect 1465 390 300 330 28 "#5A6A72" 180 2
DrawText "APP ATLETA" 1505 425 24 "#F4F7F8" ([System.Drawing.FontStyle]::Bold)
DrawText "Rotacion correcta" 1505 478 22 "#00C2E0" ([System.Drawing.FontStyle]::Bold)
DrawText "Alineacion estable" 1505 520 22 "#65E99A" ([System.Drawing.FontStyle]::Bold)
DrawText "Impulso en validacion" 1505 562 20 "#D7E6EA"
$p1 = Pen "#00C2E0" 3 230
$p2 = Pen "#FFCC66" 3 230
for ($i=0; $i -lt 8; $i++) {
    $x1 = 1510 + $i*28
    $y1 = 650 - (($i%3)*26)
    $x2 = 1538 + $i*28
    $y2 = 630 - ((($i+1)%3)*26)
    $g.DrawLine($p1,$x1,$y1,$x2,$y2)
    $g.DrawLine($p2,$x1,$y1+30,$x2,$y2+30)
}
$p1.Dispose(); $p2.Dispose()

# Bottom cards
$bottom = @(
    @("1. DATOS REALES","Sesiones cortas, codigos claros y CSV por prueba."),
    @("2. GPS + MOVIMIENTO","Ubicacion junto a lectura dorsal del cuerpo."),
    @("3. REGISTRO LOCAL","microSD para no perder datos si se corta BLE."),
    @("4. PISCINA","Proxima etapa: calibracion controlada con atleta.")
)
for ($i=0; $i -lt 4; $i++) {
    $x = 82 + $i*450
    FillRoundRect $x 918 395 84 10 "#092838" 210
    StrokeRoundRect $x 918 395 84 10 "#00C2E0" 85 1
    DrawTextBox ($bottom[$i][0]) ($x+22) 936 350 28 23 "#00C2E0" ([System.Drawing.FontStyle]::Bold)
    DrawTextBox ($bottom[$i][1]) ($x+22) 968 350 45 16 "#D7E6EA"
}

DrawText "Probamos hoy para proteger manana." 1240 1036 22 "#F4F7F8" ([System.Drawing.FontStyle]::Bold)
DrawText "@saveswimmer  |  saveswimmer@gmail.com" 82 1037 20 "#D7E6EA"

$g.Dispose()
$bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

Write-Host $outPath
