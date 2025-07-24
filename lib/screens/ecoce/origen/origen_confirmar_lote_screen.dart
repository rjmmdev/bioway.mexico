import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../../../utils/colors.dart';
import '../../../services/lote_unificado_service.dart';
import '../../../services/firebase/firebase_storage_service.dart';
import '../../../services/user_session_service.dart';
import '../shared/utils/dialog_utils.dart';
import '../shared/widgets/signature_painter.dart';
import 'origen_config.dart';
import 'origen_lote_detalle_screen.dart';
import 'dart:ui' as ui;

class OrigenConfirmarLoteScreen extends StatefulWidget {
  final String tipoPolimero;
  final String presentacion;
  final String fuente;
  final bool isPostConsumo;
  final bool isPreConsumo;
  final double peso;
  final String condiciones;
  final String nombreOperador;
  final String? comentarios;
  final List<Offset?> signaturePoints;
  final List<File> photoFiles;

  const OrigenConfirmarLoteScreen({
    super.key,
    required this.tipoPolimero,
    required this.presentacion,
    required this.fuente,
    required this.isPostConsumo,
    required this.isPreConsumo,
    required this.peso,
    required this.condiciones,
    required this.nombreOperador,
    this.comentarios,
    required this.signaturePoints,
    required this.photoFiles,
  });

  @override
  State<OrigenConfirmarLoteScreen> createState() => _OrigenConfirmarLoteScreenState();
}

class _OrigenConfirmarLoteScreenState extends State<OrigenConfirmarLoteScreen> {
  final LoteUnificadoService _loteUnificadoService = LoteUnificadoService();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  final UserSessionService _userSession = UserSessionService();
  
  bool _isLoading = false;
  Color get _primaryColor => OrigenUserConfig.current.color;

  String get _tipoOrigen {
    if (widget.isPostConsumo && widget.isPreConsumo) {
      return 'Post-consumo y Pre-consumo';
    } else if (widget.isPostConsumo) {
      return 'Post-consumo';
    } else if (widget.isPreConsumo) {
      return 'Pre-consumo';
    }
    return '';
  }

  Future<File?> _captureSignature() async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, 300, 200));
      
      // Fondo blanco
      canvas.drawRect(
        Rect.fromLTWH(0, 0, 300, 200),
        Paint()..color = Colors.white,
      );

      // Dibujar la firma
      final paint = Paint()
        ..color = Colors.black
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < widget.signaturePoints.length - 1; i++) {
        if (widget.signaturePoints[i] != null && widget.signaturePoints[i + 1] != null) {
          canvas.drawLine(widget.signaturePoints[i]!, widget.signaturePoints[i + 1]!, paint);
        }
      }

      final picture = recorder.endRecording();
      final img = await picture.toImage(300, 200);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        final buffer = byteData.buffer.asUint8List();
        
        // Guardar temporalmente
        final tempDir = await Directory.systemTemp.createTemp();
        final file = File('${tempDir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png');
        await file.writeAsBytes(buffer);
        
        return file;
      }
      
      return null;
    } catch (e) {
      print('Error al capturar firma: $e');
      return null;
    }
  }

  void _mostrarDialogoConfirmacion() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: BioWayColors.warning,
                size: 32,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Confirmar Creación de Lote',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: BioWayColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: BioWayColors.warning.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: BioWayColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Los lotes creados NO se pueden borrar ni modificar',
                        style: TextStyle(
                          color: BioWayColors.warning,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '¿Estás seguro de que todos los datos son correctos?',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'Al continuar, confirmas que:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildCheckItem('Los datos del material son correctos'),
              _buildCheckItem('El peso registrado es preciso'),
              _buildCheckItem('La firma y evidencias son válidas'),
              _buildCheckItem('Entiendes que esta acción es irreversible'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _crearLote();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Crear Lote',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 14)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _crearLote() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Capturar firma como imagen
      File? signatureFile = await _captureSignature();
      String? signatureUrl;
      
      if (signatureFile != null) {
        signatureUrl = await _storageService.uploadImage(
          signatureFile,
          'firmas/origen',
        );
      }

      // Subir fotos de evidencia
      List<String> photoUrls = [];
      for (int i = 0; i < widget.photoFiles.length; i++) {
        final url = await _storageService.uploadImage(
          widget.photoFiles[i],
          'evidencias/origen',
        );
        if (url != null) {
          photoUrls.add(url);
        }
      }

      // Obtener datos del usuario con perfil completo
      final userData = _userSession.getUserData();
      final userProfile = await _userSession.getUserProfile();
      
      print('=== DATOS DEL USUARIO ===');
      print('userData: $userData');
      print('userProfile: $userProfile');
      print('Dirección obtenida: ${userProfile?['direccion']}');
      print('======================');

      // Crear el lote usando el servicio unificado
      final loteId = await _loteUnificadoService.crearLoteDesdeOrigen(
        tipoMaterial: 'EPF-${widget.tipoPolimero}',
        pesoInicial: widget.peso,
        direccion: userProfile?['direccion'] ?? 'Sin dirección registrada',
        fuente: widget.fuente,
        presentacion: widget.presentacion,
        tipoPoli: widget.tipoPolimero,
        origenMaterial: _tipoOrigen,
        condiciones: widget.condiciones,
        nombreOperador: widget.nombreOperador,
        firmaOperador: signatureUrl,
        evidenciasFoto: photoUrls,
        comentarios: widget.comentarios,
        folioUsuario: userData?['folio'] ?? 'A0000001',
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Navegar a la pantalla de detalles con mensaje de éxito
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => OrigenLoteDetalleScreen(
              firebaseId: loteId,
              material: 'EPF-${widget.tipoPolimero}',
              peso: widget.peso,
              presentacion: widget.presentacion,
              fuente: widget.fuente,
              fechaCreacion: DateTime.now(),
              mostrarMensajeExito: true,
            ),
          ),
          (route) => route.isFirst,
        );
      }
    } catch (e) {
      print('Error al crear lote: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        DialogUtils.showErrorDialog(
          context: context,
          title: 'Error',
          message: 'No se pudo crear el lote. Por favor intenta nuevamente.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BioWayColors.backgroundGrey,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Confirmar Datos del Lote',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sección: Información del Material
                _buildSection(
                  icon: '📦',
                  title: 'Información del Material',
                  children: [
                    _buildInfoRow('Tipo de Polímero', widget.tipoPolimero),
                    _buildInfoRow('Presentación', widget.presentacion),
                    _buildInfoRow('Fuente', widget.fuente),
                    _buildInfoRow('Origen', _tipoOrigen),
                    _buildInfoRow('Peso', '${widget.peso.toStringAsFixed(1)} kg'),
                    _buildInfoRow('Condiciones', widget.condiciones),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Sección: Datos del Responsable
                _buildSection(
                  icon: '👤',
                  title: 'Datos del Responsable',
                  children: [
                    _buildInfoRow('Nombre del Operador', widget.nombreOperador),
                    const SizedBox(height: 12),
                    const Text(
                      'Firma del Operador',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: SizedBox(
                            width: 300,
                            height: 200,
                            child: CustomPaint(
                              size: const Size(300, 200),
                              painter: SignaturePainter(
                                widget.signaturePoints,
                                color: Colors.black,
                                strokeWidth: 3.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Sección: Evidencia Fotográfica
                _buildSection(
                  icon: '📷',
                  title: 'Evidencia Fotográfica',
                  children: [
                    Text(
                      '${widget.photoFiles.length} foto(s) adjunta(s)',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.photoFiles.length,
                        itemBuilder: (context, index) {
                          return Container(
                            width: 100,
                            height: 100,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: FileImage(widget.photoFiles[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                
                if (widget.comentarios != null && widget.comentarios!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  // Sección: Comentarios
                  _buildSection(
                    icon: '💬',
                    title: 'Comentarios',
                    children: [
                      Text(
                        widget.comentarios!,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ],
                
                const SizedBox(height: 100), // Espacio para el botón flotante
              ],
            ),
          ),
          
          // Botón Crear Lote
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _mostrarDialogoConfirmacion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 3,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Crear Lote',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}