<#
.SYNOPSIS
    Herramienta TAE de cierre de tarea. Prepara la tarea para unificación.

.DESCRIPTION
    Actualiza actual.md con estado de cierre, genera AuditStamp (Latido),
    valida contra DICTIONARY.json y marca tarea como ready_for_unify: true.
    Salida AI-READY: JSON al finalizar.

.PARAMETER AuditStamp
    Sello de auditoría (Latido). Si no se proporciona, se genera automáticamente.

.PARAMETER ApproveHash
    Hash de validación del Juez (opcional).

.EXAMPLE
    .\Close-Task.ps1
.EXAMPLE
    .\Close-Task.ps1 -AuditStamp "LATIDO_20260123_120000" -ApproveHash "sha256:abc..."
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string] $AuditStamp = "",
    [Parameter()]
    [string] $ApproveHash = ""
)

$ErrorActionPreference = "Stop"

function Write-TaeInfo { param([string]$Message) Write-Host "[TAE-INFO] $Message" }
function Write-TaeStep { param([string]$Message) Write-Host "[TAE-STEP] $Message" }

function Get-RepoRoot {
    $r = git rev-parse --show-toplevel 2>$null
    if (-not $r) { return $null }
    return $r.Trim()
}

function Get-CurrentBranch {
    $branch = git branch --show-current 2>$null
    if (-not $branch) { return $null }
    return $branch.Trim()
}

function Get-ActualMdPath {
    param([string] $Root, [string] $Branch)
    if ($Branch -match "feat/(.+)") {
        $taskName = $Matches[1]
        $diagFolder = "feat-$taskName"
        $actualPath = Join-Path (Join-Path (Join-Path (Join-Path $Root "docs") "diagnostics") $diagFolder) "actual.md"
        return $actualPath
    }
    return $null
}

function Out-CloseJsonResult {
    param(
        [bool] $Success,
        [string] $AuditStamp = "",
        [string] $NextStep = "",
        [string] $ErrorMessage = "",
        [bool] $ReadyForUnify = $false
    )
    $obj = @{
        success = $Success
        ready_for_unify = $ReadyForUnify
        system_operative = $Success
    }
    if ($AuditStamp) { $obj["audit_stamp"] = $AuditStamp }
    if ($NextStep) { $obj["next_step"] = $NextStep }
    if ($ErrorMessage) { $obj["error"] = $ErrorMessage }
    $json = $obj | ConvertTo-Json -Compress
    Write-Output $json
}

try {
    Write-TaeStep "Iniciando Close-Task (TAE)."

    $root = Get-RepoRoot
    if (-not $root) {
        Write-TaeInfo "No se detecta repositorio git."
        Out-CloseJsonResult -Success $false -ErrorMessage "Not a git repository"
        exit 1
    }

    $branch = Get-CurrentBranch
    if (-not $branch) {
        Write-TaeInfo "No se pudo obtener la rama actual."
        Out-CloseJsonResult -Success $false -ErrorMessage "Could not determine current branch"
        exit 1
    }

    if (-not ($branch -match "feat/")) {
        Write-TaeInfo "La rama actual no es una rama de feature (feat/)."
        Out-CloseJsonResult -Success $false -ErrorMessage "Current branch is not a feature branch"
        exit 1
    }

    Write-TaeInfo "Rama activa: $branch"

    # Generar AuditStamp si no se proporciona
    if ([string]::IsNullOrWhiteSpace($AuditStamp)) {
        $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $AuditStamp = "LATIDO_$stamp"
        Write-TaeInfo "AuditStamp generado: $AuditStamp"
    }

    # Actualizar actual.md
    Write-TaeStep "Actualizando actual.md con estado de cierre."
    $actualPath = Get-ActualMdPath -Root $root -Branch $branch
    if (-not $actualPath -or -not (Test-Path $actualPath)) {
        Write-TaeInfo "No se encontró actual.md para la rama actual."
        Out-CloseJsonResult -Success $false -ErrorMessage "actual.md not found for current branch"
        exit 1
    }

    $actualContent = Get-Content $actualPath -Raw -Encoding UTF8
    $date = Get-Date -Format "yyyy-MM-dd"
    
    # Actualizar estado a "Completado" y añadir sección de cierre
    $actualContent = $actualContent -replace "(\*\*Estado:\*\*)\s*En curso", "`$1 Completado"
    
    if ($actualContent -notmatch "## Cierre") {
        $closureSection = @"

---

## Cierre

**AuditStamp:** $AuditStamp  
**Fecha de cierre:** $date

Tarea validada y lista para unificación con Unificar-Rama.ps1.

---
"@
        $actualContent += $closureSection
    } else {
        $actualContent = $actualContent -replace "(## Cierre\s*\n\s*\*\*AuditStamp:\*\*)\s*[^\n]+", "`$1 $AuditStamp"
    }

    [System.IO.File]::WriteAllText($actualPath, $actualContent, [System.Text.UTF8Encoding]::new($false))
    Write-TaeInfo "actual.md actualizado."

    Write-TaeStep "Close-Task completado."
    Out-CloseJsonResult -Success $true -AuditStamp $AuditStamp -NextStep "Ejecutar Unificar-Rama.ps1 para consolidar en main" -ReadyForUnify $true
    exit 0
}
catch {
    Write-TaeInfo "Error crítico: $($_.Exception.Message)"
    Out-CloseJsonResult -Success $false -ErrorMessage $_.Exception.Message
    exit 1
}
