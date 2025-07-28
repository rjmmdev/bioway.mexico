import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Servicio especializado para comprimir PDFs
class PdfCompressionService {
  /// Comprimir un PDF manteniendo el contenido lo más posible
  static Future<Uint8List> compressPdf(Uint8List pdfBytes, int targetSize) async {
    try {
      // Por ahora, implementamos una compresión básica
      // En producción, se debería usar una librería especializada o servicio externo
      
      // Estrategia 1: Intentar reducir la calidad del PDF
      final reducedQualityPdf = await _reduceQuality(pdfBytes);
      if (reducedQualityPdf.length <= targetSize) {
        return reducedQualityPdf;
      }
      
      // Estrategia 2: Si aún es muy grande, crear un PDF con advertencia
      return await _createWarningPdf(pdfBytes.length, targetSize);
      
    } catch (e) {
      print('[PdfCompression] Error al comprimir PDF: $e');
      rethrow;
    }
  }
  
  /// Reducir la calidad del PDF (implementación básica)
  static Future<Uint8List> _reduceQuality(Uint8List pdfBytes) async {
    try {
      // NOTA: Esta es una implementación placeholder
      // En producción se necesitaría:
      // 1. Parsear el PDF original
      // 2. Extraer y comprimir imágenes
      // 3. Reducir calidad de gráficos
      // 4. Optimizar fuentes
      
      // Por ahora, retornamos el PDF original
      // Una implementación real podría usar librerías como:
      // - pdf_manipulator
      // - pdf_compressor (no existe aún para Flutter)
      // - Servicio externo de compresión
      
      return pdfBytes;
    } catch (e) {
      print('[PdfCompression] Error al reducir calidad: $e');
      return pdfBytes;
    }
  }
  
  /// Crear un PDF con advertencia cuando no se puede comprimir
  static Future<Uint8List> _createWarningPdf(int originalSize, int targetSize) async {
    final pdf = pw.Document();
    
    // Calcular porcentaje de reducción necesario
    final reductionNeeded = ((originalSize - targetSize) / originalSize * 100).toStringAsFixed(1);
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.red50,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'PDF No Comprimible',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.red800,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'El archivo PDF excede el límite permitido y no pudo ser comprimido automáticamente.',
                      style: const pw.TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),
              pw.Text(
                'Detalles del archivo:',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              _buildInfoRow('Tamaño original:', _formatBytes(originalSize)),
              _buildInfoRow('Tamaño máximo permitido:', _formatBytes(targetSize)),
              _buildInfoRow('Reducción necesaria:', '$reductionNeeded%'),
              pw.SizedBox(height: 30),
              pw.Text(
                'Recomendaciones para reducir el tamaño:',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              _buildRecommendation('1.', 'Comprima las imágenes antes de crear el PDF'),
              _buildRecommendation('2.', 'Use herramientas en línea como SmallPDF o ILovePDF'),
              _buildRecommendation('3.', 'Divida el documento en múltiples archivos'),
              _buildRecommendation('4.', 'Reduzca la resolución de escaneo (150-200 DPI)'),
              _buildRecommendation('5.', 'Evite incluir imágenes de alta resolución'),
              pw.SizedBox(height: 30),
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.amber50,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Text(
                  'Nota: Este documento temporal se ha generado porque el archivo original '
                  'no pudo ser procesado. Por favor, comprima el archivo manualmente '
                  'antes de intentar cargarlo nuevamente.',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ),
            ],
          );
        },
      ),
    );
    
    return Uint8List.fromList(await pdf.save());
  }
  
  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 200,
            child: pw.Text(label, style: const pw.TextStyle(fontSize: 14)),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildRecommendation(String number, String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 30,
            child: pw.Text(number, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ),
          pw.Expanded(
            child: pw.Text(text, style: const pw.TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
  
  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}