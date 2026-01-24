<#
.SYNOPSIS
    Herramienta TAE de inicio de tarea. Automatiza arranque de ramas, carpeta de diagnóstico
    e inicialización de actual.md. Requisito S+: valida contra DICTIONARY.json (términos prohibidos).

.DESCRIPTION
    Crea rama feat/<TaskName>, docs/diagnostics/feat-<TaskName>/ y actual.md inicial.
    Importa Tekton/Configuration/DICTIONARY.json y FALLA si el nombre de la tarea contiene
    términos prohibidos (forbidden_synonyms). Salida AI-READY: JSON al finalizar.

.PARAMETER TaskName
    Nombre de la tarea (ej. "refactor-core-complex"). Se usa para rama feat/<TaskName>
    y carpeta docs/diagnostics/feat-<TaskName>/. No puede contener términos prohibidos.

.PARAMETER BaseBranch
    Rama base para crear la nueva rama. Por defecto: main.

.PARAMETER Simulate
    Solo validar contra DICTIONARY y emitir JSON; no crea rama ni archivos. Útil para comprobar operatividad.

.EXAMPLE
    .\Inicio-Tarea.ps1 -TaskName "add-company-api"
.EXAMPLE
    .\Inicio-Tarea.ps1 -TaskName "empresa-api"
    # Falla: "empresa" es término prohibido.
.EXAMPLE
    .\Inicio-Tarea.ps1 -TaskName "operativity-check" -Simulate
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $TaskName,
    [Parameter()]
    [string] $BaseBranch = "main",
    [Parameter()]
    [switch] $Simulate
)

$ErrorActionPreference = "Stop"

function Write-TaeInfo { param([string]$Message) Write-Host "[TAE-INFO] $Message" }
function Write-TaeStep { param([string]$Message) Write-Host "[TAE-STEP] $Message" }

function Get-RepoRoot {
    $r = git rev-parse --show-toplevel 2>$null
    if (-not $r) { return $null }
    return $r.Trim()
}

function Get-DictionaryPath {
    param([string] $Root)
    return Join-Path (Join-Path (Join-Path $Root "Tekton") "Configuration") "DICTIONARY.json"
}

function Get-ForbiddenSynonyms {
    param([string] $DictPath)
    if (-not (Test-Path $DictPath)) {
        throw "DICTIONARY.json no encontrado: $DictPath"
    }
    $raw = Get-Content $DictPath -Raw -Encoding UTF8
    $dict = $raw | ConvertFrom-Json
    $entity = $dict.RULES_ENGINE.PSObject.Properties | Where-Object { $_.Name -eq "ENTITY_COMPANY" } | Select-Object -First 1
    if (-not $entity) {
        throw "RULES_ENGINE.ENTITY_COMPANY no definido en DICTIONARY.json"
    }
    $synonyms = $entity.Value.forbidden_synonyms
    if (-not $synonyms) { return @() }
    return @($synonyms)
}

function Test-TaskNameAllowed {
    param(
        [string] $Name,
        [string[]] $Forbidden
    )
    $lower = $Name.ToLowerInvariant()
    foreach ($term in $Forbidden) {
        if ([string]::IsNullOrWhiteSpace($term)) { continue }
        if ($lower.Contains($term.ToLowerInvariant())) {
            return @{ Ok = $false; Forbidden = $term }
        }
    }
    return @{ Ok = $true; Forbidden = $null }
}

function Out-InicioJsonResult {
    param(
        [bool] $Success,
        [string] $Branch = "",
        [string] $DiagnosticsPath = "",
        [string] $ActualPath = "",
        [string] $ErrorMessage = "",
        [string] $ForbiddenTerm = "",
        [bool] $Simulated = $false
    )
    $obj = @{
        success          = $Success
        branch           = $Branch
        diagnostics_path = $DiagnosticsPath
        actual_md_path   = $ActualPath
        dictionary_used  = "Tekton/Configuration/DICTIONARY.json"
        validation       = "forbidden_terms_check"
        system_operative = $Success
    }
    if ($ErrorMessage) { $obj["error"] = $ErrorMessage }
    if ($ForbiddenTerm) { $obj["forbidden_term"] = $ForbiddenTerm }
    if ($Simulated) { $obj["simulated"] = $true }
    $json = $obj | ConvertTo-Json -Compress
    Write-Output $json
}

try {
    Write-TaeStep "Iniciando Inicio-Tarea (TAE)."

    $root = Get-RepoRoot
    if (-not $root) {
        Write-TaeInfo "No se detecta repositorio git."
        Out-InicioJsonResult -Success $false -ErrorMessage "Not a git repository"
        exit 1
    }

    if (-not $Simulate) {
        Write-TaeStep "Verificando estado limpio del repositorio (git_clean_status)."
        $gitStatus = git status --porcelain 2>$null
        if ($gitStatus) {
            Write-TaeInfo "El repositorio tiene cambios sin commitear. Limpie el working directory antes de crear una nueva rama."
            Out-InicioJsonResult -Success $false -ErrorMessage "Working directory is not clean. Commit or stash changes before creating a new branch."
            exit 1
        }
        Write-TaeInfo "Validación de git_clean_status: superada."
    }

    $dictPath = Get-DictionaryPath -Root $root
    Write-TaeStep "Cargando Motor de Reglas: DICTIONARY.json."
    $forbidden = Get-ForbiddenSynonyms -DictPath $dictPath

    $validation = Test-TaskNameAllowed -Name $TaskName -Forbidden $forbidden
    if (-not $validation.Ok) {
        Write-TaeInfo "Rechazado: el nombre de la tarea contiene el término prohibido '$($validation.Forbidden)'."
        Out-InicioJsonResult -Success $false -ErrorMessage "Task name contains forbidden term" -ForbiddenTerm $validation.Forbidden
        exit 1
    }
    Write-TaeInfo "Validación de términos prohibidos: superada."

    if ($Simulate) {
        Write-TaeStep "Modo simulado: validación OK. No se crean rama ni archivos."
        Out-InicioJsonResult -Success $true -Branch "feat/$TaskName" -DiagnosticsPath "docs/diagnostics/feat-$TaskName" -ActualPath "docs/diagnostics/feat-$TaskName/actual.md" -Simulated $true
        exit 0
    }

    $branchName = "feat/$TaskName"
    $diagFolder = "feat-$TaskName"
    $diagPath = Join-Path (Join-Path (Join-Path $root "docs") "diagnostics") $diagFolder
    $actualPath = Join-Path $diagPath "actual.md"

    Write-TaeStep "Creación de rama: $branchName desde $BaseBranch."
    $gitErrPref = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $branchCreateOk = $false
    try {
        git fetch origin 2>$null | Out-Null
        $baseRef = $null
        if (git rev-parse --verify $BaseBranch 2>$null) { $baseRef = $BaseBranch }
        if (-not $baseRef -and (git rev-parse --verify "origin/$BaseBranch" 2>$null)) { $baseRef = "origin/$BaseBranch" }
        if (-not $baseRef) {
            Write-TaeInfo "Rama base '$BaseBranch' no existe."
            Out-InicioJsonResult -Success $false -ErrorMessage "Base branch '$BaseBranch' not found"
            exit 1
        }
        git checkout -b $branchName $baseRef 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $branchCreateOk = $true
        } else {
            $existing = git rev-parse --verify $branchName 2>$null
            if ($existing) {
                git checkout $branchName 2>$null | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    Write-TaeInfo "Rama '$branchName' ya existe; se usará la actual."
                    $branchCreateOk = $true
                }
            }
        }
    } catch {
        $branchExists = git rev-parse --verify $branchName 2>$null
        $onBranch = (git branch --show-current 2>$null) -eq $branchName
        if ($branchExists -and $onBranch) {
            Write-TaeInfo "Rama '$branchName' ya existe; se usará la actual."
            $branchCreateOk = $true
        }
    } finally {
        $ErrorActionPreference = $gitErrPref
    }
    if (-not $branchCreateOk) {
        Write-TaeInfo "No se pudo crear o cambiar a la rama '$branchName'."
        Out-InicioJsonResult -Success $false -ErrorMessage "Failed to create or checkout branch '$branchName'"
        exit 1
    }
    Write-TaeInfo "Rama activa: $branchName."

    Write-TaeStep "Creación de carpeta de diagnóstico: docs/diagnostics/$diagFolder."
    if (-not (Test-Path $diagPath)) {
        New-Item -ItemType Directory -Path $diagPath -Force | Out-Null
    }
    Write-TaeInfo "Carpeta de diagnóstico lista."

    Write-TaeStep "Inicialización de actual.md."
    $stamp = Get-Date -Format "yyyy-MM-dd"
    $actualContent = @"
# feat/$TaskName — Diagnóstico

**Fecha:** $stamp  
**Rama:** `$branchName`  
**Estado:** En curso

---

## Objetivo

Tarea iniciada con Inicio-Tarea.ps1. Validación contra DICTIONARY.json (términos prohibidos): superada.

---

## Próximos pasos

- Desarrollar en `$branchName`.
- Actualizar este diagnóstico según avances.
- Cerrar con Unificar-Rama.ps1 cuando corresponda.

"@
    [System.IO.File]::WriteAllText($actualPath, $actualContent, [System.Text.UTF8Encoding]::new($false))
    Write-TaeInfo "actual.md creado en docs/diagnostics/$diagFolder/."

    Write-TaeStep "Inicio-Tarea completado."
    Out-InicioJsonResult -Success $true -Branch $branchName -DiagnosticsPath "docs/diagnostics/$diagFolder" -ActualPath "docs/diagnostics/$diagFolder/actual.md"
    exit 0
}
catch {
    Write-TaeInfo "Error crítico: $($_.Exception.Message)"
    Out-InicioJsonResult -Success $false -ErrorMessage $_.Exception.Message
    exit 1
}
