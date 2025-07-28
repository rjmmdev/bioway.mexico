import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import '../shared/utils/dialog_utils.dart';
import '../shared/widgets/signature_dialog.dart';
import '../shared/widgets/photo_evidence_widget.dart';
import '../shared/widgets/weight_input_widget.dart';
import '../../../services/lote_unificado_service.dart';
import '../../../services/transformacion_service.dart';
import '../../../services/firebase/firebase_storage_service.dart';
import '../../../models/lotes/transformacion_model.dart';

class SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  final Color color;
  final double strokeWidth;

  SignaturePainter({
    required this.points,
    this.color = const Color(0xFF9333EA),
    this.strokeWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) => true;
}

class LaboratorioTomaMuestraMegaloteScreen extends StatefulWidget {
  final String qrCode;
  
  const LaboratorioTomaMuestraMegaloteScreen({
    super.key,
    required this.qrCode,
  });
  
  @override
  State<LaboratorioTomaMuestraMegaloteScreen> createState() => _LaboratorioTomaMuestraMegaloteScreenState();
}

class _LaboratorioTomaMuestraMegaloteScreenState extends State<LaboratorioTomaMuestraMegaloteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pesoMuestraController = TextEditingController();
  
  // Servicios
  final LoteUnificadoService _loteService = LoteUnificadoService();
  final TransformacionService _transformacionService = TransformacionService();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  
  // Estado
  bool _isLoading = true;
  bool _isSubmitting = false;
  List<Offset?> _signaturePoints = [];
  bool _hasSignature = false;
  List<File> _photoFiles = [];
  TransformacionModel? _transformacion;
  String? _transformacionId;
  String? _muestraId;
  
  @override
  void initState() {
    super.initState();
    _parseQRAndLoadData();
  }
  
  @override
  void dispose() {
    _pesoMuestraController.dispose();
    super.dispose();
  }
  
  Future<void> _parseQRAndLoadData() async {
    try {
      // Extraer IDs del QR code: MUESTRA-MEGALOTE-transformacionId-muestraId
      final parts = widget.qrCode.split('-');
      if (parts.length != 4 || parts[0] != 'MUESTRA' || parts[1] != 'MEGALOTE') {
        throw Exception('Código QR de muestra inválido');
      }
      
      _transformacionId = parts[2];
      _muestraId = parts[3];
      
      // Cargar datos de la transformación
      final transformacion = await _transformacionService.obtenerTransformacionPorId(_transformacionId!);
      
      if (mounted) {
        setState(() {
          _transformacion = transformacion;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        await DialogUtils.showErrorDialog(
          context: context,
          title: 'Error',
          message: 'Error al cargar datos: ${e.toString()}',
        );
        if (mounted) Navigator.pop(context);
      }
    }
  }
  
  void _onPhotosChanged(List<File> photos) {
    setState(() {
      _photoFiles = photos;
    });
  }
  
  void _showSignatureDialog() {
    SignatureDialog.show(
      context: context,
      title: 'Firma del Operador',
      initialSignature: _signaturePoints,
      onSignatureSaved: (points) {
        setState(() {
          _signaturePoints = points;
          _hasSignature = points.isNotEmpty;
        });
      },
      primaryColor: const Color(0xFF9333EA),
    );
  }
  
  Future<void> _guardarTomaMuestra() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_signaturePoints.isEmpty) {
      DialogUtils.showErrorDialog(
        context: context,
        title: 'Firma requerida',
        message: 'Por favor firme el formulario antes de continuar',
      );
      return;
    }
    
    setState(() => _isSubmitting = true);
    
    try {
      // Subir firma
      String? firmaUrl = await _uploadSignature();
      if (firmaUrl == null) {
        throw Exception('Error al subir la firma');
      }
      
      // Subir fotos
      final fotosUrls = <String>[];
      for (final photoFile in _photoFiles) {
        if (await photoFile.exists()) {
          final url = await _storageService.uploadFile(
            photoFile,
            'laboratorio/evidencias',
          );
          if (url != null) {
            fotosUrls.add(url);
          }
        }
      }
      
      // Procesar muestra del megalote
      await _loteService.procesarMuestraMegalote(
        qrCode: widget.qrCode,
        pesoMuestra: double.parse(_pesoMuestraController.text),
        firmaOperador: firmaUrl,
        evidenciasFoto: fotosUrls,
      );
      
      // Mostrar éxito
      if (mounted) {
        DialogUtils.showSuccessDialog(
          context: context,
          title: 'Muestra registrada',
          message: 'La toma de muestra del megalote se ha registrado exitosamente',
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/laboratorio_inicio',
              (route) => false,
            );
          },
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        DialogUtils.showErrorDialog(
          context: context,
          title: 'Error',
          message: 'Error al registrar la muestra: ${e.toString()}',
        );
      }
    }
  }
  
  Future<String?> _uploadSignature() async {
    if (_signaturePoints.isEmpty) return null;

    try {
      // Crear imagen de la firma
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final painter = SignaturePainter(
        points: _signaturePoints,
        color: const Color(0xFF9333EA),
        strokeWidth: 2.0,
      );
      
      final size = const Size(300, 120);
      
      // Fondo blanco
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.white,
      );
      
      painter.paint(canvas, size);
      
      final picture = recorder.endRecording();
      final img = await picture.toImage(size.width.toInt(), size.height.toInt());
      final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
      
      if (pngBytes == null) return null;
      
      final bytes = pngBytes.buffer.asUint8List();
      
      // Guardar temporalmente
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/firma_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      
      // Subir a Firebase Storage
      final url = await _storageService.uploadFile(
        file,
        'firmas/laboratorio',
      );
      
      // Eliminar archivo temporal
      await file.delete();
      
      return url;
    } catch (e) {
      debugPrint('Error al subir firma: $e');
      return null;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF9333EA), // Morado para laboratorio
        title: const Text(
          'Toma de Muestra - Megalote',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: const Color(0xFF9333EA),
              ),
            )
          : _transformacion == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No se pudo cargar la información',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Información del megalote
                        _buildInfoCard(),
                        const SizedBox(height: 20),
                        
                        // Peso de la muestra
                        _buildPesoMuestraField(),
                        const SizedBox(height: 20),
                        
                        // Firma
                        _buildFirmaSection(),
                        const SizedBox(height: 20),
                        
                        // Evidencias fotográficas
                        _buildEvidenciasSection(),
                        const SizedBox(height: 30),
                        
                        // Botón guardar
                        _buildGuardarButton(),
                      ],
                    ),
                  ),
                ),
    );
  }
  
  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información del Megalote',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF9333EA),
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('ID Megalote:', _transformacion!.id.substring(0, 8).toUpperCase()),
            _buildInfoRow('Material:', _transformacion!.materialPredominante ?? 'Mixto'),
            _buildInfoRow('Peso disponible:', '${_transformacion!.pesoDisponible.toStringAsFixed(2)} kg'),
            _buildInfoRow('Fecha creación:', _formatDate(_transformacion!.fechaInicio)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPesoMuestraField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Peso de la muestra (kg) *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF9333EA),
          ),
        ),
        const SizedBox(height: 8),
        WeightInputWidget(
          controller: _pesoMuestraController,
          label: 'Ingrese el peso de la muestra tomada',
          primaryColor: const Color(0xFF9333EA),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'El peso es requerido';
            }
            final peso = double.tryParse(value);
            if (peso == null || peso <= 0) {
              return 'Ingrese un peso válido';
            }
            if (peso > _transformacion!.pesoDisponible) {
              return 'La muestra no puede exceder el peso disponible';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Peso máximo disponible: ${_transformacion!.pesoDisponible.toStringAsFixed(2)} kg',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
  
  Widget _buildFirmaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Firma del Operador',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '*',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _hasSignature ? null : () => _showSignatureDialog(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _hasSignature ? 150 : 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _hasSignature 
                  ? const Color(0xFF9333EA).withValues(alpha: 0.05)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _hasSignature 
                    ? const Color(0xFF9333EA) 
                    : Colors.grey[300]!,
                width: _hasSignature ? 2 : 1,
              ),
            ),
            child: !_hasSignature
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.draw,
                          size: 32,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Toque para firmar',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: 2.5,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey[200]!,
                                  width: 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(7),
                                child: FittedBox(
                                  fit: BoxFit.contain,
                                  child: SizedBox(
                                    width: 300,
                                    height: 120,
                                    child: CustomPaint(
                                      size: const Size(300, 120),
                                      painter: SignaturePainter(
                                        points: _signaturePoints,
                                        color: const Color(0xFF9333EA),
                                        strokeWidth: 2.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: IconButton(
                                onPressed: _showSignatureDialog,
                                icon: Icon(
                                  Icons.edit,
                                  color: const Color(0xFF9333EA),
                                  size: 20,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _signaturePoints.clear();
                                    _hasSignature = false;
                                  });
                                },
                                icon: const Icon(
                                  Icons.clear,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildEvidenciasSection() {
    return PhotoEvidenceWidget(
      title: 'Evidencia Fotográfica',
      maxPhotos: 3,
      minPhotos: 0,
      isRequired: false,
      onPhotosChanged: _onPhotosChanged,
      primaryColor: const Color(0xFF9333EA),
    );
  }
  
  Widget _buildGuardarButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _guardarTomaMuestra,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF9333EA),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Registrar Toma de Muestra',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}