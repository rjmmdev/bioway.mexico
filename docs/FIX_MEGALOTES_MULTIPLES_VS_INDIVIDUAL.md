# Fix: Error con Múltiples Lotes vs Individual en Transformador

## Problema Identificado
El sistema funcionaba con **1 lote** pero fallaba con **2 o más lotes** con error de permisos.

## Causa Raíz
El código tenía una diferencia crítica entre procesamiento individual y múltiple:

### Con 1 Lote (Funcionaba ✅):
```dart
// Línea 641+ - Usa el servicio que maneja todo correctamente
await _loteUnificadoService.actualizarProcesoTransformador(...)
```

### Con 2+ Lotes (Fallaba ❌):
```dart
// Problema: Intentaba marcar lotes como consumidos ANTES de crear la transformación
'transformacion_id': _transformacionId ?? '',  // Era null, enviaba string vacío ''
```

El flujo incorrecto era:
1. Intentar marcar lotes con `transformacion_id: ''` (vacío)
2. Crear la transformación
3. Volver a marcar lotes

## Solución Aplicada

### 1. Eliminar Marcado Prematuro (líneas 562-564)
```dart
// ANTES - Marcaba lotes antes de tener el ID
await FirebaseFirestore.instance
    .set({
      'consumido_en_transformacion': true,
      'transformacion_id': _transformacionId ?? '', // Era null!
    })

// DESPUÉS - Solo preparar datos, no marcar aún
// NO marcar como consumido aquí - lo haremos después de crear la transformación
```

### 2. Flujo Corregido (líneas 598-639)
El nuevo flujo es:
1. **PRIMERO** crear la transformación y obtener su ID
2. **LUEGO** marcar todos los lotes como consumidos con el ID correcto

```dart
// Paso 1: Crear transformación
if (_transformacionId == null) {
  final docRef = await FirebaseFirestore.instance
      .collection('transformaciones')
      .add(transformacionData);
  _transformacionId = docRef.id;
  print('Transformación creada con ID: $_transformacionId');
}

// Paso 2: Ahora sí marcar lotes con el ID correcto
for (var lote in lotes) {
  await FirebaseFirestore.instance
      .set({
        'consumido_en_transformacion': true,
        'transformacion_id': _transformacionId!, // Ahora sí tiene valor
      }, SetOptions(merge: true));
}
```

### 3. Mejor Manejo de Errores
Se agregó try-catch individual para cada lote, así si uno falla, los demás continúan:
```dart
for (var lote in lotes) {
  try {
    // Marcar lote
  } catch (e) {
    print('ERROR al marcar lote ${lote.id}: $e');
    // Continuar con los demás
  }
}
```

## Por Qué Funcionaba con 1 Lote

Con **1 solo lote**, el código detecta `_esProcesamientoMultiple = false` y usa una ruta diferente:
- Llama a `_loteUnificadoService.actualizarProcesoTransformador()`
- Este servicio NO crea transformaciones (megalotes)
- Solo actualiza el proceso del lote individual
- Por eso no había error de permisos

## Diferencias Clave

| Aspecto | 1 Lote | 2+ Lotes |
|---------|--------|----------|
| **Variable** | `_esProcesamientoMultiple = false` | `_esProcesamientoMultiple = true` |
| **Flujo** | Actualiza lote individual | Crea megalote (transformación) |
| **Servicio** | `actualizarProcesoTransformador()` | Crea en `transformaciones` collection |
| **Resultado** | Lote en estado "documentación" | Megalote con lotes consumidos |

## Estado
✅ **IMPLEMENTADO** - 2025-01-29

## Testing
1. Con **1 lote**: Debe seguir funcionando normal
2. Con **2+ lotes**: Ahora debe:
   - Crear el megalote sin errores
   - Marcar todos los lotes como consumidos
   - Aparecer en pestaña "Documentación"

## Logs de Debugging
La consola ahora mostrará:
```
Creando nueva transformación...
Transformación creada con ID: ABC123
Marcando 2 lotes como consumidos...
Lote XYZ marcado como consumido
Lote DEF marcado como consumido
```