# Actualización Temporal del Límite de PDFs a 5MB

## Contexto

Los usuarios no podían subir documentación PDF mayor a 1MB a pesar de que la interfaz mostraba "máx. 5MB", causando confusión y bloqueando el flujo de documentación, especialmente en megalotes del Reciclador.

**Fecha de implementación**: 28 de Enero de 2025
**Tipo de cambio**: Temporal hasta implementar compresión real

## Problema Original

### Inconsistencia de Límites
- **UI mostraba**: "PDF (máx. 5MB)"
- **DocumentService permitía**: 5MB
- **FirebaseStorageService rechazaba**: > 1MB

### Sistema de Compresión No Funcional
El servicio `PdfCompressionService` es un placeholder que no realiza compresión real:

```dart
// lib/services/pdf_compression_service.dart (línea 39-45)
static Future<Uint8List> _reduceQuality(Uint8List pdfBytes) async {
  // NOTA: Esta es una implementación placeholder
  // Por ahora, retornamos el PDF original
  return pdfBytes; // NO HACE COMPRESIÓN
}
```

## Solución Temporal Implementada

### Archivos Modificados

1. **`lib/services/firebase/firebase_storage_service.dart`** (línea 75)
   ```dart
   // ANTES
   if (fileData.length > 1024 * 1024) {
     throw Exception('El archivo es demasiado grande. Máximo 1MB.');
   }
   
   // AHORA
   if (fileData.length > 5 * 1024 * 1024) {
     throw Exception('El archivo es demasiado grande. Máximo 5MB.');
   }
   ```

2. **`lib/services/document_compression_service.dart`** (línea 15)
   ```dart
   // ANTES
   static const int maxPdfSize = 1024 * 1024; // 1MB
   
   // AHORA
   static const int maxPdfSize = 5 * 1024 * 1024; // 5MB
   ```

3. **`lib/services/document_service.dart`** (línea 87)
   ```dart
   // ANTES
   if (sizeInMB < 1.0) {
     return file.bytes;
   }
   
   // AHORA
   if (sizeInMB < 5.0) {
     return file.bytes;
   }
   ```

### Mensajes de Error Actualizados
Todos los mensajes de error se actualizaron para mostrar consistentemente "Máximo 5MB".

## Comportamiento Actual

| Tamaño del PDF | Antes | Ahora |
|---------------|-------|-------|
| < 1MB | ✅ Acepta | ✅ Acepta |
| 1-5MB | ❌ Rechaza con error | ✅ Acepta sin compresión |
| > 5MB | ❌ Rechaza | ❌ Rechaza con mensaje claro |

## Impacto en el Sistema

### Positivo
- ✅ Usuarios pueden subir documentación hasta 5MB
- ✅ Consistencia entre UI y backend
- ✅ Desbloquea flujo de documentación de megalotes
- ✅ Elimina confusión de usuarios

### Consideraciones
- ⚠️ Mayor uso de almacenamiento en Firebase Storage
- ⚠️ PDFs de 1-5MB se suben sin optimización
- ⚠️ Mayor tiempo de carga/descarga para archivos grandes
- ⚠️ Posible incremento en costos de Firebase Storage

## Plan a Futuro

### Opciones de Compresión Real Analizadas

1. **Compresión con librería `pdf` existente**
   - Factible pero con limitaciones
   - Tasa esperada: 30-50% en PDFs con imágenes
   - Tiempo estimado: 2-3 días de implementación

2. **Sistema de Compresión por Niveles**
   ```
   < 1MB: Sin compresión
   1-3MB: Compresión ligera
   3-5MB: Compresión media
   > 5MB: Compresión agresiva o rechazo
   ```

3. **Procesamiento Asíncrono**
   - Upload del original a carpeta temporal
   - Cloud Function procesa y comprime
   - Notificación cuando esté listo

### Recomendación
Implementar compresión progresiva cuando se estabilice el flujo completo de lotes, priorizando:
- Compresión rápida para no afectar UX
- Preservación de calidad para documentos legales
- Manejo robusto de errores

## Monitoreo Recomendado

1. **Métricas a trackear**:
   - Tamaño promedio de PDFs subidos
   - Cantidad de PDFs entre 1-5MB
   - Tiempo de carga promedio
   - Uso de almacenamiento en Firebase

2. **Alertas sugeridas**:
   - Uso de storage > 80% del límite
   - PDFs > 4MB (candidatos a compresión)
   - Errores de timeout en uploads

## Documentación Relacionada

- `docs/ANALISIS_COMPRESION_PDF.md` - Análisis detallado del sistema actual
- `docs/PLAN_IMPLEMENTACION_COMPRESION.md` - Plan completo para compresión real
- `CLAUDE.md` - Actualizado con nueva configuración

## Estado

🟡 **TEMPORAL** - Solución provisional funcionando en producción

Esta solución debe ser reemplazada por compresión real cuando las prioridades del proyecto lo permitan.