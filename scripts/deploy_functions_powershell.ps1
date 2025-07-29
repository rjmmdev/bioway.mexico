# Script de PowerShell para desplegar Cloud Functions

Write-Host "========================================"
Write-Host "  Desplegando Cloud Functions"
Write-Host "========================================"
Write-Host ""

# Cambiar al directorio del proyecto
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

# Verificar si Firebase CLI está instalado
try {
    $version = firebase --version
    Write-Host "Firebase CLI version: $version"
} catch {
    Write-Host "ERROR: Firebase CLI no está instalado."
    Write-Host "Por favor instala Firebase CLI ejecutando: npm install -g firebase-tools"
    exit 1
}

# Cambiar al directorio de funciones
Set-Location functions

# Verificar si node_modules existe
if (-not (Test-Path "node_modules")) {
    Write-Host "Instalando dependencias..."
    npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Fallo la instalación de dependencias"
        exit 1
    }
}

# Volver al directorio raíz
Set-Location ..

# Configurar el proyecto
Write-Host ""
Write-Host "Configurando proyecto Firebase..."
firebase use trazabilidad-ecoce

# Habilitar APIs necesarias
Write-Host ""
Write-Host "Habilitando APIs necesarias..."
Write-Host "Esto puede tomar unos minutos la primera vez..."

# Intentar habilitar las APIs manualmente
$apis = @(
    "cloudfunctions.googleapis.com",
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudscheduler.googleapis.com"
)

Write-Host ""
Write-Host "IMPORTANTE: Si el deploy falla, habilita manualmente estas APIs en:"
Write-Host "https://console.cloud.google.com/apis/library?project=trazabilidad-ecoce"
Write-Host ""
foreach ($api in $apis) {
    Write-Host "  - $api"
}

# Desplegar funciones
Write-Host ""
Write-Host "Desplegando Cloud Functions..."
Write-Host "NOTA: Si es la primera vez, puede tomar varios minutos..."
Write-Host ""

# Usar cmd para evitar problemas con bash
cmd /c "firebase deploy --only functions"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================"
    Write-Host "  ✅ Funciones desplegadas exitosamente"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "Puedes ver los logs con: firebase functions:log"
    Write-Host ""
    Write-Host "URLs de las funciones:"
    Write-Host "  - healthCheck: https://us-central1-trazabilidad-ecoce.cloudfunctions.net/healthCheck"
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "========================================"
    Write-Host "  ❌ Error al desplegar funciones"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "Si el error es por APIs no habilitadas:"
    Write-Host "1. Ve a https://console.cloud.google.com/apis/library?project=trazabilidad-ecoce"
    Write-Host "2. Busca y habilita cada API listada arriba"
    Write-Host "3. Ejecuta este script nuevamente"
    Write-Host ""
}

Write-Host "Presiona cualquier tecla para continuar..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")