# Verificación de Reglas de Firebase Storage

## Problema Actual
Los documentos subidos a Firebase Storage no pueden ser visualizados, mostrando error 403 (Permission denied).

## Posibles Causas

### 1. Reglas de Firebase Storage
Las reglas actuales de Firebase Storage pueden estar configuradas para requerir autenticación o tener restricciones específicas.

#### Reglas Recomendadas para ECOCE
```javascript
// Opción 1: Permitir lectura a usuarios autenticados
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Permitir lectura a usuarios autenticados
    match /ecoce/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    // Documentos de usuarios
    match /ecoce/usuarios/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Documentos de solicitudes (temporal)
    match /ecoce/documentos/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

#### Opción 2: URLs públicas con tiempo de expiración
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Hacer públicos los documentos pero con control en la aplicación
    match /ecoce/{allPaths=**} {
      allow read: if true;  // Público para lectura
      allow write: if request.auth != null;
    }
  }
}
```

### 2. Configuración de CORS
El bucket de Firebase Storage puede necesitar configuración CORS para permitir acceso desde el navegador.

#### Archivo cors.json
```json
[
  {
    "origin": ["*"],
    "method": ["GET"],
    "maxAgeSeconds": 3600
  }
]
```

#### Aplicar configuración CORS
```bash
gsutil cors set cors.json gs://trazabilidad-ecoce.firebasestorage.app
```

## Solución Implementada en el Código

1. **Simplificación del manejo de URLs**: Se eliminó la lógica compleja de actualización de tokens
2. **Acceso directo al navegador**: Las URLs se abren directamente en el navegador externo
3. **Fallback con copia manual**: Si falla la apertura automática, se permite copiar la URL

## Pasos para Verificar

1. **Verificar reglas actuales en Firebase Console**:
   - Ir a Firebase Console > Storage > Reglas
   - Verificar las reglas actuales

2. **Probar con reglas temporales públicas**:
   ```javascript
   allow read: if true;
   ```

3. **Verificar autenticación del usuario**:
   - Confirmar que el usuario está autenticado al intentar acceder
   - Verificar que Firebase Auth está inicializado correctamente

## URLs de Prueba

Para verificar si el problema es específico de Firebase Storage o general:

1. Subir un archivo de prueba manualmente a Firebase Storage
2. Hacer el archivo público desde la consola
3. Intentar acceder con la URL pública
4. Si funciona, el problema son las reglas de seguridad

## Recomendación

La mejor solución es configurar las reglas de Firebase Storage para permitir lectura a usuarios autenticados, manteniendo la seguridad pero permitiendo el acceso necesario para la aplicación.