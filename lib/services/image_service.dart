import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
}