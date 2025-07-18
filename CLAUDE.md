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

### Convenience Scripts
```bash
# PowerShell script for building debug APK
./build_debug.ps1

# PowerShell script for clean, get dependencies, and run
./run_app.ps1

# Batch file alternatives
./compile_debug.bat  # Run on emulator
./run_app.bat       # Clean, get dependencies, and run
```

## Architecture

The application follows Clean Architecture with clear separation of concerns:

- **lib/screens/** - UI screens organized by feature modules:
  - `splash_screen.dart` - Initial splash screen
  - `login/` - Authentication screens
    - `platform_selector_screen.dart` - Main platform selection (BioWay/ECOCE)
    - `bioway/` - BioWay login and registration
    - `ecoce/` - ECOCE login and provider selection
      - `providers/` - Registration screens for each provider type
  - `ecoce/` - ECOCE platform screens by user role:
    - `origen/` - Origin collector (Acopiador) screens
    - `reciclador/` - Recycler screens with lot management
    - `transporte/` - Transport screens for pickup/delivery
    - `shared/` - Shared ECOCE components
    
- **lib/widgets/** - Reusable UI components
  - `common/` - Shared widgets like gradient backgrounds
  - Platform-specific reusable components

- **lib/services/** - Business logic and external integrations
  - `image_service.dart` - Image handling and compression
  - Document services for file management

- **lib/utils/** - Helper functions and constants
  - `colors.dart` - Centralized color definitions (BioWayColors)
  - `optimized_navigation.dart` - Navigation utilities

## Key Features

- **Multi-Platform Support**: 
  - BioWay: Main recycling system for collectors and recyclers
  - ECOCE: Traceability system with 6 provider types (Acopiador, Planta de Separación, Reciclador, Transformador, Transportista, Laboratorio)

- **QR Code Management**: 
  - Scanning (`mobile_scanner`) for lot tracking
  - Generation (`qr_flutter`) for lot identification

- **Document Management**: 
  - File upload/download (`file_picker`, `open_file`)
  - Multi-file selection support

- **Photo Evidence**: 
  - Camera/gallery integration (`image_picker`)
  - Image compression (`flutter_image_compress`)
  - Gallery saving (`gal`)

- **Permissions**: 
  - Comprehensive permission handling (`permission_handler`)
  - Camera, storage, and location permissions

- **Material Tracking**: 
  - Lot/batch management system
  - Material type selection (PET, HDPE, PP, etc.)
  - Weight and quantity tracking

## Navigation Flow

1. **Splash Screen** → Platform Selector
2. **Platform Selector** → BioWay Login or ECOCE Login
3. **ECOCE Login** → Provider Type Selector → Registration → Role-specific Dashboard
4. **BioWay Login** → Registration → Dashboard

Key named routes in `main.dart`:
- `/` - Splash screen
- `/origen_inicio` - Origin collector dashboard
- `/reciclador_inicio` - Recycler dashboard  
- `/transporte_inicio` - Transport dashboard
- Additional routes for each role's screens

## Firebase Integration

Firebase is configured with:
- Firebase Analytics for tracking
- Google Services JSON in `android/app/google-services.json`
- Firebase project ID: `trazabilidad-ecoce`
- Multidex enabled for Android
- Firebase BoM version: 33.6.0

## ECOCE Provider Types

The ECOCE platform supports 6 provider types, each with specific roles:
- **Acopiador (A)**: Collection centers for recyclable materials
- **Planta de Separación (PS)**: Material classification and separation
- **Reciclador (R)**: Processing of recyclable materials
- **Transformador (T)**: Manufacturing with recycled materials
- **Transportista (TR)**: Logistics and material transport
- **Laboratorio (L)**: Quality analysis and certification

## Assets

The app includes the following asset structure:
- `assets/logos/` - Platform logos (bioway_logo.svg, ecoce_logo.svg)
- `assets/images/` - General images
- `assets/images/icons/` - Icon files (pacas.svg, sacos.svg)

Assets are declared in `pubspec.yaml` and loaded using Flutter's asset system.

## Development Notes

- Flutter SDK: ^3.8.1
- Dart SDK: Compatible with Flutter version
- Package name: `com.biowaymexico.app`
- Min SDK: Android 21 (Lollipop)
- Material Design 3 theming implemented
- SVG support via `flutter_svg` for scalable graphics
- Comprehensive permission handling for camera, storage access
- Screenshot and sharing capabilities via `screenshot` and `share_plus`
- Print functionality support via `printing`
- Gallery saving functionality for images/videos via `gal`

## Code Style

- Follow Flutter's official style guide
- Use meaningful variable and function names
- Implement proper error handling
- Add appropriate comments for complex logic
- Use const constructors where possible for performance