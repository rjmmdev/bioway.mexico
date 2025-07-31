@echo off
echo.
echo ========================================
echo   Desplegando configuración de Firebase
echo ========================================
echo.

REM Verificar si Firebase CLI está instalado
where firebase >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Firebase CLI no está instalado.
    echo Por favor instala Firebase CLI ejecutando: npm install -g firebase-tools
    echo.
    pause
    exit /b 1
)

REM Seleccionar el proyecto
echo Configurando proyecto Firebase...
firebase use trazabilidad-ecoce

echo.
echo Desplegando reglas de Firestore...
firebase deploy --only firestore:rules

echo.
echo Desplegando índices de Firestore...
firebase deploy --only firestore:indexes

echo.
echo Desplegando reglas de Storage...
firebase deploy --only storage

echo.
echo ========================================
echo   Despliegue completado
echo ========================================
echo.
echo IMPORTANTE: Los índices pueden tardar unos minutos en estar disponibles.
echo.
pause