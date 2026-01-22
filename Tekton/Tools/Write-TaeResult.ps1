<#
.SYNOPSIS
    Normalizador de salida TAE. Genera JSON estructurado para IA y persiste en activity_stream.jsonl.

.DESCRIPTION
    Componente centralizado para normalizar la salida de todas las herramientas TAE.
    Emite JSON estructurado a consola (para procesamiento por IA) y persiste en formato
    JSON Lines (JSONL) para análisis posterior y auditoría.

.PARAMETER SourceTool
    Identificador de la herramienta TAE que genera el resultado (ej: "TAE-001-START", "TAE-002-UNIFY").

.PARAMETER Status
    Estado de la operación: "Success", "Failure", o "Warning".

.PARAMETER Payload
    Hashtable con los datos específicos del resultado de la herramienta.

.PARAMETER AuditStamp
    Sello de auditoría / Latido / Correlation ID asociado a la operación.

.EXAMPLE
    $payload = @{ branch = "feat/test"; diagnostics_path = "docs/diagnostics/feat-test" }
    .\Write-TaeResult.ps1 -SourceTool "TAE-001-START" -Status "Success" -Payload $payload -AuditStamp "STAMP_20260123_120000"

.EXAMPLE
    $payload = @{ error = "Validation failed"; forbidden_term = "empresa" }
    .\Write-TaeResult.ps1 -SourceTool "TAE-001-START" -Status "Failure" -Payload $payload -AuditStamp "STAMP_20260123_120000"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $SourceTool,
    
    [Parameter(Mandatory = $true)]
    [ValidateSet("Success", "Failure", "Warning")]
    [string] $Status,
    
    [Parameter(Mandatory = $true)]
    [hashtable] $Payload,
    
    [Parameter(Mandatory = $false)]
    [string] $AuditStamp = ""
)

$ErrorActionPreference = "Stop"

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

function Write-TaeResultToConsole {
    param(
        [string] $SourceTool,
        [string] $Status,
        [hashtable] $Payload,
        [string] $AuditStamp
    )
    
    $timestamp = Get-Date -Format "o"
    
    $result = @{
        source_tool = $SourceTool
        status = $Status
        timestamp = $timestamp
        payload = $Payload
    }
    
    if (-not [string]::IsNullOrWhiteSpace($AuditStamp)) {
        $result["audit_stamp"] = $AuditStamp
    }
    
    # Emitir JSON compacto para procesamiento por IA
    $json = $result | ConvertTo-Json -Compress -Depth 10
    Write-Output $json
}

function Write-TaeResultToStream {
    param(
        [string] $SourceTool,
        [string] $Status,
        [hashtable] $Payload,
        [string] $AuditStamp,
        [string] $StreamPath
    )
    
    $timestamp = Get-Date -Format "o"
    
    $entry = @{
        source_tool = $SourceTool
        status = $Status
        timestamp = $timestamp
        payload = $Payload
    }
    
    if (-not [string]::IsNullOrWhiteSpace($AuditStamp)) {
        $entry["audit_stamp"] = $AuditStamp
    }
    
    # Convertir a JSON Lines (una línea por entrada)
    $jsonLine = $entry | ConvertTo-Json -Compress -Depth 10
    
    # Añadir línea al archivo JSONL (append mode)
    try {
        Add-Content -Path $StreamPath -Value $jsonLine -Encoding UTF8 -NoNewline
        Add-Content -Path $StreamPath -Value "" -Encoding UTF8
    } catch {
        Write-Error "Failed to write to activity stream: $($_.Exception.Message)"
        throw
    }
}

try {
    $root = Get-RepoRoot
    if (-not $root) {
        # Si no hay repo, solo emitir a consola
        Write-TaeResultToConsole -SourceTool $SourceTool -Status $Status -Payload $Payload -AuditStamp $AuditStamp
        exit 0
    }
    
    $streamPath = Get-ActivityStreamPath -Root $root
    
    # Función 1: Emitir a consola (para IA)
    Write-TaeResultToConsole -SourceTool $SourceTool -Status $Status -Payload $Payload -AuditStamp $AuditStamp
    
    # Función 2: Persistir en JSONL (para auditoría y análisis)
    Write-TaeResultToStream -SourceTool $SourceTool -Status $Status -Payload $Payload -AuditStamp $AuditStamp -StreamPath $streamPath
    
    exit 0
}
catch {
    Write-Error "Write-TaeResult failed: $($_.Exception.Message)"
    # Intentar emitir resultado de error a consola
    $errorPayload = @{ error = $_.Exception.Message; original_payload = $Payload }
    Write-TaeResultToConsole -SourceTool $SourceTool -Status "Failure" -Payload $errorPayload -AuditStamp $AuditStamp
    exit 1
}
