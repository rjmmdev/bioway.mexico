import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import 'reciclador_lote_qr_screen.dart';
import '../shared/widgets/document_upload_per_requirement_widget.dart';

class RecicladorDocumentacion extends StatelessWidget {
  final String lotId;
  
  const RecicladorDocumentacion({
    super.key,
    required this.lotId,
  });

  void _onDocumentsSubmitted(BuildContext context, Map<String, DocumentInfo> documents) {
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
                      loteId: lotId,
                      material: 'PET', // En producción vendría de la base de datos
                      pesoOriginal: 100.0, // En producción vendría de la base de datos
                      presentacion: 'Pacas', // En producción vendría de la base de datos
                      origen: 'Acopiador Norte', // En producción vendría de la base de datos
                      fechaEntrada: DateTime.now().subtract(const Duration(days: 2)),
                      fechaSalida: DateTime.now(),
                      documentosCargados: documents.values.map((doc) => doc.fileName).toList(),
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
    return DocumentUploadPerRequirementWidget(
      title: 'Documentación Técnica',
      subtitle: 'Carga un documento por cada requisito',
      lotId: lotId,
      requiredDocuments: const {
        'ficha_tecnica': 'Ficha Técnica del Pellet',
        'reporte_reciclaje': 'Reporte de Resultados de Reciclaje',
      },
      onDocumentsSubmitted: (documents) => _onDocumentsSubmitted(context, documents),
      primaryColor: BioWayColors.ecoceGreen,
      userType: 'reciclador',
    );
  }
}