$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$outputBase = Join-Path $PSScriptRoot "SS-MAPA-MAESTRO-DOCUMENTAL-V001"

$includedRoots = @(
    (Join-Path $root "documentos_iso"),
    (Join-Path $root "documentos_legales"),
    (Join-Path $root "hardware_design"),
    (Join-Path $root "campana_financiamiento")
)

$rootFiles = @(
    "feedback_comunidad_aguas_abiertas.csv",
    "save_swimmer_costos.md",
    "save_swimmer_esquema.md",
    "save_swimmer_mapa_integral.md",
    "save_swimmer_premisas.md"
) | ForEach-Object { Join-Path $root $_ } | Where-Object { Test-Path $_ }

$extensions = @(".csv", ".xlsx", ".docx", ".md", ".txt", ".html", ".svg")

function Get-RelativePath([string]$basePath, [string]$targetPath) {
    $baseFull = [IO.Path]::GetFullPath($basePath).TrimEnd("\") + "\"
    $targetFull = [IO.Path]::GetFullPath($targetPath)
    $baseUri = [Uri]$baseFull
    $targetUri = [Uri]$targetFull
    return [Uri]::UnescapeDataString($baseUri.MakeRelativeUri($targetUri).ToString()).Replace("/", "\")
}

$files = @()
foreach ($folder in $includedRoots) {
    if (Test-Path $folder) {
        $files += Get-ChildItem -LiteralPath $folder -File -Recurse | Where-Object {
            $extensions -contains $_.Extension.ToLowerInvariant() -and
            $_.Name -notmatch "^(generar_|convertir_)" -and
            $_.BaseName -ne "SS-MAPA-MAESTRO-DOCUMENTAL-V001"
        }
    }
}
$files += $rootFiles | ForEach-Object { Get-Item -LiteralPath $_ }

function Get-Category([string]$name, [string]$relativePath) {
    switch -Regex ($name) {
        "ISO-BASE|ARBOL-EMPRESA|BASE-CONCEPTUAL|MAPA-INTEGRAL|PREMISAS" { return "01. Direccion, empresa e ISO" }
        "MODELO-FINANCIERO|COSTOS|presupuesto_referencial|recompensas_y_metas" { return "02. Finanzas y sostenibilidad" }
        "TERMINOS-CONDICIONES|CONFIDENCIALIDAD|AUTORIZACION" { return "03. Legal, privacidad y autorizaciones" }
        "PCB|CARCASA|FLOTABILIDAD|FAB-NOTES|LAYOUT|LISTA-COMPRAS|PROTOTIPO-ACTUAL|PINOUT" { return "04. Hardware y diseno fisico" }
        "PENDIENTES-FIRMWARE|REGISTRO-PRUEBA-MICROSD|BITACORA|PROTOCOLO-PRUEBA|GATEWAY-GSM" { return "05. Firmware, pruebas y validacion" }
        "MAPA-CONFIANZA|COBERTURA-MOVIL|VISUALIZACION-RECORRIDOS|CRITERIOS-VALIDACION-ALERTA" { return "06. Comunicacion, mapas y alertas" }
        "PORTAFOLIO-VERSIONES|ROADMAP-MERCADO|ABANICO-MERCADO|REGISTRO-ESCENARIOS" { return "07. Producto, versiones y mercado" }
        "EVENTS|COMPETENCIA|FINISHER|CHECKIN|RF-EVENTS" { return "08. Events y competencias" }
        "ENCUESTA|INVESTIGACION-MERCADO|FUENTES-INVESTIGACION|BETA-TESTERS|feedback_comunidad|GUIA-VISITA|CALENDARIO-OPORTUNIDADES" { return "09. Investigacion, comunidad y pilotos" }
        "PNP|CASOS-REFERENCIA|SEGURIDAD-EVENTS" { return "10. Seguridad, autoridades y casos" }
        "CAMPANA|crowdfunding|startfund|posts_redes|mensajes_directos|README_CAMPANA|contenido_editor|paso_a_paso|post_avance_plin_copy" { return "11. Comunicacion y financiamiento" }
        default {
            if ($relativePath -like "campana_financiamiento*") { return "11. Comunicacion y financiamiento" }
            if ($relativePath -like "hardware_design*") { return "04. Hardware y diseno fisico" }
            return "12. Referencias generales"
        }
    }
}

function Get-Purpose([string]$name) {
    switch -Regex ($name) {
        "ISO-BASE" { return "Base inicial del sistema de gestion y documentacion ISO." }
        "ARBOL-EMPRESA" { return "Estructura integral de empresa, producto, operaciones y cumplimiento." }
        "BASE-CONCEPTUAL" { return "Registro central de premisas y decisiones fundamentales del producto." }
        "PENDIENTES-FIRMWARE" { return "Lista priorizada de funciones, correcciones y validaciones pendientes." }
        "BITACORA-PRUEBAS" { return "Historial maestro de pruebas, hallazgos y avances del prototipo." }
        "MODELO-FINANCIERO" { return "Costos, ingresos, membresias y punto de equilibrio proyectado." }
        "PORTAFOLIO-VERSIONES" { return "Definicion de Lite, Pro, apps y plataforma." }
        "ROADMAP-MERCADO" { return "Etapas previstas para ingreso, crecimiento y expansion." }
        "ROADMAP-ACERCAMIENTO-PNP" { return "Etapas y condiciones para acercamiento responsable a autoridades." }
        "TERMINOS-CONDICIONES" { return "Borrador de condiciones de uso y limites del servicio." }
        "CONFIDENCIALIDAD|AUTORIZACION" { return "Consentimiento, confidencialidad y autorizacion para pruebas piloto." }
        "PCB-LITE-CONCEPT" { return "Concepto preliminar de PCB compacta para Save Swimmer Lite." }
        "PCB-LITE-LAYOUT" { return "Representacion visual preliminar de distribucion de la PCB." }
        "PCB-LITE-FAB-NOTES" { return "Notas tecnicas preliminares para futura fabricacion de PCB." }
        "CARCASA-Y-FLOTABILIDAD" { return "Requisitos de flotabilidad, desprendimiento y autoenderezamiento." }
        "LISTA-COMPRAS" { return "Lista priorizada de compras para resolver incertidumbres del prototipo sin agregar componentes prematuramente." }
        "PROTOTIPO-ACTUAL|PINOUT" { return "Esquema modular KiCad y conexiones documentadas del prototipo actualmente ensamblado." }
        "MICROSD-ENERGIA" { return "Registro formal de pruebas y fallas microSD/alimentacion." }
        "SENAL-INMERSION-DESPRENDIMIENTO" { return "Protocolo para caracterizar comunicacion en posturas, inmersion y desprendimiento." }
        "GATEWAY-GSM" { return "Procedimiento de prueba del telefono como gateway GSM temporal." }
        "MAPA-CONFIANZA-COMUNICACION" { return "Requisitos del mapa colaborativo de comunicacion observada." }
        "COBERTURA-MOVIL-MAR-PERU" { return "Investigacion preliminar de cobertura movil costera en Peru." }
        "VISUALIZACION-RECORRIDOS-LARGOS" { return "Requisitos para mapas de recorridos largos sin inventar continuidad." }
        "CRITERIOS-VALIDACION-ALERTA" { return "Criterios para validar alertas tempranas antes de considerarlas confiables." }
        "EVENTS-MULTISPORT" { return "Estrategia de aplicacion de Save Swimmer Events en eventos multideporte." }
        "TIPOS-COMPETENCIA" { return "Matriz de competencias y variantes operativas posibles." }
        "RF-EVENTS" { return "Arquitectura preliminar de radiofrecuencia para Events." }
        "REGISTRO-Y-CHECKIN" { return "Flujo de inscripcion, identificacion y check-in para Events." }
        "FINISHER-DATA" { return "Analisis competitivo y estrategico frente a Finisher Data." }
        "SEGURIDAD-EVENTS" { return "Requisitos de seguridad derivados de casos y observaciones reales." }
        "CASOS-REFERENCIA" { return "Casos externos estudiados para fortalecer requisitos sin usarlos comercialmente." }
        "ENCUESTA-BREVE" { return "Formulario breve utilizado para recopilar necesidades en eventos." }
        "ENCUESTA-DIGITAL" { return "Respuestas digitales normalizadas para analisis." }
        "RESUMEN-ENCUESTAS" { return "Resumen de resultados y prioridades observadas en encuestas." }
        "INVESTIGACION-MERCADO-RESPUESTAS" { return "Registro de comentarios y solicitudes expresadas por la comunidad." }
        "FUENTES-INVESTIGACION" { return "Fuentes utilizadas para investigacion de mercado." }
        "BETA-TESTERS" { return "Contactos privados de posibles participantes de pruebas." }
        "GUIA-VISITA-EVENTO" { return "Guia operativa para observar y documentar eventos de aguas abiertas." }
        "CALENDARIO-OPORTUNIDADES" { return "Calendario de oportunidades para observacion y pruebas." }
        "ABANICO-MERCADO" { return "Posibilidades de aplicacion nacional y global por version." }
        "REGISTRO-ESCENARIOS" { return "Escenarios estrategicos contemplados para decisiones futuras." }
        "feedback_comunidad" { return "Registro continuo de comentarios recibidos de nadadores y comunidad." }
        "presupuesto_referencial" { return "Presupuesto de referencia de la campana de financiamiento." }
        "recompensas_y_metas" { return "Metas y recompensas propuestas para crowdfunding." }
        "CAMPANA|crowdfunding|startfund|posts_redes|mensajes_directos|contenido_editor|README_CAMPANA|paso_a_paso|post_avance_plin_copy" { return "Contenido operativo y comunicacional de la campana de financiamiento." }
        "save_swimmer_costos" { return "Notas historicas de costos del proyecto." }
        "save_swimmer_esquema" { return "Esquema general historico del dispositivo y aplicaciones." }
        "save_swimmer_mapa_integral" { return "Mapa integral historico del ecosistema Save Swimmer." }
        "save_swimmer_premisas" { return "Premisas historicas del proyecto." }
        default { return "Documento de apoyo del proyecto Save Swimmer." }
    }
}

$groups = $files | Group-Object {
    $relative = Get-RelativePath $root $_.FullName
    $folder = Split-Path $relative -Parent
    "$folder|$($_.BaseName)"
}

$versionMax = @{}
foreach ($group in $groups) {
    $base = $group.Group[0].BaseName
    if ($base -match "^(.*)-V(\d{3})$") {
        $family = $Matches[1]
        $version = [int]$Matches[2]
        if (-not $versionMax.ContainsKey($family) -or $version -gt $versionMax[$family]) {
            $versionMax[$family] = $version
        }
    }
}

$records = foreach ($group in $groups) {
    $sample = $group.Group[0]
    $base = $sample.BaseName
    $relativePaths = $group.Group | ForEach-Object { Get-RelativePath $root $_.FullName } | Sort-Object
    $formats = $group.Group.Extension.TrimStart(".").ToUpperInvariant() | Sort-Object -Unique
    $status = "ACTIVO"
    if ($base -match "^(.*)-V(\d{3})$") {
        $family = $Matches[1]
        $version = [int]$Matches[2]
        if ($version -lt $versionMax[$family]) { $status = "REEMPLAZADO" }
    }
    $relativeSample = $relativePaths[0]
    [pscustomobject]@{
        categoria = Get-Category $base $relativeSample
        documento = $base
        finalidad = Get-Purpose $base
        estado = $status
        formatos = ($formats -join " / ")
        archivos = ($relativePaths -join " | ")
        actualizado = ($group.Group | Sort-Object LastWriteTime -Descending | Select-Object -First 1).LastWriteTime.ToString("yyyy-MM-dd HH:mm")
    }
}

$records = $records | Sort-Object categoria, documento
$records | Export-Csv -LiteralPath "$outputBase.csv" -NoTypeInformation -Encoding UTF8

function Html([string]$value) {
    return [System.Net.WebUtility]::HtmlEncode($value)
}

$categoryBlocks = foreach ($categoryGroup in ($records | Group-Object categoria)) {
    $rows = foreach ($record in $categoryGroup.Group) {
        $links = foreach ($path in ($record.archivos -split " \| ")) {
            $href = "../" + ($path -replace "\\", "/")
            "<a href='$(Html $href)'>$(Html ([IO.Path]::GetExtension($path).TrimStart('.').ToUpperInvariant()))</a>"
        }
        $statusClass = if ($record.estado -eq "ACTIVO") { "active" } else { "replaced" }
        "<tr data-search='$(Html (($record.documento + " " + $record.finalidad + " " + $categoryGroup.Name).ToLowerInvariant()))'><td><strong>$(Html $record.documento)</strong></td><td>$(Html $record.finalidad)</td><td><span class='status $statusClass'>$(Html $record.estado)</span></td><td>$($links -join " ")</td></tr>"
    }
    @"
<details open>
  <summary><span>$(Html $categoryGroup.Name)</span><b>$($categoryGroup.Count)</b></summary>
  <table><thead><tr><th>Documento</th><th>Para que sirve</th><th>Estado</th><th>Abrir</th></tr></thead><tbody>$($rows -join "`n")</tbody></table>
</details>
"@
}

$treeNodes = foreach ($categoryGroup in ($records | Group-Object categoria)) {
    "<a class='branch' href='#' data-category='$(Html $categoryGroup.Name)'><span>$(Html $categoryGroup.Name)</span><b>$($categoryGroup.Count)</b></a>"
}

$html = @"
<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Save Swimmer | Mapa maestro documental</title>
<style>
:root{--bg:#06151d;--panel:#0b2632;--line:#1d5263;--cyan:#28cbe4;--orange:#ff6b18;--text:#eef8fb;--muted:#9bb5bf}
*{box-sizing:border-box} body{margin:0;background:var(--bg);color:var(--text);font-family:Arial,sans-serif} main{max-width:1500px;margin:auto;padding:28px}
h1{letter-spacing:4px;margin:0;font-size:28px}.sub{color:var(--cyan);letter-spacing:2px;margin:8px 0 24px}.toolbar{display:flex;gap:10px;margin-bottom:22px}
input{width:100%;padding:14px;background:#081f29;border:1px solid var(--line);color:var(--text);font-size:16px}
.tree{border-left:3px solid var(--orange);padding-left:22px;margin:22px 0 32px}.root{display:inline-block;padding:12px 18px;border:1px solid var(--cyan);font-weight:bold;margin-bottom:14px}
.branches{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:8px}.branch{display:flex;justify-content:space-between;gap:12px;padding:12px;background:var(--panel);border-left:2px solid var(--cyan);color:var(--text);text-decoration:none}.branch b{color:var(--orange)}
details{margin:12px 0;background:var(--panel);border:1px solid var(--line)}summary{cursor:pointer;padding:16px;display:flex;justify-content:space-between;color:var(--cyan);font-weight:bold}summary b{color:var(--orange)}
table{width:100%;border-collapse:collapse}th,td{padding:12px;border-top:1px solid #163f4d;text-align:left;vertical-align:top}th{color:var(--muted);font-size:12px;text-transform:uppercase}td:nth-child(1){width:29%}td:nth-child(3){width:10%}td:nth-child(4){width:12%}
a{color:var(--cyan);margin-right:8px}.status{font-size:11px;padding:5px 7px;border:1px solid}.active{color:#65e6a4}.replaced{color:#ffb36e}.hidden{display:none}
@media(max-width:800px){main{padding:15px}h1{font-size:21px}table,thead,tbody,tr,th,td{display:block}thead{display:none}td{width:auto!important;padding:8px 12px}tr{border-top:1px solid var(--line);padding:6px 0}}
</style>
</head>
<body><main>
<h1>SAVE SWIMMER</h1>
<div class="sub">MAPA MAESTRO DOCUMENTAL V001 | $($records.Count) DOCUMENTOS LOGICOS</div>
<div class="toolbar"><input id="search" placeholder="Buscar documento, funcion o area..."></div>
<section class="tree"><div class="root">SAVE SWIMMER | DOCUMENTACION</div><div class="branches">$($treeNodes -join "`n")</div></section>
<section id="documents">$($categoryBlocks -join "`n")</section>
</main>
<script>
const input=document.getElementById('search');
input.addEventListener('input',()=>{const q=input.value.toLowerCase().trim();document.querySelectorAll('tbody tr').forEach(r=>r.classList.toggle('hidden',q&&!r.dataset.search.includes(q)));document.querySelectorAll('details').forEach(d=>{const visible=[...d.querySelectorAll('tbody tr')].some(r=>!r.classList.contains('hidden'));d.classList.toggle('hidden',!visible);if(q&&visible)d.open=true;});});
document.querySelectorAll('.branch').forEach(b=>b.addEventListener('click',e=>{e.preventDefault();const target=[...document.querySelectorAll('details')].find(d=>d.querySelector('summary span').textContent===b.dataset.category);if(target){target.open=true;target.scrollIntoView({behavior:'smooth'});}}));
</script></body></html>
"@

[IO.File]::WriteAllText("$outputBase.html", $html, [Text.UTF8Encoding]::new($false))
Write-Host "Creado: $outputBase.csv"
Write-Host "Creado: $outputBase.html"
