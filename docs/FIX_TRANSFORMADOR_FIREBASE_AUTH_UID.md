# Fix: Transformador usando Firebase Auth UID Correctamente

## Problema Final Identificado
El Transformador estaba enviando el ID del perfil en lugar del UID de Firebase Auth, causando que las reglas de Firestore rechazaran la operación con `PERMISSION_DENIED`.

**Regla de Firestore que fallaba:**
```javascript
allow create: if isAuthenticated() &&
  request.resource.data.usuario_id == request.auth.uid  // Validación crítica
```

## Comparación de Implementaciones

### ❌ Transformador ANTES (Fallaba)
```dart
// Obtenía el perfil y usaba campos que podían no ser el UID
final userProfile = await _userSession.getUserProfile();
final usuarioId = userProfile['userId'] ?? userProfile['uid'] ?? '';
// 'userId' era el ID del documento del perfil, NO el UID de Auth
```

### ✅ Reciclador (Funcionaba)
```dart
// TransformacionService siempre usa el UID de Firebase Auth
final authUid = userData['uid']; // UID real de Firebase Auth
usuarioId: authUid,
```

## Solución Aplicada

### 1. Importar Firebase Auth
```dart
import 'package:firebase_auth/firebase_auth.dart';
```

### 2. Obtener UID Directamente (líneas 482-509)
```dart
// NUEVO - Como hace el Reciclador
final firebaseAuth = FirebaseAuth.instance;
final currentUser = firebaseAuth.currentUser;

if (currentUser == null) {
  throw Exception('Usuario no autenticado');
}

final authUid = currentUser.uid; // UID real de Firebase Auth
final userData = _userSession.getUserData();
final userFolio = userData?['folio'] ?? '';
```

### 3. Usar UID Correcto en Transformación (líneas 595-597)
```dart
final transformacionData = {
  'tipo': 'agrupacion_transformador',
  'usuario_id': authUid,  // Ahora usa el UID de Firebase Auth
  'usuario_folio': userFolio,
  'fecha_inicio': DateTime.now(), // También cambiado a DateTime
  // ...
};
```

### 4. Cambiar Fechas a DateTime (no strings)
```dart
// ANTES
'fecha_inicio': DateTime.now().toIso8601String(),

// DESPUÉS (como el Reciclador)
'fecha_inicio': DateTime.now(),
```

### 5. Actualizar _prepareTransformacionData (líneas 329-376)
El método para guardar borradores también fue actualizado para usar el mismo patrón.

## Diferencias Clave Corregidas

| Aspecto | Antes (Error) | Después (Correcto) |
|---------|---------------|-------------------|
| **Obtención UID** | `getUserProfile()['userId']` | `FirebaseAuth.instance.currentUser.uid` |
| **Verificación** | Sin verificación | Verifica que UID coincida con Auth |
| **Tipo fecha** | String ISO | DateTime object |
| **Consistencia** | Diferente al Reciclador | Igual que Reciclador |

## Verificación en Consola
Ahora verás en los logs:
```
=== USUARIO FIREBASE AUTH ===
Firebase Auth UID: abc123xyz
Usuario Folio: T0000001
=== VERIFICACIÓN DE USUARIO ===
Verificando que UID coincide con Auth: true
```

## Estado
✅ **IMPLEMENTADO** - 2025-01-29

## Testing
1. El sistema ahora obtiene el UID correcto de Firebase Auth
2. Las reglas de Firestore validarán correctamente `usuario_id == request.auth.uid`
3. El Transformador funciona igual que el Reciclador
4. Pueden crear megalotes con 2+ lotes sin errores de permisos

## Nota Importante
El problema fundamental era que `getUserProfile()` retornaba el ID del documento del perfil (que puede coincidir o no con el UID de Auth), mientras que las reglas de Firestore validan contra `request.auth.uid` que es el UID real de autenticación de Firebase.