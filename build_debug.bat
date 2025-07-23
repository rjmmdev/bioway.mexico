@echo off
echo Building debug APK...
flutter clean
flutter pub get
flutter build apk --debug
echo Build complete!
pause