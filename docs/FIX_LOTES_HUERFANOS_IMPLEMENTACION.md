# Correcciones en la Implementación de Lotes Huérfanos

## Fecha: 2025-01-06

## Resumen
Durante la implementación del sistema de detección y eliminación de lotes huérfanos para el usuario Maestro ECOCE, se encontraron y corrigieron varios problemas críticos que impedían el correcto funcionamiento del sistema.

## Problemas Encontrados y Soluciones

### 1. Error en la Búsqueda de Usuarios Origen

#### Problema
Los usuarios de tipo origen (centro de acopio y planta de separación) no se detectaban correctamente porque el código buscaba en rutas incorrectas.

#### Código Incorrecto
```dart
final subcarpetas = [
  'origen/centro_acopio/usuarios',      // ❌ Ruta incorrecta
  'origen/planta_separacion/usuarios',  // ❌ Ruta incorrecta
  'reciclador/usuarios',
  'transformador/usuarios',
  'transporte/usuarios',
  'laboratorio/usuarios',
];
```

#### Solución
```dart
final subcarpetas = [
  'origen/centro_acopio',      // ✅ Sin /usuarios al final
  'origen/planta_separacion',  // ✅ Sin /usuarios al final
  'reciclador/usuarios',
  'transformador/usuarios',
  'transporte/usuarios',
  'laboratorio/usuarios',
];
```

**Razón**: En la estructura de Firebase, los usuarios de origen se almacenan directamente en `centro_acopio` y `planta_separacion`, no en una subcarpeta `/usuarios`.

### 2. Error de Índice en CollectionGroup para Transformaciones

#### Problema
La consulta para obtener transformaciones fallaba porque requería un índice compuesto:
```dart
// ❌ Requiere índice COLLECTION_GROUP_ASC
final snapshot = await _firestore
    .collectionGroup('datos_generales')
    .where('tipo', whereIn: ['agrupacion_reciclador', 'agrupacion_transformador'])
    .get();
```

#### Solución
```dart
// ✅ Consulta directa sin necesidad de índice
final snapshot = await _firestore
    .collection('transformaciones')
    .get();
```

**Razón**: Las consultas `collectionGroup` con cláusulas `where` requieren índices compuestos manuales. Al cambiar a una consulta directa de la colección, evitamos este requisito.

### 3. Problemas de Autenticación del Maestro

#### Problema
El usuario maestro perdía autenticación al navegar entre pantallas, causando errores de permisos.

#### Solución
Implementación de `UserSessionService` para el maestro:
```dart
// Verificación de autenticación robusta
if (_sessionService.isLoggedIn) {
  final userData = _sessionService.getUserData();
  userId = userData?['uid'];
}

// Fallback a Firebase Auth si es necesario
if (userId == null) {
  final currentUser = _auth.currentUser;
  userId = currentUser?.uid;
}
```

**Razón**: El maestro ahora usa el mismo sistema de sesión que otros usuarios, eliminando excepciones y manteniendo la autenticación persistente.

### 4. Permisos de Firestore Insuficientes

#### Problema
Las reglas de Firestore no permitían al maestro eliminar varios tipos de documentos.

#### Soluciones Aplicadas

**Cargas de Transporte** (línea 149):
```javascript
// Antes
allow delete: if false;
// Después
allow delete: if isMaestro();
```

**Entregas de Transporte** (línea 157):
```javascript
// Antes
allow delete: if isAuthenticated();
// Después
allow delete: if isMaestro();
```

**Sublotes** (línea 281):
```javascript
// Antes
allow delete: if false;
// Después
allow delete: if isMaestro();
```

### 5. Sublotes No Detectados

#### Problema
El sistema no detectaba sublotes huérfanos porque no se incluían en las consultas.

#### Solución
Agregado de detección de sublotes:
```dart
// Agregar consulta de sublotes
final results = await Future.wait([
  // ... otras consultas
  _firestore.collection('sublotes').get(), // ✅ Nueva consulta
]);

// Procesar sublotes huérfanos
for (var doc in sublotesSnapshot.docs) {
  final creadoPor = data['creado_por'] as String?;
  if (creadoPor != null && !usuariosExistentes.contains(creadoPor)) {
    // Marcar como huérfano
  }
}
```

### 6. Manejo de Errores en Eliminación

#### Problema
No se manejaban correctamente los errores durante la eliminación masiva.

#### Solución
```dart
try {
  if (lotInfo.isSublote) {
    await _deleteSublote(loteId);
  } else if (lotInfo.isTransformacion) {
    await _deleteTransformacion(loteId);
  }
  // ... otros tipos
  deletedCount++;
} catch (e) {
  debugPrint('Error eliminando lote $loteId: $e');
  errorCount++;
}
```

## Mejoras Adicionales Implementadas

### 1. Consultas Paralelas
Todas las consultas se ejecutan en paralelo para mejorar el rendimiento:
```dart
final results = await Future.wait([
  _firestore.collection('ecoce_profiles').get(),
  _firestore.collectionGroup('datos_generales').get(),
  _firestore.collection('transformaciones').get(),
  _firestore.collectionGroup('analisis_laboratorio').get(),
  _firestore.collection('sublotes').get(),
]);
```

### 2. Optimización con Set
Uso de `Set<String>` para búsqueda O(1) de usuarios existentes:
```dart
final Set<String> usuariosExistentes = {};
for (var doc in profilesSnapshot.docs) {
  usuariosExistentes.add(doc.id);
}
```

### 3. Información Detallada
El sistema ahora muestra información más completa:
- Tipo específico de transformación para sublotes
- Peso total de material huérfano
- Tiempo desde la creación
- Estadísticas por tipo de documento

## Lecciones Aprendidas

1. **Estructura de Firebase**: Es crítico entender la estructura exacta de las colecciones y subcollecciones
2. **Índices de Firestore**: Las consultas `collectionGroup` con filtros requieren planificación de índices
3. **Gestión de Sesión**: Usar un sistema consistente para todos los tipos de usuarios evita problemas
4. **Permisos Granulares**: Las reglas de Firestore deben ser específicas para cada operación
5. **Pruebas Completas**: Probar con datos reales revela problemas no evidentes en desarrollo

## Resultado Final

El sistema ahora detecta y puede eliminar correctamente:
- ✅ Lotes regulares huérfanos
- ✅ Transformaciones (megalotes) huérfanas
- ✅ Sublotes huérfanos
- ✅ Cargas de transporte huérfanas
- ✅ Entregas de transporte huérfanas
- ✅ Muestras de laboratorio huérfanas

Con registro completo de auditoría y confirmación de doble paso para prevenir eliminaciones accidentales.