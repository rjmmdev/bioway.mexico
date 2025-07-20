import 'package:flutter/material.dart';
import '../../../../utils/colors.dart';

/// Diálogo para visualizar documentos
class DocumentViewerDialog extends StatelessWidget {
  final String title;
  final String url;

  const DocumentViewerDialog({
    super.key,
    required this.title,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.description,
              size: 64,
              color: BioWayColors.petBlue,
            ),
            SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: BioWayColors.darkGreen,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Documento disponible para revisión',
              style: TextStyle(
                fontSize: 14,
                color: BioWayColors.textGrey,
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: BioWayColors.backgroundGrey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.link,
                    size: 20,
                    color: BioWayColors.textGrey,
                  ),
                  SizedBox(height: 4),
                  Text(
                    url.length > 50 ? '${url.substring(0, 50)}...' : url,
                    style: TextStyle(
                      fontSize: 10,
                      color: BioWayColors.textGrey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cerrar'),
                ),
                SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implementar apertura del documento
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Abriendo documento...'),
                        backgroundColor: BioWayColors.ecoceGreen,
                      ),
                    );
                  },
                  icon: Icon(Icons.open_in_new),
                  label: Text('Ver Documento'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BioWayColors.ecoceGreen,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}