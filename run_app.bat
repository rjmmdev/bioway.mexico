@echo off
echo Cleaning Flutter project...
call flutter clean

echo Getting dependencies...
call flutter pub get

echo Running app on emulator...
call flutter run -d emulator-5554

pause