<#
.SYNOPSIS
    Herramienta de integridad absoluta. Realiza refactor de core, saneamiento de ramas y sincronización con el almacén en un solo latido.

.DESCRIPTION
    Sync-Latido ejecuta un flujo completo de sincronización:
    1. Validación: Verifica existencia de Vision.md
    2. Evolución: Refactoriza Unificar-Rama.ps1 si es necesario
    3. Consolidación: Commit de cambios
    4. Saneamiento: Limpieza de ramas y rebase
    5. Sincronización: Push a origin/main
    6. Certificación: Registro en activity_stream.jsonl

.PARAMETER AuditStamp
    Sello de auditoría / Latido para la operación.

.EXAMPLE
    .\Sync-Latido.ps1 -AuditStamp "TEKTON_CONSOLIDATION_INIT"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $AuditStamp
)

$ErrorActionPreference = "Stop"

function Write-TaeInfo { param([string]$Message) Write-Host "[SYNC-LATIDO] $Message" }
function Write-TaeStep { param([string]$Message) Write-Host "[SYNC-LATIDO-STEP] $Message" }

function Get-RepoRoot {
    $r = git rev-parse --show-toplevel 2>$null
    if (-not $r) { return $null }
    return $r.Trim()
}

# PASO 1: Validación
Write-TaeStep "Paso 1: Validación de Vision.md"

$visionPaths = @(
    "G:\Mi unidad\GesFer_Audios\Tormentosa\Tools\Vision.md",
    "Storage\Tormentosa\Tools\Vision.md",
    ".\Storage\Tormentosa\Tools\Vision.md"
)

$visionFound = $false
foreach ($path in $visionPaths) {
    if (Test-Path $path) {
        Write-TaeInfo "Vision.md encontrado en: $path"
        $visionFound = $true
        break
    }
}

if (-not $visionFound) {
    Write-TaeInfo "ERROR: Vision.md no encontrado en ninguna ubicación esperada."
    Write-TaeInfo "Ubicaciones verificadas:"
    foreach ($path in $visionPaths) {
        Write-TaeInfo "  - $path"
    }
    exit 1
}

# PASO 2: Evolución - Verificar y refactorizar Unificar-Rama.ps1
Write-TaeStep "Paso 2: Evolución - Verificar Unificar-Rama.ps1"

$root = Get-RepoRoot
if (-not $root) {
    Write-TaeInfo "ERROR: No se detecta repositorio git."
    exit 1
}

$unificarRamaPath = Join-Path (Join-Path (Join-Path (Join-Path $root "Storage") "Tekton") "Tools") "Unificar-Rama.ps1"

if (-not (Test-Path $unificarRamaPath)) {
    Write-TaeInfo "ERROR: Unificar-Rama.ps1 no encontrado en $unificarRamaPath"
    exit 1
}

$content = Get-Content $unificarRamaPath -Raw -Encoding UTF8
$needsUpdate = $false

# Verificar si contiene Write-TaeResult.ps1
if ($content -notmatch "Write-TaeResult\.ps1") {
    Write-TaeInfo "Unificar-Rama.ps1 no contiene Write-TaeResult.ps1. Añadiendo llamada..."
    $needsUpdate = $true
    
    # Buscar el final del script antes del catch
    if ($content -match "(Write-TaeStep `"Unificación completada\.`"[\s\S]*?)(catch \{)") {
        $beforeCatch = $matches[1]
        $newCall = @"

    # Llamada a Write-TaeResult.ps1 para telemetría
    `$ResultData = @{
        merge_details = @{ from = `$Branch; to = `$Target; commit = `$mergeCommit }
        cleanup = `$cleanupStatus
        next_step = "Ready for next beat"
    }
    `$writeTaeResultPath = Join-Path (Join-Path (Join-Path `$root "Tekton") "Tools") "Write-TaeResult.ps1"
    & `$writeTaeResultPath -SourceTool "Unificar-Rama" -Status "Success" -Payload `$ResultData -AuditStamp `$stamp

"@
        $content = $content -replace [regex]::Escape($beforeCatch), ($beforeCatch + $newCall)
    } else {
        Write-TaeInfo "ADVERTENCIA: No se pudo encontrar el punto de inserción. El script puede necesitar actualización manual."
    }
} else {
    Write-TaeInfo "Unificar-Rama.ps1 ya contiene Write-TaeResult.ps1. No se requiere actualización."
}

if ($needsUpdate) {
    [System.IO.File]::WriteAllText($unificarRamaPath, $content, [System.Text.UTF8Encoding]::new($false))
    Write-TaeInfo "Unificar-Rama.ps1 actualizado."
}

# PASO 3: Consolidación
Write-TaeStep "Paso 3: Consolidación - Commit de cambios"

git add . 2>&1 | Out-Null
$status = git status --porcelain
if ($status) {
    git commit -m "feat(tekton): latido de sincronización total incluyendo el $AuditStamp" 2>&1 | Out-Null
    $commitHash = (git rev-parse HEAD 2>$null).Trim()
    Write-TaeInfo "Commit creado: $commitHash"
} else {
    Write-TaeInfo "No hay cambios para commitear."
    $commitHash = (git rev-parse HEAD 2>$null).Trim()
}

# PASO 4: Saneamiento
Write-TaeStep "Paso 4: Saneamiento - Limpieza de ramas y rebase"

git fetch --all --prune 2>&1 | Out-Null
Write-TaeInfo "Fetch completado."

$currentBranch = (git branch --show-current 2>$null).Trim()
if ($currentBranch -ne "main") {
    git checkout main 2>&1 | Out-Null
    Write-TaeInfo "Cambiado a rama main."
}

git pull origin main --rebase 2>&1 | Out-Null
Write-TaeInfo "Rebase completado."

# Eliminar ramas locales ya fusionadas
$mergedBranches = git branch --merged main 2>$null | Where-Object { $_ -notmatch "^\*|main" } | ForEach-Object { $_.Trim() }
foreach ($branch in $mergedBranches) {
    git branch -d $branch 2>&1 | Out-Null
    Write-TaeInfo "Rama local eliminada: $branch"
}

# PASO 5: Sincronización
Write-TaeStep "Paso 5: Sincronización - Push a origin/main"

git push origin main 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-TaeInfo "Push a origin/main completado exitosamente."
} else {
    Write-TaeInfo "ADVERTENCIA: Push puede haber fallado. Verificar manualmente."
}

# Certificación
Write-TaeStep "Certificación - Registro en activity_stream.jsonl"

$writeTaeResultPath = Join-Path (Join-Path (Join-Path (Join-Path $root "Storage") "Tekton") "Tools") "Write-TaeResult.ps1"
if (Test-Path $writeTaeResultPath) {
    $payload = @{
        action = "FullSync"
        commit_hash = $commitHash
        branches_cleaned = @($mergedBranches)
    }
    & $writeTaeResultPath -SourceTool "Sync-Latido" -Status "Success" -Payload $payload -AuditStamp $AuditStamp
    Write-TaeInfo "Certificación completada."
} else {
    Write-TaeInfo "ADVERTENCIA: Write-TaeResult.ps1 no encontrado. Certificación omitida."
}

Write-TaeStep "Sync-Latido completado exitosamente."
Write-TaeInfo "Commit hash: $commitHash"
Write-TaeInfo "AuditStamp: $AuditStamp"
