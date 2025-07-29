# Fix: Visibilidad de Lotes por Usuario

## Problema Identificado

Los usuarios del sistema (origen, transporte, reciclador, transformador y laboratorio) estaban viendo lotes/sublotes con los que no habían interactuado. Específicamente:

- Un reciclador nuevo podía ver sublotes creados por otro reciclador
- Los usuarios podían ver lotes de otros usuarios del mismo tipo

## Causa del Problema

1. El método `obtenerLotesRecicladorConPendientes()` incluía TODOS los sublotes sin verificar quién los creó
2. El método genérico `obtenerLotesPorProceso()` no filtraba por usuario
3. No había validación de propiedad/relación con los lotes

## Solución Implementada

### 1. Modificación de `obtenerLotesRecicladorConPendientes()`

Se agregó validación para verificar la relación del usuario con cada lote:

```dart
// Para sublotes: verificar que fueron creados por el usuario actual
if (lote.esSublote) {
  if (lote.datosGenerales.creadoPor == userId) {
    usuarioRelacionado = true;
  } else {
    continue; // No mostrar sublotes creados por otros usuarios
  }
}

// Para lotes originales: verificar que el reciclador los haya recibido
else if (lote.reciclador != null) {
  // Verificar el usuario_id en el proceso reciclador
  final recicladorDoc = await _firestore
      .collection(COLECCION_LOTES)
      .doc(loteId)
      .collection(PROCESO_RECICLADOR)
      .doc('data')
      .get();
      
  if (recicladorDoc.exists) {
    final data = recicladorDoc.data() ?? {};
    final recicladorUserId = data['usuario_id'] ?? data['reciclador_id'];
    
    if (recicladorUserId == userId) {
      usuarioRelacionado = true;
    }
  }
}
```

### 2. Nuevo Método Genérico `obtenerMisLotesPorProcesoActual()`

Se creó un método que aplica filtros específicos para cada tipo de usuario:

```dart
Stream<List<LoteUnificadoModel>> obtenerMisLotesPorProcesoActual(String proceso) {
  // Filtros específicos por proceso:
  
  // ORIGEN: Solo lotes creados por el usuario
  case 'origen':
    incluirLote = lote.datosGenerales.creadoPor == userId;
    
  // TRANSPORTE: Solo lotes en cargas activas del usuario
  case 'transporte':
    // Verificar fases de transporte activas
    
  // RECICLADOR: Lotes recibidos + sublotes creados
  case 'reciclador':
    if (lote.esSublote) {
      incluirLote = lote.datosGenerales.creadoPor == userId;
    } else {
      // Verificar recepción por el usuario
    }
    
  // LABORATORIO: Solo lotes donde tomó muestras
  case 'laboratorio':
    // Verificar análisis del usuario
    
  // TRANSFORMADOR: Solo lotes recibidos
  case 'transformador':
    // Verificar recepción por el usuario
}
```

## Uso Correcto de los Métodos

### ❌ NO USAR (muestra todos los lotes):
```dart
_loteService.obtenerLotesPorProceso('reciclador')
```

### ✅ USAR (filtra por usuario actual):
```dart
// Para reciclador con documentación pendiente
_loteService.obtenerLotesRecicladorConPendientes()

// Para otros procesos
_loteService.obtenerMisLotesPorProcesoActual('origen')
_loteService.obtenerMisLotesPorProcesoActual('transporte')
_loteService.obtenerMisLotesPorProcesoActual('transformador')

// Para laboratorio (ya filtrado correctamente)
_loteService.obtenerLotesConAnalisisLaboratorio()
```

## Reglas de Visibilidad

### Origen
- Solo ve lotes que él mismo creó (`creado_por == userId`)

### Transporte
- Solo ve lotes en sus cargas activas
- No ve lotes de otros transportistas

### Reciclador
- Ve lotes originales que recibió
- Ve sublotes que él mismo creó
- NO ve sublotes de otros recicladores
- NO ve lotes que no ha recibido

### Laboratorio
- Solo ve lotes donde tomó muestras
- El proceso es paralelo (no transfiere propiedad)

### Transformador
- Solo ve lotes/sublotes que recibió
- NO ve lotes de otros transformadores

### Maestro/Repositorio
- Pueden ver todos los lotes (sin filtro de usuario)

## Verificación

Para verificar que la solución funciona:

1. Crear dos cuentas del mismo tipo (ej: dos recicladores)
2. Con cuenta 1: recibir lotes y crear sublotes
3. Con cuenta 2: verificar que NO aparecen los sublotes de cuenta 1
4. Con cuenta 2: recibir sus propios lotes
5. Verificar que cada cuenta solo ve sus lotes

## Archivos Modificados

- `lib/services/lote_unificado_service.dart`
  - Método `obtenerLotesRecicladorConPendientes()` - líneas 759-849
  - Nuevo método `obtenerMisLotesPorProcesoActual()` - líneas 761-865

## Consideraciones Adicionales

1. El método `obtenerLotesPorProceso()` se mantiene sin filtro para casos especiales (maestro/repositorio)
2. Los sublotes SIEMPRE deben verificar `creado_por`
3. Los lotes originales deben verificar el `usuario_id` en el proceso correspondiente
4. Laboratorio es un caso especial que no transfiere propiedad

---

*Fecha de implementación: 2025-01-29*  
*Problema reportado por: Usuario*  
*Solución implementada por: Sistema*