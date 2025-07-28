# Implementación del Sistema de Transformaciones y Sublotes - Usuario Reciclador

## Resumen

Este documento detalla la implementación completa del sistema de transformaciones (megalotes) y sublotes para el usuario Reciclador en la aplicación BioWay México.

## Fecha de Implementación
25-28 de Enero de 2025

## Funcionalidades Implementadas

### 1. Creación de Megalotes (Transformaciones)

- **Selección múltiple de lotes** en la pestaña "Salida"
- **Formulario de procesamiento** con captura de merma
- **Consumo de lotes originales** marcándolos como `consumido_en_transformacion: true`
- **Creación automática** del documento de transformación

### 2. Gestión de Sublotes

- **Creación bajo demanda** desde megalotes con peso disponible
- **Control de peso** para evitar exceder el peso disponible
- **Generación de QR único** para cada sublote
- **Trazabilidad completa** hacia los lotes originales

### 3. Sistema de Documentación

- **Carga de documentos** requeridos (Ficha Técnica y Reporte de Resultados)
- **Eliminación automática** de megalotes cuando peso = 0 Y documentación completa
- **Prevención de eliminación** si hay peso disponible o falta documentación

## Archivos Clave Modificados

### Modelos
- `lib/models/lotes/transformacion_model.dart`
- `lib/models/lotes/sublote_model.dart`
- `lib/models/lotes/lote_unificado_model.dart`

### Servicios
- `lib/services/transformacion_service.dart`
- `lib/services/lote_unificado_service.dart`

### Pantallas
- `lib/screens/ecoce/reciclador/reciclador_administracion_lotes.dart`
- `lib/screens/ecoce/reciclador/reciclador_formulario_salida.dart`
- `lib/screens/ecoce/reciclador/reciclador_transformacion_documentacion.dart`
- `lib/screens/ecoce/reciclador/reciclador_inicio.dart`

## Flujo de Proceso

### 1. Crear Megalote

```dart
// En reciclador_formulario_salida.dart
Future<void> _procesarLotes() async {
  // 1. Crear transformación
  final transformacionId = await _transformacionService.crearTransformacion(
    lotes: lotes,
    mermaProceso: _merma,
    procesoAplicado: _procesoAplicadoController.text,
    observaciones: _observacionesController.text,
  );
  
  // 2. Marcar lotes como consumidos
  await _loteUnificadoService.marcarLotesComoConsumidos(
    loteIds: widget.lotIds,
    transformacionId: transformacionId,
  );
  
  // 3. Navegar a lotes completados
  Navigator.pushNamedAndRemoveUntil(
    context,
    '/reciclador_lotes',
    arguments: {'initialTab': 1},
    (route) => false,
  );
}
```

### 2. Crear Sublote

```dart
// En reciclador_administracion_lotes.dart
Future<void> _mostrarDialogoCrearSublote(TransformacionModel transformacion) async {
  // Dialog con input de peso
  final resultado = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) => _SubLoteCreationDialog(
      transformacion: transformacion,
      onCrear: (peso) async {
        final subloteId = await _transformacionService.crearSublote(
          transformacionId: transformacion.id,
          peso: peso,
        );
        return subloteId;
      },
    ),
  );
}
```

### 3. Documentación

```dart
// En reciclador_transformacion_documentacion.dart
Future<void> _subirDocumento(String tipoDocumento) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf'],
  );
  
  if (result != null) {
    final url = await _documentService.subirDocumentoConCompresion(
      archivo: file,
      rutaStorage: 'ecoce/transformaciones/${widget.transformacionId}/$fileName',
      maxSizeMB: 5,
    );
    
    await _transformacionService.actualizarDocumento(
      transformacionId: widget.transformacionId,
      tipoDocumento: tipoDocumento,
      url: url,
    );
  }
}
```

## Estructura de Datos en Firebase

### Colección `transformaciones`

```javascript
{
  "id": "TRANS-001",
  "tipo": "agrupacion_reciclador",
  "fecha_inicio": Timestamp,
  "fecha_fin": Timestamp | null,
  "estado": "en_proceso" | "completada",
  "lotes_entrada": [
    {
      "lote_id": "LOTE-001",
      "peso": 100.0,
      "porcentaje": 50.0,
      "tipo_material": "PEBD"
    }
  ],
  "peso_total_entrada": 200.0,
  "peso_disponible": 180.0,
  "merma_proceso": 20.0,
  "sublotes_generados": ["SUB-001", "SUB-002"],
  "documentos_asociados": {
    "f_tecnica_pellet": "https://...",
    "rep_result_reci": "https://..."
  },
  "usuario_id": "userId",
  "usuario_folio": "R0000001",
  "proceso_aplicado": "Lavado y triturado",
  "observaciones": "Proceso estándar"
}
```

### Modificación en `lotes/{loteId}/datos_generales/info`

```javascript
{
  // ... campos existentes ...
  "consumido_en_transformacion": true,
  "transformacion_id": "TRANS-001"
}
```

### Sublotes en `lotes/{subloteId}`

```javascript
{
  "datos_generales": {
    "tipo_lote": "derivado",
    "transformacion_origen": "TRANS-001",
    "composicion": {
      "LOTE-001": {
        "peso_aportado": 50.0,
        "porcentaje": 50.0
      },
      "LOTE-002": {
        "peso_aportado": 50.0,
        "porcentaje": 50.0
      }
    },
    // ... otros campos estándar ...
  }
}
```

## Reglas de Negocio Implementadas

### 1. Creación de Megalotes
- Solo lotes con `proceso_actual == 'reciclador'`
- Solo lotes no consumidos (`consumido_en_transformacion != true`)
- Mínimo 1 lote para crear transformación
- Merma no puede exceder el peso total

### 2. Creación de Sublotes
- Solo si `transformacion.pesoDisponible > 0`
- Peso del sublote no puede exceder peso disponible
- Cada sublote genera un QR único
- Mantiene trazabilidad completa

### 3. Eliminación de Megalotes
- Automática cuando `pesoDisponible <= 0 && tieneDocumentacion == true`
- No se puede eliminar manualmente
- Se oculta de la UI cuando cumple criterios

### 4. Visibilidad en UI
- Lotes consumidos no aparecen en pestaña "Salida"
- Solo megalotes con peso disponible muestran botón de crear sublote
- Sublotes aparecen en "Completados" del Reciclador

## Problemas Resueltos Durante la Implementación

### 1. Type Casting Error (28/01/2025)
**Problema**: Error al navegar después de crear transformación
**Solución**: Cambiar `arguments: 1` por `arguments: {'initialTab': 1}`

### 2. Lotes Consumidos No Desaparecían (28/01/2025)
**Problema**: Lotes usados seguían apareciendo en "Salida"
**Solución**: Corregir referencia de documento de `'data'` a `'info'` en datos_generales

### 3. Sublotes No Visibles (28/01/2025)
**Problema**: Sublotes creados no aparecían en "Completados"
**Solución**: Actualizar filtros para incluir sublotes con `proceso_actual == 'reciclador'`

### 4. Estadísticas en 0 (28/01/2025)
**Problema**: Las estadísticas mostraban 0 a pesar de tener datos
**Solución**: 
- Cambiar campo de búsqueda de `usuarioId` a `usuario_id`
- Contar lotes desde transformaciones en lugar de colección lotes

## Mejoras Futuras Sugeridas

1. **Validación de documentos**: Verificar que los PDFs sean válidos antes de subirlos
2. **Historial de transformaciones**: Vista detallada del historial de cada transformación
3. **Reportes**: Generación de reportes de transformaciones por período
4. **Notificaciones**: Alertar cuando un megalote está listo para documentación
5. **Optimización**: Implementar paginación para listas grandes de transformaciones

## Conclusión

La implementación del sistema de transformaciones y sublotes proporciona al usuario Reciclador una herramienta completa para gestionar el procesamiento de múltiples lotes, manteniendo la trazabilidad completa y cumpliendo con los requisitos de documentación del sistema ECOCE.