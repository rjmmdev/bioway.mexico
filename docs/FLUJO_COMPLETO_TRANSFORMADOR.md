# Flujo Completo del Sistema de Trazabilidad - Usuario Transformador
## Fecha: 2025-01-29

## Resumen Ejecutivo
Con la implementación del módulo del Transformador, el flujo completo del sistema de trazabilidad está operativo. El sistema permite el seguimiento de materiales reciclables desde su origen hasta su transformación final, con trazabilidad completa en cada etapa.

## Flujo Completo del Sistema

### 1. **Origen** (Centro de Acopio / Planta de Separación)
- Crea lotes iniciales con código QR
- Peso inicial registrado (`peso_nace`)
- Estado: `proceso_actual = 'origen'`

### 2. **Transporte Fase 1** (Origen → Reciclador)
- Escanea múltiples lotes para crear carga
- Confirma entrega con firma
- Actualiza: `proceso_actual = 'transporte'`

### 3. **Reciclador**
- Recibe lotes mediante escaneo QR
- Procesa y crea megalotes (transformaciones)
- Genera sublotes con nuevos pesos
- Registra merma del proceso
- Estado: `proceso_actual = 'reciclador'`

### 4. **Laboratorio** (Proceso Paralelo)
- Toma muestras sin transferir propiedad
- No cambia `proceso_actual`
- Registra análisis y certificados

### 5. **Transporte Fase 2** (Reciclador → Transformador)
- Transporta sublotes generados
- Proceso idéntico a Fase 1
- Actualiza: `proceso_actual = 'transporte'`

### 6. **Transformador** (IMPLEMENTADO COMPLETAMENTE)
- Recibe sublotes del Reciclador
- TODOS los lotes (individuales o múltiples) se convierten en megalotes
- Procesa materiales y genera productos finales
- Estado: `proceso_actual = 'transformador'`

## Implementación del Transformador - Detalles Técnicos

### Arquitectura de Transformaciones

#### Creación Unificada de Megalotes
```dart
// TODOS los lotes procesados crean transformaciones
// Ya sea procesamiento individual o múltiple
{
  'tipo': 'agrupacion_transformador',
  'usuario_id': userId,
  'estado': 'documentacion', // Estados: en_proceso, documentacion, completado
  'peso_total_entrada': pesoOriginal,
  'peso_salida': pesoReal, // Peso real recibido del Reciclador
  'peso_disponible': pesoActual,
  'lotes_entrada': [...], // Array de lotes procesados
}
```

### Problemas Resueltos y Soluciones Implementadas

#### 1. Creación de Megalotes Duplicados
**Problema**: Se creaban dos megalotes al procesar - uno con peso 0 y otro con peso correcto
**Causa**: 
- Guardado automático de borrador al firmar
- `_pesoSalidaController` vacío al guardar borrador

**Solución**:
```dart
// Eliminado guardado automático después de firma
// Verificación de transformaciones existentes antes de crear nueva
final existingQuery = await _firestore
    .collection('transformaciones')
    .where('usuario_id', isEqualTo: authUid)
    .get();

// Buscar si ya existe transformación con mismos lotes
for (var doc in existingQuery.docs) {
  final existingLotes = (data['lotes_entrada'] as List<dynamic>?) ?? [];
  if (lotesCoinciden) {
    _transformacionId = doc.id; // Reusar existente
    break;
  }
}
```

#### 2. Visualización Incorrecta de Peso
**Problema**: Tarjetas mostraban "cantidad generada" (unidades) como peso
**Solución**:
```dart
// Ahora usa peso_salida para el peso real
final pesoSalida = transformacion.datos['peso_salida'] ?? transformacion.pesoDisponible;
// cantidad_producto se muestra separadamente como unidades
```

#### 3. Estadísticas de Material Procesado Incorrectas
**Problema**: Usaba `peso_total_entrada` (peso original del Reciclador)
**Solución**:
```dart
// Ahora usa peso_salida (peso real recibido)
final pesoRecibido = (data['peso_salida'] ?? data['peso_total_entrada'] ?? 0).toDouble();
materialProcesado += pesoRecibido;
```

#### 4. Filtros de Visualización
**Problema**: Toggle "Mostrar Solo Megalotes" innecesario
**Solución**: 
- Eliminados filtros ya que TODO se convierte en megalotes
- Pestañas simplificadas:
  - **Salida**: Lotes pendientes de procesar
  - **Documentación**: Megalotes en estado 'documentacion' o 'en_proceso'
  - **Completados**: Megalotes en estado 'completado'

#### 5. Estadísticas por Pestaña
**Problema**: Peso disponible mostraba total de todos los megalotes
**Solución**:
```dart
// Filtrar por estado según pestaña actual
final transformacionesPestanaActual = _filterTransformacionesByState();
final pesoDisponible = transformacionesPestanaActual.fold(0.0, (sum, t) => sum + t.pesoDisponible);
```

### Estructura de Datos Final

#### Transformaciones del Transformador
```
transformaciones/
  [transformacionId]/
    tipo: 'agrupacion_transformador'
    usuario_id: string
    estado: 'documentacion' | 'completado'
    lotes_entrada: [
      {
        lote_id: string,
        peso: number,
        tipo_material: string,
        porcentaje: number
      }
    ]
    peso_total_entrada: number  // Peso original
    peso_salida: number         // Peso real recibido
    peso_disponible: number     // Peso actual disponible
    producto_fabricado: string
    cantidad_producto: number   // Unidades generadas
    procesos_aplicados: []
    documentos_asociados: {}
```

### Pestañas y Estados

#### Pestaña Salida
- Muestra: Sublotes pendientes de procesar
- Condición: `proceso_actual == 'transformador'` && sin transformación asociada
- Acción: Crear megalote (transformación)

#### Pestaña Documentación  
- Muestra: Megalotes esperando documentación
- Condición: `estado IN ['documentacion', 'en_proceso']`
- Acción: Subir documentación técnica

#### Pestaña Completados
- Muestra: Megalotes completamente procesados
- Condición: `estado == 'completado'`
- Solo lectura

## Validaciones Críticas

### 1. Prevención de Duplicados
- Verificar transformaciones existentes antes de crear
- Validar peso de salida antes de guardar borrador
- No guardar automáticamente al firmar

### 2. Cálculos de Peso
- **Peso recibido**: Usar `peso_salida` del Reciclador
- **Merma**: `peso_original - peso_salida`
- **Estadísticas**: Filtrar por pestaña actual

### 3. Visibilidad de Datos
- Usar `obtenerMisLotesPorProcesoActual()` no `obtenerLotesPorProceso()`
- Filtrar siempre por `usuario_id`
- Verificar campo `usuario_id` en transformador/data

## Pendientes para Finalización

### 1. Módulo Repositorio
- Visualización de todo el flujo
- Reportes consolidados
- Trazabilidad completa

### 2. Optimizaciones
- Caché de transformaciones
- Paginación para grandes volúmenes
- Índices de Firestore optimizados

### 3. Validaciones Adicionales
- Verificar peso mínimo/máximo
- Validar tipos de material compatibles
- Control de calidad automatizado

## Estado Actual del Sistema

✅ **COMPLETADO**:
- Flujo completo Origen → Transformador
- Creación y gestión de megalotes
- Sistema de documentación
- Estadísticas por usuario
- Prevención de duplicados
- Cálculos de peso correctos

⏳ **PENDIENTE**:
- Módulo Repositorio
- Reportes PDF
- Dashboard administrativo
- Optimizaciones de rendimiento

## Conclusión

El sistema de trazabilidad está funcionalmente completo con la implementación del módulo Transformador. El flujo permite el seguimiento completo de materiales desde su origen hasta su transformación final, con puntos de control y documentación en cada etapa. Solo resta implementar el módulo de Repositorio para visualización consolidada y reportes finales.