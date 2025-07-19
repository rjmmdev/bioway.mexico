# Configuración de Autenticación en Firebase

## Problema Actual
El error que estás viendo indica que la autenticación por email/contraseña no está habilitada en Firebase:

```
This operation is not allowed. This may be because the given sign-in provider is disabled for this Firebase project.
```

## Solución

### 1. Habilitar Autenticación por Email/Contraseña

1. Ve a la [Consola de Firebase](https://console.firebase.google.com)
2. Selecciona el proyecto **trazabilidad-ecoce**
3. En el menú lateral, ve a **Authentication**
4. Click en la pestaña **Sign-in method**
5. Busca **Email/Password** en la lista
6. Click en el ícono de editar (lápiz)
7. Activa el switch de **Enable**
8. Click en **Save**

### 2. Estructura de Datos Implementada

El sistema ahora funciona con solicitudes de cuenta:

#### Colección: `solicitudes_cuentas`
```json
{
  "id": "auto-generated-id",
  "tipo": "origen",
  "subtipo": "A" | "P",
  "email": "usuario@ejemplo.com",
  "password": "contraseña-temporal",
  "datos_perfil": {
    "ecoce_tipo_actor": "O",
    "ecoce_subtipo": "A" | "P",
    "ecoce_nombre": "Nombre Comercial",
    "ecoce_folio": "PENDIENTE",
    "ecoce_rfc": "RFC123456789",
    // ... todos los demás campos del perfil
  },
  "estado": "pendiente" | "aprobada" | "rechazada",
  "fecha_solicitud": "timestamp",
  "fecha_revision": null,
  "revisado_por": null,
  "comentarios_revision": null
}
```

## Flujo del Sistema

### 1. Registro de Usuario
- Usuario completa el formulario
- Se crea una **solicitud** en `solicitudes_cuentas`
- NO se crea usuario en Firebase Auth todavía
- Estado: `pendiente`

### 2. Aprobación por Maestro
- Maestro revisa solicitudes pendientes
- Al aprobar:
  1. Se crea el usuario en Firebase Auth
  2. Se genera el folio secuencial (A0000001, P0000001, etc.)
  3. Se crea el perfil en `ecoce_profiles`
  4. Se actualiza la solicitud a estado `aprobada`

### 3. Rechazo
- Si se rechaza, la solicitud se marca como `rechazada`
- No se crea usuario en Auth
- Se guarda la razón del rechazo

## Ventajas del Nuevo Sistema

1. **Control Total**: Los usuarios no pueden acceder hasta ser aprobados
2. **Sin Usuarios Fantasma**: Solo se crean usuarios en Auth cuando son aprobados
3. **Auditoría Completa**: Se mantiene registro de todas las solicitudes
4. **Folios Secuenciales**: Solo usuarios aprobados reciben folio
5. **Seguridad**: Las contraseñas están temporalmente en Firestore (considerar encriptación en producción)

## Reglas de Seguridad Recomendadas

Para la colección `solicitudes_cuentas`:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Solicitudes de cuentas
    match /solicitudes_cuentas/{document} {
      // Cualquiera puede crear una solicitud
      allow create: if true;
      
      // Solo usuarios autenticados pueden leer
      allow read: if request.auth != null;
      
      // Solo maestros pueden actualizar
      allow update: if request.auth != null && 
        get(/databases/$(database)/documents/ecoce_profiles/$(request.auth.uid)).data.ecoce_tipo_actor == 'M';
      
      // Nadie puede eliminar
      allow delete: if false;
    }
  }
}
```

## Pruebas

1. **Crear solicitud**: Registra un nuevo usuario origen
2. **Verificar en Firestore**: Revisa que se creó en `solicitudes_cuentas`
3. **Como maestro**: Aprueba la solicitud
4. **Verificar**:
   - Usuario creado en Authentication
   - Perfil creado en `ecoce_profiles` con folio asignado
   - Solicitud marcada como `aprobada`

## Nota Importante

En producción, considera:
- Encriptar las contraseñas en `solicitudes_cuentas`
- Implementar notificaciones por email
- Agregar validación adicional de documentos
- Implementar límite de solicitudes por IP/email