# Solución de Estadísticas del Usuario Reciclador

## Resumen del Problema

Las estadísticas del usuario Reciclador mostraban valores de 0 a pesar de que existían datos en el sistema (megalotes creados y lotes procesados). El problema radicaba en:

1. **Nombres de campos incorrectos** en las consultas de Firebase
2. **Estrategia inadecuada** para contar lotes que habían sido consumidos en transformaciones
3. **Búsqueda en colecciones vacías** del sistema antiguo

## Fecha de Implementación
28 de Enero de 2025

## Archivos Modificados

- `lib/services/lote_unificado_service.dart`
- `lib/screens/ecoce/reciclador/reciclador_inicio.dart`
- `pubspec.yaml` (se agregó rxdart pero luego se removió)

## Análisis del Problema

### 1. Estructura de Datos en Firebase

La investigación reveló:
- La colección `lotes` estaba vacía (0 documentos)
- Las colecciones del sistema antiguo (`lotes_origen`, `lotes_reciclador`) también estaban vacías
- Las transformaciones SÍ existían y contenían referencias a los lotes procesados

### 2. Nombres de Campos

Los logs de debug mostraron que:
```
usuarioId: null
usuario_id: LlCQksT0UmcnfbM0cL2tY4UoQdo1
creado_por: null
```

El campo correcto era `usuario_id` (con guión bajo), no `usuarioId`.

### 3. Lotes Consumidos

Los lotes originales fueron marcados como `consumido_en_transformacion: true` y ya no aparecen en las consultas normales, por lo que era necesario cambiar la estrategia de conteo.

## Solución Implementada

### 1. Método `obtenerEstadisticasReciclador()`

```dart
Future<Map<String, dynamic>> obtenerEstadisticasReciclador() async {
  try {
    final userId = _currentUserId;
    if (userId == null) {
      return {
        'lotesRecibidos': 0,
        'megalotesCreados': 0,
        'materialProcesado': 0.0,
      };
    }

    int lotesRecibidos = 0;
    int megalotesCreados = 0;
    double materialProcesado = 0.0;

    // Obtener todas las transformaciones del usuario
    final transformacionesUsuario = await _firestore
        .collection('transformaciones')
        .where('usuario_id', isEqualTo: userId)
        .get();
    
    Set<String> lotesUnicos = {};
    
    // Contar lotes únicos desde las transformaciones
    for (final transformDoc in transformacionesUsuario.docs) {
      final data = transformDoc.data();
      final lotesEntrada = data['lotes_entrada'] as List<dynamic>?;
      
      if (lotesEntrada != null) {
        for (var lote in lotesEntrada) {
          if (lote is Map<String, dynamic>) {
            final loteId = lote['lote_id'] as String?;
            if (loteId != null) {
              lotesUnicos.add(loteId);
            }
          }
        }
      }
    }
    
    lotesRecibidos = lotesUnicos.length;
    megalotesCreados = transformacionesUsuario.docs.length;
    
    // Sumar el peso de entrada de todos los megalotes
    for (final transformacionDoc in transformacionesUsuario.docs) {
      final data = transformacionDoc.data();
      final pesoTotalEntrada = (data['peso_total_entrada'] as num?)?.toDouble() ?? 0.0;
      materialProcesado += pesoTotalEntrada;
    }

    return {
      'lotesRecibidos': lotesRecibidos,
      'megalotesCreados': megalotesCreados,
      'materialProcesado': materialProcesado,
    };
  } catch (e) {
    debugPrint('Error obteniendo estadísticas del reciclador: $e');
    return {
      'lotesRecibidos': 0,
      'megalotesCreados': 0,
      'materialProcesado': 0.0,
    };
  }
}
```

### 2. Método `streamEstadisticasReciclador()`

```dart
Stream<Map<String, dynamic>> streamEstadisticasReciclador() {
  final userId = _currentUserId;
  
  if (userId == null) {
    return Stream.value({
      'lotesRecibidos': 0,
      'megalotesCreados': 0,
      'materialProcesado': 0.0,
    });
  }

  // Stream solo de transformaciones
  return _firestore
      .collection('transformaciones')
      .where('usuario_id', isEqualTo: userId)
      .snapshots()
      .map((transformacionesSnapshot) {
        int lotesRecibidos = 0;
        int megalotesCreados = 0;
        double materialProcesado = 0.0;
        
        Set<String> lotesUnicos = {};
        
        megalotesCreados = transformacionesSnapshot.docs.length;
        
        // Contar lotes únicos y sumar material procesado
        for (final transformacionDoc in transformacionesSnapshot.docs) {
          final data = transformacionDoc.data();
          
          // Contar lotes únicos
          final lotesEntrada = data['lotes_entrada'] as List<dynamic>?;
          if (lotesEntrada != null) {
            for (var lote in lotesEntrada) {
              if (lote is Map<String, dynamic>) {
                final loteId = lote['lote_id'] as String?;
                if (loteId != null) {
                  lotesUnicos.add(loteId);
                }
              }
            }
          }
          
          // Sumar peso
          final pesoTotalEntrada = (data['peso_total_entrada'] as num?)?.toDouble() ?? 0.0;
          materialProcesado += pesoTotalEntrada;
        }
        
        lotesRecibidos = lotesUnicos.length;
        
        return {
          'lotesRecibidos': lotesRecibidos,
          'megalotesCreados': megalotesCreados,
          'materialProcesado': materialProcesado,
        };
      });
}
```

## Cambios Clave

### 1. Nueva Estrategia de Conteo

**Antes**: Buscábamos lotes en la colección `lotes` con proceso reciclador.

**Después**: Contamos los lotes únicos desde las transformaciones, ya que los lotes originales fueron consumidos.

### 2. Corrección de Nombres de Campos

**Antes**: `where('usuarioId', isEqualTo: userId)` y `recibido_por_id`

**Después**: `where('usuario_id', isEqualTo: userId)`

### 3. Simplificación del Stream

**Antes**: Usábamos `CombineLatestStream` de rxdart para combinar dos streams.

**Después**: Un solo stream de transformaciones que calcula todas las estadísticas.

## Estadísticas Resultantes

Las estadísticas ahora muestran correctamente:

1. **Lotes recibidos**: Total de lotes únicos que han sido procesados en transformaciones por el usuario
2. **Megalotes creados**: Total de transformaciones creadas por el usuario
3. **Material procesado**: Suma del peso de entrada (`peso_total_entrada`) de todas las transformaciones

## Ventajas de la Solución

1. **Eficiencia**: Una sola consulta a Firebase en lugar de múltiples
2. **Precisión**: Cuenta correctamente los lotes incluso si han sido consumidos
3. **Mantenibilidad**: Código más simple sin dependencias externas (rxdart)
4. **Tiempo real**: Las estadísticas se actualizan automáticamente con el stream

## Lecciones Aprendidas

1. **Siempre verificar los nombres exactos de campos** en Firebase antes de hacer consultas
2. **Considerar el ciclo de vida completo de los datos** (lotes consumidos vs activos)
3. **Usar logs de debug extensivos** para identificar problemas de estructura de datos
4. **Adaptar la estrategia** según cómo se almacenan realmente los datos

## Conclusión

La solución implementada resuelve completamente el problema de las estadísticas mostrando 0, adaptándose a la realidad de cómo el sistema maneja los lotes consumidos en transformaciones. Las estadísticas ahora reflejan con precisión la actividad del usuario Reciclador en el sistema.