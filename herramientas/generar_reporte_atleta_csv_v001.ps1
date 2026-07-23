param(
    [Parameter(Mandatory = $true)]
    [string]$CsvPath,

    [string]$OutDir = ""
)

$ErrorActionPreference = "Stop"

if (!(Test-Path -LiteralPath $CsvPath)) {
    throw "No existe el CSV: $CsvPath"
}

$projectRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($OutDir)) {
    $OutDir = Join-Path $projectRoot "reportes_atleta"
}
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

function Clean-Key([string]$value) {
    return ($value -replace '[^A-Za-z0-9_]', '').ToUpperInvariant()
}

function Num($value, [double]$default = [double]::NaN) {
    if ($null -eq $value) { return $default }
    $s = [string]$value
    $s = $s.Trim().Replace(",", ".")
    $out = 0.0
    if ([double]::TryParse($s, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$out)) {
        return $out
    }
    return $default
}

function Clamp([double]$v, [double]$min, [double]$max) {
    return [Math]::Max($min, [Math]::Min($max, $v))
}

function Avg($items, [scriptblock]$selector) {
    $vals = @()
    foreach ($item in $items) {
        $v = & $selector $item
        if (-not [double]::IsNaN($v)) { $vals += [double]$v }
    }
    if ($vals.Count -eq 0) { return [double]::NaN }
    return ($vals | Measure-Object -Average).Average
}

function Median($values) {
    $vals = @($values | Where-Object { -not [double]::IsNaN($_) } | Sort-Object)
    if ($vals.Count -eq 0) { return [double]::NaN }
    $mid = [int]($vals.Count / 2)
    if ($vals.Count % 2 -eq 1) { return [double]$vals[$mid] }
    return ([double]$vals[$mid - 1] + [double]$vals[$mid]) / 2.0
}

function Percentile($values, [double]$pct) {
    $vals = @($values | Where-Object { -not [double]::IsNaN($_) } | Sort-Object)
    if ($vals.Count -eq 0) { return [double]::NaN }
    $p = Clamp $pct 0 1
    $idx = [Math]::Min($vals.Count - 1, [int][Math]::Floor(($vals.Count - 1) * $p))
    return [double]$vals[$idx]
}

function Useful-PeakAverage($values) {
    $vals = @($values | Where-Object { -not [double]::IsNaN($_) -and $_ -gt 0 } | Sort-Object)
    if ($vals.Count -eq 0) { return 0.0 }

    # La rotación útil se lee desde los picos, no desde todo el retorno al eje 0.
    # Usamos la zona alta de la señal para representar "cuánto llegó a rotar" cada lado.
    $p90 = Percentile $vals 0.90
    if ([double]::IsNaN($p90)) { return 0.0 }
    if ($p90 -lt 4.0) { return $p90 }

    $threshold = [Math]::Max(4.0, $p90 * 0.60)
    $peaks = @($vals | Where-Object { $_ -ge $threshold })
    if ($peaks.Count -eq 0) { return $p90 }
    return ($peaks | Measure-Object -Average).Average
}

function Distance-Meters($a, $b) {
    if ([double]::IsNaN($a.lat) -or [double]::IsNaN($a.lon) -or [double]::IsNaN($b.lat) -or [double]::IsNaN($b.lon)) { return 0.0 }
    $r = 6371000.0
    $lat1 = $a.lat * [Math]::PI / 180.0
    $lat2 = $b.lat * [Math]::PI / 180.0
    $dLat = ($b.lat - $a.lat) * [Math]::PI / 180.0
    $dLon = ($b.lon - $a.lon) * [Math]::PI / 180.0
    $h = [Math]::Sin($dLat / 2.0) * [Math]::Sin($dLat / 2.0) + [Math]::Cos($lat1) * [Math]::Cos($lat2) * [Math]::Sin($dLon / 2.0) * [Math]::Sin($dLon / 2.0)
    return $r * 2.0 * [Math]::Atan2([Math]::Sqrt($h), [Math]::Sqrt(1.0 - $h))
}

function Fmt-Seconds([double]$seconds) {
    if ([double]::IsNaN($seconds) -or $seconds -lt 0) { return "--" }
    $ts = [TimeSpan]::FromSeconds($seconds)
    if ($ts.TotalHours -ge 1) { return "{0:00}:{1:00}:{2:00}" -f [int]$ts.TotalHours, $ts.Minutes, $ts.Seconds }
    return "{0:00}:{1:00}" -f $ts.Minutes, $ts.Seconds
}

function Label-Rotation([double]$avgRot, [double]$symmetry) {
    if ($symmetry -gt 12) { return "asimetría" }
    if ($avgRot -lt 20) { return "baja" }
    if ($avgRot -le 50) { return "correcta" }
    return "excesiva"
}

function Label-Alignment([double]$align) {
    if ($align -lt 8) { return "estable" }
    if ($align -lt 16) { return "variable" }
    return "irregular"
}

function Label-Impulse([double]$impulse) {
    if ($impulse -lt 0.8) { return "suave" }
    if ($impulse -lt 2.5) { return "normal" }
    return "alto"
}

function Csv-Escape([string]$s) {
    if ($null -eq $s) { return "" }
    if ($s.Contains('"') -or $s.Contains(',') -or $s.Contains("`n")) {
        return '"' + $s.Replace('"','""') + '"'
    }
    return $s
}

function Html($s) {
    return [System.Net.WebUtility]::HtmlEncode([string]$s)
}

$lines = Get-Content -LiteralPath $CsvPath -Encoding UTF8
$meta = [ordered]@{}
$headerLine = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i].Trim()
    if ($line.StartsWith("#")) {
        $parts = $line.Substring(1).Split(",", 2)
        if ($parts.Count -eq 2) { $meta[(Clean-Key $parts[0])] = $parts[1].Trim() }
        continue
    }
    if ($line -match "(?i)(^|,)lr(,|$)" -and $line -match "(?i)(^|,)ud(,|$)" -and $line -match "(?i)(^|,)mag(,|$)") {
        $headerLine = $i
        break
    }
}

if ($headerLine -lt 0) {
    throw "No encontré una tabla con columnas LR, UD y MAG. CSV no compatible todavía."
}

$headersRaw = $lines[$headerLine].Split(",")
$headers = @($headersRaw | ForEach-Object { Clean-Key $_ })
$rows = New-Object System.Collections.Generic.List[object]

function ColIndex($names) {
    foreach ($name in $names) {
        $idx = [Array]::IndexOf($headers, (Clean-Key $name))
        if ($idx -ge 0) { return $idx }
    }
    return -1
}

$idxTime = ColIndex @("elapsed_s", "time", "time_s", "elapsed", "seconds")
$idxLocal = ColIndex @("local_time", "datetime", "date_time")
$idxLr = ColIndex @("lr", "x")
$idxFb = ColIndex @("fb", "y")
$idxUd = ColIndex @("ud", "z")
$idxMag = ColIndex @("mag", "m")
$idxPitch = ColIndex @("pitch", "pitch_deg")
$idxRoll = ColIndex @("roll", "roll_deg")
$idxLat = ColIndex @("lat", "gps_lat", "latitude", "gps_latitude")
$idxLon = ColIndex @("lon", "lng", "gps_lon", "longitude", "gps_longitude")
$idxSpeed = ColIndex @("speed_kmh", "gps_speed_kmh", "speed")

for ($i = $headerLine + 1; $i -lt $lines.Count; $i++) {
    $line = $lines[$i].Trim()
    if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith("#")) { continue }
    $v = $line.Split(",")
    if ($v.Count -le ([Math]::Max([Math]::Max($idxLr, $idxUd), $idxMag))) { continue }
    $lr = Num $v[$idxLr]
    $fb = if ($idxFb -ge 0 -and $v.Count -gt $idxFb) { Num $v[$idxFb] } else { [double]::NaN }
    $ud = Num $v[$idxUd]
    $mag = Num $v[$idxMag]
    if ([double]::IsNaN($lr) -or [double]::IsNaN($ud) -or [double]::IsNaN($mag)) { continue }
    $t = if ($idxTime -ge 0 -and $v.Count -gt $idxTime) { Num $v[$idxTime] } else { $rows.Count / 10.0 }
    $lat = if ($idxLat -ge 0 -and $v.Count -gt $idxLat) { Num $v[$idxLat] } else { [double]::NaN }
    $lon = if ($idxLon -ge 0 -and $v.Count -gt $idxLon) { Num $v[$idxLon] } else { [double]::NaN }
    $speed = if ($idxSpeed -ge 0 -and $v.Count -gt $idxSpeed) { Num $v[$idxSpeed] } else { [double]::NaN }
    $pitch = if ($idxPitch -ge 0 -and $v.Count -gt $idxPitch) { Num $v[$idxPitch] } else { [double]::NaN }
    $roll = if ($idxRoll -ge 0 -and $v.Count -gt $idxRoll) { Num $v[$idxRoll] } else { [double]::NaN }
    $local = if ($idxLocal -ge 0 -and $v.Count -gt $idxLocal) { $v[$idxLocal] } else { "" }
    $rows.Add([pscustomobject]@{
        t = $t; local = $local; lr = $lr; fb = $fb; ud = $ud; mag = $mag; pitch = $pitch; roll = $roll; lat = $lat; lon = $lon; speed = $speed
    })
}

if ($rows.Count -lt 5) {
    throw "Muy pocas muestras válidas para generar reporte: $($rows.Count)"
}

$duration = [Math]::Max(0, $rows[$rows.Count - 1].t - $rows[0].t)

# Cero corporal automático: los primeros segundos se toman como base de colocación.
# Esto evita que el promedio de una prueba de movimiento sea interpretado como "cabeza levantada".
$baseWindow = [Math]::Min(3.0, [Math]::Max(1.0, $duration * 0.12))
$baseRows = @($rows | Where-Object { $_.t -le ($rows[0].t + $baseWindow) })
if ($baseRows.Count -lt 5) { $baseRows = @($rows | Select-Object -First ([Math]::Min(20, $rows.Count))) }

$zeroLr = Median ($baseRows | ForEach-Object { $_.lr })
$zeroFb = Median ($baseRows | ForEach-Object { $_.fb })
$zeroUd = Median ($baseRows | ForEach-Object { $_.ud })
$zeroMag = Median ($rows | ForEach-Object { $_.mag })
$zeroPitch = Median ($baseRows | Where-Object { ![double]::IsNaN($_.pitch) } | ForEach-Object { $_.pitch })
$zeroRoll = Median ($baseRows | Where-Object { ![double]::IsNaN($_.roll) } | ForEach-Object { $_.roll })
$useAngles = ![double]::IsNaN($zeroPitch) -and ![double]::IsNaN($zeroRoll)

$analysis = New-Object System.Collections.Generic.List[object]
foreach ($r in $rows) {
    $lrD = $r.lr - $zeroLr
    $fbD = if ([double]::IsNaN($r.fb)) { 0.0 } else { $r.fb - $zeroFb }
    $udD = $r.ud - $zeroUd
    $magD = $r.mag - $zeroMag
    $rot = [Math]::Asin((Clamp ($lrD / 9.81) -1 1)) * 180.0 / [Math]::PI
    if ($useAngles -and ![double]::IsNaN($r.roll) -and ![double]::IsNaN($r.pitch)) {
        $align = $r.pitch - $zeroPitch
    } else {
        $align = [Math]::Asin((Clamp ($udD / 9.81) -1 1)) * 180.0 / [Math]::PI
    }
    $imp = [Math]::Abs($udD) + [Math]::Max(0.0, $magD)
    $analysis.Add([pscustomobject]@{
        t = $r.t; lr = $r.lr; fb = $r.fb; ud = $r.ud; mag = $r.mag; lat = $r.lat; lon = $r.lon; speed = $r.speed;
        rot = $rot; align = $align; impulse = $imp
    })
}

$rightRot = Useful-PeakAverage ($analysis | Where-Object { $_.rot -gt 0 } | ForEach-Object { $_.rot })
$leftRot = Useful-PeakAverage ($analysis | Where-Object { $_.rot -lt 0 } | ForEach-Object { [Math]::Abs($_.rot) })
$avgRot = ($rightRot + $leftRot) / 2.0
$avgAlign = Median ($analysis | ForEach-Object { [Math]::Abs($_.align) })
$avgImpulse = Avg $analysis { param($x) $x.impulse }
$symmetry = [Math]::Abs($rightRot - $leftRot)
$rotationLabel = Label-Rotation $avgRot $symmetry
$alignmentLabel = Label-Alignment $avgAlign
$impulseLabel = Label-Impulse $avgImpulse
$dominant = if ($rightRot -gt $leftRot + 4) { "DER" } elseif ($leftRot -gt $rightRot + 4) { "IZQ" } else { "parejo" }

# Ciclos/brazadas aproximados por picos de rotación.
$peaks = New-Object System.Collections.Generic.List[double]
$minPeakGap = 0.8
$lastPeakT = -999.0
$threshold = [Math]::Max(8.0, $avgRot * 0.60)
for ($i = 1; $i -lt $analysis.Count - 1; $i++) {
    $a = [Math]::Abs($analysis[$i-1].rot)
    $b = [Math]::Abs($analysis[$i].rot)
    $c = [Math]::Abs($analysis[$i+1].rot)
    if ($b -ge $threshold -and $b -gt $a -and $b -ge $c -and (($analysis[$i].t - $lastPeakT) -ge $minPeakGap)) {
        $peaks.Add($analysis[$i].t)
        $lastPeakT = $analysis[$i].t
    }
}

$cycleSeconds = [double]::NaN
if ($peaks.Count -ge 2) {
    $diffs = for ($i = 1; $i -lt $peaks.Count; $i++) { $peaks[$i] - $peaks[$i - 1] }
    $cycleSeconds = ($diffs | Measure-Object -Average).Average
}
$rhythmLabel = if ([double]::IsNaN($cycleSeconds)) { "sin ciclo claro" } else { ("{0:N1} s/ciclo" -f $cycleSeconds) }

# Distancia GPS: si hay puntos válidos, suma desplazamientos realistas.
$gpsRows = @($rows | Where-Object { -not [double]::IsNaN($_.lat) -and -not [double]::IsNaN($_.lon) -and [Math]::Abs($_.lat) -gt 0.0001 -and [Math]::Abs($_.lon) -gt 0.0001 })
$distanceM = 0.0
if ($gpsRows.Count -gt 1) {
    for ($i = 1; $i -lt $gpsRows.Count; $i++) {
        $d = Distance-Meters $gpsRows[$i - 1] $gpsRows[$i]
        if ($d -lt 80) { $distanceM += $d }
    }
}

function Window-Score($items) {
    if ($items.Count -lt 4) { return -999.0 }
    $rot = Avg $items { param($x) [Math]::Abs($x.rot) }
    $align = Avg $items { param($x) [Math]::Abs($x.align) }
    $imp = Avg $items { param($x) $x.impulse }
    $rotScore = 100 - [Math]::Abs(38 - [Math]::Min(70, $rot)) * 2.0
    $alignScore = 100 - $align * 4.0
    $impScore = if ($imp -lt 0.3) { 35 } else { 100 - [Math]::Abs(1.6 - [Math]::Min(5, $imp)) * 16.0 }
    return $rotScore * .35 + $alignScore * .35 + $impScore * .30
}

$bestScore = -999.0
$bestStart = $analysis[0].t
$bestEnd = $analysis[0].t
$win = if ($duration -lt 30) { [Math]::Max(5, $duration) } else { 30.0 }
$step = [Math]::Max(3.0, $win / 3.0)
for ($start = $analysis[0].t; $start -le ($analysis[$analysis.Count - 1].t - [Math]::Max(1, $win * .5)); $start += $step) {
    $part = @($analysis | Where-Object { $_.t -ge $start -and $_.t -le ($start + $win) })
    $score = Window-Score $part
    if ($score -gt $bestScore) {
        $bestScore = $score
        $bestStart = $start
        $bestEnd = $start + $win
    }
}

$firstSpan = [Math]::Min(30.0, [Math]::Max(5.0, $duration * .20))
$first = @($analysis | Where-Object { $_.t -le ($analysis[0].t + $firstSpan) })
$last = @($analysis | Where-Object { $_.t -ge ($analysis[$analysis.Count - 1].t - $firstSpan) })
$impStart = Avg $first { param($x) $x.impulse }
$impEnd = Avg $last { param($x) $x.impulse }
$alignStart = Avg $first { param($x) [Math]::Abs($x.align) }
$alignEnd = Avg $last { param($x) [Math]::Abs($x.align) }

$simpleRotation = switch ($rotationLabel) {
    "asimetría" { "un lado giró más que el otro. Lado dominante: $dominant." }
    "baja" { "giraste poco el cuerpo; puede faltar rolido para preparar mejor la brazada." }
    "correcta" { "el giro corporal estuvo dentro de una zona útil para nadar." }
    "excesiva" { "giraste demasiado; puede generar pérdida de estabilidad." }
    default { "faltan datos." }
}
$simpleAlignment = switch ($alignmentLabel) {
    "estable" { "el cuerpo se mantuvo bastante parejo." }
    "variable" { "la postura cambió por momentos." }
    "irregular" { "hubo mucha variación; puede aparecer cansancio o pérdida de línea corporal." }
}
$simpleImpulse = switch ($impulseLabel) {
    "suave" { "empuje suave; puede ser nado tranquilo o poca energía de impulso." }
    "normal" { "empuje controlado y parejo." }
    "alto" { "hubo picos fuertes; mirar si fue fuerza útil o movimiento brusco." }
}

$changeText = if (($impEnd - $impStart) -gt 0.4 -and ($alignEnd - $alignStart) -gt 2.0) {
    "al final subió el esfuerzo y cambió la alineación; posible fatiga o técnica menos estable."
} elseif (($impEnd - $impStart) -gt 0.4) {
    "al final subió el empuje; puede haber más fuerza o más esfuerzo."
} elseif (($alignEnd - $alignStart) -gt 2.0) {
    "al final cambió la alineación; revisar si aparece cansancio."
} else {
    "no hubo un cambio fuerte entre inicio y final."
}

$csvName = [IO.Path]::GetFileNameWithoutExtension($CsvPath)
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$safeUser = if ($meta.Contains("USER")) { ($meta["USER"] -replace '[^\w\-]+','_') } else { "SIN_USUARIO" }
$reportBase = "SS-REPORTE-ATLETA-$safeUser-$csvName-$stamp"
$htmlPath = Join-Path $OutDir "$reportBase.html"
$txtPath = Join-Path $OutDir "$reportBase.txt"
$metricsPath = Join-Path $OutDir "$reportBase-metricas.csv"

$metricRows = @(
    "metric,value",
    "archivo,$(Csv-Escape ([IO.Path]::GetFileName($CsvPath)))",
    "atleta,$(Csv-Escape $meta['USER'])",
    "firmware,$(Csv-Escape $meta['FIRMWARE'])",
    "modo,$(Csv-Escape $meta['MODE'])",
    "duracion_s,$([Math]::Round($duration,2))",
    "muestras,$($rows.Count)",
    "rot_der_deg,$([Math]::Round($rightRot,2))",
    "rot_izq_deg,$([Math]::Round($leftRot,2))",
    "rot_prom_deg,$([Math]::Round($avgRot,2))",
    "simetria_diff_deg,$([Math]::Round($symmetry,2))",
    "alineacion_prom_deg,$([Math]::Round($avgAlign,2))",
    "base_pitch_deg,$(if([double]::IsNaN($zeroPitch)){'--'}else{[Math]::Round($zeroPitch,2)})",
    "base_roll_deg,$(if([double]::IsNaN($zeroRoll)){'--'}else{[Math]::Round($zeroRoll,2)})",
    "base_ud,$([Math]::Round($zeroUd,2))",
    "impulso_prom,$([Math]::Round($avgImpulse,2))",
    "brazadas_estimadas,$($peaks.Count)",
    "ritmo_s,$(if([double]::IsNaN($cycleSeconds)){'--'}else{[Math]::Round($cycleSeconds,2)})",
    "gps_puntos,$($gpsRows.Count)",
    "distancia_m,$([Math]::Round($distanceM,2))",
    "mejor_tramo_inicio_s,$([Math]::Round($bestStart,2))",
    "mejor_tramo_fin_s,$([Math]::Round($bestEnd,2))"
)
[IO.File]::WriteAllLines($metricsPath, $metricRows, [Text.UTF8Encoding]::new($true))

function Svg-Trend($data, [int]$width = 900, [int]$height = 260) {
    $padL = 55; $padR = 18; $padT = 20; $padB = 34
    $plotW = $width - $padL - $padR
    $plotH = $height - $padT - $padB
    $minT = $data[0].t; $maxT = $data[$data.Count - 1].t
    if ($maxT -le $minT) { $maxT = $minT + 1 }
    $series = @(
        @{ Name="rotación"; Color="#23d7ef"; Values=($data | ForEach-Object { $_.rot }) },
        @{ Name="alineación"; Color="#ffd166"; Values=($data | ForEach-Object { $_.align }) },
        @{ Name="impulso"; Color="#5be98d"; Values=($data | ForEach-Object { $_.impulse * 8 }) }
    )
    $all = @()
    foreach ($s in $series) { $all += $s.Values }
    $maxAbs = [Math]::Max(5, ($all | ForEach-Object { [Math]::Abs($_) } | Measure-Object -Maximum).Maximum)
    $sb = New-Object Text.StringBuilder
    [void]$sb.Append("<svg viewBox='0 0 $width $height' role='img' aria-label='Tendencia de sesión'>")
    [void]$sb.Append("<rect width='100%' height='100%' rx='10' fill='#071822'/>")
    for ($i=0; $i -le 4; $i++) {
        $y = $padT + $plotH * $i / 4
        [void]$sb.Append("<line x1='$padL' y1='$y' x2='$($width-$padR)' y2='$y' stroke='#214b58' stroke-width='1'/>")
    }
    foreach ($s in $series) {
        $pts = New-Object System.Collections.Generic.List[string]
        for ($i=0; $i -lt $data.Count; $i += [Math]::Max(1, [int]($data.Count / 500))) {
            $x = $padL + (($data[$i].t - $minT) / ($maxT - $minT)) * $plotW
            $y = $padT + ($plotH / 2) - (($s.Values[$i] / $maxAbs) * ($plotH / 2))
            $px = $x.ToString("0.0", [Globalization.CultureInfo]::InvariantCulture)
            $py = $y.ToString("0.0", [Globalization.CultureInfo]::InvariantCulture)
            $pts.Add("$px,$py")
        }
        [void]$sb.Append("<polyline points='$($pts -join " ")' fill='none' stroke='$($s.Color)' stroke-width='3' stroke-linejoin='round' stroke-linecap='round'/>")
    }
    [void]$sb.Append("<text x='70' y='24' fill='#23d7ef' font-size='13'>rotación</text><text x='160' y='24' fill='#ffd166' font-size='13'>alineación</text><text x='260' y='24' fill='#5be98d' font-size='13'>impulso x8</text>")
    [void]$sb.Append("<text x='70' y='$($height-10)' fill='#9bb5bf' font-size='12'>0s</text><text x='$($width-90)' y='$($height-10)' fill='#9bb5bf' font-size='12'>$([Math]::Round($duration))s</text>")
    [void]$sb.Append("</svg>")
    return $sb.ToString()
}

function Svg-Rotation($right, $left, [int]$width = 900, [int]$height = 270) {
    function SvgNum([double]$v) {
        return $v.ToString("0.0", [Globalization.CultureInfo]::InvariantCulture)
    }
    function GaugePoint([double]$cx, [double]$cy, [double]$r, [double]$deg, [string]$side) {
        $d = Clamp $deg 0 60
        $rad = $d * [Math]::PI / 180.0
        if ($side -eq "L") {
            $x = $cx - [Math]::Cos($rad) * $r
            $y = $cy - [Math]::Sin($rad) * $r
        } else {
            $x = $cx + [Math]::Cos($rad) * $r
            $y = $cy - [Math]::Sin($rad) * $r
        }
        return @{ X = $x; Y = $y }
    }
    function ArcPath([double]$cx, [double]$cy, [double]$r, [double]$a1, [double]$a2, [string]$side) {
        $p1 = GaugePoint $cx $cy $r $a1 $side
        $p2 = GaugePoint $cx $cy $r $a2 $side
        $sweep = if ($side -eq "L") { 1 } else { 0 }
        return "M $(SvgNum $p1.X) $(SvgNum $p1.Y) A $(SvgNum $r) $(SvgNum $r) 0 0 $sweep $(SvgNum $p2.X) $(SvgNum $p2.Y)"
    }

    $leftCx = 235; $rightCx = 665; $bodyCx = $width / 2; $cy = 138; $r = 82
    $leftNeedle = GaugePoint $leftCx $cy ($r - 6) $left "L"
    $rightNeedle = GaugePoint $rightCx $cy ($r - 6) $right "R"
    $leftArmEnd = GaugePoint $leftCx $cy 170 $left "L"
    $rightArmEnd = GaugePoint $rightCx $cy 170 $right "R"
    $diff = [Math]::Abs($right - $left)
    $balanceText = if ($diff -le 8) { "simetría buena" } elseif ($diff -le 16) { "diferencia moderada" } else { "diferencia alta" }

    $leftGood = ArcPath $leftCx $cy ($r + 6) 32 45 "L"
    $rightGood = ArcPath $rightCx $cy ($r + 6) 32 45 "R"
    $leftOver = ArcPath $leftCx $cy ($r + 12) 50 60 "L"
    $rightOver = ArcPath $rightCx $cy ($r + 12) 50 60 "R"

    return @"
<svg viewBox='0 0 $width $height' role='img' aria-label='Rotación promedio derecha e izquierda'>
<rect width='100%' height='100%' rx='10' fill='#071822'/>
<line x1='80' y1='$cy' x2='$($width-80)' y2='$cy' stroke='#285665' stroke-width='2'/>
<line x1='$bodyCx' y1='35' x2='$bodyCx' y2='$($height-60)' stroke='#214b58' stroke-width='2'/>

<path d='$leftGood' fill='none' stroke='#5be98d' stroke-width='7' stroke-linecap='round'/>
<path d='$rightGood' fill='none' stroke='#5be98d' stroke-width='7' stroke-linecap='round'/>
<path d='$leftOver' fill='none' stroke='#ff6a00' stroke-width='5' stroke-linecap='round' opacity='.85'/>
<path d='$rightOver' fill='none' stroke='#ff6a00' stroke-width='5' stroke-linecap='round' opacity='.85'/>

<polyline points='$(SvgNum $leftArmEnd.X),$(SvgNum $leftArmEnd.Y) $(SvgNum $leftNeedle.X),$(SvgNum $leftNeedle.Y) $(SvgNum $rightNeedle.X),$(SvgNum $rightNeedle.Y) $(SvgNum $rightArmEnd.X),$(SvgNum $rightArmEnd.Y)' fill='none' stroke='#cfe5eb' stroke-width='5' stroke-linecap='round' stroke-linejoin='round' opacity='.45'/>
<line x1='$leftCx' y1='$cy' x2='$rightCx' y2='$cy' stroke='#5d808a' stroke-width='5' stroke-linecap='round' opacity='.45'/>
<line x1='$leftCx' y1='$cy' x2='$(SvgNum $leftArmEnd.X)' y2='$(SvgNum $leftArmEnd.Y)' stroke='#ff6a00' stroke-width='8' stroke-linecap='round' opacity='.95'/>
<line x1='$rightCx' y1='$cy' x2='$(SvgNum $rightArmEnd.X)' y2='$(SvgNum $rightArmEnd.Y)' stroke='#23d7ef' stroke-width='8' stroke-linecap='round' opacity='.95'/>
<circle cx='$leftCx' cy='$cy' r='8' fill='#cfe5eb'/><circle cx='$rightCx' cy='$cy' r='8' fill='#cfe5eb'/>
<circle cx='$(SvgNum $leftNeedle.X)' cy='$(SvgNum $leftNeedle.Y)' r='11' fill='#ff6a00'/>
<circle cx='$(SvgNum $rightNeedle.X)' cy='$(SvgNum $rightNeedle.Y)' r='11' fill='#23d7ef'/>

<text x='$($leftCx-40)' y='34' fill='#ff6a00' font-size='18' font-weight='800'>IZQ $([Math]::Round($left,1))°</text>
<text x='$($rightCx-42)' y='34' fill='#23d7ef' font-size='18' font-weight='800'>DER $([Math]::Round($right,1))°</text>
<text x='$($leftCx-92)' y='$($cy+34)' fill='#9bb5bf' font-size='13'>0°</text>
<text x='$($rightCx+82)' y='$($cy+34)' fill='#9bb5bf' font-size='13'>0°</text>
<text x='$($leftCx-124)' y='$($cy-82)' fill='#5be98d' font-size='13'>32-45° recomendado</text>
<text x='$($rightCx-8)' y='$($cy-82)' fill='#5be98d' font-size='13'>32-45° recomendado</text>
<text x='$($width/2-125)' y='$($height-42)' fill='#cfe5eb' font-size='16' font-weight='800'>$balanceText | diferencia $([Math]::Round($diff,1))°</text>
<text x='$($width/2-290)' y='$($height-18)' fill='#9bb5bf' font-size='13'>línea clara continua: referencia hombro-brazo; puntos: promedio de picos útiles por lado</text>
</svg>
"@
}

function Svg-Alignment($align, [int]$width = 900, [int]$height = 180) {
    function SvgNum([double]$v) { return $v.ToString("0.0", [Globalization.CultureInfo]::InvariantCulture) }
    $cx = $width / 2; $cy = 86
    $tilt = Clamp $align 0 25
    $angle = $tilt * [Math]::PI / 180.0
    $len = 520
    $dx = [Math]::Cos($angle) * $len / 2
    $dy = [Math]::Sin($angle) * $len / 2
    $x1 = $cx - $dx; $y1 = $cy + $dy
    $x2 = $cx + $dx; $y2 = $cy - $dy
    $state = if ($align -lt 8) { "estable" } elseif ($align -lt 16) { "variable" } else { "irregular" }
    return @"
<svg viewBox='0 0 $width $height' role='img' aria-label='Alineación corporal'>
<rect width='100%' height='100%' rx='10' fill='#071822'/>
<line x1='90' y1='$cy' x2='$($width-90)' y2='$cy' stroke='#285665' stroke-width='2'/>
<line x1='90' y1='$($cy-34)' x2='$($width-90)' y2='$($cy-34)' stroke='#5be98d' stroke-width='2' stroke-dasharray='8 8' opacity='.75'/>
<line x1='90' y1='$($cy+34)' x2='$($width-90)' y2='$($cy+34)' stroke='#5be98d' stroke-width='2' stroke-dasharray='8 8' opacity='.75'/>
<line x1='$(SvgNum $x1)' y1='$(SvgNum $y1)' x2='$(SvgNum $x2)' y2='$(SvgNum $y2)' stroke='#89a7ff' stroke-width='10' stroke-linecap='round'/>
<circle cx='$cx' cy='$cy' r='18' fill='#cfe5eb' opacity='.95'/>
<text x='80' y='35' fill='#9bb5bf' font-size='14'>línea del cuerpo</text>
<text x='$($width-250)' y='35' fill='#89a7ff' font-size='18' font-weight='800'>$state | $([Math]::Round($align,1))°</text>
<text x='80' y='$($height-18)' fill='#9bb5bf' font-size='13'>si esta línea se inclina mucho, el cuerpo pierde alineación y puede aumentar el esfuerzo</text>
</svg>
"@
}

function Svg-Impulse($impulse, [int]$width = 900, [int]$height = 150) {
    $max = 4.0
    $barW = [Math]::Min(1.0, $impulse / $max) * 640
    $label = if ($impulse -lt 0.8) { "suave" } elseif ($impulse -lt 2.5) { "normal" } else { "alto" }
    return @"
<svg viewBox='0 0 $width $height' role='img' aria-label='Impulso observado'>
<rect width='100%' height='100%' rx='10' fill='#071822'/>
<line x1='110' y1='78' x2='790' y2='78' stroke='#285665' stroke-width='18' stroke-linecap='round'/>
<line x1='110' y1='78' x2='$([Math]::Round(110 + $barW,1))' y2='78' stroke='#5be98d' stroke-width='18' stroke-linecap='round'/>
<line x1='238' y1='48' x2='238' y2='108' stroke='#ffd166' stroke-width='2'/><line x1='510' y1='48' x2='510' y2='108' stroke='#ff6a00' stroke-width='2'/>
<text x='105' y='35' fill='#9bb5bf' font-size='13'>suave</text><text x='316' y='35' fill='#9bb5bf' font-size='13'>normal</text><text x='612' y='35' fill='#9bb5bf' font-size='13'>alto/picos</text>
<text x='105' y='130' fill='#cfe5eb' font-size='16' font-weight='800'>empuje $label | $([Math]::Round($impulse,2)) promedio</text>
</svg>
"@
}

$trendSvg = Svg-Trend $analysis
$rotationSvg = Svg-Rotation $rightRot $leftRot
$alignmentSvg = Svg-Alignment $avgAlign
$impulseSvg = Svg-Impulse $avgImpulse

$summaryText = @"
SAVE SWIMMER - REPORTE AUTOMÁTICO DE SESIÓN
Atleta: $($meta["USER"])
Archivo: $([IO.Path]::GetFileName($CsvPath))
Duración: $(Fmt-Seconds $duration) | Muestras: $($rows.Count)

Rotación: $rotationLabel. $simpleRotation
Alineación: $alignmentLabel. $simpleAlignment
Impulso: $impulseLabel. $simpleImpulse
Ritmo: $rhythmLabel | Brazadas/ciclos detectados: $($peaks.Count)
GPS: $($gpsRows.Count) puntos válidos | Distancia aproximada: $([Math]::Round($distanceM,1)) m
Mejor tramo: $(Fmt-Seconds $bestStart) a $(Fmt-Seconds $bestEnd)
Cambio observado: $changeText

Nota: lectura técnica/deportiva experimental. No es diagnóstico médico.
"@
[IO.File]::WriteAllText($txtPath, $summaryText, [Text.UTF8Encoding]::new($true))

$html = @"
<!doctype html>
<html lang="es-PE">
<head>
<meta charset="utf-8">
<title>$(Html $reportBase)</title>
<style>
:root{--bg:#06151d;--panel:#0b2632;--line:#1d5263;--cyan:#23d7ef;--orange:#ff6a00;--green:#5be98d;--text:#eef8fb;--muted:#9bb5bf}
*{box-sizing:border-box} body{margin:0;background:#eef4f6;font-family:Calibri,Arial,sans-serif;color:#12232d}.page{width:210mm;min-height:297mm;margin:0 auto;background:white;padding:13mm}
header{background:var(--bg);color:var(--text);padding:18px 20px;border-radius:14px;margin-bottom:14px}h1{margin:0;letter-spacing:3px;font-size:28px}.sub{color:var(--cyan);font-weight:700;font-size:18px;margin-top:4px}.meta{color:#c8d7dc;margin-top:8px;font-size:13px}
.grid{display:grid;grid-template-columns:1fr 1fr;gap:10px}.card{border:1px solid #c7d6dc;border-radius:10px;padding:12px;background:#fbfdfe;break-inside:avoid}.dark{background:var(--panel);border-color:var(--line);color:var(--text)}
h2{font-size:16px;margin:0 0 8px;color:#071822}.dark h2{color:var(--cyan)}.big{font-size:26px;font-weight:800;margin:2px 0}.muted{color:#60737c}.dark .muted{color:var(--muted)}
.span{grid-column:1 / -1}.pill{display:inline-block;padding:4px 9px;border-radius:20px;background:#eaf7fa;color:#007f96;font-weight:700;margin-right:6px}.warn{border-left:5px solid var(--orange);padding:8px 10px;background:#fff7ef;font-size:13px;margin:10px 0}.kid{font-size:18px;line-height:1.35}
footer{margin-top:12px;font-size:11px;color:#60737c;display:flex;justify-content:space-between}
@media print{body{background:white}.page{margin:0;width:auto;min-height:auto}.card{break-inside:avoid}}
</style>
</head>
<body>
<main class="page">
<header>
  <h1>SAVE SWIMMER</h1>
  <div class="sub">REPORTE AUTOMÁTICO PARA ATLETA</div>
  <div class="meta">Archivo: $(Html ([IO.Path]::GetFileName($CsvPath))) | Atleta: $(Html $meta["USER"]) | Firmware: $(Html $meta["FIRMWARE"])</div>
</header>
<div class="warn">Lectura técnica/deportiva experimental. No es diagnóstico médico ni reemplaza supervisión profesional.</div>
<section class="grid">
  <div class="card"><h2>Duración</h2><div class="big">$(Fmt-Seconds $duration)</div><div class="muted">$($rows.Count) muestras válidas</div></div>
  <div class="card"><h2>GPS</h2><div class="big">$([Math]::Round($distanceM,1)) m</div><div class="muted">$($gpsRows.Count) puntos válidos</div></div>
  <div class="card"><h2>Rotación</h2><div class="big">$rotationLabel</div><div class="muted">picos útiles: DER $([Math]::Round($rightRot,1))° / IZQ $([Math]::Round($leftRot,1))°</div></div>
  <div class="card"><h2>Alineación</h2><div class="big">$alignmentLabel</div><div class="muted">$([Math]::Round($avgAlign,1))° promedio</div></div>
  <div class="card"><h2>Impulso</h2><div class="big">$impulseLabel</div><div class="muted">$([Math]::Round($avgImpulse,2)) promedio</div></div>
  <div class="card"><h2>Ritmo</h2><div class="big">$rhythmLabel</div><div class="muted">$($peaks.Count) ciclos/brazadas detectados</div></div>
  <div class="card span"><h2>Resumen para entender rápido</h2><div class="kid">
    <p><b>Rotación:</b> $(Html $simpleRotation)</p>
    <p><b>Alineación:</b> $(Html $simpleAlignment)</p>
    <p><b>Empuje:</b> $(Html $simpleImpulse)</p>
    <p><b>Mejor tramo:</b> de $(Fmt-Seconds $bestStart) a $(Fmt-Seconds $bestEnd). Fue el tramo con mejor mezcla entre giro, línea corporal e impulso.</p>
    <p><b>Cambio durante la sesión:</b> $(Html $changeText)</p>
  </div></div>
  <div class="card dark span"><h2>Tendencia de la sesión</h2>$trendSvg</div>
  <div class="card dark span"><h2>Rotación y simetría</h2>$rotationSvg</div>
  <div class="card dark span"><h2>Alineación corporal</h2>$alignmentSvg</div>
  <div class="card dark span"><h2>Impulso / empuje</h2>$impulseSvg</div>
  <div class="card span"><h2>Qué mirar en la próxima prueba</h2>
    <span class="pill">mismo atleta</span><span class="pill">mismo código</span><span class="pill">misma distancia</span>
    <p>Comparar si el lado dominante se reduce, si la alineación se mantiene estable y si el impulso aumenta sin perder línea corporal.</p>
  </div>
</section>
<footer><span>@saveswimmer | saveswimmer@gmail.com</span><span>Probamos hoy para proteger mañana.</span></footer>
</main>
</body>
</html>
"@
[IO.File]::WriteAllText($htmlPath, $html, [Text.UTF8Encoding]::new($true))

Write-Host "Reporte generado:"
Write-Host $htmlPath
Write-Host $txtPath
Write-Host $metricsPath
