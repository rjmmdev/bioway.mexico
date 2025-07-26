# API y Servicios - Documentación Técnica

> **Última actualización**: 2025-01-26  
> **Versión**: 1.0.0  
> Documentación completa de todos los servicios y APIs del sistema BioWay México

## Índice

1. [Arquitectura de Servicios](#arquitectura-de-servicios)
2. [Servicios Core](#servicios-core)
3. [Servicios de Autenticación](#servicios-de-autenticación)
4. [Servicios de Usuario](#servicios-de-usuario)
5. [Servicios de Almacenamiento](#servicios-de-almacenamiento)
6. [Servicios Utilitarios](#servicios-utilitarios)
7. [Modelos de Datos](#modelos-de-datos)
8. [Manejo de Errores](#manejo-de-errores)
9. [Mejores Prácticas](#mejores-prácticas)

---

## Arquitectura de Servicios

### Estructura General

```
lib/services/
├── firebase/
│   ├── firebase_manager.dart       # Gestión multi-tenant
│   ├── firebase_config.dart        # Configuraciones por plataforma
│   ├── auth_service.dart           # Autenticación multi-plataforma
│   └── firebase_storage_service.dart # Almacenamiento de archivos
├── lote_service.dart               # Gestión de lotes (legacy)
├── lote_unificado_service.dart     # Sistema unificado de lotes
├── carga_transporte_service.dart   # Gestión de cargas y entregas
├── user_session_service.dart       # Gestión de sesión local
├── ecoce_profile_service.dart      # Perfiles de usuarios ECOCE
├── document_service.dart           # Gestión de documentos
└── image_service.dart              # Compresión de imágenes
```

### Principios de Diseño

1. **Singleton Pattern**: Servicios como instancias únicas
2. **Dependency Injection**: Inyección manual de dependencias
3. **Error Handling**: Try-catch en todas las operaciones Firebase
4. **Async/Await**: Todas las operaciones son asíncronas
5. **Streams**: Para datos en tiempo real

---

## Servicios Core

### LoteUnificadoService

**Ubicación**: `lib/services/lote_unificado_service.dart`

**Propósito**: Gestión completa del ciclo de vida de lotes con modelo unificado.

#### Métodos Principales

##### crearLoteDesdeOrigen

```dart
Future<String> crearLoteDesdeOrigen({
  required String tipoMaterial,
  required double pesoInicial,
  required String presentacion,
  required String fuente,
  required String operador,
  required List<String> fotosUrls,
  String? observaciones,
  Map<String, double>? ubicacion,
}) async
```

**Descripción**: Crea un nuevo lote desde origen con ID único autogenerado.

**Parámetros**:
- `tipoMaterial`: PEBD, PP, o MULTILAMINADO
- `pesoInicial`: Peso en kilogramos (double)
- `presentacion`: Forma física del material
- `fuente`: Origen del material
- `operador`: Nombre del operador
- `fotosUrls`: Lista de URLs de fotos (1-3)
- `observaciones`: Texto opcional
- `ubicacion`: Lat/Lng opcional

**Retorna**: `String` - ID del lote creado

**Ejemplo de uso**:
```dart
final loteId = await _loteUnificadoService.crearLoteDesdeOrigen(
  tipoMaterial: 'PEBD',
  pesoInicial: 150.5,
  presentacion: 'Pacas',
  fuente: 'Recolección urbana',
  operador: 'Juan Pérez',
  fotosUrls: ['url1', 'url2'],
  observaciones: 'Material limpio',
  ubicacion: {'lat': 19.4326, 'lng': -99.1332},
);
```

##### obtenerLotePorId

```dart
Future<LoteUnificadoModel?> obtenerLotePorId(String loteId) async
```

**Descripción**: Obtiene un lote completo con todos sus procesos.

**Implementación interna**:
1. Consulta documento principal
2. Obtiene subcolecciones de cada proceso
3. Construye modelo unificado
4. Calcula peso actual dinámicamente

##### actualizarProcesoActual

```dart
Future<void> actualizarProcesoActual({
  required String loteId,
  required String nuevoProceso,
}) async
```

**Descripción**: Actualiza el proceso actual del lote (transferencia unidireccional).

**Uso**: Para pickups inmediatos sin confirmación del origen.

##### transferirLote

```dart
Future<void> transferirLote({
  required String loteId,
  required String procesoOrigen,
  required String procesoDestino,
  required Map<String, dynamic> datosIniciales,
}) async
```

**Descripción**: Transfiere un lote entre procesos con datos iniciales.

**Lógica de transferencia**:
```dart
switch (procesoDestino) {
  case 'transporte':
    // Determina fase automáticamente
    final fase = procesoOrigen == 'origen' ? 'fase_1' : 'fase_2';
    await _transferirATransporte(loteId, datosIniciales, fase);
    break;
  case 'reciclador':
    await _transferirAReciclador(loteId, datosIniciales);
    break;
  case 'transformador':
    await _transferirATransformador(loteId, datosIniciales);
    break;
}
```

##### registrarAnalisisLaboratorio

```dart
Future<String> registrarAnalisisLaboratorio({
  required String loteId,
  required double pesoMuestra,
  required String folioLaboratorio,
  required String firmaOperador,
  required List<String> evidenciasFoto,
  String? certificado,
}) async
```

**Descripción**: Registra análisis de laboratorio sin transferir propiedad.

**Características especiales**:
- No modifica `proceso_actual`
- Peso se resta automáticamente del disponible
- Permite múltiples análisis por lote
- Certificado puede agregarse posteriormente

##### Stream Methods

```dart
// Obtener lotes por proceso actual
Stream<List<LoteUnificadoModel>> obtenerLotesPorProceso(
  String proceso, {
  String? userId,
  String? estado,
})

// Obtener lotes creados por usuario
Stream<List<LoteUnificadoModel>> obtenerLotesOrigen(String userId)

// Obtener lotes con análisis de laboratorio
Stream<List<LoteUnificadoModel>> obtenerLotesConAnalisisLaboratorio()

// Obtener todos los lotes (repositorio)
Stream<List<LoteUnificadoModel>> obtenerTodosLotesRepositorio({
  String? searchQuery,
  String? tipoMaterial,
  String? procesoActual,
  DateTime? fechaInicio,
  DateTime? fechaFin,
})
```

**Características de Streams**:
- Actualizaciones en tiempo real
- Filtrado del lado del cliente cuando necesario
- Manejo automático de cambios en Firebase

---

### CargaTransporteService

**Ubicación**: `lib/services/carga_transporte_service.dart`

**Propósito**: Gestión de cargas, entregas y logística de transporte.

#### Métodos Principales

##### crearCarga

```dart
Future<String> crearCarga({
  required List<String> lotesIds,
  required String transportistaId,
  required String transportistaFolio,
  required String origenId,
  required String origenFolio,
  required double pesoTotal,
}) async
```

**Descripción**: Crea una carga agrupando múltiples lotes.

**Proceso interno**:
1. Valida que todos los lotes existen
2. Actualiza `proceso_actual = 'transporte'` para cada lote
3. Crea documento en `cargas_transporte/`
4. Genera ID único para la carga

##### crearEntrega

```dart
Future<String> crearEntrega({
  required List<String> lotesIds,
  required String destinatarioId,
  required String destinatarioFolio,
  required String tipoDestinatario,
  required double pesoTotalEntregado,
  required Map<String, dynamic> datosTransporte,
}) async
```

**Descripción**: Crea entrega temporal con validez de 15 minutos.

**Estructura de entrega**:
```dart
{
  'id': entregaId,
  'lotes_ids': lotesIds,
  'destinatario_id': destinatarioId,
  'destinatario_folio': destinatarioFolio,
  'tipo_destinatario': tipoDestinatario,
  'transportista_id': currentUserId,
  'fecha_creacion': FieldValue.serverTimestamp(),
  'valido_hasta': DateTime.now().add(Duration(minutes: 15)),
  'peso_total_entregado': pesoTotalEntregado,
  'datos_transporte': datosTransporte,
  'usado': false,
}
```

##### procesarEntregaQR

```dart
Future<Map<String, dynamic>> procesarEntregaQR(String entregaId) async
```

**Descripción**: Procesa QR de entrega y valida vigencia.

**Validaciones**:
- Entrega existe
- No ha sido usada
- Está dentro del período de validez
- Destinatario coincide con usuario actual

##### obtenerCargasTransportista

```dart
Stream<List<Map<String, dynamic>>> obtenerCargasTransportista(
  String transportistaId, {
  String estado = 'en_transito',
})
```

**Descripción**: Stream de cargas del transportista.

---

## Servicios de Autenticación

### FirebaseAuthService

**Ubicación**: `lib/services/firebase/auth_service.dart`

**Propósito**: Autenticación multi-tenant para BioWay y ECOCE.

#### Métodos Principales

##### initializeForPlatform

```dart
Future<void> initializeForPlatform(FirebasePlatform platform) async
```

**Descripción**: Inicializa Firebase para la plataforma seleccionada.

**Importante**: No inicializar en `main.dart`, cada plataforma se inicializa al seleccionarla.

##### signIn

```dart
Future<UserCredential?> signIn({
  required String email,
  required String password,
}) async
```

**Descripción**: Autenticación con email y contraseña.

**Manejo de errores**:
```dart
try {
  return await _auth.signInWithEmailAndPassword(
    email: email,
    password: password,
  );
} on FirebaseAuthException catch (e) {
  switch (e.code) {
    case 'user-not-found':
      throw 'Usuario no encontrado';
    case 'wrong-password':
      throw 'Contraseña incorrecta';
    case 'invalid-email':
      throw 'Email inválido';
    default:
      throw 'Error de autenticación: ${e.message}';
  }
}
```

##### createUser

```dart
Future<User?> createUser({
  required String email,
  required String password,
  required String displayName,
}) async
```

**Descripción**: Crea nuevo usuario en Firebase Auth.

**Uso**: Solo por usuario Maestro al aprobar solicitudes.

##### signOut

```dart
Future<void> signOut() async
```

**Descripción**: Cierra sesión y limpia datos locales.

---

## Servicios de Usuario

### UserSessionService

**Ubicación**: `lib/services/user_session_service.dart`

**Propósito**: Gestión de sesión y datos del usuario actual.

#### Implementación

```dart
class UserSessionService {
  static final UserSessionService _instance = UserSessionService._internal();
  factory UserSessionService() => _instance;
  UserSessionService._internal();

  Map<String, dynamic>? _userData;
  String? _userRole;
  String? _platform;

  // Guardar datos de sesión
  Future<void> saveUserSession({
    required Map<String, dynamic> userData,
    required String userRole,
    required String platform,
  }) async {
    _userData = userData;
    _userRole = userRole;
    _platform = platform;
    
    // Persistir en SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userData', jsonEncode(userData));
    await prefs.setString('userRole', userRole);
    await prefs.setString('platform', platform);
  }

  // Obtener datos del usuario
  Map<String, dynamic>? getUserData() => _userData;
  
  // Obtener folio del usuario actual
  String? getCurrentUserFolio() => _userData?['folio'];
  
  // Obtener ID del usuario actual
  String? getCurrentUserId() => _userData?['uid'];
  
  // Limpiar sesión
  Future<void> clearSession() async {
    _userData = null;
    _userRole = null;
    _platform = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
```

### EcoceProfileService

**Ubicación**: `lib/services/ecoce_profile_service.dart`

**Propósito**: Gestión de perfiles de usuarios ECOCE.

#### Métodos Principales

##### obtenerPerfilPorFolio

```dart
Future<Map<String, dynamic>?> obtenerPerfilPorFolio(String folio) async
```

**Descripción**: Busca usuario por folio único.

**Proceso**:
1. Determina tipo de usuario por prefijo del folio
2. Construye path según tipo
3. Consulta documento específico

##### crearSolicitudCuenta

```dart
Future<void> crearSolicitudCuenta({
  required String tipoCuenta,
  required Map<String, dynamic> datosPerfil,
  required Map<String, String> documentosUrls,
}) async
```

**Descripción**: Crea solicitud de cuenta nueva.

##### aprobarSolicitud

```dart
Future<String> aprobarSolicitud(String solicitudId) async
```

**Descripción**: Aprueba solicitud y crea usuario (solo Maestro).

**Proceso**:
1. Obtiene datos de la solicitud
2. Crea usuario en Firebase Auth
3. Asigna folio secuencial
4. Crea perfil en ubicación correcta
5. Actualiza índice en `ecoce_profiles/`

---

## Servicios de Almacenamiento

### FirebaseStorageService

**Ubicación**: `lib/services/firebase/firebase_storage_service.dart`

**Propósito**: Gestión de archivos en Firebase Storage.

#### Métodos Principales

##### uploadFile

```dart
Future<String?> uploadFile(
  File file,
  String path, {
  Function(double)? onProgress,
}) async
```

**Descripción**: Sube archivo a Firebase Storage.

**Ejemplo**:
```dart
final url = await _storageService.uploadFile(
  imageFile,
  'evidencias/${DateTime.now().millisecondsSinceEpoch}.jpg',
  onProgress: (progress) {
    print('Upload progress: ${progress * 100}%');
  },
);
```

##### uploadBase64Image

```dart
Future<String?> uploadBase64Image(
  String base64String,
  String fileName,
) async
```

**Descripción**: Sube imagen desde string base64 (usado para firmas).

**Proceso**:
1. Limpia header base64 si existe
2. Decodifica a bytes
3. Sube como imagen PNG
4. Retorna URL de descarga

##### deleteFile

```dart
Future<bool> deleteFile(String fileUrl) async
```

**Descripción**: Elimina archivo de Storage.

### DocumentService

**Ubicación**: `lib/services/document_service.dart`

**Propósito**: Gestión especializada de documentos con compresión.

#### uploadDocument

```dart
Future<String?> uploadDocument(
  File file,
  String documentType,
  String userId, {
  int maxSizeMB = 5,
}) async
```

**Descripción**: Sube documento con validación de tamaño.

**Validaciones**:
- Tamaño máximo: 5MB (configurable)
- Tipos permitidos: PDF, imágenes
- Compresión automática si es imagen

### ImageService

**Ubicación**: `lib/services/image_service.dart`

**Propósito**: Compresión y optimización de imágenes.

#### optimizeImageForDatabase

```dart
static Future<String?> optimizeImageForDatabase(
  File imageFile, {
  int targetSizeKB = 50,
  int quality = 85,
}) async
```

**Descripción**: Comprime imagen a tamaño objetivo.

**Algoritmo**:
1. Lee imagen original
2. Aplica compresión inicial
3. Si excede tamaño, reduce calidad iterativamente
4. Retorna base64 de imagen optimizada

**Ejemplo**:
```dart
final base64Image = await ImageService.optimizeImageForDatabase(
  selectedImage,
  targetSizeKB: 50, // Objetivo 50KB
);
```

---

## Servicios Utilitarios

### Utilidades Incluidas

#### QRUtils

```dart
class QRUtils {
  // Generar QR de lote
  static String generateLoteQR(String tipoMaterial, String loteId) {
    return 'LOTE-$tipoMaterial-$loteId';
  }
  
  // Extraer ID de lote del QR
  static String? extractLoteIdFromQR(String qrCode) {
    if (!qrCode.startsWith('LOTE-')) return null;
    final parts = qrCode.split('-');
    if (parts.length < 3) return null;
    return parts.sublist(2).join('-');
  }
  
  // Generar QR de usuario
  static String generateUserQR(String userType, String userId) {
    return 'USER-$userType-$userId';
  }
  
  // Validar formato QR
  static bool isValidQRFormat(String qrCode) {
    final prefixes = ['USER', 'LOTE', 'CARGA', 'ENTREGA'];
    return prefixes.any((prefix) => qrCode.startsWith('$prefix-'));
  }
}
```

#### FormatUtils

```dart
class FormatUtils {
  // Formato de fecha: "21/07/2025"
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
  
  // Formato fecha y hora: "21/07/2025 14:30"
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }
  
  // Formato de peso: "150.5 kg"
  static String formatWeight(double weight) {
    return '${weight.toStringAsFixed(1)} kg';
  }
  
  // Formato de moneda: "$1,234.56"
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
    );
    return formatter.format(amount);
  }
}
```

#### ValidationUtils

```dart
class ValidationUtils {
  // Email válido
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
  
  // RFC válido
  static bool isValidRFC(String rfc) {
    return RegExp(r'^[A-ZÑ&]{3,4}\d{6}[A-Z\d]{3}$').hasMatch(rfc);
  }
  
  // Peso válido
  static bool isValidWeight(String weight) {
    final value = double.tryParse(weight);
    return value != null && value > 0 && value < 10000;
  }
}
```

#### DialogUtils

```dart
class DialogUtils {
  // Diálogo de éxito
  static Future<void> showSuccessDialog(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onAccept,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onAccept?.call();
            },
            child: Text('Aceptar'),
          ),
        ],
      ),
    );
  }
  
  // Diálogo de error
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String error,
  }) async {
    // Implementación similar con ícono de error
  }
  
  // Diálogo de confirmación
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
```

---

## Modelos de Datos

### Estructura de Modelos

```
lib/models/
├── lote_unificado_model.dart      # Modelo principal unificado
├── datos_generales_lote.dart      # Información general del lote
├── proceso_origen_data.dart       # Datos específicos de origen
├── proceso_transporte_data.dart   # Datos de transporte (fases)
├── proceso_reciclador_data.dart   # Datos del reciclador
├── analisis_laboratorio_data.dart # Datos de análisis
├── proceso_transformador_data.dart # Datos del transformador
└── user_models.dart               # Modelos de usuario
```

### Ejemplo: LoteUnificadoModel

```dart
@immutable
class LoteUnificadoModel {
  final String id;
  final DatosGeneralesLote datosGenerales;
  final ProcesoOrigenData? origen;
  final Map<String, ProcesoTransporteData> transporteFases;
  final ProcesoRecicladorData? reciclador;
  final List<AnalisisLaboratorioData> analisisLaboratorio;
  final ProcesoTransformadorData? transformador;

  const LoteUnificadoModel({
    required this.id,
    required this.datosGenerales,
    this.origen,
    required this.transporteFases,
    this.reciclador,
    required this.analisisLaboratorio,
    this.transformador,
  });

  // Factory desde Firestore
  factory LoteUnificadoModel.fromFirestore(
    String id,
    Map<String, dynamic> datosGenerales,
    // ... otros datos
  ) {
    return LoteUnificadoModel(
      id: id,
      datosGenerales: DatosGeneralesLote.fromMap(datosGenerales),
      // ... mapeo de otros campos
    );
  }
  
  // Conversión a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'datosGenerales': datosGenerales.toMap(),
      // ... otros campos
    };
  }
  
  // Getters computados
  double get pesoActual => _calcularPesoActual();
  
  String get procesoActual => datosGenerales.procesoActual;
  
  bool get estaEnTransito => procesoActual == 'transporte';
  
  // Métodos helper
  bool tieneProcesoCompleto(String proceso) {
    switch (proceso) {
      case 'origen':
        return origen != null;
      case 'reciclador':
        return reciclador?.salida != null;
      case 'transformador':
        return transformador?.especificaciones?['estado'] == 'completado';
      default:
        return false;
    }
  }
}
```

---

## Manejo de Errores

### Estrategia General

1. **Try-Catch en servicios**: Todas las operaciones Firebase
2. **Mensajes user-friendly**: Traducir errores técnicos
3. **Logging**: Registrar errores para debugging
4. **Fallbacks**: Valores por defecto cuando sea posible

### Ejemplo de Implementación

```dart
Future<String?> uploadDocument(File file) async {
  try {
    // Validación previa
    if (!file.existsSync()) {
      throw 'El archivo no existe';
    }
    
    final fileSize = file.lengthSync();
    if (fileSize > 5 * 1024 * 1024) {
      throw 'El archivo excede el tamaño máximo de 5MB';
    }
    
    // Operación principal
    final ref = FirebaseStorage.instance
        .ref()
        .child('documents/${DateTime.now().millisecondsSinceEpoch}');
    
    final uploadTask = ref.putFile(file);
    
    // Monitoreo de progreso
    uploadTask.snapshotEvents.listen(
      (TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('Upload progress: ${(progress * 100).toStringAsFixed(0)}%');
      },
      onError: (error) {
        print('Error durante upload: $error');
      },
    );
    
    // Esperar finalización
    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();
    
    return downloadUrl;
    
  } on FirebaseException catch (e) {
    // Errores específicos de Firebase
    print('Firebase error: ${e.code} - ${e.message}');
    
    switch (e.code) {
      case 'storage/unauthorized':
        throw 'No tienes permisos para subir archivos';
      case 'storage/canceled':
        throw 'La subida fue cancelada';
      case 'storage/unknown':
        throw 'Error desconocido al subir archivo';
      default:
        throw 'Error al subir archivo: ${e.message}';
    }
    
  } catch (e) {
    // Otros errores
    print('Error general: $e');
    throw 'Error al procesar el archivo';
  }
}
```

### Códigos de Error Comunes

#### Firebase Auth
- `user-not-found`: Usuario no existe
- `wrong-password`: Contraseña incorrecta
- `email-already-in-use`: Email ya registrado
- `weak-password`: Contraseña muy débil
- `invalid-email`: Formato de email inválido

#### Firestore
- `permission-denied`: Sin permisos de lectura/escritura
- `not-found`: Documento no existe
- `already-exists`: Documento ya existe
- `resource-exhausted`: Límite de cuota excedido

#### Storage
- `storage/unauthorized`: Sin permisos
- `storage/canceled`: Operación cancelada
- `storage/object-not-found`: Archivo no existe
- `storage/bucket-not-found`: Bucket no configurado

---

## Mejores Prácticas

### 1. Inicialización de Servicios

```dart
class MyScreen extends StatefulWidget {
  @override
  _MyScreenState createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  // Servicios como variables de instancia
  final _loteService = LoteUnificadoService();
  final _userSession = UserSessionService();
  final _storageService = FirebaseStorageService();
  
  // Streams
  StreamSubscription? _lotesSubscription;
  
  @override
  void initState() {
    super.initState();
    _initializeData();
  }
  
  @override
  void dispose() {
    // Siempre cancelar subscripciones
    _lotesSubscription?.cancel();
    super.dispose();
  }
}
```

### 2. Manejo de Streams

```dart
// CORRECTO: Stream con manejo de errores
Stream<List<LoteModel>> getLotes() {
  return _firestore
      .collection('lotes')
      .where('proceso_actual', isEqualTo: 'origen')
      .snapshots()
      .handleError((error) {
        print('Error en stream: $error');
        return Stream.value([]);
      })
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => LoteModel.fromFirestore(doc))
            .toList();
      });
}

// INCORRECTO: Sin manejo de errores
Stream<List<LoteModel>> getLotes() {
  return _firestore
      .collection('lotes')
      .snapshots()
      .map((snapshot) => 
          snapshot.docs.map((doc) => LoteModel.fromFirestore(doc)).toList());
}
```

### 3. Operaciones Batch

```dart
// Para operaciones múltiples, usar batch
Future<void> actualizarMultiplesLotes(List<String> loteIds) async {
  final batch = _firestore.batch();
  
  for (final loteId in loteIds) {
    final ref = _firestore
        .collection('lotes')
        .doc(loteId)
        .collection('datos_generales')
        .doc('info');
        
    batch.update(ref, {
      'proceso_actual': 'transporte',
      'fecha_actualizacion': FieldValue.serverTimestamp(),
    });
  }
  
  // Commit único para todas las operaciones
  await batch.commit();
}
```

### 4. Cacheo Local

```dart
class CachedDataService {
  // Cache en memoria
  final Map<String, dynamic> _cache = {};
  final Duration _cacheValidity = Duration(minutes: 5);
  
  Future<T?> getCachedOrFetch<T>(
    String key,
    Future<T> Function() fetcher,
  ) async {
    // Verificar cache
    final cached = _cache[key];
    if (cached != null && 
        DateTime.now().difference(cached['timestamp']) < _cacheValidity) {
      return cached['data'] as T;
    }
    
    // Fetch nuevo
    try {
      final data = await fetcher();
      _cache[key] = {
        'data': data,
        'timestamp': DateTime.now(),
      };
      return data;
    } catch (e) {
      // Si hay error, retornar cache expirado si existe
      return cached?['data'] as T?;
    }
  }
}
```

### 5. Validación de Datos

```dart
// Validar antes de enviar a Firebase
class LoteValidator {
  static Map<String, String?> validate(Map<String, dynamic> data) {
    final errors = <String, String?>{};
    
    // Peso
    final peso = data['peso'] as double?;
    if (peso == null || peso <= 0) {
      errors['peso'] = 'El peso debe ser mayor a 0';
    } else if (peso > 10000) {
      errors['peso'] = 'El peso no puede exceder 10,000 kg';
    }
    
    // Material
    final material = data['tipoMaterial'] as String?;
    if (material == null || material.isEmpty) {
      errors['tipoMaterial'] = 'Debe seleccionar un tipo de material';
    } else if (!['PEBD', 'PP', 'MULTILAMINADO'].contains(material)) {
      errors['tipoMaterial'] = 'Tipo de material inválido';
    }
    
    // Fotos
    final fotos = data['fotos'] as List?;
    if (fotos == null || fotos.isEmpty) {
      errors['fotos'] = 'Debe agregar al menos una foto';
    } else if (fotos.length > 3) {
      errors['fotos'] = 'Máximo 3 fotos permitidas';
    }
    
    return errors;
  }
}
```

### 6. Testing de Servicios

```dart
// test/services/lote_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class MockFirestore extends Mock implements FirebaseFirestore {}

void main() {
  group('LoteUnificadoService', () {
    late LoteUnificadoService service;
    late MockFirestore mockFirestore;
    
    setUp(() {
      mockFirestore = MockFirestore();
      service = LoteUnificadoService(firestore: mockFirestore);
    });
    
    test('crearLoteDesdeOrigen should return lote ID', () async {
      // Arrange
      const expectedId = 'test-lote-123';
      when(mockFirestore.collection('lotes').doc())
          .thenReturn(MockDocumentReference(expectedId));
      
      // Act
      final result = await service.crearLoteDesdeOrigen(
        tipoMaterial: 'PEBD',
        pesoInicial: 100.0,
        presentacion: 'Pacas',
        fuente: 'Recolección',
        operador: 'Test User',
        fotosUrls: ['url1'],
      );
      
      // Assert
      expect(result, equals(expectedId));
    });
  });
}
```

---

## Conclusión

Esta documentación cubre todos los servicios principales del sistema BioWay México. Los servicios están diseñados para ser:

- **Modulares**: Cada servicio tiene una responsabilidad específica
- **Reutilizables**: Pueden usarse en diferentes partes de la app
- **Testables**: Inyección de dependencias facilita testing
- **Escalables**: Preparados para crecimiento futuro
- **Mantenibles**: Código claro y bien documentado

Para cambios o nuevas funcionalidades, seguir los patrones establecidos y actualizar esta documentación.

---

*Última actualización: 2025-01-26*  
*Versión: 1.0.0*