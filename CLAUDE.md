# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# BioWay México - Flutter Mobile Application

## Project Overview

BioWay México is a dual-platform Flutter mobile application for recycling and waste management supporting both BioWay and ECOCE systems. The app implements a complete supply chain tracking system for recyclable materials with role-based access and multi-tenant Firebase architecture.

**Current Status**: ECOCE platform is in production. BioWay platform pending Firebase configuration.

### Key Features
- **Dual Platform Support**: BioWay and ECOCE in a single application
- **Multi-Tenant Firebase**: Separate projects per platform
- **Role-Based Access Control**: Different user types with specific permissions
- **Material Tracking**: Complete tracking of recyclable materials through the supply chain
- **QR Code System**: Generation and scanning for batch tracking
- **Document Management**: Upload and management with compression
- **Geolocation**: Location selection without GPS permissions required
- **Cloud Functions**: Automatic user deletion and scheduled cleanup tasks

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

### Firebase Functions
```bash
# Deploy functions (use Google Cloud Shell for Windows)
cd functions
firebase deploy --only functions

# View function logs
firebase functions:log

# Test locally with emulators
firebase emulators:start --only functions
```

### Firebase Rules
```bash
# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Storage rules
firebase deploy --only storage:rules

# Deploy both
firebase deploy --only firestore:rules,storage:rules
```

### Package Dependencies
Key dependencies (from pubspec.yaml):
- **Flutter SDK**: ^3.8.1
- **Firebase**: cloud_firestore, firebase_auth, firebase_storage, firebase_core, firebase_analytics
- **QR/Scanning**: mobile_scanner ^7.0.1, qr_flutter ^4.1.0
- **Image handling**: image_picker ^1.0.7, flutter_image_compress ^2.1.0
- **Documents**: pdf ^3.11.0, printing ^5.13.0, file_picker ^8.0.0+1
- **Location**: google_maps_flutter ^2.9.0, geolocator ^13.0.2, geocoding ^3.0.0
- **UI/UX**: timeline_tile ^2.0.0, photo_view ^0.15.0
- **Utilities**: rxdart ^0.27.7, intl ^0.19.0, url_launcher ^6.2.0, share_plus ^10.1.0

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
│   ├── documentos: {...}
│   └── usuario_id: string    # Added for aprobación flow

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
│   ├── datos_generales/      # General lot information (doc: 'info')
│   ├── origen/               # Origin process data (doc: 'data')
│   ├── transporte/           # Transport phases (docs: 'fase_1', 'fase_2')
│   ├── reciclador/          # Recycler process data (doc: 'data')
│   ├── analisis_laboratorio/ # Laboratory analysis (parallel process)
│   └── transformador/        # Transformer process data (doc: 'data')

transformaciones/              # Megalotes and sublotes system
├── [transformacionId]/
│   ├── datos_generales/      # General transformation info (doc: 'info')
│   │   ├── usuario_id: string # NOT usuarioId - critical field name
│   │   ├── peso_total_entrada: number
│   │   └── lotes_entrada: [{lote_id: string, ...}]
│   ├── sublotes/             # Generated sublotes
│   └── documentacion/        # Technical sheets and reports

users_pending_deletion/        # Users marked for Auth deletion (Cloud Function trigger)
├── [userId]
│   ├── status: "pending"/"completed"/"failed"
│   ├── created_at: timestamp
│   └── reason: string

material_reciclable/           # Material configurations
firmas/                        # Digital signatures storage
audit_logs/                    # System audit trail from Cloud Functions
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

Special cases:
- **Consumed lots**: Marked with `consumido_en_transformacion: true` are hidden from Exit tab
- **Sublots**: Only visible in Recycler's Completed tab when `proceso_actual == 'reciclador'`
- **Laboratory samples**: Don't change `proceso_actual` (parallel process)

### Weight Tracking System
The system uses dynamic weight calculation through the `pesoActual` getter:
- **Origin**: Uses initial weight (`pesoNace`)
- **After Transport Phase 1**: Uses delivered or picked weight
- **Recycler**: Uses processed weight (`pesoProcesado`) minus laboratory samples
- **After Transport Phase 2**: Uses delivered or picked weight  
- **Transformer**: Uses output weight or input weight

**Important**: Laboratory samples are automatically subtracted from recycler's weight. The laboratory must take samples BEFORE transport picks up the lot.

## Transformation System (Megalotes & Sublotes)

### Overview
The transformation system allows recyclers to process multiple lots together as "megalotes" and split them into "sublotes":
- **Megalote**: Virtual container for processing multiple lots together
- **Sublote**: New lot created from megalote with specific weight
- **Automatic deletion**: Megalotes are removed when `pesoDisponible == 0` AND documentation is uploaded

### Key Implementation
```dart
// Megalote deletion logic in transformacion_model.dart
bool get debeSerEliminada => pesoDisponible <= 0 && tieneDocumentacion;

// Creating sublotes
await _transformacionService.crearSublote(
  transformacionId: transformacion.id,
  peso: peso,
);
```

### Documentation Requirements
- **Ficha Técnica de Pellet** (f_tecnica_pellet)
- **Reporte de Resultado de Reciclador** (rep_result_reci)

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

### Route Arguments Pattern
Always pass route arguments as Map<String, dynamic>:
```dart
// CORRECT
Navigator.pushNamed(context, '/reciclador_lotes', arguments: {'initialTab': 1});

// WRONG - Will cause type casting error
Navigator.pushNamed(context, '/reciclador_lotes', arguments: 1);
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

### Transformation System (Megalotes)
Megalotes are created when recycler processes materials. Critical deletion logic:
```dart
// TransformacionModel deletion criteria
bool get debeSerEliminada => pesoDisponible <= 0 && tieneDocumentacion;

// NEVER auto-complete transformations when uploading docs
// Let the user explicitly mark as complete
```

### Merma Calculation Display
Always wrap merma calculations in setState for UI updates:
```dart
void _calcularMerma() {
  setState(() {
    final pesoOriginal = double.tryParse(_pesoOriginalController.text) ?? 0;
    final pesoProcesado = double.tryParse(_pesoProcesadoController.text) ?? 0;
    _merma = pesoOriginal - pesoProcesado;
    _mermaController.text = _merma.toStringAsFixed(2);
  });
}
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

### WillPopScope/PopScope Pattern
All main screens should prevent back button from logging out. Use PopScope for newer Flutter versions:
```dart
@override
Widget build(BuildContext context) {
  return PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) async {
      if (didPop) return;
      // Handle back button action
    },
    child: Scaffold(
      // ... screen content
    ),
  );
}
```

### Adaptive UI for Overflow Prevention
When displaying multiple items in rows, use Expanded widgets:
```dart
Row(
  children: [
    Expanded(
      flex: 2,
      child: Text(
        'Long text here',
        overflow: TextOverflow.ellipsis,
      ),
    ),
    Expanded(
      flex: 3,
      child: Text(
        'Another long text',
        textAlign: TextAlign.end,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  ],
)
```

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

### Document Opening Pattern
```dart
// Use DocumentUtils for consistent document opening
await DocumentUtils.openDocument(
  context: context,
  url: documentUrl,
  documentName: 'Constancia de Situación Fiscal',
);
```

### Scrollable Content Pattern
For filters and statistics that should scroll with content:
```dart
ListView(
  physics: const BouncingScrollPhysics(),
  children: [
    // Filters container
    Container(...),
    // Statistics container  
    Container(...),
    // List items
    ...items.map((item) => ItemWidget(item)),
  ],
)
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

### Firebase Storage Rules
Documents require proper Firebase Storage rules to be accessible:
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /ecoce/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

## State Management
Currently using StatefulWidget + setState(). No external state management libraries.

## Error Handling
Always wrap Firebase operations in try-catch blocks and show user-friendly error messages using DialogUtils.

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
3. Cloud Functions deployment blocked on Windows Git Bash conflict
   - Solution: Use Google Cloud Shell (see `docs/DEPLOY_FUNCTIONS_CLOUD_SHELL.md`)
4. Default emulator is `emulator-5554`
5. Firebase Storage rules must be configured for document access

### Permissions Issues
1. **Megalotes Visibility**: May not appear across devices with same account
   - Root cause: Firestore security rules with user filters
   - Solution documented in `docs/PROBLEMA_VISUALIZACION_MEGALOTES.md`

### Testing Considerations
- No unit tests currently implemented
- Integration tests require real device or emulator
- Firebase emulator suite not configured

### Performance Considerations
- Image compression target: ~50KB
- PDF size limit: 5MB
- Signature dimensions: 300x120 with AspectRatio 2.5
- Use `collectionGroup` queries without user filters for better cross-device compatibility

## Recent Critical Fixes

### Transfer System
- **Reciclador→Transportista Transfer** (2025-07-25): Changed from bidirectional to unidirectional confirmation
  - Files: `lote_unificado_service.dart`, `carga_transporte_service.dart`
  - When Transport scans from Recycler, `proceso_actual` updates immediately

### UI/UX Improvements
- **Signature Display**: Fixed AspectRatio to 2.5 with 300x120 dimensions
- **Origin Statistics**: Shows ALL lots created (using `creado_por` field)
- **Back Button**: All main screens use PopScope to prevent accidental logout
- **Document Viewing**: Simplified approach with DocumentUtils and external browser
- **Pixel Overflow**: Fixed in Recycler exit form with adaptive UI components
- **Scrollable Statistics**: Made filters and statistics scrollable in lot management screens

### Weight Tracking
- Dynamic weight calculation through `pesoActual` getter
- Laboratory samples automatically subtracted from recycler weight
- Transport uses actual weight, not initial weight

### QR Code System
- Unified scanner implementation across all user types
- Debounce logic to prevent duplicate scans
- QRUtils for consistent QR code handling

### Recent UI Updates (2025-07-27)
- **Merma Display**: Fixed merma calculation display in Recycler reception form
- **Scanner Messages**: Unified error messages in Transport receiver scanning
- **Statistics Optimization**: Removed polymer statistics, reduced statistics space
- **Adaptive Layouts**: Fixed pixel overflow in multi-lot processing sections

### Critical Fixes (2025-07-27)

#### Megalote Deletion Issue
- **Problem**: Megalotes were being deleted without using all weight or uploading documentation
- **Solution**: Modified `debeSerEliminada` getter in `transformacion_model.dart` to only check weight and documentation
- **Files Modified**: 
  - `lib/models/lotes/transformacion_model.dart` - Changed deletion logic
  - `lib/screens/ecoce/reciclador/reciclador_transformacion_documentacion.dart` - Removed automatic completion

#### Android Back Button Navigation
- **Problem**: Back button was logging users out instead of navigating to home screen
- **Solution**: Implemented PopScope with proper navigation handling
- **Files Modified**:
  - All Origin screens: Added PopScope to navigate to home instead of logout
  - All Transporter screens: Replaced deprecated WillPopScope with PopScope
  - Shared screens (profile, help): Updated to use PopScope

#### UI/UX Improvements
- **Merma Calculation**: Wrapped calculation in setState() for proper UI updates
- **Scrollable Statistics**: Changed Column to ListView in lot management screens
- **Adaptive Multi-lot Display**: Used Expanded widgets with flex ratios to prevent overflow
- **Empty State Handling**: Ensured filters/statistics remain visible when no lots exist

#### Code Cleanup
- **Removed Unused Imports**: Cleaned up unused imports across Origin and Transporter screens
- **Fixed Deprecated Methods**: Replaced withOpacity with withValues(alpha:)
- **Added Missing Dependency**: Added pdf package (^3.11.0) to pubspec.yaml

### Critical Fixes (2025-07-28)

#### Type Casting Error in Recycler Exit Form
- **Problem**: `'int' is not a subtype of type 'Map<String, dynamic>?' in type cast` error when completing exit form
- **Root Cause**: Route argument was passed as integer instead of Map in `reciclador_formulario_salida.dart`
- **Solution**: 
  - Changed `arguments: 1` to `arguments: {'initialTab': 1}`
  - Updated `main.dart` routing to handle both int and Map arguments for backward compatibility
- **Files Modified**:
  - `lib/screens/ecoce/reciclador/reciclador_formulario_salida.dart` - Fixed route argument format
  - `lib/main.dart` - Added robust argument handling for `/reciclador_lotes` route

#### Consumed Lots Not Disappearing from Exit Tab
- **Problem**: Lots used to create megalotes were not being removed from the "Salida" (Exit) tab
- **Root Cause**: Document name inconsistency - `datos_generales` collection uses `'info'` document, but transformation service was updating `'data'`
- **Solution**: Updated document references to use consistent naming
- **Files Modified**:
  - `lib/services/transformacion_service.dart` - Changed `.doc('data')` to `.doc('info')` for datos_generales updates
  - `lib/services/lote_unificado_service.dart` - Fixed inconsistent document reference in line 1760

#### Recycler Lots Tab Improvements
- **Sublots Visibility**: Fixed sublots not appearing in Completed tab by updating filters
- **Tab Navigation**: User now stays on Completed tab after creating sublots
- **Sample Button**: Disabled when megalote has no available weight
- **Megalote Filtering**: Only show megalotes with available weight or pending documentation

### Database Document Structure Clarification
- **datos_generales**: Uses document name `'info'`
- **Other processes** (origen, reciclador, transformador): Use document name `'data'`
- **transporte**: Uses phase names ('fase_1', 'fase_2') as document names

### Recent Critical Fixes (2025-01-28) - Reciclador Final Implementation

#### Visibilidad de Lotes en Transferencia Transporte-Reciclador
- **Problem**: Lots disappeared from Recycler's "Salida" tab when Recycler received before Transport confirmed delivery
- **Root Causes**:
  - Transport service incorrectly calling `transferirLote()` and overwriting recycler's `usuario_id`
  - Query filter too restrictive (only `proceso_actual == 'reciclador'`)
  - Excessive filtering based on documentation status
  - Legacy lots with corrupted `usuario_id` from previous bug
- **Solution**:
  - Removed incorrect `transferirLote()` call in `carga_transporte_service.dart`
  - Expanded query to include `['reciclador', 'transporte']` states
  - Implemented flexible verification for legacy lots using additional evidence fields
- **Files Modified**:
  - `lib/services/carga_transporte_service.dart` - Removed lines 554-566
  - `lib/services/lote_unificado_service.dart` - Lines 892, 920-963, 944-947
  - `lib/screens/ecoce/reciclador/reciclador_administracion_lotes.dart` - Lines 149-151
- **Documentation**: `docs/FIX_VISIBILIDAD_LOTES_TRANSPORTE_RECICLADOR.md`

#### Estadísticas del Reciclador Mostrando 0
- **Problem**: Statistics showed 0 despite having data (megalotes and processed lots)
- **Root Cause**: 
  - Field name mismatch: searching for `usuarioId` instead of `usuario_id`
  - Searching in empty `lotes` collection (lots were consumed in transformations)
- **Solution**: 
  - Changed query field from `usuarioId` to `usuario_id`
  - New strategy: count unique lots from transformations instead of lotes collection
  - Simplified stream to use single query instead of rxdart CombineLatestStream
- **Files Modified**:
  - `lib/services/lote_unificado_service.dart` - New statistics methods
  - `lib/screens/ecoce/reciclador/reciclador_inicio.dart` - Updated field names

#### Sistema de Transformaciones y Sublotes Completo
- **Features Implemented**:
  - Multiple lot selection in "Salida" tab
  - Megalote creation with weight loss (merma) tracking
  - On-demand sublot creation from available weight
  - Automatic megalote deletion when weight=0 AND documentation complete
  - Complete traceability from sublots to original lots
- **Key Files**:
  - `lib/services/transformacion_service.dart` - Core transformation logic
  - `lib/screens/ecoce/reciclador/reciclador_formulario_salida.dart` - Multi-lot processing
  - `lib/screens/ecoce/reciclador/reciclador_administracion_lotes.dart` - Sublot creation UI

#### Laboratory Module Implementation (2025-01-28)
- **Problem**: Laboratory signature and photo evidence not working
- **Solution**: Replicated exact implementation from functional Recycler forms
- **Files Modified**:
  - `lib/screens/ecoce/laboratorio/laboratorio_toma_muestra_megalote_screen.dart` - Fixed signature and photo widgets

#### Megalotes Visibility Issue (PENDING)
- **Problem**: Megalotes not visible on different devices with same account
- **Root Cause**: Transformaciones use `where('usuario_id', isEqualTo: uid)` filter that requires specific permissions
- **Current Behavior**:
  - Lotes: Use `collectionGroup` without user filter (work correctly)
  - Transformaciones: Use `where` with user filter (blocked by permissions)
- **Status**: Identified but pending implementation
- **Documentation**: `docs/PROBLEMA_VISUALIZACION_MEGALOTES.md`

#### Important Field Names in Firebase
- **Transformaciones collection**: 
  - User field: `usuario_id` (NOT `usuarioId`)
  - Weight field: `peso_total_entrada`
  - Lots array: `lotes_entrada` with objects containing `lote_id`
- **Lotes consumed**: Marked with `consumido_en_transformacion: true` in datos_generales/info

## Cloud Functions

### Implemented Functions
1. **deleteAuthUser**: Automatically deletes Firebase Auth users when accounts are rejected
2. **cleanupOldDeletionRecords**: Daily cleanup of deletion records older than 30 days
3. **manualDeleteUser**: Callable function for manual user deletion by administrators
4. **healthCheck**: HTTP endpoint to verify functions are deployed and running

### Deployment
```bash
# Use Google Cloud Shell for Windows users
cd functions
npm install
firebase deploy --only functions
```

For detailed deployment instructions, see `docs/DEPLOY_FUNCTIONS_CLOUD_SHELL.md`

## Documentation Index

### Implementation Guides
- `docs/RECICLADOR_ESTADISTICAS_SOLUCION.md` - Statistics fix details
- `docs/RECICLADOR_TRANSFORMACIONES_IMPLEMENTACION.md` - Complete transformation system
- `docs/SISTEMA_TRANSFORMACIONES_SUBLOTES.md` - Megalotes and sublotes architecture
- `docs/RESUMEN_CLOUD_FUNCTIONS_IMPLEMENTACION.md` - Cloud Functions summary

### Troubleshooting
- `docs/PROBLEMA_VISUALIZACION_MEGALOTES.md` - Megalotes visibility issue analysis
- `docs/MISMO_USUARIO_MULTIPLES_DISPOSITIVOS.md` - Multi-device same account usage
- `docs/FIREBASE_RULES_TRANSFORMACIONES_SOLUTION.md` - Firebase security rules
- `docs/TROUBLESHOOTING_GUIDE.md` - General troubleshooting guide

### Deployment & Configuration
- `docs/DEPLOY_FUNCTIONS_CLOUD_SHELL.md` - Cloud Functions deployment
- `docs/DEPLOY_FIRESTORE_RULES_FIX.md` - Firestore rules deployment
- `docs/HABILITAR_APIS_CLOUD_FUNCTIONS.md` - Enable required Google Cloud APIs
- `docs/CONFIGURACION_TECNICA_COMPLETA.md` - Complete technical configuration

### Recent Fixes
- `docs/FIX_VISIBILIDAD_LOTES_TRANSPORTE_RECICLADOR.md` - Batch visibility fix in Transport-Recycler transfer
- `docs/OPTIMIZACION_REGISTRO_PROVEEDORES.md` - Provider registration optimization
- `docs/FIX_FOLIO_FORMAT.md` - Folio format standardization
- `docs/FIX_MISSING_USER_ID_IN_SOLICITUD.md` - User ID in account requests
- `docs/ECOCE_PROFILE_SERVICE_FIXES.md` - Profile service improvements