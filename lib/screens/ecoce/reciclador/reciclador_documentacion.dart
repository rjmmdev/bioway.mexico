import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/colors.dart';
import '../../../services/lote_service.dart';
import '../../../services/firebase/firebase_storage_service.dart';
import '../../../models/lotes/lote_reciclador_model.dart';
import 'reciclador_lote_qr_screen.dart';
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
      // Subir documentos a Firebase Storage
      List<String> documentUrls = [];
      for (var doc in documents.values) {
        if (doc.file != null) {
          final url = await _storageService.uploadFile(
            doc.file!,
            'lotes/reciclador/documentos',
          );
          if (url != null) {
            documentUrls.add(url);
          }
        }
      }
      
      // Actualizar el lote con los documentos
      await _loteService.actualizarLoteReciclador(
        widget.lotId,
        {
          'ecoce_reciclador_documentos': documentUrls,
          'ecoce_reciclador_fecha_documentos': Timestamp.fromDate(DateTime.now()),
          'estado': 'finalizado',
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
                    
                    // Navegar directamente a la pantalla de QR mostrando el éxito
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecicladorLoteQRScreen(
                          loteId: widget.lotId,
                          material: material,
                          pesoOriginal: _loteReciclador!.pesoBruto ?? 0.0,
                          pesoFinal: _loteReciclador!.pesoResultante ?? _loteReciclador!.pesoBruto ?? 0.0,
                          presentacion: 'Pacas', // Default presentation for reciclador
                          origen: 'Reciclador',
                          fechaEntrada: DateTime.now(), // We don't have this field, using current date
                          fechaSalida: DateTime.now(),
                          documentosCargados: documents.values.map((doc) => doc.fileName).toList(),
                          mostrarMensajeExito: true,
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
        // Actualizar estado del lote a 'enviado' cuando se pospone la documentación
        await _loteService.actualizarLoteReciclador(
          widget.lotId,
          {'estado': 'enviado'},
        );
        
        // Navegar a la pantalla de administración de lotes en la pestaña de documentación
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/reciclador_lotes',
          (route) => route.isFirst,
          arguments: {'initialTab': 1}, // Pestaña de documentación
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
            onPressed: () async {
              // Actualizar estado del lote a 'enviado' cuando se pospone la documentación
              await _loteService.actualizarLoteReciclador(
                widget.lotId,
                {'estado': 'enviado'},
              );
              
              // Navegar a la pantalla de administración de lotes en la pestaña de documentación
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/reciclador_lotes',
                (route) => route.isFirst,
                arguments: {'initialTab': 1}, // Pestaña de documentación
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