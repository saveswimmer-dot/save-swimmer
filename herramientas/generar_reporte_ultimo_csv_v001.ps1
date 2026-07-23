param(
    [string]$InputDir = "$env:USERPROFILE\Downloads",
    [string]$OutDir = "",
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

$csv = Get-ChildItem -LiteralPath $InputDir -File -Include "*.csv", "*.CSV" |
    Where-Object {
        $_.Length -ge $MinBytes -and
        ($_.Name -match '^(SS|SM|INCOMPLETA_SS).+\.CSV$' -or $_.Name -match '^ss_.+\.csv$')
    } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if ($null -eq $csv) {
    throw "No encontre CSV de Save Swimmer en $InputDir"
}

Write-Host "CSV seleccionado automaticamente:"
Write-Host $csv.FullName

if ([string]::IsNullOrWhiteSpace($OutDir)) {
    & powershell -ExecutionPolicy Bypass -File $generator -CsvPath $csv.FullName
} else {
    & powershell -ExecutionPolicy Bypass -File $generator -CsvPath $csv.FullName -OutDir $OutDir
}
