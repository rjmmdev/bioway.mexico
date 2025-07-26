import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/colors.dart';
import '../../../services/firebase/firebase_storage_service.dart';
import '../../../services/lote_unificado_service.dart';

class TransformadorDocumentacionScreen extends StatefulWidget {
  final String? loteId;
  final String? material;
  final double? peso;
  
  const TransformadorDocumentacionScreen({
    super.key,
    this.loteId,
    this.material,
    this.peso,
  });

  @override
  State<TransformadorDocumentacionScreen> createState() => _TransformadorDocumentacionScreenState();
}

class _TransformadorDocumentacionScreenState extends State<TransformadorDocumentacionScreen> {
  final FirebaseStorageService _storageService = FirebaseStorageService();
  final LoteUnificadoService _loteUnificadoService = LoteUnificadoService();
  
  // Mapa para almacenar archivos por tipo de documento
  final Map<String, List<PlatformFile>> _archivosPorDocumento = {
    'ficha_tecnica_pellet': [],
    'resultados_mezcla_inicial': [],
    'resultados_transformacion': [],
    'ficha_tecnica_mezcla_final': [],
  };
  
  // Descripciones de los documentos
  final Map<String, String> _descripcionesDocumentos = {
    'ficha_tecnica_pellet': 'Ficha técnica del pellet reciclado recibido',
    'resultados_mezcla_inicial': 'Resultados de prueba de mezcla inicial',
    'resultados_transformacion': 'Resultados del proceso de transformación',
    'ficha_tecnica_mezcla_final': 'Ficha técnica de la mezcla final utilizada',
  };

  // Iconos para cada tipo de documento
  final Map<String, IconData> _iconosDocumentos = {
    'ficha_tecnica_pellet': Icons.description,
    'resultados_mezcla_inicial': Icons.science,
    'resultados_transformacion': Icons.engineering,
    'ficha_tecnica_mezcla_final': Icons.verified,
  };

  // Documentos obligatorios (todos excepto ficha_tecnica_mezcla_final)
  final Set<String> _documentosObligatorios = {
    'ficha_tecnica_pellet',
    'resultados_mezcla_inicial',
    'resultados_transformacion',
  };

  bool _isLoading = false;

  Future<void> _seleccionarArchivos(String tipoDocumento) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: true,
      );

      if (result != null) {
        setState(() {
          _archivosPorDocumento[tipoDocumento]!.addAll(result.files);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar archivos: $e'),
            backgroundColor: BioWayColors.error,
          ),
        );
      }
    }
  }

  void _eliminarArchivo(String tipoDocumento, int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _archivosPorDocumento[tipoDocumento]!.removeAt(index);
    });
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    int unitIndex = 0;
    double size = bytes.toDouble();
    
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    
    return '${size.toStringAsFixed(1)} ${units[unitIndex]}';
  }

  IconData _getFileIcon(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  bool get _todosDocumentosCargados {
    // Verificar que todos los documentos obligatorios tengan archivos
    for (String docObligatorio in _documentosObligatorios) {
      if (_archivosPorDocumento[docObligatorio]!.isEmpty) {
        return false;
      }
    }
    return true;
  }

  int get _totalArchivos {
    return _archivosPorDocumento.values.fold(0, (total, archivos) => total + archivos.length);
  }

  void _confirmarDocumentacion() async {
    if (!_todosDocumentosCargados) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, carga los documentos obligatorios marcados con (*)'),
          backgroundColor: BioWayColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload documents to Firebase Storage
      Map<String, List<String>> documentUrls = {};
      
      for (var entry in _archivosPorDocumento.entries) {
        if (entry.value.isNotEmpty) {
          List<String> urls = [];
          for (var file in entry.value) {
            if (file.path != null) {
              // Convert file path to File object for upload
              final fileToUpload = File(file.path!);
              final url = await _storageService.uploadFile(
                fileToUpload,
                'transformador/${widget.loteId}/documentos/${entry.key}',
              );
              if (url != null) {
                urls.add(url);
              }
            }
          }
          documentUrls[entry.key] = urls;
        }
      }
      
      // Update lot status to 'completado' and save document URLs using Unified System
      if (widget.loteId != null) {
        await _loteUnificadoService.actualizarProcesoTransformador(
          loteId: widget.loteId!,
          datosTransformador: {
            'estado': 'completado',
            'documentos': documentUrls,
            'fecha_documentacion': DateTime.now(),
          },
        );
      }
      
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Documentación cargada exitosamente. El lote ha sido completado.'),
            backgroundColor: BioWayColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        
        // Wait for snackbar to show
        await Future.delayed(const Duration(seconds: 2));
        
        // Pop back with success result
        if (mounted) {
          Navigator.pop(context, true); // Return true when documentation is completed
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar documentación: ${e.toString()}'),
            backgroundColor: BioWayColors.error,
          ),
        );
      }
    }
  }

  Widget _buildDocumentSection(String tipoDocumento) {
    final archivos = _archivosPorDocumento[tipoDocumento]!;
    final descripcion = _descripcionesDocumentos[tipoDocumento]!;
    final icono = _iconosDocumentos[tipoDocumento]!;
    final tieneArchivos = archivos.isNotEmpty;
    final esObligatorio = _documentosObligatorios.contains(tipoDocumento);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado del documento
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tieneArchivos 
                      ? BioWayColors.ecoceGreen.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icono,
                  color: tieneArchivos ? BioWayColors.ecoceGreen : Colors.grey,
                  size: 24,
                ),
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
                            descripcion,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (esObligatorio)
                          Text(
                            ' *',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: BioWayColors.error,
                            ),
                          ),
                      ],
                    ),
                    if (tieneArchivos) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${archivos.length} archivo${archivos.length > 1 ? 's' : ''} cargado${archivos.length > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: BioWayColors.ecoceGreen,
                        ),
                      ),
                    ] else if (esObligatorio) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Documento obligatorio',
                        style: TextStyle(
                          fontSize: 12,
                          color: BioWayColors.error,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (tieneArchivos)
                Icon(
                  Icons.check_circle,
                  color: BioWayColors.ecoceGreen,
                  size: 24,
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Área de carga
          InkWell(
            onTap: () => _seleccionarArchivos(tipoDocumento),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: BioWayColors.ecoceGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    tieneArchivos ? 'Agregar más archivos' : 'Seleccionar archivos',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: BioWayColors.ecoceGreen,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Lista de archivos cargados
          if (tieneArchivos) ...[
            const SizedBox(height: 12),
            ...archivos.asMap().entries.map((entry) {
              final index = entry.key;
              final file = entry.value;
              final color = _getFileColor(file.extension);
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getFileIcon(file.extension),
                      color: color,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            file.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _formatFileSize(file.size),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Colors.grey[600],
                        size: 18,
                      ),
                      onPressed: () => _eliminarArchivo(tipoDocumento, index),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Documentación',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context, false), // Return false when backing out
        ),
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _todosDocumentosCargados 
                    ? BioWayColors.ecoceGreen.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_upload,
                    size: 16,
                    color: _todosDocumentosCargados 
                        ? BioWayColors.ecoceGreen
                        : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$_totalArchivos archivo${_totalArchivos != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _todosDocumentosCargados 
                          ? BioWayColors.ecoceGreen
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lot info if available
              if (widget.loteId != null) ...[
                Container(
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
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lote: ${widget.loteId}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (widget.material != null)
                              Text(
                                'Material: ${widget.material}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                            if (widget.peso != null)
                              Text(
                                'Peso: ${widget.peso} kg',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Título de la sección
              const Text(
                'Documentos de Evidencia',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Carga los documentos relacionados con el proceso de transformación. Puede saltar este paso si es necesario.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),

              // Indicador de progreso
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Documentos obligatorios',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          '${_documentosObligatorios.where((doc) => _archivosPorDocumento[doc]!.isNotEmpty).length} de ${_documentosObligatorios.length}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: _documentosObligatorios.isEmpty 
                          ? 0 
                          : _documentosObligatorios.where((doc) => _archivosPorDocumento[doc]!.isNotEmpty).length / _documentosObligatorios.length,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(BioWayColors.ecoceGreen),
                      minHeight: 6,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Secciones de documentos
              ..._archivosPorDocumento.keys.map((tipoDocumento) => 
                _buildDocumentSection(tipoDocumento)
              ),

              const SizedBox(height: 12),

              // Nota sobre documentos obligatorios
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Colors.amber[700],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Los documentos marcados con (*) son obligatorios',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.amber[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Botón de confirmación
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading || !_todosDocumentosCargados 
                      ? null 
                      : _confirmarDocumentacion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BioWayColors.ecoceGreen,
                    disabledBackgroundColor: Colors.grey[300],
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Confirmar Documentación',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _todosDocumentosCargados 
                                ? Colors.white 
                                : Colors.grey[600],
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}