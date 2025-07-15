# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BioWay México is a Flutter-based mobile application for recycling and waste management, supporting two platforms: BioWay and ECOCE. The app focuses on material recycling (PET, HDPE, PP) with a comprehensive provider registration system.

## Essential Commands

### Development
```bash
# Install dependencies
flutter pub get

# Run the app (auto-selects connected device)
flutter run

# Run on specific platform
flutter run -d chrome     # Web browser
flutter run -d emulator   # Android emulator
flutter run -d iPhone     # iOS simulator

# Code analysis and linting
flutter analyze

# Run tests
flutter test
```

### Building
```bash
# Android
flutter build apk --release          # APK file
flutter build appbundle --release    # Google Play bundle

# iOS (requires macOS)
flutter build ios --release

# Web
flutter build web
```

## Project Architecture

### Directory Structure
- `lib/screens/` - UI screens organized by feature/platform
  - `login/` - Authentication flows for BioWay and ECOCE
  - `ecoce/` - ECOCE-specific feature modules (laboratorio, reciclador, etc.)
- `lib/widgets/` - Reusable UI components
- `lib/utils/` - Utilities (colors.dart contains comprehensive theme colors)

### Key Architectural Patterns
1. **Dual Platform Support**: Separate flows for BioWay and ECOCE platforms accessed via `platform_selector_screen.dart`
2. **Provider Types**: Six different provider registration types (Acopiador, Laboratorio, Planta Separación, Reciclador, Transformador, Transportista)
3. **Animation-Heavy UI**: Complex animations in splash screen using AnimationController
4. **Theme Management**: Centralized Material Design 3 theming in main.dart
5. **Navigation**: Custom PageRouteBuilder transitions between screens

### Firebase Integration
- Android configuration present (`google-services.json`)
- Firebase Analytics enabled
- Multidex support enabled for Android

## Important Development Notes

1. **State Management**: Currently using StatefulWidget pattern. No state management library (Provider, Riverpod, Bloc) is implemented yet.

2. **Color System**: Comprehensive color palette defined in `lib/utils/colors.dart` with 23 predefined colors for consistent theming.

3. **Platform-Specific Code**:
   - Android package: `com.biowaymexico.app`
   - iOS bundle identifier uses `$(PRODUCT_BUNDLE_IDENTIFIER)`

4. **Current Development Branch**: Work is being done on `raul_usuarios` branch focusing on user registration functionality.

5. **Testing**: Basic widget tests exist for splash screen. Test files should verify UI elements and user flows.

## Code Style Guidelines

- Follow Flutter lints (flutter_lints package is configured)
- Use consistent naming: `snake_case` for files, `camelCase` for variables
- Widgets should be extracted into separate files in `lib/widgets/` when reusable
- Screen files should be organized by feature in `lib/screens/`