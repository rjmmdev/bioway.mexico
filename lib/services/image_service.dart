import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageService {
  static final ImagePicker _picker = ImagePicker();

  /// Toma una foto usando la cámara del dispositivo
  static Future<File?> takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 80, // Comprimir al 80% para optimizar el tamaño
      );
      
      if (photo != null) {
        return File(photo.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error al tomar foto: $e');
      return null;
    }
  }

  /// Selecciona una imagen de la galería
  static Future<File?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Comprimir al 80% para optimizar el tamaño
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error al seleccionar imagen: $e');
      return null;
    }
  }

  /// Muestra un diálogo de opciones para seleccionar la fuente de la imagen
  static Future<File?> showImageSourceDialog(BuildContext context) async {
    File? selectedImage;
    
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Seleccionar imagen',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tomar foto'),
                onTap: () async {
                  Navigator.pop(context);
                  selectedImage = await takePhoto();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Seleccionar de galería'),
                onTap: () async {
                  Navigator.pop(context);
                  selectedImage = await pickFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );
    
    return selectedImage;
  }

  /// Verifica si un archivo de imagen existe
  static bool imageExists(File? image) {
    return image != null && image.existsSync();
  }

  /// Obtiene el tamaño de la imagen en MB
  static double getImageSizeInMB(File image) {
    int sizeInBytes = image.lengthSync();
    double sizeInMB = sizeInBytes / (1024 * 1024);
    return double.parse(sizeInMB.toStringAsFixed(2));
  }

  /// Comprime y optimiza una imagen para su almacenamiento en base de datos
  /// Garantiza que la imagen no exceda 50KB
  static Future<File?> optimizeImageForDatabase(
    File imageFile, {
    int maxWidth = 800,
    int quality = 60,
    CompressFormat format = CompressFormat.jpeg,
    int maxSizeKB = 50, // Máximo 50KB
  }) async {
    try {
      // Verificar tamaño original
      final int originalSizeBytes = await imageFile.length();
      final double originalSizeKB = originalSizeBytes / 1024;
      
      // Si ya es menor al objetivo + 50%, no comprimir
      if (originalSizeKB <= maxSizeKB * 1.5) {
        debugPrint('✓ Imagen ya está optimizada: ${originalSizeKB.toStringAsFixed(1)}KB');
        return imageFile;
      }
      
      // Obtener directorio temporal
      final Directory tempDir = await getTemporaryDirectory();
      String targetPath;
      File? compressedFile;
      
      // Variables para el algoritmo iterativo optimizado
      int currentQuality = quality;
      int currentWidth = maxWidth;
      int attempts = 0;
      const int maxAttempts = 3; // Reducido de 5 a 3
      
      // Si es muy grande, empezar con parámetros más agresivos
      if (originalSizeKB > 1000) { // > 1MB
        currentQuality = 40;
        currentWidth = 600;
      }
      
      // Intentar comprimir hasta alcanzar el tamaño objetivo
      while (attempts < maxAttempts) {
        targetPath = path.join(
          tempDir.path,
          'optimized_${DateTime.now().millisecondsSinceEpoch}_$attempts.jpg',
        );
        
        // Comprimir la imagen
        final XFile? result = await FlutterImageCompress.compressAndGetFile(
          compressedFile?.absolute.path ?? imageFile.absolute.path, // Usar resultado anterior si existe
          targetPath,
          minWidth: currentWidth,
          minHeight: (currentWidth * 0.75).round(), // Mantener proporción 4:3
          quality: currentQuality,
          format: CompressFormat.jpeg, // JPEG es más eficiente para fotos
          autoCorrectionAngle: true,
          keepExif: false,
        );
        
        if (result == null) break;
        
        // Limpiar archivo anterior si existe
        if (compressedFile != null && compressedFile.existsSync()) {
          await compressedFile.delete();
        }
        
        compressedFile = File(result.path);
        final int sizeInBytes = await compressedFile.length();
        final double sizeInKB = sizeInBytes / 1024;
        
        debugPrint('Intento ${attempts + 1}: ${sizeInKB.toStringAsFixed(1)}KB (quality: $currentQuality, width: $currentWidth)');
        
        // Si el tamaño es aceptable, terminar
        if (sizeInKB <= maxSizeKB) {
          final double originalSize = getImageSizeInMB(imageFile);
          
          debugPrint('✓ Imagen optimizada: ${originalSize.toStringAsFixed(1)}MB -> ${sizeInKB.toStringAsFixed(1)}KB');
          return compressedFile;
        }
        
        // Ajustar parámetros más agresivamente
        if (sizeInKB > maxSizeKB * 3) {
          // Si es más del triple, reducir muy agresivamente
          currentWidth = (currentWidth * 0.5).round();
          currentQuality = (currentQuality * 0.5).round();
        } else if (sizeInKB > maxSizeKB * 1.5) {
          // Si es más de 1.5x, reducir moderadamente
          currentWidth = (currentWidth * 0.7).round();
          currentQuality = (currentQuality * 0.7).round();
        } else {
          // Si está cerca, reducir gradualmente
          currentWidth = (currentWidth * 0.85).round();
          currentQuality = (currentQuality * 0.9).round();
        }
        
        // Límites mínimos
        if (currentWidth < 400) currentWidth = 400;
        if (currentQuality < 20) currentQuality = 20;
        
        attempts++;
      }
      
      // Si no se logró el tamaño objetivo, usar la última compresión
      if (compressedFile != null && compressedFile.existsSync()) {
        final double sizeInKB = await compressedFile.length() / 1024;
        debugPrint('⚠️ No se alcanzó el objetivo de ${maxSizeKB}KB, tamaño final: ${sizeInKB.toStringAsFixed(1)}KB');
        return compressedFile;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error al optimizar imagen: $e');
      return null;
    }
  }

  /// Comprime múltiples imágenes en lote
  static Future<List<File>> optimizeMultipleImages(
    List<File> images, {
    int maxWidth = 800,
    int quality = 60,
    int maxSizeKB = 50,
    Function(int current, int total)? onProgress,
  }) async {
    List<File> optimizedImages = [];
    
    for (int i = 0; i < images.length; i++) {
      onProgress?.call(i + 1, images.length);
      
      final File? optimized = await optimizeImageForDatabase(
        images[i],
        maxWidth: maxWidth,
        quality: quality,
        maxSizeKB: maxSizeKB,
      );
      
      if (optimized != null) {
        optimizedImages.add(optimized);
      } else {
        // Si falla la optimización, usar la imagen original
        optimizedImages.add(images[i]);
      }
    }
    
    return optimizedImages;
  }

  /// Calcula el tamaño total de una lista de imágenes
  static double getTotalSizeInMB(List<File> images) {
    double totalSize = 0;
    for (File image in images) {
      totalSize += getImageSizeInMB(image);
    }
    return double.parse(totalSize.toStringAsFixed(2));
  }

  /// Limpia las imágenes temporales optimizadas
  static Future<void> cleanupTempImages() async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final List<FileSystemEntity> files = tempDir.listSync();
      
      for (FileSystemEntity file in files) {
        if (file is File && file.path.contains('optimized_')) {
          await file.delete();
        }
      }
    } catch (e) {
      debugPrint('Error al limpiar imágenes temporales: $e');
    }
  }
}