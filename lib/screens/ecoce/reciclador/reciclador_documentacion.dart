import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import 'reciclador_lote_qr_screen.dart';
import '../shared/widgets/document_upload_widget.dart';

class RecicladorDocumentacion extends StatelessWidget {
  final String? lotId;
  final Map<String, dynamic>? loteData;
  
  const RecicladorDocumentacion({
    super.key,
    this.lotId,
    this.loteData,
  }) : assert(lotId != null || loteData != null, 'Either lotId or loteData must be provided');

  void _onDocumentsSubmitted(BuildContext context, List<DocumentInfo> documents) {
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
                // Navegar directamente a la pantalla de QR mostrando el éxito
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecicladorLoteQRScreen(
                      loteId: lotId ?? loteData?['id'] ?? '',
                      material: 'PET', // En producción vendría de la base de datos
                      pesoOriginal: 100.0, // En producción vendría de la base de datos
                      presentacion: 'Pacas', // En producción vendría de la base de datos
                      origen: 'Acopiador Norte', // En producción vendría de la base de datos
                      fechaEntrada: DateTime.now().subtract(const Duration(days: 2)),
                      fechaSalida: DateTime.now(),
                      documentosCargados: documents.map((doc) => doc.fileName).toList(),
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

  @override
  Widget build(BuildContext context) {
    return DocumentUploadWidget(
      title: 'Documentación Técnica',
      subtitle: 'Carga los documentos técnicos',
      lotId: lotId ?? loteData?['id'] ?? '',
      requiredDocuments: const [
        'Ficha Técnica del Pellet',
        'Reporte de Resultados de Reciclaje',
      ],
      onDocumentsSubmitted: (documents) => _onDocumentsSubmitted(context, documents),
      primaryColor: BioWayColors.ecoceGreen,
      userType: 'reciclador',
      additionalInfoText: 'Mínimo 1 documento requerido, máximo 2 documentos permitidos',
      minDocuments: 1,
      maxDocuments: 2,
    );
  }
}