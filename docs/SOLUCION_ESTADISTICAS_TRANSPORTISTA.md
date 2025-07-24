# Solución: Estadísticas Personalizadas del Transportista

## Problema Original
Las estadísticas en la pantalla de inicio del Usuario Transportista parecían hardcodeadas ya que mostraban datos de TODOS los transportistas, no solo del usuario actual.

## Solución Implementada

### 1. Agregar userId al Modelo
Se agregó el campo `userId` al modelo `LoteTransportistaModel`:

```dart
class LoteTransportistaModel {
  final String? id; // Firebase ID
  final String? userId; // ID del usuario transportista
  // ... resto de campos
}
```

### 2. Guardar userId al Crear Lotes
Se actualizó la creación de lotes en dos lugares:

**En transporte_formulario_carga_screen.dart:**
```dart
// Obtener el userId del transportista actual
final userData = _userSession.getUserData();
final userId = userData?['uid'] ?? '';

// Crear el modelo del lote de transportista
final loteTransportista = LoteTransportistaModel(
  userId: userId,
  // ... resto de campos
);
```

**En transporte_qr_entrega_screen.dart:**
```dart
// Obtener el userId del transportista actual
final userSession = UserSessionService();
final userData = userSession.getUserData();
final userId = userData?['uid'] ?? '';

// Crear nuevo lote de transportista
final nuevoLote = LoteTransportistaModel(
  userId: userId,
  // ... resto de campos
);
```

### 3. Nuevo Método en el Servicio
Se agregó un método en `LoteService` para filtrar por userId:

```dart
Stream<List<LoteTransportistaModel>> getLotesTransportistaByUserId({
  required String userId,
  String? estado,
}) {
  Query query = _firestore.collection(LOTES_TRANSPORTISTA)
      .where('userId', isEqualTo: userId);
  
  if (estado != null) {
    query = query.where('estado', isEqualTo: estado);
  }
  
  return query
      .orderBy('ecoce_transportista_fecha_recepcion', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => LoteTransportistaModel.fromFirestore(doc))
          .toList());
}
```

### 4. Actualizar Pantalla de Inicio
Se modificó `transporte_inicio_screen.dart` para usar el filtrado por userId:

**Para lotes en tránsito:**
```dart
// Obtener el userId del transportista actual
final userData = _sessionService.getUserData();
final userId = userData?['uid'] ?? '';

// Obtener lotes del transportista actual con estado 'en_transporte'
final lotesTransportista = await _loteService.getLotesTransportistaByUserId(
  userId: userId,
  estado: 'en_transporte',
).first;
```

**Para estadísticas:**
```dart
// Obtener todos los lotes del transportista actual
final todosLotesStream = _loteService.getLotesTransportistaByUserId(
  userId: userId,
);
final todosLotes = await todosLotesStream.first;
```

## Resultado

Ahora las estadísticas mostradas son específicas del transportista:
1. ✅ **Viajes realizados**: Solo cuenta los lotes creados por el transportista actual
2. ✅ **Lotes transportados**: Suma de lotes transportados por este usuario
3. ✅ **Entregas realizadas**: Solo entregas completadas por este transportista
4. ✅ **Lotes en tránsito**: Solo muestra lotes del transportista actual

## Importante

Los lotes creados ANTES de esta actualización no tienen el campo `userId`, por lo que:
- No aparecerán en las estadísticas personalizadas
- No se mostrarán en "Lotes en Tránsito" del transportista
- Para pruebas, es necesario crear nuevos lotes después de esta actualización

## Archivos Modificados

1. `lib/models/lotes/lote_transportista_model.dart` - Agregado campo userId
2. `lib/services/lote_service.dart` - Nuevo método getLotesTransportistaByUserId
3. `lib/screens/ecoce/transporte/transporte_formulario_carga_screen.dart` - Guardar userId
4. `lib/screens/ecoce/transporte/transporte_qr_entrega_screen.dart` - Guardar userId
5. `lib/screens/ecoce/transporte/transporte_inicio_screen.dart` - Filtrar por userId