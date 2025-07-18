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

# Run a specific test file
flutter test test/widget_test.dart

# Hot reload (while app is running)
r

# Hot restart (while app is running)
R
```

### Building
```bash
# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release

# Build app bundle for Play Store
flutter build appbundle

# Build iOS (macOS only)
flutter build ios

# Build with specific flavor
flutter build apk --flavor production --release
```

### Testing
```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run a specific test
flutter test test/specific_test.dart

# Run tests in watch mode
flutter test --reporter expanded
```

### Code Quality
```bash
# Analyze code
flutter analyze

# Format code
dart format .

# Format specific file
dart format lib/screens/example.dart

# Check for outdated dependencies
flutter pub outdated
```

## Architecture

### Navigation Architecture
The app uses **named routes** with custom page transitions:
- Routes pattern: `/{user_type}_{screen}` (e.g., `/origen_inicio`, `/reciclador_lotes`)
- Custom `NavigationHelper` provides three transition types:
  - `navigateWithSlideTransition` - Horizontal slide (most common)
  - `navigateWithFadeTransition` - Fade effect
  - `navigateWithReplacement` - Replace current route

### State Management
Currently uses **StatefulWidget** with local state management:
- Data flows top-down via constructor parameters
- Bottom-up communication via callbacks
- No external state management library (consider adding Provider/Riverpod for complex flows)

### Project Structure
```
lib/
├── screens/
│   ├── bioway/                 # BioWay platform screens
│   └── ecoce/                  # ECOCE platform screens
│       ├── shared/             # Shared components and utilities
│       │   ├── widgets/        # Reusable UI components
│       │   └── utils/          # Shared utilities
│       ├── origen/             # Origin collector user (Acopiador)
│       ├── reciclador/         # Recycler user
│       ├── transporte/         # Transport user
│       ├── cadena_suministro/  # Supply chain user
│       ├── autoridad/          # Authority user
│       └── laboratorio/        # Laboratory user
├── services/                   # Business logic and external integrations
├── utils/                      # Global utilities and constants
└── widgets/                    # Global reusable components
```

### Key Patterns

**Widget Composition Pattern**:
- Screens typically follow: SafeArea → Column/Stack → [Header, Content, Navigation]
- Heavy use of gradient backgrounds and shadow effects
- Consistent border radius (12-20px) and spacing

**Service Layer Pattern**:
- Services use static methods for utilities
- Key services: `ImageService`, `DocumentPickerService`
- All async operations with proper error handling

**Bottom Navigation Pattern**:
- Each user role has dedicated `{UserType}BottomNavigation` widget
- Consistent structure: 4 tabs + central FAB
- Navigation state managed locally in each screen

**Data Handling**:
- Currently using `Map<String, dynamic>` for data models
- Mock data hardcoded in screens (no backend integration yet)
- Consider implementing proper model classes

## Key Features

### QR Code Management
- **Scanning**: `mobile_scanner` package with custom UI overlay
- **Generation**: `qr_flutter` for creating QR codes
- Pattern: Scan → Register → Manage flow

### Document Management
- **File Picker**: `file_picker` for document selection
- **Preview**: `open_file` for viewing documents
- Supports PDF, images, and common document formats

### Photo Evidence
- **Camera/Gallery**: `image_picker` with permission handling
- **Compression**: `flutter_image_compress` for optimizing images
- Custom UI for photo grid display

### Material Tracking
- Lot/batch management system
- Material types: PEBD, PP, Multilaminado
- Weight tracking and aggregation

## User Roles and Navigation

### ECOCE Platform Users
1. **Origen/Acopiador** (Origin Collector)
   - Create and manage material lots
   - FAB: Create new lot
   
2. **Reciclador** (Recycler)
   - Scan and process lots
   - FAB: Scan QR code
   
3. **Transporte** (Transport)
   - Pick up and deliver materials
   - No FAB (action buttons in content)
   
4. **Laboratorio** (Laboratory)
   - Analyze material samples
   - FAB: Add new sample

## Color System

Centralized in `BioWayColors` class:
- Primary: `ecoceGreen` (#4CAF50)
- Material colors: `pebdPink`, `ppPurple`, `multilaminadoBrown`
- Status colors: `success`, `error`, `warning`, `info`
- Gradients defined for headers and cards

## Firebase Integration

- Firebase Analytics for tracking
- Configuration files in `android/app/google-services.json`
- Multidex enabled for Android

## Development Notes

- **Flutter SDK**: ^3.8.1
- **Material Design 3** theming
- **SVG Support** via `flutter_svg`
- **Permissions**: Camera, storage access handled via `permission_handler`
- **Platform-specific**: Different UI patterns for iOS/Android where needed
- **Haptic Feedback**: Used throughout for better UX