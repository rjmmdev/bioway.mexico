import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../../utils/colors.dart';
import '../../../utils/ui_constants.dart';
import '../../../services/lote_service.dart';
// import '../../../services/lote_unificado_service.dart'; // No se usa actualmente
import '../../../services/muestra_laboratorio_service.dart'; // NUEVO: Servicio independiente
// import '../../../models/laboratorio/muestra_laboratorio_model.dart'; // No se usa actualmente
import '../../../services/user_session_service.dart';
import '../../../services/firebase/firebase_storage_service.dart';
import '../../../services/firebase/auth_service.dart';
import '../shared/widgets/signature_dialog.dart';
import '../shared/widgets/dialog_utils.dart';
import 'laboratorio_documentacion.dart';
import 'laboratorio_gestion_muestras.dart';

// Painter para la firma
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

class LaboratorioFormulario extends StatefulWidget {
  final String muestraId;
  final String transformacionId; // Para el sistema de megalotes
  final Map<String, dynamic> datosMuestra;

  const LaboratorioFormulario({
    super.key,
    required this.muestraId,
    required this.transformacionId,
    required this.datosMuestra,
  });

  @override
  State<LaboratorioFormulario> createState() => _LaboratorioFormularioState();
}

class _LaboratorioFormularioState extends State<LaboratorioFormulario> {
  final _formKey = GlobalKey<FormState>();
  
  // Servicios
  final LoteService _loteService = LoteService();
  // final LoteUnificadoService _loteUnificadoService = LoteUnificadoService(); // No se usa actualmente
  final MuestraLaboratorioService _muestraService = MuestraLaboratorioService(); // NUEVO: Servicio independiente
  final UserSessionService _userSession = UserSessionService();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  final AuthService _authService = AuthService();
  
  // Controladores para los campos
  final _humedadController = TextEditingController();
  final _pelletsController = TextEditingController();
  final _tipoPolimeroController = TextEditingController();
  final _temperaturaUnicaController = TextEditingController();
  final _temperaturaRangoMinController = TextEditingController();
  final _temperaturaRangoMaxController = TextEditingController();
  final _contenidoOrganicoController = TextEditingController();
  final _contenidoInorganicoController = TextEditingController();
  final _oitController = TextEditingController();
  final _mfiController = TextEditingController();
  final _densidadController = TextEditingController();
  final _normaController = TextEditingController();
  final _observacionesController = TextEditingController();
  final _nombreResponsableController = TextEditingController();
  
  // Estados para el formulario
  List<Offset?> _signaturePoints = [];
  String? _signatureUrl;
  bool _isTemperaturaUnica = true; // true = única, false = rango
  String _unidadTemperatura = 'C°'; // C°, K°, F°
  bool? _cumpleRequisitos; // null = no seleccionado, true = Sí, false = No
  bool _isLoading = false;
  
  @override
  void dispose() {
    _humedadController.dispose();
    _pelletsController.dispose();
    _tipoPolimeroController.dispose();
    _temperaturaUnicaController.dispose();
    _temperaturaRangoMinController.dispose();
    _temperaturaRangoMaxController.dispose();
    _contenidoOrganicoController.dispose();
    _contenidoInorganicoController.dispose();
    _oitController.dispose();
    _mfiController.dispose();
    _densidadController.dispose();
    _normaController.dispose();
    _observacionesController.dispose();
    _nombreResponsableController.dispose();
    super.dispose();
  }

  // Inicializar nombre del responsable
  @override
  void initState() {
    super.initState();
    _initializeResponsableData();
  }
  
  void _initializeResponsableData() async {
    final userProfile = await _userSession.getUserProfile();
    if (userProfile != null && mounted) {
      setState(() {
        _nombreResponsableController.text = userProfile['ecoceNombre'] ?? '';
      });
    }
  }
  
  // Capturar firma
  Future<void> _captureSignature() async {
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (!mounted) return;
    
    try {
      await SignatureDialog.show(
        context: context,
        title: 'Firma del Responsable',
        initialSignature: _signaturePoints,
        onSignatureSaved: (points) {
          setState(() {
            _signaturePoints = List.from(points);
            _signatureUrl = null;
          });
        },
        primaryColor: const Color(0xFF9333EA), // Color del Laboratorio
      );
    } catch (e) {
      debugPrint('[ERROR] Error mostrando diálogo de firma: $e');
    }
  }
  
  // Subir firma a Firebase
  Future<String?> _uploadSignature() async {
    if (_signaturePoints.isEmpty) return null;
    
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final painter = SignaturePainter(
        points: _signaturePoints,
        strokeWidth: UIConstants.strokeWidth,
      );
      
      const size = Size(300, 300);
      
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
      
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/firma_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      
      final url = await _storageService.uploadFile(
        file,
        'firmas/laboratorio/${_authService.currentUser?.uid}',
      );
      
      await file.delete();
      
      return url;
    } catch (e) {
      debugPrint('Error al subir firma: $e');
      return null;
    }
  }
  
  void _handleFormSubmit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor completa todos los campos obligatorios'),
          backgroundColor: BioWayColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusConstants.borderRadiusSmall,
          ),
        ),
      );
      return;
    }

    if (_cumpleRequisitos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor indica si la muestra cumple con los requisitos'),
          backgroundColor: BioWayColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusConstants.borderRadiusSmall,
          ),
        ),
      );
      return;
    }

    // Validar que tenga firma
    if (_signaturePoints.isEmpty) {
      DialogUtils.showErrorDialog(
        context,
        title: 'Firma Requerida',
        message: 'Por favor capture la firma del responsable antes de continuar.',
      );
      return;
    }
    
    HapticFeedback.mediumImpact();
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Subir firma
      _signatureUrl = await _uploadSignature();
      if (_signatureUrl == null) {
        throw Exception('Error al subir la firma');
      }
      // Preparar datos de temperatura
      Map<String, dynamic> temperaturaData = {
        'unidad': _unidadTemperatura,
      };
      
      if (_isTemperaturaUnica) {
        temperaturaData['tipo'] = 'unica';
        temperaturaData['valor'] = double.parse(_temperaturaUnicaController.text);
      } else {
        temperaturaData['tipo'] = 'rango';
        temperaturaData['minima'] = double.parse(_temperaturaRangoMinController.text);
        temperaturaData['maxima'] = double.parse(_temperaturaRangoMaxController.text);
      }

      // Obtener datos del usuario
      final userProfile = await _userSession.getUserProfile();
      
      // Preparar datos del análisis
      final datosAnalisis = {
        'humedad': double.parse(_humedadController.text),
        'pellets_gramo': double.parse(_pelletsController.text),
        'tipo_polimero': _tipoPolimeroController.text.trim(),
        'temperatura_fusion': temperaturaData,
        'contenido_organico': double.parse(_contenidoOrganicoController.text),
        'contenido_inorganico': double.parse(_contenidoInorganicoController.text),
        'oit': _oitController.text.trim(),
        'mfi': _mfiController.text.trim(),
        'densidad': _densidadController.text.trim(),
        'norma': _normaController.text.trim(),
        'observaciones': _observacionesController.text.trim(),
        'cumple_requisitos': _cumpleRequisitos,
        'analista': userProfile?['ecoceNombre'] ?? 'Sin nombre',
        'nombre_responsable': _nombreResponsableController.text.trim(),
        'firma_responsable': _signatureUrl,
      };
      
      // NUEVO SISTEMA: Actualizar análisis usando el servicio independiente
      debugPrint('[LABORATORIO] ========================================');
      debugPrint('[LABORATORIO] ACTUALIZANDO ANÁLISIS');
      debugPrint('[LABORATORIO] Muestra ID: ${widget.muestraId}');
      debugPrint('[LABORATORIO] Transformación ID: ${widget.transformacionId}');
      debugPrint('[LABORATORIO] Datos muestra: ${widget.datosMuestra['id'] ?? 'Sin ID en datos'}');
      debugPrint('[LABORATORIO] ========================================');
      
      // Verificar si es una muestra de megalote
      final transformacionId = widget.transformacionId;
      if (transformacionId != null && transformacionId.isNotEmpty) {
        // Es una muestra de megalote - usar el sistema independiente
        debugPrint('[LABORATORIO] Usando sistema independiente para megalote');
        debugPrint('[LABORATORIO] Actualizando muestra con ID: ${widget.muestraId}');
        
        await _muestraService.actualizarAnalisis(
          widget.muestraId,
          datosAnalisis,
        );
        
        debugPrint('[LABORATORIO] ✓ Análisis actualizado exitosamente en muestra: ${widget.muestraId}');
      } else {
        // Sistema antiguo (por compatibilidad con lotes normales)
        await _loteService.actualizarLoteLaboratorio(
          widget.muestraId,
          {
            ...datosAnalisis.map((key, value) => MapEntry('ecoce_laboratorio_$key', value)),
            'ecoce_laboratorio_fecha_analisis': Timestamp.fromDate(DateTime.now()),
            'estado': 'documentacion',
          },
        );
        
        debugPrint('[LABORATORIO] Análisis actualizado en sistema antiguo (lote normal)');
      }

      if (mounted) {
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Análisis registrado correctamente. Preparando documentación...'),
            backgroundColor: BioWayColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadiusConstants.borderRadiusSmall,
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Navegar directamente a gestión de muestras en la pestaña de documentación
        debugPrint('[LABORATORIO] Análisis completado, navegando a gestión de muestras...');
        debugPrint('[LABORATORIO] Esperando propagación de datos en Firebase...');
        
        // Dar más tiempo para asegurar que Firebase propague los cambios
        await Future.delayed(const Duration(milliseconds: 1500));
        
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const LaboratorioGestionMuestras(
                initialTab: 1, // Tab de documentación donde ahora aparecerá la muestra
              ),
            ),
            (route) => route.isFirst,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar análisis: ${e.toString()}'),
            backgroundColor: BioWayColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadiusConstants.borderRadiusSmall,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildNumericField({
    required String label,
    required TextEditingController controller,
    required String hint,
    String? suffix,
    required String pattern, // e.g., "100.00" for percentage, "10.2" for pellets
  }) {
    List<TextInputFormatter> formatters = [];
    TextInputType keyboardType = const TextInputType.numberWithOptions(decimal: true);
    
    if (pattern == "100.00") {
      // Porcentaje - máximo 100.00
      formatters = [
        FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d{0,2})?$')),
      ];
    } else if (pattern == "10.2") {
      // Pellets por gramo - XXXXXXXXXX.XX
      formatters = [
        FilteringTextInputFormatter.allow(RegExp(r'^\d{0,10}(\.\d{0,2})?$')),
      ];
    } else if (pattern == "5.5") {
      // Temperatura - XXXXX.XXXXX
      formatters = [
        FilteringTextInputFormatter.allow(RegExp(r'^\d{0,5}(\.\d{0,5})?$')),
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: UIConstants.fontSizeMedium,
                fontWeight: FontWeight.w600,
                color: BioWayColors.textGrey,
              ),
            ),
            SizedBox(width: UIConstants.spacing4),
            Text(
              '*',
              style: TextStyle(
                fontSize: UIConstants.fontSizeMedium,
                fontWeight: FontWeight.w600,
                color: BioWayColors.error,
              ),
            ),
          ],
        ),
        SizedBox(height: UIConstants.spacing8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: formatters,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: UIConstants.fontSizeMedium,
            ),
            suffixText: suffix,
            suffixStyle: const TextStyle(
              color: BioWayColors.darkGreen,
              fontWeight: FontWeight.w600,
            ),
            filled: true,
            fillColor: BioWayColors.backgroundGrey,
            border: OutlineInputBorder(
              borderRadius: BorderRadiusConstants.borderRadiusMedium,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadiusConstants.borderRadiusMedium,
              borderSide: BorderSide(
                color: BioWayColors.ecoceGreen.withValues(alpha: UIConstants.opacityMediumLow),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadiusConstants.borderRadiusMedium,
              borderSide: const BorderSide(
                color: BioWayColors.ecoceGreen,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadiusConstants.borderRadiusMedium,
              borderSide: const BorderSide(
                color: BioWayColors.error,
                width: 2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadiusConstants.borderRadiusMedium,
              borderSide: const BorderSide(
                color: BioWayColors.error,
                width: 2,
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Este campo es obligatorio';
            }
            
            if (pattern == "100.00") {
              final numValue = double.tryParse(value);
              if (numValue == null || numValue > 100 || numValue < 0) {
                return 'Debe ser un porcentaje entre 0 y 100';
              }
            }
            
            return null;
          },
        ),
      ],
    );
  }

  // Método para campos numéricos con punto decimal (OIT, MFI, Densidad)
  Widget _buildDecimalField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLength = 10,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: UIConstants.fontSizeMedium,
                fontWeight: FontWeight.w600,
                color: BioWayColors.textGrey,
              ),
            ),
            SizedBox(width: UIConstants.spacing4),
            Text(
              '*',
              style: TextStyle(
                fontSize: UIConstants.fontSizeMedium,
                fontWeight: FontWeight.w600,
                color: BioWayColors.error,
              ),
            ),
          ],
        ),
        SizedBox(height: UIConstants.spacing8),
        TextFormField(
          controller: controller,
          maxLength: maxLength,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: UIConstants.fontSizeMedium,
            ),
            filled: true,
            fillColor: BioWayColors.backgroundGrey,
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadiusConstants.borderRadiusMedium,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadiusConstants.borderRadiusMedium,
              borderSide: BorderSide(
                color: BioWayColors.backgroundGrey,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadiusConstants.borderRadiusMedium,
              borderSide: BorderSide(
                color: BioWayColors.ecoceGreen,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadiusConstants.borderRadiusMedium,
              borderSide: BorderSide(
                color: BioWayColors.error,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadiusConstants.borderRadiusMedium,
              borderSide: BorderSide(
                color: BioWayColors.error,
                width: 2,
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Campo requerido';
            }
            return null;
          },
        ),
      ],
    );
  }
  
  Widget _buildStringField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLength = 50,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: UIConstants.fontSizeMedium,
                fontWeight: FontWeight.w600,
                color: BioWayColors.textGrey,
              ),
            ),
            SizedBox(width: UIConstants.spacing4),
            Text(
              '*',
              style: TextStyle(
                fontSize: UIConstants.fontSizeMedium,
                fontWeight: FontWeight.w600,
                color: BioWayColors.error,
              ),
            ),
          ],
        ),
        SizedBox(height: UIConstants.spacing8),
        TextFormField(
          controller: controller,
          maxLength: maxLength,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: UIConstants.fontSizeMedium,
            ),
            filled: true,
            fillColor: BioWayColors.backgroundGrey,
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadiusConstants.borderRadiusMedium,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadiusConstants.borderRadiusMedium,
              borderSide: BorderSide(
                color: BioWayColors.ecoceGreen.withValues(alpha: UIConstants.opacityMediumLow),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadiusConstants.borderRadiusMedium,
              borderSide: const BorderSide(
                color: BioWayColors.ecoceGreen,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadiusConstants.borderRadiusMedium,
              borderSide: const BorderSide(
                color: BioWayColors.error,
                width: 2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadiusConstants.borderRadiusMedium,
              borderSide: const BorderSide(
                color: BioWayColors.error,
                width: 2,
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Este campo es obligatorio';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTemperatureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Temperatura de Fusión*',
          style: TextStyle(
            fontSize: UIConstants.fontSizeBody,
            fontWeight: FontWeight.w600,
            color: BioWayColors.darkGreen,
          ),
        ),
        SizedBox(height: UIConstants.spacing12),
        
        // Radio buttons para tipo de temperatura
        Row(
          children: [
            Expanded(
              child: RadioListTile<bool>(
                title: const Text('Única'),
                value: true,
                groupValue: _isTemperaturaUnica,
                onChanged: (value) {
                  setState(() {
                    _isTemperaturaUnica = value!;
                    _temperaturaRangoMinController.clear();
                    _temperaturaRangoMaxController.clear();
                  });
                },
                activeColor: BioWayColors.ecoceGreen,
                contentPadding: EdgeInsetsConstants.paddingNone,
                dense: true,
              ),
            ),
            Expanded(
              child: RadioListTile<bool>(
                title: const Text('Rango'),
                value: false,
                groupValue: _isTemperaturaUnica,
                onChanged: (value) {
                  setState(() {
                    _isTemperaturaUnica = value!;
                    _temperaturaUnicaController.clear();
                  });
                },
                activeColor: BioWayColors.ecoceGreen,
                contentPadding: EdgeInsetsConstants.paddingNone,
                dense: true,
              ),
            ),
          ],
        ),
        
        SizedBox(height: UIConstants.spacing12),
        
        // Selector de unidad
        Container(
          padding: EdgeInsets.symmetric(horizontal: UIConstants.spacing12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[300]!,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _unidadTemperatura,
              items: ['C°', 'K°', 'F°'].map((unidad) {
                return DropdownMenuItem(
                  value: unidad,
                  child: Text(
                    'Unidad: $unidad',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _unidadTemperatura = value!;
                });
              },
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down),
            ),
          ),
        ),
        
        SizedBox(height: UIConstants.spacing16),
        
        // Campos de temperatura según la selección
        if (_isTemperaturaUnica)
          _buildNumericField(
            label: 'Temperatura $_unidadTemperatura',
            controller: _temperaturaUnicaController,
            hint: 'Ej: 165.5',
            suffix: _unidadTemperatura,
            pattern: '5.5',
          )
        else
          Row(
            children: [
              Expanded(
                child: _buildNumericField(
                  label: 'Mínima $_unidadTemperatura',
                  controller: _temperaturaRangoMinController,
                  hint: 'Ej: 160.0',
                  suffix: _unidadTemperatura,
                  pattern: '5.5',
                ),
              ),
              SizedBox(width: UIConstants.spacing16),
              Expanded(
                child: _buildNumericField(
                  label: 'Máxima $_unidadTemperatura',
                  controller: _temperaturaRangoMaxController,
                  hint: 'Ej: 170.0',
                  suffix: _unidadTemperatura,
                  pattern: '5.5',
                ),
              ),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BioWayColors.backgroundGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: UIConstants.elevationNone,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: BioWayColors.darkGreen),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Formulario de Muestra',
          style: TextStyle(
            fontSize: UIConstants.fontSizeXLarge,
            fontWeight: FontWeight.bold,
            color: BioWayColors.darkGreen,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
        ),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
              // Header con información de la muestra
              Container(
                width: double.infinity,
                padding: EdgeInsetsConstants.paddingAll20,
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Muestra ID',
                              style: TextStyle(
                                fontSize: UIConstants.fontSizeSmall,
                                color: BioWayColors.textGrey,
                              ),
                            ),
                            Text(
                              widget.muestraId,
                              style: const TextStyle(
                                fontSize: UIConstants.fontSizeLarge,
                                fontWeight: FontWeight.bold,
                                color: BioWayColors.darkGreen,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: UIConstants.spacing16,
                            vertical: UIConstants.spacing8,
                          ),
                          decoration: BoxDecoration(
                            color: BioWayColors.info.withValues(alpha: UIConstants.opacityLow),
                            borderRadius: BorderRadiusConstants.borderRadiusLarge,
                          ),
                          child: Text(
                            '${(widget.datosMuestra['peso_muestra'] ?? 0.0).toStringAsFixed(2)} kg',
                            style: TextStyle(
                              fontSize: UIConstants.fontSizeMedium,
                              fontWeight: FontWeight.bold,
                              color: BioWayColors.info,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: UIConstants.spacing16),

              // Tarjeta de Características de la Muestra
              Container(
                margin: EdgeInsets.symmetric(horizontal: UIConstants.spacing20),
                padding: EdgeInsetsConstants.paddingAll20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadiusConstants.borderRadiusMedium,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: UIConstants.opacityVeryLow),
                      blurRadius: UIConstants.blurRadiusMedium,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsetsConstants.paddingAll8,
                          decoration: BoxDecoration(
                            color: BioWayColors.ecoceGreen.withValues(alpha: UIConstants.opacityLow),
                            borderRadius: BorderRadiusConstants.borderRadiusSmall,
                          ),
                          child: Icon(
                            Icons.science,
                            color: BioWayColors.ecoceGreen,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: UIConstants.spacing12),
                        const Text(
                          'Características de la Muestra',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: BioWayColors.darkGreen,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: UIConstants.spacing20),
                    
                    _buildNumericField(
                      label: 'Humedad',
                      controller: _humedadController,
                      hint: 'Ej: 2.45',
                      suffix: '%',
                      pattern: '100.00',
                    ),
                    SizedBox(height: UIConstants.spacing16),
                    
                    _buildNumericField(
                      label: 'Pellets por Gramo',
                      controller: _pelletsController,
                      hint: 'Ej: 25.50',
                      pattern: '10.2',
                    ),
                    SizedBox(height: UIConstants.spacing16),
                    
                    _buildStringField(
                      label: 'Tipo de Polímero (FTIR)',
                      controller: _tipoPolimeroController,
                      hint: 'Ej: Polietileno de baja densidad',
                      maxLength: 30,
                    ),
                    SizedBox(height: UIConstants.spacing20),
                    
                    _buildTemperatureSection(),
                    SizedBox(height: UIConstants.spacing16),
                    
                    _buildNumericField(
                      label: 'Contenido Orgánico',
                      controller: _contenidoOrganicoController,
                      hint: 'Ej: 98.50',
                      suffix: '%',
                      pattern: '100.00',
                    ),
                    SizedBox(height: UIConstants.spacing16),
                    
                    _buildNumericField(
                      label: 'Contenido Inorgánico',
                      controller: _contenidoInorganicoController,
                      hint: 'Ej: 1.50',
                      suffix: '%',
                      pattern: '100.00',
                    ),
                    SizedBox(height: UIConstants.spacing16),
                    
                    _buildDecimalField(
                      label: 'Tiempo de Inducción de Oxidación (OIT)',
                      controller: _oitController,
                      hint: 'Ej: 45',
                      maxLength: 6,
                    ),
                    SizedBox(height: UIConstants.spacing16),
                    
                    _buildDecimalField(
                      label: 'Índice de fluidez (MFI)',
                      controller: _mfiController,
                      hint: 'Ej: 2.16',
                      maxLength: 10,
                    ),
                    SizedBox(height: UIConstants.spacing16),
                    
                    _buildDecimalField(
                      label: 'Densidad',
                      controller: _densidadController,
                      hint: 'Ej: 0.918',
                      maxLength: 10,
                    ),
                  ],
                ),
              ),

              SizedBox(height: UIConstants.spacing16),

              // Tarjeta de Análisis
              Container(
                margin: EdgeInsets.symmetric(horizontal: UIConstants.spacing20),
                padding: EdgeInsetsConstants.paddingAll20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadiusConstants.borderRadiusMedium,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: UIConstants.opacityVeryLow),
                      blurRadius: UIConstants.blurRadiusMedium,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsetsConstants.paddingAll8,
                          decoration: BoxDecoration(
                            color: BioWayColors.info.withValues(alpha: UIConstants.opacityLow),
                            borderRadius: BorderRadiusConstants.borderRadiusSmall,
                          ),
                          child: Icon(
                            Icons.analytics,
                            color: BioWayColors.info,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: UIConstants.spacing12),
                        const Text(
                          'Análisis',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: BioWayColors.darkGreen,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: UIConstants.spacing20),
                    
                    _buildStringField(
                      label: 'Norma o Método de Referencia',
                      controller: _normaController,
                      hint: 'Ej: ASTM D5511-18',
                      maxLength: 50,
                    ),
                    SizedBox(height: UIConstants.spacing16),
                    
                    _buildStringField(
                      label: 'Observaciones / Interpretación Técnica',
                      controller: _observacionesController,
                      hint: 'Describe las observaciones técnicas del análisis...',
                      maxLength: 200,
                      maxLines: 4,
                    ),
                    SizedBox(height: UIConstants.spacing20),
                    
                    // Checkbox de cumplimiento
                    Container(
                      padding: EdgeInsetsConstants.paddingAll16,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadiusConstants.borderRadiusMedium,
                        border: Border.all(
                          color: Colors.grey[300]!,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '¿La muestra cumple con los requisitos de transformación?*',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: BioWayColors.darkGreen,
                            ),
                          ),
                          SizedBox(height: UIConstants.spacing16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              // Opción Sí
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _cumpleRequisitos = true;
                                  });
                                },
                                borderRadius: BorderRadiusConstants.borderRadiusSmall,
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: UIConstants.spacing12, vertical: UIConstants.spacing8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: _cumpleRequisitos == true 
                                                ? BioWayColors.success 
                                                : Colors.grey[400]!,
                                            width: 2,
                                          ),
                                          color: _cumpleRequisitos == true 
                                              ? BioWayColors.success 
                                              : Colors.transparent,
                                        ),
                                        child: _cumpleRequisitos == true
                                            ? const Icon(
                                                Icons.check,
                                                size: 14,
                                                color: Colors.white,
                                              )
                                            : null,
                                      ),
                                      SizedBox(width: UIConstants.spacing8),
                                      Text(
                                        'Sí',
                                        style: TextStyle(
                                          fontSize: UIConstants.fontSizeMedium + 1,
                                          fontWeight: _cumpleRequisitos == true 
                                              ? FontWeight.w600 
                                              : FontWeight.normal,
                                          color: _cumpleRequisitos == true 
                                              ? BioWayColors.success 
                                              : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: UIConstants.spacing32),
                              // Opción No
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _cumpleRequisitos = false;
                                  });
                                },
                                borderRadius: BorderRadiusConstants.borderRadiusSmall,
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: UIConstants.spacing12, vertical: UIConstants.spacing8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: _cumpleRequisitos == false 
                                                ? BioWayColors.error 
                                                : Colors.grey[400]!,
                                            width: 2,
                                          ),
                                          color: _cumpleRequisitos == false 
                                              ? BioWayColors.error 
                                              : Colors.transparent,
                                        ),
                                        child: _cumpleRequisitos == false
                                            ? const Icon(
                                                Icons.check,
                                                size: 14,
                                                color: Colors.white,
                                              )
                                            : null,
                                      ),
                                      SizedBox(width: UIConstants.spacing8),
                                      Text(
                                        'No',
                                        style: TextStyle(
                                          fontSize: UIConstants.fontSizeMedium + 1,
                                          fontWeight: _cumpleRequisitos == false 
                                              ? FontWeight.w600 
                                              : FontWeight.normal,
                                          color: _cumpleRequisitos == false 
                                              ? BioWayColors.error 
                                              : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: UIConstants.spacing20),
              
              // Datos del responsable
              Container(
                margin: EdgeInsets.symmetric(horizontal: UIConstants.spacing20),
                padding: EdgeInsetsConstants.paddingAll20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadiusConstants.borderRadiusMedium,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: UIConstants.opacityVeryLow),
                      blurRadius: UIConstants.blurRadiusMedium,
                      offset: const Offset(0, 5),
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
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF9333EA),
                          ),
                        ),
                        SizedBox(width: UIConstants.spacing4),
                        const Text(
                          '*',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: UIConstants.spacing20),
                    
                    // Nombre del Responsable
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Nombre',
                              style: TextStyle(
                                fontSize: UIConstants.fontSizeMedium,
                                fontWeight: FontWeight.w600,
                                color: BioWayColors.textGrey,
                              ),
                            ),
                            SizedBox(width: UIConstants.spacing4),
                            Text(
                              '*',
                              style: TextStyle(
                                fontSize: UIConstants.fontSizeMedium,
                                fontWeight: FontWeight.w600,
                                color: BioWayColors.error,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: UIConstants.spacing8),
                        TextFormField(
                          controller: _nombreResponsableController,
                          maxLength: 50,
                          keyboardType: TextInputType.name,
                          textInputAction: TextInputAction.done,
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
                                color: const Color(0xFF9333EA).withValues(alpha: UIConstants.opacityMediumLow),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadiusConstants.borderRadiusMedium,
                              borderSide: const BorderSide(
                                color: Color(0xFF9333EA),
                                width: 2,
                              ),
                            ),
                            counterText: '',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa el nombre del responsable';
                            }
                            if (value.length < 3) {
                              return 'El nombre debe tener al menos 3 caracteres';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    
                    SizedBox(height: UIConstants.spacing20),
                    
                    // Firma del Responsable
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Firma',
                              style: TextStyle(
                                fontSize: UIConstants.fontSizeMedium,
                                fontWeight: FontWeight.w600,
                                color: BioWayColors.textGrey,
                              ),
                            ),
                            SizedBox(width: UIConstants.spacing4),
                            Text(
                              '*',
                              style: TextStyle(
                                fontSize: UIConstants.fontSizeMedium,
                                fontWeight: FontWeight.w600,
                                color: BioWayColors.error,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: UIConstants.spacing8),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (_signaturePoints.isEmpty) {
                              _captureSignature();
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: _signaturePoints.isNotEmpty ? 150 : 100,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: _signaturePoints.isNotEmpty 
                                  ? const Color(0xFF9333EA).withValues(alpha: UIConstants.opacityVeryLow)
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
                                            aspectRatio: 2.0,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadiusConstants.borderRadiusSmall,
                                                border: Border.all(
                                                  color: Colors.grey[200]!,
                                                  width: 1,
                                                ),
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(UIConstants.radiusSmall + 1),
                                                child: FittedBox(
                                                  fit: BoxFit.contain,
                                                  child: SizedBox(
                                                    width: 300,
                                                    height: 300,
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
                                                    color: Colors.black.withValues(alpha: UIConstants.opacityLow),
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
                                                    color: Colors.black.withValues(alpha: UIConstants.opacityLow),
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
                  ],
                ),
              ),

              SizedBox(height: UIConstants.spacing20),

              // Botón de confirmación
              Container(
                margin: EdgeInsets.symmetric(horizontal: UIConstants.spacing20),
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _handleFormSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BioWayColors.ecoceGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadiusConstants.borderRadiusRound,
                    ),
                    elevation: UIConstants.elevationMedium,
                  ),
                  child: const Text(
                    'Confirmar Análisis de la Muestra',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              SizedBox(height: UIConstants.spacing40),
            ],
          ),
        ),
      ),
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: UIConstants.opacityMedium),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF9333EA), // Purple for laboratorio
                ),
              ),
            ),
        ],
      ),
    );
  }
}