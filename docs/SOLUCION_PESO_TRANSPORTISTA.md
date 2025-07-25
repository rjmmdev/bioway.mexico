# Solución: Peso Correcto en Escaneo del Transportista

## Problema Identificado
El transportista estaba tomando el peso original/inicial del lote en lugar del peso procesado/final cuando escaneaba un lote que salía del Usuario Reciclador. Esto generaba un error en la trazabilidad, ya que se registraba más peso del realmente transportado.

## Causa del Problema
1. **Uso de peso estático**: Se estaba usando `lote.datosGenerales.peso` que contiene el peso inicial del lote
2. **Campo faltante en el modelo**: El formulario del reciclador guardaba el peso como `peso_neto_salida` pero el modelo esperaba `peso_procesado`
3. **No uso del cálculo dinámico**: No se estaba aprovechando el método `pesoActual` del modelo que calcula el peso según el proceso actual

## Solución Implementada

### 1. Cambios en el Escaneo del Transportista
**Archivo**: `lib/screens/ecoce/transporte/transporte_escanear_carga_screen.dart`
```dart
// ANTES
'peso': lote.datosGenerales.peso,

// DESPUÉS
'peso': lote.pesoActual, // Usar el peso actual calculado dinámicamente
```

### 2. Cambios en el Servicio de Carga
**Archivo**: `lib/services/carga_transporte_service.dart`
```dart
// ANTES (línea 79)
final pesoOriginalLote = lote?.datosGenerales.peso ?? 0.0;

// DESPUÉS
final pesoActualLote = lote?.pesoActual ?? 0.0;
```

### 3. Cambios en la Pantalla de Entrega
**Archivo**: `lib/screens/ecoce/transporte/transporte_entrega_pasos_screen.dart`
```dart
// Se actualizaron las líneas 207 y 214 para usar lote.pesoActual
```

### 4. Corrección en el Formulario del Reciclador
**Archivo**: `lib/screens/ecoce/reciclador/reciclador_formulario_salida.dart`
```dart
// Se agregaron los campos esperados por el modelo
datosActualizacion['peso_procesado'] = pesoResultante; // Campo esperado por el modelo
datosActualizacion['merma_proceso'] = _mermaCalculada; // Campo esperado por el modelo
```

## Lógica del Método pesoActual

El método `pesoActual` en `LoteUnificadoModel` calcula dinámicamente el peso según el proceso actual:

```dart
double get pesoActual {
    // Si está en transformador, usar peso de salida o entrada
    if (transformador != null) return transformador!.pesoSalida ?? transformador!.pesoEntrada;
    
    // Si está en transporte fase 2 (reciclador -> transformador)
    if (transporteFases.containsKey('fase_2')) {
        final fase2 = transporteFases['fase_2']!;
        return fase2.pesoEntregado ?? fase2.pesoRecogido;
    }
    
    // Si está en reciclador
    if (reciclador != null) {
        // Usar peso procesado o de entrada, menos las muestras del laboratorio
        double pesoReciclador = reciclador!.pesoProcesado ?? reciclador!.pesoEntrada;
        double pesoMuestras = analisisLaboratorio.fold(0.0, 
            (sum, analisis) => sum + analisis.pesoMuestra
        );
        return pesoReciclador - pesoMuestras;
    }
    
    // Si está en transporte fase 1 (origen -> reciclador)
    if (transporteFases.containsKey('fase_1')) {
        final fase1 = transporteFases['fase_1']!;
        return fase1.pesoEntregado ?? fase1.pesoRecogido;
    }
    
    // Si está en origen
    if (origen != null) return origen!.pesoNace;
    
    // Default: peso inicial
    return datosGenerales.pesoInicial;
}
```

## Impacto y Consideraciones

### Usuarios NO Afectados Negativamente:
- **Origen**: Continúa usando el peso inicial (correcto)
- **Transformador**: Usa peso de salida o entrada (correcto)
- **Transporte**: Ahora registra los pesos correctos en cada fase

### Consideración Importante - Laboratorio:
- El método resta automáticamente el peso de las muestras del laboratorio
- Esto es correcto siempre que el laboratorio tome las muestras ANTES de que el transportista recoja
- Confirmado por el usuario que este es siempre el flujo correcto

### Lotes Antiguos:
- Pueden no tener el campo `peso_procesado`
- El sistema usa `pesoEntrada` como fallback (comportamiento seguro)
- Los lotes antiguos serán eliminados según confirmación del usuario

## Resultado
El transportista ahora registra correctamente el peso procesado por el reciclador, mejorando la precisión de la trazabilidad en toda la cadena de suministro.

## Fecha de Implementación
25 de Julio de 2025