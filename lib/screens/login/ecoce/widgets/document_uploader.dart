// Archivo: widgets/document_uploader.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../utils/colors.dart';
import '../../../../services/document_service.dart';

class DocumentUploader extends StatefulWidget {
  final Map<String, String?> selectedFiles;
  final Function(String, PlatformFile?, String?) onFileSelected;
  final Map<String, PlatformFile?> platformFiles;
  final bool isUploading;

  const DocumentUploader({
    super.key,
    required this.selectedFiles,
    required this.onFileSelected,
    required this.platformFiles,
    this.isUploading = false,
  });

  @override
  State<DocumentUploader> createState() => _DocumentUploaderState();
}

class _DocumentUploaderState extends State<DocumentUploader> {
  final DocumentService _documentService = DocumentService();
  Map<String, bool> _uploadingStates = {};

  static const List<Map<String, dynamic>> _documents = [
    {
      'key': 'const_sit_fis',
      'title': 'Constancia de Situación Fiscal',
      'icon': Icons.description,
    },
    {
      'key': 'comp_domicilio',
      'title': 'Comprobante de Domicilio',
      'icon': Icons.home_work,
    },
    {
      'key': 'banco_caratula',
      'title': 'Carátula de Estado de Cuenta',
      'icon': Icons.account_balance,
    },
    {
      'key': 'ine',
      'title': 'INE/Identificación Oficial',
      'icon': Icons.badge,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BioWayColors.lightGrey.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BioWayColors.lightGrey, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder_open, color: BioWayColors.petBlue, size: 24),
              const SizedBox(width: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Documentos Fiscales',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: BioWayColors.darkGreen,
                    ),
                  ),
                  Text(
                    'Los documentos son opcionales pero recomendados',
                    style: TextStyle(fontSize: 12, color: BioWayColors.textGrey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Lista de documentos
          ..._documents.map((doc) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DocumentUploadItem(
              title: doc['title'],
              documentKey: doc['key'],
              icon: doc['icon'],
              hasFile: widget.selectedFiles[doc['key']] != null,
              fileName: widget.platformFiles[doc['key']]?.name,
              fileSize: widget.platformFiles[doc['key']]?.size,
              isUploading: _uploadingStates[doc['key']] ?? false,
              onTap: () => _selectDocument(doc['key']),
              onRemove: widget.selectedFiles[doc['key']] != null 
                  ? () => _removeDocument(doc['key']) 
                  : null,
            ),
          )).toList(),
          if (widget.isUploading)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: LinearProgressIndicator(
                backgroundColor: BioWayColors.lightGrey,
                valueColor: AlwaysStoppedAnimation<Color>(BioWayColors.ecoceGreen),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _selectDocument(String documentKey) async {
    try {
      setState(() {
        _uploadingStates[documentKey] = true;
      });

      // Seleccionar archivo
      final file = await _documentService.pickDocument(
        documentType: documentKey,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (file != null) {
        // Validar tamaño
        if (!_documentService.validateFileSize(file, maxSizeMB: 5)) {
          _showError('El archivo es demasiado grande. Máximo 5MB.');
          setState(() {
            _uploadingStates[documentKey] = false;
          });
          return;
        }

        // Notificar al padre
        widget.onFileSelected(documentKey, file, null);
      }
    } catch (e) {
      _showError('Error al seleccionar archivo: $e');
    } finally {
      setState(() {
        _uploadingStates[documentKey] = false;
      });
    }
  }

  void _removeDocument(String documentKey) {
    widget.onFileSelected(documentKey, null, null);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

class DocumentUploadItem extends StatelessWidget {
  final String title;
  final String documentKey;
  final IconData icon;
  final bool hasFile;
  final String? fileName;
  final int? fileSize;
  final bool isUploading;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const DocumentUploadItem({
    super.key,
    required this.title,
    required this.documentKey,
    required this.icon,
    required this.hasFile,
    this.fileName,
    this.fileSize,
    this.isUploading = false,
    required this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: !isUploading ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: hasFile ? BioWayColors.success.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasFile ? BioWayColors.success : BioWayColors.lightGrey,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: hasFile ? BioWayColors.success : BioWayColors.textGrey,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: hasFile ? FontWeight.bold : FontWeight.normal,
                      color: hasFile ? BioWayColors.success : BioWayColors.darkGreen,
                    ),
                  ),
                  Text(
                    hasFile
                        ? _formatFileInfo()
                        : 'Toca para seleccionar archivo',
                    style: const TextStyle(
                      fontSize: 12,
                      color: BioWayColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            if (isUploading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(BioWayColors.petBlue),
                ),
              )
            else if (hasFile && onRemove != null)
              IconButton(
                icon: const Icon(
                  Icons.close,
                  color: BioWayColors.error,
                  size: 20,
                ),
                onPressed: onRemove,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Quitar archivo',
              )
            else
              Icon(
                hasFile ? Icons.check_circle : Icons.upload_file,
                color: hasFile ? BioWayColors.success : BioWayColors.textGrey,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  String _formatFileInfo() {
    if (fileName == null) return 'Archivo seleccionado';
    
    String info = fileName!;
    if (fileSize != null) {
      final sizeInKB = fileSize! / 1024;
      if (sizeInKB > 1024) {
        final sizeInMB = sizeInKB / 1024;
        info += ' (${sizeInMB.toStringAsFixed(1)} MB)';
      } else {
        info += ' (${sizeInKB.toStringAsFixed(0)} KB)';
      }
    }
    return info;
  }
}