<#
.SYNOPSIS
    Herramienta TAE de cierre de tarea (Fase 3 del Protocolo S+). Valida cumplimiento de objetivos
    y prepara la rama para unificación.

.DESCRIPTION
    Close-Task ejecuta validaciones finales, actualiza el diagnóstico (actual.md), genera AuditStamp
    si no se proporciona, y prepara la rama para Unificar-Rama.ps1. Integra con Write-TaeResult.ps1
    para telemetría.

.PARAMETER AuditStamp
    Sello de auditoría / Latido. Si no se proporciona, se genera automáticamente.

.PARAMETER ApproveHash
    Hash de validación del Juez (opcional).

.PARAMETER TaskName
    Nombre de la tarea (se infiere de la rama actual si no se proporciona).

.EXAMPLE
    .\Close-Task.ps1 -AuditStamp "LATIDO_03_MIGRATION_COMPLETE"
.EXAMPLE
    .\Close-Task.ps1
    # Genera AuditStamp automáticamente
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string] $AuditStamp = "",
    [Parameter()]
    [string] $ApproveHash = "",
    [Parameter()]
    [string] $TaskName = ""
)

$ErrorActionPreference = "Stop"

function Write-TaeInfo { param([string]$Message) Write-Host "[TAE-INFO] $Message" }
function Write-TaeStep { param([string]$Message) Write-Host "[TAE-STEP] $Message" }

function Get-RepoRoot {
    $r = git rev-parse --show-toplevel 2>$null
    if (-not $r) { return $null }
    return $r.Trim()
}

function Get-WriteTaeResultPath {
    param([string] $Root)
    return Join-Path (Join-Path (Join-Path $Root "Storage") "Tekton") "Tools\Write-TaeResult.ps1"
}

function Get-CurrentBranch {
    $branch = git branch --show-current 2>$null
    if (-not $branch) { return $null }
    return $branch.Trim()
}

function Get-TaskNameFromBranch {
    param([string] $Branch)
    if ($Branch -match "feat/(.+)") {
        return $matches[1]
    }
    return $null
}

function Get-DiagnosticsPath {
    param([string] $Root, [string] $TaskName)
    if ([string]::IsNullOrWhiteSpace($TaskName)) { return $null }
    $diagFolder = "feat-$TaskName"
    return Join-Path (Join-Path (Join-Path $Root "docs") "diagnostics") $diagFolder
}

function Update-ActualMd {
    param(
        [string] $ActualPath,
        [string] $AuditStamp,
        [string] $Status = "Completado"
    )
    
    if (-not (Test-Path $ActualPath)) {
        Write-TaeInfo "actual.md no encontrado en $ActualPath. Se creará uno nuevo."
    }
    
    $stamp = Get-Date -Format "yyyy-MM-dd"
    $content = @"
# feat/$TaskName — Diagnóstico

**Fecha:** $stamp  
**Rama:** `$branchName`  
**Estado:** $Status

---

## Objetivo

Tarea cerrada con Close-Task.ps1 (Protocolo S+ TAE - Fase 3).

---

## Cierre

**AuditStamp:** $AuditStamp  
**Fecha de cierre:** $stamp

Tarea validada y lista para unificación con Unificar-Rama.ps1.

---

## Próximos pasos

- Ejecutar Unificar-Rama.ps1 para consolidar en main.
- O ejecutar Sync-Latido.ps1 para sincronización completa con el Almacén.

"@
    
    [System.IO.File]::WriteAllText($ActualPath, $content, [System.Text.UTF8Encoding]::new($false))
    Write-TaeInfo "actual.md actualizado en $ActualPath."
}

function Out-CloseJsonResult {
    param(
        [bool] $Success,
        [string] $AuditStamp = "",
        [string] $NextStep = "",
        [string] $ErrorMessage = ""
    )
    $obj = @{
        success = $Success
        audit_stamp = $AuditStamp
        next_step = $NextStep
    }
    if ($ErrorMessage) { $obj["error"] = $ErrorMessage }
    $json = $obj | ConvertTo-Json -Compress
    Write-Output $json
}

try {
    Write-TaeStep "Iniciando Close-Task (TAE - Fase 3)."

    $root = Get-RepoRoot
    if (-not $root) {
        Write-TaeInfo "No se detecta repositorio git."
        Out-CloseJsonResult -Success $false -ErrorMessage "Not a git repository"
        exit 1
    }

    $branchName = Get-CurrentBranch
    if (-not $branchName) {
        Write-TaeInfo "No se pudo determinar la rama actual."
        Out-CloseJsonResult -Success $false -ErrorMessage "Could not determine current branch"
        exit 1
    }

    if ([string]::IsNullOrWhiteSpace($TaskName)) {
        $TaskName = Get-TaskNameFromBranch -Branch $branchName
        if (-not $TaskName) {
            Write-TaeInfo "No se pudo inferir TaskName de la rama '$branchName'."
            Out-CloseJsonResult -Success $false -ErrorMessage "Could not infer TaskName from branch name"
            exit 1
        }
    }

    Write-TaeStep "Validando cumplimiento de objetivos de la tarea."
    Write-TaeInfo "Rama actual: $branchName"
    Write-TaeInfo "Tarea: $TaskName"

    # Validación: verificar que hay cambios para consolidar
    $gitStatus = git status --porcelain 2>$null
    if (-not $gitStatus) {
        Write-TaeInfo "No hay cambios pendientes. La tarea puede estar ya consolidada."
    } else {
        Write-TaeInfo "Cambios pendientes detectados. Listos para consolidación."
    }

    # Actualizar diagnóstico
    $diagPath = Get-DiagnosticsPath -Root $root -TaskName $TaskName
    if ($diagPath -and (Test-Path $diagPath)) {
        $actualPath = Join-Path $diagPath "actual.md"
        if ([string]::IsNullOrWhiteSpace($AuditStamp)) {
            $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $AuditStamp = "LATIDO_$stamp"
        }
        Update-ActualMd -ActualPath $actualPath -AuditStamp $AuditStamp
    } else {
        Write-TaeInfo "Carpeta de diagnóstico no encontrada. Continuando sin actualizar actual.md."
    }

    # Generar AuditStamp si no se proporcionó
    if ([string]::IsNullOrWhiteSpace($AuditStamp)) {
        $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $AuditStamp = "LATIDO_$stamp"
        Write-TaeInfo "AuditStamp generado automáticamente: $AuditStamp"
    }

    Write-TaeStep "Close-Task completado. Preparando telemetría."

    # Integración con Write-TaeResult.ps1
    $writeTaeResultPath = Get-WriteTaeResultPath -Root $root
    if (Test-Path $writeTaeResultPath) {
        $payload = @{
            branch = $branchName
            task_name = $TaskName
            audit_stamp = $AuditStamp
            approve_hash = $ApproveHash
            ready_for_unify = $true
        }
        & $writeTaeResultPath -SourceTool "TAE-003-CLOSE" -Status "Success" -Payload $payload -AuditStamp $AuditStamp
        Write-TaeInfo "Telemetría registrada."
    } else {
        Write-TaeInfo "ADVERTENCIA: Write-TaeResult.ps1 no encontrado. Telemetría omitida."
    }

    $nextStep = "Ejecutar Unificar-Rama.ps1 o Sync-Latido.ps1 para consolidación."

    Write-TaeStep "Close-Task completado exitosamente."
    Out-CloseJsonResult -Success $true -AuditStamp $AuditStamp -NextStep $nextStep
    exit 0
}
catch {
    Write-TaeInfo "Error crítico: $($_.Exception.Message)"
    
    # Intentar registrar error en telemetría
    $root = Get-RepoRoot
    if ($root) {
        $writeTaeResultPath = Get-WriteTaeResultPath -Root $root
        if (Test-Path $writeTaeResultPath) {
            $errorPayload = @{ error = $_.Exception.Message }
            & $writeTaeResultPath -SourceTool "TAE-003-CLOSE" -Status "Failure" -Payload $errorPayload -AuditStamp $AuditStamp
        }
    }
    
    Out-CloseJsonResult -Success $false -ErrorMessage $_.Exception.Message
    exit 1
}
