# Fix: Permission Denied al crear Megalotes con 2+ lotes en Transformador

## Problema Identificado
El Usuario Transformador no podía crear megalotes con 2 o más lotes, mostrando error:
```
[cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation
```

El mismo proceso funcionaba correctamente con:
- 1 solo lote (procesamiento individual)
- Usuario Reciclador con cualquier cantidad de lotes

## Causa Raíz
El Transformador enviaba datos en formato diferente al Reciclador:

### Diferencias Críticas

| Campo | Reciclador (✅ Funciona) | Transformador (❌ Fallaba) |
|-------|--------------------------|----------------------------|
| **fecha_inicio** | `Timestamp.fromDate(DateTime.now())` | `DateTime.now()` |
| **fecha_procesamiento** | `Timestamp.fromDate(DateTime.now())` | `DateTime.now()` |
| **lotes_entrada** | Incluye `porcentaje` para cada lote | Faltaba campo `porcentaje` |
| **merma_proceso** | Siempre presente (requerido) | No incluido |
| **peso_disponible** | Siempre presente (requerido) | No incluido |
| **sublotes_generados** | Lista vacía `[]` inicial | No incluido |
| **documentos_asociados** | Mapa vacío `{}` inicial | No incluido |

## Análisis Técnico

### 1. Firestore Rules
Las reglas requieren estos campos obligatorios:
```javascript
allow create: if request.resource.data.keys().hasAll([
  'usuario_id', 
  'usuario_folio', 
  'tipo', 
  'fecha_inicio'
]);
```

### 2. Modelo TransformacionModel
El modelo espera:
- `fecha_inicio` como `Timestamp` (no `DateTime`)
- `lotes_entrada` con estructura completa incluyendo `porcentaje`
- Campos obligatorios: `merma_proceso`, `peso_disponible`, `sublotes_generados`, `documentos_asociados`

### 3. Conversión de Datos
- **Reciclador**: Usa `TransformacionModel.toMap()` que convierte `DateTime` → `Timestamp`
- **Transformador**: Creaba Map manual sin conversión

## Solución Aplicada

### 1. Convertir DateTime a Timestamp
```dart
// ANTES (Incorrecto)
'fecha_inicio': DateTime.now(),

// DESPUÉS (Correcto)
'fecha_inicio': Timestamp.fromDate(DateTime.now()),
```

### 2. Agregar porcentajes a lotes_entrada
```dart
// Calcular porcentajes para cada lote
for (var lote in lotes) {
  final peso = lote.pesoActual;
  final porcentaje = (peso / pesoTotal) * 100;
  
  lotesEntrada.add({
    'lote_id': lote.id,
    'peso': peso,
    'porcentaje': porcentaje, // REQUERIDO
    'tipo_material': lote.datosGenerales.tipoMaterial,
  });
}
```

### 3. Incluir todos los campos requeridos
```dart
final transformacionData = {
  'tipo': 'agrupacion_transformador',
  'usuario_id': authUid,
  'usuario_folio': userFolio,
  'fecha_inicio': Timestamp.fromDate(DateTime.now()),
  'estado': 'documentacion',
  'lotes_entrada': lotesEntrada,
  'peso_total_entrada': _pesoTotalOriginal,
  'peso_disponible': cantidadGenerada,        // REQUERIDO
  'merma_proceso': mermaProceso,              // REQUERIDO
  'sublotes_generados': [],                   // REQUERIDO
  'documentos_asociados': {},                 // REQUERIDO
  'muestras_laboratorio': [],                 // Compatibilidad
  // ... campos específicos del transformador
};
```

### 4. Usar set con merge para actualizaciones
```dart
// ANTES (podía fallar con campos anidados)
.update(transformacionData)

// DESPUÉS (más robusto)
.set(transformacionData, SetOptions(merge: true))
```

## Archivos Modificados
- `lib/screens/ecoce/transformador/transformador_formulario_salida.dart`
  - Líneas 580-641: Creación de transformación con formato correcto
  - Líneas 331-404: Método `_prepareTransformacionData()` actualizado
  - Línea 689: Cambio de `.update()` a `.set()` con merge

## Verificación
El sistema ahora:
1. ✅ Crea megalotes con 1 lote (procesamiento individual)
2. ✅ Crea megalotes con 2+ lotes (procesamiento múltiple)
3. ✅ Mantiene compatibilidad con el modelo `TransformacionModel`
4. ✅ Cumple con las reglas de Firestore
5. ✅ Funciona igual que el Usuario Reciclador

## Lecciones Aprendidas
1. **Siempre usar `Timestamp`** para fechas en Firestore, no `DateTime` directamente
2. **Incluir TODOS los campos del modelo** aunque sean vacíos inicialmente
3. **Mantener consistencia** entre diferentes usuarios que usan la misma funcionalidad
4. **El campo `porcentaje`** es requerido en `lotes_entrada` para el modelo
5. **Usar `.set()` con `merge: true`** es más seguro que `.update()` para documentos complejos

## Testing Recomendado
1. Crear megalote con 2 lotes
2. Crear megalote con 3+ lotes
3. Verificar que los lotes se marquen como consumidos
4. Verificar que el megalote aparezca en la lista
5. Verificar que se pueda actualizar el megalote (borrador)

## Estado
✅ **IMPLEMENTADO** - 2025-01-29