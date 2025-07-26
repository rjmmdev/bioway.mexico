import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../models/maestro/documento_usuario.dart';
import '../../../../utils/colors.dart';

/// Dialog reutilizable para visualizar documentos
/// Soporta imágenes y PDFs con manejo de errores
class DocumentViewerDialog extends StatefulWidget {
  final DocumentoUsuario documento;
  final Color headerColor;
  final String? headerTitle;

  const DocumentViewerDialog({
    super.key,
    required this.documento,
    this.headerColor = BioWayColors.ecoceGreen,
    this.headerTitle,
  });

  @override
  State<DocumentViewerDialog> createState() => _DocumentViewerDialogState();
}

class _DocumentViewerDialogState extends State<DocumentViewerDialog> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.headerColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.documento.icon,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.headerTitle ?? widget.documento.nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Contenido
            Expanded(
              child: Container(
                color: Colors.grey[100],
                child: _buildDocumentViewer(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentViewer() {
    if (widget.documento.isImage) {
      return _buildImageViewer();
    } else if (widget.documento.isPDF) {
      return _buildPDFViewer();
    } else {
      return _buildUnsupportedViewer();
    }
  }

  Widget _buildImageViewer() {
    return InteractiveViewer(
      panEnabled: true,
      boundaryMargin: const EdgeInsets.all(20),
      minScale: 0.5,
      maxScale: 4.0,
      child: Center(
        child: Image.network(
          widget.documento.path,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorWidget('Error al cargar la imagen');
          },
        ),
      ),
    );
  }

  Widget _buildPDFViewer() {
    // Placeholder para visor de PDF
    // En producción, usar un paquete como flutter_pdfview
    return Builder(
      builder: (context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.picture_as_pdf,
              size: 100,
              color: Colors.red[700],
            ),
            const SizedBox(height: 16),
            Text(
              'Vista previa de PDF',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.documento.nombre,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: const Text('Abrir PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: BioWayColors.primaryGreen,
              ),
              onPressed: () async {
                try {
                  final uri = Uri.parse(widget.documento.path);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    if (context.mounted) {
                      // Mostrar diálogo para copiar URL
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
                                  widget.documento.path,
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
                                await Clipboard.setData(ClipboardData(text: widget.documento.path));
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
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al abrir PDF: $e'),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnsupportedViewer() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.orange[700],
          ),
          const SizedBox(height: 16),
          Text(
            'Tipo de archivo no soportado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tipo: ${widget.documento.tipo}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error,
            size: 80,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  /// Método estático para mostrar el diálogo fácilmente
  static void show({
    required BuildContext context,
    required DocumentoUsuario documento,
    Color? headerColor,
    String? headerTitle,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DocumentViewerDialog(
          documento: documento,
          headerColor: headerColor ?? BioWayColors.ecoceGreen,
          headerTitle: headerTitle,
        );
      },
    );
  }
}