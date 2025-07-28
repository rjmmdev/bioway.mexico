# Cloud Functions para Eliminación de Usuarios

## Descripción

Este documento describe las Cloud Functions implementadas para manejar la eliminación de usuarios de Firebase Auth cuando se rechazan o eliminan cuentas desde la aplicación.

## Funciones Implementadas

### 1. `deleteAuthUser` (Trigger: onCreate)

**Trigger**: Se activa cuando se crea un documento en `users_pending_deletion/{userId}`

**Propósito**: Eliminar automáticamente un usuario de Firebase Auth

**Flujo**:
1. Lee el documento creado con el ID del usuario
2. Verifica que el usuario existe en Auth
3. Elimina el usuario de Auth
4. Actualiza el estado del documento a 'completed'
5. Crea un registro en `audit_logs`

**Manejo de errores**:
- Si el usuario no existe en Auth, marca como completado
- Si hay error, actualiza el documento con el error

### 2. `cleanupOldDeletionRecords` (Scheduled)

**Schedule**: Diariamente a las 2:00 AM (México)

**Propósito**: Limpiar registros antiguos de `users_pending_deletion`

**Flujo**:
1. Busca documentos con más de 30 días
2. Elimina en lotes (máximo 500 por batch)
3. Registra en `audit_logs`

### 3. `manualDeleteUser` (Callable)

**Tipo**: HTTPS Callable Function

**Propósito**: Permitir eliminación manual por maestros

**Seguridad**:
- Requiere autenticación
- Verifica que el usuario es maestro

**Uso desde la app**:
```dart
final functions = FirebaseFunctions.instance;
final callable = functions.httpsCallable('manualDeleteUser');
final result = await callable.call({
  'userId': 'USER_ID_TO_DELETE',
  'reason': 'Razón de eliminación'
});
```

### 4. `healthCheck` (HTTP)

**Tipo**: HTTPS Request

**Propósito**: Verificar el estado del sistema

**URL**: `https://us-central1-trazabilidad-ecoce.cloudfunctions.net/healthCheck`

## Estructura de Datos

### Documento en `users_pending_deletion`:
```json
{
  "userId": "ID_DEL_USUARIO",
  "userEmail": "email@ejemplo.com",
  "requestedBy": "ID_DEL_MAESTRO",
  "requestedAt": "timestamp",
  "status": "pending|completed|error",
  "reason": "solicitud_rechazada|eliminacion_manual",
  "rejectionReason": "Razón específica del rechazo",
  
  // Campos agregados por la función:
  "completedAt": "timestamp",
  "deletedEmail": "email@ejemplo.com",
  "error": "mensaje de error si falla",
  "errorCode": "código de error"
}
```

### Registro en `audit_logs`:
```json
{
  "action": "user_deleted_from_auth",
  "userId": "ID_DEL_USUARIO",
  "userEmail": "email@ejemplo.com",
  "deletedAt": "timestamp",
  "deletedBy": "ID_DEL_SOLICITANTE",
  "reason": "razón",
  "rejectionReason": "razón específica si aplica"
}
```

## Instalación y Despliegue

### 1. Instalar dependencias:
```bash
cd functions
npm install
```

### 2. Configurar Firebase:
```bash
firebase use trazabilidad-ecoce
```

### 3. Desplegar funciones:
```bash
# Desplegar todas las funciones
firebase deploy --only functions

# Desplegar función específica
firebase deploy --only functions:deleteAuthUser
```

### 4. Ver logs:
```bash
firebase functions:log

# Seguir logs en tiempo real
firebase functions:log --follow

# Ver logs de función específica
firebase functions:log --only deleteAuthUser
```

## Integración con la App

La app ya está configurada para usar estas funciones:

1. **Al rechazar solicitud** (`rejectSolicitud`):
   - Crea documento en `users_pending_deletion`
   - La función se activa automáticamente

2. **Al eliminar usuario** (`deleteUserCompletely`):
   - Crea documento en `users_pending_deletion`
   - La función se activa automáticamente

## Monitoreo

### Firebase Console:
1. Ir a Functions en Firebase Console
2. Ver métricas de ejecución
3. Revisar logs de errores

### Colección `users_pending_deletion`:
- `status: 'pending'` - Esperando procesamiento
- `status: 'completed'` - Usuario eliminado exitosamente
- `status: 'error'` - Error en la eliminación

## Costos

Las funciones tienen los siguientes costos asociados:
- **deleteAuthUser**: Por cada eliminación de usuario
- **cleanupOldDeletionRecords**: Una ejecución diaria
- **manualDeleteUser**: Por cada llamada
- **healthCheck**: Por cada verificación

Primeros 2 millones de invocaciones/mes son gratuitos.

## Troubleshooting

### Error: "Usuario no encontrado en Auth"
- Normal si el usuario ya fue eliminado manualmente
- La función marca como completado de todos modos

### Error: "Permission denied"
- Verificar que las funciones tienen permisos de Admin
- Verificar que el proyecto está correctamente configurado

### Los usuarios no se eliminan
1. Verificar logs: `firebase functions:log`
2. Verificar que el documento se crea en `users_pending_deletion`
3. Verificar que el userId es correcto

## Seguridad

- Solo los maestros pueden crear documentos en `users_pending_deletion`
- Las funciones usan Admin SDK (permisos totales)
- Los logs de auditoría registran todas las operaciones
- La función scheduled limpia datos antiguos automáticamente