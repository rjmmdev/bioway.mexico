# Script para arreglar permisos de Gradle y compilar el proyecto

Write-Host "=== Arreglando permisos de Gradle ===" -ForegroundColor Green

# Cambiar al directorio del proyecto
Set-Location -Path $PSScriptRoot

# Verificar si existe el archivo gradlew
$gradlewPath = ".\android\gradlew.bat"
if (Test-Path $gradlewPath) {
    Write-Host "✓ gradlew.bat encontrado" -ForegroundColor Green
    
    # Dar permisos de ejecución
    Write-Host "Configurando permisos..." -ForegroundColor Yellow
    icacls $gradlewPath /grant "$env:USERNAME:F"
} else {
    Write-Host "✗ gradlew.bat no encontrado" -ForegroundColor Red
    exit 1
}

# Limpiar el proyecto
Write-Host "`n=== Limpiando el proyecto ===" -ForegroundColor Green
flutter clean

# Obtener dependencias
Write-Host "`n=== Obteniendo dependencias ===" -ForegroundColor Green
flutter pub get

# Intentar compilar usando Flutter directamente
Write-Host "`n=== Compilando con Flutter ===" -ForegroundColor Green
flutter build apk --debug

# Si falla, intentar con gradle directamente
if ($LASTEXITCODE -ne 0) {
    Write-Host "`n=== Intentando con Gradle directamente ===" -ForegroundColor Yellow
    Set-Location -Path ".\android"
    .\gradlew.bat assembleDebug
    Set-Location -Path ".."
}

Write-Host "`n=== Proceso completado ===" -ForegroundColor Green