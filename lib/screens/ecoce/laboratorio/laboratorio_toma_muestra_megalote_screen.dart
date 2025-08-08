import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import '../../../utils/ui_constants.dart';
import '../../../services/transformacion_service.dart';
import '../../../services/muestra_laboratorio_service.dart'; // NUEVO: Servicio independiente
import '../../../services/user_session_service.dart';
import '../../../services/firebase/firebase_storage_service.dart';
import '../../../services/firebase/auth_service.dart';
import '../../../services/image_service.dart';
import '../../../models/lotes/transformacion_model.dart';
import '../shared/widgets/weight_input_widget.dart';
import '../shared/widgets/signature_dialog.dart';
import '../shared/widgets/dialog_utils.dart';
import '../shared/widgets/photo_evidence_widget.dart';
import '../shared/widgets/field_label.dart' as field_label;
import 'laboratorio_formulario.dart';

/// Painter personalizado para dibujar la firma con el color del Laboratorio
class SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  final double strokeWidth;

  SignaturePainter({
    required this.points,
    this.strokeWidth = UIConstants.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF9333EA) // Color morado del Laboratorio
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
  final TransformacionService _transformacionService = TransformacionService();
  final MuestraLaboratorioService _muestraService = MuestraLaboratorioService(); // NUEVO: Servicio independiente
  final UserSessionService _userSession = UserSessionService();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  final AuthService _authService = AuthService();

  // Datos del megalote
  TransformacionModel? _transformacion;
  String? _transformacionId;
  
  // Controladores
  final TextEditingController _pesoMuestraController = TextEditingController();
  final TextEditingController _operadorController = TextEditingController();
  
  // Firma
  List<Offset?> _signaturePoints = [];
  String? _signatureUrl;
  
  // Fotos
  List<File> _photoFiles = [];
  List<String> _photoUrls = [];
  
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _parseQRAndLoadData();
  }

  @override
  void dispose() {
    _pesoMuestraController.dispose();
    _operadorController.dispose();
    super.dispose();
  }

  void _initializeForm() async {
    // NO pre-cargar el nombre del operador - el usuario debe ingresarlo manualmente
    // Dejar el campo vacío para que el responsable ingrese su nombre
    // final userData = _userSession.getUserData();
    // _operadorController.text = userData?['nombre'] ?? '';
  }

  Future<void> _parseQRAndLoadData() async {
    try {
      // NUEVO SISTEMA: El QR puede ser simplemente MUESTRA-MEGALOTE-transformacionId
      // o el formato anterior MUESTRA-MEGALOTE-transformacionId-muestraId
      final parts = widget.qrCode.split('-');
      
      if (parts.length < 3 || parts[0] != 'MUESTRA' || parts[1] != 'MEGALOTE') {
        throw Exception('Código QR de muestra inválido');
      }
      
      _transformacionId = parts[2];
      
      // Cargar datos de la transformación usando el servicio independiente
      final transformacion = await _transformacionService.obtenerTransformacionPorId(_transformacionId!);
      
      if (transformacion == null) {
        throw Exception('No se encontró el megalote con ID: $_transformacionId');
      }
      
      // Verificar que el megalote tenga peso disponible
      if (transformacion.pesoDisponible <= 0) {
        throw Exception('El megalote no tiene peso disponible para tomar muestras');
      }
      
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
          context,
          title: 'Error',
          message: 'Error al cargar datos: ${e.toString()}',
        );
        if (mounted) Navigator.pop(context);
      }
    }
  }

  Future<void> _captureSignature() async {
    print('[DEBUG] _captureSignature llamado');
    print('[DEBUG] mounted: $mounted');
    print('[DEBUG] context: $context');
    
    // Dismiss keyboard
    FocusScope.of(context).unfocus();
    
    // Wait for keyboard to hide
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Check if still mounted
    if (!mounted) {
      print('[DEBUG] Widget no montado, saliendo');
      return;
    }
    
    print('[DEBUG] Mostrando diálogo de firma');
    
    try {
      await SignatureDialog.show(
        context: context,
        title: 'Firma del Responsable',
        initialSignature: _signaturePoints,
        onSignatureSaved: (points) {
          print('[DEBUG] Firma guardada con ${points.length} puntos');
          setState(() {
            _signaturePoints = List.from(points);
            _signatureUrl = null;
          });
        },
        primaryColor: const Color(0xFF9333EA), // Color del Laboratorio
      );
      print('[DEBUG] Diálogo de firma mostrado exitosamente');
    } catch (e) {
      print('[ERROR] Error mostrando diálogo de firma: $e');
    }
  }

  void _onPhotosChanged(List<File> photos) {
    print('[DEBUG] _onPhotosChanged llamado con ${photos.length} fotos');
    setState(() {
      _photoFiles = photos;
    });
    print('[DEBUG] _photoFiles actualizado: ${_photoFiles.length} fotos');
  }

  Future<String?> _uploadSignature() async {
    if (_signaturePoints.isEmpty) return null;

    try {
      // Crear imagen de la firma
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final painter = SignaturePainter(
        points: _signaturePoints,
        strokeWidth: UIConstants.strokeWidth,
      );
      
      final size = Size(UIConstants.qrSizeMedium + UIConstants.iconSizeDialog + UIConstants.iconSizeMedium, UIConstants.statCardHeight);
      
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
        'firmas/laboratorio/${_authService.currentUser?.uid}',
      );
      
      // Eliminar archivo temporal
      await file.delete();
      
      return url;
    } catch (e) {
      debugPrint('Error al subir firma: $e');
      return null;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_signaturePoints.isEmpty) {
      DialogUtils.showErrorDialog(
        context,
        title: 'Firma Requerida',
        message: 'Por favor capture la firma del operador antes de continuar.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Subir firma
      _signatureUrl = await _uploadSignature();
      if (_signatureUrl == null) {
        throw Exception('Error al subir la firma');
      }

      // Subir fotos
      _photoUrls = [];
      for (final photoFile in _photoFiles) {
        if (await photoFile.exists()) {
          final url = await _storageService.uploadFile(
            photoFile,
            'evidencias/laboratorio/${_authService.currentUser?.uid}',
          );
          if (url != null) {
            _photoUrls.add(url);
          }
        }
      }

      // NUEVO SISTEMA: Crear muestra usando el servicio independiente
      print('[DEBUG] Creando muestra con sistema independiente');
      
      final pesoMuestra = double.parse(_pesoMuestraController.text);
      
      // Crear la muestra en la colección independiente
      final muestraId = await _muestraService.crearMuestra(
        origenId: _transformacionId!,
        origenTipo: 'transformacion',
        pesoMuestra: pesoMuestra,
        firmaOperador: _signatureUrl!,
        evidenciasFoto: _photoUrls,
        qrCode: 'MUESTRA-MEGALOTE-$_transformacionId',
      );
      
      print('[DEBUG] Muestra creada exitosamente con ID: $muestraId');

      if (mounted) {
        // Navegar directamente a inicio después de crear la muestra
        print('[LABORATORIO] Muestra creada exitosamente: $muestraId');
        print('[LABORATORIO] Navegando a inicio...');
        
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/laboratorio_inicio',
          (route) => false,
        );
      }
    } catch (e) {
      print('[ERROR] Error al registrar muestra: $e');
      if (mounted) {
        DialogUtils.showErrorDialog(
          context,
          title: 'Error',
          message: 'Error al registrar la muestra: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Center(
          child: CircularProgressIndicator(
            color: const Color(0xFF9333EA),
          ),
        ),
      );
    }

    if (_transformacion == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: const Color(0xFF9333EA),
          title: const Text(
            'Error',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              SizedBox(height: UIConstants.spacing16),
              const Text(
                'No se pudo cargar la información del megalote',
                style: TextStyle(fontSize: UIConstants.fontSizeBody),
              ),
              SizedBox(height: UIConstants.spacing24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9333EA),
                ),
                child: const Text(
                  'Volver',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF9333EA),
        title: const Text(
          'Toma de Muestra - Megalote',
          style: TextStyle(
            fontSize: UIConstants.fontSizeXLarge,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () async {
            if (_signaturePoints.isNotEmpty || _photoFiles.isNotEmpty) {
              final shouldLeave = await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  title: const Text('¿Abandonar formulario?'),
                  content: const Text(
                    'Los datos capturados se perderán.\n\n¿Estás seguro de que deseas salir?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Salir'),
                    ),
                  ],
                ),
              );
              
              if (shouldLeave == true && context.mounted) {
                Navigator.pop(context);
              }
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsetsConstants.paddingAll16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Información del megalote
              Container(
                padding: EdgeInsetsConstants.paddingAll16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadiusConstants.borderRadiusMedium,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: UIConstants.opacityVeryLow),
                      blurRadius: UIConstants.blurRadiusMedium,
                      offset: Offset(0, UIConstants.spacing4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2,
                          color: const Color(0xFF9333EA),
                          size: 24,
                        ),
                        SizedBox(width: UIConstants.spacing12),
                        const Text(
                          'Información del Megalote',
                          style: TextStyle(
                            fontSize: UIConstants.fontSizeLarge,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: UIConstants.spacing16),
                    _buildInfoRow('ID:', _transformacion!.id),
                    SizedBox(height: UIConstants.spacing8),
                    _buildInfoRow('Peso Total:', '${_transformacion!.pesoTotalEntrada.toStringAsFixed(2)} kg'),
                    SizedBox(height: UIConstants.spacing8),
                    _buildInfoRow('Peso Disponible:', '${_transformacion!.pesoDisponible.toStringAsFixed(2)} kg'),
                    SizedBox(height: UIConstants.spacing8),
                    _buildInfoRow('Fecha:', _formatDate(DateTime.now())),
                  ],
                ),
              ),
              
              SizedBox(height: UIConstants.spacing16),
              
              // Peso de la muestra
              Container(
                padding: EdgeInsetsConstants.paddingAll16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadiusConstants.borderRadiusMedium,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: UIConstants.opacityVeryLow),
                      blurRadius: UIConstants.blurRadiusMedium,
                      offset: Offset(0, UIConstants.spacing4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.scale,
                          color: const Color(0xFF9333EA),
                          size: 24,
                        ),
                        SizedBox(width: UIConstants.spacing12),
                        const Text(
                          'Peso de la Muestra',
                          style: TextStyle(
                            fontSize: UIConstants.fontSizeLarge,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: UIConstants.spacing4),
                        const Text(
                          '*',
                          style: TextStyle(
                            fontSize: UIConstants.fontSizeLarge,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: UIConstants.spacing16),
                    WeightInputWidget(
                      controller: _pesoMuestraController,
                      label: 'Peso de la muestra en kg',
                      primaryColor: const Color(0xFF9333EA),
                      quickAddValues: const [5, 10, 25, 50], // Valores apropiados para muestras de laboratorio
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese el peso de la muestra';
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
                    SizedBox(height: UIConstants.spacing8),
                    Text(
                      'Peso máximo disponible: ${_transformacion!.pesoDisponible.toStringAsFixed(2)} kg',
                      style: TextStyle(
                        fontSize: UIConstants.fontSizeSmall,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: UIConstants.spacing16),
              
              // Datos del responsable
              Container(
                width: double.infinity,
                padding: EdgeInsetsConstants.paddingAll20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadiusConstants.borderRadiusMedium,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: UIConstants.opacityVeryLow),
                      blurRadius: UIConstants.blurRadiusMedium,
                      offset: Offset(0, UIConstants.spacing4 + 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          color: const Color(0xFF9333EA),
                          size: 24,
                        ),
                        SizedBox(width: UIConstants.spacing12),
                        Text(
                          'Datos del Responsable',
                          style: TextStyle(
                            fontSize: UIConstants.fontSizeLarge,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF9333EA),
                          ),
                        ),
                        SizedBox(width: UIConstants.spacing4),
                        const Text(
                          '*',
                          style: TextStyle(
                            fontSize: UIConstants.fontSizeLarge,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: UIConstants.spacing20),
                    
                    // Nombre del Operador
                    const field_label.FieldLabel(text: 'Nombre', isRequired: true),
                    SizedBox(height: UIConstants.spacing8),
                    TextFormField(
                      controller: _operadorController,
                      maxLength: 50,
                      keyboardType: TextInputType.name,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        hintText: 'Ingresa el nombre completo',
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadiusConstants.borderRadiusMedium,
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadiusConstants.borderRadiusMedium,
                          borderSide: BorderSide(
                            color: const Color(0xFF9333EA).withValues(alpha: 0.3),
                            width: UIConstants.borderWidthThin,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadiusConstants.borderRadiusMedium,
                          borderSide: const BorderSide(
                            color: Color(0xFF9333EA),
                            width: UIConstants.strokeWidth,
                          ),
                        ),
                        counterText: '',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa el nombre del operador';
                        }
                        if (value.length < 3) {
                          return 'El nombre debe tener al menos 3 caracteres';
                        }
                        return null;
                      },
                    ),
                    
                    SizedBox(height: UIConstants.spacing20),
                    
                    // Firma del Operador
                    const field_label.FieldLabel(text: 'Firma', isRequired: true),
                    SizedBox(height: UIConstants.spacing8),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        print('[DEBUG] GestureDetector tap detectado');
                        print('[DEBUG] _signaturePoints.isEmpty: ${_signaturePoints.isEmpty}');
                        if (_signaturePoints.isEmpty) {
                          print('[DEBUG] Llamando _captureSignature');
                          _captureSignature();
                        } else {
                          print('[DEBUG] Ya hay firma, no se hace nada');
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: _signaturePoints.isNotEmpty ? 150 : 100,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: _signaturePoints.isNotEmpty 
                              ? const Color(0xFF9333EA).withValues(alpha: 0.05)
                              : Colors.grey[50],
                          borderRadius: BorderRadiusConstants.borderRadiusMedium,
                          border: Border.all(
                            color: _signaturePoints.isNotEmpty 
                                ? const Color(0xFF9333EA) 
                                : Colors.grey[300]!,
                            width: _signaturePoints.isNotEmpty ? 2 : 1,
                          ),
                        ),
                        child: !_signaturePoints.isNotEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.draw,
                                      size: 32,
                                      color: Colors.grey[400],
                                    ),
                                    SizedBox(height: UIConstants.spacing8),
                                    Text(
                                      'Toque para firmar',
                                      style: TextStyle(
                                        fontSize: UIConstants.fontSizeMedium,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Stack(
                                children: [
                                  Container(
                                    padding: EdgeInsetsConstants.paddingAll12,
                                    child: Center(
                                      child: AspectRatio(
                                        aspectRatio: 2.0, // Mismo aspect ratio que Reciclador
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadiusConstants.borderRadiusSmall,
                                            border: Border.all(
                                              color: Colors.grey[200]!,
                                              width: UIConstants.borderWidthThin,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(UIConstants.radiusSmall + 1),
                                            child: FittedBox(
                                              fit: BoxFit.contain,
                                              child: SizedBox(
                                                width: UIConstants.qrSizeMedium + UIConstants.iconSizeDialog + UIConstants.iconSizeMedium,
                                                height: UIConstants.qrSizeMedium + UIConstants.iconSizeDialog + UIConstants.iconSizeMedium, // Mismo tamaño que Reciclador para consistencia
                                                child: CustomPaint(
                                                  painter: SignaturePainter(
                                                    points: _signaturePoints,
                                                    strokeWidth: UIConstants.strokeWidth,
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
                                                blurRadius: UIConstants.blurRadiusSmall,
                                              ),
                                            ],
                                          ),
                                          child: IconButton(
                                            onPressed: _captureSignature,
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Color(0xFF9333EA),
                                              size: 20,
                                            ),
                                            constraints: const BoxConstraints(
                                              minWidth: 32,
                                              minHeight: 32,
                                            ),
                                            padding: EdgeInsetsConstants.paddingNone,
                                          ),
                                        ),
                                        SizedBox(width: UIConstants.spacing8),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.1),
                                                blurRadius: UIConstants.blurRadiusSmall,
                                              ),
                                            ],
                                          ),
                                          child: IconButton(
                                            onPressed: () {
                                              setState(() {
                                                _signaturePoints.clear();
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
                                            padding: EdgeInsetsConstants.paddingNone,
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
                ),
              ),
              
              SizedBox(height: UIConstants.spacing16),
              
              // Evidencia fotográfica
              Container(
                width: double.infinity,
                padding: EdgeInsetsConstants.paddingAll20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadiusConstants.borderRadiusMedium,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: UIConstants.opacityVeryLow),
                      blurRadius: UIConstants.blurRadiusMedium,
                      offset: Offset(0, UIConstants.spacing4 + 1),
                    ),
                  ],
                ),
                child: PhotoEvidenceWidget(
                  title: 'Evidencia Fotográfica',
                  maxPhotos: 3,
                  minPhotos: 0,
                  isRequired: false,
                  onPhotosChanged: _onPhotosChanged,
                  primaryColor: const Color(0xFF9333EA),
                ),
              ),
              
              SizedBox(height: UIConstants.spacing24),
              
              // Botón de enviar
              SizedBox(
                height: UIConstants.buttonHeight,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9333EA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadiusConstants.borderRadiusMedium,
                    ),
                    elevation: UIConstants.elevationSmall,
                  ),
                  child: _isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: UIConstants.iconSizeSmall,
                              height: UIConstants.iconSizeSmall,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: UIConstants.strokeWidth,
                              ),
                            ),
                            SizedBox(width: UIConstants.spacing12),
                            Text(
                              'Procesando...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: UIConstants.fontSizeBody,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Registrar Toma de Muestra',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              
              SizedBox(height: UIConstants.spacing32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: UIConstants.statCardHeight,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}