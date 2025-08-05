import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/ui_constants.dart';
import '../../../services/firebase/firebase_storage_service.dart';
import '../../../services/lote_unificado_service.dart';
import '../../../services/transformacion_service.dart';
import '../shared/widgets/document_upload_per_requirement_widget.dart';
import '../shared/widgets/dialog_utils.dart';

class TransformadorDocumentacionScreen extends StatefulWidget {
  final String? loteId;
  final String? transformacionId;
  final String? material;
  final double? peso;
  
  const TransformadorDocumentacionScreen({
    super.key,
    this.loteId,
    this.transformacionId,
    this.material,
    this.peso,
  });

  @override
  State<TransformadorDocumentacionScreen> createState() => _TransformadorDocumentacionScreenState();
}

class _TransformadorDocumentacionScreenState extends State<TransformadorDocumentacionScreen> {
  final FirebaseStorageService _storageService = FirebaseStorageService();
  final LoteUnificadoService _loteUnificadoService = LoteUnificadoService();
  final TransformacionService _transformacionService = TransformacionService();
  
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.orange,
        elevation: UIConstants.elevationNone,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context, false);
          },
        ),
        title: const Text(
          'Documentación',
          style: TextStyle(
            fontSize: UIConstants.fontSizeBody + 2,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: DocumentUploadPerRequirementWidget(
        title: 'Documentación del Proceso',
        subtitle: 'Carga los documentos técnicos del proceso de transformación',
        lotId: widget.loteId ?? widget.transformacionId,
        requiredDocuments: const {
          'ficha_tecnica_pellet': 'Ficha técnica del pellet reciclado recibido',
          'resultados_mezcla_inicial': 'Resultados de prueba de mezcla inicial',
          'resultados_transformacion': 'Resultados del proceso de transformación',
          'ficha_tecnica_mezcla_final': 'Ficha técnica de la mezcla final utilizada',
        },
        optionalRequirements: const ['ficha_tecnica_mezcla_final'],
        onDocumentsSubmitted: _handleDocumentsSubmitted,
        primaryColor: Colors.orange,
        userType: 'transformador',
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
          final String path;
          
          // Determinar la ruta según si es un lote individual o una transformación
          if (widget.transformacionId != null) {
            path = 'transformaciones/${widget.transformacionId}/documentos';
          } else if (widget.loteId != null) {
            path = 'transformador/${widget.loteId}/documentos/${entry.key}';
          } else {
            throw Exception('No se proporcionó ID de lote o transformación');
          }
          
          final url = await _storageService.uploadFile(
            entry.value.file!,
            path,
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
      
      // Actualizar según el tipo de proceso
      if (widget.transformacionId != null) {
        // Es una transformación (megalote)
        await _transformacionService.actualizarDocumentacion(
          transformacionId: widget.transformacionId!,
          documentos: documentUrls,
        );
      } else if (widget.loteId != null) {
        // Es un lote individual
        await _loteUnificadoService.actualizarProcesoTransformador(
          loteId: widget.loteId!,
          datosTransformador: {
            'estado': 'completado',
            'documentos': documentUrls, // Ahora es Map<String, String> no Map<String, List<String>>
            'fecha_documentacion': DateTime.now(),
            'documentacion_completada': true,
          },
        );
      }
      
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
            borderRadius: BorderRadiusConstants.borderRadiusLarge,
          ),
          child: Container(
            padding: EdgeInsetsConstants.paddingAll24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: UIConstants.iconSizeDialog + UIConstants.spacing20,
                  height: UIConstants.iconSizeDialog + UIConstants.spacing20,
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: UIConstants.opacityLow),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.orange,
                    size: UIConstants.iconSizeLarge + UIConstants.spacing24,
                  ),
                ),
                SizedBox(height: UIConstants.spacing24),
                const Text(
                  'Documentación Cargada',
                  style: TextStyle(
                    fontSize: UIConstants.fontSizeLarge,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: UIConstants.spacing16),
                Text(
                  widget.transformacionId != null 
                    ? 'Los documentos del megalote se han guardado correctamente.'
                    : 'Los documentos se han guardado correctamente. El lote ha sido completado.',
                  style: const TextStyle(
                    fontSize: UIConstants.fontSizeBody,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: UIConstants.spacing24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Cerrar diálogo
                      Navigator.pop(context, true); // Regresar con resultado exitoso
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: EdgeInsets.symmetric(vertical: UIConstants.spacing12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadiusConstants.borderRadiusSmall,
                      ),
                    ),
                    child: const Text(
                      'Aceptar',
                      style: TextStyle(
                        fontSize: UIConstants.fontSizeBody,
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