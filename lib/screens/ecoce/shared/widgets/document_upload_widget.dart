import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import '../../../../utils/colors.dart';
import '../../reciclador/services/document_picker_service.dart';

/// Widget compartido para carga de documentación técnica
/// Puede ser utilizado por cualquier usuario del sistema ECOCE
class DocumentUploadWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final String? lotId;
  final List<String> requiredDocuments;
  final Function(List<DocumentInfo>) onDocumentsSubmitted;
  final Color primaryColor;
  final String userType;
  final String submitButtonText;
  final String loadingText;
  final String successTitle;
  final String? additionalInfoText;
  final List<String> allowedExtensions;
  final bool showCounter;

  const DocumentUploadWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.requiredDocuments,
    required this.onDocumentsSubmitted,
    this.lotId,
    this.primaryColor = const Color(0xFF4CAF50), // Verde ECOCE por defecto
    this.userType = 'default',
    this.submitButtonText = 'Confirmar Documentación',
    this.loadingText = 'Procesando documentos...',
    this.successTitle = 'Documentación Completada',
    this.additionalInfoText,
    this.allowedExtensions = const ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'jpg', 'jpeg', 'png'],
    this.showCounter = true,
  });

  @override
  State<DocumentUploadWidget> createState() => _DocumentUploadWidgetState();
}

class _DocumentUploadWidgetState extends State<DocumentUploadWidget> {
  List<DocumentInfo> _uploadedDocuments = [];
  bool _isUploading = false;

  Future<void> _pickDocuments() async {
    try {
      final documentPickerService = DocumentPickerService();
      final result = await documentPickerService.pickDocument();
      
      if (result != null) {
        setState(() {
          _uploadedDocuments.add(DocumentInfo(
            file: result.file,
            fileName: result.fileName,
            fileSize: result.fileSize,
            uploadDate: DateTime.now(),
          ));
        });
        
        _showSuccessSnackBar('Documento cargado correctamente');
      }
    } catch (e) {
      _showErrorSnackBar('Error al cargar el documento: ${e.toString()}');
    }
  }

  void _removeDocument(int index) {
    setState(() {
      _uploadedDocuments.removeAt(index);
    });
  }

  Future<void> _openDocument(File file) async {
    try {
      final result = await OpenFile.open(file.path);
      if (result.type != ResultType.done) {
        _showErrorSnackBar('No se pudo abrir el documento');
      }
    } catch (e) {
      _showErrorSnackBar('Error al abrir el documento');
    }
  }

  void _submitDocumentation() {
    if (_uploadedDocuments.length < widget.requiredDocuments.length) {
      _showErrorSnackBar(
        'Por favor carga al menos ${widget.requiredDocuments.length} documentos (${widget.requiredDocuments.join(", ")})'
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    // Simular carga
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        widget.onDocumentsSubmitted(_uploadedDocuments);
      }
    });
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

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BioWayColors.backgroundGrey,
      appBar: AppBar(
        backgroundColor: widget.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: widget.primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.subtitle,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                if (widget.lotId != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Lote: ${widget.lotId}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Contenido
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Tarjeta de documentos requeridos
                  _buildRequiredDocumentsCard(),
                  
                  const SizedBox(height: 20),
                  
                  // Área de carga de documentos
                  _buildUploadArea(),
                  
                  const SizedBox(height: 30),
                  
                  // Botón de confirmar
                  _buildSubmitButton(),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequiredDocumentsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '📋',
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 10),
              Text(
                'Documentos Requeridos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: BioWayColors.darkGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Por favor carga los siguientes documentos:',
            style: TextStyle(
              fontSize: 14,
              color: BioWayColors.textGrey,
            ),
          ),
          const SizedBox(height: 12),
          ...widget.requiredDocuments.map((doc) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: widget.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    doc,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
          if (widget.additionalInfoText != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: BioWayColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: BioWayColors.info.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: BioWayColors.info,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.additionalInfoText!,
                      style: TextStyle(
                        fontSize: 12,
                        color: BioWayColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUploadArea() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    '📄',
                    style: TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Documentos Cargados',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: BioWayColors.darkGreen,
                    ),
                  ),
                ],
              ),
              if (widget.showCounter)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _uploadedDocuments.length >= widget.requiredDocuments.length
                        ? BioWayColors.success.withOpacity(0.1)
                        : BioWayColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_uploadedDocuments.length} / ${widget.requiredDocuments.length}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _uploadedDocuments.length >= widget.requiredDocuments.length
                          ? BioWayColors.success
                          : BioWayColors.warning,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Botón para cargar documentos
          InkWell(
            onTap: _pickDocuments,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(
                  color: widget.primaryColor.withOpacity(0.3),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
                color: BioWayColors.backgroundGrey,
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      color: widget.primaryColor,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Cargar Documento',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: widget.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.allowedExtensions.map((e) => e.toUpperCase()).join(', '),
                      style: TextStyle(
                        fontSize: 12,
                        color: BioWayColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Lista de documentos cargados
          if (_uploadedDocuments.isNotEmpty) ...[
            const SizedBox(height: 16),
            ..._uploadedDocuments.asMap().entries.map((entry) {
              final index = entry.key;
              final doc = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildDocumentItem(doc, index),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentItem(DocumentInfo doc, int index) {
    return GestureDetector(
      onTap: () => _openDocument(doc.file),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Icono del tipo de archivo
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: _getFileColor(doc.fileName).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getFileIcon(doc.fileName),
                color: _getFileColor(doc.fileName),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.fileName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        doc.fileSize,
                        style: TextStyle(
                          fontSize: 12,
                          color: BioWayColors.textGrey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: TextStyle(
                          color: BioWayColors.textGrey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.check_circle,
                        color: BioWayColors.success,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Cargado',
                        style: TextStyle(
                          fontSize: 12,
                          color: BioWayColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _removeDocument(index),
              icon: Icon(
                Icons.close,
                color: BioWayColors.error,
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isUploading ? null : _submitDocumentation,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 3,
        ),
        child: _isUploading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.loadingText,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : Text(
                widget.submitButtonText,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}

/// Clase para información del documento
class DocumentInfo {
  final File file;
  final String fileName;
  final String fileSize;
  final DateTime uploadDate;

  DocumentInfo({
    required this.file,
    required this.fileName,
    required this.fileSize,
    required this.uploadDate,
  });
}

/// Página simplificada que utiliza el widget compartido
class SharedDocumentUploadScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? lotId;
  final List<String> requiredDocuments;
  final Function(List<DocumentInfo>) onDocumentsSubmitted;
  final Color primaryColor;
  final String userType;
  final String submitButtonText;
  final String loadingText;
  final String successTitle;
  final String? additionalInfoText;

  const SharedDocumentUploadScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.requiredDocuments,
    required this.onDocumentsSubmitted,
    this.lotId,
    this.primaryColor = const Color(0xFF4CAF50),
    this.userType = 'default',
    this.submitButtonText = 'Confirmar Documentación',
    this.loadingText = 'Procesando documentos...',
    this.successTitle = 'Documentación Completada',
    this.additionalInfoText,
  });

  @override
  Widget build(BuildContext context) {
    return DocumentUploadWidget(
      title: title,
      subtitle: subtitle,
      lotId: lotId,
      requiredDocuments: requiredDocuments,
      onDocumentsSubmitted: onDocumentsSubmitted,
      primaryColor: primaryColor,
      userType: userType,
      submitButtonText: submitButtonText,
      loadingText: loadingText,
      successTitle: successTitle,
      additionalInfoText: additionalInfoText,
    );
  }
}