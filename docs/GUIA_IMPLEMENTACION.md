# Guía de Implementación y Solución de Problemas - BioWay México

## Índice
1. [Configuración Inicial](#configuración-inicial)
2. [Implementación de Características](#implementación-de-características)
3. [Solución de Problemas Comunes](#solución-de-problemas-comunes)
4. [Patrones de Código y Mejores Prácticas](#patrones-de-código-y-mejores-prácticas)
5. [Deployment y Producción](#deployment-y-producción)
6. [Mantenimiento y Monitoreo](#mantenimiento-y-monitoreo)
7. [Casos de Uso Específicos](#casos-de-uso-específicos)
8. [Referencias Rápidas](#referencias-rápidas)

---

## Configuración Inicial

### 1. Clonar y Configurar el Proyecto

```bash
# Clonar repositorio
git clone [repository-url]
cd app

# Instalar dependencias
flutter clean
flutter pub get

# Verificar instalación
flutter doctor
```

### 2. Configuración de Firebase

#### ECOCE (Producción)
```dart
// Ya configurado en firebase_config.dart
static const FirebaseOptions ecoceOptions = FirebaseOptions(
  apiKey: "AIzaSyB5mFxH8K2bXkMQ_ZyY1AqKlOQPt6XKLVM",
  authDomain: "trazabilidad-ecoce.firebaseapp.com",
  projectId: "trazabilidad-ecoce",
  storageBucket: "trazabilidad-ecoce.firebasestorage.app",
  messagingSenderId: "376182934505",
  appId: "1:376182934505:android:app-id",
);
```

#### BioWay (Pendiente)
```dart
// Necesita crearse el proyecto Firebase
// 1. Crear proyecto en Firebase Console
// 2. Agregar app Android: com.biowaymexico.app
// 3. Descargar google-services.json
// 4. Actualizar firebase_config.dart
```

### 3. Configuración de Google Maps

```dart
// lib/config/google_maps_config.dart
class GoogleMapsConfig {
  static const String androidApiKey = 'YOUR_ANDROID_API_KEY';
  static const String iosApiKey = 'YOUR_IOS_API_KEY';
}

// android/app/src/main/AndroidManifest.xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ANDROID_API_KEY"/>
```

### 4. Permisos Requeridos

#### Android (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

#### iOS (Info.plist)
```xml
<key>NSCameraUsageDescription</key>
<string>La app necesita acceso a la cámara para escanear códigos QR</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>La app necesita acceso a tus fotos para subir evidencias</string>
```

---

## Implementación de Características

### 1. Sistema de Transformaciones (Megalotes)

#### Crear Servicio de Transformaciones
```dart
// lib/services/transformacion_service.dart
class TransformacionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userUid;
  
  // Crear transformación consumiendo lotes
  Future<String> crearTransformacion({
    required List<LoteUnificadoModel> lotes,
    required double mermaProceso,
    required String procesoAplicado,
  }) async {
    final batch = _firestore.batch();
    final transformacionId = 'TRANS-${DateTime.now().millisecondsSinceEpoch}';
    
    // 1. Crear documento de transformación
    final transformacionRef = _firestore
        .collection('transformaciones')
        .doc(transformacionId)
        .collection('datos_generales')
        .doc('info');
    
    final lotesEntrada = lotes.map((lote) => {
      'lote_id': lote.id,
      'peso': lote.pesoActual,
      'tipo_material': lote.datosGenerales.tipoPolimero,
      'porcentaje': (lote.pesoActual / pesoTotal) * 100,
    }).toList();
    
    batch.set(transformacionRef, {
      'tipo': 'agrupacion_reciclador',
      'usuario_id': _userUid, // CRÍTICO: no usar 'usuarioId'
      'fecha_inicio': FieldValue.serverTimestamp(),
      'estado': 'en_proceso',
      'lotes_entrada': lotesEntrada,
      'peso_total_entrada': pesoTotal,
      'merma_proceso': mermaProceso,
      'peso_disponible': pesoTotal - mermaProceso,
      'sublotes_generados': [],
      'proceso_aplicado': procesoAplicado,
    });
    
    // 2. Marcar lotes como consumidos
    for (final lote in lotes) {
      final loteRef = _firestore
          .collection('lotes')
          .doc(lote.id)
          .collection('datos_generales')
          .doc('info'); // CRÍTICO: usar 'info', no 'data'
      
      batch.update(loteRef, {
        'consumido_en_transformacion': true,
        'transformacion_id': transformacionId,
        'fecha_consumo': FieldValue.serverTimestamp(),
      });
    }
    
    await batch.commit();
    return transformacionId;
  }
  
  // Crear sublote bajo demanda
  Future<String> crearSublote({
    required String transformacionId,
    required double peso,
  }) async {
    // Validar peso disponible
    final transformacion = await obtenerTransformacion(transformacionId);
    if (peso > transformacion.pesoDisponible) {
      throw Exception('Peso excede disponible');
    }
    
    final subloteId = 'SUB-${DateTime.now().millisecondsSinceEpoch}';
    final batch = _firestore.batch();
    
    // 1. Crear sublote como lote derivado
    final subloteRef = _firestore
        .collection('lotes')
        .doc(subloteId)
        .collection('datos_generales')
        .doc('info');
    
    batch.set(subloteRef, {
      'id': subloteId,
      'tipo_lote': 'derivado',
      'transformacion_origen': transformacionId,
      'peso_nace': peso,
      'proceso_actual': 'reciclador',
      'fecha_creacion': FieldValue.serverTimestamp(),
      'creado_por': _userUid,
      'composicion': _calcularComposicion(transformacion, peso),
    });
    
    // 2. Actualizar transformación
    batch.update(transformacionRef, {
      'peso_disponible': FieldValue.increment(-peso),
      'sublotes_generados': FieldValue.arrayUnion([subloteId]),
    });
    
    await batch.commit();
    return subloteId;
  }
}
```

#### UI para Selección Múltiple
```dart
// Modificar reciclador_administracion_lotes.dart
class _SalidaTabContent extends StatefulWidget {
  @override
  State<_SalidaTabContent> createState() => _SalidaTabContentState();
}

class _SalidaTabContentState extends State<_SalidaTabContent> {
  final Set<String> _selectedLoteIds = {};
  bool _isSelectionMode = false;
  
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isSelectionMode
          ? AppBar(
              title: Text('${_selectedLoteIds.length} lotes seleccionados'),
              leading: IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedLoteIds.clear();
                  });
                },
              ),
            )
          : null,
      body: StreamBuilder<List<LoteUnificadoModel>>(
        stream: _loteService.obtenerLotesPorProceso('reciclador'),
        builder: (context, snapshot) {
          return ListView.builder(
            itemCount: lotes.length,
            itemBuilder: (context, index) {
              final lote = lotes[index];
              return LoteCard(
                lote: lote,
                isSelectionMode: _isSelectionMode,
                isSelected: _selectedLoteIds.contains(lote.id),
                onLongPress: () {
                  setState(() {
                    _isSelectionMode = true;
                    _selectedLoteIds.add(lote.id);
                  });
                },
                onTap: () {
                  if (_isSelectionMode) {
                    setState(() {
                      if (_selectedLoteIds.contains(lote.id)) {
                        _selectedLoteIds.remove(lote.id);
                      } else {
                        _selectedLoteIds.add(lote.id);
                      }
                    });
                  } else {
                    _navigateToExitForm(lote.id);
                  }
                },
              );
            },
          );
        },
      ),
      floatingActionButton: _isSelectionMode && _selectedLoteIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _procesarLotesSeleccionados,
              label: Text('Procesar Lotes'),
              icon: Icon(Icons.arrow_forward),
            )
          : null,
    );
  }
}
```

### 2. Cloud Functions

#### Configuración e Instalación
```bash
# Inicializar functions
cd functions
npm init -y
npm install firebase-functions@^6.4.0 firebase-admin@^11.11.1

# Crear index.js con las funciones
```

#### Implementación de Funciones
```javascript
// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// 1. Eliminar usuarios rechazados automáticamente
exports.deleteAuthUser = functions.firestore
  .document('users_pending_deletion/{userId}')
  .onCreate(async (snap, context) => {
    const userId = context.params.userId;
    const data = snap.data();
    
    try {
      // Eliminar de Firebase Auth
      await admin.auth().deleteUser(userId);
      
      // Actualizar estado
      await snap.ref.update({
        status: 'completed',
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
        error: null
      });
      
      // Log de auditoría
      await admin.firestore().collection('audit_logs').add({
        action: 'user_deleted',
        userId: userId,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        reason: data.reason || 'Solicitud rechazada',
        success: true
      });
      
      console.log(`Usuario ${userId} eliminado exitosamente`);
      
    } catch (error) {
      console.error(`Error eliminando usuario ${userId}:`, error);
      
      await snap.ref.update({
        status: 'failed',
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
        error: error.message
      });
      
      await admin.firestore().collection('audit_logs').add({
        action: 'user_deletion_failed',
        userId: userId,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        error: error.message,
        success: false
      });
    }
  });

// 2. Limpieza programada de registros antiguos
exports.cleanupOldDeletionRecords = functions.pubsub
  .schedule('every 24 hours')
  .timeZone('America/Mexico_City')
  .onRun(async (context) => {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    
    const snapshot = await admin.firestore()
      .collection('users_pending_deletion')
      .where('status', 'in', ['completed', 'failed'])
      .where('completedAt', '<', thirtyDaysAgo)
      .get();
    
    const batch = admin.firestore().batch();
    let count = 0;
    
    snapshot.forEach(doc => {
      batch.delete(doc.ref);
      count++;
    });
    
    if (count > 0) {
      await batch.commit();
      console.log(`Eliminados ${count} registros antiguos`);
    }
    
    return null;
  });

// 3. Función manual para administradores
exports.manualDeleteUser = functions.https.onCall(async (data, context) => {
  // Verificar autenticación
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Usuario no autenticado'
    );
  }
  
  // Verificar rol maestro
  const userDoc = await admin.firestore()
    .collection('maestros')
    .doc(context.auth.uid)
    .get();
  
  if (!userDoc.exists) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'No tienes permisos de maestro'
    );
  }
  
  const { userId, reason } = data;
  
  try {
    await admin.auth().deleteUser(userId);
    
    await admin.firestore().collection('audit_logs').add({
      action: 'manual_user_deletion',
      deletedBy: context.auth.uid,
      userId: userId,
      reason: reason,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    return { success: true, message: 'Usuario eliminado' };
    
  } catch (error) {
    throw new functions.https.HttpsError(
      'internal',
      `Error al eliminar usuario: ${error.message}`
    );
  }
});

// 4. Health check
exports.healthCheck = functions.https.onRequest((req, res) => {
  res.status(200).json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    functions: [
      'deleteAuthUser',
      'cleanupOldDeletionRecords',
      'manualDeleteUser',
      'healthCheck'
    ]
  });
});
```

#### Despliegue con Google Cloud Shell
```bash
# Solución para Windows (Git Bash conflict)
# 1. Abrir https://console.cloud.google.com
# 2. Activar Cloud Shell (icono terminal arriba derecha)
# 3. Clonar el repositorio o subir functions/

# En Cloud Shell:
cd functions
npm install
firebase use trazabilidad-ecoce
firebase deploy --only functions

# Verificar
curl https://us-central1-trazabilidad-ecoce.cloudfunctions.net/healthCheck
```

---

## Solución de Problemas Comunes

### 1. Error: No Firebase App '[DEFAULT]'

**Problema**: Intentar usar Firebase antes de inicializar plataforma

**Solución**:
```dart
// INCORRECTO - main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // NO HACER ESTO
  runApp(MyApp());
}

// CORRECTO - Después de seleccionar plataforma
class _LoginScreenState extends State<LoginScreen> {
  @override
  void initState() {
    super.initState();
    _initializePlatform();
  }
  
  Future<void> _initializePlatform() async {
    await _authService.initializeForPlatform(widget.platform);
  }
}
```

### 2. Error: Permission Denied en Firestore

**Problema**: Usuario no tiene permisos para leer/escribir

**Diagnóstico**:
```dart
// Verificar autenticación
final user = FirebaseAuth.instance.currentUser;
print('Usuario autenticado: ${user?.uid}');

// Verificar índices
// Si el error menciona índices, crear desde el link en consola
```

**Solución**: Actualizar reglas de seguridad
```javascript
// firestore.rules
match /lotes/{loteId}/{document=**} {
  allow read: if request.auth != null;
  allow write: if request.auth != null;
}
```

### 3. Error: Type Cast en Argumentos de Ruta

**Problema**: `'int' is not a subtype of type 'Map<String, dynamic>?'`

**Solución**:
```dart
// INCORRECTO
Navigator.pushNamed(context, '/reciclador_lotes', arguments: 1);

// CORRECTO
Navigator.pushNamed(
  context, 
  '/reciclador_lotes', 
  arguments: {'initialTab': 1}
);

// En main.dart - manejar ambos casos
case '/reciclador_lotes':
  final args = settings.arguments;
  int initialTab = 0;
  
  if (args is Map<String, dynamic>) {
    initialTab = args['initialTab'] ?? 0;
  } else if (args is int) {
    initialTab = args;
  }
  
  return MaterialPageRoute(
    builder: (_) => RecicladorAdministracionLotes(
      initialTab: initialTab,
    ),
  );
```

### 4. Megalotes No Visibles en Otros Dispositivos

**Problema**: Transformaciones usan filtro `where('usuario_id', isEqualTo: uid)`

**Análisis**: 
- Los índices compuestos con `usuario_id` requieren permisos específicos
- `collectionGroup` sin filtro de usuario funciona mejor

**Solución Temporal**:
```dart
// Cambiar query para no filtrar por usuario
Stream<List<TransformacionModel>> obtenerTransformaciones() {
  // Opción 1: Sin filtro (muestra todas)
  return _firestore
    .collection('transformaciones')
    .orderBy('fecha_inicio', descending: true)
    .snapshots()
    .map(...);
    
  // Opción 2: Filtrar en cliente
  return _firestore
    .collection('transformaciones')
    .snapshots()
    .map((snapshot) {
      final todas = snapshot.docs.map(...).toList();
      return todas.where((t) => t.usuarioId == _userUid).toList();
    });
}
```

### 5. Sublotes No Aparecen Después de Crear

**Problema**: Sublotes creados pero no visibles en lista

**Verificación**:
```dart
// 1. Verificar en Firebase Console que el sublote existe
// 2. Verificar proceso_actual del sublote
// 3. Verificar query en el servicio

// Debug en servicio
print('Buscando lotes con proceso: $proceso');
print('Excluyendo consumidos: true');
```

**Solución**: Asegurar que sublotes tienen estructura correcta
```dart
// Al crear sublote
batch.set(subloteRef, {
  'id': subloteId,
  'tipo_lote': 'derivado',
  'proceso_actual': 'reciclador', // CRÍTICO
  'consumido_en_transformacion': false, // CRÍTICO
  // ... resto de campos
});
```

### 6. Error al Subir Archivos a Storage

**Problema**: `[storage/unauthorized]` o archivos no accesibles

**Solución**:
1. Verificar reglas de Storage:
```javascript
match /ecoce/{allPaths=**} {
  allow read: if request.auth != null;
  allow write: if request.auth != null 
    && request.resource.size < 5 * 1024 * 1024;
}
```

2. Verificar ruta de almacenamiento:
```dart
// Usar rutas consistentes
final path = 'ecoce/usuarios/$userId/documentos/${DateTime.now().millisecondsSinceEpoch}_$fileName';
```

### 7. Problemas con QR Scanner

**Problema**: Cámara no se activa o escaneo duplicado

**Solución**:
```dart
class _SharedQRScannerScreenState extends State<SharedQRScannerScreen> {
  bool _hasScanned = false; // Evitar escaneo duplicado
  
  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return; // Debounce
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String code = barcodes.first.rawValue ?? '';
      if (code.isNotEmpty) {
        setState(() => _hasScanned = true);
        
        // Vibración y retorno
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop(code);
      }
    }
  }
}
```

---

## Patrones de Código y Mejores Prácticas

### 1. Manejo de Estados de Carga

```dart
class _MyScreenState extends State<MyScreen> {
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      // Cargar datos
      await _service.fetchData();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: BioWayColors.primaryGreen,
          ),
        ),
      );
    }
    
    if (_error != null) {
      return _buildErrorWidget();
    }
    
    return _buildContent();
  }
}
```

### 2. Uso Consistente de Colores

```dart
// NUNCA hardcodear colores
// INCORRECTO
Container(color: Color(0xFF4CAF50))

// CORRECTO
Container(color: BioWayColors.primaryGreen)

// Colores disponibles en utils/colors.dart
BioWayColors.primaryGreen    // Verde principal
BioWayColors.ecoceGreen     // Verde ECOCE
BioWayColors.pebdPink       // Rosa para PEBD
BioWayColors.ppPurple       // Morado para PP
BioWayColors.multilaminadoBrown // Café para Multi
```

### 3. Navegación y Prevención de Logout

```dart
// Todas las pantallas principales deben prevenir back
@override
Widget build(BuildContext context) {
  return PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) async {
      if (didPop) return;
      
      // Mostrar diálogo de confirmación
      final shouldExit = await DialogUtils.showConfirmDialog(
        context,
        title: '¿Cerrar sesión?',
        message: '¿Estás seguro de que deseas salir?',
      );
      
      if (shouldExit && context.mounted) {
        await _authService.signOut();
        Navigator.of(context).pushReplacementNamed('/login');
      }
    },
    child: Scaffold(...),
  );
}
```

### 4. Manejo de Formularios

```dart
class _MyFormState extends State<MyForm> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  bool _isSubmitting = false;
  
  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }
  
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      await _service.saveData(
        nombre: _nombreController.text.trim(),
      );
      
      if (mounted) {
        DialogUtils.showSuccessDialog(
          context,
          message: 'Datos guardados correctamente',
          onAccept: () => Navigator.pop(context),
        );
      }
    } catch (e) {
      if (mounted) {
        DialogUtils.showErrorDialog(
          context,
          message: 'Error: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
```

### 5. Streams y Dispose

```dart
class _MyWidgetState extends State<MyWidget> {
  StreamSubscription? _subscription;
  
  @override
  void initState() {
    super.initState();
    _subscription = _service.dataStream.listen((data) {
      if (mounted) {
        setState(() {
          // Actualizar estado
        });
      }
    });
  }
  
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
```

---

## Deployment y Producción

### 1. Preparación para Release

```bash
# Limpiar y verificar
flutter clean
flutter pub get
flutter analyze

# Build para Android
flutter build apk --release
flutter build appbundle --release

# Build con ofuscación
flutter build apk --release --obfuscate --split-debug-info=./symbols
```

### 2. Configuración de Firmas (Android)

```gradle
// android/app/build.gradle
android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
}
```

### 3. Despliegue de Reglas Firebase

```bash
# Firestore rules
firebase deploy --only firestore:rules

# Storage rules  
firebase deploy --only storage:rules

# Functions
firebase deploy --only functions

# Todo junto
firebase deploy
```

### 4. Configuración de Índices

```bash
# Crear índices desde enlaces o CLI
firebase deploy --only firestore:indexes
```

---

## Mantenimiento y Monitoreo

### 1. Monitoreo de Cloud Functions

```bash
# Ver logs en tiempo real
firebase functions:log

# Ver logs de función específica
firebase functions:log --only deleteAuthUser

# Últimas 50 entradas
firebase functions:log --lines 50
```

### 2. Monitoreo de Firestore

- Firebase Console → Firestore → Usage
- Verificar:
  - Lecturas/Escrituras diarias
  - Almacenamiento usado
  - Ancho de banda

### 3. Análisis de Crashes

```dart
// Configurar Firebase Crashlytics
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Capturar errores de Flutter
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  
  // Capturar errores asíncronos
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  
  runApp(MyApp());
}
```

### 4. Backups y Recuperación

```bash
# Exportar datos de Firestore
gcloud firestore export gs://[BUCKET_NAME]

# Importar datos
gcloud firestore import gs://[BUCKET_NAME]/[EXPORT_PREFIX]/
```

---

## Casos de Uso Específicos

### 1. Agregar Nuevo Tipo de Usuario

1. Actualizar modelo de datos:
```dart
// models/user_type.dart
enum UserType {
  centroAcopio('A', 'Centro de Acopio'),
  plantaSeparacion('P', 'Planta de Separación'),
  nuevoTipo('N', 'Nuevo Tipo'); // AGREGAR
}
```

2. Crear pantallas específicas:
```
lib/screens/ecoce/nuevo_tipo/
├── nuevo_tipo_inicio.dart
├── nuevo_tipo_formularios.dart
└── nuevo_tipo_widgets.dart
```

3. Actualizar rutas:
```dart
// main.dart
case '/nuevo_tipo_inicio':
  return MaterialPageRoute(
    builder: (_) => NuevoTipoInicio(),
  );
```

4. Actualizar reglas de seguridad:
```javascript
function isNuevoTipo() {
  return getUserType() == 'N';
}
```

### 2. Modificar Flujo de Aprobación

```dart
// services/firebase/ecoce_profile_service.dart
Future<void> aprobarSolicitud(String solicitudId) async {
  // 1. Agregar validaciones personalizadas
  if (!_validarDocumentosCompletos(solicitud)) {
    throw Exception('Documentos incompletos');
  }
  
  // 2. Agregar notificaciones
  await _notificationService.notifyUserApproved(userId);
  
  // 3. Agregar logs adicionales
  await _auditService.logApproval(solicitudId, _currentUserId);
}
```

### 3. Extender Sistema de QR

```dart
// utils/qr_utils.dart
class QRUtils {
  // Agregar nuevo tipo de QR
  static String generateCustomQR(String type, String id) {
    return '$type-${DateTime.now().millisecondsSinceEpoch}-$id';
  }
  
  // Parser para nuevo tipo
  static Map<String, String>? parseCustomQR(String qrCode) {
    if (qrCode.startsWith('CUSTOM-')) {
      final parts = qrCode.split('-');
      return {
        'type': 'custom',
        'timestamp': parts[1],
        'id': parts[2],
      };
    }
    return null;
  }
}
```

---

## Referencias Rápidas

### Comandos Frecuentes

```bash
# Desarrollo
flutter run -d emulator-5554
flutter run -v                    # Verbose para debug
flutter logs                      # Ver logs del dispositivo

# Limpieza
flutter clean && flutter pub get
cd ios && pod install            # Solo iOS

# Testing
flutter test
flutter test --coverage
flutter drive --target=test_driver/app.dart

# Análisis
flutter analyze
dart fix --apply                 # Aplicar fixes automáticos
```

### Estructura de Archivos Clave

```
app/
├── lib/
│   ├── main.dart                # Punto de entrada
│   ├── services/
│   │   ├── firebase/           # Servicios Firebase
│   │   └── *.dart              # Otros servicios
│   ├── models/                 # Modelos de datos
│   ├── screens/                # Pantallas UI
│   └── utils/                  # Utilidades
├── android/
│   └── app/
│       ├── google-services.json # Config Firebase Android
│       └── build.gradle        # Configuración build
├── ios/
│   └── Runner/
│       └── GoogleService-Info.plist # Config Firebase iOS
├── functions/                   # Cloud Functions
│   ├── index.js
│   └── package.json
├── firestore.rules             # Reglas seguridad Firestore
├── storage.rules               # Reglas seguridad Storage
└── docs/                       # Documentación
    ├── ARQUITECTURA_Y_SISTEMA.md
    ├── FLUJOS_Y_PROCESOS.md
    └── GUIA_IMPLEMENTACION.md
```

### URLs y Endpoints

```yaml
Firebase Console:
  Project: https://console.firebase.google.com/project/trazabilidad-ecoce
  
Cloud Functions:
  Health Check: https://us-central1-trazabilidad-ecoce.cloudfunctions.net/healthCheck
  
Storage Buckets:
  ECOCE: gs://trazabilidad-ecoce.firebasestorage.app
```

### Contactos y Recursos

- Documentación Flutter: https://docs.flutter.dev
- Firebase Docs: https://firebase.google.com/docs
- Proyecto GitHub: [URL del repositorio]

---

*Documento actualizado: 2025-01-29*  
*Versión: 1.0.0*  
*Sistema de Trazabilidad BioWay México*