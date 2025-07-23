import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../utils/colors.dart';
import '../utils/dialog_utils.dart';

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
        constraints: BoxConstraints(
          maxWidth: 400,
          minWidth: 280,
        ),
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
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: double.infinity),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cerrar'),
                  ),
                  SizedBox(width: 8),
                  Flexible(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context); // Close dialog first
                        await _openDocument(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BioWayColors.ecoceGreen,
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.open_in_new, size: 18),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Ver Documento',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDocument(BuildContext context) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          DialogUtils.showErrorDialog(
            context: context,
            title: 'Error',
            message: 'No se pudo abrir el documento',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        DialogUtils.showErrorDialog(
          context: context,
          title: 'Error',
          message: 'Error al abrir el documento: $e',
        );
      }
    }
  }
}