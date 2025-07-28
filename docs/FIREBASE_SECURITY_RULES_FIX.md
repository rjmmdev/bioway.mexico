# Corrección de Reglas de Seguridad Firebase Firestore

## Problema
Los usuarios reciben errores `PERMISSION_DENIED` al intentar acceder a:
1. Documentos de reciclador en lotes: `lotes/[loteId]/reciclador/data`
2. Transformaciones filtradas por usuario: `transformaciones where usuario_id==...`

## Solución: Actualizar Reglas de Seguridad

Ve a la consola de Firebase → Firestore Database → Rules y reemplaza con estas reglas:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Función helper para verificar si el usuario está autenticado
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Función para verificar si el usuario es dueño del documento
    function isOwner(userId) {
      return request.auth != null && request.auth.uid == userId;
    }
    
    // Reglas para lotes y sus subcolecciones
    match /lotes/{loteId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated();
      
      // Subcolecciones del lote
      match /{subcollection}/{document} {
        allow read: if isAuthenticated();
        allow write: if isAuthenticated();
      }
      
      // Regla específica para proceso reciclador
      match /reciclador/data {
        allow read: if isAuthenticated();
        allow write: if isAuthenticated();
      }
      
      // Regla para datos generales
      match /datos_generales/info {
        allow read: if isAuthenticated();
        allow write: if isAuthenticated();
      }
    }
    
    // Reglas para transformaciones (megalotes)
    match /transformaciones/{transformacionId} {
      allow read: if isAuthenticated() && (
        // El usuario es el dueño
        isOwner(resource.data.usuario_id) ||
        // O el usuario pertenece a la misma organización (mismo prefijo de folio)
        (resource.data.usuario_folio != null && 
         request.auth.token.folio != null &&
         resource.data.usuario_folio[0] == request.auth.token.folio[0])
      );
      allow create: if isAuthenticated();
      allow update: if isAuthenticated() && (
        isOwner(resource.data.usuario_id) ||
        // Permitir actualización si es para toma de muestra de laboratorio
        (request.resource.data.diff(resource.data).affectedKeys()
          .hasOnly(['muestras_laboratorio', 'peso_disponible']))
      );
      allow delete: if isAuthenticated() && isOwner(resource.data.usuario_id);
    }
    
    // Reglas para sublotes
    match /sublotes/{subloteId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated();
    }
    
    // Reglas para perfiles ECOCE
    match /ecoce_profiles/{document=**} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated();
    }
    
    // Reglas para usuarios
    match /users/{userId} {
      allow read: if isAuthenticated() && isOwner(userId);
      allow write: if isAuthenticated() && isOwner(userId);
    }
    
    // Reglas para solicitudes de cuentas
    match /solicitudes_cuentas/{solicitudId} {
      allow read: if isAuthenticated();
      allow create: if true; // Permitir registro sin autenticación
      allow update, delete: if isAuthenticated();
    }
    
    // Regla general para otras colecciones
    match /{document=**} {
      allow read, write: if isAuthenticated();
    }
  }
}
```

## Reglas Simplificadas (Alternativa más permisiva)

Si las reglas anteriores son muy restrictivas, puedes usar estas reglas más simples:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Permitir todo a usuarios autenticados
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
    
    // Permitir crear solicitudes sin autenticación
    match /solicitudes_cuentas/{solicitudId} {
      allow create: if true;
      allow read, update, delete: if request.auth != null;
    }
  }
}
```

## Pasos para Aplicar

1. Ve a [Firebase Console](https://console.firebase.google.com)
2. Selecciona tu proyecto
3. Ve a Firestore Database → Rules
4. Reemplaza las reglas existentes con las de arriba
5. Click en "Publish"
6. Espera 1-2 minutos para que se propaguen

## Verificación

Después de publicar las reglas:
1. Cierra la app completamente
2. Vuelve a abrirla
3. Haz login de nuevo
4. Los errores de permisos deberían desaparecer

## Notas Importantes

- Las reglas simplificadas permiten a CUALQUIER usuario autenticado leer/escribir TODO
- Para producción, usa las reglas más específicas y ajusta según necesidades
- Los cambios pueden tardar hasta 5 minutos en propagarse completamente