# Solución: Aprobación de Cuentas ECOCE

## Problema Identificado

Al aprobar una solicitud de cuenta como usuario maestro, ocurrían los siguientes errores:

1. **La solicitud permanecía en estado "Pendiente"** después de aprobarla
2. **Error de permisos PERMISSION_DENIED** al intentar actualizar la solicitud
3. **El usuario se creaba en Firebase Auth pero no podía iniciar sesión** porque el perfil no se creaba correctamente
4. **Índice faltante** para la generación de folios

## Causa Raíz

El problema principal ocurría porque:

1. Cuando se crea un usuario con `createUserWithEmailAndPassword`, Firebase automáticamente autentica al nuevo usuario
2. Esto cambiaba el contexto de autenticación del maestro al nuevo usuario
3. El nuevo usuario no tiene permisos para actualizar/eliminar la solicitud
4. Esto causaba el error PERMISSION_DENIED

## Solución Implementada

### 1. Actualización del flujo de aprobación

Modificamos `ecoce_profile_service.dart` para:

```dart
// ANTES: Crear usuario primero, luego actualizar solicitud
// DESPUÉS: Actualizar solicitud primero, luego crear usuario

// 1. Generar folio
folio = await _generateFolio(tipoActor, subtipo);

// 2. Actualizar solicitud ANTES de crear el usuario
await _solicitudesCollection.doc(solicitudId).update({
  'estado': 'aprobada',
  'fecha_revision': FieldValue.serverTimestamp(),
  'aprobado_por': approvedById,
  'folio_asignado': folio,
  'procesando': true,
});

// 3. Crear usuario en Auth
userCredential = await _auth.createUserWithEmailAndPassword(...);

// 4. Actualizar con el ID del usuario creado
await _solicitudesCollection.doc(solicitudId).update({
  'usuario_creado_id': userId,
  'procesando': false,
});
```

### 2. Creación del índice en ecoce_profiles

Agregamos la creación del índice para permitir búsquedas rápidas:

```dart
await _profilesCollection.doc(userId).set({
  'path': _getProfilePath(tipoActor, subtipo, userId),
  'folio': folio,
  'aprobado': true,
  'tipo': subtipo,
  'fecha_aprobacion': FieldValue.serverTimestamp(),
});
```

### 3. Mantener solicitudes como registro histórico

En lugar de eliminar las solicitudes aprobadas, las mantenemos con `estado: 'aprobada'` para:
- Evitar problemas de permisos
- Mantener un registro histórico
- Permitir auditorías

### 4. Índices de Firestore

Agregamos el índice necesario en `firestore.indexes.json`:

```json
{
  "collectionGroup": "solicitudes_cuentas",
  "queryScope": "COLLECTION",
  "fields": [
    {
      "fieldPath": "estado",
      "order": "ASCENDING"
    },
    {
      "fieldPath": "folio_asignado",
      "order": "ASCENDING"
    }
  ]
}
```

## Despliegue de la Solución

### 1. Desplegar reglas e índices

```bash
# Windows
scripts\deploy_firebase_config.bat

# Mac/Linux
chmod +x scripts/deploy_firebase_config.sh
./scripts/deploy_firebase_config.sh
```

### 2. Esperar a que los índices se construyan

Los índices pueden tardar 5-10 minutos en estar disponibles después del despliegue.

### 3. Verificar la configuración del usuario maestro

El sistema automáticamente configura el usuario maestro al iniciar sesión, creando un documento en la colección `maestros`.

## Limitaciones Conocidas

1. **Cambio de contexto de autenticación**: Después de aprobar una cuenta, el nuevo usuario queda autenticado brevemente. La app debe manejar esto apropiadamente.

2. **Índices**: Los índices deben crearse manualmente la primera vez o mediante el script de despliegue.

3. **Solicitudes históricas**: Las solicitudes aprobadas permanecen en la base de datos con `estado: 'aprobada'`.

## Pruebas

Para verificar que la solución funciona:

1. Iniciar sesión como maestro
2. Aprobar una solicitud pendiente
3. Verificar que:
   - La solicitud ya no aparece en "Pendientes"
   - El usuario aparece en la pestaña "Usuarios"
   - Se puede iniciar sesión con la cuenta aprobada
   - El folio se asignó correctamente

## Mantenimiento

- Las solicitudes con `estado: 'aprobada'` pueden eliminarse periódicamente si se desea
- Los logs de auditoría en `audit_logs` registran todas las aprobaciones
- El sistema de folios incrementa automáticamente basándose en solicitudes aprobadas