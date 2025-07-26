import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      print('Intentando abrir documento: $url');
      
      // Intentar abrir la URL directamente
      final uri = Uri.parse(url);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri, 
          mode: LaunchMode.externalApplication,
          webViewConfiguration: const WebViewConfiguration(
            enableJavaScript: true,
            enableDomStorage: true,
          ),
        );
      } else {
        throw Exception('No se pudo abrir la URL');
      }
    } catch (e) {
      print('Error al abrir documento: $e');
      
      if (context.mounted) {
        // Mostrar diálogo con opción de copiar URL
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('No se pudo abrir el documento'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Puede copiar la URL e intentar abrirla en su navegador:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: SelectableText(
                    url,
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cerrar'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: url));
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('URL copiada al portapapeles'),
                        backgroundColor: BioWayColors.success,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copiar URL'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BioWayColors.ecoceGreen,
                ),
              ),
            ],
          ),
        );
      }
    }
  }
}