# Golden Rules - GesFer.Company

## Directrices S+ Grade

> **Estado:** Activo con sistema de auditoría y protección de master
> **Última actualización:** 2026-01-22
> **Versión:** 1.1.0

Este archivo contiene las reglas de oro y directrices de nivel S+ para el desarrollo del microservicio GesFer.Company.

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

#### 8.1. Protección de Rama Master

**PROHIBICIÓN ABSOLUTA:** No se permite merge directo a la rama `master` (o `main`).

**Reglas obligatorias:**
- Todos los cambios deben realizarse mediante Pull Requests (PR)
- Los PRs deben pasar todas las validaciones antes de ser aprobados
- La rama `master` está protegida y requiere revisión explícita
- Cualquier intento de merge directo a `master` debe ser bloqueado y registrado

**Excepciones:** Ninguna. Esta regla es innegociable.

#### 8.2. Sistema de Auditoría y Logging

**OBLIGATORIEDAD:** Todas las interacciones deben ser registradas en `/Tekton/Logs/session_history.json`.

**Requisitos de registro:**
- Cada sesión de trabajo debe tener una entrada única con `session_id`
- Timestamp en formato ISO 8601 para cada interacción
- Contexto completo de la acción realizada
- Estado de la operación (pending, in_progress, completed, failed, blocked)
- Restricciones aplicadas durante la sesión
- Validación del formato JSON estricto

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
  "validation": { "json_valid": true, "schema_compliant": true }
}
```

#### 8.3. Análisis de Logs Previo

**INSTRUCCIÓN OBLIGATORIA:** Antes de iniciar tareas complejas, la IA debe:

1. **Leer y analizar** los últimos registros en `/Tekton/Logs/session_history.json`
2. **Identificar** patrones, errores previos o restricciones aplicadas
3. **Consultar** el historial de sesiones relacionadas con la tarea actual
4. **Verificar** que no haya conflictos con acciones previas
5. **Documentar** el análisis previo en la nueva sesión

**Objetivo:** Asegurar continuidad, prevenir errores repetidos y mantener coherencia en el desarrollo.

---

## Notas de Implementación

- Las directrices aquí definidas tienen prioridad sobre cualquier otra fuente de reglas
- Todas las decisiones técnicas deben alinearse con estas reglas
- Las excepciones deben ser documentadas y justificadas
- El sistema de auditoría es obligatorio y no puede ser omitido

---

_Este documento será actualizado con las directrices S+ Grade específicas del proyecto._
