Add-Type -AssemblyName System.Drawing

$size = 1080
$out = Join-Path $PSScriptRoot "post_redes_nuevas_herramientas_v001.png"
$gpsPath = Join-Path $PSScriptRoot "foto_gps_neo_m9n_v001.jpg"
$inaPath = Join-Path $PSScriptRoot "foto_ina219_v001.jpg"

$bmp = New-Object Drawing.Bitmap $size, $size
$g = [Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = "AntiAlias"
$g.InterpolationMode = "HighQualityBicubic"
$g.TextRenderingHint = "AntiAliasGridFit"

$navy = [Drawing.Color]::FromArgb(4, 20, 29)
$panel = [Drawing.Color]::FromArgb(10, 42, 54)
$panel2 = [Drawing.Color]::FromArgb(7, 31, 41)
$cyan = [Drawing.Color]::FromArgb(39, 205, 229)
$orange = [Drawing.Color]::FromArgb(255, 103, 25)
$white = [Drawing.Color]::FromArgb(240, 249, 251)
$muted = [Drawing.Color]::FromArgb(157, 185, 194)
$line = [Drawing.Color]::FromArgb(39, 92, 107)

$g.Clear($navy)

$cyanPen = New-Object Drawing.Pen $cyan, 5
$orangePen = New-Object Drawing.Pen $orange, 5
$thinPen = New-Object Drawing.Pen $line, 2
$mutedPen = New-Object Drawing.Pen ([Drawing.Color]::FromArgb(90, 39, 205, 229)), 2

$titleFont = New-Object Drawing.Font "Arial", 39, ([Drawing.FontStyle]::Bold)
$subFont = New-Object Drawing.Font "Arial", 19, ([Drawing.FontStyle]::Regular)
$labelFont = New-Object Drawing.Font "Arial", 24, ([Drawing.FontStyle]::Bold)
$smallFont = New-Object Drawing.Font "Arial", 16, ([Drawing.FontStyle]::Regular)
$brandFont = New-Object Drawing.Font "Arial", 17, ([Drawing.FontStyle]::Bold)

$whiteBrush = New-Object Drawing.SolidBrush $white
$cyanBrush = New-Object Drawing.SolidBrush $cyan
$orangeBrush = New-Object Drawing.SolidBrush $orange
$mutedBrush = New-Object Drawing.SolidBrush $muted
$panelBrush = New-Object Drawing.SolidBrush $panel
$panel2Brush = New-Object Drawing.SolidBrush $panel2

$g.DrawString("NUEVAS HERRAMIENTAS.", $titleFont, $whiteBrush, 60, 48)
$g.DrawString("NUEVAS PRUEBAS.", $titleFont, $cyanBrush, 60, 96)
$g.DrawString("Dos compras para responder preguntas concretas del prototipo.", $subFont, $mutedBrush, 62, 158)
$g.DrawLine($orangePen, 62, 205, 250, 205)

function Draw-CoverImage($graphics, $imagePath, $x, $y, $w, $h) {
    $image = [Drawing.Image]::FromFile($imagePath)
    try {
        $scale = [Math]::Max($w / $image.Width, $h / $image.Height)
        $srcW = $w / $scale
        $srcH = $h / $scale
        $srcX = ($image.Width - $srcW) / 2
        $srcY = ($image.Height - $srcH) / 2
        $dest = New-Object Drawing.Rectangle $x, $y, $w, $h
        $src = New-Object Drawing.Rectangle ([int]$srcX), ([int]$srcY), ([int]$srcW), ([int]$srcH)
        $graphics.DrawImage($image, $dest, $src, [Drawing.GraphicsUnit]::Pixel)
    } finally {
        $image.Dispose()
    }
}

$leftCard = New-Object Drawing.Rectangle 55, 245, 470, 650
$rightCard = New-Object Drawing.Rectangle 555, 245, 470, 650
$g.FillRectangle($panelBrush, $leftCard)
$g.FillRectangle($panelBrush, $rightCard)
$g.DrawRectangle($thinPen, $leftCard)
$g.DrawRectangle($thinPen, $rightCard)

Draw-CoverImage $g $gpsPath 75 265 430 405
Draw-CoverImage $g $inaPath 575 265 430 405

$g.FillRectangle($panel2Brush, 75, 690, 430, 180)
$g.FillRectangle($panel2Brush, 575, 690, 430, 180)

$g.DrawString("GPS / GNSS", $labelFont, $cyanBrush, 95, 713)
$g.DrawString("Ubicacion y recorrido", $subFont, $whiteBrush, 95, 753)
$g.DrawString("Nos permitira registrar rutas reales,", $smallFont, $mutedBrush, 95, 800)
$g.DrawString("distancia y ultima posicion confirmada.", $smallFont, $mutedBrush, 95, 829)

$g.DrawString("INA219", $labelFont, $orangeBrush, 595, 713)
$g.DrawString("Consumo y autonomia", $subFont, $whiteBrush, 595, 753)
$g.DrawString("Nos permitira medir energia, picos", $smallFont, $mutedBrush, 595, 800)
$g.DrawString("y duracion estimada del prototipo.", $smallFont, $mutedBrush, 595, 829)

# Route motif
$route = @(
    (New-Object Drawing.Point 105, 930),
    (New-Object Drawing.Point 195, 945),
    (New-Object Drawing.Point 285, 918),
    (New-Object Drawing.Point 380, 950),
    (New-Object Drawing.Point 475, 927)
)
$g.DrawLines($cyanPen, $route)
foreach ($p in $route) { $g.FillEllipse($cyanBrush, $p.X - 7, $p.Y - 7, 14, 14) }

# Energy motif
$energy = @(
    (New-Object Drawing.Point 605, 940),
    (New-Object Drawing.Point 670, 940),
    (New-Object Drawing.Point 700, 905),
    (New-Object Drawing.Point 735, 975),
    (New-Object Drawing.Point 770, 925),
    (New-Object Drawing.Point 815, 940),
    (New-Object Drawing.Point 990, 940)
)
$g.DrawLines($orangePen, $energy)

$g.DrawString("SAVE SWIMMER", $brandFont, $whiteBrush, 60, 1005)
$g.DrawString("EN DESARROLLO", $brandFont, $cyanBrush, 835, 1005)

$bmp.Save($out, [Drawing.Imaging.ImageFormat]::Png)

$g.Dispose()
$bmp.Dispose()
$cyanPen.Dispose()
$orangePen.Dispose()
$thinPen.Dispose()
$mutedPen.Dispose()
$titleFont.Dispose()
$subFont.Dispose()
$labelFont.Dispose()
$smallFont.Dispose()
$brandFont.Dispose()
$whiteBrush.Dispose()
$cyanBrush.Dispose()
$orangeBrush.Dispose()
$mutedBrush.Dispose()
$panelBrush.Dispose()
$panel2Brush.Dispose()

Write-Host "Creado: $out"
