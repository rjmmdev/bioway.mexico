import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/firebase/firebase_storage_service.dart';
import '../../../services/transformacion_service.dart';
import '../../../models/lotes/transformacion_model.dart';
import '../shared/widgets/document_upload_per_requirement_widget.dart';
import '../shared/widgets/dialog_utils.dart';

class TransformadorDocumentacionMegaloteScreen extends StatefulWidget {
  final String transformacionId;
  final TransformacionModel? transformacion;
  
  const TransformadorDocumentacionMegaloteScreen({
    super.key,
    required this.transformacionId,
    this.transformacion,
  });

  @override
  State<TransformadorDocumentacionMegaloteScreen> createState() => _TransformadorDocumentacionMegaloteScreenState();
}

class _TransformadorDocumentacionMegaloteScreenState extends State<TransformadorDocumentacionMegaloteScreen> {
  final FirebaseStorageService _storageService = FirebaseStorageService();
  final TransformacionService _transformacionService = TransformacionService();
  
  bool _isLoading = true;
  TransformacionModel? _transformacion;
  bool _hasDocuments = false;

  @override
  void initState() {
    super.initState();
    _transformacion = widget.transformacion;
    if (_transformacion == null) {
      _loadTransformacion();
    } else {
      _checkDocumentStatus();
    }
  }

  Future<void> _loadTransformacion() async {
    try {
      final transformacion = await _transformacionService.obtenerTransformacion(widget.transformacionId);
      
      if (mounted) {
        setState(() {
          _transformacion = transformacion;
          _isLoading = false;
        });
        
        if (_transformacion != null) {
          _checkDocumentStatus();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        DialogUtils.showErrorDialog(
          context,
          title: 'Error',
          message: 'Error al cargar la transformación: $e',
        );
      }
    }
  }
  
  void _checkDocumentStatus() {
    if (_transformacion != null) {
      _hasDocuments = _transformacion!.documentosAsociados.isNotEmpty;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.orange,
          title: const Text(
            'Documentación del Megalote',
            style: TextStyle(color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      );
    }
    
    if (_transformacion == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.orange,
          title: const Text(
            'Documentación del Megalote',
            style: TextStyle(color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              const Text(
                'Transformación no encontrada',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_hasDocuments) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.orange,
          title: const Text(
            'Documentación del Megalote',
            style: TextStyle(color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                size: 80,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              const Text(
                'Documentación ya enviada',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Los documentos de este megalote ya fueron cargados',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Regresar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.orange,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context, false);
          },
        ),
        title: const Text(
          'Documentación del Megalote',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: DocumentUploadPerRequirementWidget(
        title: 'Documentación del Proceso',
        subtitle: 'Carga los documentos técnicos del proceso de transformación',
        lotId: widget.transformacionId,
        requiredDocuments: const {
          'ficha_tecnica_pellet': 'Ficha técnica del pellet reciclado recibido',
          'resultados_mezcla_inicial': 'Resultados de prueba de mezcla inicial',
          'resultados_transformacion': 'Resultados del proceso de transformación',
          'ficha_tecnica_mezcla_final': 'Ficha técnica de la mezcla final utilizada',
        },
        optionalRequirements: const ['ficha_tecnica_mezcla_final'],
        onDocumentsSubmitted: _handleDocumentsSubmitted,
        primaryColor: Colors.orange,
        userType: 'transformador_megalote',
        submitButtonText: 'Confirmar Documentación',
        loadingText: 'Procesando documentos...',
        showOptionalBadge: true,
        showAppBar: false,
      ),
    );
  }
  
  Future<void> _handleDocumentsSubmitted(Map<String, DocumentInfo> documents) async {
    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      );
      
      // Subir documentos a Firebase Storage
      Map<String, String> documentUrls = {};
      
      for (var entry in documents.entries) {
        if (entry.value.file != null) {
          final url = await _storageService.uploadFile(
            entry.value.file!,
            'transformador/megalotes/${widget.transformacionId}/documentos/${entry.key}',
          );
          
          if (url != null) {
            // Guardar como string único, no como array
            documentUrls[entry.key] = url;
          }
        }
      }
      
      // Verificar que tenemos al menos los documentos obligatorios
      final requiredDocs = ['ficha_tecnica_pellet', 'resultados_mezcla_inicial', 'resultados_transformacion'];
      for (String doc in requiredDocs) {
        if (!documentUrls.containsKey(doc)) {
          throw Exception('Falta el documento obligatorio: $doc');
        }
      }
      
      // Actualizar la transformación y cambiar estado a completado
      await _transformacionService.actualizarDocumentacion(
        transformacionId: widget.transformacionId,
        documentos: documentUrls,
      );
      
      // También actualizar el estado a completado
      await _transformacionService.actualizarEstadoTransformacion(
        transformacionId: widget.transformacionId,
        nuevoEstado: 'completado',
      );
      
      if (!mounted) return;
      
      // Cerrar loading
      Navigator.pop(context);
      
      // Mostrar éxito con diálogo personalizado para Transformador
      _showTransformadorSuccessDialog();
      
    } catch (e) {
      if (!mounted) return;
      
      // Cerrar loading si está abierto
      Navigator.pop(context);
      
      DialogUtils.showErrorDialog(
        context,
        title: 'Error',
        message: 'Error al cargar documentación: $e',
      );
    }
  }
  
  void _showTransformadorSuccessDialog() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.orange,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Documentación Cargada',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Los documentos del megalote se han guardado correctamente. El megalote ha sido completado.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Cerrar diálogo
                      Navigator.pop(context, true); // Regresar con resultado exitoso
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Aceptar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}