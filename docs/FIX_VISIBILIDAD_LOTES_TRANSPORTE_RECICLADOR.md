# Fix de Visibilidad de Lotes en Transferencia Transporte-Reciclador

## Problema Identificado

Los lotes desaparecían de la pestaña "Salida" del Usuario Reciclador cuando:
1. El Reciclador recibía los lotes ANTES de que el Transportista confirmara la entrega
2. Esto causaba una sobrescritura incorrecta del `usuario_id` en el proceso del reciclador
3. Los lotes quedaban "huérfanos" - existían pero no eran visibles para ningún usuario

## Análisis de Causa Raíz

### Problema 1: Llamada Incorrecta a transferirLote()
**Ubicación**: `lib/services/carga_transporte_service.dart` (líneas 554-566)

El servicio de transporte estaba llamando incorrectamente a `transferirLote()` con el ID del transportista, sobrescribiendo el `usuario_id` del reciclador que ya había recibido el lote.

```dart
// CÓDIGO PROBLEMÁTICO (ELIMINADO)
await _loteUnificadoService.transferirLote(
  loteId: loteId,
  procesoDestino: entrega.destinatarioTipo,
  usuarioDestinoFolio: entrega.destinatarioFolio,
  datosIniciales: {
    'peso_entrada': entrega.pesoTotalEntregado / entrega.lotesIds.length,
    'transportista_folio': entrega.transportistaFolio,
  },
);
```

### Problema 2: Filtro de Query Demasiado Restrictivo
**Ubicación**: `lib/services/lote_unificado_service.dart` (línea 892)

El query solo buscaba lotes con `proceso_actual == 'reciclador'`, excluyendo lotes en estado de transporte.

```dart
// ANTES
.where('proceso_actual', isEqualTo: 'reciclador')

// DESPUÉS
.where('proceso_actual', whereIn: ['reciclador', 'transporte'])
```

### Problema 3: Filtrado Excesivo por Documentación
**Ubicación**: `lib/services/lote_unificado_service.dart` (líneas 944-971)

La lógica de filtrado excluía lotes válidos basándose en el estado de documentación.

### Problema 4: Lotes Legacy con usuario_id Corrupto
Los lotes afectados por el bug anterior tenían el `usuario_id` sobrescrito con el ID del transportista, haciéndolos invisibles incluso después de corregir el código.

## Solución Implementada

### Paso 1: Eliminar la Llamada Incorrecta a transferirLote()
**Archivo**: `lib/services/carga_transporte_service.dart`

Se eliminaron las líneas 554-566 que causaban la sobrescritura. El transportista ahora solo marca la entrega como completada sin modificar el `usuario_id` del proceso destino.

```dart
// SOLUCIÓN IMPLEMENTADA
// Solo actualizar los datos del transporte sin transferir el lote
await _loteUnificadoService.actualizarProcesoTransporte(
  loteId: loteId,
  datos: {
    'fecha_salida': FieldValue.serverTimestamp(),
    'entrega_completada': true,
    'entregado_a': entrega.destinatarioFolio,
  },
);
```

### Paso 2: Ampliar el Filtro de Proceso Actual
**Archivo**: `lib/services/lote_unificado_service.dart` (línea 892)

```dart
// Incluir lotes en proceso de transporte además de reciclador
.where('proceso_actual', whereIn: ['reciclador', 'transporte'])
```

### Paso 3: Simplificar la Lógica de Filtrado
**Archivo**: `lib/services/lote_unificado_service.dart` (líneas 944-947)

Se simplificó la verificación para incluir todos los lotes válidos del reciclador:

```dart
final usuarioRelacionado = reciclador != null && 
  (reciclador.usuarioId == currentUserId || 
   reciclador.usuarioFolio == userFolio);
```

### Paso 4: Implementar Verificación Flexible para Lotes Legacy
**Archivo**: `lib/services/lote_unificado_service.dart` (líneas 920-963)

Se agregó lógica de recuperación para lotes con `usuario_id` corrupto:

```dart
// Verificación adicional para lotes legacy con usuario_id corrupto
else if (data['recepcion_completada'] == true && 
         lote.datosGenerales.procesoActual == 'reciclador') {
  // Verificar si hay evidencia de que el reciclador recibió el lote
  final tieneOperadorNombre = data['operador_nombre'] != null;
  final tieneFirmaOperador = data['firma_operador'] != null;
  final tienePesoRecibido = data['peso_recibido'] != null;
  
  // Si hay evidencia suficiente, recuperar el lote
  if (tieneOperadorNombre && (tieneFirmaOperador || tienePesoRecibido)) {
    usuarioRelacionado = true;
  }
}
```

### Paso 5: Actualizar la Vista del Reciclador
**Archivo**: `lib/screens/ecoce/reciclador/reciclador_administracion_lotes.dart` (líneas 149-151)

```dart
// Aceptar lotes en estado de transporte o reciclador
return !esSublote &&
       (lote.datosGenerales.procesoActual == 'reciclador' || 
        lote.datosGenerales.procesoActual == 'transporte') &&
       reciclador != null && 
       reciclador.fechaSalida == null &&
       !lote.estaConsumido;
```

## Verificación del Proceso Transporte → Transformador

Se verificó que el proceso de Transporte a Transformador no presenta el mismo problema porque:
1. El transformador no tiene un proceso de recepción previo a la confirmación del transporte
2. El flujo es unidireccional y no permite la situación problemática

## Resultado

✅ **Lotes nuevos**: Se visualizan correctamente sin importar el orden de confirmación
✅ **Lotes legacy**: Recuperados mediante verificación flexible de campos adicionales
✅ **Integridad de datos**: Se mantiene la trazabilidad completa sin pérdida de información
✅ **Compatibilidad**: La solución es retrocompatible y no afecta otros flujos

## Escenarios de Prueba

### Escenario 1: Flujo Normal
1. Transportista carga lotes desde Origen
2. Transportista confirma entrega
3. Reciclador recibe lotes
**Resultado**: ✅ Lotes visibles en pestaña "Salida"

### Escenario 2: Flujo Problemático (Ahora Corregido)
1. Transportista carga lotes desde Origen
2. Reciclador recibe lotes ANTES de que Transportista confirme
3. Transportista confirma entrega
**Resultado**: ✅ Lotes siguen visibles en pestaña "Salida"

### Escenario 3: Lotes Legacy Corruptos
1. Lotes con `usuario_id` sobrescrito por bug anterior
2. Tienen campos de recepción válidos (operador_nombre, firma_operador, etc.)
**Resultado**: ✅ Lotes recuperados y visibles

## Archivos Modificados

1. **lib/services/carga_transporte_service.dart**
   - Líneas 554-566: Eliminadas (llamada incorrecta a transferirLote)

2. **lib/services/lote_unificado_service.dart**
   - Línea 892: Modificado query para incluir estado 'transporte'
   - Líneas 920-963: Agregada verificación flexible para lotes legacy
   - Líneas 944-947: Simplificada lógica de filtrado

3. **lib/screens/ecoce/reciclador/reciclador_administracion_lotes.dart**
   - Líneas 149-151: Actualizado filtro para aceptar lotes en transporte

## Lecciones Aprendidas

1. **Validación de Estado**: Siempre verificar el estado actual antes de realizar transferencias
2. **Idempotencia**: Las operaciones de confirmación deben ser idempotentes
3. **Recuperación de Datos**: Implementar mecanismos de recuperación para datos corruptos
4. **Verificación Flexible**: Usar múltiples campos para validar la propiedad de un registro

## Prevención Futura

Para evitar problemas similares:
1. No sobrescribir campos de identificación de usuario en procesos ya iniciados
2. Implementar validaciones de estado antes de modificar datos
3. Mantener logs de auditoría para rastrear cambios en campos críticos
4. Usar transacciones cuando se requieran múltiples actualizaciones coordinadas

## Fecha de Implementación

**Fecha**: 28 de Enero de 2025
**Versión afectada**: 1.0.0+1
**Estado**: ✅ Implementado y verificado en producción