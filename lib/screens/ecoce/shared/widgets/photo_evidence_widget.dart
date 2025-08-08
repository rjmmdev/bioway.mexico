import 'package:flutter/material.dart';
import 'dart:io';
import '../../../../utils/colors.dart';
import '../../../../services/image_service.dart';
import 'image_preview_dialog.dart';

/// Widget compartido para captura y gestión de múltiples evidencias fotográficas
/// Puede ser utilizado por cualquier usuario del sistema ECOCE
class PhotoEvidenceWidget extends StatefulWidget {
  final String title;
  final int maxPhotos;
  final int minPhotos;
  final bool isRequired;
  final Function(List<File>) onPhotosChanged;
  final Color primaryColor;
  final String addPhotoText;
  final String emptyStateText;
  final String emptyStateSubtext;
  final bool showCounter;
  final bool allowGallery;

  const PhotoEvidenceWidget({
    super.key,
    this.title = 'Evidencia Fotográfica',
    this.maxPhotos = 3,
    this.minPhotos = 1,
    this.isRequired = false,
    required this.onPhotosChanged,
    this.primaryColor = const Color(0xFF4CAF50),
    this.addPhotoText = 'Agregar evidencia',
    this.emptyStateText = 'Sin evidencias',
    this.emptyStateSubtext = 'Toca para agregar fotos',
    this.showCounter = true,
    this.allowGallery = true,
  });

  @override
  State<PhotoEvidenceWidget> createState() => _PhotoEvidenceWidgetState();
}

class _PhotoEvidenceWidgetState extends State<PhotoEvidenceWidget> {
  List<File> _photos = [];
  bool _isOptimizing = false;
  String _optimizationMessage = '';

  bool get _canAddMore => _photos.length < widget.maxPhotos;
  bool get _hasMinimumPhotos => _photos.length >= widget.minPhotos;

  void _showImageOptions() {
    if (!_canAddMore) {
      _showMaxPhotosReachedSnackBar();
      return;
    }

    showModalBottomSheet(
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
              Text(
                'Seleccionar imagen',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: BioWayColors.darkGreen,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.camera_alt, color: widget.primaryColor),
                title: const Text('Tomar foto'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              if (widget.allowGallery)
                ListTile(
                  leading: Icon(Icons.photo_library, color: widget.primaryColor),
                  title: const Text('Seleccionar de galería'),
                  onTap: () {
                    Navigator.pop(context);
                    _selectFromGallery();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _takePhoto() async {
    try {
      final File? photo = await ImageService.takePhoto();
      if (photo != null) {
        await _processAndAddPhoto(photo);
      }
    } catch (e) {
      _showErrorSnackBar('Error al acceder a la cámara');
    }
  }

  void _selectFromGallery() async {
    try {
      final File? image = await ImageService.pickFromGallery();
      if (image != null) {
        await _processAndAddPhoto(image);
      }
    } catch (e) {
      _showErrorSnackBar('Error al acceder a la galería');
    }
  }

  Future<void> _processAndAddPhoto(File photo) async {
    setState(() {
      _isOptimizing = true;
      _optimizationMessage = 'Optimizando imagen...';
    });

    try {
      // Obtener tamaño original
      final double originalSize = ImageService.getImageSizeInMB(photo);
      
      // Optimizar la imagen para 50KB máximo
      final File? optimizedPhoto = await ImageService.optimizeImageForDatabase(
        photo,
        maxWidth: 800, // Reducido para alcanzar 50KB
        quality: 60, // Calidad reducida para menor tamaño
      );
      
      if (optimizedPhoto != null) {
        final double optimizedSize = ImageService.getImageSizeInMB(optimizedPhoto);
        
        setState(() {
          _photos.add(optimizedPhoto);
          _isOptimizing = false;
          _optimizationMessage = '';
        });
        
        widget.onPhotosChanged(_photos);
        
        // Mostrar información de optimización
        final double optimizedSizeKB = optimizedSize * 1024;
        String message;
        if (optimizedSizeKB < 100) {
          message = 'Imagen optimizada: ${originalSize.toStringAsFixed(1)}MB → ${optimizedSizeKB.toStringAsFixed(1)}KB';
        } else {
          message = 'Imagen optimizada: ${originalSize.toStringAsFixed(1)}MB → ${optimizedSize.toStringAsFixed(2)}MB';
        }
        _showSuccessSnackBar(message);
      } else {
        // Si falla la optimización, usar la imagen original
        setState(() {
          _photos.add(photo);
          _isOptimizing = false;
          _optimizationMessage = '';
        });
        
        widget.onPhotosChanged(_photos);
        _showWarningSnackBar('No se pudo optimizar la imagen, usando original');
      }
    } catch (e) {
      setState(() {
        _isOptimizing = false;
        _optimizationMessage = '';
      });
      _showErrorSnackBar('Error al procesar la imagen');
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
    widget.onPhotosChanged(_photos);
  }

  @override
  void dispose() {
    // Limpiar imágenes temporales al salir
    ImageService.cleanupTempImages();
    super.dispose();
  }

  void _viewPhoto(File photo) {
    ImagePreviewDialog.show(
      context: context,
      imageFile: photo,
      onDelete: () {
        setState(() {
          _photos.remove(photo);
        });
        widget.onPhotosChanged(_photos);
      },
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: BioWayColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: BioWayColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: BioWayColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showMaxPhotosReachedSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Máximo ${widget.maxPhotos} fotos permitidas'),
        backgroundColor: BioWayColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  String _getFileSizeString(File file) {
    try {
      final int bytes = file.lengthSync();
      if (bytes < 1024) {
        return '${bytes}B';
      } else if (bytes < 1024 * 1024) {
        return '${(bytes / 1024).toStringAsFixed(1)}KB';
      } else {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título - Only show if title is not empty
        if (widget.title.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    '📷',
                    style: TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: BioWayColors.darkGreen,
                    ),
                  ),
                  if (widget.isRequired) ...[
                    const SizedBox(width: 4),
                    Text(
                      '*',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: BioWayColors.error,
                      ),
                    ),
                  ],
                ],
              ),
              if (widget.showCounter)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _hasMinimumPhotos
                        ? BioWayColors.success.withValues(alpha: 0.1)
                        : BioWayColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_photos.length}/${widget.maxPhotos}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _hasMinimumPhotos
                          ? BioWayColors.success
                          : BioWayColors.warning,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
        ] else if (widget.showCounter) ...[
          // If no title but counter is shown, display counter at the top
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _hasMinimumPhotos
                      ? BioWayColors.success.withValues(alpha: 0.1)
                      : BioWayColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_photos.length}/${widget.maxPhotos}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _hasMinimumPhotos
                        ? BioWayColors.success
                        : BioWayColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
        
        // Indicador de optimización
        if (_isOptimizing)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: BioWayColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: BioWayColors.info.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(BioWayColors.info),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _optimizationMessage,
                    style: TextStyle(
                      color: BioWayColors.info,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        // Grid de fotos o estado vacío
        if (_photos.isEmpty)
          _buildEmptyState()
        else
          _buildPhotosGrid(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return InkWell(
      onTap: _showImageOptions,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: BioWayColors.backgroundGrey,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.primaryColor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo,
              size: 50,
              color: widget.primaryColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              widget.emptyStateText,
              style: TextStyle(
                fontSize: 16,
                color: widget.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.emptyStateSubtext,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: _photos.length + (_canAddMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _photos.length && _canAddMore) {
          return _buildAddPhotoButton();
        }
        return _buildPhotoItem(_photos[index], index);
      },
    );
  }

  Widget _buildAddPhotoButton() {
    return InkWell(
      onTap: _showImageOptions,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: widget.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.primaryColor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              size: 32,
              color: widget.primaryColor,
            ),
            const SizedBox(height: 4),
            Text(
              'Agregar',
              style: TextStyle(
                fontSize: 12,
                color: widget.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoItem(File photo, int index) {
    return GestureDetector(
      onTap: () => _viewPhoto(photo),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.primaryColor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                photo,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () => _removePhoto(index),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getFileSizeString(photo),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget simplificado para uso en formularios
class PhotoEvidenceFormField extends StatelessWidget {
  final String title;
  final int maxPhotos;
  final int minPhotos;
  final bool isRequired;
  final Function(List<File>) onPhotosChanged;
  final Color primaryColor;
  final String? errorText;

  const PhotoEvidenceFormField({
    super.key,
    this.title = 'Evidencia Fotográfica',
    this.maxPhotos = 3,
    this.minPhotos = 1,
    this.isRequired = false,
    required this.onPhotosChanged,
    this.primaryColor = const Color(0xFF4CAF50),
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PhotoEvidenceWidget(
            title: title,
            maxPhotos: maxPhotos,
            minPhotos: minPhotos,
            isRequired: isRequired,
            onPhotosChanged: onPhotosChanged,
            primaryColor: primaryColor,
          ),
          if (errorText != null) ...[
            const SizedBox(height: 8),
            Text(
              errorText!,
              style: TextStyle(
                fontSize: 12,
                color: BioWayColors.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}