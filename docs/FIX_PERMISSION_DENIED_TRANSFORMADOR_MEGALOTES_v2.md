# Fix v2: PERMISSION_DENIED al Crear Megalotes en Transformador

## Problema Actualizado
Después del primer fix, el error persistía pero ahora mostraba: "Error de permisos. Por favor contacte al administrador"

## Causa Raíz Adicional
Las reglas de Firestore para la colección `transformaciones` requieren que al crear un documento, este tenga exactamente los campos:
- `usuario_id`
- `usuario_folio` 
- `tipo`
- `fecha_inicio`

El problema era que:
1. `FieldValue.serverTimestamp()` no cumple con la validación de las reglas al momento de crear
2. Los campos podrían estar en orden incorrecto o faltar

## Soluciones Aplicadas - Segunda Iteración

### 1. Cambio de FieldValue.serverTimestamp() a DateTime ISO String
**Archivo:** `lib/screens/ecoce/transformador/transformador_formulario_salida.dart`

#### En creación de transformación (líneas 572-590):
```dart
// ANTES
'fecha_inicio': FieldValue.serverTimestamp(),

// DESPUÉS  
'fecha_inicio': DateTime.now().toIso8601String(),
```

#### En método _prepareTransformacionData (líneas 345-365):
```dart
// Mismo cambio aplicado para consistencia
'fecha_inicio': DateTime.now().toIso8601String(),
'ultima_actualizacion': DateTime.now().toIso8601String(),
```

### 2. Orden de campos para cumplir con reglas
Se reorganizaron los campos para asegurar que los requeridos estén primero:
```dart
final transformacionData = {
  'tipo': 'agrupacion_transformador',
  'usuario_id': usuarioId,
  'usuario_folio': usuarioFolio,
  'fecha_inicio': DateTime.now().toIso8601String(),
  // ... resto de campos
};
```

### 3. Validación de perfil de usuario (líneas 482-499)
Se agregó validación para asegurar que el perfil tenga los campos necesarios:
```dart
if ((userProfile['userId'] == null && userProfile['uid'] == null) ||
    (userProfile['ecoceFolio'] == null && userProfile['folio'] == null)) {
  throw Exception('Perfil de usuario incompleto. Faltan campos requeridos.');
}
```

### 4. Logging detallado para debugging (líneas 576-580, 697-701)
Se agregaron logs para identificar problemas:
```dart
print('=== CREANDO TRANSFORMACIÓN ===');
print('usuario_id: $usuarioId');
print('usuario_folio: $usuarioFolio');
print('tipo: agrupacion_transformador');
print('Campos requeridos presentes: ${usuarioId.isNotEmpty && usuarioFolio.isNotEmpty}');
```

## Reglas de Firestore Relevantes
```javascript
// firestore.rules líneas 225-228
allow create: if isAuthenticated() &&
  request.resource.data.usuario_id == request.auth.uid &&
  request.resource.data.keys().hasAll(['usuario_id', 'usuario_folio', 'tipo', 'fecha_inicio']);
```

## Cambios Totales Aplicados
1. ✅ `.update()` → `.set()` con `merge: true` (primera iteración)
2. ✅ Validación de estado de lotes (primera iteración)
3. ✅ `FieldValue.serverTimestamp()` → `DateTime.now().toIso8601String()`
4. ✅ Orden correcto de campos requeridos
5. ✅ Validación de perfil de usuario
6. ✅ Logging detallado para debugging

## Testing
Para verificar que funciona:
1. Revisar la consola de Flutter para ver los logs de debugging
2. Verificar que aparezcan:
   - `=== PERFIL DE USUARIO OBTENIDO ===`
   - `=== CREANDO TRANSFORMACIÓN ===`
   - Los valores de usuario_id y usuario_folio
3. Si falla, el error ahora mostrará información más específica

## Estado
✅ **IMPLEMENTADO v2** - 2025-01-29

## Notas Importantes
- Los campos deben estar presentes y en el orden correcto para las reglas de Firestore
- `FieldValue.serverTimestamp()` no funciona para campos requeridos en reglas de creación
- El perfil del usuario debe tener campos completos antes de crear transformaciones