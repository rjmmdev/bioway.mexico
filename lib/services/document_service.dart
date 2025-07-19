import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../services/firebase/firebase_manager.dart';

class DocumentService {
  final FirebaseManager _firebaseManager = FirebaseManager();
  
  FirebaseStorage get _storage {
    final app = _firebaseManager.currentApp;
    if (app == null) throw Exception('Firebase no inicializado');
    return FirebaseStorage.instanceFor(app: app);
  }

  // Seleccionar documento (PDF o imagen)
  Future<PlatformFile?> pickDocument({
    required String documentType,
    List<String>? allowedExtensions,
  }) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions ?? ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        return result.files.single;
      }
      return null;
    } catch (e) {
      // Log error - En producción usar un servicio de logging
      return null;
    }
  }

  // Comprimir PDF o imagen
  Future<Uint8List?> compressDocument(PlatformFile file) async {
    try {
      final extension = file.extension?.toLowerCase();
      
      if (extension == 'pdf') {
        // Para PDFs, intentamos reducir el tamaño
        return await _compressPDF(file);
      } else if (['jpg', 'jpeg', 'png'].contains(extension)) {
        // Para imágenes, usamos flutter_image_compress
        return await _compressImage(file);
      }
      
      // Si no es PDF ni imagen, devolver sin comprimir
      return file.bytes;
    } catch (e) {
      // Log error - En producción usar un servicio de logging
      return file.bytes;
    }
  }

  // Comprimir PDF
  Future<Uint8List?> _compressPDF(PlatformFile file) async {
    if (file.bytes == null) return null;
    
    try {
      // Verificar tamaño del PDF
      final sizeInMB = file.bytes!.length / (1024 * 1024);
      print('Tamaño original del PDF: ${sizeInMB.toStringAsFixed(2)} MB');
      
      // Si el PDF es menor a 1MB, no comprimir
      if (sizeInMB < 1.0) {
        return file.bytes;
      }
      
      // NOTA: La compresión de PDF es compleja y generalmente requiere:
      // 1. Librerías especializadas como pdf_compressor (no disponible en Flutter)
      // 2. Procesamiento del lado del servidor
      // 3. Reducción de calidad de imágenes dentro del PDF
      // 4. Eliminación de metadatos
      
      // Por ahora, solo validamos el tamaño y rechazamos PDFs muy grandes
      const maxSizeMB = 5.0;
      if (sizeInMB > maxSizeMB) {
        throw Exception('El PDF excede el tamaño máximo permitido de ${maxSizeMB}MB');
      }
      
      return file.bytes;
    } catch (e) {
      print('Error al procesar PDF: $e');
      rethrow;
    }
  }

  // Comprimir imagen con compresión máxima
  Future<Uint8List?> _compressImage(PlatformFile file) async {
    if (file.bytes == null) return null;
    
    try {
      Uint8List result = file.bytes!;
      int attempts = 0;
      const int maxAttempts = 5;
      const int targetSizeKB = 100; // Objetivo: 100KB máximo
      
      // Parámetros iniciales
      int quality = 70;
      int minWidth = 1024;
      int minHeight = 1024;
      
      // Intentar comprimir hasta alcanzar el tamaño objetivo
      while (attempts < maxAttempts) {
        result = await FlutterImageCompress.compressWithList(
          file.bytes!,
          minHeight: minHeight,
          minWidth: minWidth,
          quality: quality,
          format: CompressFormat.jpeg,
          autoCorrectionAngle: true,
          keepExif: false, // Eliminar metadatos para reducir tamaño
        );
        
        final sizeInKB = result.length / 1024;
        
        print('Intento ${attempts + 1}: ${sizeInKB.toStringAsFixed(1)}KB (quality: $quality, dimensions: ${minWidth}x${minHeight})');
        
        // Si el tamaño es aceptable, terminar
        if (sizeInKB <= targetSizeKB) {
          break;
        }
        
        // Ajustar parámetros para el siguiente intento
        if (sizeInKB > targetSizeKB * 2) {
          // Si es más del doble, reducir agresivamente
          quality = (quality * 0.6).round();
          minWidth = (minWidth * 0.7).round();
          minHeight = (minHeight * 0.7).round();
        } else {
          // Si está cerca, reducir gradualmente
          quality = (quality * 0.8).round();
          minWidth = (minWidth * 0.85).round();
          minHeight = (minHeight * 0.85).round();
        }
        
        // Límites mínimos
        if (quality < 20) quality = 20;
        if (minWidth < 400) minWidth = 400;
        if (minHeight < 400) minHeight = 400;
        
        attempts++;
      }
      
      // Verificar reducción de tamaño
      final originalSize = file.bytes!.length / 1024; // KB
      final compressedSize = result.length / 1024; // KB
      final reduction = ((originalSize - compressedSize) / originalSize * 100);
      
      print('Compresión final: ${originalSize.toStringAsFixed(1)}KB -> ${compressedSize.toStringAsFixed(1)}KB (${reduction.toStringAsFixed(1)}% reducción)');
      
      return result;
    } catch (e) {
      print('Error al comprimir imagen: $e');
      return file.bytes;
    }
  }

  // Subir documento a Firebase Storage
  Future<String?> uploadDocument({
    required String userId,
    required String documentType,
    required PlatformFile file,
    String? solicitudId,
  }) async {
    try {
      // Comprimir el documento
      final compressedBytes = await compressDocument(file);
      if (compressedBytes == null) {
        throw Exception('No se pudo comprimir el documento');
      }

      // Generar nombre único para el archivo
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${documentType}_$timestamp.${file.extension}';
      
      // Determinar la ruta en Storage
      final storagePath = solicitudId != null
          ? 'solicitudes/$solicitudId/documentos/$fileName'
          : 'usuarios/$userId/documentos/$fileName';
      
      // Crear referencia en Storage
      final ref = _storage.ref().child(storagePath);
      
      // Configurar metadata
      final metadata = SettableMetadata(
        contentType: _getContentType(file.extension ?? ''),
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'originalName': file.name,
          'documentType': documentType,
          'compressed': 'true',
          'originalSize': '${file.bytes?.length ?? 0}',
          'compressedSize': '${compressedBytes.length}',
        },
      );
      
      // Subir archivo
      final uploadTask = ref.putData(compressedBytes, metadata);
      
      // Monitorear progreso (opcional)
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        // final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        // Log progress - En producción usar callbacks o streams
      });
      
      // Esperar a que termine la carga
      final snapshot = await uploadTask;
      
      // Obtener URL de descarga
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Log success - En producción usar un servicio de logging
      return downloadUrl;
      
    } catch (e) {
      // Log error - En producción usar un servicio de logging
      return null;
    }
  }

  // Eliminar documento de Storage
  Future<bool> deleteDocument(String documentUrl) async {
    try {
      // Obtener referencia desde la URL
      final ref = _storage.refFromURL(documentUrl);
      await ref.delete();
      return true;
    } catch (e) {
      // Log error - En producción usar un servicio de logging
      return false;
    }
  }

  // Obtener tipo de contenido según extensión
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  // Validar tamaño del archivo
  bool validateFileSize(PlatformFile file, {int maxSizeMB = 10}) {
    if (file.bytes == null) return false;
    
    final sizeInMB = file.bytes!.length / (1024 * 1024);
    return sizeInMB <= maxSizeMB;
  }

  // Obtener nombre formateado del tipo de documento
  String getDocumentTypeName(String documentType) {
    switch (documentType) {
      case 'const_sit_fis':
        return 'Constancia de Situación Fiscal';
      case 'comp_domicilio':
        return 'Comprobante de Domicilio';
      case 'banco_caratula':
        return 'Carátula de Banco';
      case 'ine':
        return 'INE';
      default:
        return documentType;
    }
  }
  
  // Subir múltiples documentos para una solicitud
  Future<Map<String, String?>> uploadSolicitudDocuments({
    required String solicitudId,
    required Map<String, PlatformFile?> documents,
    Function(String documentType, double progress)? onProgress,
  }) async {
    final Map<String, String?> uploadedUrls = {};
    
    for (final entry in documents.entries) {
      final documentType = entry.key;
      final file = entry.value;
      
      if (file != null) {
        try {
          print('Subiendo documento: $documentType');
          
          // Notificar progreso inicial
          onProgress?.call(documentType, 0.0);
          
          final url = await uploadDocument(
            userId: 'temp_$solicitudId',
            documentType: documentType,
            file: file,
            solicitudId: solicitudId,
          );
          
          uploadedUrls[documentType] = url;
          
          // Notificar completado
          onProgress?.call(documentType, 1.0);
          
          if (url != null) {
            print('✓ Documento $documentType subido exitosamente');
          } else {
            print('✗ Error al subir documento $documentType');
          }
        } catch (e) {
          print('Error al subir $documentType: $e');
          uploadedUrls[documentType] = null;
          onProgress?.call(documentType, -1.0); // -1 indica error
        }
      }
    }
    
    return uploadedUrls;
  }
  
  // Eliminar todos los documentos de una solicitud
  Future<void> deleteSolicitudDocuments(Map<String, dynamic> solicitudData) async {
    final datosPerfil = solicitudData['datos_perfil'] as Map<String, dynamic>?;
    if (datosPerfil == null) return;
    
    final documentFields = [
      'ecoce_const_sit_fis',
      'ecoce_comp_domicilio',
      'ecoce_banco_caratula',
      'ecoce_ine',
    ];
    
    for (final field in documentFields) {
      final url = datosPerfil[field];
      if (url != null && url is String && url.isNotEmpty) {
        try {
          await deleteDocument(url);
          print('✓ Documento $field eliminado');
        } catch (e) {
          print('✗ Error al eliminar $field: $e');
        }
      }
    }
  }
  
  // Obtener información de un documento desde su URL
  Future<Map<String, dynamic>?> getDocumentInfo(String documentUrl) async {
    try {
      final ref = _storage.refFromURL(documentUrl);
      final metadata = await ref.getMetadata();
      
      return {
        'name': metadata.name,
        'size': metadata.size,
        'contentType': metadata.contentType,
        'createdAt': metadata.timeCreated,
        'updatedAt': metadata.updated,
        'customMetadata': metadata.customMetadata,
      };
    } catch (e) {
      print('Error al obtener información del documento: $e');
      return null;
    }
  }
}