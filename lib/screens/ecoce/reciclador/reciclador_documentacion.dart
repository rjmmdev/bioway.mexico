import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/colors.dart';
import '../../../services/lote_service.dart';
import '../../../services/lote_unificado_service.dart';
import '../../../services/firebase/firebase_storage_service.dart';
import '../../../models/lotes/lote_reciclador_model.dart';
import 'reciclador_administracion_lotes_v2.dart';
import '../shared/widgets/document_upload_per_requirement_widget.dart';

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
  final LoteService _loteService = LoteService();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  
  LoteRecicladorModel? _loteReciclador;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadLoteData();
  }
  
  Future<void> _loadLoteData() async {
    try {
      final lotes = await _loteService.getLotesReciclador().first;
      _loteReciclador = lotes.firstWhere((l) => l.id == widget.lotId);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildDocumentUploadContent() {
    // Usar el widget sin su propio AppBar/Scaffold
    return DocumentUploadPerRequirementWidget(
      title: 'Documentación Técnica',
      subtitle: 'Carga un documento por cada requisito',
      lotId: widget.lotId,
      requiredDocuments: const {
        'ficha_tecnica': 'Ficha Técnica del Pellet',
        'reporte_reciclaje': 'Reporte de Resultados de Reciclaje',
      },
      onDocumentsSubmitted: _onDocumentsSubmitted,
      primaryColor: BioWayColors.ecoceGreen,
      userType: 'reciclador',
      showAppBar: false, // Desactivar el AppBar interno
    );
  }

  void _onDocumentsSubmitted(Map<String, DocumentInfo> documents) async {
    try {
      final loteUnificadoService = LoteUnificadoService();
      
      // Subir documentos a Firebase Storage
      Map<String, String> documentUrls = {};
      for (var entry in documents.entries) {
        if (entry.value.file != null) {
          final url = await _storageService.uploadFile(
            entry.value.file!,
            'lotes/reciclador/documentos',
          );
          if (url != null) {
            // Mapear según el tipo de documento
            if (entry.key == 'ficha_tecnica') {
              documentUrls['f_tecnica_pellet'] = url;
            } else if (entry.key == 'reporte_reciclaje') {
              documentUrls['rep_result_reci'] = url;
            }
          }
        }
      }
      
      // Actualizar el lote usando el servicio unificado
      await loteUnificadoService.actualizarDatosProceso(
        loteId: widget.lotId,
        proceso: 'reciclador',
        datos: {
          ...documentUrls,
          'fecha_documentos': FieldValue.serverTimestamp(),
        },
      );
      
      if (!mounted) return;
      
      // Mostrar diálogo de éxito
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
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
                  'Se han cargado ${documents.length} documentos exitosamente',
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
                  Navigator.of(dialogContext).pop();
                  
                  if (_loteReciclador != null) {
                    // Obtener el material predominante
                    String material = 'Mixto';
                    if (_loteReciclador!.tipoPoli != null && _loteReciclador!.tipoPoli!.isNotEmpty) {
                      material = _loteReciclador!.tipoPoli!.entries
                          .reduce((a, b) => a.value > b.value ? a : b)
                          .key;
                    }
                    
                    // Navegar a la pantalla de administración de lotes
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RecicladorAdministracionLotesV2(
                          initialTab: 1, // Pestaña Completados
                        ),
                      ),
                    );
                  }
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar documentos: ${e.toString()}'),
            backgroundColor: BioWayColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Center(
          child: CircularProgressIndicator(
            color: BioWayColors.ecoceGreen,
          ),
        ),
      );
    }
    
    return WillPopScope(
      onWillPop: () async {
        // Navegar a la pantalla de administración de lotes en la pestaña Completados
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const RecicladorAdministracionLotesV2(
              initialTab: 1, // Pestaña Completados
            ),
          ),
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: BioWayColors.ecoceGreen,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () {
              // Navegar a la pantalla de administración de lotes en la pestaña Completados
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const RecicladorAdministracionLotesV2(
                    initialTab: 1, // Pestaña Completados
                  ),
                ),
              );
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
          centerTitle: true,
        ),
        body: _buildDocumentUploadContent(),
      ),
    );
  }
}