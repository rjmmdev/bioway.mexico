# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BioWay México is a Flutter-based mobile application for recycling and waste management with multiple user roles in a supply chain tracking system. The app supports both iOS and Android platforms and includes two main platforms: BioWay and ECOCE. Currently in prototype/early development stage with mock data and no backend integration.

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

# Run a specific test file
flutter test test/widget_test.dart

# Run tests with verbose output
flutter test -v
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

The application follows a feature-based folder structure with clear separation of concerns. Currently uses Flutter's built-in state management (StatefulWidget + setState) with no external state management libraries.

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
    - `planta_separacion/` - Material classification screens
    - `transformador/` - Manufacturing screens
    - `laboratorio/` - Laboratory analysis screens
    - `shared/` - Shared ECOCE components
      - `widgets/` - Reusable widgets (signature_dialog, weight_input_widget, qr_scanner_widget, etc.)
      - `utils/` - Shared utilities (material_utils, input_decorations, navigation_utils)
    
- **lib/widgets/** - Reusable UI components
  - `common/` - Shared widgets like gradient backgrounds
  - Platform-specific reusable components

- **lib/services/** - Business logic and external integrations
  - `image_service.dart` - Image handling and compression (max 50KB for DB storage)
  - Document services for file management

- **lib/utils/** - Helper functions and constants
  - `colors.dart` - Centralized color definitions (BioWayColors)

## Key Features

- **Multi-Platform Support**: 
  - BioWay: Main recycling system for collectors and recyclers
  - ECOCE: Traceability system with 6 provider types (Acopiador, Planta de Separación, Reciclador, Transformador, Transportista, Laboratorio)

- **QR Code Management**: 
  - Scanning (`mobile_scanner`) for lot tracking
  - Generation (`qr_flutter`) for lot identification
  - Shared scanner widget for consistency

- **Document Management**: 
  - File upload/download (`file_picker`, `open_file`)
  - Multi-file selection support
  - Shared document upload widget

- **Photo Evidence**: 
  - Camera/gallery integration (`image_picker`)
  - Image compression (`flutter_image_compress`) - max 50KB for DB storage
  - Gallery saving (`gal`)

- **Permissions**: 
  - Comprehensive permission handling (`permission_handler`)
  - Camera, storage, and location permissions

- **Material Tracking**: 
  - Lot/batch management system
  - Material type selection (PET, HDPE, PP, etc.)
  - Weight and quantity tracking
  - Color-coded material system

## Navigation Flow

1. **Splash Screen** → Platform Selector
2. **Platform Selector** → BioWay Login or ECOCE Login
3. **ECOCE Login** → Provider Type Selector → Registration → Role-specific Dashboard
4. **BioWay Login** → Registration → Dashboard

Key named routes in `main.dart`:
- **Origen (Acopiador)**:
  - `/origen_inicio` - Dashboard
  - `/origen_lotes` - Lot management
  - `/origen_crear_lote` - Create new lot
  - `/origen_ayuda` - Help screen
  - `/origen_perfil` - Profile
- **Reciclador**:
  - `/reciclador_inicio` - Dashboard
  - `/reciclador_lotes` - Lot administration
  - `/reciclador_escaneo` - QR scanner
  - `/reciclador_ayuda` - Help
  - `/reciclador_perfil` - Profile
- **Transporte**:
  - `/transporte_inicio` - Scanner screen (entry point)
  - `/transporte_recoger` - Pickup form
  - `/transporte_entregar` - Delivery
  - `/transporte_ayuda` - Help
  - `/transporte_perfil` - Profile
- **Laboratorio**:
  - `/laboratorio_inicio` - Dashboard
  - `/laboratorio_muestras` - Sample management
  - `/laboratorio_registro` - Sample registration
  - `/laboratorio_analisis` - Analysis forms

## Firebase Integration

Firebase is configured with:
- Firebase Analytics for tracking
- Google Services JSON in `android/app/google-services.json`
- Firebase project ID: `trazabilidad-ecoce`
- Multidex enabled for Android
- Firebase BoM version: 33.6.0
- Mock Firebase IDs format: 'FID_1x7h9k3' (for demo data)

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

## State Management

- Uses Flutter's built-in StatefulWidget + setState()
- No external state management library (Provider, Riverpod, Bloc, etc.)
- Each screen manages its own local state
- Data passed between screens via constructor parameters
- Configuration stored in classes like `OrigenUserConfig`
- Shared navigation utility: `NavigationUtils.navigateWithFade()` for consistent transitions

## Development Notes

- Flutter SDK: ^3.8.1
- Dart SDK: Compatible with Flutter version
- Package name: `com.biowaymexico.app`
- Min SDK: Android 21 (Lollipop)
- Target SDK: Android 34 (API 34)
- Material Design 3 theming implemented
- Portrait-only orientation locked in main()
- SVG support via `flutter_svg` for scalable graphics
- Comprehensive permission handling for camera, storage access
- Screenshot and sharing capabilities via `screenshot` and `share_plus`
- Print functionality support via `printing`
- Gallery saving functionality for images/videos via `gal`
- No backend integration - currently uses mock/hardcoded data

## Performance Optimization Guidelines

- Use const constructors wherever possible
- Implement caching for expensive operations (e.g., InputDecoration cache)
- Use adaptive sizing with MediaQuery percentages instead of fixed pixels
- Minimize widget rebuilds by checking state changes before setState()
- Prefer ClampingScrollPhysics for better scroll performance
- Set resizeToAvoidBottomInset: false to avoid keyboard animation issues
- Image compression: Automatically compress images to max 50KB for database storage
- Use FittedBox and Flexible widgets for responsive text scaling

## Responsive Design Patterns

- All sizing should use MediaQuery-based calculations:
  - Padding: `screenWidth * 0.03` (3% of screen width)
  - Border radius: `screenWidth * 0.02-0.04`
  - Font sizes: `screenWidth * 0.035-0.05`
- Check for tablet vs phone: `screenWidth > 600`
- Check for small screens: `screenWidth < 360`
- Check for compact height: `screenHeight < 700`
- Use percentage-based sizing for dialogs and modals
- Bottom navigation adapts height based on screen size and system padding

## Code Style

- Follow Flutter's official style guide
- Use meaningful variable and function names
- Group related widgets in shared/widgets folder
- Extract reusable components (e.g., SectionCard, FieldLabel)
- Use const for static lists and data
- Implement proper error handling
- Add appropriate comments for complex logic
- Mock data patterns: Use Firebase ID format (e.g., 'FID_1x7h9k3') for consistency
- Color usage: Always use BioWayColors constants, never hardcode colors