import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/colors.dart';
import '../../../services/lote_service.dart';
import '../../../services/firebase/firebase_storage_service.dart';
import 'laboratorio_gestion_muestras.dart';
import '../shared/widgets/document_upload_per_requirement_widget.dart';

class LaboratorioDocumentacion extends StatelessWidget {
  final String muestraId;
  final String? transformacionId;
  
  LaboratorioDocumentacion({
    super.key,
    required this.muestraId,
    this.transformacionId,
  });
  
  final LoteService _loteService = LoteService();
  final FirebaseStorageService _storageService = FirebaseStorageService();

  void _onDocumentsSubmitted(BuildContext context, Map<String, DocumentInfo> documents) async {
    try {
      // Preparar URLs de documentos
      Map<String, String> documentosUrls = {};
      
      // Subir documentos a Firebase Storage
      for (var entry in documents.entries) {
        if (entry.value.file != null) {
          final url = await _storageService.uploadFile(
            entry.value.file!,
            'laboratorio/documentos/${transformacionId ?? 'lotes'}',
          );
          if (url != null) {
            documentosUrls[entry.key] = url;
          }
        }
      }
      
      // Si hay transformacionId, actualizar la muestra del megalote
      if (transformacionId != null) {
        // Obtener la transformación actual
        final transformacionDoc = await FirebaseFirestore.instance
            .collection('transformaciones')
            .doc(transformacionId)
            .get();
            
        if (transformacionDoc.exists) {
          final muestrasLab = List<Map<String, dynamic>>.from(
            transformacionDoc.data()!['muestras_laboratorio'] ?? []
          );
          
          // Buscar la muestra y actualizarla
          final muestraIndex = muestrasLab.indexWhere((m) => m['id'] == muestraId);
          if (muestraIndex != -1) {
            muestrasLab[muestraIndex] = {
              ...muestrasLab[muestraIndex],
              'certificado': documentosUrls['certificado_analisis'] ?? '',
              'documentos': documentosUrls,
              'fecha_documentos': FieldValue.serverTimestamp(),
            };
            
            // Actualizar la transformación
            await FirebaseFirestore.instance
                .collection('transformaciones')
                .doc(transformacionId)
                .update({
              'muestras_laboratorio': muestrasLab,
            });
          }
        }
      } else {
        // Sistema antiguo (por compatibilidad)
        await _loteService.actualizarLoteLaboratorio(
          muestraId,
          {
            'ecoce_laboratorio_documentos': documentosUrls.values.toList(),
            'ecoce_laboratorio_fecha_documentos': Timestamp.fromDate(DateTime.now()),
            'estado': 'finalizado',
          },
        );
      }
      
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
      subtitle: 'Carga el certificado de análisis de la muestra',
      lotId: muestraId,
      requiredDocuments: const {
        'certificado_analisis': 'Certificado de Análisis de Laboratorio',
      },
      onDocumentsSubmitted: (documents) => _onDocumentsSubmitted(context, documents),
      primaryColor: const Color(0xFF9333EA), // Morado para laboratorio
      userType: 'laboratorio',
    );
  }
}