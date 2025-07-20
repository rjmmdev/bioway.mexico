# Cloud Function para Eliminar Usuarios de Firebase Auth

## Descripción
Esta Cloud Function procesa las solicitudes de eliminación de usuarios de Firebase Authentication que se crean desde la aplicación Flutter.

## Flujo de Trabajo
1. La app Flutter marca usuarios para eliminación en la colección `users_pending_deletion`
2. La Cloud Function se activa cuando se crea un nuevo documento
3. Elimina el usuario de Firebase Authentication
4. Actualiza el documento con el estado de la operación

## Implementación

### 1. Crear el proyecto de Cloud Functions

```bash
# En la carpeta del proyecto Firebase
mkdir functions
cd functions
npm init -y
npm install firebase-functions firebase-admin
```

### 2. Código de la Cloud Function

Crear archivo `functions/index.js`:

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Cloud Function para eliminar usuarios de Authentication
exports.deleteUserFromAuth = functions.firestore
  .document('users_pending_deletion/{userId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const userId = context.params.userId;
    
    try {
      // Eliminar usuario de Firebase Authentication
      await admin.auth().deleteUser(userId);
      
      // Actualizar el documento con éxito
      await snap.ref.update({
        status: 'completed',
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
        error: null
      });
      
      console.log(`Usuario ${userId} eliminado exitosamente de Authentication`);
      
      // Opcional: Eliminar el documento después de procesarlo
      // await snap.ref.delete();
      
    } catch (error) {
      console.error(`Error al eliminar usuario ${userId}:`, error);
      
      // Actualizar el documento con el error
      await snap.ref.update({
        status: 'failed',
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
        error: error.message
      });
    }
  });

// Función programada para limpiar documentos procesados (opcional)
exports.cleanupProcessedDeletions = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    const db = admin.firestore();
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    
    const snapshot = await db.collection('users_pending_deletion')
      .where('status', 'in', ['completed', 'failed'])
      .where('completedAt', '<', thirtyDaysAgo)
      .get();
    
    const batch = db.batch();
    snapshot.docs.forEach(doc => {
      batch.delete(doc.ref);
    });
    
    await batch.commit();
    console.log(`Eliminados ${snapshot.size} registros antiguos de eliminación`);
  });
```

### 3. Configurar package.json

```json
{
  "name": "functions",
  "version": "1.0.0",
  "description": "Cloud Functions for BioWay Mexico",
  "main": "index.js",
  "scripts": {
    "serve": "firebase emulators:start --only functions",
    "shell": "firebase functions:shell",
    "start": "npm run shell",
    "deploy": "firebase deploy --only functions",
    "logs": "firebase functions:log"
  },
  "engines": {
    "node": "18"
  },
  "dependencies": {
    "firebase-admin": "^11.11.0",
    "firebase-functions": "^4.5.0"
  }
}
```

### 4. Desplegar la función

```bash
# Asegurarse de estar en el directorio del proyecto
cd ..

# Inicializar Functions en el proyecto
firebase init functions

# Desplegar
firebase deploy --only functions
```

## Seguridad

### Reglas de Firestore
Agregar reglas para la colección `users_pending_deletion`:

```javascript
// En firestore.rules
match /users_pending_deletion/{userId} {
  // Solo el usuario maestro puede crear documentos
  allow create: if request.auth != null && 
                   request.auth.uid in get(/databases/$(database)/documents/maestro_users/authorized).data.userIds;
  
  // Solo la Cloud Function (admin) puede actualizar
  allow update: if false;
  
  // Nadie puede leer directamente
  allow read: if false;
  
  // Solo admin puede eliminar
  allow delete: if false;
}
```

## Monitoreo

### Logs
Ver logs de la función:
```bash
firebase functions:log
```

### Métricas
En Firebase Console > Functions, puedes ver:
- Número de ejecuciones
- Errores
- Duración promedio
- Uso de memoria

## Consideraciones

1. **Costo**: Cada ejecución de Cloud Function tiene un costo (hay cuota gratuita)
2. **Latencia**: La eliminación no es instantánea, puede tomar unos segundos
3. **Límites**: Firebase Auth tiene límites de eliminación por segundo
4. **Auditoría**: Los registros en `audit_logs` se mantienen para historial

## Alternativa: Firebase Admin SDK en Backend

Si tienes un backend propio, puedes implementar un endpoint:

```javascript
// Ejemplo con Express.js
const express = require('express');
const admin = require('firebase-admin');

app.delete('/api/users/:userId', async (req, res) => {
  try {
    // Verificar autenticación y permisos
    const idToken = req.headers.authorization?.split('Bearer ')[1];
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    
    // Verificar que es usuario maestro
    const userDoc = await admin.firestore()
      .collection('ecoce_profiles')
      .doc(decodedToken.uid)
      .get();
    
    if (userDoc.data()?.ecoce_tipo_actor !== 'M') {
      return res.status(403).json({ error: 'No autorizado' });
    }
    
    // Eliminar usuario
    await admin.auth().deleteUser(req.params.userId);
    
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

## Estado Actual

Mientras no se implemente la Cloud Function:
1. Los usuarios se eliminan de Firestore completamente ✅
2. Se crea registro en `users_pending_deletion` ✅
3. El usuario no puede acceder al sistema ✅
4. El usuario permanece en Firebase Auth ⚠️

Una vez implementada la Cloud Function:
- Los usuarios se eliminarán automáticamente de Firebase Auth
- El proceso será completamente transparente para el usuario maestro