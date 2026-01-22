#!/bin/bash
# Script de validación para GesFer.Company

set -e

echo "🔍 Validando infraestructura..."

# Validar docker-compose.yml
echo "📦 Validando docker-compose.yml..."
docker-compose config > /dev/null
echo "✅ docker-compose.yml es válido"

# Validar sintaxis de playbooks de Ansible (si está instalado)
if command -v ansible-playbook &> /dev/null; then
    echo "📋 Validando playbooks de Ansible..."
    cd ansible
    
    echo "  - Validando deploy.yml..."
    ansible-playbook --syntax-check -i inventory/development.yml playbooks/deploy.yml
    echo "  ✅ deploy.yml es válido"
    
    echo "  - Validando rollback.yml..."
    ansible-playbook --syntax-check -i inventory/development.yml playbooks/rollback.yml
    echo "  ✅ rollback.yml es válido"
    
    cd ..
else
    echo "⚠️  Ansible no está instalado. Saltando validación de playbooks."
    echo "   Para instalar: pip install ansible"
fi

echo ""
echo "✅ Todas las validaciones pasaron correctamente"
