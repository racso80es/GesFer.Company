# Ansible Deployment para GesFer.Company

## Estructura

```
ansible/
├── ansible.cfg              # Configuración de Ansible
├── inventory/               # Inventarios por entorno
│   ├── development.yml
│   ├── preproduction.yml
│   └── production.yml
├── group_vars/              # Variables por grupo
│   ├── all.yml
│   ├── development.yml
│   ├── preproduction.yml
│   └── production.yml
├── roles/                   # Roles de Ansible
│   ├── deploy/              # Rol de despliegue
│   └── rollback/            # Rol de rollback
├── playbooks/               # Playbooks principales
│   ├── deploy.yml
│   └── rollback.yml
└── requirements.yml         # Dependencias de Ansible
```

## Instalación

```bash
# Instalar colecciones de Ansible
ansible-galaxy collection install -r requirements.yml
```

## Uso

### Despliegue

```bash
# Development
ansible-playbook -i inventory/development.yml playbooks/deploy.yml

# Preproduction
ansible-playbook -i inventory/preproduction.yml playbooks/deploy.yml

# Production
ansible-playbook -i inventory/production.yml playbooks/deploy.yml
```

### Rollback

```bash
# Development
ansible-playbook -i inventory/development.yml playbooks/rollback.yml

# Preproduction
ansible-playbook -i inventory/preproduction.yml playbooks/rollback.yml

# Production
ansible-playbook -i inventory/production.yml playbooks/rollback.yml
```

### Validación de Sintaxis

```bash
# Validar sintaxis de playbooks
ansible-playbook --syntax-check -i inventory/development.yml playbooks/deploy.yml
ansible-playbook --syntax-check -i inventory/development.yml playbooks/rollback.yml
```

## Variables Importantes

- `deploy_user`: Usuario para ejecutar el despliegue
- `deploy_path`: Ruta donde se despliega la aplicación
- `app_port`: Puerto de la aplicación
- `aspnetcore_environment`: Entorno de .NET Core
- `keep_releases`: Número de releases a mantener
