# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BioWay México is a Flutter-based mobile application for recycling and waste management in Mexico. The app connects different stakeholders in the recycling ecosystem (recyclers, laboratories, transporters, collectors, etc.) and provides material traceability.

## Key Technologies

- **Flutter SDK**: ^3.8.1 (Dart)
- **Firebase**: Integration for backend services
- **Platforms**: iOS, Android, Web support
- **QR Code Scanning**: For batch/lot tracking

## Development Commands

### Running the App
```bash
flutter run                  # Run in debug mode
flutter run --release        # Run in release mode
flutter run -d <device_id>   # Run on specific device
flutter devices              # List available devices
```

### Building
```bash
flutter build apk           # Build Android APK
flutter build appbundle     # Build Android App Bundle
flutter build ios           # Build iOS (macOS required)
flutter build web           # Build for web
```

### Testing and Code Quality
```bash
flutter test                # Run all tests
flutter test --coverage     # Run tests with coverage
flutter analyze             # Analyze code for issues
dart fix --apply           # Fix auto-fixable issues
dart format .              # Format code
```

### Dependency Management
```bash
flutter pub get            # Get dependencies
flutter pub upgrade        # Upgrade dependencies
flutter clean             # Clean build cache
```

## Architecture

The app follows a multi-platform architecture supporting two main systems:

### 1. BioWay Platform
- Provider management and recycler functionality
- Material batch registration and tracking

### 2. ECOCE Platform
- Traceability system for recyclable materials
- Support for multiple user types:
  - Reciclador (Recycler)
  - Acopiador (Collector)
  - Laboratorio (Laboratory)
  - Planta de Separación (Separation Plant)
  - Transformador (Transformer)
  - Transportista (Transporter)

### Project Structure
```
lib/
├── main.dart                    # App entry point
├── screens/
│   ├── splash_screen.dart       # Initial splash screen
│   ├── login/
│   │   ├── platform_selector_screen.dart  # Platform selection (BioWay/ECOCE)
│   │   ├── bioway/             # BioWay login/registration
│   │   └── ecoce/              # ECOCE login/registration
│   └── ecoce/
│       └── reciclador/         # Recycler-specific screens
│           ├── inicio_reciclador.dart
│           ├── escaner_reciclador.dart
│           └── registro_lote_reciclador.dart
├── utils/
│   └── colors.dart             # App color constants
└── widgets/
    ├── common/                 # Shared widgets
    └── login/                  # Login-specific widgets
```

### Key Features

1. **QR Code Scanning**: Integrated scanner for tracking material batches
2. **Material Types**: Support for PET, HDPE, PP, and other recyclable materials
3. **Batch Registration**: Weight tracking and lot management
4. **User Authentication**: Separate flows for different user types
5. **Gradient UI**: Green-based sustainability theme

### Important Notes

- The app is portrait-only orientation
- Firebase integration requires `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
- Current development branch: `usuario_reciclador` - implementing recycler user features
- QR scanner requires camera permissions

## Common Development Tasks

### Adding a New Screen
1. Create the screen file in appropriate directory under `lib/screens/`
2. Follow existing naming conventions (e.g., `nombre_tipo_usuario.dart`)
3. Use existing widgets from `lib/widgets/common/` for consistency

### Working with User Types
Each user type has its own directory under `lib/screens/ecoce/` with specific functionality. Follow the existing pattern when adding new features.

### UI Guidelines
- Use colors from `lib/utils/colors.dart`
- Maintain green gradient theme for sustainability branding
- Follow Material Design 3 principles
- Keep portrait orientation