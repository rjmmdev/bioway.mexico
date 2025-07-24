import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import '../../../../utils/colors.dart';
import '../../../../services/document_service.dart';

/// Widget para carga de documentación con un área de carga por cada requisito
class DocumentUploadPerRequirementWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final String? lotId;
  final Map<String, String> requiredDocuments; // key: ID del requisito, value: descripción
  final Function(Map<String, DocumentInfo>) onDocumentsSubmitted;
  final Color primaryColor;
  final String userType;
  final String submitButtonText;
  final String loadingText;
  final bool showOptionalBadge;
  final List<String>? optionalRequirements; // IDs de requisitos opcionales
  final bool showAppBar; // Nuevo parámetro para controlar si se muestra el AppBar

  const DocumentUploadPerRequirementWidget({
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
    this.showOptionalBadge = true,
    this.optionalRequirements,
    this.showAppBar = true, // Por defecto sí muestra el AppBar
  });

  @override
  State<DocumentUploadPerRequirementWidget> createState() => _DocumentUploadPerRequirementWidgetState();
}

class _DocumentUploadPerRequirementWidgetState extends State<DocumentUploadPerRequirementWidget> {
  final Map<String, DocumentInfo> _uploadedDocuments = {};
  bool _isUploading = false;

  bool _isRequirementOptional(String requirementId) {
    return widget.optionalRequirements?.contains(requirementId) ?? false;
  }

  Future<void> _pickDocument(String requirementId) async {
    try {
      final documentService = DocumentService();
      final result = await documentService.pickDocument(
        documentType: widget.requiredDocuments[requirementId] ?? 'documento',
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      
      if (result != null) {
        setState(() {
          _uploadedDocuments[requirementId] = DocumentInfo(
            file: File(result.path!),
            fileName: result.name,
            fileSize: result.size.toString(),
            uploadDate: DateTime.now(),
          );
        });
        
        _showSuccessSnackBar('Documento cargado correctamente');
      }
    } catch (e) {
      _showErrorSnackBar('Error al cargar el documento: ${e.toString()}');
    }
  }

  void _removeDocument(String requirementId) {
    setState(() {
      _uploadedDocuments.remove(requirementId);
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

  bool _canSubmit() {
    // Verificar que todos los documentos obligatorios estén cargados
    for (final requirementId in widget.requiredDocuments.keys) {
      if (!_isRequirementOptional(requirementId) && !_uploadedDocuments.containsKey(requirementId)) {
        return false;
      }
    }
    return true;
  }

  void _submitDocumentation() {
    if (!_canSubmit()) {
      _showErrorSnackBar('Por favor carga todos los documentos obligatorios');
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
    final content = Column(
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
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                if (widget.lotId != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
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
                  // Información general
                  _buildInfoCard(),
                  
                  const SizedBox(height: 20),
                  
                  // Lista de requisitos con área de carga individual
                  ...widget.requiredDocuments.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildRequirementCard(entry.key, entry.value),
                    );
                  }).toList(),
                  
                  const SizedBox(height: 30),
                  
                  // Botón de confirmar
                  _buildSubmitButton(),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
    );
    
    // Si showAppBar es false, solo devolver el contenido
    if (!widget.showAppBar) {
      return content;
    }
    
    // Si showAppBar es true, envolver en Scaffold con AppBar
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
      body: content,
    );
  }

  Widget _buildInfoCard() {
    final totalRequired = widget.requiredDocuments.length - (widget.optionalRequirements?.length ?? 0);
    final uploadedRequired = widget.requiredDocuments.keys
        .where((id) => !_isRequirementOptional(id) && _uploadedDocuments.containsKey(id))
        .length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BioWayColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: BioWayColors.info.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: BioWayColors.info,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Carga un documento por cada requisito',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: BioWayColors.info,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Documentos obligatorios: $uploadedRequired de $totalRequired',
                  style: TextStyle(
                    fontSize: 12,
                    color: BioWayColors.info.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementCard(String requirementId, String requirementName) {
    final isOptional = _isRequirementOptional(requirementId);
    final hasDocument = _uploadedDocuments.containsKey(requirementId);
    final document = _uploadedDocuments[requirementId];

    return Container(
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
        children: [
          // Header del requisito
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: hasDocument 
                  ? BioWayColors.success.withValues(alpha: 0.05)
                  : isOptional 
                      ? Colors.grey.withValues(alpha: 0.05)
                      : widget.primaryColor.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(
                  color: hasDocument 
                      ? BioWayColors.success.withValues(alpha: 0.2)
                      : isOptional 
                          ? Colors.grey.withValues(alpha: 0.2)
                          : widget.primaryColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  hasDocument ? Icons.check_circle : Icons.pending_outlined,
                  color: hasDocument 
                      ? BioWayColors.success
                      : isOptional 
                          ? Colors.grey
                          : widget.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              requirementName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (isOptional && widget.showOptionalBadge)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Opcional',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          if (!isOptional)
                            Text(
                              '*',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: BioWayColors.error,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Área de carga o documento cargado
          Container(
            padding: const EdgeInsets.all(16),
            child: hasDocument
                ? _buildUploadedDocument(requirementId, document!)
                : _buildUploadArea(requirementId),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadArea(String requirementId) {
    return InkWell(
      onTap: () => _pickDocument(requirementId),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          border: Border.all(
            color: widget.primaryColor.withValues(alpha: 0.3),
            width: 2,
            style: BorderStyle.solid,
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
                size: 36,
              ),
              const SizedBox(height: 8),
              Text(
                'Cargar Documento',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: widget.primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'PDF, JPG, PNG',
                style: TextStyle(
                  fontSize: 12,
                  color: BioWayColors.textGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadedDocument(String requirementId, DocumentInfo doc) {
    return GestureDetector(
      onTap: () => _openDocument(doc.file),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: BioWayColors.success.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: BioWayColors.success.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getFileColor(doc.fileName).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getFileIcon(doc.fileName),
                color: _getFileColor(doc.fileName),
                size: 20,
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
                      Icon(
                        Icons.check_circle,
                        color: BioWayColors.success,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Cargado',
                        style: TextStyle(
                          fontSize: 11,
                          color: BioWayColors.success,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: TextStyle(
                          color: BioWayColors.textGrey,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        doc.fileSize,
                        style: TextStyle(
                          fontSize: 11,
                          color: BioWayColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _removeDocument(requirementId),
              icon: Icon(
                Icons.close,
                color: BioWayColors.error,
                size: 18,
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
    final canSubmit = _canSubmit();
    
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: (_isUploading || !canSubmit) ? null : _submitDocumentation,
        style: ElevatedButton.styleFrom(
          backgroundColor: canSubmit ? widget.primaryColor : Colors.grey,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: canSubmit ? 3 : 0,
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