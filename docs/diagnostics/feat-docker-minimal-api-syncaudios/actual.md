# feat/docker-minimal-api-syncaudios — Diagnóstico

**Fecha:** 2026-01-23  
**Rama:** `feat/docker-minimal-api-syncaudios`  
**Estado:** En curso

---

## Objetivo

Configurar el entorno Docker para una Minimal API en C# con un endpoint funcional "SyncAudios".

### Definición de la Tarea

**Fase de Diseño:** Crear el Dockerfile y el proyecto Minimal API (.NET 8/9) que exponga el endpoint GET /SyncAudios.

**Integración de Almacén:** El endpoint debe invocar el script `.\Storage\Tekton\Tools\Ingesta_Audio.ps1` (asegura el mapeo de volúmenes en Docker para que el contenedor vea el Almacén).

**Orquestación:** Configurar un docker-compose.yml si es necesario para gestionar persistencia o variables de entorno.

**Kaizen colateral:** Asegurar que los logs de la API se escriban también en el `activity_stream.jsonl` del Almacén.

**Instrucción de Gobernanza:** Ejecutar los pasos de forma autónoma, reportando cada fase. No avanzar a la consolidación final hasta que la API compile y responda al endpoint.

---

## Kaizen del día

**Mejora técnica colateral:** Integración de logging estructurado de la Minimal API hacia `activity_stream.jsonl` del Almacén Tekton, manteniendo coherencia con el formato JSONL existente y asegurando trazabilidad completa de las operaciones de sincronización de audios.

---

## Próximos pasos

- [x] PASO 0: Verificar estado base (git status limpio)
- [x] PASO 1: Ejecutar Inicio-Tarea.ps1 y definir Kaizen del día
- [x] PASO 1.1: Analizar logs previos en session_history.json
- [x] PASO 2: Crear Dockerfile para Minimal API .NET 8/9
- [x] PASO 2: Crear proyecto Minimal API con endpoint GET /SyncAudios
- [x] PASO 2: Integrar invocación de Ingesta_Audio.ps1 con mapeo de volúmenes
- [x] PASO 2: Configurar docker-compose.yml para persistencia y variables
- [x] PASO 2: Configurar logs de API hacia activity_stream.jsonl
- [x] PASO 2: Validar compilación (✅ exitosa con `dotnet build`)
- [x] PASO 2: Dockerfile y docker-compose.yml configurados
- [ ] PASO 2: Validar respuesta del endpoint en Docker (build en progreso)
- [ ] PASO 3: Ejecutar Close-Task.ps1 para cierre técnico
- [ ] PASO 4: Ejecutar Sync-Latido.ps1 y actualizar activity_stream.jsonl

---

## Desarrollo

### Decisiones Técnicas

- **.NET 8:** Se utilizará .NET 8 para la Minimal API (versión LTS estable)
- **PowerShell Core:** El contenedor necesitará PowerShell Core para ejecutar el script Ingesta_Audio.ps1
- **Mapeo de volúmenes:** Se mapeará `./Storage` del host hacia `/app/storage` en el contenedor
- **Logging:** Se implementará un logger personalizado que escriba en formato JSONL hacia `activity_stream.jsonl`

### Problemas Encontrados

1. **Ruta del script:** Inicialmente se configuró la ruta como `Storage/Tekton/Tools/Ingesta_Audio.ps1`, pero la ruta correcta es `Storage/Scripts/Ingesta_Audio.ps1`. ✅ Corregido.

### Hitos Completados

1. **Proyecto Minimal API creado:** ✅
   - Proyecto .NET 8 Minimal API creado y compilado exitosamente
   - Endpoint GET /SyncAudios implementado
   - Integración con script PowerShell Ingesta_Audio.ps1

2. **Dockerfile actualizado:** ✅
   - PowerShell Core instalado en la imagen base
   - Multi-stage build configurado
   - Directorio /app/storage creado

3. **docker-compose.yml configurado:** ✅
   - Volumen de Storage mapeado: `./Storage:/app/storage`
   - Variable de entorno STORAGE_PATH configurada
   - Validación de configuración exitosa

4. **Logging hacia activity_stream.jsonl:** ✅
   - Logger personalizado `ActivityStreamLogger` implementado
   - Formato JSONL compatible con el formato existente
   - Thread-safe con SemaphoreSlim

---

## Cierre

_Se completará al finalizar la tarea._
