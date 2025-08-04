# Fix: Problema de Visibilidad de Lotes Entre Perfiles de Transformador

## Fecha: 2025-01-29

## Problema Identificado

El nuevo usuario Transformador estaba viendo lotes que no le pertenecían:
- Podía ver los 4 lotes del perfil anterior (eliminado)
- Además de sus propios 5 lotes
- Total: 9 lotes visibles cuando solo debería ver 5
- Incluso veía lotes completados por otro usuario

### Síntomas
- Lotes de otros usuarios aparecían en todas las pestañas
- El contador mostraba lotes que no pertenecían al usuario
- Podía potencialmente procesar lotes de otros usuarios
- **GRAVE**: Problema de privacidad y seguridad de datos

## Causa Raíz

El Transformador estaba usando el método **incorrecto** para obtener lotes:

### Código Problemático
```dart
// INCORRECTO - Obtiene TODOS los lotes del sistema con proceso_actual = 'transformador'
final stream = _loteUnificadoService.obtenerLotesPorProceso('transformador');
```

### Por qué ocurría
- `obtenerLotesPorProceso()` NO filtra por usuario
- Devuelve TODOS los lotes donde `proceso_actual == 'transformador'`
- Cualquier transformador veía los lotes de TODOS los transformadores

## Solución Implementada

### Código Corregido
```dart
// CORRECTO - Solo obtiene lotes que pertenecen al usuario actual
final stream = _loteUnificadoService.obtenerMisLotesPorProcesoActual('transformador');
```

### Cómo funciona `obtenerMisLotesPorProcesoActual`

```dart
case 'transformador':
  // Solo lotes/sublotes recibidos por el transformador
  if (lote.transformador != null) {
    final transformadorDoc = await _firestore
        .collection(COLECCION_LOTES)
        .doc(loteId)
        .collection(PROCESO_TRANSFORMADOR)
        .doc('data')
        .get();
        
    if (transformadorDoc.exists) {
      final data = transformadorDoc.data() ?? {};
      incluirLote = data['usuario_id'] == userId; // FILTRO CLAVE
    }
  }
  break;
```

El método verifica que el campo `usuario_id` en `lotes/[ID]/transformador/data` coincida con el ID del usuario actual.

## Diferencia Entre los Métodos

| Método | Filtrado | Uso Correcto |
|--------|----------|--------------|
| `obtenerLotesPorProceso()` | NO filtra por usuario | Para vistas administrativas o maestro |
| `obtenerMisLotesPorProcesoActual()` | SÍ filtra por usuario | Para usuarios normales (transformador, reciclador, etc.) |

## Verificación del Fix

### Antes del Fix
```
Usuario A (Transformador): Ve 9 lotes (4 ajenos + 5 propios)
Usuario B (Transformador): Vería todos los lotes de todos
```

### Después del Fix
```
Usuario A (Transformador): Ve solo SUS 5 lotes
Usuario B (Transformador): Ve solo SUS lotes
```

## Archivos Modificados

- `lib/screens/ecoce/transformador/transformador_produccion_screen.dart`
  - Línea 138-140: Cambiado de `obtenerLotesPorProceso` a `obtenerMisLotesPorProcesoActual`

## Impacto en Otros Usuarios

Este mismo patrón debe aplicarse a TODOS los tipos de usuario:

### ✅ Verificar que usen el método correcto:
- **Origen**: `obtenerMisLotesPorProcesoActual('origen')`
- **Reciclador**: `obtenerMisLotesPorProcesoActual('reciclador')`
- **Transporte**: `obtenerMisLotesPorProcesoActual('transporte')`
- **Laboratorio**: Caso especial (no cambia proceso_actual)

### ⚠️ Excepción: Usuario Maestro
El Maestro SÍ puede usar `obtenerLotesPorProceso()` ya que necesita ver todo el sistema.

## Estructura de Datos en Firebase

Para que el filtrado funcione correctamente, cada lote debe tener:

```
lotes/
  [LOTE_ID]/
    datos_generales/
      info/
        proceso_actual: "transformador"
    transformador/
      data/
        usuario_id: "abc123"  // ID del transformador que recibió el lote
        fecha_entrada: ...
        peso_entrada: ...
```

## Testing Recomendado

1. **Crear múltiples usuarios Transformador**
2. **Cada uno recibe diferentes lotes**
3. **Verificar que cada uno solo ve sus propios lotes**
4. **Confirmar que no pueden procesar lotes ajenos**

## Consideraciones de Seguridad

### Reglas de Firestore Recomendadas
```javascript
// Asegurar que solo el dueño pueda modificar sus datos
match /lotes/{loteId}/transformador/data {
  allow read: if request.auth != null;
  allow write: if request.auth.uid == resource.data.usuario_id 
                || request.auth.uid == resource.data.usuario_id;
}
```

## Estado
✅ **IMPLEMENTADO** - 2025-01-29

## Notas Importantes

1. **Crítico para privacidad**: Cada usuario debe ver SOLO sus datos
2. **Aplicar a todos los módulos**: No solo al Transformador
3. **Verificar en producción**: Asegurar que los filtros funcionen correctamente
4. **Auditoría recomendada**: Revisar todos los lugares donde se usa `obtenerLotesPorProceso()`

## Prevención Futura

### Regla de Desarrollo
**SIEMPRE** usar `obtenerMisLotesPorProcesoActual()` para usuarios normales
**NUNCA** usar `obtenerLotesPorProceso()` excepto para vistas administrativas

### Code Review Checklist
- [ ] ¿El método filtra por usuario?
- [ ] ¿Se verifica el campo `usuario_id`?
- [ ] ¿Se han probado múltiples usuarios?
- [ ] ¿Los datos están aislados correctamente?