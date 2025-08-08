@echo off
echo ====================================
echo Limpiando y reconstruyendo proyecto
echo ====================================
echo.

echo Limpiando cache de Flutter...
flutter clean

echo.
echo Limpiando cache de Gradle...
cd android
call gradlew clean
cd ..

echo.
echo Obteniendo dependencias...
flutter pub get

echo.
echo Construyendo APK Release...
flutter build apk --release

echo.
echo ====================================
echo Proceso completado!
echo ====================================
echo.
echo Si el APK se genero correctamente, lo encontraras en:
echo build\app\outputs\flutter-apk\app-release.apk
echo.
pause