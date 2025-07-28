# Solución: Flujo de Registro y Aprobación sin Cambio de Sesión

## Problema Original

Cuando un maestro aprobaba una cuenta:
1. Se creaba el usuario con `createUserWithEmailAndPassword`
2. Firebase automáticamente autenticaba al nuevo usuario
3. El maestro perdía su sesión
4. Aparecían errores de permisos

## Solución Implementada

### Nuevo Flujo de Registro y Aprobación

#### 1. **Registro de Usuario** (`createAccountRequest`)
- El usuario llena el formulario de registro
- Se crea el usuario en Firebase Auth inmediatamente
- Se cierra sesión automáticamente después de crear el usuario
- Se guarda la solicitud en `solicitudes_cuentas` con:
  - `usuario_creado_id`: ID del usuario en Auth
  - `auth_creado`: true/false
  - `estado`: 'pendiente'

#### 2. **Login de Usuario** (`signInWithEmailAndPassword`)
- El usuario intenta iniciar sesión
- Se verifica si existe una solicitud en `solicitudes_cuentas`
- Si la solicitud está:
  - **Pendiente**: Se muestra pantalla de "Cuenta pendiente de aprobación"
  - **Rechazada**: Se muestra mensaje de rechazo
  - **Aprobada**: Se permite el acceso normal

#### 3. **Aprobación por Maestro** (`approveSolicitud`)
- El maestro revisa la solicitud
- Al aprobar:
  - NO se crea usuario (ya existe)
  - Se genera el folio
  - Se actualiza la solicitud
  - Se crea el perfil en la subcolección correspondiente
  - Se crea el índice en `ecoce_profiles`
- **No hay cambio de sesión** porque no se crea usuario nuevo

#### 4. **Rechazo por Maestro** (`rejectSolicitud`)
- El maestro rechaza la solicitud
- Se marca el usuario para eliminación en `users_pending_deletion`
- Se eliminan archivos de Storage
- Se elimina la solicitud
- Una Cloud Function eliminará el usuario de Auth

## Ventajas del Nuevo Flujo

1. **Sin cambio de sesión**: El maestro mantiene su sesión al aprobar
2. **Mayor seguridad**: Los usuarios no pueden acceder hasta ser aprobados
3. **Mejor UX**: El usuario sabe inmediatamente si su registro fue exitoso
4. **Prevención de duplicados**: Firebase Auth previene emails duplicados automáticamente

## Cambios en el Código

### 1. `createAccountRequest` - Crear usuario en Auth durante registro
```dart
// Crear usuario en Firebase Auth DURANTE EL REGISTRO
userCredential = await _auth.createUserWithEmailAndPassword(
  email: email,
  password: password,
);

// Cerrar sesión inmediatamente
await _auth.signOut();

// Guardar solicitud con usuario_creado_id
solicitudData['usuario_creado_id'] = userId;
solicitudData['auth_creado'] = true;
```

### 2. `approveSolicitud` - Simplificado sin crear usuario
```dart
// Verificar si el usuario ya fue creado
final authCreado = solicitudData['auth_creado'] ?? false;
userId = solicitudData['usuario_creado_id'];

if (!authCreado || userId == null) {
  throw Exception('El usuario no fue creado en Auth');
}

// Solo actualizar estado y crear perfil
// No hay createUserWithEmailAndPassword
```

### 3. Login Screen - Ya verifica estado de solicitud
```dart
// El código existente ya maneja correctamente:
final solicitud = await _profileService.checkAccountRequestStatus(email);
if (solicitud != null) {
  final estado = solicitud['estado'];
  if (estado == 'pendiente') {
    // Mostrar pantalla de pendiente
  } else if (estado == 'rechazada') {
    // Mostrar mensaje de rechazo
  }
}
```

## Reglas de Firestore Simplificadas

```javascript
match /solicitudes_cuentas/{solicitudId} {
  allow create: if true;
  allow read: if isAuthenticated();
  allow update: if (
    // Para subir documentos sin auth
    request.auth == null && 
    request.resource.data.diff(resource.data).affectedKeys()
      .hasOnly(['documentos']) 
  ) || isMaestro();
  allow delete: if isMaestro();
}
```

## Consideraciones

1. **Cloud Function necesaria**: Para eliminar usuarios de Auth cuando se rechazan
2. **Índice requerido**: El índice para búsqueda de folios debe crearse
3. **Usuarios existentes**: Los usuarios ya aprobados continúan funcionando normalmente

## Estado del Sistema

- ✅ Registro crea usuario en Auth
- ✅ Login verifica estado de aprobación  
- ✅ Aprobación no cambia sesión del maestro
- ✅ Rechazo marca usuario para eliminación
- ⏳ Cloud Function para eliminar usuarios rechazados (pendiente)