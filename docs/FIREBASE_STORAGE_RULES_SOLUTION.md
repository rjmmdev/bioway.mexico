# Solución para Error 403 en Firebase Storage

## Problema
Los documentos subidos a Firebase Storage muestran error 403 (Permission denied) al intentar acceder a ellos desde el navegador.

## Causa Raíz
Las reglas de seguridad de Firebase Storage están configuradas de forma muy restrictiva, impidiendo el acceso incluso a usuarios autenticados.

## Solución: Configurar Reglas de Firebase Storage

### Paso 1: Acceder a Firebase Console
1. Ir a [Firebase Console](https://console.firebase.google.com)
2. Seleccionar el proyecto `trazabilidad-ecoce`
3. En el menú lateral, ir a **Storage**
4. Hacer clic en la pestaña **Rules**

### Paso 2: Actualizar las Reglas

#### Opción A: Permitir lectura a usuarios autenticados (RECOMENDADO)
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

#### Opción B: Reglas más permisivas para pruebas
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Permitir lectura pública pero escritura solo autenticada
    match /{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

### Paso 3: Publicar las Reglas
1. Después de pegar las reglas, hacer clic en **Publish**
2. Esperar confirmación de que las reglas se han actualizado

## Verificación

### Probar acceso a documentos
1. Cerrar sesión en la aplicación
2. Volver a iniciar sesión
3. Intentar abrir un documento desde el perfil

### Si el problema persiste
1. Verificar que el usuario esté autenticado correctamente
2. Revisar la consola del navegador para ver el error exacto
3. Verificar que las URLs tengan tokens válidos

## Configuración CORS (si es necesario)

Si los documentos siguen sin abrirse, puede ser necesario configurar CORS:

### 1. Crear archivo `cors.json`:
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

### 2. Aplicar configuración con gsutil:
```bash
# Instalar gsutil si no lo tienes
# https://cloud.google.com/storage/docs/gsutil_install

# Aplicar configuración CORS
gsutil cors set cors.json gs://trazabilidad-ecoce.firebasestorage.app
```

## Notas Importantes

1. **Seguridad**: La Opción A es más segura ya que requiere autenticación
2. **Tokens**: Las URLs de Firebase Storage incluyen tokens que expiran después de cierto tiempo
3. **Cache**: Los navegadores pueden cachear respuestas 403, limpiar caché si es necesario
4. **Logs**: Revisar los logs de Firebase para ver intentos de acceso denegados

## Implementación en el Código

La aplicación ya está preparada para manejar estos casos:
- `FirebaseStorageService.getValidDownloadUrl()`: Genera nuevas URLs con tokens válidos
- `DocumentUtils.openDocument()`: Maneja errores y proporciona opciones al usuario
- Diálogo de fallback: Permite copiar URL si el acceso automático falla

## Resultado Esperado

Después de aplicar estas reglas:
1. Los usuarios autenticados podrán ver los documentos
2. Las URLs se abrirán correctamente en el navegador
3. No se mostrará el error 403

## Contacto

Si el problema persiste después de aplicar estas reglas, verificar:
- Estado de autenticación del usuario
- Configuración del proyecto Firebase
- Permisos del bucket de Storage en Google Cloud Console