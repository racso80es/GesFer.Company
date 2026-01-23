$ErrorActionPreference = "Stop"

function Check-LastAction {
    param([string]$Message)
    if ($LASTEXITCODE -ne 0) {
        $root = git rev-parse --show-toplevel 2>$null
        if ($root) { $root = $root.Trim() }
        $writeTaeResultPath = if ($root) {
            Join-Path (Join-Path (Join-Path (Join-Path $root "Storage") "Tekton") "Tools") "Write-TaeResult.ps1"
        } else {
            ".\Write-TaeResult.ps1"
        }
        if (Test-Path $writeTaeResultPath) {
            & $writeTaeResultPath -SourceTool "Sync-Latido" -Status "Failure" -Payload @{ error=$Message; exitCode=$LASTEXITCODE } -AuditStamp $AuditStamp
        }
        throw "ERROR CRÍTICO: $Message. Abortando para evitar desincronización."
    }
}

# 1. Protocolo de Visión
$root = git rev-parse --show-toplevel 2>$null
if ($root) { $root = $root.Trim() }

$visionPaths = @(
    "G:\Mi unidad\GesFer_Audios\Tormentosa\Tools\Vision.md",
    "Storage\Tormentosa\Tools\Vision.md"
)

if ($root) {
    $visionPaths += Join-Path $root "Storage\Tormentosa\Tools\Vision.md"
} else {
    $visionPaths += ".\Storage\Tormentosa\Tools\Vision.md"
}

$visionFound = $false
foreach ($path in $visionPaths) {
    if ($path -and (Test-Path $path)) {
        Write-Host "Vision.md encontrado en: $path" -ForegroundColor Green
        $visionFound = $true
        break
    }
}

if (-not $visionFound) {
    Write-Host "ADVERTENCIA: Vision.md no encontrado. Continuando sin validación de protocolo Tormentosa." -ForegroundColor Yellow
    Write-Host "Ubicaciones verificadas:" -ForegroundColor Yellow
    foreach ($path in $visionPaths) {
        if ($path) { Write-Host "  - $path" -ForegroundColor Gray }
    }
}

# 2. Kaizen: Centralización de Herramientas
$OldPath = "..\..\Tekton\Tools"
if (Test-Path $OldPath) {
    Write-Host "Iniciando Kaizen: Migrando herramientas al almacén..." -ForegroundColor Cyan
    Get-ChildItem $OldPath | Copy-Item -Destination ".\" -Force
    # No borramos la antigua todavía por seguridad, pero trabajamos con la nueva
}

# 3. Refactor de Unificar-Rama
$UnificarPath = ".\Unificar-Rama.ps1"
if (Test-Path $UnificarPath) {
    $Content = Get-Content $UnificarPath -Raw
    if ($Content -notmatch "Write-TaeResult.ps1") {
        $Content += "`n.\Tekton\Tools\Write-TaeResult.ps1 -SourceTool 'Unificar-Rama' -Status 'Success' -AuditStamp `$AuditStamp"
        Set-Content $UnificarPath $Content
    }
}

# 4. Ciclo de Git Blindado
Write-Host "Consolidando cambios locales..." -ForegroundColor Yellow
git add .
git commit -m "feat(tekton): sync-latido robusto con kaizen de rutas" -m "AuditStamp: $AuditStamp"
# No validamos commit porque puede no haber cambios, pero seguimos

Write-Host "Sincronizando con la nube (Rebase)..." -ForegroundColor Yellow
git fetch --all --prune
Check-LastAction "Fallo en fetch"

git checkout main
Check-LastAction "Fallo al cambiar a main"

git pull origin main --rebase
Check-LastAction "Conflicto en Rebase. Resuelve manualmente antes de seguir."

# 5. Limpieza de Ramas
git branch --merged main | Where-Object { $_ -notmatch "main" } | ForEach-Object { git branch -d $_.Trim() }

# 6. Sincronización Final
Write-Host "Empujando al almacén central..." -ForegroundColor Green
git push origin main
Check-LastAction "Fallo en el Push final. El almacén está desincronizado."

# 7. Certificación de Éxito
$root = git rev-parse --show-toplevel 2>$null
if ($root) { $root = $root.Trim() }
$writeTaeResultPath = if ($root) {
    Join-Path (Join-Path (Join-Path (Join-Path $root "Storage") "Tekton") "Tools") "Write-TaeResult.ps1"
} else {
    ".\Write-TaeResult.ps1"
}
if (Test-Path $writeTaeResultPath) {
    & $writeTaeResultPath -SourceTool "Sync-Latido" -Status "Success" -Payload @{ action="FullSync"; kaizen="ToolMigration" } -AuditStamp $AuditStamp
}
Write-Host "LATIDO COMPLETADO: El sistema está 100% sincronizado." -ForegroundColor Green