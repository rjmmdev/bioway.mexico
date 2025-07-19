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

  // Comprimir PDF (implementación básica)
  Future<Uint8List?> _compressPDF(PlatformFile file) async {
    // Por ahora retornamos el PDF sin comprimir
    // En producción, podrías usar una librería como pdf_compressor
    // o implementar compresión del lado del servidor
    
    // Verificar tamaño del PDF
    if (file.bytes != null) {
      final sizeInMB = file.bytes!.length / (1024 * 1024);
      // Log PDF size - En producción usar un servicio de logging
      // Tamaño del PDF: ${sizeInMB.toStringAsFixed(2)} MB
    }
    
    return file.bytes;
  }

  // Comprimir imagen
  Future<Uint8List?> _compressImage(PlatformFile file) async {
    if (file.bytes == null) return null;
    
    try {
      // Comprimir la imagen manteniendo una calidad razonable
      final result = await FlutterImageCompress.compressWithList(
        file.bytes!,
        minHeight: 1920,
        minWidth: 1080,
        quality: 85, // Calidad del 85%
        format: CompressFormat.jpeg,
      );
      
      // Verificar reducción de tamaño
      final originalSize = file.bytes!.length / 1024; // KB
      final compressedSize = result.length / 1024; // KB
      final reduction = ((originalSize - compressedSize) / originalSize * 100).toStringAsFixed(1);
      
      // Log compression stats - En producción usar un servicio de logging
      // Compresión: ${originalSize.toStringAsFixed(1)}KB -> ${compressedSize.toStringAsFixed(1)}KB ($reduction% reducción)
      
      return result;
    } catch (e) {
      // Log error - En producción usar un servicio de logging
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
}