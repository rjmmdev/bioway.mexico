# Configuración Técnica Completa - BioWay México

## Índice
1. [Firebase Configuration](#firebase-configuration)
2. [Cloud Functions](#cloud-functions)
3. [Índices de Firestore](#índices-de-firestore)
4. [Reglas de Seguridad](#reglas-de-seguridad)
5. [Troubleshooting](#troubleshooting)

---

## Firebase Configuration

### Storage Rules

Las reglas de Firebase Storage permiten acceso de lectura y escritura a usuarios autenticados:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Regla general para archivos de ECOCE
    match /ecoce/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    // Reglas específicas para documentos de usuarios
    match /ecoce/usuarios/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Reglas para documentos temporales (solicitudes)
    match /ecoce/documentos/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    // Reglas para firmas
    match /firmas/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    // Reglas para fotos de lotes
    match /lotes/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

### Configuración CORS (si es necesario)

Crear archivo `cors.json`:
```json
[
  {
    "origin": ["*"],
    "method": ["GET", "HEAD"],
    "maxAgeSeconds": 3600,
    "responseHeader": ["Content-Type", "Authorization"]
  }
]
```

Aplicar con gsutil:
```bash
gsutil cors set cors.json gs://trazabilidad-ecoce.firebasestorage.app
```

---

## Cloud Functions

### Función para Eliminar Usuarios de Firebase Auth

#### Instalación

```bash
# En la carpeta del proyecto Firebase
mkdir functions
cd functions
npm init -y
npm install firebase-functions firebase-admin
```

#### Código de la función (`functions/index.js`)

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

#### Configuración package.json

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

#### Despliegue

```bash
# Desde el directorio raíz del proyecto
firebase init functions
firebase deploy --only functions
```

---

## Índices de Firestore

### Índices Requeridos

#### 1. Para consultas del sistema unificado

Estos índices son necesarios para el nuevo sistema de transformaciones y sublotes:

```javascript
// Índice para transformaciones por usuario y estado
{
  collectionGroup: "transformaciones",
  fields: [
    { fieldPath: "usuario_id", order: "ASCENDING" },
    { fieldPath: "estado", order: "ASCENDING" },
    { fieldPath: "fecha_inicio", order: "DESCENDING" }
  ]
}

// Índice para sublotes por transformación
{
  collectionGroup: "sublotes",
  fields: [
    { fieldPath: "transformacion_origen", order: "ASCENDING" },
    { fieldPath: "fecha_creacion", order: "DESCENDING" }
  ]
}

// Índice para documentos por entidad
{
  collectionGroup: "documentos",
  fields: [
    { fieldPath: "entidad_origen.id", order: "ASCENDING" },
    { fieldPath: "tipo", order: "ASCENDING" },
    { fieldPath: "fecha_generacion", order: "DESCENDING" }
  ]
}

// Índice para datos_generales (existente)
{
  collectionGroup: "datos_generales",
  fields: [
    { fieldPath: "proceso_actual", order: "ASCENDING" },
    { fieldPath: "fecha_creacion", order: "DESCENDING" }
  ]
}

// Índice para trazabilidad
{
  collection: "trazabilidad_index",
  fields: [
    { fieldPath: "tipo_entidad", order: "ASCENDING" },
    { fieldPath: "fecha_creacion", order: "DESCENDING" }
  ]
}
```

#### 2. Crear índices manualmente

Para el sistema actual, crear estos índices:

- **lotes_reciclador (legacy)**: https://console.firebase.google.com/v1/r/project/trazabilidad-ecoce/firestore/indexes?create_composite=Cltwcm9qZWN0cy90cmF6YWJpbGlkYWQtZWNvY2UvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL2xvdGVzX3JlY2ljbGFkb3IvaW5kZXhlcy9fEAEaCgoGdXNlcklkEAEaEgoOZmVjaGFfY3JlYWNpb24QAhoMCghfX25hbWVfXxAC

- **datos_generales**: https://console.firebase.google.com/v1/r/project/trazabilidad-ecoce/firestore/indexes?create_exemption=CmZwcm9qZWN0cy90cmF6YWJpbGlkYWQtZWNvY2UvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL2RhdG9zX2dlbmVyYWxlcy9maWVsZHMvcHJvY2Vzb19hY3R1YWwQAhoSCg5wcm9jZXNvX2FjdHVhbBAB

#### 3. Desplegar con Firebase CLI

```bash
firebase deploy --only firestore:indexes
```

---

## Reglas de Seguridad

### Firestore Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Función helper para verificar autenticación
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Función helper para verificar tipo de usuario
    function getUserType() {
      return get(/databases/$(database)/documents/ecoce_profiles/$(request.auth.uid)).data.ecoce_tipo_actor;
    }
    
    // Función helper para verificar si es reciclador
    function isReciclador() {
      return isAuthenticated() && getUserType() == 'R';
    }
    
    // Función helper para verificar si es maestro
    function isMaestro() {
      return isAuthenticated() && getUserType() == 'M';
    }
    
    // Reglas para transformaciones
    match /transformaciones/{transformacionId} {
      allow read: if isAuthenticated();
      allow create: if isReciclador() || getUserType() == 'T'; // Reciclador o Transformador
      allow update: if isAuthenticated() && 
        resource.data.usuario_id == request.auth.uid;
      allow delete: if false;
    }
    
    // Reglas para sublotes
    match /sublotes/{subloteId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && 
        exists(/databases/$(database)/documents/transformaciones/$(request.resource.data.transformacion_origen));
      allow update: if isAuthenticated();
      allow delete: if false;
    }
    
    // Reglas para documentos
    match /documentos/{documentoId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update: if false; // Los documentos son inmutables
      allow delete: if false;
    }
    
    // Reglas para trazabilidad_index
    match /trazabilidad_index/{entidadId} {
      allow read: if isAuthenticated();
      allow write: if false; // Solo el sistema puede escribir
    }
    
    // Reglas para users_pending_deletion
    match /users_pending_deletion/{userId} {
      allow create: if isMaestro();
      allow update: if false; // Solo Cloud Functions
      allow read: if false;
      allow delete: if false;
    }
    
    // Reglas para entregas_transporte
    match /entregas_transporte/{entregaId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update: if isAuthenticated();
      allow delete: if isAuthenticated(); // Permitir eliminar entregas completadas
    }
    
    // Reglas existentes del sistema...
    match /lotes/{loteId}/{document=**} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated();
    }
  }
}
```

### Desplegar Reglas

```bash
# Opción 1: Firebase CLI
firebase deploy --only firestore:rules

# Opción 2: Consola de Firebase
# 1. Ir a Firebase Console → Firestore → Rules
# 2. Copiar y pegar las reglas
# 3. Publicar
```

---

## Troubleshooting

### Problemas Comunes y Soluciones

#### 1. Firebase Initialization

**Error**: `No Firebase App '[DEFAULT]' has been created`

**Solución**: Verificar inicialización correcta por plataforma
```dart
// En login screen después de seleccionar plataforma
await _authService.initializeForPlatform(FirebasePlatform.ecoce);
```

#### 2. Storage Access Denied

**Error**: `[storage/unauthorized] User is not authorized`

**Solución**: 
1. Verificar reglas de Storage están publicadas
2. Verificar usuario autenticado
3. Verificar estructura de carpetas

#### 3. Firestore Permission Denied

**Error**: `[cloud_firestore/permission-denied] Missing or insufficient permissions`

**Solución**:
1. Verificar índices creados
2. Verificar reglas de seguridad
3. Verificar autenticación activa

#### 4. QR Scanner Issues

**Problema**: Cámara no se activa

**Solución Android**:
```xml
<!-- AndroidManifest.xml -->
<uses-permission android:name="android.permission.CAMERA" />
```

**Solución iOS**:
```xml
<!-- Info.plist -->
<key>NSCameraUsageDescription</key>
<string>La app necesita acceso a la cámara para escanear códigos QR</string>
```

#### 5. Performance Issues

**Problema**: Listas lentas con muchos elementos

**Solución**: Implementar paginación
```dart
Query query = FirebaseFirestore.instance
  .collection('lotes')
  .orderBy('fecha_creacion', descending: true)
  .limit(20);
```

### Herramientas de Debug

#### Firebase Debug Logging
```bash
adb shell setprop log.tag.FA VERBOSE
adb shell setprop log.tag.FA-SVC VERBOSE
adb logcat -v time -s FA FA-SVC
```

#### Verificar Cloud Functions
```bash
firebase functions:log
```

#### Monitorear Firestore
- Firebase Console → Firestore → Usage
- Firebase Console → Functions → Logs
- Firebase Console → Storage → Usage

### Contacto para Soporte

Si persisten problemas después de seguir esta guía:

1. Verificar logs en Firebase Console
2. Revisar `SISTEMA_TRANSFORMACIONES_SUBLOTES.md` para la arquitectura
3. Consultar CLAUDE.md en el proyecto para guías específicas

---

*Documento actualizado: 2025-01-27*
*Versión: 2.0.0*
*Compatible con: Sistema de Transformaciones y Sublotes*