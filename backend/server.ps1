param(
  [int]$Port = 8787
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$PublicDir = Join-Path $Root "public"
$DataDir = Join-Path $Root "data"
$DbFile = Join-Path $DataDir "save_swimmer_db.json"
$AssetsDir = Join-Path (Split-Path -Parent $Root) "assets"
$MaxTelemetryPerDevice = 10000

function New-Db {
  $now = (Get-Date).ToUniversalTime().ToString("o")
  return [ordered]@{
    version = 1
    createdAt = $now
    updatedAt = $now
    devices = [pscustomobject]@{}
    telemetry = [pscustomobject]@{}
    alerts = @()
    sessions = [pscustomobject]@{}
  }
}

function Ensure-Db {
  if (!(Test-Path $DataDir)) {
    New-Item -ItemType Directory -Path $DataDir -Force | Out-Null
  }
  if (!(Test-Path $DbFile)) {
    Write-Db (New-Db)
  }
}

function Read-Db {
  Ensure-Db
  return Get-Content -LiteralPath $DbFile -Raw | ConvertFrom-Json
}

function Write-Db($db) {
  $db.updatedAt = (Get-Date).ToUniversalTime().ToString("o")
  $db | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $DbFile -Encoding UTF8
}

function Send-Text($context, [int]$status, [string]$text, [string]$contentType = "text/plain; charset=utf-8") {
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($text)
  $reason = if ($status -eq 200) { "OK" } elseif ($status -eq 201) { "Created" } elseif ($status -eq 400) { "Bad Request" } elseif ($status -eq 403) { "Forbidden" } elseif ($status -eq 404) { "Not Found" } else { "Error" }
  $headers = "HTTP/1.1 $status $reason`r`nContent-Type: $contentType`r`nContent-Length: $($bytes.Length)`r`nConnection: close`r`n`r`n"
  $headerBytes = [System.Text.Encoding]::ASCII.GetBytes($headers)
  $context.Stream.Write($headerBytes, 0, $headerBytes.Length)
  $context.Stream.Write($bytes, 0, $bytes.Length)
  $context.Stream.Flush()
}

function Send-Json($context, [int]$status, $body) {
  $json = $body | ConvertTo-Json -Depth 20
  Send-Text $context $status $json "application/json; charset=utf-8"
}

function Read-Body($request) {
  return [string]$request.Body
}

function Set-Prop($obj, [string]$name, $value) {
  if ($obj.PSObject.Properties[$name]) {
    $obj.$name = $value
  } else {
    $obj | Add-Member -NotePropertyName $name -NotePropertyValue $value
  }
}

function Get-Prop($obj, [string]$name, $fallback = $null) {
  if ($null -eq $obj) { return $fallback }
  if ($obj.PSObject.Properties[$name]) { return $obj.$name }
  return $fallback
}

function To-Number($value) {
  if ($null -eq $value -or "$value" -eq "") { return $null }
  $n = 0.0
  if ([double]::TryParse("$value", [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$n)) {
    return $n
  }
  return $null
}

function To-Bool($value) {
  if ($value -is [bool]) { return $value }
  if ($null -eq $value -or "$value" -eq "") { return $null }
  $text = "$value".ToLowerInvariant()
  if (@("yes", "true", "1", "agua", "water") -contains $text) { return $true }
  if (@("no", "false", "0", "seco", "dry") -contains $text) { return $false }
  return $null
}

function Normalize-Telemetry($payload) {
  $now = (Get-Date).ToUniversalTime().ToString("o")
  $serial = ([string](Get-Prop $payload 'serial' (Get-Prop $payload 'device' 'SS-LT-000001'))).Trim()
  $user = ([string](Get-Prop $payload 'user' (Get-Prop $payload 'name' 'SIN_USUARIO'))).Trim()
  $mode = ([string](Get-Prop $payload 'mode' 'FIELD_TEST')).Trim()
  $time = ([string](Get-Prop $payload 'time' (Get-Prop $payload 'timestamp' $now))).Trim()
  $defaultSessionId = "$serial-$user-$((Get-Date).ToString('yyyy-MM-dd'))"
  $sessionId = ([string](Get-Prop $payload 'sessionId' (Get-Prop $payload 'session_id' $defaultSessionId))).Trim()

  return [pscustomobject]@{
    id = "$([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())-$([guid]::NewGuid().ToString("N").Substring(0,8))"
    serial = $serial
    user = $user
    mode = $mode
    time = $time
    receivedAt = $now
    sessionId = $sessionId
    lr = To-Number (Get-Prop $payload "lr" (Get-Prop $payload "LR"))
    fb = To-Number (Get-Prop $payload "fb" (Get-Prop $payload "FB"))
    ud = To-Number (Get-Prop $payload "ud" (Get-Prop $payload "UD"))
    mag = To-Number (Get-Prop $payload "mag" (Get-Prop $payload "MAG"))
    pitch = To-Number (Get-Prop $payload "pitch" (Get-Prop $payload "PITCH"))
    roll = To-Number (Get-Prop $payload "roll" (Get-Prop $payload "ROLL"))
    lat = To-Number (Get-Prop $payload "lat" (Get-Prop $payload "latitude"))
    lon = To-Number (Get-Prop $payload "lon" (Get-Prop $payload "longitude"))
    baseLat = To-Number (Get-Prop $payload "baseLat" (Get-Prop $payload "base_lat"))
    baseLon = To-Number (Get-Prop $payload "baseLon" (Get-Prop $payload "base_lon"))
    gpsAccuracy = To-Number (Get-Prop $payload "gpsAccuracy" (Get-Prop $payload "gps_accuracy"))
    speed = To-Number (Get-Prop $payload "speed")
    pace100m = To-Number (Get-Prop $payload "pace100m" (Get-Prop $payload "pace_100m"))
    battery = To-Number (Get-Prop $payload "battery" (Get-Prop $payload "batt" (Get-Prop $payload "BATT")))
    water = To-Bool (Get-Prop $payload "water")
    motion = [string](Get-Prop $payload 'motion' (Get-Prop $payload 'motionState' 'UNKNOWN'))
    body = [string](Get-Prop $payload 'body' (Get-Prop $payload 'bodyState' 'UNKNOWN'))
    risk = [string](Get-Prop $payload 'risk' (Get-Prop $payload 'riskState' 'NORMAL'))
    signal = To-Number (Get-Prop $payload "signal" (Get-Prop $payload "rssi"))
    gateway = [string](Get-Prop $payload 'gateway' '')
    raw = Get-Prop $payload "raw"
  }
}

function Upsert-Telemetry($sample) {
  $db = Read-Db
  $serial = $sample.serial

  if (!(Get-Prop $db.devices $serial)) {
    Set-Prop $db.devices $serial ([pscustomobject]@{
      serial = $serial
      model = "Lite Prototype"
      firmware = "UNKNOWN"
      createdAt = (Get-Date).ToUniversalTime().ToString("o")
      status = "ACTIVE"
    })
  }

  $device = Get-Prop $db.devices $serial
  Set-Prop $device "user" $sample.user
  Set-Prop $device "mode" $sample.mode
  Set-Prop $device "latest" $sample
  Set-Prop $device "lastSeenAt" $sample.receivedAt
  Set-Prop $device "battery" $sample.battery
  Set-Prop $device "water" $sample.water
  Set-Prop $device "risk" $sample.risk
  Set-Prop $device "motion" $sample.motion

  $rows = Get-Prop $db.telemetry $serial
  if ($null -eq $rows) { $rows = @() }
  $rows = @($rows) + $sample
  if ($rows.Count -gt $MaxTelemetryPerDevice) {
    $rows = $rows[($rows.Count - $MaxTelemetryPerDevice)..($rows.Count - 1)]
  }
  Set-Prop $db.telemetry $serial $rows

  $session = Get-Prop $db.sessions $sample.sessionId
  if ($null -eq $session) {
    $session = [pscustomobject]@{
      id = $sample.sessionId
      serial = $serial
      user = $sample.user
      mode = $sample.mode
      startedAt = $sample.time
      createdAt = $sample.receivedAt
      sampleCount = 0
      status = "ACTIVE"
    }
    Set-Prop $db.sessions $sample.sessionId $session
  }
  $session.sampleCount = [int]$session.sampleCount + 1
  Set-Prop $session "lastSampleAt" $sample.time
  Set-Prop $session "latest" $sample

  if (@("WATCH", "WARNING", "SOS", "EMERGENCY") -contains $sample.risk.ToUpperInvariant()) {
    $alert = [pscustomobject]@{
      id = $sample.id
      serial = $serial
      user = $sample.user
      risk = $sample.risk
      motion = $sample.motion
      water = $sample.water
      lat = $sample.lat
      lon = $sample.lon
      time = $sample.time
      receivedAt = $sample.receivedAt
      status = "ACTIVE"
    }
    $db.alerts = @($alert) + @($db.alerts) | Select-Object -First 500
  }

  Write-Db $db
  return $sample
}

function Send-File($context, [string]$filePath) {
  if (!(Test-Path $filePath) -or (Get-Item $filePath).PSIsContainer) {
    Send-Text $context 404 "Not found"
    return
  }

  $ext = [IO.Path]::GetExtension($filePath).ToLowerInvariant()
  $types = @{
    ".html" = "text/html; charset=utf-8"
    ".js" = "application/javascript; charset=utf-8"
    ".css" = "text/css; charset=utf-8"
    ".json" = "application/json; charset=utf-8"
    ".jpg" = "image/jpeg"
    ".jpeg" = "image/jpeg"
    ".png" = "image/png"
  }
  $contentType = if ($types.ContainsKey($ext)) { $types[$ext] } else { "application/octet-stream" }
  $bytes = [IO.File]::ReadAllBytes($filePath)
  $headers = "HTTP/1.1 200 OK`r`nContent-Type: $contentType`r`nContent-Length: $($bytes.Length)`r`nConnection: close`r`n`r`n"
  $headerBytes = [System.Text.Encoding]::ASCII.GetBytes($headers)
  $context.Stream.Write($headerBytes, 0, $headerBytes.Length)
  $context.Stream.Write($bytes, 0, $bytes.Length)
  $context.Stream.Flush()
}

function Handle-Api($context, $path, $query) {
  $method = $context.Request.HttpMethod
  if ($method -eq "OPTIONS") {
    Send-Json $context 200 @{ ok = $true }
    return
  }

  if ($method -eq "GET" -and $path -eq "/api/health") {
    $db = Read-Db
    Send-Json $context 200 @{
      ok = $true
      service = "save-swimmer-backend-powershell"
      devices = @($db.devices.PSObject.Properties).Count
      updatedAt = $db.updatedAt
    }
    return
  }

  if ($method -eq "POST" -and $path -eq "/api/telemetry") {
    try {
      $body = Read-Body $context.Request
      $input = if ($body.Trim().Length -gt 0) { $body | ConvertFrom-Json } else { [pscustomobject]@{} }
      $sample = Upsert-Telemetry (Normalize-Telemetry $input)
      Send-Json $context 201 @{ ok = $true; sample = $sample }
    } catch {
      Send-Json $context 400 @{ ok = $false; error = $_.Exception.Message }
    }
    return
  }

  if ($method -eq "POST" -and $path -eq "/api/reset") {
    Write-Db (New-Db)
    Send-Json $context 200 @{ ok = $true; resetAt = (Get-Date).ToUniversalTime().ToString("o") }
    return
  }

  if ($method -eq "POST" -and $path -eq "/api/simulate") {
    $t = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $input = [pscustomobject]@{
      serial = "SS-LT-000001"
      user = "Demo Agua Dulce"
      mode = "FIELD_TEST"
      time = (Get-Date).ToUniversalTime().ToString("o")
      lat = -12.1609 + [Math]::Sin($t / 20) * 0.003
      lon = -77.0309 + [Math]::Cos($t / 28) * 0.004
      baseLat = -12.1609
      baseLon = -77.0309
      lr = [Math]::Sin($t * 2.1) * 4
      fb = [Math]::Cos($t * 1.4) * 2
      ud = 8.9 + [Math]::Sin($t * 1.1)
      mag = 9.6 + [Math]::Sin($t * 3) * 0.4
      battery = [Math]::Max(18, 92 - (($t / 10) % 30))
      water = $true
      motion = "SWIMMING"
      risk = "NORMAL"
      speed = 1.15 + [Math]::Sin($t / 8) * 0.18
      pace100m = 95 + [Math]::Sin($t / 12) * 9
      signal = -72
    }
    $sample = Upsert-Telemetry (Normalize-Telemetry $input)
    Send-Json $context 201 @{ ok = $true; sample = $sample }
    return
  }

  if ($method -eq "GET" -and $path -eq "/api/coach-live") {
    $db = Read-Db
    $limit = 300
    if ($query["limit"]) { $limit = [Math]::Min(1000, [int]$query["limit"]) }

    $devices = @($db.devices.PSObject.Properties | ForEach-Object { $_.Value })
    $active = $null
    $activeTime = [DateTime]::MinValue
    foreach ($device in $devices) {
      $seen = [string](Get-Prop $device "lastSeenAt" "")
      $parsed = [DateTime]::MinValue
      if ([DateTime]::TryParse($seen, [ref]$parsed) -and $parsed -gt $activeTime) {
        $active = $device
        $activeTime = $parsed
      }
    }

    $rows = @()
    if ($null -ne $active) {
      $serial = [string](Get-Prop $active "serial" "")
      $rows = @(Get-Prop $db.telemetry $serial @())
      if ($rows.Count -gt $limit) { $rows = $rows[($rows.Count - $limit)..($rows.Count - 1)] }
    }

    Send-Json $context 200 @{
      ok = $true
      mode = "coach-live-optimized"
      pollRecommendedMs = 5000
      devices = $devices
      active = $active
      telemetry = $rows
      updatedAt = $db.updatedAt
    }
    return
  }

  if ($method -eq "GET" -and $path -eq "/api/devices") {
    $db = Read-Db
    Send-Json $context 200 @{ ok = $true; devices = @($db.devices.PSObject.Properties | ForEach-Object { $_.Value }) }
    return
  }

  if ($method -eq "GET" -and $path -match "^/api/devices/([^/]+)/latest$") {
    $db = Read-Db
    $serial = [uri]::UnescapeDataString($Matches[1])
    $device = Get-Prop $db.devices $serial
    Send-Json $context 200 @{ ok = $true; latest = (Get-Prop $device "latest") }
    return
  }

  if ($method -eq "GET" -and $path -match "^/api/devices/([^/]+)/telemetry$") {
    $db = Read-Db
    $serial = [uri]::UnescapeDataString($Matches[1])
    $limit = 300
    if ($query["limit"]) { $limit = [Math]::Min(5000, [int]$query["limit"]) }
    $rows = @(Get-Prop $db.telemetry $serial @())
    if ($rows.Count -gt $limit) { $rows = $rows[($rows.Count - $limit)..($rows.Count - 1)] }
    Send-Json $context 200 @{ ok = $true; telemetry = $rows }
    return
  }

  if ($method -eq "GET" -and $path -eq "/api/sessions") {
    $db = Read-Db
    $sessions = @($db.sessions.PSObject.Properties | ForEach-Object { $_.Value })
    if ($query["serial"]) { $sessions = $sessions | Where-Object { $_.serial -eq $query["serial"] } }
    Send-Json $context 200 @{ ok = $true; sessions = $sessions }
    return
  }

  if ($method -eq "GET" -and $path -eq "/api/alerts/active") {
    $db = Read-Db
    Send-Json $context 200 @{ ok = $true; alerts = @($db.alerts | Where-Object { $_.status -eq "ACTIVE" }) }
    return
  }

  Send-Json $context 404 @{ ok = $false; error = "API route not found" }
}

Ensure-Db

$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $Port)
$prefix = "http://localhost:$Port/"
$listener.Start()

Write-Host "========================================"
Write-Host "SAVE SWIMMER BACKEND"
Write-Host "========================================"
Write-Host "Dashboard: $prefix"
Write-Host "POST telemetry: $prefix`api/telemetry"
Write-Host "Presiona Ctrl+C para detener."

try {
  while ($true) {
    $client = $listener.AcceptTcpClient()
    $stream = $client.GetStream()

    try {
      $buffer = New-Object byte[] 1048576
      $count = $stream.Read($buffer, 0, $buffer.Length)
      if ($count -le 0) {
        $client.Close()
        continue
      }

      $requestText = [System.Text.Encoding]::UTF8.GetString($buffer, 0, $count)
      $parts = $requestText -split "`r`n`r`n", 2
      $headerText = $parts[0]
      $bodyText = if ($parts.Count -gt 1) { $parts[1] } else { "" }
      $headerLines = $headerText -split "`r`n"
      $requestLine = $headerLines[0] -split " "
      $method = $requestLine[0]
      $target = $requestLine[1]
      $uri = [uri]("http://localhost:$Port$target")
      $path = $uri.AbsolutePath
      $query = @{}
      if ($uri.Query.Length -gt 1) {
        foreach ($pair in $uri.Query.TrimStart("?").Split("&")) {
          if ($pair.Length -eq 0) { continue }
          $kv = $pair.Split("=", 2)
          $key = [uri]::UnescapeDataString($kv[0])
          $value = if ($kv.Count -gt 1) { [uri]::UnescapeDataString($kv[1]) } else { "" }
          $query[$key] = $value
        }
      }

      $context = [pscustomobject]@{
        Stream = $stream
        Request = [pscustomobject]@{
          HttpMethod = $method
          Url = $uri
          QueryString = $query
          Body = $bodyText
        }
      }

      if ($path.StartsWith("/api/")) {
        Handle-Api $context $path $query
      } elseif ($path.StartsWith("/assets/")) {
        $name = [uri]::UnescapeDataString($path.Substring("/assets/".Length))
        $file = Join-Path $AssetsDir $name
        Send-File $context $file
      } else {
        $name = if ($path -eq "/") { "dashboard.html" } else { [uri]::UnescapeDataString($path.TrimStart("/")) }
        $file = Join-Path $PublicDir $name
        Send-File $context $file
      }
    } catch {
      Send-Json $context 500 @{ ok = $false; error = $_.Exception.Message }
    } finally {
      $stream.Close()
      $client.Close()
    }
  }
} finally {
  $listener.Stop()
}
