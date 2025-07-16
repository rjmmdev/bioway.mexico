# Script para compilar la aplicación Flutter
Write-Host "Compilando aplicación Flutter..." -ForegroundColor Green

# Verificar que Flutter está instalado
if (!(Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "Error: Flutter no está instalado o no está en el PATH" -ForegroundColor Red
    exit 1
}

# Limpiar caché
Write-Host "Limpiando caché..." -ForegroundColor Yellow
flutter clean

# Obtener dependencias
Write-Host "Obteniendo dependencias..." -ForegroundColor Yellow
flutter pub get

# Compilar para Android
Write-Host "Compilando APK debug..." -ForegroundColor Yellow
flutter build apk --debug

if ($LASTEXITCODE -eq 0) {
    Write-Host "Compilación exitosa!" -ForegroundColor Green
    Write-Host "APK ubicado en: build\app\outputs\flutter-apk\app-debug.apk" -ForegroundColor Cyan
} else {
    Write-Host "Error en la compilación" -ForegroundColor Red
    exit 1
}