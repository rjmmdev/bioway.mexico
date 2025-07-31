import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/firebase/firebase_storage_service.dart';
import 'colors.dart';

class DocumentUtils {
  static final FirebaseStorageService _storageService = FirebaseStorageService();
  
  // Intentar abrir documento con múltiples estrategias
  static Future<void> openDocument({
    required BuildContext context,
    required String? url,
    required String documentName,
  }) async {
    if (url == null || url.isEmpty) {
      _showErrorDialog(
        context: context,
        title: 'Documento no disponible',
        message: 'El documento "$documentName" no está disponible.',
      );
      return;
    }

    // Mostrar indicador de carga mientras se obtiene la URL válida
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    String? validUrl = url;
    
    // Si es una URL de Firebase Storage, obtener una con token válido
    if (url.contains('firebasestorage.googleapis.com')) {
      try {
        validUrl = await _storageService.getValidDownloadUrl(url);
        if (validUrl == null) {
          throw Exception('No se pudo obtener URL válida');
        }
      } catch (e) {
        print('Error obteniendo URL válida: $e');
        // Continuar con la URL original
        validUrl = url;
      }
    }
    
    // Cerrar el indicador de carga
    if (context.mounted) {
      Navigator.of(context).pop();
    }

    // Estrategia 1: Intentar abrir directamente en navegador externo
    try {
      final uri = Uri.parse(validUrl);
      
      // Para URLs de Firebase Storage, usar siempre modo externo
      if (validUrl.contains('firebasestorage.googleapis.com')) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        
        if (launched) return;
      } else {
        // Para otras URLs, usar modo estándar
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
          return;
        }
      }
    } catch (e) {
      print('Error al abrir documento con url_launcher: $e');
    }

    // Estrategia 2: Si falla, mostrar diálogo con opciones
    if (context.mounted) {
      _showDocumentOptionsDialog(
        context: context,
        url: validUrl,
        documentName: documentName,
      );
    }
  }

  static void _showErrorDialog({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: BioWayColors.error),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  static void _showDocumentOptionsDialog({
    required BuildContext context,
    required String url,
    required String documentName,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Abrir Documento'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Documento: $documentName',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'No se pudo abrir el documento automáticamente.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              const Text(
                'Opciones disponibles:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '1. Copie la URL y ábrala manualmente en su navegador',
                style: TextStyle(fontSize: 14),
              ),
              const Text(
                '2. Si el problema persiste, contacte al administrador',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'URL del documento:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      url,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Instrucciones adicionales para Firebase Storage
              if (url.contains('firebasestorage.googleapis.com')) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: BioWayColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: BioWayColors.info.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, 
                            color: BioWayColors.info, 
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Nota importante',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: BioWayColors.info,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Si ve un error de permisos (403):\n'
                        '• Asegúrese de estar conectado a internet\n'
                        '• Intente cerrar sesión y volver a iniciar\n'
                        '• El enlace puede haber expirado',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
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
                    duration: Duration(seconds: 2),
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

  // Verificar si una URL parece ser válida
  static bool isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  // Obtener el tipo de documento desde la URL
  static String getDocumentType(String url) {
    final extension = url.split('.').last.toLowerCase().split('?').first;
    
    switch (extension) {
      case 'pdf':
        return 'PDF';
      case 'jpg':
      case 'jpeg':
        return 'Imagen JPEG';
      case 'png':
        return 'Imagen PNG';
      case 'doc':
        return 'Documento Word';
      case 'docx':
        return 'Documento Word';
      default:
        return 'Documento';
    }
  }
}