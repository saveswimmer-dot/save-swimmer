param(
  [string]$Port = "",
  [int]$Baud = 115200,
  [string]$OutDir = "calibracion_usb",
  [int]$BaseSeconds = 3
)

$ErrorActionPreference = "Stop"

function Clamp-Value([double]$v, [double]$min, [double]$max) {
  if ($v -lt $min) { return $min }
  if ($v -gt $max) { return $max }
  return $v
}

function Get-Prop($obj, [string]$name, [double]$default = 0.0) {
  if ($null -eq $obj) { return $default }
  $p = $obj.PSObject.Properties[$name]
  if ($null -eq $p) { return $default }
  if ($null -eq $p.Value) { return $default }
  try { return [double]$p.Value } catch { return $default }
}

function Average-Prop($rows, [string]$name) {
  $vals = @()
  foreach ($r in $rows) {
    $p = $r.PSObject.Properties[$name]
    if ($null -ne $p -and $null -ne $p.Value) {
      try { $vals += [double]$p.Value } catch {}
    }
  }
  if ($vals.Count -eq 0) { return 0.0 }
  return (($vals | Measure-Object -Average).Average)
}

function New-PhaseStats($name) {
  [pscustomobject]@{
    Name = $name
    Count = 0
    RotMaxDer = 0.0
    RotMaxIzq = 0.0
    AlignMax = 0.0
    MagMax = 0.0
  }
}

Write-Host "========================================"
Write-Host "SAVE SWIMMER - CALIBRACION USB SERIAL"
Write-Host "========================================"
Write-Host ""

if ([string]::IsNullOrWhiteSpace($Port)) {
  $ports = [System.IO.Ports.SerialPort]::GetPortNames() | Sort-Object
  if ($ports.Count -eq 0) {
    Write-Host "No encontre puertos COM. Conecta el ESP por USB y vuelve a intentar."
    exit 1
  }
  Write-Host "Puertos detectados:"
  for ($i = 0; $i -lt $ports.Count; $i++) {
    Write-Host ("  {0}. {1}" -f ($i + 1), $ports[$i])
  }
  $choice = (Read-Host "Elige numero de puerto COM o escribe el puerto completo, ej COM5").Trim()
  if ($choice -match '^(?i)COM\d+$') {
    $Port = $choice.ToUpper()
  } else {
    try {
      $idx = [int]$choice - 1
    } catch {
      Write-Host "Seleccion invalida. Usa un numero de la lista o escribe algo como COM5."
      exit 1
    }
    if ($idx -lt 0 -or $idx -ge $ports.Count) {
      Write-Host "Seleccion invalida."
      exit 1
    }
    $Port = $ports[$idx]
  }
}

New-Item -ItemType Directory -Force $OutDir | Out-Null
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logPath = Join-Path $OutDir ("SS-CALIBRACION-USB-{0}.csv" -f $stamp)
$summaryPath = Join-Path $OutDir ("SS-CALIBRACION-USB-{0}-RESUMEN.txt" -f $stamp)

$header = "pc_time,elapsed_s,phase,lr,fb,ud,mag,pitch,roll,rot_deg,align_deg,input_v,current_ma,lat,lon,raw"
Set-Content -Path $logPath -Value $header -Encoding UTF8

$serial = New-Object System.IO.Ports.SerialPort $Port, $Baud, "None", 8, "One"
$serial.ReadTimeout = 250
$serial.NewLine = "`n"

$base = [pscustomobject]@{
  Ready = $false
  LR = 0.0
  FB = 0.0
  UD = 0.0
  MAG = 0.0
  PITCH = 0.0
  ROLL = 0.0
}

$phase = "LIBRE"
$phaseStats = @{}
$phaseStats[$phase] = New-PhaseStats $phase
$recent = New-Object System.Collections.ArrayList
$allCount = 0
$jsonCount = 0
$start = Get-Date
$lastPrint = Get-Date

Write-Host ""
Write-Host "Abriendo $Port a $Baud..."
$serial.Open()
Start-Sleep -Milliseconds 500
$serial.DiscardInBuffer()

Write-Host ""
Write-Host "TECLAS:"
Write-Host "  B = tomar base con ultimos $BaseSeconds segundos"
Write-Host "  1 = quieto / mesa"
Write-Host "  2 = rotacion derecha"
Write-Host "  3 = rotacion izquierda"
Write-Host "  4 = alineacion UD / cabeza-cuerpo"
Write-Host "  5 = impulso MAG"
Write-Host "  Q = cerrar calibracion"
Write-Host ""
Write-Host "Primero deja el dispositivo quieto, espera 3 segundos y presiona B."
Write-Host ""

try {
  while ($true) {
    if ([Console]::KeyAvailable) {
      $key = [Console]::ReadKey($true).Key
      if ($key -eq "Q") { break }
      if ($key -eq "B") {
        $cut = (Get-Date).AddSeconds(-1 * $BaseSeconds)
        $baseRows = @($recent | Where-Object { $_.pc_time_dt -ge $cut })
        if ($baseRows.Count -lt 5) {
          Write-Host "Base no tomada: faltan muestras recientes."
        } else {
          $base.LR = Average-Prop $baseRows "LR"
          $base.FB = Average-Prop $baseRows "FB"
          $base.UD = Average-Prop $baseRows "UD"
          $base.MAG = Average-Prop $baseRows "MAG"
          $base.PITCH = Average-Prop $baseRows "PITCH"
          $base.ROLL = Average-Prop $baseRows "ROLL"
          $base.Ready = $true
          Write-Host ("BASE OK | LR {0:n2} FB {1:n2} UD {2:n2} MAG {3:n2} PITCH {4:n1} ROLL {5:n1}" -f $base.LR,$base.FB,$base.UD,$base.MAG,$base.PITCH,$base.ROLL)
        }
      }
      if ($key -eq "D1") { $phase = "QUIETO_MESA" }
      if ($key -eq "D2") { $phase = "ROT_DERECHA" }
      if ($key -eq "D3") { $phase = "ROT_IZQUIERDA" }
      if ($key -eq "D4") { $phase = "ALINEACION_UD" }
      if ($key -eq "D5") { $phase = "IMPULSO_MAG" }
      if (-not $phaseStats.ContainsKey($phase)) { $phaseStats[$phase] = New-PhaseStats $phase }
    }

    $line = $null
    try {
      $line = $serial.ReadLine().Trim()
    } catch [System.TimeoutException] {
      continue
    }

    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $allCount++
    if (-not ($line.StartsWith("{") -and $line.EndsWith("}"))) { continue }

    try {
      $obj = $line | ConvertFrom-Json
    } catch {
      continue
    }

    $jsonCount++
    $now = Get-Date
    $elapsed = ($now - $start).TotalSeconds
    $lr = Get-Prop $obj "LR"
    $fb = Get-Prop $obj "FB"
    $ud = Get-Prop $obj "UD"
    $mag = Get-Prop $obj "MAG"
    $pitch = Get-Prop $obj "PITCH"
    $roll = Get-Prop $obj "ROLL"
    $inputV = Get-Prop $obj "INPUT_V"
    $currentMa = Get-Prop $obj "CURRENT_MA"
    $lat = Get-Prop $obj "LAT"
    $lon = Get-Prop $obj "LON"

    $rotDeg = 0.0
    $alignDeg = 0.0
    if ($base.Ready) {
      $rotDeg = [Math]::Asin((Clamp-Value (($lr - $base.LR) / 9.81) -1 1)) * 180.0 / [Math]::PI
      if ($obj.PSObject.Properties["PITCH"]) {
        $alignDeg = $pitch - $base.PITCH
      } else {
        $alignDeg = [Math]::Asin((Clamp-Value (($ud - $base.UD) / 9.81) -1 1)) * 180.0 / [Math]::PI
      }
    }

    $rowObj = [pscustomobject]@{
      pc_time_dt = $now
      LR = $lr
      FB = $fb
      UD = $ud
      MAG = $mag
      PITCH = $pitch
      ROLL = $roll
      ROT = $rotDeg
      ALIGN = $alignDeg
    }
    [void]$recent.Add($rowObj)
    while ($recent.Count -gt 600) { $recent.RemoveAt(0) }

    $stat = $phaseStats[$phase]
    $stat.Count++
    if ($rotDeg -gt $stat.RotMaxDer) { $stat.RotMaxDer = $rotDeg }
    if ((-1 * $rotDeg) -gt $stat.RotMaxIzq) { $stat.RotMaxIzq = -1 * $rotDeg }
    if ([Math]::Abs($alignDeg) -gt $stat.AlignMax) { $stat.AlignMax = [Math]::Abs($alignDeg) }
    if ([Math]::Abs($mag - $base.MAG) -gt $stat.MagMax) { $stat.MagMax = [Math]::Abs($mag - $base.MAG) }

    $safeRaw = $line.Replace('"','""')
    $csvLine = ('"{0}",{1:n2},"{2}",{3:n3},{4:n3},{5:n3},{6:n3},{7:n2},{8:n2},{9:n2},{10:n2},{11:n3},{12:n2},{13:n6},{14:n6},"{15}"' -f `
      ($now.ToString("yyyy-MM-dd HH:mm:ss.fff")), $elapsed, $phase, $lr, $fb, $ud, $mag, $pitch, $roll, $rotDeg, $alignDeg, $inputV, $currentMa, $lat, $lon, $safeRaw)
    Add-Content -Path $logPath -Value $csvLine -Encoding UTF8

    if (($now - $lastPrint).TotalMilliseconds -ge 500) {
      $lastPrint = $now
      $baseText = "SIN_BASE"
      if ($base.Ready) { $baseText = "BASE_OK" }
      Write-Host ("{0,7:n1}s | {1,-14} | {2} | LR {3,6:n2} UD {4,6:n2} MAG {5,6:n2} | ROT {6,6:n1} ALIGN {7,6:n1}" -f $elapsed, $phase, $baseText, $lr, $ud, $mag, $rotDeg, $alignDeg)
    }
  }
}
finally {
  if ($serial.IsOpen) { $serial.Close() }
}

$summary = @()
$summary += "SAVE SWIMMER - RESUMEN CALIBRACION USB"
$summary += "Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$summary += "Puerto: $Port"
$summary += "Baud: $Baud"
$summary += "Log: $logPath"
$summary += ""
$summary += "Muestras JSON: $jsonCount"
$summary += "Lineas totales leidas: $allCount"
$summary += ""
$summary += "Base:"
$summary += ("LR {0:n3} | FB {1:n3} | UD {2:n3} | MAG {3:n3} | PITCH {4:n2} | ROLL {5:n2}" -f $base.LR,$base.FB,$base.UD,$base.MAG,$base.PITCH,$base.ROLL)
$summary += ""
$summary += "Fases:"
foreach ($k in ($phaseStats.Keys | Sort-Object)) {
  $s = $phaseStats[$k]
  $summary += ("{0}: muestras {1}, rot der max {2:n1}, rot izq max {3:n1}, alineacion max {4:n1}, energia MAG max {5:n2}" -f $s.Name,$s.Count,$s.RotMaxDer,$s.RotMaxIzq,$s.AlignMax,$s.MagMax)
}

Set-Content -Path $summaryPath -Value $summary -Encoding UTF8

Write-Host ""
Write-Host "Calibracion cerrada."
Write-Host "CSV: $logPath"
Write-Host "Resumen: $summaryPath"
