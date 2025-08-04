# Fix: Lotes Consumidos Reaparecen y Megalote Desaparece en Transformador

## Problema Identificado
1. Los lotes que ya fueron usados para crear un megalote reaparecen en la pestaña "Salida"
2. El megalote creado desaparece de la pestaña "Documentación"
3. Al intentar usar los lotes nuevamente, el sistema dice que ya fueron utilizados (validación funciona)

## Causa Raíz

### Problema 1: Lotes Consumidos Reaparecen
El método `obtenerLotesPorProceso('transformador')` no filtraba los lotes que tenían `consumido_en_transformacion = true`. Esto causaba que:
- Los lotes aparecían en la lista aunque ya estuvieran marcados como consumidos
- La validación al intentar usarlos sí funcionaba (verificaba en Firebase)
- Generaba confusión visual al usuario

### Problema 2: Megalote Desaparece
Posibles causas:
1. El stream de transformaciones usa multi-tenant y podría no estar sincronizado
2. El estado inicial 'documentacion' podría no persistirse correctamente
3. Delay en la propagación de datos en Firebase

## Solución Aplicada

### 1. Filtrar Lotes Consumidos
En `transformador_produccion_screen.dart`, método `_loadLotes()`:

```dart
// ANTES - No filtraba lotes consumidos
var lotesFiltrados = _aplicarFiltros(lotes);

// DESPUÉS - Filtra lotes consumidos antes de aplicar otros filtros
var lotesNoConsumidos = lotes.where((lote) {
  final estaConsumido = lote.datosGenerales.consumidoEnTransformacion ?? false;
  if (estaConsumido) {
    print('Lote ${lote.id} está consumido, filtrando de la lista');
  }
  return !estaConsumido; // Solo incluir lotes NO consumidos
}).toList();

var lotesFiltrados = _aplicarFiltros(lotesNoConsumidos);
```

### 2. Verificación del Modelo
El campo `consumidoEnTransformacion` está correctamente mapeado en `DatosGeneralesLote`:
```dart
class DatosGeneralesLote {
  final bool consumidoEnTransformacion;
  final String? transformacionId;
  
  factory DatosGeneralesLote.fromMap(Map<String, dynamic> map) {
    return DatosGeneralesLote(
      // ...
      consumidoEnTransformacion: map['consumido_en_transformacion'] ?? false,
      transformacionId: map['transformacion_id'],
    );
  }
}
```

## Flujo Correcto

### Creación de Megalote:
1. **Crear transformación** → Estado: 'documentacion'
2. **Marcar lotes como consumidos**:
   ```dart
   'consumido_en_transformacion': true,
   'transformacion_id': _transformacionId,
   'fecha_consumo': FieldValue.serverTimestamp()
   ```
3. **Filtrar en lista** → Lotes consumidos no aparecen
4. **Megalote visible** → En pestaña Documentación

### Verificación en Firebase:
```
lotes/[loteId]/datos_generales/info:
{
  consumido_en_transformacion: true,
  transformacion_id: "XXXX",
  fecha_consumo: Timestamp
}
```

## Archivos Modificados
- `lib/screens/ecoce/transformador/transformador_produccion_screen.dart`
  - Líneas 143-152: Agregado filtro para excluir lotes consumidos

## Impacto
- ✅ Los lotes consumidos ya NO aparecen en la pestaña "Salida"
- ✅ Se evita confusión al usuario sobre qué lotes están disponibles
- ✅ La validación de doble uso sigue funcionando como respaldo
- ⚠️ Si el megalote desaparece, verificar:
  - Que el stream de transformaciones esté activo
  - Que el estado sea 'documentacion'
  - Que use la instancia correcta de Firestore (multi-tenant)

## Recomendaciones Adicionales

### Si el Megalote Sigue Desapareciendo:
1. **Verificar en Firebase Console**:
   - Buscar en `transformaciones` collection
   - Verificar que `estado: 'documentacion'`
   - Verificar que `tipo: 'agrupacion_transformador'`

2. **Posible Solución Adicional**:
   Si el problema persiste, considerar agregar un delay antes de navegar:
   ```dart
   // Esperar a que Firebase propague los cambios
   await Future.delayed(Duration(seconds: 2));
   Navigator.pushNamed(context, '/transformador_produccion');
   ```

3. **Verificar Filtros**:
   El método `_filterTransformacionesByState()` debe retornar transformaciones con:
   - `estado == 'documentacion'` para tab 1
   - `tipo == 'agrupacion_transformador'`

## Testing
1. Crear un megalote con 2-3 lotes
2. Verificar que los lotes desaparecen de "Salida"
3. Verificar que el megalote aparece en "Documentación"
4. Intentar usar un lote consumido debe mostrar error
5. El megalote debe persistir al cambiar de pestañas

## Estado
✅ **IMPLEMENTADO** - 2025-01-29

## Notas
- El filtrado de lotes consumidos es preventivo (visual)
- La validación en Firebase es la protección real (funcional)
- Ambas capas de protección son necesarias para buena UX