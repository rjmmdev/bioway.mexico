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

  // Subir archivo (PDF, DOC, etc)
  Future<String?> uploadFile(File file, String folder) async {
    try {
      // Validar tamaño del archivo (máximo 5MB)
      final fileSize = await file.length();
      if (fileSize > 5 * 1024 * 1024) {
        throw Exception('El archivo es demasiado grande. Máximo 5MB.');
      }

      // Generar nombre único
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final ref = _storage.ref().child('$folder/$fileName');

      // Subir archivo
      final uploadTask = await ref.putFile(file);
      
      // Obtener URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error al subir archivo: $e');
      return null;
    }
  }

  // Comprimir imagen a ~50KB
  Future<List<int>?> _compressImage(File file) async {
    try {
      final result = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        minWidth: 800,
        minHeight: 600,
        quality: 70,
        rotate: 0,
      );
      
      // Si aún es muy grande, reducir calidad
      if (result != null && result.length > 60000) {
        return await FlutterImageCompress.compressWithFile(
          file.absolute.path,
          minWidth: 600,
          minHeight: 450,
          quality: 50,
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
}