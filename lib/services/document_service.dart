import 'dart:typed_data';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import '../services/firebase/firebase_manager.dart';

class DocumentService {
  final FirebaseManager _firebaseManager = FirebaseManager();
  
  FirebaseStorage? get _storage {
    try {
      final app = _firebaseManager.currentApp;
      if (app == null) {
        print('❌ ERROR: Firebase no está inicializado en DocumentService');
        print('  Current platform: ${_firebaseManager.currentPlatform}');
        return null;
      }
      return FirebaseStorage.instanceFor(app: app);
    } catch (e) {
      print('❌ ERROR al obtener Firebase Storage: $e');
      return null;
    }
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
  
  // Validar tamaño del archivo
  bool validateFileSize(PlatformFile file, {double maxSizeMB = 5.0}) {
    if (file.size == 0) return false;
    final sizeInMB = file.size / (1024 * 1024);
    return sizeInMB <= maxSizeMB;
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
      
      // Si el PDF es menor a 5MB, no comprimir (temporal hasta implementar compresión real)
      if (sizeInMB < 5.0) {
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

  // Subir documento a Firebase Storage - Versión simplificada y robusta
  Future<String?> uploadDocument({
    required String userId,
    required String documentType,
    required PlatformFile file,
    String? solicitudId,
  }) async {
    try {
      print('\n========================================');
      print('📤 INICIANDO SUBIDA DE DOCUMENTO');
      print('  Tipo: $documentType');
      print('  Archivo: ${file.name}');
      print('  Tamaño: ${file.size} bytes');
      print('  Extensión: ${file.extension}');
      print('  UserId: $userId');
      print('  SolicitudId: $solicitudId');
      print('========================================\n');
      
      // 1. Verificar que tengamos los bytes del archivo
      if (file.bytes == null || file.bytes!.isEmpty) {
        throw Exception('El archivo no tiene contenido');
      }
      
      // 2. Obtener los bytes a subir (con o sin compresión)
      Uint8List bytesToUpload;
      final extension = file.extension?.toLowerCase() ?? '';
      
      if (extension == 'pdf' || extension == 'doc' || extension == 'docx') {
        // Para documentos, solo validar tamaño
        if (file.size > 5 * 1024 * 1024) { // 5MB
          throw Exception('El archivo excede el tamaño máximo de 5MB');
        }
        bytesToUpload = file.bytes!;
        print('📄 Documento sin comprimir: ${bytesToUpload.length} bytes');
      } else {
        // Para imágenes, intentar comprimir
        try {
          final compressed = await _compressImage(file);
          bytesToUpload = compressed ?? file.bytes!;
          print('🖼️ Imagen comprimida: ${file.bytes!.length} -> ${bytesToUpload.length} bytes');
        } catch (e) {
          print('⚠️ No se pudo comprimir, usando original: $e');
          bytesToUpload = file.bytes!;
        }
      }
      
      // 3. Generar un nombre único para el archivo
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeFileName = '${documentType}_${timestamp}_${userId.substring(0, 8)}.${extension}';
      
      // 4. Crear la ruta en Storage
      final storagePath = 'ecoce/documentos/$userId/$documentType/$safeFileName';
      print('📂 Ruta de almacenamiento: $storagePath');
      
      // 5. Obtener referencia de Storage (con verificación)
      FirebaseStorage? storage = _storage;
      if (storage == null) {
        print('❌ Firebase Storage no disponible. Intentando inicializar...');
        // Intentar inicializar Firebase para ECOCE
        await _firebaseManager.initializeForPlatform(FirebasePlatform.ecoce);
        storage = _storage;
        
        if (storage == null) {
          throw Exception('No se pudo inicializar Firebase Storage. Verifique la configuración.');
        }
      }
      
      // 6. Crear referencia al archivo
      final Reference ref = storage.ref().child(storagePath);
      
      // 7. Configurar metadata
      final metadata = SettableMetadata(
        contentType: _getContentType(extension),
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'originalName': file.name,
          'documentType': documentType,
          'userId': userId,
          'solicitudId': solicitudId ?? '',
          'platform': 'ecoce',
        },
      );
      
      // 8. Subir el archivo
      print('⬆️ Iniciando carga a Firebase Storage...');
      final UploadTask uploadTask = ref.putData(bytesToUpload, metadata);
      
      // 9. Esperar a que termine
      final TaskSnapshot snapshot = await uploadTask;
      print('✅ Carga completada. Estado: ${snapshot.state}');
      
      // 10. Obtener la URL de descarga
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('\n✅ DOCUMENTO SUBIDO EXITOSAMENTE');
      print('  URL: $downloadUrl');
      print('========================================\n');
      
      return downloadUrl;
      
    } catch (e, stack) {
      print('\n❌ ERROR AL SUBIR DOCUMENTO');
      print('  Error: $e');
      print('  Stack: $stack');
      print('========================================\n');
      return null; // Retornar null en caso de error para no bloquear el proceso
    }
  }

  // Eliminar documento de Storage
  Future<bool> deleteDocument(String documentUrl) async {
    try {
      final storage = _storage;
      if (storage == null) {
        print('❌ Firebase Storage no disponible para eliminar documento');
        return false;
      }
      
      // Obtener referencia desde la URL
      final ref = storage.refFromURL(documentUrl);
      await ref.delete();
      return true;
    } catch (e) {
      print('Error al eliminar documento: $e');
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
      case 'opinion_cumplimiento':
        return 'Opinión de Cumplimiento';
      case 'ramir':
        return 'RAMIR';
      case 'plan_manejo':
        return 'Plan de Manejo';
      case 'licencia_ambiental':
        return 'Licencia Ambiental';
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
      'ecoce_opinion_cumplimiento',
      'ecoce_ramir',
      'ecoce_plan_manejo',
      'ecoce_licencia_ambiental',
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
      final storage = _storage;
      if (storage == null) {
        print('❌ Firebase Storage no disponible');
        return null;
      }
      
      final ref = storage.refFromURL(documentUrl);
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
  
  // Copiar documentos de una solicitud temporal a la ubicación final del usuario
  Future<Map<String, String?>> copyDocumentsToUserProfile({
    required String temporaryId,
    required String finalUserId,
    required Map<String, dynamic> documentUrls,
  }) async {
    print('\n📂 COPIANDO DOCUMENTOS AL PERFIL FINAL DEL USUARIO');
    print('  Desde: $temporaryId');
    print('  Hacia: $finalUserId');
    
    final storage = _storage;
    if (storage == null) {
      print('❌ Firebase Storage no disponible para copiar documentos');
      // Retornar las URLs originales sin copiar
      return Map<String, String?>.from(documentUrls);
    }
    
    final Map<String, String?> newUrls = {};
    
    for (final entry in documentUrls.entries) {
      if (entry.value != null && entry.value is String && entry.value.isNotEmpty) {
        try {
          print('\n  Copiando ${entry.key}...');
          
          // 1. Obtener referencia del documento original
          final originalRef = storage.refFromURL(entry.value);
          
          // 2. Descargar los bytes del documento original
          final bytes = await originalRef.getData();
          if (bytes == null) {
            print('  ⚠️ No se pudieron obtener los bytes del documento');
            continue;
          }
          
          // 3. Obtener metadata original
          final originalMetadata = await originalRef.getMetadata();
          
          // 4. Crear nueva ruta para el usuario final
          final extension = originalRef.name.split('.').last;
          final newFileName = '${entry.key}_${DateTime.now().millisecondsSinceEpoch}.$extension';
          final newPath = 'ecoce/usuarios/$finalUserId/documentos/$newFileName';
          
          // 5. Subir el documento a la nueva ubicación
          final newRef = storage.ref().child(newPath);
          final newMetadata = SettableMetadata(
            contentType: originalMetadata.contentType,
            customMetadata: {
              ...originalMetadata.customMetadata ?? {},
              'copiedAt': DateTime.now().toIso8601String(),
              'originalPath': originalRef.fullPath,
              'userId': finalUserId,
            },
          );
          
          final uploadTask = newRef.putData(bytes, newMetadata);
          final snapshot = await uploadTask;
          
          // 6. Obtener la nueva URL
          final newUrl = await snapshot.ref.getDownloadURL();
          newUrls[entry.key] = newUrl;
          
          print('  ✅ Copiado exitosamente');
          print('     Nueva URL: $newUrl');
          
        } catch (e) {
          print('  ❌ Error al copiar ${entry.key}: $e');
          // Mantener la URL original si no se puede copiar
          newUrls[entry.key] = entry.value;
        }
      }
    }
    
    print('\n✅ Proceso de copia completado');
    print('  Documentos copiados: ${newUrls.length}');
    
    return newUrls;
  }
  
  // Obtener directorio temporal
  Future<Directory> getTempDirectory() async {
    return await getTemporaryDirectory();
  }
}