param(
    [string]$OutDir = $PSScriptRoot
)

$ErrorActionPreference = "Stop"
New-Item -ItemType Directory -Force $OutDir | Out-Null

$prefix = Join-Path $OutDir "SS-CARCASA-LITE-MOCKUP-V001"

function SgnPow([double]$v, [double]$p) {
    if ($v -lt 0) { return -[math]::Pow(-$v, $p) }
    return [math]::Pow($v, $p)
}

function Add-Tri([System.Collections.Generic.List[string]]$lines, [double[]]$a, [double[]]$b, [double[]]$c) {
    $ux=$b[0]-$a[0]; $uy=$b[1]-$a[1]; $uz=$b[2]-$a[2]
    $vx=$c[0]-$a[0]; $vy=$c[1]-$a[1]; $vz=$c[2]-$a[2]
    $nx=$uy*$vz-$uz*$vy; $ny=$uz*$vx-$ux*$vz; $nz=$ux*$vy-$uy*$vx
    $n=[math]::Sqrt($nx*$nx+$ny*$ny+$nz*$nz)
    if ($n -gt 0) { $nx/=$n; $ny/=$n; $nz/=$n }
    $lines.Add(("  facet normal {0:0.######} {1:0.######} {2:0.######}" -f $nx,$ny,$nz))
    $lines.Add("    outer loop")
    $lines.Add(("      vertex {0:0.######} {1:0.######} {2:0.######}" -f $a[0],$a[1],$a[2]))
    $lines.Add(("      vertex {0:0.######} {1:0.######} {2:0.######}" -f $b[0],$b[1],$b[2]))
    $lines.Add(("      vertex {0:0.######} {1:0.######} {2:0.######}" -f $c[0],$c[1],$c[2]))
    $lines.Add("    endloop")
    $lines.Add("  endfacet")
}

function Write-CapsuleStl {
    param([string]$Path)
    $segments = 96
    $layers = @(
        @{z=0.0; scale=0.82},
        @{z=2.0; scale=0.94},
        @{z=5.5; scale=1.00},
        @{z=12.0; scale=1.00},
        @{z=18.0; scale=0.97},
        @{z=21.0; scale=0.90},
        @{z=22.0; scale=0.78}
    )
    $halfLen = 47.5
    $halfWid = 27.5
    $power = 0.42
    $verts = @()
    foreach ($layer in $layers) {
        $ring = @()
        for ($i=0; $i -lt $segments; $i++) {
            $t = 2.0 * [math]::PI * $i / $segments
            $x = $halfLen * (SgnPow ([math]::Cos($t)) $power) * $layer.scale
            $y = $halfWid * (SgnPow ([math]::Sin($t)) $power) * $layer.scale
            $z = $layer.z - 11.0
            $ring += ,@([double]$x,[double]$y,[double]$z)
        }
        $verts += ,$ring
    }

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add("solid SaveSwimmer_Lite_Mockup_V001")

    for ($l=0; $l -lt $layers.Count-1; $l++) {
        for ($i=0; $i -lt $segments; $i++) {
            $j = ($i + 1) % $segments
            Add-Tri $lines $verts[$l][$i] $verts[$l+1][$i] $verts[$l+1][$j]
            Add-Tri $lines $verts[$l][$i] $verts[$l+1][$j] $verts[$l][$j]
        }
    }

    $bottom = @(0.0,0.0,-11.0)
    $top = @(0.0,0.0,11.0)
    for ($i=0; $i -lt $segments; $i++) {
        $j = ($i + 1) % $segments
        Add-Tri $lines $bottom $verts[0][$j] $verts[0][$i]
        Add-Tri $lines $top $verts[$layers.Count-1][$i] $verts[$layers.Count-1][$j]
    }

    $lines.Add("endsolid SaveSwimmer_Lite_Mockup_V001")
    Set-Content -LiteralPath $Path -Value $lines -Encoding ASCII
}

function Write-Obj {
    param([string]$Path)
    $content = @(
        "# Save Swimmer Lite mockup V001 - reference OBJ",
        "# Main volume: 95 x 55 x 22 mm approximate",
        "o SaveSwimmer_Lite_Mockup_Block",
        "v -47.5 -27.5 -11",
        "v 47.5 -27.5 -11",
        "v 47.5 27.5 -11",
        "v -47.5 27.5 -11",
        "v -47.5 -27.5 11",
        "v 47.5 -27.5 11",
        "v 47.5 27.5 11",
        "v -47.5 27.5 11",
        "f 1 2 3 4",
        "f 5 8 7 6",
        "f 1 5 6 2",
        "f 2 6 7 3",
        "f 3 7 8 4",
        "f 4 8 5 1"
    )
    Set-Content -LiteralPath $Path -Value $content -Encoding ASCII
}

function Write-Dxf {
    param([string]$Path)
    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($item in @("0","SECTION","2","ENTITIES")) { $lines.Add([string]$item) }
    $segments = 96
    $halfLen = 47.5
    $halfWid = 27.5
    $power = 0.42
    for ($i=0; $i -lt $segments; $i++) {
        $j = ($i + 1) % $segments
        $t1 = 2.0 * [math]::PI * $i / $segments
        $t2 = 2.0 * [math]::PI * $j / $segments
        $x1 = $halfLen * (SgnPow ([math]::Cos($t1)) $power)
        $y1 = $halfWid * (SgnPow ([math]::Sin($t1)) $power)
        $x2 = $halfLen * (SgnPow ([math]::Cos($t2)) $power)
        $y2 = $halfWid * (SgnPow ([math]::Sin($t2)) $power)
        foreach ($item in @("0","LINE","8","OUTLINE","10",("$x1"),"20",("$y1"),"11",("$x2"),"21",("$y2"))) { $lines.Add([string]$item) }
    }
    foreach ($x in @(-30,30)) {
        foreach ($y in @(-14,14)) {
            foreach ($item in @("0","CIRCLE","8","SCREW_MARKERS","10",("$x"),"20",("$y"),"40","1.8")) { $lines.Add([string]$item) }
        }
    }
    foreach ($item in @("0","LINE","8","STRAP","10","-52","20","-11","11","52","21","-11")) { $lines.Add([string]$item) }
    foreach ($item in @("0","LINE","8","STRAP","10","-52","20","11","11","52","21","11")) { $lines.Add([string]$item) }
    foreach ($item in @("0","ENDSEC","0","EOF")) { $lines.Add([string]$item) }
    Set-Content -LiteralPath $Path -Value $lines -Encoding ASCII
}

function Write-Png {
    param([string]$Path)
    Add-Type -AssemblyName System.Drawing
    $w = 1600; $h = 1000
    $bmp = New-Object System.Drawing.Bitmap $w,$h
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $bg = [System.Drawing.Color]::FromArgb(9,31,38)
    $panel = [System.Drawing.Color]::FromArgb(15,48,58)
    $cyan = [System.Drawing.Color]::FromArgb(44,211,230)
    $green = [System.Drawing.Color]::FromArgb(80,231,143)
    $orange = [System.Drawing.Color]::FromArgb(255,114,36)
    $white = [System.Drawing.Color]::FromArgb(238,246,248)
    $muted = [System.Drawing.Color]::FromArgb(142,170,178)
    $g.Clear($bg)
    $fontTitle = New-Object System.Drawing.Font("Arial",36,[System.Drawing.FontStyle]::Bold)
    $fontSub = New-Object System.Drawing.Font("Arial",20,[System.Drawing.FontStyle]::Regular)
    $fontSmall = New-Object System.Drawing.Font("Arial",16,[System.Drawing.FontStyle]::Regular)
    $brushW = New-Object System.Drawing.SolidBrush($white)
    $brushM = New-Object System.Drawing.SolidBrush($muted)
    $brushC = New-Object System.Drawing.SolidBrush($cyan)
    $brushG = New-Object System.Drawing.SolidBrush($green)
    $brushO = New-Object System.Drawing.SolidBrush($orange)
    $penC = New-Object System.Drawing.Pen($cyan,8)
    $penG = New-Object System.Drawing.Pen($green,5)
    $penO = New-Object System.Drawing.Pen($orange,5)
    $penM = New-Object System.Drawing.Pen($muted,2)

    $g.DrawString("Save Swimmer Lite - mockup carcasa V001", $fontTitle, $brushW, 70, 55)
    $g.DrawString("Primera muestra 3D para volumen dorsal, correa y ubicacion de antena/boton. No es diseno estanco final.", $fontSub, $brushM, 74, 112)
    $g.FillRectangle((New-Object System.Drawing.SolidBrush($panel)), 70, 180, 1460, 690)

    $body = New-Object System.Drawing.Drawing2D.GraphicsPath
    $body.AddArc(260, 300, 120, 120, 90, 180)
    $body.AddLine(320,300,760,300)
    $body.AddArc(700,300,120,120,270,180)
    $body.AddLine(760,420,320,420)
    $body.CloseFigure()
    $g.FillPath((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(20,75,88))), $body)
    $g.DrawPath($penC, $body)
    $g.DrawRectangle($penG, 330, 346, 420, 28)
    $g.DrawString("canal correa/velcro", $fontSmall, $brushG, 458, 382)
    $g.DrawEllipse($penO, 355, 328, 42, 42)
    $g.DrawString("boton / LED", $fontSmall, $brushO, 315, 270)
    $g.DrawRectangle($penM, 610, 315, 130, 90)
    $g.DrawString("zona antena / GPS", $fontSmall, $brushM, 580, 420)
    $g.DrawString("Vista superior aprox. 95 x 55 mm", $fontSub, $brushW, 280, 235)

    $side = New-Object System.Drawing.Drawing2D.GraphicsPath
    $side.AddBezier(950,390,1040,310,1260,310,1350,390)
    $side.AddBezier(1350,390,1260,450,1040,450,950,390)
    $g.FillPath((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(20,75,88))), $side)
    $g.DrawPath($penC, $side)
    $g.DrawLine($penG, 1040, 433, 1260, 433)
    $g.DrawString("curva inferior suave para apoyo dorsal", $fontSmall, $brushG, 990, 465)
    $g.DrawString("Vista lateral aprox. 22 mm alto", $fontSub, $brushW, 965, 235)

    $g.DrawString("Supuestos V001", $fontSub, $brushW, 110, 610)
    $g.DrawString("- Cuerpo compacto dorsal: 95 x 55 x 22 mm", $fontSmall, $brushM, 130, 660)
    $g.DrawString("- Correa central de 22 mm para evaluar montaje en gorra/neopreno", $fontSmall, $brushM, 130, 700)
    $g.DrawString("- Zona superior reservada para GPS/LTE; boton/LED separados", $fontSmall, $brushM, 130, 740)
    $g.DrawString("- Falta validar: flotabilidad, sello, tornillos, carga, antena real y ergonomia", $fontSmall, $brushM, 130, 780)

    $g.DrawString("Archivos: SCAD parametric, STL imprimible, DXF 2D, OBJ referencia", $fontSmall, $brushC, 840, 780)
    $bmp.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
}

Write-CapsuleStl -Path "$prefix.stl"
Write-Obj -Path "$prefix.obj"
Write-Dxf -Path "$prefix.dxf"
Write-Png -Path "$prefix.png"

Write-Host "Generado en $OutDir"
