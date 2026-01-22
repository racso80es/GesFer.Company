# GesFer.Company

Microservicio de gestión de empresas para GesFer V2.

## 🏗️ Infraestructura

### Docker & Docker Compose

El proyecto utiliza Docker para la containerización del microservicio.

#### Levantar el servicio

```bash
docker-compose up -d
```

#### Verificar estado

```bash
docker-compose ps
```

#### Ver logs

```bash
docker-compose logs -f gesfer-company
```

#### Detener el servicio

```bash
docker-compose down
```

### Ansible & Ansistrano

La infraestructura de despliegue está configurada con Ansible siguiendo el patrón Ansistrano (estilo Capistrano).

#### Estructura de Entornos

- **Development**: Entorno de desarrollo local
- **Preproduction**: Entorno de preproducción
- **Production**: Entorno de producción

#### Despliegue

```bash
# Development
ansible-playbook -i ansible/inventory/development.yml ansible/playbooks/deploy.yml

# Preproduction
ansible-playbook -i ansible/inventory/preproduction.yml ansible/playbooks/deploy.yml

# Production
ansible-playbook -i ansible/inventory/production.yml ansible/playbooks/deploy.yml
```

#### Rollback

```bash
# Development
ansible-playbook -i ansible/inventory/development.yml ansible/playbooks/rollback.yml

# Preproduction
ansible-playbook -i ansible/inventory/preproduction.yml ansible/playbooks/rollback.yml

# Production
ansible-playbook -i ansible/inventory/production.yml ansible/playbooks/rollback.yml
```

#### Validación de Sintaxis

```bash
# Validar playbooks
ansible-playbook --syntax-check -i ansible/inventory/development.yml ansible/playbooks/deploy.yml
ansible-playbook --syntax-check -i ansible/inventory/development.yml ansible/playbooks/rollback.yml
```

O usar el script de validación:

```bash
# PowerShell
.\scripts\validate.ps1

# Bash
./scripts/validate.sh
```

## 📋 Requisitos Previos

- Docker y Docker Compose
- Ansible (para despliegues automatizados)
- Python 3.x (para Ansible)

## 🚀 Inicio Rápido

1. Clonar el repositorio
2. Configurar variables de entorno si es necesario
3. Levantar con Docker Compose: `docker-compose up -d`
4. Verificar que el servicio esté corriendo: `docker-compose ps`

## 📁 Estructura del Proyecto

```
GesFer.Company/
├── docker-compose.yml      # Configuración de Docker Compose
├── Dockerfile              # Imagen Docker del microservicio
├── ansible/                # Configuración de Ansible
│   ├── inventory/         # Inventarios por entorno
│   ├── group_vars/        # Variables por grupo
│   ├── roles/             # Roles de Ansible (deploy/rollback)
│   └── playbooks/         # Playbooks principales
└── scripts/               # Scripts de utilidad
```

## 🔧 Configuración

### Variables de Entorno

- `APP_PORT`: Puerto de la aplicación (default: 5000)
- `ASPNETCORE_ENVIRONMENT`: Entorno de .NET Core (Development/PreProduction/Production)

### Variables de Ansible

Ver `ansible/group_vars/` para la configuración específica de cada entorno.

## 📝 Git Flow

Los commits siguen el siguiente formato:
- `feat:` para nuevas funcionalidades
- `config:` para cambios de configuración
- `fix:` para correcciones de bugs

## 🔍 Validación

Antes de hacer commit, asegúrate de:

1. ✅ Validar docker-compose: `docker-compose config`
2. ✅ Validar sintaxis de Ansible: `ansible-playbook --syntax-check`
3. ✅ Verificar que el contenedor levante correctamente
