import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import '../../../../utils/colors.dart';
import '../../../../utils/format_utils.dart';
import '../utils/material_utils.dart';

/// Widget compartido para mostrar códigos QR con información de lotes
/// Puede ser utilizado por cualquier tipo de usuario del sistema
class QRCodeDisplayWidget extends StatefulWidget {
  // Información básica del lote
  final String loteId;
  final String material;
  final double peso;
  final String presentacion;
  final String origen;
  final DateTime? fechaCreacion;
  
  // Información adicional opcional
  final double? pesoFinal;
  final DateTime? fechaSalida;
  final Map<String, dynamic>? datosAdicionales;
  final List<String>? documentos;
  
  // Personalización
  final String titulo;
  final String subtitulo;
  final Color colorPrincipal;
  final IconData? iconoPrincipal;
  final bool mostrarSeccionDocumentos;
  final bool mostrarPesoFinal;
  final String? tipoUsuario;
  
  // Callbacks
  final VoidCallback? onDescargar;
  final VoidCallback? onImprimir;
  final VoidCallback? onCompartir;

  const QRCodeDisplayWidget({
    super.key,
    required this.loteId,
    required this.material,
    required this.peso,
    required this.presentacion,
    required this.origen,
    this.fechaCreacion,
    this.pesoFinal,
    this.fechaSalida,
    this.datosAdicionales,
    this.documentos,
    this.titulo = 'Código QR del Lote',
    this.subtitulo = 'QR Code',
    this.colorPrincipal = const Color(0xFF4CAF50),
    this.iconoPrincipal,
    this.mostrarSeccionDocumentos = false,
    this.mostrarPesoFinal = false,
    this.tipoUsuario,
    this.onDescargar,
    this.onImprimir,
    this.onCompartir,
  });

  @override
  State<QRCodeDisplayWidget> createState() => _QRCodeDisplayWidgetState();
}

class _QRCodeDisplayWidgetState extends State<QRCodeDisplayWidget> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isProcessing = false;

  String get _fechaFormateada {
    return FormatUtils.formatDate(widget.fechaCreacion ?? DateTime.now());
  }

  String get _fechaSalidaFormateada {
    return FormatUtils.formatDate(widget.fechaSalida ?? DateTime.now());
  }

  String get _qrData {
    final Map<String, dynamic> qrInfo = {
      'loteId': widget.loteId,
      'material': widget.material,
      'peso': widget.peso,
      'presentacion': widget.presentacion,
      'origen': widget.origen,
      'fechaCreacion': _fechaFormateada,
      if (widget.pesoFinal != null) 'pesoFinal': widget.pesoFinal,
      if (widget.fechaSalida != null) 'fechaSalida': _fechaSalidaFormateada,
      if (widget.datosAdicionales != null) ...widget.datosAdicionales!,
      if (widget.documentos != null && widget.documentos!.isNotEmpty) 'documentos': widget.documentos,
      if (widget.tipoUsuario != null) 'procesadoPor': widget.tipoUsuario,
    };
    
    return qrInfo.toString();
  }

  Future<void> _descargarQR() async {
    if (_isProcessing) return;
    
    setState(() => _isProcessing = true);
    
    try {
      // Capturar el widget del QR
      final Uint8List? image = await _screenshotController.capture();
      if (image == null) {
        throw Exception('Error al capturar el código QR');
      }
      
      // Guardar directamente en el dispositivo
      await _guardarDirectamente(image);
      
      // Llamar callback personalizado si existe
      if (widget.onDescargar != null) {
        widget.onDescargar!();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: BioWayColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _guardarDirectamente(Uint8List image) async {
    try {
      // Verificar y solicitar permisos primero
      await _solicitarPermisos();
      
      // Mostrar mensaje de progreso
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('Guardando en galería...'),
              ],
            ),
            backgroundColor: BioWayColors.info,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
      
      // Guardar la imagen temporalmente primero
      final tempDir = await getTemporaryDirectory();
      final fileName = 'QR_${widget.loteId}_${DateTime.now().millisecondsSinceEpoch}.png';
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(image);
      
      // Usar Gal para guardar directamente en la galería
      await Gal.putImage(tempFile.path, album: 'BioWay México');
      
      print('✅ DEBUG - Imagen guardada en galería exitosamente');
      
      // Eliminar archivo temporal
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('QR guardado en galería'),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  Platform.isAndroid 
                    ? 'Guardado en el álbum "BioWay México"'
                    : 'Guardado en tu app Fotos',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: BioWayColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Abrir Galería',
              textColor: Colors.white,
              onPressed: () async {
                try {
                  await Gal.open();
                } catch (e) {
                  print('No se pudo abrir la galería: $e');
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ DEBUG - Error al guardar: $e');
      // Si hay error, intentar método alternativo
      await _guardarConMetodoAlternativo(image);
    }
  }
  
  
  
  Future<void> _solicitarPermisos() async {
    // Verificar si Gal tiene acceso
    final hasAccess = await Gal.hasAccess();
    print('🔍 DEBUG - Gal hasAccess: $hasAccess');
    
    if (!hasAccess) {
      // Solicitar acceso
      final granted = await Gal.requestAccess();
      print('🔍 DEBUG - Gal requestAccess result: $granted');
      
      if (!granted) {
        throw Exception('Se requiere permiso para guardar imágenes en la galería');
      }
    }
    
    print('✅ DEBUG - Permisos de galería verificados');
  }
  
  Future<String> _getAppName() async {
    // Placeholder for app name - you can get this from package info if needed
    return 'BioWay México';
  }

  Future<void> _guardarConMetodoAlternativo(Uint8List image) async {
    try {
      // Método alternativo: crear archivo y mostrar opciones al usuario
      final tempDir = await getTemporaryDirectory();
      final fileName = 'QR_${widget.loteId}_${DateTime.now().millisecondsSinceEpoch}.png';
      final tempFile = File('${tempDir.path}/$fileName');
      
      await tempFile.writeAsBytes(image);
      
      if (mounted) {
        // Mostrar diálogo con opciones
        final action = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning_amber, color: BioWayColors.warning),
                const SizedBox(width: 8),
                const Text('Guardar QR'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('No se pudo guardar automáticamente en la galería.'),
                const SizedBox(height: 16),
                const Text('Opciones disponibles:'),
                const SizedBox(height: 8),
                Text('1. Compartir y guardar manualmente', style: TextStyle(color: BioWayColors.textGrey)),
                Text('2. Verificar permisos de la app', style: TextStyle(color: BioWayColors.textGrey)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'cancel'),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context, 'settings');
                  try {
                    await openAppSettings();
                  } catch (e) {
                    print('Error abriendo configuración: $e');
                  }
                },
                child: const Text('Ver Permisos'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, 'share'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BioWayColors.ecoceGreen,
                ),
                child: const Text('Compartir', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
        
        if (action == 'share') {
          // Compartir con instrucciones específicas
          await Share.shareXFiles(
            [XFile(tempFile.path)],
            text: '''🔻 PARA GUARDAR EN GALERÍA:

Android:
• Abre el menú que aparece
• Busca "Galería", "Fotos" o "Archivos"
• Selecciona "Guardar" o toca el ícono de descarga

📱 Código QR - Lote ${widget.loteId}
📦 Material: ${widget.material}
⚖️ Peso: ${widget.peso} kg''',
            subject: 'QR Code - Lote ${widget.loteId}',
          );
          
          // Mostrar mensaje de seguimiento
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📤 QR compartido'),
                    Text(
                      'Usa la aplicación que aparece para guardarlo en galería',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                backgroundColor: BioWayColors.info,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        } else if (action == 'settings') {
          // Mostrar instrucciones para verificar permisos
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('⚙️ Verificar permisos'),
                    Text(
                      'Ve a Configuración > Apps > BioWay México > Permisos > Almacenamiento',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                backgroundColor: BioWayColors.warning,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                duration: const Duration(seconds: 6),
              ),
            );
          }
        }
      }
      
      // Limpiar archivo temporal
      Future.delayed(const Duration(seconds: 90), () {
        if (tempFile.existsSync()) {
          tempFile.deleteSync();
        }
      });
    } catch (e) {
      throw Exception('No se pudo procesar la imagen: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  Future<void> _compartirImagen(Uint8List image) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/QR_${widget.loteId}_${DateTime.now().millisecondsSinceEpoch}.png');
      await tempFile.writeAsBytes(image);
      
      // Crear texto detallado para compartir
      final String shareText = '''
Código QR - Lote ${widget.loteId}
Material: ${widget.material}
Peso: ${widget.peso} kg
Presentación: ${widget.presentacion}
Origen: ${widget.origen}
Fecha: $_fechaFormateada${widget.pesoFinal != null ? '\nPeso Final: ${widget.pesoFinal} kg' : ''}${widget.fechaSalida != null ? '\nFecha Salida: $_fechaSalidaFormateada' : ''}
      ''';
      
      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: shareText,
        subject: 'Código QR - Lote ${widget.loteId}',
      );
      
      // Limpiar archivo temporal después de un delay
      Future.delayed(const Duration(seconds: 10), () {
        if (tempFile.existsSync()) {
          tempFile.deleteSync();
        }
      });
    } catch (e) {
      throw Exception('Error al compartir: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  Future<void> _imprimirQR() async {
    if (_isProcessing) return;
    
    setState(() => _isProcessing = true);
    
    try {
      // Capturar el widget del QR
      final Uint8List? image = await _screenshotController.capture();
      if (image == null) {
        throw Exception('Error al capturar el código QR');
      }
      
      // Crear un documento PDF
      final pdf = pw.Document();
      
      final pdfImage = pw.MemoryImage(image);
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'Código QR - Lote ${widget.loteId}',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Container(
                    width: 300,
                    height: 300,
                    child: pw.Image(pdfImage),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text('Material: ${widget.material}'),
                  pw.Text('Peso: ${widget.peso} kg'),
                  pw.Text('Presentación: ${widget.presentacion}'),
                  pw.Text('Origen: ${widget.origen}'),
                  pw.Text('Fecha: $_fechaFormateada'),
                ],
              ),
            );
          },
        ),
      );
      
      // Imprimir el PDF
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'QR_${widget.loteId}',
      );
      
      // Llamar callback personalizado si existe
      if (widget.onImprimir != null) {
        widget.onImprimir!();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al imprimir: $e'),
            backgroundColor: BioWayColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _compartirQR() async {
    if (_isProcessing) return;
    
    setState(() => _isProcessing = true);
    
    try {
      // Capturar el widget del QR
      final Uint8List? image = await _screenshotController.capture();
      if (image == null) {
        throw Exception('Error al capturar el código QR');
      }
      
      // Compartir directamente usando la función compartir
      await _compartirImagen(image);
      
      // Llamar callback personalizado si existe
      if (widget.onCompartir != null) {
        widget.onCompartir!();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al compartir: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: BioWayColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Color _getMaterialColor(String material) {
    return MaterialUtils.getMaterialColor(material);
  }

  IconData _getMaterialIcon(String material) {
    return MaterialUtils.getMaterialIcon(material);
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final horizontalPadding = isSmallScreen ? 16.0 : 24.0;
    
    return Container(
      padding: EdgeInsets.all(horizontalPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Título con icono opcional
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.iconoPrincipal != null) ...[
                Icon(
                  widget.iconoPrincipal,
                  color: widget.colorPrincipal,
                  size: 24,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                widget.titulo,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // QR Code Container
          Screenshot(
            controller: _screenshotController,
            child: Container(
              width: 200,
              height: 200,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.colorPrincipal.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: QrImageView(
                data: _qrData,
                version: QrVersions.auto,
                size: 184,
                backgroundColor: Colors.white,
                errorCorrectionLevel: QrErrorCorrectLevel.H,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // ID del lote
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: widget.colorPrincipal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.colorPrincipal.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.fingerprint,
                  color: widget.colorPrincipal,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.loteId,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.colorPrincipal.withValues(alpha: 0.9),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: isSmallScreen ? 24 : 32),
          
          // Información del lote
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  icon: _getMaterialIcon(widget.material),
                  label: 'Material',
                  value: widget.material,
                  color: _getMaterialColor(widget.material),
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  icon: Icons.scale_outlined,
                  label: widget.mostrarPesoFinal ? 'Peso Original' : 'Peso',
                  value: '${widget.peso} kg',
                  color: Colors.blue,
                ),
                if (widget.mostrarPesoFinal && widget.pesoFinal != null) ...[
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    icon: Icons.compress,
                    label: 'Peso Final',
                    value: '${widget.pesoFinal} kg',
                    color: Colors.indigo,
                  ),
                ],
                const SizedBox(height: 16),
                _buildPresentacionRow(
                  label: 'Presentación',
                  value: widget.presentacion,
                  color: Colors.green,
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  icon: widget.tipoUsuario == 'origen' ? Icons.factory_outlined : Icons.location_on_outlined,
                  label: widget.tipoUsuario == 'origen' ? 'Fuente' : 'Origen',
                  value: widget.origen,
                  color: Colors.purple,
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Fecha de creación',
                  value: _fechaFormateada,
                  color: Colors.orange,
                ),
                if (widget.fechaSalida != null) ...[
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    icon: Icons.logout,
                    label: 'Fecha de salida',
                    value: _fechaSalidaFormateada,
                    color: BioWayColors.success,
                  ),
                ],
                if (widget.mostrarSeccionDocumentos && widget.documentos != null && widget.documentos!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    icon: Icons.folder_copy,
                    label: 'Documentación',
                    value: '${widget.documentos!.length} archivos',
                    color: BioWayColors.info,
                  ),
                ],
              ],
            ),
          ),
          
          SizedBox(height: isSmallScreen ? 24 : 32),
          
          // Botones de acción
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _descargarQR,
                  icon: Icon(Icons.download, size: isSmallScreen ? 18 : 20),
                  label: Text(
                    isSmallScreen ? 'Descargar' : 'Descargar QR',
                    style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.colorPrincipal,
                    padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              SizedBox(width: isSmallScreen ? 8 : 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isProcessing ? null : _imprimirQR,
                  icon: Icon(Icons.print, size: isSmallScreen ? 18 : 20),
                  label: Text(
                    'Imprimir',
                    style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color: Colors.grey[400]!,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: _isProcessing ? null : _compartirQR,
              icon: const Icon(Icons.share),
              label: const Text('Compartir'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: color,
            size: 22,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPresentacionRow({
    required String label,
    required String value,
    required Color color,
  }) {
    final svgPath = value == 'Pacas' 
        ? 'assets/images/icons/pacas.svg' 
        : 'assets/images/icons/sacos.svg';
        
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: SvgPicture.asset(
              svgPath,
              width: 22,
              height: 22,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}