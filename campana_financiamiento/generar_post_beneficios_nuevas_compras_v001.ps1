Add-Type -AssemblyName System.Drawing

$size = 1080
$out = Join-Path $PSScriptRoot "post_redes_beneficios_nuevas_compras_v001.png"
$mapPath = Join-Path (Split-Path $PSScriptRoot -Parent) "assets\costa_verde_agua_dulce.jpg"

$bmp = New-Object Drawing.Bitmap $size, $size
$g = [Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = "AntiAlias"
$g.InterpolationMode = "HighQualityBicubic"
$g.TextRenderingHint = "AntiAliasGridFit"

$navy = [Drawing.Color]::FromArgb(4, 20, 29)
$cyan = [Drawing.Color]::FromArgb(37, 207, 231)
$orange = [Drawing.Color]::FromArgb(255, 104, 24)
$white = [Drawing.Color]::FromArgb(242, 250, 252)
$muted = [Drawing.Color]::FromArgb(169, 193, 200)
$panel = [Drawing.Color]::FromArgb(225, 5, 25, 34)
$overlay = [Drawing.Color]::FromArgb(105, 1, 16, 24)

$g.Clear($navy)

$image = [Drawing.Image]::FromFile($mapPath)
$dest = New-Object Drawing.Rectangle 0, 0, 1080, 760
$src = New-Object Drawing.Rectangle 0, 0, $image.Width, $image.Height
$g.DrawImage($image, $dest, $src, [Drawing.GraphicsUnit]::Pixel)
$image.Dispose()
$g.FillRectangle((New-Object Drawing.SolidBrush $overlay), 0, 0, 1080, 760)

$whiteBrush = New-Object Drawing.SolidBrush $white
$cyanBrush = New-Object Drawing.SolidBrush $cyan
$orangeBrush = New-Object Drawing.SolidBrush $orange
$mutedBrush = New-Object Drawing.SolidBrush $muted
$panelBrush = New-Object Drawing.SolidBrush $panel

$titleFont = New-Object Drawing.Font "Arial", 45, ([Drawing.FontStyle]::Bold)
$subFont = New-Object Drawing.Font "Arial", 23, ([Drawing.FontStyle]::Regular)
$benefitFont = New-Object Drawing.Font "Arial", 28, ([Drawing.FontStyle]::Bold)
$smallFont = New-Object Drawing.Font "Arial", 18, ([Drawing.FontStyle]::Regular)
$brandFont = New-Object Drawing.Font "Arial", 17, ([Drawing.FontStyle]::Bold)

$g.DrawString("AHORA PODEMOS", $titleFont, $whiteBrush, 60, 50)
$g.DrawString("MEDIR MAS.", $titleFont, $cyanBrush, 60, 105)
$g.DrawString("Dos nuevas pruebas para entender mejor cada sesion.", $subFont, $whiteBrush, 64, 174)

# Route through the water
$routePen = New-Object Drawing.Pen $cyan, 9
$routePen.LineJoin = "Round"
$route = @(
    (New-Object Drawing.Point 170, 610),
    (New-Object Drawing.Point 240, 560),
    (New-Object Drawing.Point 330, 525),
    (New-Object Drawing.Point 420, 470),
    (New-Object Drawing.Point 515, 440),
    (New-Object Drawing.Point 610, 375),
    (New-Object Drawing.Point 700, 345),
    (New-Object Drawing.Point 770, 300)
)
$g.DrawLines($routePen, $route)
foreach ($p in $route) { $g.FillEllipse($cyanBrush, $p.X - 9, $p.Y - 9, 18, 18) }
$g.FillEllipse($orangeBrush, 752, 282, 36, 36)
$g.DrawEllipse((New-Object Drawing.Pen $white, 5), 744, 274, 52, 52)

# Two human-readable benefits
$g.FillRectangle($panelBrush, 45, 735, 475, 245)
$g.FillRectangle($panelBrush, 560, 735, 475, 245)
$g.DrawRectangle((New-Object Drawing.Pen ([Drawing.Color]::FromArgb(65, 37, 207, 231)), 2), 45, 735, 475, 245)
$g.DrawRectangle((New-Object Drawing.Pen ([Drawing.Color]::FromArgb(65, 37, 207, 231)), 2), 560, 735, 475, 245)

# Location icon
$g.DrawEllipse((New-Object Drawing.Pen $cyan, 7), 82, 780, 54, 54)
$g.FillEllipse($cyanBrush, 99, 797, 20, 20)
$g.DrawLine((New-Object Drawing.Pen $cyan, 7), 109, 835, 109, 858)
$g.DrawString("RECORRIDO REAL", $benefitFont, $cyanBrush, 165, 774)
$g.DrawString("Empezamos a validar por donde", $smallFont, $whiteBrush, 165, 824)
$g.DrawString("se mueve el prototipo.", $smallFont, $whiteBrush, 165, 855)

# Duration icon
$g.DrawEllipse((New-Object Drawing.Pen $orange, 7), 600, 780, 62, 62)
$g.DrawLine((New-Object Drawing.Pen $orange, 6), 631, 811, 631, 790)
$g.DrawLine((New-Object Drawing.Pen $orange, 6), 631, 811, 650, 822)
$g.DrawString("DURACION REAL", $benefitFont, $orangeBrush, 690, 774)
$g.DrawString("Mediremos cuanto tiempo puede", $smallFont, $whiteBrush, 690, 824)
$g.DrawString("funcionar antes de recargar.", $smallFont, $whiteBrush, 690, 855)

$g.DrawString("SAVE SWIMMER", $brandFont, $whiteBrush, 64, 1014)
$g.DrawString("EN DESARROLLO", $brandFont, $cyanBrush, 835, 1014)

$bmp.Save($out, [Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$bmp.Dispose()
Write-Host "Creado: $out"
