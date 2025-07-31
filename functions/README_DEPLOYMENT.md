# Guía de Despliegue de Cloud Functions para BioWay México

## Resumen

Esta guía explica cómo desplegar las Cloud Functions necesarias para la eliminación de usuarios de Firebase Auth cuando se eliminen desde el panel de administración maestro.

## Prerrequisitos

1. **Firebase CLI instalado**
   ```bash
   npm install -g firebase-tools
   ```

2. **Autenticado en Firebase**
   ```bash
   firebase login
   ```

3. **Node.js 18+ instalado**

## Pasos de Despliegue

### 1. Navegar a la carpeta de funciones
```bash
cd D:\Libreria\Development\rjmmdev\proyectos\biowaymexico\app\functions
```

### 2. Instalar dependencias
```bash
npm install
```

### 3. Configurar el proyecto Firebase
```bash
firebase use trazabilidad-ecoce
```

### 4. Desplegar las funciones
```bash
firebase deploy --only functions
```

Este comando desplegará las siguientes funciones:
- `deleteAuthUser` - Se activa cuando se crea un documento en `users_pending_deletion`
- `retryFailedDeletions` - Se ejecuta cada hora para reintentar eliminaciones fallidas
- `cleanupOldDeletionRecords` - Se ejecuta diariamente para limpiar registros antiguos

## Verificación del Despliegue

### 1. Verificar en Firebase Console
1. Ir a [Firebase Console](https://console.firebase.google.com)
2. Seleccionar el proyecto `trazabilidad-ecoce`
3. Ir a Functions en el menú lateral
4. Verificar que las 3 funciones aparezcan como "Deployed"

### 2. Verificar logs
```bash
firebase functions:log
```

## Flujo de Eliminación de Usuarios

### Proceso Completo:

1. **Usuario Maestro elimina un usuario** desde el panel de administración
   - Se muestra un diálogo de confirmación
   - Se muestra indicador de carga "Eliminando usuario..."

2. **EcoceProfileService.deleteUserCompletely()** se ejecuta:
   - Elimina todos los documentos del perfil en Firestore
   - Elimina archivos de Storage
   - Crea documento en `users_pending_deletion`

3. **Cloud Function se activa** automáticamente:
   - Elimina el usuario de Firebase Auth
   - Registra en audit logs
   - Elimina el documento de la cola

4. **UI se actualiza**:
   - Se muestra mensaje de éxito
   - El usuario desaparece de la lista
   - Se recarga la lista en segundo plano

## Monitoreo

### Verificar eliminaciones pendientes:
```javascript
// En Firebase Console > Firestore
// Colección: users_pending_deletion
// Los documentos aquí están esperando ser procesados
```

### Verificar logs de auditoría:
```javascript
// Colección: audit_logs
// Filtrar por action: 'auth_user_deleted' o 'auth_user_deletion_failed'
```

## Solución de Problemas

### Error: "Permission denied"
- Verificar que las funciones tengan los permisos necesarios
- El service account debe tener rol de `Firebase Admin`

### Error: "User not found"
- El usuario ya fue eliminado de Auth
- Verificar en Authentication de Firebase Console

### Eliminaciones atascadas
- Verificar el campo `retryCount` en `users_pending_deletion`
- Si `retryCount >= 3`, revisar el campo `finalError`
- Eliminar manualmente el documento si es necesario

## Mejoras en la UI del Maestro

La UI ya incluye:

1. **Diálogo de confirmación** con información clara
2. **Indicador de carga** durante la eliminación
3. **Actualización inmediata** de la lista
4. **Mensajes de éxito/error** claros
5. **Recarga automática** en segundo plano

## Notas Importantes

- La eliminación de Auth es **asíncrona** - puede tomar algunos segundos
- Los usuarios eliminados **no pueden recuperarse**
- El email queda disponible para nuevo registro inmediatamente
- Todos los datos del usuario se eliminan permanentemente