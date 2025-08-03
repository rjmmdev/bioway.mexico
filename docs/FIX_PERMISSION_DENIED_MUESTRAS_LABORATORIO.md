# Fix: Permission Denied al Cargar Muestras de Laboratorio

## Fecha de Identificación y Solución
**2025-01-29**

## ACTUALIZACIÓN: Solución Implementada
El código ahora incluye manejo automático del error mientras se crea el índice:
1. Intenta la consulta óptima con índice
2. Si falla, usa consulta simple y ordena manualmente
3. Proporciona mensajes de error claros al usuario

## Error Reportado
```
Error al cargar muestras: [cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation
```

## Causa Raíz

El error NO es de permisos reales, sino de **falta de índice compuesto en Firestore**. 

Cuando se ejecuta una consulta que combina:
- `where('laboratorio_id', isEqualTo: userId)`
- `orderBy('fecha_toma', descending: true)`

Firestore requiere un índice compuesto para optimizar la consulta.

## Soluciones

### Solución 1: Crear el Índice Compuesto (RECOMENDADO)

1. **Opción A - Desde Firebase Console:**
   - Ir a Firebase Console > Firestore Database > Indexes
   - Crear nuevo índice:
     - Collection ID: `muestras_laboratorio`
     - Fields:
       - `laboratorio_id` (Ascending)
       - `fecha_toma` (Descending)
   - Click "Create Index"

2. **Opción B - Desde el error en la app:**
   - Ejecutar la app y dejar que falle
   - En los logs de consola, Firebase proporciona un enlace directo para crear el índice
   - Hacer click en el enlace y confirmar

3. **Opción C - Usando Firebase CLI:**
   ```json
   // En firestore.indexes.json
   {
     "indexes": [
       {
         "collectionGroup": "muestras_laboratorio",
         "queryScope": "COLLECTION",
         "fields": [
           {
             "fieldPath": "laboratorio_id",
             "order": "ASCENDING"
           },
           {
             "fieldPath": "fecha_toma",
             "order": "DESCENDING"
           }
         ]
       }
     ]
   }
   ```
   Luego ejecutar:
   ```bash
   firebase deploy --only firestore:indexes
   ```

### Solución 2: Modificar la Consulta (Temporal)

Si necesitas que funcione inmediatamente mientras se crea el índice:

```dart
// En laboratorio_gestion_muestras.dart, línea 81-85
// Cambiar de:
final muestrasSnapshot = await _firestore
    .collection('muestras_laboratorio')
    .where('laboratorio_id', isEqualTo: userId)
    .orderBy('fecha_toma', descending: true)
    .get();

// A:
final muestrasSnapshot = await _firestore
    .collection('muestras_laboratorio')
    .where('laboratorio_id', isEqualTo: userId)
    .get();

// Luego ordenar manualmente en Dart:
final docs = muestrasSnapshot.docs;
docs.sort((a, b) {
  final fechaA = (a.data()['fecha_toma'] as Timestamp).toDate();
  final fechaB = (b.data()['fecha_toma'] as Timestamp).toDate();
  return fechaB.compareTo(fechaA); // Orden descendente
});
```

## Verificación de las Reglas de Seguridad

Las reglas actuales están CORRECTAS:
```javascript
allow read: if isAuthenticated() && 
  (resource.data.laboratorio_id == request.auth.uid || isAdmin());
```

El problema NO es de permisos, sino del índice faltante.

## Estado Final

✅ **Problema Identificado**: Falta índice compuesto
✅ **Solución Documentada**: Crear índice o modificar consulta
⏳ **Acción Requerida**: El usuario debe crear el índice en Firebase Console

## Testing

Después de crear el índice:
1. Reiniciar la app
2. Ir a Gestión de Muestras como Laboratorio
3. Las muestras deberían cargar correctamente

## Notas Importantes

- El índice tarda 2-5 minutos en crearse
- Una vez creado, funciona permanentemente
- Este es un requisito común de Firestore para consultas complejas