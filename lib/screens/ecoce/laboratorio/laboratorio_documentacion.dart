import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/colors.dart';
import '../../../services/lote_service.dart';
import '../../../services/muestra_laboratorio_service.dart'; // NUEVO: Servicio independiente
import '../../../services/firebase/firebase_storage_service.dart';
import 'laboratorio_gestion_muestras.dart';
import '../shared/widgets/document_upload_per_requirement_widget.dart';
import '../shared/widgets/dialog_utils.dart';

class LaboratorioDocumentacion extends StatefulWidget {
  final String muestraId;
  final String? transformacionId;
  
  const LaboratorioDocumentacion({
    super.key,
    required this.muestraId,
    this.transformacionId,
  });

  @override
  State<LaboratorioDocumentacion> createState() => _LaboratorioDocumentacionState();
}

class _LaboratorioDocumentacionState extends State<LaboratorioDocumentacion> {
  final LoteService _loteService = LoteService();
  final MuestraLaboratorioService _muestraService = MuestraLaboratorioService(); // NUEVO: Servicio independiente
  final FirebaseStorageService _storageService = FirebaseStorageService();
  bool _isLoading = false;

  void _showLaboratorioSuccessDialog() {
    HapticFeedback.lightImpact();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Column(
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFF9333EA), // Morado de laboratorio
                size: 60,
              ),
              const SizedBox(height: 16),
              const Text(
                'Documentación Cargada',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF9333EA), // Morado de laboratorio
                ),
              ),
            ],
          ),
          content: const Text(
            'Los documentos se han guardado correctamente',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Navegar a la gestión de muestras en la pestaña de finalizados
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LaboratorioGestionMuestras(
                        initialTab: 2, // Pestaña de Finalizados
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9333EA), // Morado de laboratorio
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Aceptar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _onDocumentsSubmitted(Map<String, DocumentInfo> documents) async {
    if (_isLoading) return; // Evitar múltiples envíos
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Preparar URLs de documentos
      Map<String, String> documentosUrls = {};
      
      // Subir documentos a Firebase Storage
      for (var entry in documents.entries) {
        final file = entry.value.file;
        if (file != null) {
          final url = await _storageService.uploadFile(
            file,
            'laboratorio/documentos/${widget.transformacionId ?? 'lotes'}',
          );
          if (url != null) {
            documentosUrls[entry.key] = url;
          }
        }
      }
      
      // NUEVO SISTEMA: Actualizar documentación usando el servicio independiente
      debugPrint('[LABORATORIO] Actualizando documentación con sistema independiente');
      debugPrint('[LABORATORIO] Muestra ID: ${widget.muestraId}');
      debugPrint('[LABORATORIO] Transformación ID: ${widget.transformacionId}');
      
      if (widget.transformacionId != null) {
        // Es una muestra de megalote - usar el sistema independiente
        // El método actualizarDocumentacion espera 2 parámetros posicionales
        await _muestraService.actualizarDocumentacion(
          widget.muestraId,
          documentosUrls, // Solo pasamos el mapa de documentos
        );
        
        debugPrint('[LABORATORIO] ✓ Documentación actualizada en sistema independiente');
        debugPrint('[LABORATORIO] Certificado: ${documentosUrls['certificado_analisis'] ?? 'No cargado'}');
        debugPrint('[LABORATORIO] Total documentos: ${documentosUrls.length}');
      } else {
        // Sistema antiguo (por compatibilidad)
        await _loteService.actualizarLoteLaboratorio(
          widget.muestraId,
          {
            'ecoce_laboratorio_documentos': documentosUrls.values.toList(),
            'ecoce_laboratorio_fecha_documentos': Timestamp.fromDate(DateTime.now()),
            'estado': 'finalizado',
          },
        );
      }
      
      // Mostrar diálogo de éxito y luego navegar
      if (mounted) {
        debugPrint('[LABORATORIO] Documentación completada, mostrando diálogo de éxito...');
        
        _showLaboratorioSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar documentos: ${e.toString()}'),
            backgroundColor: BioWayColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF9333EA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            // Botón de retroceso para salir sin guardar
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Documentación de Análisis',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          // Botón de cancelar adicional
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const LaboratorioGestionMuestras(
                    initialTab: 1, // Volver a documentación pendiente
                  ),
                ),
              );
            },
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          DocumentUploadPerRequirementWidget(
            title: 'Documentación de Análisis',
            subtitle: 'Carga el certificado de análisis de la muestra',
            lotId: widget.muestraId,
            requiredDocuments: const {
              'certificado_analisis': 'Certificado de Análisis de Laboratorio',
            },
            onDocumentsSubmitted: _onDocumentsSubmitted,
            primaryColor: const Color(0xFF9333EA), // Morado para laboratorio
            userType: 'laboratorio',
            showAppBar: false, // Evitar duplicación del AppBar
          ),
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF9333EA),
                ),
              ),
            ),
        ],
      ),
    );
  }
}