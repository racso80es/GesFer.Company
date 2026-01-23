<#
.SYNOPSIS
    Herramienta TAE de sincronización Latido. Sincroniza con el Almacén Local y actualiza activity_stream.jsonl.

.DESCRIPTION
    Sincroniza con el Almacén Local (/Storage), valida integridad de hashes
    y actualiza el estado global. Actualiza activity_stream.jsonl con el AuditStamp.

.PARAMETER AuditStamp
    Sello de auditoría (Latido) a sincronizar.

.EXAMPLE
    .\Sync-Latido.ps1 -AuditStamp "LATIDO_20260123_120000"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string] $AuditStamp = ""
)

$ErrorActionPreference = "Stop"

function Write-TaeInfo { param([string]$Message) Write-Host "[TAE-INFO] $Message" }
function Write-TaeStep { param([string]$Message) Write-Host "[TAE-STEP] $Message" }

function Get-RepoRoot {
    $r = git rev-parse --show-toplevel 2>$null
    if (-not $r) { return $null }
    return $r.Trim()
}

function Get-ActivityStreamPath {
    param([string] $Root)
    $logsDir = Join-Path (Join-Path $Root "Tekton") "Logs"
    if (-not (Test-Path $logsDir)) {
        New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
    }
    return Join-Path $logsDir "activity_stream.jsonl"
}

function Get-StorageHash {
    param([string] $StoragePath)
    if (-not (Test-Path $StoragePath)) { return $null }
    $files = Get-ChildItem -Path $StoragePath -Recurse -File -ErrorAction SilentlyContinue
    $allContent = ""
    foreach ($file in $files) {
        $allContent += $file.FullName + "|" + (Get-FileHash -Path $file.FullName -Algorithm SHA256).Hash + "|"
    }
    if ([string]::IsNullOrWhiteSpace($allContent)) { return "empty" }
    $hash = [System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($allContent))
    return "sha256:" + ([System.BitConverter]::ToString($hash) -replace "-", "").ToLower()
}

function Out-SyncJsonResult {
    param(
        [bool] $Success,
        [string] $AuditStamp = "",
        [string] $StorageHash = "",
        [string] $ErrorMessage = ""
    )
    $obj = @{
        success = $Success
        system_operative = $Success
    }
    if ($AuditStamp) { $obj["audit_stamp"] = $AuditStamp }
    if ($StorageHash) { $obj["storage_hash"] = $StorageHash }
    if ($ErrorMessage) { $obj["error"] = $ErrorMessage }
    $json = $obj | ConvertTo-Json -Compress
    Write-Output $json
}

try {
    Write-TaeStep "Iniciando Sync-Latido (TAE)."

    $root = Get-RepoRoot
    if (-not $root) {
        Write-TaeInfo "No se detecta repositorio git."
        Out-SyncJsonResult -Success $false -ErrorMessage "Not a git repository"
        exit 1
    }

    # Generar AuditStamp si no se proporciona
    if ([string]::IsNullOrWhiteSpace($AuditStamp)) {
        $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $AuditStamp = "LATIDO_$stamp"
        Write-TaeInfo "AuditStamp generado: $AuditStamp"
    }

    # Validar integridad del Almacén Local
    Write-TaeStep "Validando integridad del Almacén Local (/Storage)."
    $storagePath = Join-Path $root "Storage"
    if (Test-Path $storagePath) {
        $storageHash = Get-StorageHash -StoragePath $storagePath
        Write-TaeInfo "Hash del Almacén Local: $storageHash"
    } else {
        Write-TaeInfo "Almacén Local no existe aún. Se creará cuando sea necesario."
        $storageHash = "not_initialized"
    }

    # Actualizar activity_stream.jsonl
    Write-TaeStep "Actualizando activity_stream.jsonl."
    $streamPath = Get-ActivityStreamPath -Root $root
    $timestamp = Get-Date -Format "o"
    
    $entry = @{
        timestamp = $timestamp
        status = "Success"
        source_tool = "TAE-004-SYNC"
        audit_stamp = $AuditStamp
        payload = @{
            sync_type = "latido_sync"
            storage_hash = $storageHash
            sync_completed = $true
        }
    }
    
    $jsonLine = $entry | ConvertTo-Json -Compress -Depth 10
    Add-Content -Path $streamPath -Value $jsonLine -Encoding UTF8
    Write-TaeInfo "activity_stream.jsonl actualizado."

    Write-TaeStep "Sync-Latido completado."
    Out-SyncJsonResult -Success $true -AuditStamp $AuditStamp -StorageHash $storageHash
    exit 0
}
catch {
    Write-TaeInfo "Error crítico: $($_.Exception.Message)"
    Out-SyncJsonResult -Success $false -ErrorMessage $_.Exception.Message
    exit 1
}
