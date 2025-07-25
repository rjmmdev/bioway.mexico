# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# BioWay México - Flutter Mobile Application

## Project Overview

BioWay México is a dual-platform Flutter mobile application for recycling and waste management supporting both BioWay and ECOCE systems. The app implements a complete supply chain tracking system for recyclable materials with role-based access and multi-tenant Firebase architecture.

### Key Features
- **Dual Platform Support**: BioWay and ECOCE in a single application
- **Multi-Tenant Firebase**: Separate projects per platform
- **Role-Based Access Control**: Different user types with specific permissions
- **Material Tracking**: Complete tracking of recyclable materials through the supply chain
- **QR Code System**: Generation and scanning for batch tracking
- **Document Management**: Upload and management with compression
- **Geolocation**: Location selection without GPS permissions required

## Commands

### Development
```bash
# Clean and get dependencies
flutter clean && flutter pub get

# Run on specific emulator
flutter run -d emulator-5554

# Run with verbose output
flutter run -v

# Run on all available devices
flutter run -d all
```

### Building
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# App Bundle
flutter build appbundle

# iOS build
flutter build ios

# Obfuscated build
flutter build apk --obfuscate --split-debug-info=./symbols
```

### Testing
```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test
flutter test test/widget_test.dart

# Run tests by name
flutter test --name="Login"

# Integration tests
flutter drive --target=test_driver/app.dart
```

### Code Quality
```bash
# Analyze code
flutter analyze

# Format all files
dart format .

# Format specific file
dart format lib/main.dart

# Check outdated packages
flutter pub outdated

# Upgrade packages
flutter pub upgrade
```

### Automation Scripts (Windows)
```powershell
# Build and run APK
.\build_and_run.ps1

# Quick run (uses existing build)
.\run_app.ps1
```

## Architecture

### Directory Structure
```
lib/
├── screens/
│   ├── splash_screen.dart              # Entry point with animation
│   ├── platform_selector_screen.dart   # BioWay vs ECOCE selection
│   ├── login/
│   │   ├── bioway/                    # BioWay authentication
│   │   └── ecoce/                     # ECOCE authentication
│   │       └── providers/             # Role-specific registration
│   └── ecoce/
│       ├── origen/                    # Collection center screens
│       ├── reciclador/               # Recycler screens
│       ├── transporte/               # Transport screens
│       ├── transformador/            # Transformer screens
│       ├── laboratorio/              # Laboratory screens
│       ├── maestro/                  # Master admin screens
│       ├── repositorio/              # Repository screens
│       └── shared/                   # Shared ECOCE components
├── services/
│   ├── firebase/
│   │   ├── firebase_manager.dart     # Multi-tenant Firebase management
│   │   ├── firebase_config.dart      # Platform configurations
│   │   └── auth_service.dart         # Multi-tenant authentication
│   ├── document_service.dart         # Document upload/compression
│   ├── image_service.dart           # Image compression (50KB target)
│   ├── lote_service.dart            # Lot management across all user types
│   ├── lote_unificado_service.dart  # Unified lot system service
│   └── user_session_service.dart    # User session management
├── models/                          # Data models
├── utils/                           # Utilities (colors, formats, etc.)
└── widgets/                         # Reusable widgets
```

### Firebase Multi-Tenant Architecture

#### Projects Configuration
1. **ECOCE Project** (Configured)
   - Project ID: `trazabilidad-ecoce`
   - Package: `com.biowaymexico.app`
   - Status: ✅ Working

2. **BioWay Project** (Pending)
   - Project ID: `bioway-mexico` (suggested)
   - Package: `com.biowaymexico.app`
   - Status: ⏳ Not created

#### Firebase Initialization Pattern
```dart
// DO NOT initialize Firebase in main.dart
// Each platform initializes its own Firebase on login
await _authService.initializeForPlatform(FirebasePlatform.ecoce);
```

### Database Structure

#### Collections
```
solicitudes_cuentas/           # Account requests pending approval
├── [solicitudId]
│   ├── estado: "pendiente"/"aprobada"/"rechazada"
│   ├── datos_perfil: {...}
│   └── documentos: {...}

ecoce_profiles/                # User profiles index
├── [userId]
│   ├── path: "ecoce_profiles/[type]/usuarios/[userId]"
│   ├── folio: "A0000001"
│   └── aprobado: true

ecoce_profiles/[type]/usuarios/  # Profile data by type
├── origen/centro_acopio/
├── origen/planta_separacion/
├── reciclador/usuarios/
├── transformador/usuarios/
├── transporte/usuarios/
└── laboratorio/usuarios/

lotes/                         # Unified lot collection
├── [loteId]/
│   ├── datos_generales/      # General lot information
│   ├── origen/               # Origin process data
│   ├── transporte/           # Transport phases (fase_1, fase_2)
│   ├── reciclador/          # Recycler process data
│   ├── analisis_laboratorio/ # Laboratory analysis (parallel process)
│   └── transformador/        # Transformer process data

users_pending_deletion/        # Users marked for Auth deletion
├── [userId]
│   └── status: "pending"/"completed"/"failed"
```

## ECOCE System

### User Types & Folios
- **A0000001**: Centro de Acopio (Origen)
- **P0000001**: Planta de Separación (Origen)
- **R0000001**: Reciclador
- **T0000001**: Transformador
- **V0000001**: Transporte
- **L0000001**: Laboratorio

### Account Approval Flow
1. User registers (creates request in `solicitudes_cuentas`)
2. Master reviews and approves/rejects
3. On approval: Firebase Auth user created, folio assigned
4. On rejection: Request deleted

### Material Types by Role
- **Origen**: EPF types (Poli, PP, Multi)
- **Reciclador**: Processing states (separated, bales, sacks)
- **Transformador**: Pellets and flakes
- **Laboratorio**: Sample types

### QR Code Flow Architecture
1. **Origin creates lot** → QR format: `LOTE-TIPOMATERIAL-ID`
2. **Transport scans lots** → Creates cargo with multiple lots
3. **Transport delivers** → Creates delivery QR: `ENTREGA-ID`
4. **Recycler scans delivery** → Receives lots automatically
5. **Laboratory takes samples** → Parallel process, no ownership transfer

### Lot Visibility Rules
Lots appear in user screens based on `proceso_actual` field:
- **Origin**: Shows lots where `proceso_actual == 'origen'`
- **Transport**: Shows lots where `proceso_actual == 'transporte'`
- **Recycler**: Shows lots where `proceso_actual == 'reciclador'`
- **Transformer**: Shows lots where `proceso_actual == 'transformador'`

When a lot is successfully transferred (both delivery and reception completed), the `proceso_actual` updates and the lot moves to the new user's screen.

### Weight Tracking System
The system uses dynamic weight calculation through the `pesoActual` getter:
- **Origin**: Uses initial weight (`pesoNace`)
- **After Transport Phase 1**: Uses delivered or picked weight
- **Recycler**: Uses processed weight (`pesoProcesado`) minus laboratory samples
- **After Transport Phase 2**: Uses delivered or picked weight  
- **Transformer**: Uses output weight or input weight

**Important**: Laboratory samples are automatically subtracted from recycler's weight. The laboratory must take samples BEFORE transport picks up the lot.

## Unified Lot System

### Key Concepts
- **Immutable ID**: Each lot has a single ID throughout its lifecycle
- **Transport Phases**: Map structure for multiple transport phases
- **Laboratory Process**: List of analyses without ownership transfer
- **Automatic Phase Detection**: System determines transport phase based on current process

### LoteUnificadoModel Structure
```dart
class LoteUnificadoModel {
  final String id;                                    // Immutable unique ID
  final DatosGeneralesLote datosGenerales;          // General information
  final ProcesoOrigenData? origen;                   // Origin data
  final Map<String, ProcesoTransporteData> transporteFases; // Transport phases
  final ProcesoRecicladorData? reciclador;          // Recycler data
  final List<AnalisisLaboratorioData> analisisLaboratorio; // Lab analyses
  final ProcesoTransformadorData? transformador;     // Transformer data
}
```

### Transport Phases
- **fase_1**: Origin → Recycler
- **fase_2**: Recycler → Transformer
- Automatically determined based on `proceso_actual`

### QR Code Handling
```dart
// Use QRUtils for consistent QR code handling
import 'package:app/utils/qr_utils.dart';

// Extract lot ID from QR code
final loteId = QRUtils.extractLoteIdFromQR(qrCode);

// Generate QR code
final qrCode = QRUtils.generateLoteQR(tipoPoli, loteId);
```

### QR Scanner Implementation
The app uses a unified full-screen QR scanner (`SharedQRScannerScreen`) for all user types:
```dart
// Navigate to scanner
final qrCode = await Navigator.push<String>(
  context,
  MaterialPageRoute(
    builder: (context) => SharedQRScannerScreen(
      isAddingMore: widget.isAddingMore,
    ),
  ),
);
```

## Critical Implementation Patterns

### Multi-Lot Scanning Fix
When implementing multi-lot QR scanning, avoid double Navigator.pop():
```dart
// CORRECT - Scanner returns value to caller
void _scanAnotherLot() async {
  final code = await Navigator.push<String>(
    context,
    MaterialPageRoute(
      builder: (context) => SharedQRScannerScreen(
        isAddingMore: true,
      ),
    ),
  );
  
  if (code != null) {
    _processScannedCode(code, fromScanner: true);
  }
}
```

### Firebase Field Naming
Always check actual Firebase field names in models:
```dart
// Example: Transport phases use specific field names
'transporteFases' // Map<String, ProcesoTransporteData>
'analisisLaboratorio' // List<AnalisisLaboratorioData>
```

### Navigation After Success
Use named routes for navigation after form submission:
```dart
// CORRECT - Navigate to user-specific home
Navigator.of(context).pushNamedAndRemoveUntil(
  '/reciclador_inicio',
  (route) => false,
);

// WRONG - Goes to login screen
Navigator.of(context).popUntil((route) => route.isFirst);
```

### Transport Phase Document Verification
When verifying lot transfers involving Transport, always check the correct phase document:
```dart
// CORRECT - Check phase document for Transport
if (procesoDestino == PROCESO_TRANSPORTE) {
  String faseDestino = procesoOrigen == PROCESO_RECICLADOR ? 'fase_2' : 'fase_1';
  destinoDoc = await loteRef.collection(PROCESO_TRANSPORTE).doc(faseDestino).get();
}

// WRONG - Transport doesn't use 'data' document
destinoDoc = await loteRef.collection(PROCESO_TRANSPORTE).doc('data').get();
```

### Bidirectional Transfer System
Lot transfers require both parties to complete their parts:
1. **Sender**: Marks lot as delivered with `entrega_completada: true` and `firma_salida`
2. **Receiver**: Marks lot as received with `recepcion_completada: true`
3. **System**: Updates `proceso_actual` only when both are complete

Use `verificarYActualizarTransferencia` to ensure transfers are completed:
```dart
await _loteUnificadoService.verificarYActualizarTransferencia(
  loteId: loteId,
  procesoOrigen: 'reciclador',
  procesoDestino: 'transporte',
);
```

### Laboratory Sample Flow
Laboratory operates as a parallel process without transferring lot ownership:
```dart
// Laboratory takes samples from recycler lots
await _loteUnificadoService.registrarAnalisisLaboratorio(
  loteId: loteId,
  pesoMuestra: peso,
  certificado: null, // Added later
  firmaOperador: firma,
  evidenciasFoto: fotos,
);
```

To get lots with laboratory analyses:
```dart
// Stream of lots where current user has taken samples
_loteService.obtenerLotesConAnalisisLaboratorio()
```

### Signature Widget Pattern
For signature capture with dynamic sizing:
```dart
AspectRatio(
  aspectRatio: 2.5,
  child: Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey[200]!),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 300,
          height: 120,
          child: CustomPaint(
            size: const Size(300, 120),
            painter: SignaturePainter(
              points: _signaturePoints,
              color: BioWayColors.darkGreen,
              strokeWidth: 2.0,
            ),
          ),
        ),
      ),
    ),
  ),
)
```

## Dependencies

### Core UI
- `cupertino_icons: ^1.0.8`
- `flutter_svg: ^2.0.10+1`
- `smooth_page_indicator: ^1.2.0+3`
- `carousel_slider: ^5.0.0`
- `fl_chart: ^0.69.0`

### Media & Files
- `image_picker: ^1.1.2`
- `flutter_image_compress: ^2.3.0`
- `screenshot: ^3.0.0`
- `photo_view: ^0.15.0`
- `gal: ^2.3.0`
- `file_picker: ^8.1.2`
- `path_provider: ^2.1.4`

### QR & Scanning
- `qr_flutter: ^4.1.0`
- `mobile_scanner: ^6.0.2`

### Maps & Location
- `google_maps_flutter: ^2.9.0`
- `geocoding: ^3.0.0`
- `geolocator: ^13.0.1`

### Firebase Suite
- `firebase_core: ^3.3.0`
- `firebase_auth: ^5.1.4`
- `cloud_firestore: ^5.2.1`
- `firebase_storage: ^12.1.3`

### Sharing & Export
- `share_plus: ^10.0.2`
- `printing: ^5.13.3`
- `pdf: ^3.11.1`

### Platform Integration
- `permission_handler: ^11.3.1`
- `url_launcher: ^6.3.0`
- `package_info_plus: ^8.0.2`

## Project Configuration

### Package Information
- **Name**: `app`
- **Version**: `1.0.0+1`
- **Dart SDK**: `^3.8.1`
- **Android Package**: `com.biowaymexico.app`

### Important Files
- `android/app/google-services.json` - Combined Firebase config for all projects
- `ios/Runner/GoogleService-Info.plist` - iOS Firebase config (per platform)
- `lib/config/google_maps_config.dart` - Google Maps API keys
- `lib/utils/colors.dart` - All color constants
- `docs/` - Solution documentation for implemented fixes

## Code Patterns

### Loading States
```dart
if (_isLoading) {
  return Scaffold(
    backgroundColor: const Color(0xFFF5F5F5),
    body: Center(
      child: CircularProgressIndicator(
        color: BioWayColors.ecoceGreen,
      ),
    ),
  );
}
```

### Dialog Pattern
```dart
DialogUtils.showSuccessDialog(
  context,
  title: 'Éxito',
  message: 'Operación completada',
  onAccept: () => Navigator.pop(context),
);
```

### Date Formatting
```dart
// Always use utility functions
FormatUtils.formatDate(DateTime.now())      // "21/07/2025"
FormatUtils.formatDateTime(DateTime.now())  // "21/07/2025 14:30"
```

### Form State Management
```dart
// Initialize form data asynchronously
Future<void> _initializeForm() async {
  final userData = _userSession.getUserData();
  _operadorController.text = userData?['nombre'] ?? '';
  
  _pesoTotalOriginal = await _loteService.calcularPesoTotal(widget.lotIds);
  setState(() {}); // Update UI after async operation
}
```

## Naming Conventions

### Files
- Screens: `[feature]_[action]_screen.dart`
- Widgets: `[feature]_[type]_widget.dart`
- Services: `[name]_service.dart`
- Models: `[name]_model.dart`

### Classes
- Screens: `[Feature][Action]Screen`
- Widgets: `[Feature][Type]Widget`
- Services: `[Name]Service`
- Models: `[Name]Model`

### Variables
- Private: `_variableName`
- Constants: `CONSTANT_NAME` or `kConstantName`
- Colors: Always use `BioWayColors.[colorName]`

## Routes

### ECOCE User Routes
- `/reciclador_inicio` - Recycler home
- `/reciclador_escaneo` - QR scanning
- `/reciclador_lotes` - Lot management
- `/transporte_inicio` - Transport home
- `/laboratorio_inicio` - Laboratory home
- `/transformador_inicio` - Transformer home
- `/origen_inicio` - Origin home
- `/maestro_inicio` - Master admin home

## State Management
Currently using StatefulWidget + setState(). No external state management libraries.

## Error Handling
Always wrap Firebase operations in try-catch blocks and show user-friendly error messages using DialogUtils.

## Responsive Design
```dart
final screenWidth = MediaQuery.of(context).size.width;
final isTablet = screenWidth > 600;
final isCompact = screenWidth < 360;
```

## Color Usage
NEVER hardcode colors. Always use `BioWayColors` constants:
- Platform colors: `ecoceGreen`, `primaryGreen`
- Material colors: `pebdPink`, `ppPurple`, `multilaminadoBrown`  
- Status colors: `success`, `error`, `warning`, `info`

## Image Compression
- Images auto-compressed to ~50KB for storage
- PDFs limited to 5MB
- Use `ImageService.optimizeImageForDatabase()` for consistency

## Known Issues & Limitations

### BioWay Platform
- Firebase project NOT created yet
- Configuration exists in `firebase_config.dart` but needs actual values
- Login and features are placeholders

### Technical Limitations
1. Google Maps API keys need to be configured
2. iOS build not tested (no GoogleService-Info.plist)
3. User deletion requires Cloud Function (see `docs/CLOUD_FUNCTION_DELETE_USERS.md`)
4. Default emulator is `emulator-5554`

## Recent Fixes Applied
1. Multi-lot QR scanning navigation issue (double pop prevented)
2. Transport delivery QR automatic lot creation
3. Recycler scanner field mapping corrections
4. Recycler form weight calculations (gross = sum, net = user input)
5. Signature widget positioning with proportional scaling
6. Navigation after form completion (avoid logout)
7. Unified lot structure with immutable IDs
8. Transport phases (fase_1, fase_2) implementation
9. Laboratory as parallel process without ownership transfer
10. QRUtils for consistent QR code handling across all screens
11. Transport phase verification in lot transfer (fixed fase_1/fase_2 document lookup)
12. Origin to Transport lot transfer completion detection
13. Fixed QR scanning triplication in Transport (added debounce and single-scan logic)
14. Transport now uses dynamic weight (pesoActual) instead of static initial weight
15. Recycler form now saves peso_procesado field for proper weight tracking
16. Bidirectional transfer verification ensures both parties complete their parts
17. Laboratory management screen updated to use unified lot system
18. Laboratory scanner updated to use full-screen SharedQRScannerScreen
19. Weight display in Transport QR shows actual weight after lab samples
20. Added visual indicators when laboratory has taken samples from lots
21. **[2025-07-25] Reciclador→Transportista Transfer Issue**: Lotes no desaparecían del Reciclador después del escaneo
    - **Problema**: El sistema requería confirmación bidireccional pero el Reciclador ya había autorizado
    - **Solución implementada**:
      - Transferencia Reciclador→Transportista ahora es unidireccional en `verificarTransferenciaCompleta`
      - Actualización inmediata de `proceso_actual` cuando transportista escanea del reciclador
      - Verificación doble: si `verificarYActualizarTransferencia` falla, forzar actualización
      - Mejorada determinación de fase de transporte verificando documentos existentes
    - **Cambios en archivos**:
      - `lote_unificado_service.dart`: Lógica unidireccional líneas 264-271
      - `carga_transporte_service.dart`: Actualización forzada líneas 243-270
      - `lote_unificado_service.dart`: Determinación de fase mejorada líneas 476-513