# Guía de Solución de Problemas - BioWay México

> **Última actualización**: 2025-01-26  
> **Versión**: 1.0.0  
> Guía completa para resolver problemas comunes en el sistema

## Índice

1. [Problemas de Instalación](#problemas-de-instalación)
2. [Errores de Firebase](#errores-de-firebase)
3. [Problemas de Autenticación](#problemas-de-autenticación)
4. [Errores de QR Scanner](#errores-de-qr-scanner)
5. [Problemas de Transferencia](#problemas-de-transferencia)
6. [Errores de UI/UX](#errores-de-uiux)
7. [Problemas de Rendimiento](#problemas-de-rendimiento)
8. [Errores de Compilación](#errores-de-compilación)
9. [Problemas Específicos por Usuario](#problemas-específicos-por-usuario)
10. [Herramientas de Debugging](#herramientas-de-debugging)

---

## Problemas de Instalación

### Error: "Flutter SDK not found"

**Síntomas**:
```
'flutter' is not recognized as an internal or external command
```

**Solución**:
1. Verificar instalación de Flutter:
   ```bash
   # Agregar Flutter al PATH
   export PATH="$PATH:/path/to/flutter/bin"
   ```

2. En Windows:
   - Panel de Control → Sistema → Configuración avanzada
   - Variables de entorno → PATH → Agregar ruta de Flutter

3. Verificar instalación:
   ```bash
   flutter doctor
   ```

### Error: "No devices available"

**Síntomas**:
```
No connected devices available
```

**Soluciones**:

1. **Android**:
   - Habilitar modo desarrollador en dispositivo
   - Habilitar depuración USB
   - Instalar drivers ADB si es necesario
   
2. **Emulador**:
   ```bash
   # Listar emuladores
   flutter emulators
   
   # Crear emulador
   flutter emulators --create
   
   # Lanzar emulador específico
   flutter emulators --launch emulator-5554
   ```

### Error: "Gradle build failed"

**Síntomas**:
```
FAILURE: Build failed with an exception
```

**Soluciones**:

1. Limpiar cache:
   ```bash
   cd android
   ./gradlew clean
   cd ..
   flutter clean
   flutter pub get
   ```

2. Actualizar Gradle:
   ```gradle
   // android/gradle/wrapper/gradle-wrapper.properties
   distributionUrl=https://services.gradle.org/distributions/gradle-7.5-all.zip
   ```

3. Verificar versión de Java:
   ```bash
   java -version  # Debe ser Java 11 o superior
   ```

---

## Errores de Firebase

### Error: "No Firebase App has been created"

**Síntomas**:
```
[core/no-app] No Firebase App '[DEFAULT]' has been created
```

**Causa**: Intentar usar Firebase antes de inicializar la plataforma.

**Solución**:

1. Verificar que se seleccionó una plataforma:
   ```dart
   // INCORRECTO - En main.dart
   await Firebase.initializeApp();
   
   // CORRECTO - En login screen después de seleccionar plataforma
   await _authService.initializeForPlatform(FirebasePlatform.ecoce);
   ```

2. Verificar archivo `google-services.json`:
   - Ubicación: `android/app/google-services.json`
   - Debe contener configuración de ECOCE

### Error: "Permission denied" en Firestore

**Síntomas**:
```
[cloud_firestore/permission-denied] The caller does not have permission
```

**Soluciones**:

1. Verificar autenticación:
   ```dart
   final user = FirebaseAuth.instance.currentUser;
   if (user == null) {
     // Usuario no autenticado
   }
   ```

2. Revisar reglas de Firestore:
   ```javascript
   // firestore.rules
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       // Usuarios autenticados pueden leer/escribir
       match /{document=**} {
         allow read, write: if request.auth != null;
       }
     }
   }
   ```

3. Verificar estructura de colección:
   ```dart
   // Ruta correcta
   FirebaseFirestore.instance
     .collection('lotes')
     .doc(loteId)
     .collection('datos_generales')
     .doc('info');
   ```

### Error: "Storage/unauthorized"

**Síntomas**:
```
[storage/unauthorized] User is not authorized to perform the desired action
```

**Solución**:

1. Actualizar reglas de Storage:
   ```javascript
   rules_version = '2';
   service firebase.storage {
     match /b/{bucket}/o {
       match /ecoce/{allPaths=**} {
         allow read: if request.auth != null;
         allow write: if request.auth != null 
                      && request.resource.size < 5 * 1024 * 1024;
       }
     }
   }
   ```

2. Verificar autenticación antes de subir:
   ```dart
   if (FirebaseAuth.instance.currentUser == null) {
     throw 'Usuario no autenticado';
   }
   ```

---

## Problemas de Autenticación

### Error: "User not found"

**Síntomas**:
- Login falla con "Usuario no encontrado"
- Credenciales correctas pero no funciona

**Soluciones**:

1. Verificar plataforma correcta:
   ```dart
   // Asegurar que se inicializó la plataforma correcta
   final platform = _isEcoce ? FirebasePlatform.ecoce : FirebasePlatform.bioway;
   await _authService.initializeForPlatform(platform);
   ```

2. Verificar aprobación de cuenta:
   - Usuario debe estar aprobado por Maestro
   - Verificar en `ecoce_profiles/[userId]` → `aprobado: true`

3. Verificar email correcto:
   - Emails son case-sensitive
   - No debe tener espacios al inicio/final

### Error: "Password reset failed"

**Síntomas**:
```
[auth/user-not-found] There is no user record corresponding to this identifier
```

**Solución**:

1. Implementar recuperación de contraseña:
   ```dart
   Future<void> resetPassword(String email) async {
     try {
       await FirebaseAuth.instance.sendPasswordResetEmail(
         email: email.trim().toLowerCase(),
       );
     } on FirebaseAuthException catch (e) {
       if (e.code == 'user-not-found') {
         throw 'No existe una cuenta con ese email';
       }
       throw 'Error al enviar email de recuperación';
     }
   }
   ```

### Sesión expirada inesperadamente

**Síntomas**:
- Usuario regresa a login sin cerrar sesión
- Datos de usuario null cuando deberían existir

**Solución**:

1. Implementar persistencia de sesión:
   ```dart
   // En UserSessionService
   Future<void> restoreSession() async {
     final prefs = await SharedPreferences.getInstance();
     final userData = prefs.getString('userData');
     if (userData != null) {
       _userData = jsonDecode(userData);
     }
   }
   ```

2. Verificar en initState:
   ```dart
   @override
   void initState() {
     super.initState();
     _checkSession();
   }
   
   Future<void> _checkSession() async {
     await _userSession.restoreSession();
     if (_userSession.getUserData() == null) {
       Navigator.pushReplacementNamed(context, '/login');
     }
   }
   ```

---

## Errores de QR Scanner

### Cámara no se activa

**Síntomas**:
- Pantalla negra en scanner
- No solicita permisos de cámara

**Soluciones**:

1. Verificar permisos en AndroidManifest.xml:
   ```xml
   <uses-permission android:name="android.permission.CAMERA" />
   ```

2. Solicitar permisos en runtime:
   ```dart
   final status = await Permission.camera.request();
   if (status.isDenied) {
     // Mostrar diálogo explicativo
   }
   ```

3. Para iOS (Info.plist):
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>La app necesita acceso a la cámara para escanear códigos QR</string>
   ```

### QR no se escanea

**Síntomas**:
- Cámara activa pero no detecta QR
- QR válido pero no responde

**Soluciones**:

1. Verificar formato del QR:
   ```dart
   // Formatos válidos
   USER-TIPO-ID
   LOTE-MATERIAL-ID
   CARGA-ID
   ENTREGA-ID
   ```

2. Implementar debounce:
   ```dart
   DateTime? _lastScanTime;
   
   void _onDetect(BarcodeCapture capture) {
     final now = DateTime.now();
     if (_lastScanTime != null && 
         now.difference(_lastScanTime!).inMilliseconds < 1000) {
       return; // Ignorar escaneos muy rápidos
     }
     _lastScanTime = now;
     // Procesar QR...
   }
   ```

3. Mejorar condiciones de escaneo:
   - Buena iluminación
   - QR sin daños o reflejos
   - Distancia adecuada (15-30 cm)

### Error: "QR code expired"

**Síntomas**:
- QR de entrega muestra "Código expirado"
- Validez de 15 minutos excedida

**Solución**:

1. Regenerar QR de entrega:
   ```dart
   // Transportista debe generar nuevo QR
   final nuevoQR = await _cargaService.crearEntrega(...);
   ```

2. Implementar indicador visual:
   ```dart
   // Mostrar tiempo restante
   StreamBuilder<int>(
     stream: Stream.periodic(Duration(seconds: 1), (i) {
       final remaining = validoHasta.difference(DateTime.now());
       return remaining.inSeconds;
     }),
     builder: (context, snapshot) {
       final seconds = snapshot.data ?? 0;
       if (seconds <= 0) {
         return Text('EXPIRADO', style: TextStyle(color: Colors.red));
       }
       return Text('Válido por: ${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}');
     },
   );
   ```

---

## Problemas de Transferencia

### Lotes no aparecen después de transferencia

**Síntomas**:
- Transferencia exitosa pero lotes no visibles
- `proceso_actual` no se actualiza

**Soluciones**:

1. Verificar transferencia bidireccional completa:
   ```dart
   // Verificar ambos flags
   final entregaCompletada = transporteData['entrega_completada'] ?? false;
   final recepcionCompletada = recicladorData['recepcion_completada'] ?? false;
   
   if (entregaCompletada && recepcionCompletada) {
     // Actualizar proceso_actual
   }
   ```

2. Forzar verificación:
   ```dart
   await _loteService.verificarYActualizarTransferencia(
     loteId: loteId,
     procesoOrigen: 'transporte',
     procesoDestino: 'reciclador',
   );
   ```

3. Refresh manual de la lista:
   ```dart
   Future<void> _refreshLotes() async {
     setState(() => _isLoading = true);
     await Future.delayed(Duration(seconds: 1));
     setState(() => _isLoading = false);
   }
   ```

### Peso incorrecto después de muestras de laboratorio

**Síntomas**:
- Peso no refleja muestras tomadas
- Cálculo incorrecto del peso actual

**Solución**:

1. Verificar getter `pesoActual`:
   ```dart
   double get pesoActual {
     if (reciclador?.salida?.pesoProcesado != null) {
       final pesoBase = reciclador!.salida!.pesoProcesado!;
       final pesoMuestras = analisisLaboratorio.fold(0.0,
         (sum, analisis) => sum + (analisis.pesoMuestra ?? 0));
       return pesoBase - pesoMuestras;
     }
     // ... otros casos
   }
   ```

2. Verificar registro de muestras:
   ```dart
   // Al registrar muestra
   await _loteService.registrarAnalisisLaboratorio(
     loteId: loteId,
     pesoMuestra: peso, // Debe ser > 0
     // ...
   );
   ```

### Error en fase de transporte

**Síntomas**:
- Confusión entre fase_1 y fase_2
- Transporte no puede recoger

**Solución**:

1. Verificar determinación de fase:
   ```dart
   String _determinarFase(String procesoOrigen) {
     switch (procesoOrigen) {
       case 'origen':
         return 'fase_1';
       case 'reciclador':
         return 'fase_2';
       default:
         throw 'Proceso origen inválido';
     }
   }
   ```

2. Debug de fases:
   ```dart
   print('Proceso origen: ${lote.procesoActual}');
   print('Fase determinada: $_determinarFase(lote.procesoActual)');
   ```

---

## Errores de UI/UX

### Pantalla negra después de navegación

**Síntomas**:
- Pantalla completamente negra
- App no responde
- Generalmente después de `pushNamedAndRemoveUntil`

**Solución**:

1. Usar navegación correcta:
   ```dart
   // INCORRECTO
   Navigator.pushNamedAndRemoveUntil(
     context,
     '/ruta_inexistente',
     (route) => false,
   );
   
   // CORRECTO
   Navigator.pushAndRemoveUntil(
     context,
     MaterialPageRoute(
       builder: (context) => PantallaDestino(),
     ),
     (route) => route.isFirst,
   );
   ```

2. Verificar rutas en main.dart:
   ```dart
   routes: {
     '/origen_inicio': (context) => OrigenInicioScreen(),
     '/reciclador_inicio': (context) => RecicladorInicioScreen(),
     // ... todas las rutas deben estar definidas
   },
   ```

### Botón de retroceso cierra sesión

**Síntomas**:
- Presionar back en Android cierra sesión
- Navegación inesperada a login

**Solución**:

1. Implementar WillPopScope:
   ```dart
   @override
   Widget build(BuildContext context) {
     return WillPopScope(
       onWillPop: () async {
         // Prevenir cierre accidental
         return false;
       },
       child: Scaffold(
         // ... contenido
       ),
     );
   }
   ```

2. Para permitir salir con confirmación:
   ```dart
   onWillPop: () async {
     final shouldPop = await showDialog<bool>(
       context: context,
       builder: (context) => AlertDialog(
         title: Text('¿Salir de la aplicación?'),
         actions: [
           TextButton(
             onPressed: () => Navigator.pop(context, false),
             child: Text('Cancelar'),
           ),
           TextButton(
             onPressed: () => Navigator.pop(context, true),
             child: Text('Salir'),
           ),
         ],
       ),
     );
     return shouldPop ?? false;
   },
   ```

### Teclado cubre campos de entrada

**Síntomas**:
- Campos de texto no visibles al escribir
- Formulario no se desplaza con teclado

**Solución**:

1. Envolver en SingleChildScrollView:
   ```dart
   Scaffold(
     resizeToAvoidBottomInset: true,
     body: SingleChildScrollView(
       child: Padding(
         padding: EdgeInsets.only(
           bottom: MediaQuery.of(context).viewInsets.bottom,
         ),
         child: Form(
           // ... campos
         ),
       ),
     ),
   );
   ```

2. Para casos complejos:
   ```dart
   // Usar Flutter's built-in handling
   Scaffold(
     resizeToAvoidBottomInset: true,
     body: LayoutBuilder(
       builder: (context, constraints) {
         return SingleChildScrollView(
           physics: ClampingScrollPhysics(),
           child: ConstrainedBox(
             constraints: BoxConstraints(
               minHeight: constraints.maxHeight,
             ),
             child: IntrinsicHeight(
               child: Column(
                 // ... contenido
               ),
             ),
           ),
         );
       },
     ),
   );
   ```

---

## Problemas de Rendimiento

### App lenta al cargar listas grandes

**Síntomas**:
- Lag al scrollear
- Demora en cargar lotes
- UI no responsiva

**Soluciones**:

1. Implementar ListView.builder:
   ```dart
   // INCORRECTO
   Column(
     children: lotes.map((lote) => LoteTile(lote)).toList(),
   )
   
   // CORRECTO
   ListView.builder(
     itemCount: lotes.length,
     itemBuilder: (context, index) => LoteTile(lotes[index]),
   )
   ```

2. Paginar resultados:
   ```dart
   Query query = FirebaseFirestore.instance
     .collection('lotes')
     .orderBy('fecha_creacion', descending: true)
     .limit(20);
   
   // Para cargar más
   if (_lastDocument != null) {
     query = query.startAfterDocument(_lastDocument);
   }
   ```

3. Implementar caché local:
   ```dart
   class LoteCache {
     static final Map<String, LoteUnificadoModel> _cache = {};
     
     static void addToCache(LoteUnificadoModel lote) {
       _cache[lote.id] = lote;
     }
     
     static LoteUnificadoModel? getFromCache(String id) {
       return _cache[id];
     }
   }
   ```

### Imágenes tardan en cargar

**Síntomas**:
- Placeholder largo tiempo
- Consumo excesivo de datos
- Memory warnings

**Soluciones**:

1. Usar CachedNetworkImage:
   ```dart
   CachedNetworkImage(
     imageUrl: imageUrl,
     placeholder: (context, url) => CircularProgressIndicator(),
     errorWidget: (context, url, error) => Icon(Icons.error),
     maxHeightDiskCache: 200,
     maxWidthDiskCache: 200,
   );
   ```

2. Comprimir antes de subir:
   ```dart
   final compressedImage = await ImageService.optimizeImageForDatabase(
     imageFile,
     targetSizeKB: 50,
   );
   ```

3. Lazy loading de imágenes:
   ```dart
   ListView.builder(
     itemBuilder: (context, index) {
       // Solo cargar imágenes visibles
       return VisibilityDetector(
         key: Key('image-$index'),
         onVisibilityChanged: (info) {
           if (info.visibleFraction > 0) {
             // Cargar imagen
           }
         },
         child: ImageWidget(),
       );
     },
   );
   ```

---

## Errores de Compilación

### Error: "The getter 'tipoPoli' isn't defined"

**Síntomas**:
```
The getter 'tipoPoli' isn't defined for the type 'DatosGeneralesLote'
```

**Solución**:

Actualizar referencias al nuevo nombre:
```dart
// ANTES
lote.datosGenerales.tipoPoli

// DESPUÉS
lote.datosGenerales.tipoMaterial
```

### Error: "The method 'uploadBase64Image' isn't defined"

**Síntomas**:
```
The method 'uploadBase64Image' isn't defined for the type 'FirebaseStorageService'
```

**Solución**:

Agregar método faltante:
```dart
Future<String?> uploadBase64Image(String base64String, String fileName) async {
  try {
    String cleanBase64 = base64String;
    if (base64String.contains(',')) {
      cleanBase64 = base64String.split(',')[1];
    }
    
    final bytes = base64.decode(cleanBase64);
    final fullPath = 'firmas/$fileName.png';
    final ref = _storage.ref().child(fullPath);
    
    final uploadTask = await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/png'),
    );
    
    return await uploadTask.ref.getDownloadURL();
  } catch (e) {
    print('Error uploading base64 image: $e');
    return null;
  }
}
```

### Error: "Undefined name 'FieldValue'"

**Síntomas**:
```
Undefined name 'FieldValue'
```

**Solución**:

Importar Cloud Firestore correctamente:
```dart
import 'package:cloud_firestore/cloud_firestore.dart';

// Usar
FieldValue.serverTimestamp()
FieldValue.arrayUnion([value])
FieldValue.increment(1)
```

---

## Problemas Específicos por Usuario

### Origen: Lotes no se crean

**Problema**: Formulario se envía pero lote no aparece

**Verificar**:
1. Todos los campos requeridos completos
2. Al menos 1 foto agregada
3. Conexión a internet activa
4. Permisos de escritura en Firestore

**Debug**:
```dart
try {
  final loteId = await _loteService.crearLoteDesdeOrigen(...);
  print('Lote creado con ID: $loteId');
} catch (e) {
  print('Error creando lote: $e');
  // Mostrar error al usuario
}
```

### Transportista: No puede generar QR de entrega

**Problema**: Botón deshabilitado o error al generar

**Verificar**:
1. Lotes seleccionados para entrega
2. Receptor identificado correctamente
3. Datos de transporte completos

**Solución**:
```dart
// Validar antes de generar
if (_lotesSeleccionados.isEmpty) {
  throw 'Debe seleccionar al menos un lote';
}
if (_receptorData == null) {
  throw 'Debe identificar al receptor';
}
```

### Reciclador: Peso incorrecto en procesamiento

**Problema**: Peso no coincide con el esperado

**Verificar**:
1. Muestras de laboratorio restadas
2. Peso original vs procesado
3. Unidades correctas (kg)

**Debug**:
```dart
print('Peso original: ${lote.datosGenerales.pesoNace}');
print('Peso actual: ${lote.pesoActual}');
print('Muestras lab: ${lote.analisisLaboratorio.length}');
```

### Laboratorio: No puede tomar muestras

**Problema**: Error al registrar muestra

**Verificar**:
1. Lote en proceso reciclador
2. Peso de muestra > 0
3. Firma capturada correctamente

### Transformador: Documentos no se suben

**Problema**: Error al subir documentación

**Verificar**:
1. Tamaño de archivo < 5MB
2. Formato correcto (PDF/imagen)
3. Estado del lote = "documentacion"

---

## Herramientas de Debugging

### Logs en Consola

```dart
// Desarrollo
if (kDebugMode) {
  print('DEBUG: ${DateTime.now()} - $message');
}

// Producción - usar logger
import 'package:logger/logger.dart';

final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    printTime: true,
  ),
);

logger.d('Debug message');
logger.e('Error message', error, stackTrace);
```

### Firebase Debugging

```bash
# Habilitar debug logging
adb shell setprop log.tag.FA VERBOSE
adb shell setprop log.tag.FA-SVC VERBOSE
adb logcat -v time -s FA FA-SVC
```

### Flutter Inspector

1. Ejecutar app en modo debug
2. Abrir Flutter Inspector en IDE
3. Herramientas útiles:
   - Widget tree
   - Layout Explorer
   - Performance overlay

### Network Debugging

```dart
// Interceptor para HTTP/Firebase
class DebugInterceptor {
  void onRequest(RequestOptions options) {
    print('REQUEST[${options.method}] => PATH: ${options.path}');
    print('Headers: ${options.headers}');
    print('Data: ${options.data}');
  }
  
  void onResponse(Response response) {
    print('RESPONSE[${response.statusCode}] => DATA: ${response.data}');
  }
  
  void onError(DioError err) {
    print('ERROR[${err.response?.statusCode}] => MESSAGE: ${err.message}');
  }
}
```

### Análisis de Performance

```dart
// Timeline events
Timeline.startSync('LoadLotes');
// ... operación costosa
Timeline.finishSync();

// Memory profiling
print('Memory usage: ${ProcessInfo.currentRss ~/ 1024 ~/ 1024} MB');
```

---

## Contacto y Soporte

Si el problema persiste después de intentar estas soluciones:

1. **Revisar documentación**:
   - `CLAUDE.md` - Guía técnica
   - `API_SERVICES_DOCUMENTATION.md` - Detalles de servicios
   - `FLUJOS_USUARIO_COMPLETOS.md` - Flujos detallados

2. **Buscar en logs**:
   - Firebase Console → Functions → Logs
   - Firebase Console → Crashlytics
   - Flutter logs locales

3. **Reportar issue**:
   - GitHub Issues con:
     - Descripción clara del problema
     - Pasos para reproducir
     - Logs relevantes
     - Versión de la app
     - Dispositivo/OS

---

*Última actualización: 2025-01-26*  
*Versión: 1.0.0*