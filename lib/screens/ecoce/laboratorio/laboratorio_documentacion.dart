import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/colors.dart';
import '../../../services/lote_service.dart';
import '../../../services/firebase/firebase_storage_service.dart';
import 'laboratorio_gestion_muestras.dart';
import '../shared/widgets/document_upload_per_requirement_widget.dart';

class LaboratorioDocumentacion extends StatelessWidget {
  final String muestraId;
  
  LaboratorioDocumentacion({
    super.key,
    required this.muestraId,
  });
  
  final LoteService _loteService = LoteService();
  final FirebaseStorageService _storageService = FirebaseStorageService();

  void _onDocumentsSubmitted(BuildContext context, Map<String, DocumentInfo> documents) async {
    try {
      // Subir documentos a Firebase Storage
      List<String> documentUrls = [];
      for (var doc in documents.values) {
        if (doc.file != null) {
          final url = await _storageService.uploadFile(
            doc.file!,
            'lotes/laboratorio/documentos',
          );
          if (url != null) {
            documentUrls.add(url);
          }
        }
      }
      
      // Actualizar el lote con los documentos
      await _loteService.actualizarLoteLaboratorio(
        muestraId,
        {
          'ecoce_laboratorio_documentos': documentUrls,
          'ecoce_laboratorio_fecha_documentos': Timestamp.fromDate(DateTime.now()),
          'estado': 'finalizado',
        },
      );
      
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
                // Navegar a la gestión de muestras en la pestaña de finalizados
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LaboratorioGestionMuestras(
                      initialTab: 2, // Pestaña de Finalizados
                    ),
                  ),
                  (route) => route.isFirst,
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar documentos: ${e.toString()}'),
          backgroundColor: BioWayColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DocumentUploadPerRequirementWidget(
      title: 'Documentación de Análisis',
      subtitle: 'Carga un documento por cada requisito',
      lotId: muestraId,
      requiredDocuments: const {
        'informe_tecnico': 'Informe Técnico o Ficha Técnica',
      },
      onDocumentsSubmitted: (documents) => _onDocumentsSubmitted(context, documents),
      primaryColor: BioWayColors.ecoceGreen,
      userType: 'laboratorio',
    );
  }
}