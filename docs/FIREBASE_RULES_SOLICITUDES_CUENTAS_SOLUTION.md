# Firebase Security Rules: Solicitudes de Cuentas

## Problema
Al intentar registrar una cuenta nueva de proveedor ECOCE (o cualquier tipo de usuario), aparece el error:
```
W/Firestore(31290): Listen for Query(target=Query(solicitudes_cuentas where email==r2@gmail.com and estado==pendiente order by __name__);limitType=LIMIT_TO_FIRST) failed: Status{code=PERMISSION_DENIED, description=Missing or insufficient permissions., cause=null}
```

## Causa
El servicio `EcoceProfileService` intenta verificar si ya existe una solicitud pendiente con el mismo email antes de crear una nueva solicitud:

```dart
// Verificar si el email ya existe en solicitudes pendientes
final existingSolicitud = await _solicitudesCollection
    .where('email', isEqualTo: email)
    .where('estado', isEqualTo: 'pendiente')
    .limit(1)
    .get();
```

Sin embargo, las reglas de Firebase no permiten que usuarios no autenticados lean de la colección `solicitudes_cuentas`.

## Solución

### Opción 1: Modificar las Reglas de Firebase (RECOMENDADA)
Actualizar las reglas de seguridad de Firestore para permitir la verificación de emails duplicados:

```javascript
// En la consola de Firebase > Firestore Database > Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // ... otras reglas existentes ...
    
    // Reglas para solicitudes de cuentas
    match /solicitudes_cuentas/{document} {
      // Permitir crear solicitudes a usuarios no autenticados
      allow create: if true;
      
      // Permitir leer solo para verificar duplicados (email y estado)
      allow read: if resource == null || (
        request.auth == null && 
        request.query.limit <= 1 &&
        'email' in request.query.constraints &&
        'estado' in request.query.constraints
      );
      
      // Solo usuarios autenticados maestros pueden actualizar
      allow update: if request.auth != null && 
        get(/databases/$(database)/documents/ecoce_profiles/maestro/usuarios/$(request.auth.uid)).data.ecoce_aprobado == true;
      
      // No permitir eliminación directa
      allow delete: if false;
    }
  }
}
```

### Opción 2: Modificar el Código (ALTERNATIVA)
Si no se pueden modificar las reglas, se puede eliminar la verificación de duplicados en el cliente:

```dart
// En ecoce_profile_service.dart, comentar o eliminar:
/*
// Verificar si el email ya existe en solicitudes pendientes
final existingSolicitud = await _solicitudesCollection
    .where('email', isEqualTo: email)
    .where('estado', isEqualTo: 'pendiente')
    .limit(1)
    .get();
    
if (existingSolicitud.docs.isNotEmpty) {
  throw 'Ya existe una solicitud pendiente con este correo electrónico';
}
*/
```

**Nota**: Esta opción no es recomendada porque permite solicitudes duplicadas.

### Opción 3: Usar Cloud Functions (MEJOR PRÁCTICA)
Crear una Cloud Function que maneje el registro:

```javascript
exports.createAccountRequest = functions.https.onCall(async (data, context) => {
  const { email, password, tipoUsuario, ...profileData } = data;
  
  // Verificar duplicados del lado del servidor
  const existingRequest = await admin.firestore()
    .collection('solicitudes_cuentas')
    .where('email', '==', email)
    .where('estado', '==', 'pendiente')
    .limit(1)
    .get();
  
  if (!existingRequest.empty) {
    throw new functions.https.HttpsError(
      'already-exists',
      'Ya existe una solicitud pendiente con este correo'
    );
  }
  
  // Crear la solicitud
  const solicitudRef = admin.firestore()
    .collection('solicitudes_cuentas')
    .doc();
    
  await solicitudRef.set({
    id: solicitudRef.id,
    email,
    password, // Deberías hashear esto
    tipo: tipoUsuario,
    estado: 'pendiente',
    fecha_solicitud: admin.firestore.FieldValue.serverTimestamp(),
    ...profileData
  });
  
  return { solicitudId: solicitudRef.id };
});
```

## Implementación Inmediata

Para resolver el problema de inmediato, usa la **Opción 1** y actualiza las reglas de Firebase en la consola.

## Otros Errores en los Logs

Los otros errores relacionados con Google Play Services (`GoogleApiManager`, `FlagRegistrar`) son warnings normales cuando se ejecuta en un emulador sin Google Play Services instalados. No afectan la funcionalidad de Firebase.