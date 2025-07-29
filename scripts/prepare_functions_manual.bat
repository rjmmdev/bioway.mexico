@echo off
echo ========================================
echo   Preparando Cloud Functions Manualmente
echo ========================================
echo.

:: Cambiar al directorio de funciones
cd functions

:: Verificar si node_modules existe
if not exist node_modules (
    echo Instalando dependencias...
    call npm install
    if errorlevel 1 (
        echo ERROR: Fallo la instalacion de dependencias
        exit /b 1
    )
)

:: Verificar que index.js existe
if not exist index.js (
    echo ERROR: index.js no encontrado
    exit /b 1
)

:: Probar que las funciones cargan correctamente
echo.
echo Verificando que las funciones cargan correctamente...
node -e "try { require('./index.js'); console.log('✓ Funciones cargadas exitosamente'); } catch(e) { console.error('✗ Error cargando funciones:', e.message); process.exit(1); }"

if errorlevel 1 (
    echo ERROR: Las funciones no cargan correctamente
    exit /b 1
)

:: Volver al directorio raíz
cd ..

echo.
echo ========================================
echo   Funciones preparadas correctamente
echo ========================================
echo.
echo Para continuar con el despliegue manual:
echo.
echo 1. Ve a Firebase Console:
echo    https://console.firebase.google.com/project/trazabilidad-ecoce/functions
echo.
echo 2. Habilita las APIs requeridas si es necesario:
echo    - Cloud Functions API
echo    - Cloud Build API
echo    - Artifact Registry API
echo    - Cloud Scheduler API
echo.
echo 3. Intenta el despliegue desde otro entorno:
echo    - WSL (Windows Subsystem for Linux)
echo    - Otra máquina sin Git Bash
echo    - Cloud Shell: https://console.cloud.google.com/cloudshell
echo.
echo 4. Si usas Cloud Shell, ejecuta:
echo    git clone [tu-repositorio]
echo    cd [directorio-del-proyecto]
echo    firebase deploy --only functions
echo.
pause