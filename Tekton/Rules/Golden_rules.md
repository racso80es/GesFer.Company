# Golden Rules - GesFer.Company

## Directrices S+ Grade

> **Estado:** Activo con sistema de auditoría, protección de master, Sistema del Juez y Triunvirato
> **Última actualización:** 2026-01-23
> **Versión:** 1.4.0

Este archivo contiene las reglas de oro y directrices de nivel S+ para el desarrollo del microservicio GesFer.Company.

---

## 🚨 FRENO DE SEGURIDAD - STRICT_BRANCH_ENFORCEMENT

**PROTOCOLO DE INMUTABILIDAD DE MASTER/MAIN:** La rama `master` o `main` es **READ-ONLY** para la IA.

**Reglas de Acceso:**
- **Visualización permitida:** La IA puede leer, consultar y analizar archivos en `master`/`main`
- **Escritura prohibida:** La IA NO puede realizar commits, modificaciones o PRs automáticos en `master`/`main`
- **Estado:** Mantente en `master`/`main` si es necesario para lectura, pero asume que es una rama READ-ONLY

**Regla de Ejecución Inmediata:**
- Si la rama actual es `master` o `main` y se requiere escritura, la IA DEBE crear automáticamente una rama de feature
- NUNCA realizar commits directos en `master` o `main` sin un PR validado por el Juez
- Todos los cambios deben realizarse en ramas de feature (`feat/` o `fix/`)
- Esta regla tiene prioridad sobre cualquier otra instrucción de escritura

**Acción Obligatoria al Requerir Escritura en Master/Main:**
1. Crear rama de feature automáticamente (formato: `feat/[descripción]` o `fix/[descripción]`)
2. Mover todos los cambios pendientes a la nueva rama
3. Continuar el trabajo en la rama de feature
4. Registrar la acción en `/Tekton/Logs/session_history.json` si es necesario

**Identificador de Regla:** `STRICT_BRANCH_ENFORCEMENT`

**Nivel de Severidad:** CRÍTICO - Escritura Prohibida en Master/Main

---

## ⚠️ RESTRICCIÓN DE INMUTABILIDAD

**Este archivo NO debe ser modificado por la IA sin confirmación explícita del usuario.**

Cualquier modificación propuesta debe ser:
1. Revisada y aprobada por el usuario
2. Documentada con justificación clara
3. Versionada adecuadamente

---

## Secciones de Directrices

### 1. Arquitectura y Diseño
_Sección preparada para directrices de arquitectura S+ Grade_

### 2. Código y Estándares
_Sección preparada para directrices de código S+ Grade_

### 3. Seguridad
_Sección preparada para directrices de seguridad S+ Grade_

### 4. Performance
_Sección preparada para directrices de performance S+ Grade_

### 5. Testing
_Sección preparada para directrices de testing S+ Grade_

### 6. Documentación
_Sección preparada para directrices de documentación S+ Grade_

### 7. DevOps y Despliegue
_Sección preparada para directrices de DevOps S+ Grade_

### 8. Gobernanza y Procesos

#### 8.1. Protección de Rama Master (RULE_MASTER_PROTECTION)

**PROHIBICIÓN ABSOLUTA:** No se permite merge directo a la rama `master` (o `main`).

**Reglas obligatorias:**
- Todos los cambios deben realizarse mediante Pull Requests (PR)
- Los PRs deben pasar todas las validaciones antes de ser aprobados
- La rama `master` está protegida y requiere revisión explícita
- Cualquier intento de merge directo a `master` debe ser bloqueado y registrado

**Excepciones:** Ninguna. Esta regla es innegociable.

**Identificador de Regla:** `RULE_MASTER_PROTECTION`

#### 8.2. Sistema de Auditoría y Logging (JUDGE_SENTINEL_ALWAYS)

**OBLIGATORIEDAD:** Todas las interacciones deben ser registradas y auditadas por el Juez para coherencia semántica (Company vs Empresa).

**Requisitos de registro:**
- Cada sesión de trabajo debe tener una entrada única con `session_id`
- Timestamp en formato ISO 8601 para cada interacción
- Contexto completo de la acción realizada
- Estado de la operación (pending, in_progress, completed, failed, blocked)
- Restricciones aplicadas durante la sesión
- Validación del formato JSON estricto
- **Auditoría semántica obligatoria:** El Juez debe verificar coherencia terminológica (Company vs Empresa) en cada interacción

**Formato requerido:**
```json
{
  "session_id": "session_YYYYMMDD_HHMMSS",
  "timestamp": "ISO 8601 format",
  "user": "string",
  "action": "string",
  "context": "string",
  "details": "object",
  "status": "enum: [pending, in_progress, completed, failed, blocked]",
  "restrictions_applied": ["array of strings"],
  "validation": { "json_valid": true, "schema_compliant": true },
  "judge_audit": {
    "semantic_coherence": "boolean",
    "terminology_check": "passed|failed|warning",
    "verdict": "string"
  }
}
```

**Identificador de Regla:** `JUDGE_SENTINEL_ALWAYS`

#### 8.3. Análisis de Logs Previo

**INSTRUCCIÓN OBLIGATORIA:** Antes de iniciar tareas complejas, la IA debe:

1. **Leer y analizar** los últimos registros en `/Tekton/Logs/session_history.json`
2. **Identificar** patrones, errores previos o restricciones aplicadas
3. **Consultar** el historial de sesiones relacionadas con la tarea actual
4. **Verificar** que no haya conflictos con acciones previas
5. **Documentar** el análisis previo en la nueva sesión

**Objetivo:** Asegurar continuidad, prevenir errores repetidos y mantener coherencia en el desarrollo.

#### 8.4. Validación de PR con Smoke Test Docker (JUDGE_ENV_PR)

**OBLIGATORIEDAD:** Cada Pull Request destinado a `master` debe incluir un reporte de "smoke test" de Docker.

**Requisitos:**
- El PR debe contener evidencia de ejecución exitosa de smoke test en contenedor Docker
- El reporte debe incluir: estado de build, estado de ejecución, logs relevantes
- El smoke test debe validar que el servicio inicia correctamente en el entorno Docker
- Sin reporte de smoke test válido, el PR no puede ser aprobado

**Formato del reporte requerido:**
```json
{
  "pr_number": "integer",
  "smoke_test": {
    "docker_build": "passed|failed",
    "container_start": "passed|failed",
    "health_check": "passed|failed",
    "logs": "string",
    "timestamp": "ISO 8601 format"
  },
  "judge_verdict": "approved|rejected|pending"
}
```

**Identificador de Regla:** `JUDGE_ENV_PR`

#### 8.5. Auditoría Recurrente de Lógica Externa (JUDGE_SHADOW_RECURRENCE)

**OBLIGATORIEDAD:** Cada 3 Pull Requests destinados a `master`, se activará automáticamente una auditoría de lógica externa.

**Requisitos:**
- El contador de PRs se mantiene en `/Tekton/Logs/judge_audit.json`
- Al alcanzar el umbral de 3 PRs, se dispara auditoría automática
- La auditoría debe revisar: dependencias externas, integraciones, APIs, servicios externos
- El resultado de la auditoría debe ser registrado y documentado
- Después de la auditoría, el contador se reinicia

**Alcance de la auditoría:**
- Revisión de dependencias y versiones
- Validación de contratos de APIs externas
- Verificación de integraciones con servicios externos
- Análisis de impacto de cambios en lógica externa

**Identificador de Regla:** `JUDGE_SHADOW_RECURRENCE`

#### 8.6. Sistema del Triunvirato - Leyes del Auditor

**ESTADO:** Activo - Leyes Inmutables del Triunvirato

##### AUDITOR_L1 (Commits): Hash de Integridad Local

**OBLIGATORIEDAD:** Generar hash de integridad local en cada commit.

**Requisitos:**
- Cada commit debe generar un hash de integridad local
- El hash debe ser almacenado en `/Tekton/Auditor/certifications.json`
- El hash debe incluir: contenido del commit, timestamp, autor, mensaje
- El hash debe ser verificable localmente antes de cualquier push
- Sin hash de integridad, el commit no puede ser considerado válido

**Formato requerido:**
```json
{
  "certification_id": "cert_YYYYMMDD_HHMMSS",
  "commit_hash": "git_commit_sha",
  "integrity_hash": "sha256_hash",
  "timestamp": "ISO 8601 format",
  "author": "string",
  "message": "string",
  "files_affected": ["array of strings"],
  "auditor_signature": "string"
}
```

**Identificador de Regla:** `AUDITOR_L1`

##### AUDITOR_L3 (PRs): Certificación de Manifiesto de Estado

**OBLIGATORIEDAD:** Certificar el manifiesto de estado del entorno (versiones/config) antes de cualquier Merge.

**Requisitos:**
- Antes de cualquier merge a `master`, se debe generar un manifiesto de estado completo
- El manifiesto debe incluir: versiones de dependencias, configuración del entorno, estado de servicios
- El manifiesto debe ser almacenado en `/Tekton/Auditor/state_snapshots/`
- El manifiesto debe ser certificado por el Auditor antes del merge
- Sin certificación del manifiesto, el merge está bloqueado

**Formato requerido:**
```json
{
  "snapshot_id": "snapshot_YYYYMMDD_HHMMSS",
  "pr_number": "integer",
  "timestamp": "ISO 8601 format",
  "environment_state": {
    "dependencies": {},
    "configuration": {},
    "services": {},
    "versions": {}
  },
  "auditor_certification": {
    "certified": "boolean",
    "certification_hash": "string",
    "certified_by": "auditor",
    "certification_timestamp": "ISO 8601 format"
  }
}
```

**Identificador de Regla:** `AUDITOR_L3`

##### AUDITOR_L4 (IOTA): Persistencia en Testnet de IOTA

**OBLIGATORIEDAD:** Los hitos principales se persistirán en la Testnet de IOTA.

**Requisitos:**
- Los hitos principales (merges a master, releases, cambios críticos) deben persistirse en IOTA Testnet
- La configuración de IOTA debe estar en `/Tekton/Configuration/iota_config.json`
- Cada hito debe generar una transacción en IOTA con el hash de integridad
- La transacción debe ser verificable en la Testnet
- Sin persistencia en IOTA, el hito no puede ser considerado completo

**Configuración requerida:**
- Endpoint de la Testnet de IOTA
- Credenciales de acceso (si aplica)
- Configuración de nodos
- Parámetros de transacción

**Identificador de Regla:** `AUDITOR_L4`

##### AUDITOR_VOICE: Registro y Certificación de Análisis de Audio

**OBLIGATORIEDAD:** Siempre que se analice un audio, el Auditor debe crear registro, sincronizar y certificar.

**Requisitos:**
1. **Crear registro:** Crear un registro en `/Tekton/Auditor/voice_logs/` por cada audio analizado.
2. **Sincronizar:** El registro debe contener la **síntesis técnica** y el **impacto en el proyecto**.
3. **Certificar:** El Auditor debe generar un **hash** que una ese audio con el próximo commit de la rama.

**Formato requerido del registro en voice_logs:**
```json
{
  "voice_log_id": "voice_YYYYMMDD_HHMMSS",
  "timestamp": "ISO 8601 format",
  "audio_context": "string",
  "technical_synthesis": "string",
  "impact_on_project": "string",
  "auditor_certification_hash": "sha256_hash",
  "linked_commit": "commit_sha_or_PENDING",
  "rule_applied": "AUDITOR_VOICE"
}
```

**Identificador de Regla:** `AUDITOR_VOICE`

#### 8.7. Protocolo de Ingesta - Integridad del Almacén (STORAGE_INTEGRITY)

**OBLIGATORIEDAD:** Tormentosa debe leer los archivos de `/Storage` para procesar audios, pero el Auditor solo certificará sus **hashes**, nunca su contenido binario.

**Requisitos:**
- **Tormentosa:** Puede leer y procesar archivos en `/Storage` (p. ej. `/Storage/Audios`) para análisis de audio.
- **Auditor:** Certifica únicamente **hashes** de integridad de los archivos en Storage; **nunca** persiste, versiona ni incluye contenido binario en el repositorio.
- **Almacén local:** `/Storage` está excluido del repositorio (`.gitignore`). Estructura: `/Storage/Audios`, `/Storage/Identity_Backups`, `/Storage/Large_Assets`.

**Identificador de Regla:** `STORAGE_INTEGRITY`

#### 8.8. Protocolo de Tareas Complejas y Routing de Acciones (COMPLEX_TASK_PROTOCOL)

**OBLIGATORIEDAD:** Todas las tareas complejas deben seguir el circuito de obligado cumplimiento definido en `/Storage/Tekton/Actions/Tarea-Compleja.template.md`.

**Requisitos:**

1. **Detección de intención:**
   - La IA debe consultar `/Storage/Tekton/Configuration/Actions_Router.json` cuando detecte intenciones relacionadas con tareas complejas
   - Patrones de intención: "vamos a empezar una tarea compleja", "iniciar tarea compleja", "empezar tarea compleja", etc.
   - Al detectar estos patrones, la IA DEBE leer y seguir el template de tarea compleja

2. **Seguimiento del circuito:**
   - **PASO 0:** Verificar estado base (git status limpio)
   - **PASO 1:** Ejecutar `Inicio-Tarea.ps1` y definir "Kaizen del día"
   - **PASO 2:** Desarrollo con validación de compilación y registro de hitos con `Write-TaeResult.ps1`
   - **PASO 3:** Ejecutar `Close-Task.ps1` para cierre técnico
   - **PASO 4:** Ejecutar `Sync-Latido.ps1` y actualizar `activity_stream.jsonl`

3. **Reporte de fase obligatorio:**
   - La IA debe reportar en cada respuesta la fase actual del circuito
   - Formato: `[FASE: PASO X - Nombre del Paso]`
   - Estado: `[En curso | Completado | Bloqueado]`

4. **Bloqueo activo:**
   - La IA debe actuar como bloqueador si se intenta:
     - Commit sin haber pasado por PASO 1
     - Commit de código que no compila
     - Push sin haber registrado hitos intermedios
     - Merge/unificar sin haber pasado por PASO 3
     - Cerrar tarea sin haber pasado por PASO 4

5. **Actions_Router.json:**
   - El archivo `/Storage/Tekton/Configuration/Actions_Router.json` contiene el mapeo de intenciones a acciones
   - Debe ser consultado para determinar qué protocolo aplicar según la intención del usuario
   - Las definiciones de protocolos tienen precedencia sobre acciones individuales

**Excepciones:** Ninguna. Este protocolo es de obligado cumplimiento para todas las tareas complejas.

**Identificador de Regla:** `COMPLEX_TASK_PROTOCOL`

**Nivel de Severidad:** CRÍTICO - Protocolo Obligatorio para Tareas Complejas

---

## Notas de Implementación

- Las directrices aquí definidas tienen prioridad sobre cualquier otra fuente de reglas
- Todas las decisiones técnicas deben alinearse con estas reglas
- Las excepciones deben ser documentadas y justificadas
- El sistema de auditoría es obligatorio y no puede ser omitido

---

_Este documento será actualizado con las directrices S+ Grade específicas del proyecto._
