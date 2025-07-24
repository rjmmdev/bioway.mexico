# Estrategia de Limpieza de Documentos - VERSIÓN CONSERVADORA

## Objetivo

Mantener las colecciones `cargas_transporte` y `entregas_transporte` organizadas, marcando documentos obsoletos SIN eliminarlos automáticamente para evitar interferencias con procesos activos.

## Estrategia Conservadora

### 1. NO Limpieza Automática

**IMPORTANTE**: La limpieza automática está DESACTIVADA por defecto para evitar:
- Interferencias con procesos activos
- Pérdida accidental de datos
- Problemas con pocos usuarios transportistas

### 2. Solo Marcado de Documentos

Por defecto, el sistema:
- **MARCA** documentos como `archivada_para_limpieza`
- **NO ELIMINA** documentos automáticamente
- Requiere intervención manual para eliminación física

### 3. Condiciones para Marcar (NO eliminar)

#### Documentos de `cargas_transporte`:
- Estado: `completada_y_transferida`
- Marcada para limpieza: `marcada_para_limpieza: true`
- Tiempo de retención: **30 días** desde `fecha_transferencia_completa`
- Verificación adicional: Todos los lotes están fuera del proceso transporte

#### Documentos de `entregas_transporte`:
- Estado: `entregada` o `completada_archivada`
- Todos los lotes han sido transferidos fuera de transporte
- Tiempo de retención: **30 días** desde la entrega/archivado

## Estados de Carga

1. **`en_transporte`**: Carga activa, no se elimina
2. **`entregada_parcial`**: Algunos lotes entregados, no se elimina
3. **`entregada_completa`**: Todos entregados pero no todos recibidos, no se elimina
4. **`completada_y_transferida`**: Todos entregados Y recibidos, candidata para limpieza

## Flujo de Limpieza

```
1. Transportista entrega → Receptor recibe
2. Sistema verifica transferencia completa
3. Marca carga como `completada_y_transferida`
4. Agrega `fecha_transferencia_completa` y `marcada_para_limpieza`
5. Después de 7 días → Elimina documentos
```

## Seguridad

### Verificaciones antes de eliminar:
1. Re-verificar que todos los lotes están fuera de transporte
2. Verificar tiempo de retención (7 días por defecto)
3. No eliminar si hay discrepancias

### Casos especiales:
- Si falla la eliminación por permisos → Marcar como `archivada`
- Mantener logs de eliminación para auditoría

## Configuración Segura

```dart
// Por defecto: Solo marca, NO elimina
await cargaService.limpiarDocumentosCompletados(
  tiempoRetencion: const Duration(days: 30), // 30 días por defecto
  soloMarcar: true, // IMPORTANTE: No elimina físicamente
);

// Para eliminación física (usar con precaución)
await cargaService.limpiarDocumentosCompletados(
  tiempoRetencion: const Duration(days: 60), // Más conservador
  soloMarcar: false, // Elimina físicamente
);
```

## Métodos de Monitoreo

```dart
// Ver estadísticas antes de limpiar
final stats = await cargaService.obtenerEstadisticasLimpieza();
print('Cargas pendientes: ${stats['cargas_pendientes']}');
print('Entregas completadas: ${stats['entregas_completadas']}');
print('Documentos archivados: ${stats['documentos_archivados']}');

// Verificar si hay documentos pendientes
final hayPendientes = await cargaService.hayDocumentosPendientesLimpieza(
  tiempoRetencion: Duration(days: 30),
);
```

## Beneficios

1. **Base de datos limpia**: Evita acumulación de documentos obsoletos
2. **Mejor rendimiento**: Menos documentos para consultar
3. **Menor costo**: Reduce almacenamiento en Firestore
4. **Sin impacto operativo**: Solo elimina después de transferencias completas

## Monitoreo

Para monitorear el estado de limpieza:
```
// Documentos pendientes de limpieza
cargas_transporte
  .where('marcada_para_limpieza', '==', true)
  .where('fecha_transferencia_completa', '<', hace_7_dias)

// Entregas completadas
entregas_transporte
  .where('estado_entrega', 'in', ['entregada', 'completada_archivada'])
```

## Implementación Manual Recomendada

### Proceso Seguro de Limpieza:

1. **Verificar estadísticas**:
```dart
final stats = await cargaService.obtenerEstadisticasLimpieza();
// Revisar cuántos documentos hay pendientes
```

2. **Marcar documentos** (no eliminar):
```dart
await cargaService.limpiarDocumentosCompletados(
  tiempoRetencion: Duration(days: 30),
  soloMarcar: true, // Solo marca, no elimina
);
```

3. **Esperar período de observación** (1-2 semanas)

4. **Eliminar físicamente** (solo si es seguro):
```dart
// SOLO ejecutar después de verificar que no hay problemas
await cargaService.limpiarDocumentosCompletados(
  tiempoRetencion: Duration(days: 60), // Muy conservador
  soloMarcar: false, // Ahora sí elimina
);
```

## Recomendaciones de Seguridad

1. **NUNCA** ejecutar limpieza automática sin supervisión
2. **SIEMPRE** verificar estadísticas antes de limpiar
3. **PREFERIR** marcar sobre eliminar
4. **MANTENER** período de retención largo (30+ días)
5. **DOCUMENTAR** cada limpieza ejecutada
6. **CONSIDERAR** el número de transportistas activos antes de limpiar