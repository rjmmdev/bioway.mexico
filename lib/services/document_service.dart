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

  // Comprimir imagen con compresión optimizada
  Future<Uint8List?> _compressImage(PlatformFile file) async {
    if (file.bytes == null) return null;
    
    try {
      Uint8List result = file.bytes!;
      final originalSizeKB = file.bytes!.length / 1024;
      
      // Si ya es menor a 150KB, no comprimir
      if (originalSizeKB <= 150) {
        print('Imagen ya es pequeña: ${originalSizeKB.toStringAsFixed(1)}KB');
        return file.bytes;
      }
      
      int attempts = 0;
      const int maxAttempts = 3; // Reducir intentos
      const int targetSizeKB = 100;
      
      // Parámetros iniciales más agresivos para archivos grandes
      int quality = originalSizeKB > 1000 ? 50 : 70;
      int minWidth = originalSizeKB > 1000 ? 800 : 1024;
      int minHeight = originalSizeKB > 1000 ? 800 : 1024;
      
      // Intentar comprimir hasta alcanzar el tamaño objetivo
      while (attempts < maxAttempts) {
        result = await FlutterImageCompress.compressWithList(
          attempts == 0 ? file.bytes! : result, // Usar resultado anterior
          minHeight: minHeight,
          minWidth: minWidth,
          quality: quality,
          format: CompressFormat.jpeg,
          autoCorrectionAngle: true,
          keepExif: false,
          rotate: 0, // Evitar rotación automática
        );
        
        final sizeInKB = result.length / 1024;
        
        print('Intento ${attempts + 1}: ${sizeInKB.toStringAsFixed(1)}KB (quality: $quality, dimensions: ${minWidth}x${minHeight})');
        
        // Si el tamaño es aceptable, terminar
        if (sizeInKB <= targetSizeKB) {
          break;
        }
        
        // Ajustar parámetros más agresivamente
        if (sizeInKB > targetSizeKB * 3) {
          // Muy grande, reducir drásticamente
          quality = 30;
          minWidth = 600;
          minHeight = 600;
        } else if (sizeInKB > targetSizeKB * 2) {
          // Doble del objetivo
          quality = (quality * 0.5).round();
          minWidth = (minWidth * 0.6).round();
          minHeight = (minHeight * 0.6).round();
        } else {
          // Cerca del objetivo
          quality = (quality * 0.7).round();
          minWidth = (minWidth * 0.8).round();
          minHeight = (minHeight * 0.8).round();
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
      // Obtener bytes del documento
      Uint8List? bytesToUpload;
      
      // Si es PDF o documento Word, no comprimir (solo validar tamaño)
      final extension = file.extension?.toLowerCase();
      if (extension == 'pdf' || extension == 'doc' || extension == 'docx') {
        if (!validateFileSize(file, maxSizeMB: 5)) {
          throw Exception('El archivo excede el tamaño máximo de 5MB');
        }
        bytesToUpload = file.bytes;
      } else {
        // Solo comprimir imágenes
        bytesToUpload = await compressDocument(file);
      }
      
      if (bytesToUpload == null) {
        throw Exception('No se pudo procesar el documento');
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
          'compressed': extension != 'pdf' && extension != 'doc' && extension != 'docx' ? 'true' : 'false',
          'originalSize': '${file.bytes?.length ?? 0}',
          'compressedSize': '${bytesToUpload.length}',
        },
      );
      
      // Subir archivo
      final uploadTask = ref.putData(bytesToUpload, metadata);
      
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
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
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