@echo off
echo === Compilando proyecto Flutter para Android ===
echo.

REM Limpiar el proyecto
echo Limpiando proyecto...
call flutter clean

REM Obtener dependencias
echo.
echo Obteniendo dependencias...
call flutter pub get

REM Compilar APK de debug
echo.
echo Compilando APK de debug...
call flutter build apk --debug --verbose

REM Si el comando anterior falla, intentar con gradle directamente
if %errorlevel% neq 0 (
    echo.
    echo === Intentando con Gradle directamente ===
    cd android
    call gradlew.bat assembleDebug
    cd ..
)

echo.
echo === Proceso completado ===
pause