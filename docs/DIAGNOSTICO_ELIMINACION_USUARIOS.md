# Diagnóstico: Problema de Eliminación de Usuarios

## Problema
El usuario maestro no puede eliminar cuentas desde la pestaña "Usuarios", a pesar de tener las reglas de Firestore configuradas correctamente.

## Puntos de Verificación

### 1. Verificar que el usuario maestro esté configurado

En Firebase Console o usando el script:
```bash
node scripts/verificar_maestro.js
```

El usuario maestro debe tener un documento en `maestros/{uid}` con:
```json
{
  "activo": true,
  "nombre": "Maestro ECOCE",
  "email": "maestro@email.com",
  "permisos": {
    "aprobar_solicitudes": true,
    "eliminar_usuarios": true,
    "gestionar_sistema": true
  }
}
```

### 2. Reglas de Firestore Actualizadas

Las reglas han sido actualizadas para permitir explícitamente:
```javascript
// Usuarios pendientes de eliminación
match /users_pending_deletion/{userId} {
  allow read: if isMaestro();
  allow create: if isMaestro();
  allow update: if isMaestro();
  allow delete: if isMaestro();
}

// Logs de auditoría
match /audit_logs/{logId} {
  allow read: if isMaestro();
  allow create: if isMaestro();
}
```

### 3. Proceso de Eliminación

El proceso `deleteUserCompletely` realiza las siguientes operaciones:
1. Busca el perfil del usuario en todas las subcolecciones
2. Elimina archivos de Storage
3. Elimina el documento del perfil
4. Elimina el índice en `ecoce_profiles`
5. Elimina solicitudes aprobadas asociadas
6. Crea un log de auditoría
7. Marca el usuario para eliminación en `users_pending_deletion`

### 4. Posibles Causas del Error

#### A. El usuario maestro no está autenticado correctamente
- Verificar que `_maestroUserId` tenga el UID correcto
- Confirmar que el usuario no se desautenticó después de aprobar cuentas

#### B. Problemas de caché del navegador/app
- Las reglas pueden estar cacheadas
- Intentar cerrar sesión y volver a iniciar

#### C. Error específico no capturado
- Revisar la consola del navegador para errores específicos
- Verificar logs de Firebase

## Solución Propuesta

### Paso 1: Verificar el usuario maestro
```javascript
// En maestro_unified_screen.dart, agregar log
print('Maestro UID al eliminar: $_maestroUserId');
```

### Paso 2: Capturar error específico
Modificar el manejo de errores en `_deleteUser` para mostrar más detalles:
```dart
} catch (e) {
  print('Error detallado al eliminar: $e');
  print('Stack trace: ${StackTrace.current}');
  _showErrorMessage('Error al eliminar usuario: ${e.toString()}');
}
```

### Paso 3: Verificar permisos en tiempo real
Agregar verificación antes de eliminar:
```dart
// Verificar si el usuario actual es maestro
final maestroDoc = await FirebaseFirestore.instance
    .collection('maestros')
    .doc(_maestroUserId)
    .get();
    
if (!maestroDoc.exists) {
  throw Exception('Usuario no configurado como maestro');
}
```

## Script de Prueba Manual

Para probar los permisos manualmente:

1. Abrir la consola de Firebase
2. Ir a Firestore Database
3. Intentar crear manualmente un documento en `users_pending_deletion`
4. Si funciona desde la consola pero no desde la app, el problema es de autenticación

## Logs a Revisar

1. **Console del navegador**: Buscar errores PERMISSION_DENIED
2. **Firebase Console > Functions > Logs**: Ver si hay errores en Cloud Functions
3. **Network tab**: Verificar las llamadas a Firestore

## Próximos Pasos

1. Ejecutar el script de verificación de maestros
2. Agregar logs detallados al código
3. Probar eliminación con un usuario de prueba
4. Verificar que las reglas estén desplegadas correctamente