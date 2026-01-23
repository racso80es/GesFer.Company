# 🧠 PROTOCOLO DE EJECUCIÓN S+ (TAE)

**Versión:** 1.0.0  
**Fecha:** 2026-01-23  
**Estándar:** S-Grade-TAE

---

## OBJETIVO

Garantizar que cada tarea compleja deje el sistema mejor de lo que lo encontró.

---

## 🛠️ CICLO DE VIDA OBLIGATORIO

### FASE 0: DIAGNÓSTICO Y KAIZEN (EL COMPROMISO)

**Acción:** Identificar qué punto del sistema se va a optimizar (Kaizen).

**Meta Actual:** Migrar las herramientas de `Tekton/Tools/` a la ruta centralizada `Storage/Tekton/Tools/` para consolidar el almacén.

**Herramientas:** Ninguna (fase de análisis).

---

### FASE 1: INICIACIÓN (Inicio-Tarea)

**Herramienta:** `.\Storage\Tekton\Tools\Inicio-Tarea.ps1`

**Propósito:**
- Crear el entorno de trabajo (rama `feat/<TaskName>`, documentación de entrada)
- Notificar al sistema el inicio del latido
- Validar contra `DICTIONARY.json` (términos prohibidos)
- Verificar estado limpio del repositorio (`git_clean_status`)

**Uso:**
```powershell
.\Storage\Tekton\Tools\Inicio-Tarea.ps1 -TaskName "mi-tarea" -BaseBranch "main"
```

**Salida:** JSON con `success`, `branch`, `diagnostics_path`, `actual_md_path`

---

### FASE 2: DESARROLLO E ITERACIÓN

**Regla:** Uso constante de `Write-TaeResult.ps1` para reportar hitos parciales.

**Compilación:** Obligatoria cada 20 líneas de cambio estructural [cite: 2026-01-16].

**Herramienta de telemetría:**
```powershell
.\Storage\Tekton\Tools\Write-TaeResult.ps1 -SourceTool "TAE-XXX" -Status "Success|Failure|Warning" -Payload @{...} -AuditStamp "LATIDO_XXX"
```

**Persistencia:** `Tekton/Logs/activity_stream.jsonl`

---

### FASE 3: CIERRE DE TAREA (Close-Task)

**Herramienta:** `.\Storage\Tekton\Tools\Close-Task.ps1`

**Propósito:**
- Validar el cumplimiento de los objetivos de la tarea
- Actualizar `docs/diagnostics/feat-<TaskName>/actual.md`
- Generar `AuditStamp` si no se proporciona
- Preparar la rama para la unificación
- Integrar con `Write-TaeResult.ps1` para telemetría

**Uso:**
```powershell
.\Storage\Tekton\Tools\Close-Task.ps1 -AuditStamp "LATIDO_03_MIGRATION_COMPLETE"
```

**Salida:** JSON con `success`, `audit_stamp`, `next_step`

---

### FASE 4: CONSOLIDACIÓN GLOBAL (Sync-Latido)

**Herramienta:** `.\Storage\Tekton\Tools\Sync-Latido.ps1`

**Propósito:**
- Sincronización final con el Almacén y la Nube
- Asegurar que el Kaizen aplicado se distribuya a todo el ecosistema
- Validación de `Vision.md`
- Refactorización automática de herramientas si es necesario
- Consolidación de cambios, saneamiento de ramas, push a `origin/main`
- Certificación en `activity_stream.jsonl`

**Uso:**
```powershell
.\Storage\Tekton\Tools\Sync-Latido.ps1 -AuditStamp "LATIDO_04_FULL_SYNC"
```

**Salida:** Telemetría vía `Write-TaeResult.ps1`

---

## ⚠️ NOTIFICACIÓN CRÍTICA

**Cualquier tarea que no use `Inicio-Tarea` al empezar y `Close-Task` al finalizar será considerada "Tarea Fallida" bajo el protocolo de Tormentosa.**

---

## 📋 CHECKLIST DE CUMPLIMIENTO

- [ ] FASE 0: Kaizen identificado y documentado
- [ ] FASE 1: `Inicio-Tarea.ps1` ejecutado (rama creada, diagnóstico inicializado)
- [ ] FASE 2: Desarrollo con telemetría (`Write-TaeResult.ps1` en hitos)
- [ ] FASE 3: `Close-Task.ps1` ejecutado (validación, actualización de diagnóstico)
- [ ] FASE 4: `Sync-Latido.ps1` ejecutado (sincronización completa) - Opcional pero recomendado

---

## 🔗 HERRAMIENTAS DEL PROTOCOLO

| Herramienta | ID | Fase | Ruta |
|-------------|----|------|------|
| Inicio-Tarea | TAE-001-START | 1 | `Storage/Tekton/Tools/Inicio-Tarea.ps1` |
| Write-TaeResult | TAE-TELEMETRY | 2 | `Storage/Tekton/Tools/Write-TaeResult.ps1` |
| Close-Task | TAE-003-CLOSE | 3 | `Storage/Tekton/Tools/Close-Task.ps1` |
| Unificar-Rama | TAE-002-UNIFY | 3.5 | `Storage/Tekton/Tools/Unificar-Rama.ps1` |
| Sync-Latido | TAE-004-SYNC | 4 | `Storage/Tekton/Tools/Sync-Latido.ps1` |

---

**Última actualización:** 2026-01-23  
**Mantenido por:** Sistema TAE / Protocolo S+
