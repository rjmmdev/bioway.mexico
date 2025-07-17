# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BioWay México is a Flutter-based mobile application for recycling and waste management with multiple user roles in a supply chain tracking system. The app supports both iOS and Android platforms and includes two main platforms: BioWay and ECOCE.

## Commands

### Development
```bash
# Clean and get dependencies
flutter clean && flutter pub get

# Run on Android emulator
flutter run -d emulator-5554

# Run on any connected device
flutter run

# Run with verbose output
flutter run -v
```

### Building
```bash
# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release

# Build iOS (macOS only)
flutter build ios
```

### Testing
```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage
```

### Code Quality
```bash
# Analyze code
flutter analyze

# Format code
dart format .
```

## Architecture

The application follows Clean Architecture with clear separation of concerns:

- **screens/** - UI screens organized by feature modules:
  - `bioway/` - BioWay platform screens
  - `ecoce/` - ECOCE platform screens with different user types:
    - `usuario_acopiador_origen/` - Origin collector user
    - `usuario_reciclador/` - Recycler user
    - `usuario_transporte/` - Transport user
    - `usuario_cadena_suministro/` - Supply chain user
    - `usuario_autoridad/` - Authority user
    
- **widgets/** - Reusable UI components shared across modules

- **services/** - Business logic and external integrations

- **utils/** - Helper functions and constants

## Key Features

- **QR Code Management**: Scanning (`mobile_scanner`) and generation (`qr_flutter`)
- **Document Management**: File upload/download (`file_picker`, `open_file`)
- **Photo Evidence**: Camera/gallery integration (`image_picker`, `flutter_image_compress`)
- **Material Tracking**: Lot/batch management system
- **Multi-role Support**: Different interfaces for various supply chain participants

## Navigation

The app uses named routes defined in `main.dart`. Key routes include:
- `/` - Splash screen
- `/bioway_login` - BioWay platform login
- `/ecoce_login` - ECOCE platform login
- User-specific dashboards for each role

## Firebase Integration

Firebase is configured with:
- Firebase Analytics for tracking
- Google Services JSON in `android/app/`
- Multidex enabled for Android

## Development Notes

- Flutter SDK: ^3.8.1
- Material Design 3 theming implemented
- SVG support for scalable graphics
- Permission handling for camera, storage access
- Screenshot and sharing capabilities
- Print functionality support