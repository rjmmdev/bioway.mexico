import 'package:flutter/material.dart';
import 'dart:io';

class ImagePreviewDialog extends StatelessWidget {
  final File imageFile;
  final VoidCallback? onDelete;

  const ImagePreviewDialog({
    super.key,
    required this.imageFile,
    this.onDelete,
  });

  static void show({
    required BuildContext context,
    required File imageFile,
    VoidCallback? onDelete,
  }) {
    showDialog(
      context: context,
      builder: (context) => ImagePreviewDialog(
        imageFile: imageFile,
        onDelete: onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Imagen
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                imageFile,
                fit: BoxFit.contain,
              ),
            ),
          ),
          
          // Botón de cerrar
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          
          // Botón de eliminar (opcional)
          if (onDelete != null)
            Positioned(
              bottom: 20,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  onDelete!();
                },
                icon: const Icon(Icons.delete),
                label: const Text('Eliminar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}