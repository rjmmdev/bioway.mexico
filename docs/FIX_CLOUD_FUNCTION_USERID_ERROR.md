# 🚨 FIX: Error "Cannot read properties of undefined (reading 'userId')" en Cloud Function

## Fecha: 2025-02-06
## Severidad: ALTA
## Estado: ⏳ PENDIENTE DE DESPLIEGUE

## 🔴 Problema Identificado

### Descripción
La Cloud Function `deleteAuthUser` falla con el siguiente error al intentar eliminar usuarios de Firebase Auth:

```
TypeError: Cannot read properties of undefined (reading 'userId')
at /workspace/index.js:23
```

### Síntomas
- Los usuarios permanecen en Firebase Authentication después de ser eliminados
- Los documentos en `users_pending_deletion` quedan en estado 'pending'
- El Maestro puede eliminar perfiles pero no las cuentas de Auth
- Error visible en los logs de Cloud Functions

## 🐛 Causa Raíz

### Código Problemático
En `functions/index.js`, líneas 22-23:

```javascript
// CÓDIGO INCORRECTO
const context = event.params;
const userId = context.params.userId; // Error: intenta acceder a params.params.userId
```

### Por qué ocurre
- Firebase Functions v2 cambió la estructura del objeto `event`
- El código intenta acceder a `event.params.params.userId` en lugar de `event.params.userId`
- La variable `context` es redundante y causa el error de acceso

## ✅ Solución Implementada

### Código Corregido
```javascript
exports.deleteAuthUser = onDocumentCreated(
  'users_pending_deletion/{userId}',
  async (event) => {
    const snap = event.data;
    const userId = event.params.userId; // Acceso directo correcto
    const data = snap.data();
    
    console.log(`🗑️ Procesando eliminación de usuario: ${userId}`);
    // resto del código...
```

### Cambios realizados
1. **Eliminada** la variable intermedia `context`
2. **Acceso directo** a `event.params.userId`
3. **Simplificado** el código para evitar confusiones

## 📋 Pasos para Desplegar la Corrección

### Opción 1: Usando Git y Cloud Shell

1. **Acceder a Google Cloud Shell**
   ```
   https://console.cloud.google.com
   Proyecto: trazabilidad-ecoce
   Click en icono de terminal (Shell)
   ```

2. **Clonar repositorio**
   ```bash
   git clone [tu-repositorio]
   cd bioway.mexico/functions
   ```

3. **Instalar dependencias**
   ```bash
   npm install
   ```

4. **Configurar Firebase**
   ```bash
   npm install -g firebase-tools
   firebase login --no-localhost
   firebase use trazabilidad-ecoce
   ```

5. **Desplegar función**
   ```bash
   firebase deploy --only functions:deleteAuthUser
   ```

### Opción 2: Creación Manual en Cloud Shell

1. **Crear directorio**
   ```bash
   mkdir -p ~/bioway-functions
   cd ~/bioway-functions
   ```

2. **Crear package.json**
   ```bash
   cat > package.json << 'EOF'
   {
     "name": "biowaymexico-functions",
     "description": "Cloud Functions for BioWay Mexico",
     "engines": {
       "node": "20"
     },
     "main": "index.js",
     "dependencies": {
       "firebase-admin": "^11.11.1",
       "firebase-functions": "^6.4.0"
     }
   }
   EOF
   ```

3. **Crear index.js corregido**
   ```bash
   cat > index.js << 'EOF'
   const { onDocumentCreated } = require('firebase-functions/v2/firestore');
   const admin = require('firebase-admin');
   
   admin.initializeApp();
   
   const db = admin.firestore();
   const auth = admin.auth();
   
   exports.deleteAuthUser = onDocumentCreated(
     'users_pending_deletion/{userId}',
     async (event) => {
       const snap = event.data;
       const userId = event.params.userId; // FIX: Acceso directo
       const data = snap.data();
       
       console.log(`🗑️ Procesando eliminación de usuario: ${userId}`);
       
       try {
         let userRecord;
         try {
           userRecord = await auth.getUser(userId);
           console.log(`✅ Usuario encontrado en Auth: ${userRecord.email}`);
         } catch (error) {
           if (error.code === 'auth/user-not-found') {
             console.log('⚠️ Usuario no encontrado en Auth');
             await snap.ref.update({
               status: 'completed',
               completedAt: admin.firestore.FieldValue.serverTimestamp(),
               error: 'Usuario no encontrado en Auth'
             });
             return null;
           }
           throw error;
         }
         
         await auth.deleteUser(userId);
         console.log(`✅ Usuario ${userId} eliminado de Firebase Auth`);
         
         await snap.ref.update({
           status: 'completed',
           completedAt: admin.firestore.FieldValue.serverTimestamp(),
           deletedEmail: userRecord.email
         });
         
         await db.collection('audit_logs').add({
           action: 'user_deleted_from_auth',
           userId: userId,
           userEmail: userRecord.email,
           deletedAt: admin.firestore.FieldValue.serverTimestamp(),
           deletedBy: data.requestedBy || 'system',
           reason: data.reason || 'No especificada'
         });
         
         console.log('✅ Proceso completado exitosamente');
         
       } catch (error) {
         console.error('❌ Error eliminando usuario:', error);
         
         await snap.ref.update({
           status: 'error',
           errorAt: admin.firestore.FieldValue.serverTimestamp(),
           error: error.message || 'Error desconocido',
           errorCode: error.code || 'unknown'
         });
         
         throw error;
       }
     });
   EOF
   ```

4. **Instalar y desplegar**
   ```bash
   npm install
   npm install -g firebase-tools
   firebase login --no-localhost
   firebase use trazabilidad-ecoce
   firebase deploy --only functions:deleteAuthUser
   ```

## 🔧 Verificación del Fix

### Pasos para verificar
1. Crear un usuario de prueba
2. Eliminarlo desde Maestro
3. Verificar en logs: `firebase functions:log`
4. Confirmar que el usuario desaparece de Firebase Auth
5. Verificar que el documento en `users_pending_deletion` cambia a status 'completed'

### Logs esperados
```
🗑️ Procesando eliminación de usuario: [userId]
✅ Usuario encontrado en Auth: [email]
✅ Usuario [userId] eliminado de Firebase Auth
✅ Proceso completado exitosamente
```

## ⚠️ Notas Importantes

1. **Archivos modificados**:
   - `functions/index.js` - Línea 22 (eliminada línea redundante)
   - `functions/index.js` - Línea 23 (acceso directo a userId)

2. **Dependencias**:
   - La función requiere Firebase Admin SDK
   - Node.js 20 configurado en package.json

3. **Permisos requeridos**:
   - La función necesita permisos para eliminar usuarios de Auth
   - Se ejecuta con credenciales de servicio automáticas

## 🚀 Estado Actual

- ✅ Error identificado
- ✅ Solución implementada localmente
- ⏳ Pendiente: Desplegar a producción
- ⏳ Pendiente: Verificar funcionamiento

## 📞 Impacto del Error

Mientras no se despliegue esta corrección:
- Los usuarios eliminados permanecerán en Firebase Auth
- Solo se eliminarán los perfiles de Firestore
- Los usuarios no podrán acceder (no tienen perfil) pero sus cuentas persisten
- La colección `users_pending_deletion` acumulará registros en estado 'pending'

## 🔍 Solución Temporal

Mientras se despliega el fix:
1. Los usuarios eliminados no pueden acceder (sin perfil)
2. Se pueden eliminar manualmente desde Firebase Console
3. Los registros 'pending' se pueden limpiar manualmente

---

**IMPORTANTE**: Este fix debe desplegarse lo antes posible para restaurar la funcionalidad completa de eliminación de usuarios.