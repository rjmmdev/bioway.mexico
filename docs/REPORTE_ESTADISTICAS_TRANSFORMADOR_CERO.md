# Reporte: Estadísticas del Transformador Mostrando 0s

## Resumen del Problema
Las estadísticas del Transformador están mostrando valores de 0 a pesar de existir datos en Firebase. El log muestra:
```
I/flutter (28289): Estadísticas cargadas - Lotes: 0, Productos: 0, Material: 0.0 t
```

## Análisis Detallado

### 1. Flujo de Autenticación y Obtención del UserId

#### Problema Identificado
El servicio `LoteUnificadoService` obtiene el userId mediante:
```dart
String? get _currentUserId => _authService.currentUser?.uid;
```

Sin embargo, `AuthService` usa multi-tenant Firebase:
```dart
FirebaseAuth get _auth {
  final app = _firebaseManager.currentApp;
  if (app == null) {
    throw Exception('Firebase no inicializado...');
  }
  return FirebaseAuth.instanceFor(app: app);
}
```

**PROBLEMA POTENCIAL #1**: Si el `FirebaseManager.currentApp` no está correctamente configurado para ECOCE al momento de llamar las estadísticas, el userId podría ser null o pertenecer a la app incorrecta.

### 2. Consultas a Firebase

#### Query de Lotes Recibidos
```dart
final lotesQuery = await _firestore
    .collectionGroup('datos_generales')
    .where('proceso_actual', isEqualTo: 'transformador')
    .get();
```

**PROBLEMA #2**: La consulta busca `proceso_actual == 'transformador'`, pero luego filtra por `usuario_id`:
```dart
if (usuarioId == userId) {
  // Solo cuenta si el usuario_id coincide
}
```

**Posibles causas de 0 lotes:**
- Los lotes no tienen el campo `usuario_id` en `datos_generales`
- El campo `usuario_id` tiene un valor diferente al userId actual
- Los lotes del transformador usan un campo diferente (ej: `transformador_id`)
- El `proceso_actual` no es exactamente 'transformador' (podría ser 'Transformador' con mayúscula)

#### Query de Transformaciones/Megalotes
```dart
final transformacionesQuery = await _firestore
    .collection('transformaciones')
    .where('usuario_id', isEqualTo: userId)
    .where('tipo', isEqualTo: 'agrupacion_transformador')
    .get();
```

**PROBLEMA #3**: Esta consulta busca transformaciones con:
- `tipo == 'agrupacion_transformador'`
- `usuario_id == userId`

**Posibles causas de 0 productos:**
- El transformador crea transformaciones con un tipo diferente
- El campo se llama diferente (ej: `usuarioId` en lugar de `usuario_id`)
- Las transformaciones del transformador no tienen el campo `tipo` o tiene otro valor

### 3. Estructura de Datos en Firebase

#### Análisis de la Ruta del Documento
```dart
final pathSegments = doc.reference.path.split('/');
if (pathSegments.length >= 2) {
  final loteId = pathSegments[pathSegments.length - 3];
  // Esperando: lotes/[ID]/datos_generales/info
}
```

**PROBLEMA #4**: El código asume que el documento está en `lotes/[ID]/datos_generales/info`, pero si la estructura es diferente (ej: `lotes/[ID]/datos_generales/data`), no obtendrá el ID correctamente.

### 4. Logs de Depuración

El método tiene logs pero aparentemente no se están mostrando todos:
```dart
debugPrint('=== OBTENIENDO ESTADÍSTICAS TRANSFORMADOR ===');
debugPrint('Usuario ID: $userId');
debugPrint('Obteniendo lotes del transformador...');
debugPrint('Lotes recibidos por el transformador: $lotesRecibidos');
```

**PROBLEMA #5**: Solo vemos el log final, lo que sugiere que:
- El userId podría ser null (saltando al return temprano)
- O las consultas están devolviendo 0 resultados

## Propuestas de Solución

### Solución 1: Verificación de Usuario y Firebase App
```dart
// Agregar más logs de depuración
Future<Map<String, dynamic>> obtenerEstadisticasTransformador() async {
  try {
    debugPrint('=== INICIO obtenerEstadisticasTransformador ===');
    
    // Verificar la app actual
    final currentApp = _firebaseManager.currentApp;
    debugPrint('Firebase App actual: ${currentApp?.name}');
    
    final userId = _currentUserId;
    debugPrint('Usuario ID obtenido: $userId');
    
    if (userId == null) {
      debugPrint('ERROR: No hay usuario autenticado');
      return {...};
    }
    // ... resto del código
```

### Solución 2: Consulta Más Amplia para Diagnóstico
```dart
// Primero obtener TODOS los lotes del transformador sin filtrar por usuario
final todosLotesTransformador = await _firestore
    .collectionGroup('datos_generales')
    .where('proceso_actual', isEqualTo: 'transformador')
    .limit(10) // Limitar para debug
    .get();

debugPrint('Total lotes con proceso_actual=transformador: ${todosLotesTransformador.docs.length}');

// Examinar la estructura de los primeros documentos
for (var doc in todosLotesTransformador.docs.take(3)) {
  final data = doc.data();
  debugPrint('Documento ejemplo:');
  debugPrint('  Path: ${doc.reference.path}');
  debugPrint('  usuario_id: ${data['usuario_id']}');
  debugPrint('  proceso_actual: ${data['proceso_actual']}');
  debugPrint('  Campos disponibles: ${data.keys.join(', ')}');
}
```

### Solución 3: Verificar Estructura de Transformaciones
```dart
// Obtener TODAS las transformaciones para debug
final todasTransformaciones = await _firestore
    .collection('transformaciones')
    .limit(5)
    .get();

debugPrint('Total transformaciones en BD: ${todasTransformaciones.docs.length}');

for (var doc in todasTransformaciones.docs) {
  final data = doc.data();
  debugPrint('Transformación ejemplo:');
  debugPrint('  ID: ${doc.id}');
  debugPrint('  usuario_id: ${data['usuario_id']}');
  debugPrint('  tipo: ${data['tipo']}');
  debugPrint('  estado: ${data['estado']}');
}
```

### Solución 4: Usar Consultas Sin Filtro de Usuario (Temporal)
Para verificar si el problema es el userId, temporalmente consultar sin ese filtro:
```dart
// Solo para debug - contar TODOS los lotes en transformador
final lotesQuery = await _firestore
    .collectionGroup('datos_generales')
    .where('proceso_actual', isEqualTo: 'transformador')
    .get();

debugPrint('Lotes totales en transformador (sin filtro usuario): ${lotesQuery.docs.length}');
```

### Solución 5: Verificar Campos Alternativos
```dart
// Buscar diferentes variaciones del campo usuario
for (final doc in lotesQuery.docs) {
  final data = doc.data();
  
  // Buscar variaciones del campo usuario
  final posiblesUsuarios = [
    data['usuario_id'],
    data['usuarioId'],
    data['transformador_id'],
    data['transformadorId'],
    data['usuario_actual'],
  ];
  
  debugPrint('Posibles campos de usuario encontrados: ${posiblesUsuarios.where((u) => u != null).toList()}');
}
```

## Recomendaciones de Implementación

### Paso 1: Diagnóstico Inmediato
1. Agregar logs extensivos para identificar exactamente dónde falla
2. Verificar que el userId no sea null
3. Confirmar que está usando la app Firebase correcta (ECOCE)

### Paso 2: Verificación de Datos
1. Consultar Firebase Console directamente para ver la estructura real
2. Verificar que los lotes del transformador tienen `usuario_id`
3. Confirmar los valores exactos de `proceso_actual` y `tipo`

### Paso 3: Ajuste de Consultas
1. Si los campos son diferentes, actualizar las consultas
2. Si la estructura es diferente, ajustar la lógica de extracción
3. Considerar usar consultas más flexibles

### Paso 4: Solución Alternativa
Si el problema persiste, considerar:
1. Almacenar estadísticas acumulativas en el perfil del usuario
2. Usar un campo específico para marcar lotes del transformador
3. Implementar un sistema de contadores incrementales

## Conclusión

El problema más probable es que:
1. **El userId es null** o no coincide con los datos en Firebase
2. **Los campos en Firebase tienen nombres diferentes** a los esperados
3. **La estructura de datos es diferente** para el transformador

Se recomienda comenzar con el diagnóstico detallado agregando logs extensivos antes de implementar cambios en la lógica.

## Estado
🔍 **ANÁLISIS COMPLETADO** - 2025-01-29
⏳ **PENDIENTE DE IMPLEMENTACIÓN**