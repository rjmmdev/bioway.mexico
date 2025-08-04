# Fix: PERMISSION_DENIED al Crear Megalotes en Transformador

## Problema
El Usuario Transformador recibía error `PERMISSION_DENIED` al intentar crear megalotes (agrupación de múltiples lotes):

```
W/Firestore(28619): (25.1.4) [WriteStream]: Stream closed with status: Status{code=PERMISSION_DENIED, description=Missing or insufficient permissions., cause=null}.
W/Firestore(28619): Write failed at lotes/GX7alDeAkQLaw0DtzsVT/datos_generales/info
Error: [cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation
```

## Causa Raíz
El código intentaba usar `.update()` en documentos que podrían no existir en `lotes/{loteId}/datos_generales/info`. Firestore requiere que el documento exista para poder actualizarlo con `.update()`.

## Solución Aplicada

### 1. Cambio de `.update()` a `.set()` con `merge: true`
Se modificó el archivo `lib/screens/ecoce/transformador/transformador_formulario_salida.dart` en dos ubicaciones:

#### Cambio 1 (líneas 537-547):
```dart
// ANTES
await FirebaseFirestore.instance
    .collection('lotes')
    .doc(lote.id)
    .collection('datos_generales')
    .doc('info')
    .update({
  'consumido_en_transformacion': true,
  'transformacion_id': _transformacionId ?? '',
});

// DESPUÉS
await FirebaseFirestore.instance
    .collection('lotes')
    .doc(lote.id)
    .collection('datos_generales')
    .doc('info')
    .set({
  'consumido_en_transformacion': true,
  'transformacion_id': _transformacionId ?? '',
  'fecha_consumo': FieldValue.serverTimestamp(),
}, SetOptions(merge: true));
```

#### Cambio 2 (líneas 587-597):
Mismo cambio aplicado en la segunda ubicación donde se actualizaban lotes consumidos.

### 2. Validación de Estado de Lotes (líneas 518-539)
Se agregó validación antes de procesar los lotes:

```dart
// Verificar que el lote está en proceso transformador
if (lote.datosGenerales.procesoActual != 'transformador') {
  throw Exception('El lote ${lote.id} no está disponible para el transformador');
}

// Verificar que no esté ya consumido
final datosGeneralesDoc = await FirebaseFirestore.instance
    .collection('lotes')
    .doc(loteId)
    .collection('datos_generales')
    .doc('info')
    .get();

if (datosGeneralesDoc.exists && 
    datosGeneralesDoc.data()?['consumido_en_transformacion'] == true) {
  throw Exception('El lote ${lote.id} ya fue procesado en otra transformación');
}
```

### 3. Mejora en Mensajes de Error (líneas 697-710)
Se mejoró el manejo de errores con mensajes más descriptivos:

```dart
String errorMessage = 'Error al procesar la salida';

if (e.toString().contains('no está disponible')) {
  errorMessage = 'Uno o más lotes no están disponibles para procesar';
} else if (e.toString().contains('ya fue procesado')) {
  errorMessage = 'Uno o más lotes ya fueron procesados anteriormente';
} else if (e.toString().contains('No se pudo obtener')) {
  errorMessage = 'Error al obtener información de los lotes';
} else if (e.toString().contains('permission')) {
  errorMessage = 'Error de permisos. Por favor contacte al administrador';
}
```

## Beneficios de la Solución

1. **Evita errores de permisos**: `set()` con `merge: true` crea el documento si no existe o lo actualiza si existe
2. **Previene duplicados**: Valida que los lotes no hayan sido procesados anteriormente
3. **Mejor experiencia de usuario**: Mensajes de error claros y específicos
4. **Mayor robustez**: Maneja casos edge donde los documentos podrían no existir

## Aclaraciones sobre el Sistema de Megalotes

### Almacenamiento
- **Todos los megalotes** (tanto de Reciclador como de Transformador) se almacenan en la **misma colección**: `transformaciones`
- Se diferencian por el campo `tipo`:
  - Reciclador: `tipo: 'agrupacion_reciclador'`
  - Transformador: `tipo: 'agrupacion_transformador'`

### Permisos
Ambos usuarios tienen los mismos permisos en Firestore para crear, leer y actualizar transformaciones.

## Estado
✅ **IMPLEMENTADO** - 2025-01-29

## Testing Recomendado
1. Crear megalote con 2 lotes nuevos
2. Intentar crear megalote con lote ya consumido (debe mostrar error claro)
3. Verificar que los lotes se marquen correctamente como consumidos
4. Confirmar que el megalote aparezca en la pestaña de Documentación