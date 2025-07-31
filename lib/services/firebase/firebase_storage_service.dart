import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import 'package:app/services/firebase/firebase_manager.dart';

class FirebaseStorageService {
  final FirebaseManager _firebaseManager = FirebaseManager();
  
  FirebaseStorage get _storage {
    final app = _firebaseManager.currentApp;
    if (app != null) {
      print('Usando Firebase Storage para app: ${app.name}');
      return FirebaseStorage.instanceFor(app: app);
    }
    print('Usando Firebase Storage por defecto');
    return FirebaseStorage.instance;
  }

  // Subir imagen comprimida
  Future<String?> uploadImage(File imageFile, String folder) async {
    try {
      print('=== INICIO SUBIDA DE IMAGEN ===');
      print('Archivo: ${imageFile.path}');
      print('Carpeta destino: $folder');
      print('Tamaño original: ${await imageFile.length()} bytes');
      
      // Comprimir imagen
      final compressedImage = await _compressImage(imageFile);
      if (compressedImage == null) {
        print('ERROR: No se pudo comprimir la imagen');
        return null;
      }
      
      print('Tamaño comprimido: ${compressedImage.length} bytes');

      // Generar nombre único
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final fullPath = '$folder/$fileName';
      print('Ruta completa en Storage: $fullPath');
      
      final ref = _storage.ref().child(fullPath);

      // Subir archivo
      print('Iniciando subida a Firebase Storage...');
      final uploadTask = await ref.putData(Uint8List.fromList(compressedImage));
      
      // Obtener URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      print('URL obtenida: $downloadUrl');
      print('=== FIN SUBIDA DE IMAGEN ===');
      
      return downloadUrl;
    } catch (e) {
      print('ERROR al subir imagen: $e');
      print('Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  // Subir archivo (PDF, DOC, etc) - Ya comprimido previamente
  Future<String?> uploadFile(File file, String folder) async {
    try {
      print('=== INICIO SUBIDA DE DOCUMENTO ===');
      print('Archivo: ${file.path}');
      print('Carpeta destino: $folder');
      
      // Leer los bytes del archivo (ya está comprimido)
      final fileData = await file.readAsBytes();
      print('Tamaño del archivo: ${_formatBytes(fileData.length)}');
      
      // Validar tamaño final (máximo 1MB)
      if (fileData.length > 1024 * 1024) {
        throw Exception('El archivo es demasiado grande. Máximo 1MB.');
      }

      // Generar nombre único
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final fullPath = '$folder/$fileName';
      print('Ruta completa en Storage: $fullPath');
      
      final ref = _storage.ref().child(fullPath);

      // Subir archivo
      print('Iniciando subida a Firebase Storage...');
      final uploadTask = await ref.putData(fileData);
      
      // Obtener URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      print('URL obtenida: $downloadUrl');
      print('=== FIN SUBIDA DE DOCUMENTO ===');
      
      return downloadUrl;
    } catch (e) {
      print('ERROR al subir archivo: $e');
      print('Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  // Comprimir imagen a ~50KB
  Future<List<int>?> _compressImage(File file) async {
    try {
      // Primera compresión
      var result = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        minWidth: 800,
        minHeight: 600,
        quality: 60,
        rotate: 0,
      );
      
      // Si aún es muy grande, reducir más agresivamente
      if (result != null && result.length > 50000) {
        result = await FlutterImageCompress.compressWithFile(
          file.absolute.path,
          minWidth: 600,
          minHeight: 450,
          quality: 40,
          rotate: 0,
        );
      }
      
      // Si todavía es muy grande, última reducción
      if (result != null && result.length > 50000) {
        result = await FlutterImageCompress.compressWithFile(
          file.absolute.path,
          minWidth: 400,
          minHeight: 300,
          quality: 30,
          rotate: 0,
        );
      }
      
      return result;
    } catch (e) {
      print('Error al comprimir imagen: $e');
      return null;
    }
  }

  // Eliminar archivo
  Future<bool> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
      return true;
    } catch (e) {
      print('Error al eliminar archivo: $e');
      return false;
    }
  }

  // Obtener metadatos del archivo
  Future<FullMetadata?> getFileMetadata(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      return await ref.getMetadata();
    } catch (e) {
      print('Error al obtener metadatos: $e');
      return null;
    }
  }

  // Verificar si la URL es accesible (simplificado)
  Future<bool> isUrlAccessible(String? url) async {
    if (url == null || url.isEmpty) return false;
    
    try {
      // Para URLs de Firebase Storage, verificar si necesitan actualización
      if (url.contains('firebasestorage.googleapis.com')) {
        // Si la URL ya tiene un token, probablemente sea válida
        if (url.contains('token=')) {
          return true;
        }
        
        // Si no tiene token, intentar obtener una URL actualizada
        try {
          final ref = _storage.refFromURL(url);
          await ref.getDownloadURL(); // Solo verificar si podemos obtenerla
          return true;
        } catch (e) {
          print('URL de Firebase Storage no accesible: $e');
          return false;
        }
      }
      
      // Para otras URLs, asumimos que son accesibles
      return url.startsWith('http://') || url.startsWith('https://');
    } catch (e) {
      print('Error verificando accesibilidad de URL: $e');
      return false;
    }
  }

  // Obtener URL de descarga con token válido
  Future<String?> getValidDownloadUrl(String? fileUrl) async {
    if (fileUrl == null || fileUrl.isEmpty) {
      return null;
    }
    
    try {
      // Si es una URL de Firebase Storage, intentar obtener una nueva con token válido
      if (fileUrl.contains('firebasestorage.googleapis.com')) {
        try {
          print('Intentando obtener URL con token válido para: $fileUrl');
          
          // Obtener la referencia desde la URL
          final ref = _storage.refFromURL(fileUrl);
          
          // Generar nueva URL con token actualizado
          final newUrl = await ref.getDownloadURL();
          print('Nueva URL generada exitosamente');
          
          return newUrl;
        } catch (e) {
          print('Error al generar nueva URL: $e');
          
          // Si falla, intentar extraer el path y regenerar
          try {
            final storagePath = _extractStoragePathFromUrl(fileUrl);
            if (storagePath != null) {
              print('Intentando con path extraído: $storagePath');
              final ref = _storage.ref().child(storagePath);
              final newUrl = await ref.getDownloadURL();
              print('URL generada desde path exitosamente');
              return newUrl;
            }
          } catch (e2) {
            print('Error al generar URL desde path: $e2');
          }
        }
      }
      
      // Para URLs normales, devolverlas directamente
      if (fileUrl.startsWith('http://') || fileUrl.startsWith('https://')) {
        return fileUrl;
      }
      
      // Si es un path relativo, intentar construir la URL completa
      if (!fileUrl.startsWith('http')) {
        try {
          final ref = _storage.ref().child(fileUrl);
          return await ref.getDownloadURL();
        } catch (e) {
          print('Error construyendo URL desde path: $e');
        }
      }
      
      return fileUrl;
    } catch (e) {
      print('Error en getValidDownloadUrl: $e');
      return null;
    }
  }
  
  // Extraer el path de storage desde una URL de Firebase
  String? _extractStoragePathFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      
      // Buscar el patrón /o/ que indica el inicio del path
      if (path.contains('/o/')) {
        final startIndex = path.indexOf('/o/') + 3;
        final endIndex = path.indexOf('?', startIndex);
        
        String storagePath;
        if (endIndex > startIndex) {
          storagePath = path.substring(startIndex, endIndex);
        } else {
          storagePath = path.substring(startIndex);
        }
        
        // Decodificar el path (los espacios y caracteres especiales están codificados)
        return Uri.decodeComponent(storagePath);
      }
      
      return null;
    } catch (e) {
      print('Error extrayendo path de URL: $e');
      return null;
    }
  }

  // Subir imagen desde base64
  Future<String?> uploadBase64Image(String base64String, String fileName) async {
    try {
      print('=== INICIO SUBIDA DE IMAGEN BASE64 ===');
      print('Nombre archivo: $fileName');
      
      // Extraer los datos base64 (remover el prefijo data:image/png;base64, si existe)
      String cleanBase64 = base64String;
      if (base64String.contains(',')) {
        cleanBase64 = base64String.split(',')[1];
      }
      
      // Convertir base64 a bytes
      final bytes = base64.decode(cleanBase64);
      print('Tamaño de bytes: ${bytes.length}');
      
      // Generar ruta completa
      final fullPath = 'firmas/$fileName.png';
      print('Ruta completa en Storage: $fullPath');
      
      final ref = _storage.ref().child(fullPath);
      
      // Subir datos
      print('Iniciando subida a Firebase Storage...');
      final uploadTask = await ref.putData(bytes);
      
      // Obtener URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      print('URL obtenida: $downloadUrl');
      print('=== FIN SUBIDA DE IMAGEN BASE64 ===');
      
      return downloadUrl;
    } catch (e) {
      print('ERROR al subir imagen base64: $e');
      print('Stack trace: ${StackTrace.current}');
      return null;
    }
  }
  
  // Método helper para formatear bytes
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}