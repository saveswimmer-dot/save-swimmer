param(
    [string]$InputDir = "$env:USERPROFILE\Downloads",
    [string]$OutDir = "",
    [int]$MaxFiles = 30,
    [int]$MinBytes = 200
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$generator = Join-Path $scriptDir "generar_reporte_atleta_csv_v002.ps1"

if (!(Test-Path -LiteralPath $generator)) {
    throw "No se encontro el generador base: $generator"
}

if (!(Test-Path -LiteralPath $InputDir)) {
    throw "No existe la carpeta de entrada: $InputDir"
}

$files = @(Get-ChildItem -LiteralPath $InputDir -File -Include "*.csv", "*.CSV" |
    Where-Object {
        $_.Length -ge $MinBytes -and
        ($_.Name -match '^(SS|SM|INCOMPLETA_SS).+\.CSV$' -or $_.Name -match '^ss_.+\.csv$')
    } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First $MaxFiles)

if ($files.Count -eq 0) {
    throw "No encontre CSV de Save Swimmer en $InputDir"
}

Write-Host ""
Write-Host "SAVE SWIMMER - ELEGIR CSV PARA REPORTE"
Write-Host "Carpeta: $InputDir"
Write-Host ""

for ($i = 0; $i -lt $files.Count; $i++) {
    $n = $i + 1
    $kb = [Math]::Round($files[$i].Length / 1KB, 1)
    $date = $files[$i].LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
    Write-Host ("{0,2}. {1}  | {2} KB | {3}" -f $n, $files[$i].Name, $kb, $date)
}

Write-Host ""
$choice = Read-Host "Numero de CSV a procesar"
$idx = 0
if (!([int]::TryParse($choice, [ref]$idx)) -or $idx -lt 1 -or $idx -gt $files.Count) {
    throw "Seleccion invalida: $choice"
}

$selected = $files[$idx - 1]
Write-Host ""
Write-Host "CSV seleccionado:"
Write-Host $selected.FullName
Write-Host ""

if ([string]::IsNullOrWhiteSpace($OutDir)) {
    & powershell -ExecutionPolicy Bypass -File $generator -CsvPath $selected.FullName
} else {
    & powershell -ExecutionPolicy Bypass -File $generator -CsvPath $selected.FullName -OutDir $OutDir
}
