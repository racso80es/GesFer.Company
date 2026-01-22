# feat/refactor-core-complex — Mapa de Impacto (Pre-Auditoría)

**Fecha:** 2026-01-22  
**Rama:** `feat/refactor-core-complex`  
**Estado:** Ejecución Kaizen completada — constantes centralizadas; sistema de inicio autovalidante operativo

---

## 1. Alcance del rastreo

Se ha realizado un **rastreo completo del repositorio** en busca de:

- Términos definidos en `Tekton/Configuration/DICTIONARY.json`
- Referencias a **Company vs Empresa** y auditoría semántica (JUDGE_SENTINEL_ALWAYS)
- Uso de `semantic_coherence`, `terminology_check`, `company_usage`, `empresa_usage`
- Términos del ejemplo de Motor de Reglas: `ENTITY_COMPANY`, `company`, `empresa`, `sociedad`, `business_unit`
- Constantes hardcodeadas (timeouts, puertos) para futura centralización en `ENVIRONMENT_CONSTANTS`
- Scripts Tekton y de validación que consumirán el Diccionario / Motor de Reglas

**Nota:** `Tekton/Configuration/DICTIONARY.json` fue **creado** en esta rama como Motor de Reglas. El rastreo inicial se basó en:

- Reglas y configuraciones existentes (`Golden_rules.md`, `judge_config.json`, `judge_audit.json`)
- Términos del ejemplo de la directiva (Motor de Reglas con `ENTITY_COMPANY`)

El Mapa de Impacto identifica archivos que **se verán afectados** cuando se cree/refactorice el Diccionario y se parametrice el sistema.

---

## 2. Términos parametrizables (referencia)

| Término / Entidad | Estándar | Prohibidos / Alternativos | Fuente |
|-------------------|----------|---------------------------|--------|
| ENTITY_COMPANY    | `company` | `empresa`, `sociedad`, `business_unit` | Directiva S+; Golden_rules (Company vs Empresa) |
| Auditoría semántica | `semantic_coherence`, `terminology_check` | — | judge_config, judge_audit, session_history |

---

## 3. Archivos afectados por la parametrización

### 3.1 Creación / modificación directa del núcleo

| Archivo | Impacto | Descripción |
|---------|---------|-------------|
| `Tekton/Configuration/DICTIONARY.json` | **CREADO** | Motor de Reglas con `RULES_ENGINE`, `VALIDATION_LOGIC`, `ENVIRONMENT_CONSTANTS` (Latido 01). |
| `Tekton/Configuration/judge_config.json` | **MODIFICAR** | Referencias a Company vs Empresa, `semantic_coherence`, `terminology_check`. Debe alinearse con el Diccionario y posibles nuevos niveles de validación. |

### 3.2 Gobernanza y reglas

| Archivo | Impacto | Ocurrencias relevantes |
|---------|---------|-------------------------|
| `Tekton/Rules/Golden_rules.md` | **CONSULTA** | Company vs Empresa (líneas 92, 101); formato de auditoría con `semantic_coherence`, `terminology_check`. Inmutable salvo confirmación explícita. |
| `diagnostics/setup-tekton-core/actual.md` | **REFERENCIA** | Company vs Empresa (líneas 49, 138); validación terminológica. Documentación diagnóstica. (Raíz del repo, no `docs/`.) |

### 3.3 Logs y auditoría del Juez

| Archivo | Impacto | Ocurrencias relevantes |
|---------|---------|-------------------------|
| `Tekton/Logs/judge_audit.json` | **MODIFICAR** | `company_usage`, `empresa_usage`, `terminology_details`, `semantic_coherence`, `terminology_check` (schema level_3). Debe consumir términos del Motor de Reglas. |
| `Tekton/Logs/session_history.json` | **MODIFICAR** | Múltiples entradas con `semantic_coherence`, `terminology_check`. El formato de sesión debe ser coherente con la VALIDATION_LOGIC. |

### 3.4 Configuración IOTA y constantes de entorno

| Archivo | Impacto | Ocurrencias relevantes |
|---------|---------|-------------------------|
| `Tekton/Configuration/iota_config.json` | **MODIFICAR** | `timeout`: 30, `retry_attempts`: 3, `retry_delay`: 5. Candidatos para `ENVIRONMENT_CONSTANTS` (Latido 01). |
| `docker-compose.yml` | **MODIFICAR** | `APP_PORT`: 5000, `timeout`: 10s (healthcheck). |
| `Dockerfile` | **MODIFICAR** | `EXPOSE 5000`. |
| `README.md` | **REFERENCIA** | `APP_PORT`, descripción “empresas” (término a validar vs estándar). |
| `ansible/group_vars/all.yml` | **MODIFICAR** | `app_name`: gesfer-company. |
| `ansible/group_vars/development.yml` | **MODIFICAR** | `app_port`: 5000. |
| `ansible/group_vars/preproduction.yml` | **MODIFICAR** | `app_port`: 5000. |
| `ansible/group_vars/production.yml` | **MODIFICAR** | `app_port`: 5000. |
| `ansible/inventory/development.yml` | **MODIFICAR** | `deploy_path`: /var/www/gesfer-company, hosts. |
| `ansible/inventory/preproduction.yml` | **MODIFICAR** | Idem. |
| `ansible/inventory/production.yml` | **MODIFICAR** | Idem. |
| `ansible/roles/deploy/templates/docker-compose.yml.j2` | **MODIFICAR** | `app_port`, `timeout`: 10s (healthcheck). |
| `ansible/ansible.cfg` | **MODIFICAR** | `fact_caching_timeout`: 3600. |

### 3.5 Scripts Tekton y validación

| Archivo | Impacto | Descripción |
|---------|---------|-------------|
| `Tekton/Tools/Unificar-Rama.ps1` | **MODIFICAR** | Sin uso actual de términos del Diccionario. Debe integrar **VALIDATION_LOGIC**: comprobar términos prohibidos antes de merge/push; comportamiento ante violación (error/warning) según Motor de Reglas. |
| `scripts/validate.ps1` | **MODIFICAR** | Validación de infraestructura (docker-compose, Ansible). Candidato para añadir validación de términos prohibidos contra DICTIONARY.json. |
| `scripts/validate.sh` | **MODIFICAR** | Equivalente en bash. Mismo criterio. |

### 3.6 Otros archivos con referencias a “company” / “empresa”

| Archivo | Impacto | Notas |
|---------|---------|-------|
| `.cursorrules` | **NO MODIFICAR** | GesFer.Company (nombre del proyecto). |
| `Tekton/Configuration/iota_config.json` | Ya listado | `GESFER_COMPANY_MILESTONE`. |
| `ansible/playbooks/deploy.yml` | **REFERENCIA** | “Deploy GesFer Company Microservice”. |
| `ansible/playbooks/rollback.yml` | **REFERENCIA** | “Rollback GesFer Company Microservice”. |
| `ansible/README.md` | **REFERENCIA** | “Ansible Deployment para GesFer.Company”. |
| `README.md` | Ya listado | “Microservicio de gestión de **empresas**” — término a validar. |

---

## 4. Resumen por tipo de impacto

| Tipo | Cantidad | Archivos |
|------|----------|----------|
| **CREAR** | 1 | `Tekton/Configuration/DICTIONARY.json` |
| **MODIFICAR** | 18 | judge_config, judge_audit, session_history, iota_config, docker-compose, Dockerfile, ansible (vars, inventory, templates, ansible.cfg), Unificar-Rama.ps1, validate.ps1, validate.sh, README |
| **CONSULTA / REFERENCIA** | 6 | Golden_rules, setup-tekton-core/actual, deploy/rollback/README Ansible, .cursorrules |
| **NO MODIFICAR** | 1 | .cursorrules (inmutable) |

---

## 5. Métricas Latido 01 y constantes candidatas

Según `docs/audits/tae_closures.json` y referencias a **Latido 01**:

| Constante | Valor actual | Ubicación actual | Destino propuesto |
|-----------|--------------|------------------|-------------------|
| `app_port` | 5000 | docker-compose, Dockerfile, Ansible | `ENVIRONMENT_CONSTANTS` |
| `healthcheck_timeout` | 10s | docker-compose, Ansible template | `ENVIRONMENT_CONSTANTS` |
| `iota_node_timeout` | 30 | iota_config.json | `ENVIRONMENT_CONSTANTS` |
| `iota_retry_attempts` | 3 | iota_config.json | `ENVIRONMENT_CONSTANTS` |
| `iota_retry_delay` | 5 | iota_config.json | `ENVIRONMENT_CONSTANTS` |
| `ansible_fact_caching_timeout` | 3600 | ansible.cfg | `ENVIRONMENT_CONSTANTS` |

Estas métricas deben basarse en el último Kaizen (Latido 01) como indica la directiva.

---

## 6. Observabilidad y control de daños

- **Rama de trabajo:** Todo el desarrollo de la refactorización se realiza en `feat/refactor-core-complex`.
- **Regla de oro:** Prioridad a **observabilidad** y **control de daños**. Cualquier extensión del alcance debe documentarse aquí.

---

## 7. Ejecución Kaizen — Resumen

- **DICTIONARY.json:** Motor de Reglas creado con `ENTITY_COMPANY` (`status`, `standard_term`, `forbidden_synonyms`), `VALIDATION_LOGIC` y `ENVIRONMENT_CONSTANTS`.
- **Inicio-Tarea.ps1:** Herramienta de arranque de ramas; importa `DICTIONARY.json`, falla si el nombre de la tarea contiene términos prohibidos. Prefijos `[TAE-STEP]` para observabilidad.
- **Manifiestos .tool.json:** Generados para `Unificar-Rama.ps1`, `Inicio-Tarea.ps1`, `Start-Task.ps1`, `Close-Task.ps1`.

---

## 8. Cierre de diagnóstico

**Constantes centralizadas:** Las métricas de Latido 01 (puertos, timeouts, reintentos) están centralizadas en la sección `ENVIRONMENT_CONSTANTS` de `Tekton/Configuration/DICTIONARY.json`. Los consumidores (iota_config, docker-compose, Ansible, etc.) pueden parametrizarse en fases posteriores para leer desde esta fuente única.

**Sistema de inicio autovalidante:** `Inicio-Tarea.ps1` valida el nombre de la tarea contra `forbidden_synonyms` antes de crear rama o archivos. En caso de violación, el script falla (exit 1) y emite JSON con `success: false` y `forbidden_term`.

**Confirmación operativa (JSON de salida):** Ejecución en modo simulado:

```powershell
.\Tekton\Tools\Inicio-Tarea.ps1 -TaskName "operativity-check" -Simulate
```

Salida JSON (sistema operativo):

```json
{"branch":"feat/operativity-check","dictionary_used":"Tekton/Configuration/DICTIONARY.json","validation":"forbidden_terms_check","diagnostics_path":"docs/diagnostics/feat-operativity-check","simulated":true,"success":true,"system_operative":true,"actual_md_path":"docs/diagnostics/feat-operativity-check/actual.md"}
```

Rechazo por término prohibido (ej. `empresa`):

```powershell
.\Tekton\Tools\Inicio-Tarea.ps1 -TaskName "empresa-api" -Simulate
```

```json
{"success":false,"error":"Task name contains forbidden term","forbidden_term":"empresa","system_operative":false,...}
```

---

**Fin del Mapa de Impacto — Ejecución Kaizen completada. Sistema operativo.**
