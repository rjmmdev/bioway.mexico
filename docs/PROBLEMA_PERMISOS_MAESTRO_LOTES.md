# Problema de Permisos - Maestro y Lotes Huérfanos

## Descripción del Problema

El usuario Maestro no puede acceder a la colección `lotes` ni usar `collectionGroup` queries para detectar lotes huérfanos.

## Errores Encontrados

### 1. Error con collectionGroup
```
Listen for Query(target=Query( collectionGroup=datos_generales order by __name__);limitType=LIMIT_TO_FIRST) failed: 
Status{code=PERMISSION_DENIED, description=Missing or insufficient permissions., cause=null}
```

### 2. Error con colección directa
```
Listen for Query(target=Query(lotes order by __name__);limitType=LIMIT_TO_FIRST) failed: 
Status{code=PERMISSION_DENIED, description=Missing or insufficient permissions., cause=null}
```

## Causa Raíz

Las reglas de Firestore actuales no permiten al maestro:
1. Leer la colección `lotes` directamente
2. Usar `collectionGroup` queries en `datos_generales`

## Solución Temporal

Se implementó un generador de datos mock para probar la funcionalidad de la UI mientras se resuelven los permisos.

```dart
// En maestro_orphan_lots_screen.dart
if (true) { // Cambiar a false cuando se resuelvan los permisos
  return _generateMockOrphanLots();
}
```

## Solución Permanente

### Opción 1: Actualizar Reglas de Firestore

Agregar permisos específicos para maestro:

```javascript
// Permitir al maestro leer todos los lotes
match /lotes/{loteId} {
  allow read: if isMaestro();
}

// Permitir collectionGroup queries para maestro
match /{path=**}/datos_generales/{doc} {
  allow read: if isMaestro();
}
```

### Opción 2: Cloud Function

Crear una Cloud Function que el maestro pueda llamar:

```javascript
exports.detectOrphanLots = functions.https.onCall(async (data, context) => {
  // Verificar que es maestro
  const userId = context.auth?.uid;
  if (!userId) throw new functions.https.HttpsError('unauthenticated');
  
  const maestroDoc = await admin.firestore()
    .collection('maestros')
    .doc(userId)
    .get();
    
  if (!maestroDoc.exists) {
    throw new functions.https.HttpsError('permission-denied', 'Usuario no es maestro');
  }
  
  // Detectar lotes huérfanos con privilegios de admin
  const lotesSnapshot = await admin.firestore()
    .collectionGroup('datos_generales')
    .where(admin.firestore.FieldPath.documentId(), '==', 'info')
    .get();
    
  const orphanLots = [];
  
  for (const doc of lotesSnapshot.docs) {
    const creadoPor = doc.data().creado_por;
    if (creadoPor) {
      const userExists = await admin.firestore()
        .collection('ecoce_profiles')
        .doc(creadoPor)
        .get()
        .then(doc => doc.exists);
        
      if (!userExists) {
        orphanLots.push({
          loteId: doc.ref.parent.parent.id,
          userId: creadoPor,
          // ... más datos
        });
      }
    }
  }
  
  return { orphanLots };
});
```

## Estado Actual

- La funcionalidad de UI está completa y funcional con datos mock
- Se requiere decisión sobre qué enfoque usar para resolver los permisos
- Una vez resuelto, cambiar `if (true)` a `if (false)` en el código

## Archivos Afectados

- `/lib/screens/ecoce/maestro/maestro_orphan_lots_screen.dart`
- `/lib/services/lote_unificado_service.dart`
- Reglas de Firestore (pendiente de actualización)