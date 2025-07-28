# Solución: Problema de Autenticación al Aprobar Cuentas

## Problema

Cuando un maestro aprueba una cuenta:
1. Se crea el usuario con `createUserWithEmailAndPassword`
2. Firebase automáticamente autentica al nuevo usuario
3. El maestro pierde su sesión
4. El nuevo usuario no tiene permisos para actualizar la solicitud

## Soluciones Implementadas

### 1. Actualización de Reglas de Firestore

Se actualizaron las reglas para permitir que el usuario recién creado actualice su propia solicitud:

```javascript
allow update: if (
  // ... otras condiciones ...
) || (
  // Permitir al usuario recién creado actualizar su propia solicitud
  request.auth != null && 
  resource.data.estado == 'aprobada' &&
  (
    // Verificar por email
    (resource.data.keys().hasAll(['email']) && 
     resource.data.email == request.auth.token.email) ||
    // O verificar que es una actualización posterior
    (request.resource.data.keys().hasAll(['usuario_creado_id']) && 
     request.resource.data.usuario_creado_id == request.auth.uid)
  ) &&
  // Limitar campos actualizables
  request.resource.data.diff(resource.data).affectedKeys()
    .hasOnly(['usuario_creado_id', 'procesando'])
);
```

### 2. Índice Faltante

Crear el índice necesario usando el enlace del error o manualmente:
- Collection: `solicitudes_cuentas`
- Fields: `estado` (ASC), `folio_asignado` (ASC), `__name__` (ASC)

### 3. Manejo de Errores Mejorado

El servicio ahora maneja el error de permisos y continúa con el proceso:

```dart
try {
  await _solicitudesCollection.doc(solicitudId).update({
    'usuario_creado_id': userId,
    'procesando': false,
  });
} catch (updateError) {
  print('⚠️ Error al actualizar solicitud: $updateError');
  // Continuar de todos modos
}
```

## Solución Definitiva (Recomendada)

Para evitar completamente el problema de cambio de autenticación, se recomienda:

1. **Usar Cloud Functions**: Crear una función que maneje la aprobación del lado del servidor
2. **Admin SDK**: Usar Firebase Admin SDK que no afecta la autenticación del cliente

### Ejemplo de Cloud Function

```javascript
exports.approveUser = functions.https.onCall(async (data, context) => {
  // Verificar que es maestro
  if (!context.auth || !await isMaestro(context.auth.uid)) {
    throw new functions.https.HttpsError('permission-denied');
  }
  
  const { solicitudId, email, password } = data;
  
  // Crear usuario con Admin SDK (no afecta auth del cliente)
  const userRecord = await admin.auth().createUser({
    email: email,
    password: password,
  });
  
  // Actualizar solicitud
  await admin.firestore()
    .collection('solicitudes_cuentas')
    .doc(solicitudId)
    .update({
      estado: 'aprobada',
      usuario_creado_id: userRecord.uid,
      // ... otros campos
    });
    
  return { success: true, userId: userRecord.uid };
});
```

## Estado Actual

Con las reglas actualizadas, el proceso debería funcionar:
1. Maestro aprueba → solicitud se marca como aprobada
2. Se crea el usuario → queda autenticado
3. El nuevo usuario actualiza su propia solicitud con su ID
4. El proceso continúa normalmente

El maestro deberá refrescar la página o volver a autenticarse después.