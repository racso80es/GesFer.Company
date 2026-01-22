# Script de validación para GesFer.Company (PowerShell)

Write-Host "🔍 Validando infraestructura..." -ForegroundColor Cyan

# Validar docker-compose.yml
Write-Host "📦 Validando docker-compose.yml..." -ForegroundColor Yellow
docker-compose config | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ docker-compose.yml es válido" -ForegroundColor Green
} else {
    Write-Host "❌ Error en docker-compose.yml" -ForegroundColor Red
    exit 1
}

# Validar sintaxis de playbooks de Ansible (si está instalado)
if (Get-Command ansible-playbook -ErrorAction SilentlyContinue) {
    Write-Host "📋 Validando playbooks de Ansible..." -ForegroundColor Yellow
    Push-Location ansible
    
    Write-Host "  - Validando deploy.yml..." -ForegroundColor Gray
    ansible-playbook --syntax-check -i inventory/development.yml playbooks/deploy.yml
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ deploy.yml es válido" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Error en deploy.yml" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    
    Write-Host "  - Validando rollback.yml..." -ForegroundColor Gray
    ansible-playbook --syntax-check -i inventory/development.yml playbooks/rollback.yml
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ rollback.yml es válido" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Error en rollback.yml" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    
    Pop-Location
} else {
    Write-Host "⚠️  Ansible no está instalado. Saltando validación de playbooks." -ForegroundColor Yellow
    Write-Host "   Para instalar: pip install ansible" -ForegroundColor Gray
}

Write-Host ""
Write-Host "✅ Todas las validaciones pasaron correctamente" -ForegroundColor Green
