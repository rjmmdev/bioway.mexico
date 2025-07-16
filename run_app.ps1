# PowerShell script para ejecutar la aplicación Flutter
Write-Host "Limpiando el proyecto Flutter..." -ForegroundColor Green
flutter clean

Write-Host "`nObteniendo dependencias..." -ForegroundColor Green
flutter pub get

Write-Host "`nEjecutando la aplicación en el emulador..." -ForegroundColor Green
flutter run -d emulator-5554

Write-Host "`nPresiona cualquier tecla para continuar..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")