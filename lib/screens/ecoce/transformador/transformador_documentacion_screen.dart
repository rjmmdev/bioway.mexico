import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import '../shared/widgets/document_upload_per_requirement_widget.dart';

class TransformadorDocumentacionScreen extends StatelessWidget {
  final String? lotId;
  
  const TransformadorDocumentacionScreen({
    super.key,
    this.lotId,
  });

  void _onDocumentsSubmitted(BuildContext context, Map<String, DocumentInfo> documents) {
    // Mostrar mensaje de éxito
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Documentación guardada exitosamente'),
        backgroundColor: BioWayColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
    
    // Volver a la pantalla anterior
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return DocumentUploadPerRequirementWidget(
      title: 'Documentación',
      subtitle: 'Carga los documentos del proceso de transformación',
      lotId: lotId,
      requiredDocuments: const {
        'ficha_tecnica_pellet': 'Ficha técnica del pellet reciclado recibido',
        'resultados_mezcla_inicial': 'Resultados de prueba de mezcla inicial (pellet + virgen)',
        'resultados_transformacion': 'Resultados del proceso de transformación',
        'ficha_tecnica_mezcla_final': 'Ficha técnica de la mezcla final utilizada',
      },
      onDocumentsSubmitted: (documents) => _onDocumentsSubmitted(context, documents),
      primaryColor: BioWayColors.ecoceGreen,
      userType: 'transformador',
    );
  }
}