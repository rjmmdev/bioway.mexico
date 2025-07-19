# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BioWay México is a Flutter-based mobile application for recycling and waste management with dual-platform support (BioWay and ECOCE). The app implements a complete supply chain tracking system for recyclable materials with role-based access and multi-tenant Firebase architecture.

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

# Hot reload (when app is running)
r

# Hot restart (when app is running)
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

# Build with obfuscation (release)
flutter build apk --obfuscate --split-debug-info=./symbols
```

### Testing
```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/widget_test.dart

# Run tests matching pattern
flutter test --name="Login"

# Run integration tests
flutter drive --target=test_driver/app.dart
```

### Code Quality
```bash
# Analyze code for issues
flutter analyze

# Format all Dart files
dart format .

# Format specific file
dart format lib/main.dart

# Check for outdated packages
flutter pub outdated

# Upgrade packages
flutter pub upgrade
```

### Debugging
```bash
# Run with observatory debugger
flutter run --observatory-port=8888

# Run with specific build flavor
flutter run --flavor development

# Clear build cache
flutter clean && rm -rf build/

# Regenerate platform files
flutter create --platforms=android,ios .
```

## Architecture

### Multi-Tenant Firebase Setup
The app uses a sophisticated multi-tenant Firebase architecture to separate BioWay and ECOCE data:

- **FirebaseManager** (`lib/services/firebase/firebase_manager.dart`): Manages multiple Firebase app instances
- **FirebaseConfig** (`lib/services/firebase/firebase_config.dart`): Stores platform-specific Firebase configurations
- **Platform Initialization**: Each platform (BioWay/ECOCE) initializes its own Firebase instance at login
- **Data Isolation**: Complete separation between BioWay and ECOCE data

### Screen Organization
Screens follow a feature-based structure with clear separation by platform and role:

```
lib/screens/
├── splash_screen.dart              # Entry point with animation
├── platform_selector_screen.dart   # BioWay vs ECOCE selection
├── login/
│   ├── bioway/                    # BioWay authentication
│   └── ecoce/                     # ECOCE authentication
│       └── providers/             # Role-specific registration
└── ecoce/
    ├── origen/                    # Acopiador screens
    ├── reciclador/               # Recycler screens
    ├── transporte/               # Transport screens
    ├── planta_separacion/        # Separation plant screens
    ├── transformador/            # Transformer screens
    ├── laboratorio/              # Laboratory screens
    ├── maestro/                  # Master admin screens
    ├── repositorio/              # Repository screens
    └── shared/                   # Shared ECOCE components
```

### Service Layer Architecture
Services handle business logic and external integrations:

- **AuthService**: Multi-tenant authentication with platform switching
- **EcoceProfileService**: ECOCE user profile management with role-based data and solicitudes system
- **ImageService**: Image compression (max 50KB) and management
- **DocumentService**: Document upload with compression and Firebase Storage integration
- **FirebaseManager**: Centralized Firebase instance management

### Widget Reusability Pattern
Common widgets are organized for maximum reusability:

- `lib/widgets/common/`: Platform-agnostic widgets (gradients, maps, etc.)
- `lib/screens/ecoce/shared/widgets/`: ECOCE-specific shared components
- Widget naming convention: `[Feature][Type]Widget` (e.g., `LocationPickerWidget`)

## Key Features & Implementation

### User Registration & Approval Flow
1. Users fill multi-step registration form (5 steps)
2. Request saved to `solicitudes_cuentas` collection (NO Auth user created yet)
3. Maestro user reviews in unified dashboard
4. On approval: Auth user created, folio assigned, profile moved to `ecoce_profiles`
5. On rejection: Request deleted completely

### QR Code System
- **Scanner**: `QrScannerWidget` using `mobile_scanner` package
- **Generator**: `qr_flutter` for creating QR codes
- **Format**: `LOTE-[MATERIAL]-[ID]` for lot tracking

### Document Management
- **Upload**: `DocumentUploadWidget` with multi-file support
- **Compression**: Images compressed to ~100KB target, PDFs validated (5MB max)
- **Storage**: Firebase Storage organized by solicitud/user ID
- **Supported Types**: PDF, images (JPG, PNG)

### Location Services
- **No GPS Required**: Uses geocoding without device location permissions
- **Map Dialog**: `MapSelectorDialog` with fixed center pin
- **Address Search**: `SimpleMapWidget` for address-based location selection

### Material Tracking
Materials are role-specific:
- **Origen**: EPF types (Poli, PP, Multi)
- **Reciclador**: Processing states (separados, pacas, sacos)
- **Transformador**: Pellets and flakes
- **Laboratorio**: Sample types

### User Deletion (Maestro)
- Complete removal from `ecoce_profiles` and `solicitudes_cuentas`
- Storage files deleted
- Marked for Auth deletion in `users_pending_deletion` collection
- Requires Cloud Function for actual Auth removal (see `docs/CLOUD_FUNCTION_DELETE_USERS.md`)

## Navigation & Routing

### Named Routes Pattern
All routes are defined in `main.dart` following the pattern: `/[role]_[screen]`

Example flows:
- ECOCE Origen: `/origen_inicio` → `/origen_lotes` → `/origen_crear_lote`
- Transport: `/transporte_inicio` → `/transporte_recoger` → `/transporte_entregar`

### Navigation Utilities
- `NavigationUtils.navigateWithFade()`: Consistent fade transitions
- `Navigator.pushReplacementNamed()`: For login flows
- `PopScope`: For handling back button behavior

## State Management

### Current Approach
- Pure StatefulWidget + setState()
- No external state management libraries
- State passed via constructor parameters
- Form validation in widget state

### Data Flow
1. Parent widgets pass callbacks to children
2. Children call callbacks with data
3. Parent updates state and rebuilds
4. Shared state stored in route-level widgets

## Firebase Integration

### Configuration Files
- Android: `android/app/google-services.json` (contains both ECOCE and BioWay configs)
- iOS: `ios/Runner/GoogleService-Info.plist` (per platform)

### Collection Structure
```
solicitudes_cuentas/           # Account requests pending approval
├── [solicitudId]
│   ├── estado: "pendiente"/"aprobada"/"rechazada"
│   ├── datos_perfil: {...}
│   └── documentos: {...}

ecoce_profiles/                # Main user profiles (index)
├── [userId]
│   ├── path: "ecoce_profiles/[type]/usuarios/[userId]"
│   ├── folio: "A0000001"
│   └── aprobado: true

ecoce_profiles/[type]/usuarios/  # Actual profile data by type
├── origen/centro_acopio/
├── origen/planta_separacion/
├── reciclador/usuarios/
├── transformador/usuarios/
├── transporte/usuarios/
└── laboratorio/usuarios/

users_pending_deletion/        # Users marked for Auth deletion
├── [userId]
│   └── status: "pending"/"completed"/"failed"
```

### Security Rules
- Platform-based data isolation
- Role-based access control
- No cross-platform data access

## Google Maps Integration

### API Configuration
- API Key: Stored in `GoogleMapsConfig` class
- Required APIs: Maps SDK, Geocoding API
- No location permissions required

### Map Components
- `MapSelectorDialog`: Full-screen map with draggable viewport
- `SimpleMapWidget`: Address search and confirmation flow
- Coordinate format: 6 decimal places precision

## Development Guidelines

### Color Management
- Always use `BioWayColors` constants
- Never hardcode colors
- Platform-specific colors: `ecoceGreen`, `primaryGreen`

### Responsive Design
```dart
// Use MediaQuery percentages
final screenWidth = MediaQuery.of(context).size.width;
padding: EdgeInsets.all(screenWidth * 0.04),
fontSize: screenWidth * 0.045,

// Breakpoints
isTablet: screenWidth > 600
isCompact: screenHeight < 700
```

### Image Handling
- Auto-compression to 50KB for storage
- Use `ImageService.optimizeImageForDatabase()`
- Support camera and gallery sources

### Form Validation
- Validate on field level with TextEditingController
- Show inline error messages
- Disable submit until valid

### Mock Data Patterns
- Firebase IDs: `FID_${random}` (e.g., 'FID_1x7h9k3')
- Folios: `[PREFIX]0000001` format
- Timestamps: Use `DateTime.now()` for demos

## Performance Optimization

### Widget Optimization
- Use `const` constructors wherever possible
- Implement `InputDecorationCache` for forms
- Minimize rebuilds with targeted setState()

### List Performance
- Use `ListView.builder` for long lists
- Implement `ClampingScrollPhysics`
- Add `key` to list items for better diffing

### Image Performance
- Compress before upload (100KB target)
- Use `cached_network_image` for remote images
- Implement progressive loading

## Common Tasks

### Adding a New ECOCE Provider Type
1. Create registration screen in `lib/screens/login/ecoce/providers/`
2. Extend `BaseProviderRegisterScreen`
3. Override required properties (type, title, icon, etc.)
4. Add to `ECOCETipoProveedorSelector._providerTypes`
5. Update `_getTipoUsuario()` and `_getSubtipo()` in base class
6. Add materials in `_getMaterialesBySubtipo()`

### Adding a New Material Type
1. Update material lists in `BaseProviderRegisterScreen._getMaterialesBySubtipo()`
2. Add color in `BioWayColors` if needed
3. Update material handling in relevant screens

### Implementing a New Screen
1. Create in appropriate feature folder
2. Follow naming convention: `[Feature][Action]Screen`
3. Use shared widgets from `ecoce/shared/widgets/`
4. Add named route in `main.dart`
5. Update navigation in parent screen

## Troubleshooting

### Firebase Issues
- "Default app already exists": Check for duplicate initialization
- "No Firebase app": Ensure platform initialization before use
- Auth errors: Verify Firebase project configuration

### Build Issues
- Clean build: `flutter clean && flutter pub get`
- iOS pods: `cd ios && pod install`
- Android gradle: `cd android && ./gradlew clean`

### Map Issues
- Verify API key in `google_maps_config.dart`
- Check API enablement in Google Cloud Console
- Ensure internet connectivity for geocoding

### User Management Issues
- Deleted users still showing: Use refresh button or pull-to-refresh
- Can't delete Auth users: Requires Cloud Function implementation
- Duplicate emails: Check both `solicitudes_cuentas` and `ecoce_profiles`