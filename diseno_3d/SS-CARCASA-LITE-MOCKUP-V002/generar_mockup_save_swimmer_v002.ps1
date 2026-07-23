param(
    [string]$OutDir = $PSScriptRoot
)

$ErrorActionPreference = "Stop"
New-Item -ItemType Directory -Force $OutDir | Out-Null
$prefix = Join-Path $OutDir "SS-CARCASA-LITE-MOCKUP-V002"

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
    foreach ($line in @(
        ("  facet normal {0:0.######} {1:0.######} {2:0.######}" -f $nx,$ny,$nz),
        "    outer loop",
        ("      vertex {0:0.######} {1:0.######} {2:0.######}" -f $a[0],$a[1],$a[2]),
        ("      vertex {0:0.######} {1:0.######} {2:0.######}" -f $b[0],$b[1],$b[2]),
        ("      vertex {0:0.######} {1:0.######} {2:0.######}" -f $c[0],$c[1],$c[2]),
        "    endloop",
        "  endfacet"
    )) { $lines.Add($line) }
}

function Make-Superellipse-Ring([double]$halfLen, [double]$halfWid, [double]$z, [double]$scale, [int]$segments) {
    $ring = @()
    $power = 0.36
    for ($i=0; $i -lt $segments; $i++) {
        $t = 2.0 * [math]::PI * $i / $segments
        $x = $halfLen * (SgnPow ([math]::Cos($t)) $power) * $scale
        $y = $halfWid * (SgnPow ([math]::Sin($t)) $power) * $scale
        $ring += ,@([double]$x,[double]$y,[double]$z)
    }
    return ,$ring
}

function Add-Superellipse-Solid {
    param(
        [System.Collections.Generic.List[string]]$Lines,
        [double]$HalfLen,
        [double]$HalfWid,
        [double]$ZOffset,
        [double]$SolidHeight,
        [double[]]$Scales
    )
    $segments = 112
    $zBase = [double](@($ZOffset)[0])
    $hBase = [double](@($SolidHeight)[0])
    $verts = @()
    for ($l=0; $l -lt $Scales.Count; $l++) {
        $z = $zBase - ($hBase / 2.0) + ($hBase * $l / ($Scales.Count - 1))
        $verts += ,(Make-Superellipse-Ring $HalfLen $HalfWid $z $Scales[$l] $segments)
    }
    for ($l=0; $l -lt $Scales.Count-1; $l++) {
        for ($i=0; $i -lt $segments; $i++) {
            $j = ($i + 1) % $segments
            Add-Tri $Lines $verts[$l][$i] $verts[$l+1][$i] $verts[$l+1][$j]
            Add-Tri $Lines $verts[$l][$i] $verts[$l+1][$j] $verts[$l][$j]
        }
    }
    $bottom = @(0.0,0.0,($zBase - ($hBase / 2.0)))
    $top = @(0.0,0.0,($zBase + ($hBase / 2.0)))
    for ($i=0; $i -lt $segments; $i++) {
        $j = ($i + 1) % $segments
        Add-Tri $Lines $bottom $verts[0][$j] $verts[0][$i]
        Add-Tri $Lines $top $verts[$Scales.Count-1][$i] $verts[$Scales.Count-1][$j]
    }
}

function Add-Box {
    param(
        [System.Collections.Generic.List[string]]$Lines,
        [double]$Cx,[double]$Cy,[double]$Cz,
        [double]$L,[double]$W,[double]$H
    )
    $x0=$Cx-$L/2; $x1=$Cx+$L/2; $y0=$Cy-$W/2; $y1=$Cy+$W/2; $z0=$Cz-$H/2; $z1=$Cz+$H/2
    $v=@(
        @($x0,$y0,$z0),@($x1,$y0,$z0),@($x1,$y1,$z0),@($x0,$y1,$z0),
        @($x0,$y0,$z1),@($x1,$y0,$z1),@($x1,$y1,$z1),@($x0,$y1,$z1)
    )
    foreach ($f in @(@(0,1,2,3),@(4,7,6,5),@(0,4,5,1),@(1,5,6,2),@(2,6,7,3),@(3,7,4,0))) {
        Add-Tri $Lines $v[$f[0]] $v[$f[1]] $v[$f[2]]
        Add-Tri $Lines $v[$f[0]] $v[$f[2]] $v[$f[3]]
    }
}

function Write-Stl {
    param([string]$Path)
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add("solid SaveSwimmer_Lite_Mockup_V002")
    Add-Superellipse-Solid -Lines $lines -HalfLen 37 -HalfWid 28 -ZOffset 0 -SolidHeight 18 -Scales @(0.78,0.92,1.00,1.00,0.95,0.82)
    Add-Superellipse-Solid -Lines $lines -HalfLen 27 -HalfWid 19 -ZOffset 8.2 -SolidHeight 2.2 -Scales @(0.92,1.00,0.92)
    Add-Box -Lines $lines -Cx 0 -Cy -28 -Cz 1.2 -L 34 -W 3.2 -H 3.2
    Add-Box -Lines $lines -Cx 0 -Cy -23 -Cz -1.2 -L 42 -W 5.0 -H 5.2
    Add-Box -Lines $lines -Cx 0 -Cy 23 -Cz -1.2 -L 42 -W 5.0 -H 5.2
    Add-Box -Lines $lines -Cx -37 -Cy 0 -Cz -0.5 -L 4.5 -W 31 -H 7
    Add-Box -Lines $lines -Cx 37 -Cy 0 -Cz -0.5 -L 4.5 -W 31 -H 7
    Add-Superellipse-Solid -Lines $lines -HalfLen 6 -HalfWid 6 -ZOffset 9.2 -SolidHeight 1.6 -Scales @(1.0,1.0)
    $lines.Add("endsolid SaveSwimmer_Lite_Mockup_V002")
    Set-Content -LiteralPath $Path -Value $lines -Encoding ASCII
}

function Write-Dxf {
    param([string]$Path)
    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($item in @("0","SECTION","2","ENTITIES")) { $lines.Add([string]$item) }
    $segments = 112
    $ring = Make-Superellipse-Ring 37 28 0 1 $segments
    for ($i=0; $i -lt $segments; $i++) {
        $j = ($i + 1) % $segments
        foreach ($item in @("0","LINE","8","OUTLINE","10",$ring[$i][0],"20",$ring[$i][1],"11",$ring[$j][0],"21",$ring[$j][1])) { $lines.Add([string]$item) }
    }
    foreach ($y in @(-23,23)) {
        foreach ($item in @("0","LINE","8","CLIP","10","-21","20",$y,"11","21","21",$y)) { $lines.Add([string]$item) }
    }
    foreach ($x in @(-25,25)) {
        foreach ($y in @(-17,17)) {
            foreach ($item in @("0","CIRCLE","8","SCREW_MARKERS","10",$x,"20",$y,"40","1.7")) { $lines.Add([string]$item) }
        }
    }
    foreach ($item in @("0","ENDSEC","0","EOF")) { $lines.Add([string]$item) }
    Set-Content -LiteralPath $Path -Value $lines -Encoding ASCII
}

function Write-Obj {
    param([string]$Path)
    $content = @(
        "# Save Swimmer Lite mockup V002 reference OBJ",
        "# Use STL for printing; SCAD for parametric CAD.",
        "o SaveSwimmer_Lite_V002_reference",
        "v -37 -28 -9",
        "v 37 -28 -9",
        "v 37 28 -9",
        "v -37 28 -9",
        "v -37 -28 9",
        "v 37 -28 9",
        "v 37 28 9",
        "v -37 28 9",
        "f 1 2 3 4",
        "f 5 8 7 6",
        "f 1 5 6 2",
        "f 2 6 7 3",
        "f 3 7 8 4",
        "f 4 8 5 1"
    )
    Set-Content -LiteralPath $Path -Value $content -Encoding ASCII
}

function Draw-RoundedRect($g, $x, $y, $w, $h, $r, $pen, $brush) {
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $p.AddArc($x,$y,$r,$r,180,90); $p.AddArc($x+$w-$r,$y,$r,$r,270,90)
    $p.AddArc($x+$w-$r,$y+$h-$r,$r,$r,0,90); $p.AddArc($x,$y+$h-$r,$r,$r,90,90)
    $p.CloseFigure()
    if ($brush -ne $null) { $g.FillPath($brush,$p) }
    if ($pen -ne $null) { $g.DrawPath($pen,$p) }
}

function Write-Png {
    param([string]$Path)
    Add-Type -AssemblyName System.Drawing
    $w=1800; $h=1150
    $bmp=New-Object System.Drawing.Bitmap $w,$h
    $g=[System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode=[System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $bg=[System.Drawing.Color]::FromArgb(248,250,252)
    $ink=[System.Drawing.Color]::FromArgb(16,24,32)
    $blue=[System.Drawing.Color]::FromArgb(0,141,216)
    $cyan=[System.Drawing.Color]::FromArgb(20,205,232)
    $green=[System.Drawing.Color]::FromArgb(52,226,117)
    $orange=[System.Drawing.Color]::FromArgb(255,109,24)
    $gray=[System.Drawing.Color]::FromArgb(95,105,112)
    $line=[System.Drawing.Color]::FromArgb(205,211,216)
    $body=[System.Drawing.Color]::FromArgb(28,31,34)
    $body2=[System.Drawing.Color]::FromArgb(49,53,58)
    $g.Clear($bg)
    $fontTitle=New-Object System.Drawing.Font("Arial",34,[System.Drawing.FontStyle]::Bold)
    $fontH=New-Object System.Drawing.Font("Arial",22,[System.Drawing.FontStyle]::Bold)
    $font=New-Object System.Drawing.Font("Arial",16,[System.Drawing.FontStyle]::Regular)
    $fontB=New-Object System.Drawing.Font("Arial",16,[System.Drawing.FontStyle]::Bold)
    $fontS=New-Object System.Drawing.Font("Arial",13,[System.Drawing.FontStyle]::Regular)
    $bInk=New-Object System.Drawing.SolidBrush($ink)
    $bBlue=New-Object System.Drawing.SolidBrush($blue)
    $bCyan=New-Object System.Drawing.SolidBrush($cyan)
    $bGreen=New-Object System.Drawing.SolidBrush($green)
    $bOrange=New-Object System.Drawing.SolidBrush($orange)
    $bGray=New-Object System.Drawing.SolidBrush($gray)
    $bBody=New-Object System.Drawing.SolidBrush($body)
    $bBody2=New-Object System.Drawing.SolidBrush($body2)
    $pLine=New-Object System.Drawing.Pen($line,2)
    $pInk=New-Object System.Drawing.Pen($ink,2)
    $pCyan=New-Object System.Drawing.Pen($cyan,5)
    $pBlue=New-Object System.Drawing.Pen($blue,3)
    $pGreen=New-Object System.Drawing.Pen($green,6)

    $g.DrawString("SAVE ", $fontTitle, $bInk, 45, 36)
    $g.DrawString("SWIMMER", $fontTitle, $bBlue, 160, 36)
    $g.DrawString("DISPOSITIVO DE SEGURIDAD PARA AGUAS ABIERTAS - MOCKUP LITE V002", $font, $bGray, 50, 92)
    $g.DrawLine($pLine, 45, 135, 1755, 135)

    $g.DrawString("VISTA EXTERNA", $fontH, $bInk, 210, 165)
    $g.DrawString("(prototipo cerrado)", $font, $bGray, 238, 198)
    Draw-RoundedRect $g 210 260 240 310 58 $pInk $bBody
    Draw-RoundedRect $g 255 292 150 80 28 $null $bBody2
    Draw-RoundedRect $g 270 403 120 58 24 $null (New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(18,20,22)))
    $g.FillEllipse($bOrange, 315, 421, 22, 22)
    $g.FillEllipse($bGreen, 348, 421, 22, 22)
    Draw-RoundedRect $g 276 535 108 14 8 $null $bGreen
    $g.DrawString("S", (New-Object System.Drawing.Font("Arial",48,[System.Drawing.FontStyle]::Bold)), (New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(14,15,16))), 302, 460)
    $g.DrawLine($pLine, 166, 260, 166, 570); $g.DrawString("74 mm", $fontB, $bInk, 82, 402)
    $g.DrawLine($pLine, 210, 612, 450, 612); $g.DrawString("56 mm", $fontB, $bInk, 294, 630)

    $g.DrawString("PERFIL LATERAL", $fontH, $bInk, 610, 165)
    $side = New-Object System.Drawing.Drawing2D.GraphicsPath
    $side.AddBezier(570,365,660,300,855,300,945,365)
    $side.AddBezier(945,365,855,414,660,414,570,365)
    $g.FillPath($bBody, $side); $g.DrawPath($pInk, $side)
    $g.DrawLine($pCyan, 615, 389, 900, 389)
    Draw-RoundedRect $g 690 395 130 15 8 $null $bBody2
    $g.DrawLine($pLine, 980, 300, 980, 414); $g.DrawString("18 mm", $fontB, $bInk, 1000, 350)
    $g.DrawString("bajo perfil hidrodinamico", $fontS, $bGray, 640, 445)

    $g.DrawString("VISTA INFERIOR / FIJACION", $fontH, $bInk, 1110, 165)
    Draw-RoundedRect $g 1125 260 300 220 54 $pInk $bBody
    Draw-RoundedRect $g 1170 300 210 140 22 $null $bBody2
    Draw-RoundedRect $g 1135 342 48 58 12 $null (New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(10,12,14)))
    Draw-RoundedRect $g 1367 342 48 58 12 $null (New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(10,12,14)))
    foreach ($pt in @(@(1165,292),@(1385,292),@(1165,438),@(1385,438))) { $g.FillEllipse($bGray, $pt[0], $pt[1], 18,18) }
    $g.DrawString("clip / base flexible", $fontB, $bInk, 1192, 510)
    $g.DrawString("para neopreno, boya personal o soporte dorsal", $fontS, $bGray, 1148, 540)

    $g.DrawLine($pLine, 45, 700, 1755, 700)
    $g.DrawString("ESPECIFICACIONES REFERENCIALES", $fontH, $bInk, 55, 735)
    $spec = @(
        "Dimensiones objetivo: 74 x 56 x 18 mm",
        "Uso: aguas abiertas, monitoreo y alerta temprana",
        "Indicadores: LED estado, alerta, GPS/conexion",
        "Sensores previstos: IMU + GPS + comunicacion",
        "Fijacion: base/clip/correa a definir",
        "Estado: mockup para impresion 3D, no IP68 final"
    )
    $yy=785
    foreach ($s in $spec) { $g.DrawString("- " + $s, $font, $bInk, 75, $yy); $yy += 38 }

    $g.DrawString("VISTA EXPLOSIONADA CONCEPTUAL", $fontH, $bInk, 650, 735)
    $xs=@(650,805,960,1115,1270,1425)
    $labels=@("carcasa","sello","soporte","PCB","bateria","tapa")
    for ($i=0; $i -lt $xs.Count; $i++) {
        Draw-RoundedRect $g $xs[$i] 815 95 145 22 $pInk $(if($i -eq 1){ New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(235,245,248)) } elseif($i -eq 3){ New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(32,120,72)) } elseif($i -eq 4){ New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(210,168,47)) } else { $bBody })
        $g.DrawString(($i+1).ToString() + ". " + $labels[$i], $fontB, $(if($i -eq 4){$bInk}else{$bBlue}), $xs[$i]-4, 980)
        if ($i -lt $xs.Count-1) { $g.DrawLine($pLine, $xs[$i]+110, 887, $xs[$i+1]-18, 887) }
    }
    $g.DrawString("La explosionada es de referencia: ayuda a conversar capas y componentes, no define ingenieria final.", $fontS, $bGray, 650, 1030)

    $g.DrawLine($pLine, 45, 1080, 1755, 1080)
    $g.DrawString("Archivos generados: PNG, STL imprimible, SCAD parametrico, DXF 2D, OBJ referencia", $fontS, $bBlue, 55, 1100)
    $bmp.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
}

Write-Stl "$prefix.stl"
Write-Obj "$prefix.obj"
Write-Dxf "$prefix.dxf"
Write-Png "$prefix.png"
Write-Host "Generado V002 en $OutDir"
