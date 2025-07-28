@echo off
echo.
echo ========================================
echo   Desplegando Cloud Functions
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

REM Cambiar al directorio de funciones
cd functions

REM Verificar si node_modules existe
if not exist node_modules (
    echo Instalando dependencias...
    npm install
    if %ERRORLEVEL% NEQ 0 (
        echo ERROR: Fallo la instalación de dependencias
        pause
        exit /b 1
    )
)

REM Volver al directorio raíz
cd ..

REM Seleccionar el proyecto
echo.
echo Configurando proyecto Firebase...
firebase use trazabilidad-ecoce

echo.
echo Desplegando Cloud Functions...
firebase deploy --only functions

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo   ✅ Funciones desplegadas exitosamente
    echo ========================================
    echo.
    echo Puedes ver los logs con: firebase functions:log
    echo.
) else (
    echo.
    echo ========================================
    echo   ❌ Error al desplegar funciones
    echo ========================================
    echo.
    echo Revisa los errores arriba e intenta nuevamente.
    echo.
)

pause