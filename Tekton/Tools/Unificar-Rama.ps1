<#
.SYNOPSIS
    Herramienta TAE de unificación de ramas. Sustituye cierres manuales y es el estándar
    para fusionar cambios en master tras la validación del Juez.

.DESCRIPTION
    Realiza pre-check, merge atómico (--no-ff), push a origen, limpieza de rama local
    y registro de auditoría en docs/audits/. Salida AI-READY: solo JSON al finalizar.

.PARAMETER Branch
    Rama origen. Por defecto: rama actual (git branch --show-current).

.PARAMETER Target
    Rama destino. Por defecto: master.

.PARAMETER AuditStamp
    Sello de auditoría generado en la tarea anterior (correlation_id / Latido).

.PARAMETER ApproveHash
    Hash de validación del Juez.

.EXAMPLE
    .\Unificar-Rama.ps1 -AuditStamp "STAMP_20260122_201500" -ApproveHash "sha256:abc..."
.EXAMPLE
    .\Unificar-Rama.ps1 -Branch "feat/my-feature" -Target "master" -AuditStamp "STAMP_X" -ApproveHash "h"
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string] $Branch = "",
    [Parameter()]
    [string] $Target = "master",
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

function Invoke-WriteTaeResult {
    param(
        [bool] $Success,
        [string] $CorrelationId = "",
        [hashtable] $MergeDetails = @{},
        [string] $Cleanup = "",
        [string] $NextStep = "",
        [string] $ErrorMessage = ""
    )
    
    $root = Get-RepoRoot
    $writeTaeResultPath = if ($root) {
        Join-Path (Join-Path (Join-Path $root "Tekton") "Tools") "Write-TaeResult.ps1"
    } else {
        "Tekton/Tools/Write-TaeResult.ps1"
    }
    
    $status = if ($Success) { "Success" } else { "Failure" }
    
    $payload = @{
        merge_details = $MergeDetails
        cleanup = $Cleanup
        next_step = $NextStep
    }
    
    if ($ErrorMessage) {
        $payload["error"] = $ErrorMessage
    }
    
    if (-not [string]::IsNullOrWhiteSpace($CorrelationId)) {
        $auditStamp = $CorrelationId
    } else {
        $auditStamp = ""
    }
    
    & $writeTaeResultPath -SourceTool "TAE-002-UNIFY" -Status $status -Payload $payload -AuditStamp $auditStamp
}

function Test-GitClean {
    $status = git status --porcelain 2>$null
    return [string]::IsNullOrWhiteSpace($status)
}

function Test-BranchSynced {
    param([string] $Br)
    git fetch origin 2>$null | Out-Null
    $local = (git rev-parse $Br 2>$null).Trim()
    $remoteRef = "origin/$Br"
    $remote = (git rev-parse $remoteRef 2>$null).Trim()
    if (-not $local) { return $false }
    if (-not $remote) { return $true }  # Rama solo local: se considera OK
    return ($local -eq $remote)
}

try {
    Write-TaeStep "Iniciando Unificar-Rama (TAE)."

    $root = Get-RepoRoot
    if (-not $root) {
        Write-TaeInfo "No se detecta repositorio git."
        Invoke-WriteTaeResult -Success $false -ErrorMessage "Not a git repository" -CorrelationId $AuditStamp
        exit 1
    }

    if ([string]::IsNullOrWhiteSpace($Branch)) {
        $Branch = (git branch --show-current 2>$null).Trim()
        if ([string]::IsNullOrWhiteSpace($Branch)) {
            Write-TaeInfo "No se pudo obtener la rama actual."
            Invoke-WriteTaeResult -Success $false -ErrorMessage "Could not determine current branch" -CorrelationId $AuditStamp
            exit 1
        }
        Write-TaeInfo "Rama origen (por defecto): $Branch"
    }

    if ($Branch -eq $Target) {
        Write-TaeInfo "Branch y Target no pueden ser iguales."
        Invoke-WriteTaeResult -Success $false -ErrorMessage "Branch and Target must differ" -CorrelationId $AuditStamp
        exit 1
    }

    # ---- Pre-check ----
    Write-TaeStep "Pre-check: cambios pendientes y sincronización."

    if (-not (Test-GitClean)) {
        Write-TaeInfo "Hay cambios pendientes (working tree o índice)."
        Invoke-WriteTaeResult -Success $false -ErrorMessage "Working tree or index has uncommitted changes" -CorrelationId $AuditStamp
        exit 1
    }

    $branchExists = git rev-parse --verify $Branch 2>$null
    if (-not $branchExists) {
        Write-TaeInfo "La rama origen '$Branch' no existe."
        Invoke-WriteTaeResult -Success $false -ErrorMessage "Branch '$Branch' does not exist" -CorrelationId $AuditStamp
        exit 1
    }

    $targetExists = git rev-parse --verify $Target 2>$null
    if (-not $targetExists) {
        Write-TaeInfo "La rama destino '$Target' no existe."
        Invoke-WriteTaeResult -Success $false -ErrorMessage "Target '$Target' does not exist" -CorrelationId $AuditStamp
        exit 1
    }

    $synced = Test-BranchSynced -Br $Branch
    if (-not $synced) {
        Write-TaeInfo "Rama '$Branch' no está sincronizada con origin/$Branch."
        Invoke-WriteTaeResult -Success $false -ErrorMessage "Branch '$Branch' is not synced with origin" -CorrelationId $AuditStamp
        exit 1
    }

    Write-TaeInfo "Pre-check superado."

    # ---- Atomic merge ----
    Write-TaeStep "Checkout a '$Target' y merge --no-ff de '$Branch'."

    $errAct = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $currentBranch = (git branch --show-current 2>$null).Trim()
        git checkout $Target 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) {
            if ($currentBranch) { git checkout $currentBranch 2>$null | Out-Null }
            Write-TaeInfo "Falló checkout a $Target."
            Invoke-WriteTaeResult -Success $false -ErrorMessage "Checkout to $Target failed" -CorrelationId $AuditStamp
            exit 1
        }

        git merge --no-ff $Branch -m "TAE Unificar-Rama: $Branch -> $Target [AuditStamp: $AuditStamp]" 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) {
            git merge --abort 2>$null | Out-Null
            Write-TaeInfo "Merge falló (posible conflicto)."
            Invoke-WriteTaeResult -Success $false -ErrorMessage "Merge failed (conflicts or other error)" -CorrelationId $AuditStamp
            exit 1
        }

        $mergeCommit = (git rev-parse HEAD 2>$null).Trim()
        Write-TaeInfo "Merge commit: $mergeCommit"

        # ---- Push & clean ----
        Write-TaeStep "Push a origin/$Target y limpieza de rama local."

        git push origin $Target 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-TaeInfo "Push a origin/$Target falló."
            Invoke-WriteTaeResult -Success $false -ErrorMessage "Push to origin/$Target failed" -CorrelationId $AuditStamp -MergeDetails @{ from = $Branch; to = $Target; commit = $mergeCommit }
            exit 1
        }

        git branch -d $Branch 2>$null | Out-Null
        $branchDeleteOk = ($LASTEXITCODE -eq 0)
        if (-not $branchDeleteOk) {
            Write-TaeInfo "No se pudo eliminar rama local '$Branch' (puede no estar mergeada o ya eliminada)."
        }
        $script:cleanupStatus = if ($branchDeleteOk) { "completed" } else { "branch_delete_skipped" }
    }
    finally {
        $ErrorActionPreference = $errAct
    }
    $cleanupStatus = $script:cleanupStatus

    # ---- Registro de auditoría ----
    Write-TaeStep "Registro de auditoría en docs/audits/."

    $auditsDir = Join-Path (Join-Path $root "docs") "audits"
    if (-not (Test-Path $auditsDir)) { New-Item -ItemType Directory -Path $auditsDir -Force | Out-Null }

    $stamp = if ([string]::IsNullOrWhiteSpace($AuditStamp)) { "STAMP_$(Get-Date -Format 'yyyyMMdd_HHmmss')" } else { $AuditStamp }
    $closureFile = Join-Path $auditsDir "tae_closures.json"

    $entry = @{
        closure_id     = $stamp
        timestamp      = (Get-Date -Format "o")
        audit_stamp    = $AuditStamp
        approve_hash   = $ApproveHash
        merge_details  = @{ from = $Branch; to = $Target; commit = $mergeCommit }
        latido         = $stamp
        cleanup        = $cleanupStatus
    }

    $list = [System.Collections.ArrayList]::new()
    if (Test-Path $closureFile) {
        try {
            $raw = Get-Content $closureFile -Raw -Encoding UTF8
            $data = $raw | ConvertFrom-Json
            $existing = if ($data.closures) { @($data.closures) } else { @() }
            foreach ($c in $existing) {
                $list.Add(@{
                    closure_id    = $c.closure_id
                    timestamp     = $c.timestamp
                    audit_stamp   = $c.audit_stamp
                    approve_hash  = $c.approve_hash
                    merge_details = @{ from = $c.merge_details.from; to = $c.merge_details.to; commit = $c.merge_details.commit }
                    latido        = $c.latido
                    cleanup       = $c.cleanup
                }) | Out-Null
            }
        } catch {
            # Archivo nuevo o corrupto; empezar vacío
        }
    }
    $list.Add($entry) | Out-Null

    $payload = @{
        metadata = @{
            version       = "1.0.0"
            last_updated  = (Get-Date -Format "o")
            description   = "Registro de cierres TAE (Unificar-Rama) vinculados al Latido actual"
        }
        closures = @($list)
    }
    $json = $payload | ConvertTo-Json -Depth 6
    [System.IO.File]::WriteAllText($closureFile, $json, [System.Text.UTF8Encoding]::new($false))
    Write-TaeInfo "Auditoría registrada en docs/audits/tae_closures.json (Latido: $stamp)."

    Write-TaeStep "Unificación completada."
    Invoke-WriteTaeResult -Success $true -CorrelationId $stamp -MergeDetails @{ from = $Branch; to = $Target; commit = $mergeCommit } -Cleanup $cleanupStatus -NextStep "Ready for next beat"
    exit 0
}
catch {
    Write-TaeInfo "Error crítico: $($_.Exception.Message)"
    Invoke-WriteTaeResult -Success $false -ErrorMessage $_.Exception.Message -CorrelationId $AuditStamp
    exit 1
}
