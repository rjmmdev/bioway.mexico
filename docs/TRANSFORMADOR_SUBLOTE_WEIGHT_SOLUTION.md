# Solución: Peso Incorrecto al Recibir Sublotes en Transformador

## Fecha: 2025-01-28

## Problema
Al escanear el código QR de entrega para recibir sublotes en el usuario Transformador:
- El material se mostraba correctamente
- **El peso mostrado era incorrecto** (no reflejaba el peso real del sublote)
- Ejemplo: Un sublote de 10kg no mostraba el peso correcto en el resumen

## Causa Raíz
El código estaba usando campos incorrectos para obtener el peso:

1. **En `receptor_escanear_entrega_screen.dart`**: 
   - Usaba `lote.datosGenerales.peso` que es el peso original del lote
   - No consideraba que los sublotes tienen un peso diferente

2. **En `transformador_lotes_registro_screen.dart`**:
   - Usaba el servicio antiguo `LoteService` que no maneja correctamente sublotes
   - Intentaba determinar el tipo de lote con lógica antigua

## Solución Implementada

### 1. Actualización en `receptor_escanear_entrega_screen.dart`
```dart
// Antes:
'peso': lote.datosGenerales.peso,

// Después:
'peso': lote.pesoActual, // Usar peso actual que considera sublotes y procesamiento
```

### 2. Refactorización completa de `transformador_lotes_registro_screen.dart`
- Cambió de `LoteService` a `LoteUnificadoService`
- Usa `loteUnificado.pesoActual` que calcula dinámicamente el peso correcto
- Verifica si es sublote y lo indica en el origen
- Valida que el lote esté en proceso de transporte

## Beneficios
1. **Peso correcto para sublotes**: Muestra el peso real del sublote (ej: 10kg)
2. **Peso correcto para lotes procesados**: Considera mermas y muestras de laboratorio
3. **Identificación clara**: Los sublotes se identifican como "Sublote - [Origen]"
4. **Validación mejorada**: Solo permite recibir lotes que estén en transporte

## Archivos Modificados
- `lib/screens/ecoce/shared/screens/receptor_escanear_entrega_screen.dart`: Línea 95
- `lib/screens/ecoce/transformador/transformador_lotes_registro_screen.dart`: Método `_addLotFromId` completo

## Cómo Funciona `pesoActual`
El getter `pesoActual` en `LoteUnificadoModel` calcula dinámicamente el peso correcto:

```dart
double get pesoActual {
  // Para sublotes: usa el peso definido al crear el sublote
  if (datosGenerales.tipoLote == 'derivado') {
    return datosGenerales.pesoOriginal ?? 0;
  }
  
  // Para lotes en reciclador: peso procesado - muestras laboratorio
  if (reciclador != null) {
    return (reciclador!.pesoProcesado ?? reciclador!.pesoEntrada) - pesoTotalMuestras;
  }
  
  // Para otros casos...
}
```

## Verificación
1. Crear un sublote de 10kg desde un megalote
2. Transferirlo mediante transporte al transformador
3. En transformador, escanear el QR de entrega
4. El resumen debe mostrar:
   - Material: Correcto (ej: "PEBD")
   - **Peso: 10.0 kg** (el peso real del sublote)
   - Origen: "Sublote - R0000001"