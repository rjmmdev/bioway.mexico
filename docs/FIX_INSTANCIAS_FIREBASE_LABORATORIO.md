# Fix: Instancias Diferentes de Firebase en Laboratorio

## Fecha de Solución
**2025-01-29**

## Problema Identificado
Las muestras de laboratorio se **creaban correctamente** en el proyecto `trazabilidad-ecoce` pero **no se podían leer** en la aplicación.

### Causa Raíz
La aplicación usa arquitectura multi-tenant con dos proyectos Firebase:
- **BioWay** (futuro)
- **ECOCE** (`trazabilidad-ecoce`)

El servicio `MuestraLaboratorioService` usaba correctamente la instancia de ECOCE para **crear** muestras:
```dart
// CREACIÓN ✅
final app = _firebaseManager.currentApp;  // App ECOCE
_firestore = FirebaseFirestore.instanceFor(app: app);
```

Pero `laboratorio_gestion_muestras.dart` usaba la instancia default para **leer**:
```dart
// LECTURA ❌ (ANTES)
final FirebaseFirestore _firestore = FirebaseFirestore.instance;  // Instancia default/incorrecta
```

## Solución Implementada

### Archivo Modificado
`lib/screens/ecoce/laboratorio/laboratorio_gestion_muestras.dart`

### Cambios Realizados

#### 1. Importar FirebaseManager
```dart
import '../../../services/firebase/firebase_manager.dart';
```

#### 2. Cambiar declaración de _firestore
```dart
// ANTES
final FirebaseFirestore _firestore = FirebaseFirestore.instance;

// AHORA
late final FirebaseFirestore _firestore;
final FirebaseManager _firebaseManager = FirebaseManager();
```

#### 3. Inicializar con la instancia correcta en initState
```dart
@override
void initState() {
  super.initState();
  
  // Usar la misma instancia de Firebase que el servicio
  final app = _firebaseManager.currentApp;
  if (app != null) {
    _firestore = FirebaseFirestore.instanceFor(app: app);  // ✅ ECOCE
    debugPrint('[LABORATORIO] Usando Firebase app: ${app.name} - Project: ${app.options.projectId}');
  } else {
    _firestore = FirebaseFirestore.instance;
    debugPrint('[LABORATORIO] ADVERTENCIA: Usando instancia default de Firebase');
  }
  
  // ... resto del initState
}
```

#### 4. Simplificar consulta (temporal)
Removido el `orderBy` de la consulta Firestore y agregado ordenamiento manual:
```dart
// Consulta simple
final muestrasSnapshot = await _firestore
    .collection('muestras_laboratorio')
    .where('laboratorio_id', isEqualTo: userId)
    .get();

// Ordenar manualmente
docs.sort((a, b) {
  final fechaA = (a.data()['fecha_toma'] as Timestamp).toDate();
  final fechaB = (b.data()['fecha_toma'] as Timestamp).toDate();
  return fechaB.compareTo(dateA); // Descendente
});
```

## Resultado

✅ **Las muestras ahora se pueden leer correctamente**
- Crear y leer usan el mismo proyecto Firebase (`trazabilidad-ecoce`)
- No más errores de "permission-denied"
- El laboratorio puede ver sus muestras en la aplicación

## Lección Aprendida

En aplicaciones multi-tenant con múltiples proyectos Firebase:
1. **SIEMPRE** usar `FirebaseFirestore.instanceFor(app: app)`
2. **NUNCA** usar `FirebaseFirestore.instance` directamente
3. **VERIFICAR** que todas las pantallas usen la misma instancia

## Archivos Similares que Podrían Necesitar la Misma Corrección

Cualquier archivo en `lib/screens/ecoce/laboratorio/` que use:
- `FirebaseFirestore.instance`
- `FirebaseAuth.instance`
- `FirebaseStorage.instance`

Debe cambiarse para usar la instancia correcta a través de `FirebaseManager`.

## Verificación

Para verificar que funciona:
1. Iniciar sesión como Laboratorio
2. Ir a "Gestión de Muestras"
3. Las muestras deben aparecer sin errores
4. Verificar en los logs: `Usando Firebase app: ecoce - Project: trazabilidad-ecoce`