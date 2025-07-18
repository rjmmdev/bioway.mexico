@echo off
echo Configurando Firebase para el proyecto ECOCE...
echo.

REM Ejecutar FlutterFire configure para ECOCE
echo Configurando proyecto ECOCE...
dart pub global run flutterfire_cli:flutterfire configure --project=trazabilidad-ecoce --platforms=android --android-package-name=com.biowaymexico.app

echo.
echo Configurando proyecto BioWay...
dart pub global run flutterfire_cli:flutterfire configure --project=bioway-directory --platforms=android --android-package-name=com.biowaymexico.app

echo.
echo Configuracion completada!
echo.
echo Proximos pasos:
echo 1. Descargar google-services.json de Firebase Console
echo 2. Colocar el archivo en android/app/
echo 3. Actualizar firebase_config.dart con las credenciales
echo.
pause