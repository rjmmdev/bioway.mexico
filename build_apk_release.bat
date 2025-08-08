@echo off
echo ========================================
echo   Construyendo APK Release
echo   Java version: 17 (compatible con 24)
echo ========================================
echo.

echo [1/5] Limpiando cache de Flutter...
call flutter clean
if %errorlevel% neq 0 (
    echo ERROR: No se pudo limpiar el cache de Flutter
    pause
    exit /b 1
)

echo.
echo [2/5] Limpiando build de Android...
cd android
if exist .gradle (
    echo Eliminando carpeta .gradle...
    rmdir /s /q .gradle
)
if exist build (
    echo Eliminando carpeta build...
    rmdir /s /q build
)
if exist app\build (
    echo Eliminando carpeta app\build...
    rmdir /s /q app\build
)
cd ..

echo.
echo [3/5] Eliminando archivos de lock...
if exist pubspec.lock del pubspec.lock
if exist android\.gradle\*.lock del android\.gradle\*.lock /s /q 2>nul

echo.
echo [4/5] Obteniendo dependencias...
call flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: No se pudieron obtener las dependencias
    pause
    exit /b 1
)

echo.
echo [5/5] Construyendo APK Release...
echo Esto puede tomar varios minutos...
call flutter build apk --release --verbose
if %errorlevel% neq 0 (
    echo.
    echo ========================================
    echo   ERROR: La construccion fallo
    echo ========================================
    echo.
    echo Posibles soluciones:
    echo 1. Verifica que Java este instalado correctamente
    echo 2. Intenta: flutter doctor -v
    echo 3. Intenta: cd android ^&^& gradlew clean
    pause
    exit /b 1
)

echo.
echo ========================================
echo   APK construido exitosamente!
echo ========================================
echo.
echo Ubicacion del APK:
echo build\app\outputs\flutter-apk\app-release.apk
echo.
echo Tamaño del APK:
dir build\app\outputs\flutter-apk\app-release.apk | findstr /i apk
echo.
pause