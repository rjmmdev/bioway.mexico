@echo off
echo Fixing build issues...

echo Step 1: Cleaning build directories...
rd /s /q build 2>nul
rd /s /q .dart_tool 2>nul
rd /s /q android\.gradle 2>nul
rd /s /q android\app\build 2>nul

echo Step 2: Getting Flutter dependencies...
call flutter pub get

echo Step 3: Building APK with SDK 24...
call flutter build apk --debug

echo Build process complete!
pause