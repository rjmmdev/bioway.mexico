import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Subir imagen comprimida
  Future<String?> uploadImage(File imageFile, String folder) async {
    try {
      // Comprimir imagen
      final compressedImage = await _compressImage(imageFile);
      if (compressedImage == null) return null;

      // Generar nombre único
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final ref = _storage.ref().child('$folder/$fileName');

      // Subir archivo
      final uploadTask = await ref.putData(Uint8List.fromList(compressedImage));
      
      // Obtener URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error al subir imagen: $e');
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
}