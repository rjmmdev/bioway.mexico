import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import '../../../utils/colors.dart';
import 'reciclador_administracion_lotes.dart';
import 'reciclador_lote_qr_screen.dart';
import 'services/document_picker_service.dart';

class RecicladorDocumentacion extends StatefulWidget {
  final String lotId;
  
  const RecicladorDocumentacion({
    super.key,
    required this.lotId,
  });

  @override
  State<RecicladorDocumentacion> createState() => _RecicladorDocumentacionState();
}

class _RecicladorDocumentacionState extends State<RecicladorDocumentacion> {
  // Lista de documentos cargados
  List<DocumentInfo> _documentosCargados = [];
  bool _isUploading = false;
  
  // Documentos requeridos
  final List<String> _documentosRequeridos = [
    'Ficha Técnica del Pellet',
    'Reporte de Resultados de Reciclaje',
  ];

  Future<void> _pickDocuments() async {
    try {
      final documentPickerService = DocumentPickerService();
      final result = await documentPickerService.pickDocument();
      
      if (result != null) {
        setState(() {
          _documentosCargados.add(DocumentInfo(
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
      _documentosCargados.removeAt(index);
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
    if (_documentosCargados.length < _documentosRequeridos.length) {
      _showErrorSnackBar(
        'Por favor carga al menos ${_documentosRequeridos.length} documentos (${_documentosRequeridos.join(", ")})'
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    // Simular carga
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isUploading = false;
      });
      _showSuccessDialog();
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: BioWayColors.success,
                size: 80,
              ),
              const SizedBox(height: 20),
              const Text(
                'Documentación Completada',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Se han cargado ${_documentosCargados.length} documentos exitosamente',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: BioWayColors.textGrey,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navegar directamente a la pantalla de QR mostrando el éxito
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecicladorLoteQRScreen(
                      loteId: widget.lotId,
                      material: 'PET', // En producción vendría de la base de datos
                      pesoOriginal: 100.0, // En producción vendría de la base de datos
                      presentacion: 'Pacas', // En producción vendría de la base de datos
                      origen: 'Acopiador Norte', // En producción vendría de la base de datos
                      fechaEntrada: DateTime.now().subtract(const Duration(days: 2)),
                      fechaSalida: DateTime.now(),
                      documentosCargados: _documentosCargados.map((doc) => doc.fileName).toList(),
                      mostrarMensajeExito: true,
                    ),
                  ),
                );
              },
              child: Text(
                'Aceptar',
                style: TextStyle(
                  color: BioWayColors.ecoceGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
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
        backgroundColor: BioWayColors.ecoceGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Documentación Técnica',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // Header verde
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: BioWayColors.ecoceGreen,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Carga los documentos técnicos',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
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
            ),
          ),

          // Contenido
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Tarjeta de documentos requeridos
                  Container(
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
                        ..._documentosRequeridos.map((doc) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                color: BioWayColors.ecoceGreen,
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
                                  'Puedes cargar documentos adicionales si lo consideras necesario',
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
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Área de carga de documentos
                  Container(
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
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: _documentosCargados.length >= _documentosRequeridos.length
                                    ? BioWayColors.success.withOpacity(0.1)
                                    : BioWayColors.warning.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_documentosCargados.length} / ${_documentosRequeridos.length}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _documentosCargados.length >= _documentosRequeridos.length
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
                                color: BioWayColors.ecoceGreen.withOpacity(0.3),
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
                                    color: BioWayColors.ecoceGreen,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Cargar Documento',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: BioWayColors.ecoceGreen,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'PDF, DOC, DOCX, XLS, XLSX, JPG, PNG',
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
                        if (_documentosCargados.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          ..._documentosCargados.asMap().entries.map((entry) {
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
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Botón de confirmar
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _submitDocumentation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BioWayColors.ecoceGreen,
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
                                const Text(
                                  'Procesando documentos...',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              'Confirmar Documentación',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
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
          color: BioWayColors.ecoceGreen.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: BioWayColors.ecoceGreen.withOpacity(0.2),
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
}

// Clase para información del documento
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