import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import 'pdf_compression_service.dart';

/// Servicio para comprimir documentos antes de subirlos
class DocumentCompressionService {
  /// Tamaño máximo de entrada para PDFs en bytes (5MB)
  static const int maxPdfInputSize = 5 * 1024 * 1024; // 5MB
  
  /// Tamaño máximo objetivo para PDFs en bytes (1MB)
  static const int maxPdfSize = 1024 * 1024; // 1MB
  
  /// Tamaño máximo objetivo para imágenes en bytes (50KB)
  static const int maxImageSize = 50 * 1024; // 50KB
  
  /// Calidad de compresión de imágenes (0-100)
  static const int imageQuality = 60;
  
  /// Comprimir un archivo PDF
  static Future<Uint8List?> compressPdf(File pdfFile) async {
    try {
      print('[DocumentCompression] Procesando PDF: ${pdfFile.path}');
      final originalSize = await pdfFile.length();
      print('[DocumentCompression] Tamaño original: ${formatBytes(originalSize)}');
      
      // Si el archivo ya es pequeño, no comprimir
      if (originalSize <= maxPdfSize) {
        print('[DocumentCompression] PDF ya está optimizado, no se requiere compresión');
        return await pdfFile.readAsBytes();
      }
      
      // Si el PDF es demasiado grande, rechazarlo
      if (originalSize > maxPdfInputSize) {
        print('[DocumentCompression] PDF demasiado grande: ${formatBytes(originalSize)}');
        throw Exception('El PDF es demasiado grande (${formatBytes(originalSize)}). Por favor, use un archivo de menos de 5MB.');
      }
      
      // Leer el PDF original
      final originalBytes = await pdfFile.readAsBytes();
      
      // Intentar comprimir el PDF usando el servicio especializado
      try {
        print('[DocumentCompression] Intentando comprimir PDF de ${formatBytes(originalSize)} a menos de 1MB...');
        final compressedBytes = await PdfCompressionService.compressPdf(originalBytes, maxPdfSize);
        final compressedSize = compressedBytes.length;
        
        print('[DocumentCompression] Resultado: ${formatBytes(originalSize)} → ${formatBytes(compressedSize)}');
        
        // Verificar si la compresión fue exitosa
        if (compressedSize <= maxPdfSize) {
          final reduction = ((originalSize - compressedSize) / originalSize * 100);
          print('[DocumentCompression] PDF comprimido exitosamente (-${reduction.toStringAsFixed(1)}%)');
          return compressedBytes;
        } else {
          print('[DocumentCompression] No se pudo comprimir el PDF por debajo de 1MB');
          throw Exception('No se pudo comprimir el PDF a menos de 1MB. Por favor, use un archivo más pequeño o con menos imágenes.');
        }
      } catch (e) {
        print('[DocumentCompression] Error durante la compresión: $e');
        // Si el PDF original cabe, usarlo
        if (originalSize <= maxPdfSize) {
          return originalBytes;
        }
        // Si no, lanzar error con mensaje claro
        throw Exception('El PDF de ${formatBytes(originalSize)} no pudo ser comprimido a menos de 1MB. Por favor, reduzca el tamaño del archivo antes de cargarlo.');
      }
      
    } catch (e) {
      print('[DocumentCompression] Error al procesar PDF: $e');
      rethrow; // Re-lanzar la excepción para que el usuario vea el mensaje
    }
  }
  
  /// Comprimir cualquier documento
  static Future<Uint8List?> compressDocument(File file) async {
    try {
      final extension = path.extension(file.path).toLowerCase();
      
      switch (extension) {
        case '.pdf':
          return await compressPdf(file);
        case '.jpg':
        case '.jpeg':
        case '.png':
          return await _compressImage(file);
        default:
          // Solo se permiten PDFs e imágenes
          throw Exception('Tipo de archivo no permitido. Solo se aceptan archivos PDF, JPG y PNG.');
      }
    } catch (e) {
      print('[DocumentCompression] Error al comprimir documento: $e');
      rethrow; // Re-lanzar la excepción para que el usuario vea el mensaje
    }
  }
  
  /// Comprimir una imagen
  static Future<Uint8List?> _compressImage(File file) async {
    try {
      // Primera compresión con calidad media
      var result = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        minWidth: 800,
        minHeight: 600,
        quality: imageQuality,
        rotate: 0,
      );
      
      // Si aún es muy grande, reducir más agresivamente
      if (result != null && result.length > maxImageSize) {
        result = await FlutterImageCompress.compressWithFile(
          file.absolute.path,
          minWidth: 600,
          minHeight: 450,
          quality: 40,
          rotate: 0,
        );
      }
      
      // Si todavía es muy grande, última reducción
      if (result != null && result.length > maxImageSize) {
        result = await FlutterImageCompress.compressWithFile(
          file.absolute.path,
          minWidth: 400,
          minHeight: 300,
          quality: 30,
          rotate: 0,
        );
      }
      
      if (result != null) {
        final originalSize = await file.length();
        print('[DocumentCompression] Imagen comprimida de ${formatBytes(originalSize)} a ${formatBytes(result.length)}');
        
        // Si después de todo sigue siendo muy grande, avisar
        if (result.length > maxImageSize) {
          print('[DocumentCompression] Advertencia: No se pudo comprimir la imagen por debajo de 50KB. Tamaño final: ${formatBytes(result.length)}');
        }
      }
      
      return result;
    } catch (e) {
      print('[DocumentCompression] Error al comprimir imagen: $e');
      return null;
    }
  }
  
  /// Crear un PDF optimizado a partir de imágenes
  static Future<Uint8List?> createOptimizedPdfFromImages(List<File> imageFiles) async {
    try {
      final pdf = pw.Document();
      
      for (final imageFile in imageFiles) {
        // Comprimir la imagen primero
        final compressedImage = await _compressImage(imageFile);
        if (compressedImage == null) continue;
        
        // Convertir a imagen para PDF
        final image = pw.MemoryImage(compressedImage);
        
        // Agregar página con la imagen
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(
                  image,
                  fit: pw.BoxFit.contain,
                ),
              );
            },
          ),
        );
      }
      
      // Guardar el PDF
      final pdfBytes = await pdf.save();
      print('[DocumentCompression] PDF creado con ${imageFiles.length} imágenes, tamaño: ${formatBytes(pdfBytes.length)}');
      
      return Uint8List.fromList(pdfBytes);
    } catch (e) {
      print('[DocumentCompression] Error al crear PDF: $e');
      return null;
    }
  }
  
  /// Optimizar un documento para subida
  /// Retorna información sobre el proceso de optimización
  static Future<Map<String, dynamic>> optimizeDocumentForUpload(File file) async {
    try {
      final originalSize = await file.length();
      final extension = path.extension(file.path).toLowerCase();
      
      print('[DocumentCompression] Optimizando ${extension} de ${formatBytes(originalSize)}');
      
      final compressedData = await compressDocument(file);
      
      if (compressedData == null) {
        return {
          'success': false,
          'error': 'No se pudo procesar el documento',
        };
      }
      
      final compressedSize = compressedData.length;
      final compressionRatio = originalSize > 0 
        ? ((originalSize - compressedSize) / originalSize * 100).toStringAsFixed(1)
        : '0';
      
      return {
        'success': true,
        'data': compressedData,
        'originalSize': originalSize,
        'compressedSize': compressedSize,
        'compressionRatio': compressionRatio,
        'message': compressionRatio != '0' 
          ? 'Documento optimizado: $compressionRatio% de reducción'
          : 'Documento procesado sin cambios',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Formatear bytes a formato legible
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
  
  /// Obtener información sobre un archivo
  static Future<Map<String, dynamic>> getFileInfo(File file) async {
    try {
      final size = await file.length();
      final extension = path.extension(file.path);
      final name = path.basename(file.path);
      
      return {
        'name': name,
        'extension': extension,
        'size': size,
        'sizeFormatted': formatBytes(size),
        'needsCompression': (extension == '.pdf' && size > maxPdfSize) || 
                           (['.jpg', '.jpeg', '.png'].contains(extension) && size > maxImageSize),
      };
    } catch (e) {
      print('[DocumentCompression] Error al obtener info del archivo: $e');
      return {};
    }
  }
}