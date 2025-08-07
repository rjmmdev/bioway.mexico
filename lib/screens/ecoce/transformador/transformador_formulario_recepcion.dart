import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/colors.dart';
import '../../../utils/ui_constants.dart';
import '../../../services/lote_unificado_service.dart';
import '../../../services/user_session_service.dart';
import '../../../services/firebase/firebase_storage_service.dart';
import '../../../services/firebase/auth_service.dart';
import '../../../services/carga_transporte_service.dart';
import '../shared/widgets/weight_input_widget.dart';
import '../shared/widgets/signature_dialog.dart';
import '../shared/widgets/dialog_utils.dart';
import '../shared/widgets/field_label.dart' as field_label;
import '../shared/utils/shared_input_decorations.dart';
import 'utils/transformador_navigation_helper.dart';

/// Painter personalizado para dibujar la firma con el color definido
class SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  final double strokeWidth;
  final Color color;

  SignaturePainter({
    required this.points,
    this.strokeWidth = UIConstants.strokeWidth,
    this.color = Colors.orange,
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

class TransformadorFormularioRecepcion extends StatefulWidget {
  final List<Map<String, dynamic>> lotes;
  final Map<String, dynamic> datosEntrega;
  
  const TransformadorFormularioRecepcion({
    super.key,
    required this.lotes,
    required this.datosEntrega,
  });

  @override
  State<TransformadorFormularioRecepcion> createState() => _TransformadorFormularioRecepcionState();
}

class _TransformadorFormularioRecepcionState extends State<TransformadorFormularioRecepcion> {
  final _formKey = GlobalKey<FormState>();
  final LoteUnificadoService _loteUnificadoService = LoteUnificadoService();
  final CargaTransporteService _cargaService = CargaTransporteService();
  final UserSessionService _userSession = UserSessionService();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  final AuthService _authService = AuthService();

  // Datos pre-cargados
  Map<String, dynamic>? _datosEntrega;
  List<Map<String, dynamic>> _lotes = [];
  
  // Controladores
  final TextEditingController _transportistaController = TextEditingController();
  final TextEditingController _pesoTotalOriginalController = TextEditingController();
  final TextEditingController _calidadMaterialController = TextEditingController();
  final TextEditingController _observacionesController = TextEditingController();
  final TextEditingController _operadorController = TextEditingController();
  
  // Controladores para peso individual por lote (NUEVO)
  final Map<String, TextEditingController> _pesosRecibidosControllers = {};
  final Map<String, double> _mermasCalculadas = {};
  
  // Totales calculados
  double _pesoNetoTotal = 0.0;
  double _mermaTotalCalculada = 0.0;
  
  // Firma
  List<Offset?> _signaturePoints = [];
  String? _signatureUrl;
  
  // Tipo de procesamiento
  String _tipoProcesamiento = 'pellets'; // pellets, hojuelas, otros
  
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _datosEntrega = widget.datosEntrega;
    _lotes = widget.lotes;
    _initializeForm();
    _loadPreloadedData();
  }

  @override
  void dispose() {
    // Limpiar controladores dinámicos
    _pesosRecibidosControllers.forEach((_, controller) {
      controller.dispose();
    });
    _transportistaController.dispose();
    _pesoTotalOriginalController.dispose();
    _calidadMaterialController.dispose();
    _observacionesController.dispose();
    _operadorController.dispose();
    super.dispose();
  }

  void _initializeForm() async {
    // Pre-cargar nombre del operador
    final userData = _userSession.getUserData();
    if (userData != null && userData['nombre'] != null) {
      _operadorController.text = userData['nombre'];
    }
    
    // Crear controladores para cada lote
    for (final lote in _lotes) {
      final loteId = lote['id'] as String;
      _pesosRecibidosControllers[loteId] = TextEditingController();
      _mermasCalculadas[loteId] = 0.0;
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  void _loadPreloadedData() {
    if (_datosEntrega != null) {
      // Pre-cargar datos del transportista
      _transportistaController.text = _datosEntrega!['transportista_folio'] ?? '';
      
      // Pre-cargar peso total
      final pesoTotal = _datosEntrega!['peso_total'] ?? 0.0;
      _pesoTotalOriginalController.text = pesoTotal.toString();
    }
  }


  void _calcularMermaIndividual(String loteId) {
    final lote = _lotes.firstWhere((l) => l['id'] == loteId, orElse: () => {});
    if (lote.isEmpty) return;
    
    final pesoBruto = (lote['peso'] ?? 0.0).toDouble();
    final controllerNeto = _pesosRecibidosControllers[loteId];
    if (controllerNeto == null) return;
    
    final pesoNeto = double.tryParse(controllerNeto.text) ?? 0;
    
    setState(() {
      // Validar que el peso recibido no sea mayor al peso bruto
      if (pesoNeto > pesoBruto) {
        // Auto-corregir al peso máximo permitido
        _pesosRecibidosControllers[loteId]?.text = pesoBruto.toString();
        _mermasCalculadas[loteId] = 0.0;
      } else if (pesoNeto > 0) {
        _mermasCalculadas[loteId] = pesoBruto - pesoNeto;
      } else {
        _mermasCalculadas[loteId] = 0.0;
      }
      
      // Recalcular totales
      _actualizarTotales();
    });
  }
  
  void _actualizarTotales() {
    double pesoNetoTotal = 0;
    double mermaTotal = 0;
    
    _pesosRecibidosControllers.forEach((loteId, controller) {
      final pesoNeto = double.tryParse(controller.text) ?? 0;
      if (pesoNeto > 0) {
        pesoNetoTotal += pesoNeto;
      }
    });
    
    _mermasCalculadas.forEach((_, merma) {
      mermaTotal += merma;
    });
    
    setState(() {
      _pesoNetoTotal = pesoNetoTotal;
      _mermaTotalCalculada = mermaTotal;
    });
  }

  void _captureSignature() async {
    // Primero ocultar el teclado
    FocusScope.of(context).unfocus();
    
    // Esperar un breve momento para que el teclado se oculte completamente
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (!mounted) return;
    
    SignatureDialog.show(
      context: context,
      title: 'Firma del Responsable',
      initialSignature: _signaturePoints,
      onSignatureSaved: (points) {
        setState(() {
          _signaturePoints = List.from(points);
          _signatureUrl = null;
        });
      },
      primaryColor: Colors.orange,
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Validar que todos los lotes tengan peso ingresado
    bool todosLosPesosIngresados = true;
    
    for (final lote in _lotes) {
      final loteId = lote['id'] as String;
      final pesoText = _pesosRecibidosControllers[loteId]?.text ?? '';
      final peso = double.tryParse(pesoText) ?? 0;
      
      if (peso <= 0) {
        todosLosPesosIngresados = false;
        break;
      }
    }
    
    if (!todosLosPesosIngresados) {
      if (mounted) {
        DialogUtils.showErrorDialog(
          context,
          title: 'Pesos Incompletos',
          message: 'Por favor ingrese el peso neto aprovechable para todos los lotes antes de continuar.',
        );
      }
      return;
    }
    
    // Validar merma excesiva (opcional - mostrar advertencia)
    final pesoTotalOriginal = double.tryParse(_pesoTotalOriginalController.text) ?? 0;
    if (_mermaTotalCalculada > 0 && pesoTotalOriginal > 0) {
      final porcentajeMerma = (_mermaTotalCalculada / pesoTotalOriginal) * 100;
      if (porcentajeMerma > 10) {
        final confirmar = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning, color: BioWayColors.warning),
                SizedBox(width: UIConstants.spacing8),
                const Text('Merma Alta Detectada'),
              ],
            ),
            content: Text(
              'La merma total es del ${porcentajeMerma.toStringAsFixed(1)}%, lo cual supera el 10% esperado.\n\n¿Desea continuar con estos valores?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Revisar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BioWayColors.warning,
                ),
                child: const Text('Continuar'),
              ),
            ],
          ),
        );
        
        if (confirmar != true) {
          return;
        }
      }
    }

    if (_signaturePoints.isEmpty) {
      if (mounted) {
        DialogUtils.showErrorDialog(
          context,
          title: 'Firma Requerida',
          message: 'Por favor capture la firma del responsable antes de continuar.',
        );
      }
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

      // Marcar entrega como completada
      if (_datosEntrega != null && _datosEntrega!['entrega_id'] != null) {
        await _cargaService.completarEntrega(
          entregaId: _datosEntrega!['entrega_id'],
          firmaEntrega: _signatureUrl!,
          evidenciasFotoEntrega: [],
          comentariosEntrega: _observacionesController.text,
        );
      }

      // Procesar cada lote recibido con pesos individuales
      for (final lote in _lotes) {
        final loteId = lote['id'] as String;
        
        // Obtener los valores individuales de peso y merma para este lote
        final pesoRecibidoIndividual = double.tryParse(_pesosRecibidosControllers[loteId]?.text ?? '0') ?? 0;
        final mermaIndividual = _mermasCalculadas[loteId] ?? 0;
        
        // Actualizar el lote en el sistema unificado para reflejar que fue recibido por el transformador
        await _loteUnificadoService.transferirLote(
          loteId: loteId,
          procesoDestino: 'transformador',
          usuarioDestinoFolio: _userSession.getUserData()?['folio'] ?? '',
          datosIniciales: {
            'usuario_id': _authService.currentUser?.uid,
            'fecha_entrada': FieldValue.serverTimestamp(),
            'fecha_creacion': FieldValue.serverTimestamp(),
            'peso_entrada': lote['peso'],  // Peso original del lote
            'peso_recibido': pesoRecibidoIndividual,  // Peso neto individual
            'peso_neto': pesoRecibidoIndividual,  // Peso neto aprovechable
            'peso_procesado': pesoRecibidoIndividual,  // NUEVO: Para compatibilidad con pesoActual
            'merma_recepcion': mermaIndividual,  // Merma individual calculada
            'tipos_analisis': [_tipoProcesamiento],
            'producto_fabricado': _tipoProcesamiento == 'pellets' ? 'Pellets' : 
                               _tipoProcesamiento == 'hojuelas' ? 'Hojuelas' : 'Otros',
            'composicion_material': _calidadMaterialController.text,
            'operador_recibe': _userSession.getUserData()?['nombre'] ?? 'Sin nombre',
            'firma_recibe': _signatureUrl,
            'comentarios': _observacionesController.text,
            'proveedor': _datosEntrega!['transportista_nombre'] ?? 'Sin especificar',
            // Guardar estado en especificaciones como espera la pantalla de producción
            'especificaciones': {
              'estado': 'pendiente',
              'tipo_procesamiento': _tipoProcesamiento,
              'calidad_material': _calidadMaterialController.text,
            },
          },
        );

        // Ya no es necesario crear registro en la colección antigua
        // El sistema unificado maneja todo
      }

      if (mounted) {
        DialogUtils.showSuccessDialog(
          context,
          title: 'Recepción Exitosa',
          message: 'Los materiales han sido recibidos correctamente. Puede proceder con el procesamiento.',
          onAccept: () {
            // Navegar a la pantalla de producción en la pestaña de Salida
            TransformadorNavigationHelper.navigateAfterReception(context);
          },
        );
      }
    } catch (e) {
      if (mounted) {
        DialogUtils.showErrorDialog(
          context,
          title: 'Error',
          message: 'Error al procesar la recepción: ${e.toString()}',
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

  Future<String?> _uploadSignature() async {
    if (_signaturePoints.isEmpty) return null;

    try {
      // Crear imagen de la firma
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = Size(UIConstants.signatureSize, UIConstants.signatureSize / 2);
      
      // Fondo blanco
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.white,
      );
      
      // Dibujar la firma con color personalizado
      final paint = Paint()
        ..color = Colors.orange
        ..strokeCap = StrokeCap.round
        ..strokeWidth = UIConstants.strokeWidth;
      
      for (int i = 0; i < _signaturePoints.length - 1; i++) {
        if (_signaturePoints[i] != null && _signaturePoints[i + 1] != null) {
          canvas.drawLine(_signaturePoints[i]!, _signaturePoints[i + 1]!, paint);
        }
      }
      
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
        'firmas/transformador/${_authService.currentUser?.uid}',
      );
      
      // Eliminar archivo temporal
      await file.delete();
      
      return url;
    } catch (e) {
      debugPrint('Error al subir firma: $e');
      return null;
    }
  }

  Widget _buildResumenTotales() {
    final pesoTotalOriginal = double.tryParse(_pesoTotalOriginalController.text) ?? 0;
    final porcentajeMerma = pesoTotalOriginal > 0 ? (_mermaTotalCalculada / pesoTotalOriginal) * 100 : 0;
    
    return Container(
      padding: EdgeInsets.all(UIConstants.spacing16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withValues(alpha: UIConstants.opacityVeryLow),
            Colors.orange.withValues(alpha: UIConstants.opacityVeryLow / 2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadiusConstants.borderRadiusMedium,
        border: Border.all(
          color: Colors.orange.withValues(alpha: UIConstants.opacityLow),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.summarize,
                color: Colors.orange,
                size: UIConstants.iconSizeMedium,
              ),
              SizedBox(width: UIConstants.spacing8),
              const Text(
                'Resumen de Totales',
                style: TextStyle(
                  fontSize: UIConstants.fontSizeBody,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: UIConstants.spacing12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Peso Bruto Total:',
                style: TextStyle(
                  fontSize: UIConstants.fontSizeMedium,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '${pesoTotalOriginal.toStringAsFixed(2)} kg',
                style: const TextStyle(
                  fontSize: UIConstants.fontSizeMedium,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: UIConstants.spacing8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Peso Neto Total:',
                style: TextStyle(
                  fontSize: UIConstants.fontSizeMedium,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '${_pesoNetoTotal.toStringAsFixed(2)} kg',
                style: TextStyle(
                  fontSize: UIConstants.fontSizeMedium,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          SizedBox(height: UIConstants.spacing8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Merma Total:',
                style: TextStyle(
                  fontSize: UIConstants.fontSizeMedium,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '${_mermaTotalCalculada.toStringAsFixed(2)} kg (${porcentajeMerma.toStringAsFixed(1)}%)',
                style: TextStyle(
                  fontSize: UIConstants.fontSizeMedium,
                  fontWeight: FontWeight.w600,
                  color: porcentajeMerma > 10 ? BioWayColors.warning : Colors.orange[700],
                ),
              ),
            ],
          ),
          if (porcentajeMerma > 10) ...[
            SizedBox(height: UIConstants.spacing12),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: UIConstants.spacing12,
                vertical: UIConstants.spacing8,
              ),
              decoration: BoxDecoration(
                color: BioWayColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadiusConstants.borderRadiusSmall,
                border: Border.all(
                  color: BioWayColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    size: UIConstants.iconSizeSmall,
                    color: BioWayColors.warning,
                  ),
                  SizedBox(width: UIConstants.spacing8),
                  Expanded(
                    child: Text(
                      'La merma supera el 10% esperado',
                      style: TextStyle(
                        fontSize: UIConstants.fontSizeSmall,
                        fontWeight: FontWeight.w600,
                        color: BioWayColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildLoteInfo(Map<String, dynamic> lote) {
    final loteId = lote['id'] as String;
    final pesoOriginal = (lote['peso'] ?? 0.0).toDouble();
    final merma = _mermasCalculadas[loteId] ?? 0.0;
    final porcentajeMerma = pesoOriginal > 0 ? (merma / pesoOriginal * 100) : 0.0;
    
    return Container(
      margin: EdgeInsets.only(bottom: UIConstants.spacing16),
      padding: EdgeInsetsConstants.paddingAll16,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadiusConstants.borderRadiusMedium,
        border: Border.all(
          color: porcentajeMerma > 10 
            ? Colors.orange.withValues(alpha: UIConstants.opacityMedium)
            : Colors.grey[300]!,
          width: porcentajeMerma > 10 ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con información del lote - IDÉNTICO AL RECICLADOR
          Row(
            children: [
              Icon(
                Icons.inventory_2,
                color: Colors.orange, // Color naranja para Transformador
                size: UIConstants.iconSizeMedium,
              ),
              SizedBox(width: UIConstants.spacing8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lote['material'] ?? 'Material',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: UIConstants.fontSizeMedium,
                      ),
                    ),
                    Text(
                      'ID: ${loteId.substring(0, 8)}...',
                      style: TextStyle(
                        fontSize: UIConstants.fontSizeXSmall,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Indicador de merma alta
              if (porcentajeMerma > 10)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: UIConstants.spacing8,
                    vertical: UIConstants.spacing4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: UIConstants.opacityVeryLow),
                    borderRadius: BorderRadiusConstants.borderRadiusSmall,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 14,
                        color: Colors.orange,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Merma alta',
                        style: TextStyle(
                          fontSize: UIConstants.fontSizeXSmall,
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          
          SizedBox(height: UIConstants.spacing16),
          
          // Peso bruto - IDÉNTICO AL RECICLADOR
          Container(
            padding: EdgeInsetsConstants.paddingAll12,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadiusConstants.borderRadiusSmall,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Peso Bruto:',
                  style: TextStyle(
                    fontSize: UIConstants.fontSizeMedium,
                    color: BioWayColors.textGrey,
                  ),
                ),
                Text(
                  '${pesoOriginal.toStringAsFixed(1)} kg',
                  style: const TextStyle(
                    fontSize: UIConstants.fontSizeMedium,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: UIConstants.spacing12),
          
          // Input peso neto - USANDO WeightInputWidget COMO RECICLADOR
          const field_label.FieldLabel(
            text: 'Peso Neto Aprovechable',
            isRequired: true,
          ),
          SizedBox(height: UIConstants.spacing8),
          WeightInputWidget(
            controller: _pesosRecibidosControllers[loteId]!,
            label: 'Ingrese el peso real recibido',
            primaryColor: Colors.orange, // Color naranja para Transformador
            onChanged: (value) => _calcularMermaIndividual(loteId),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingrese el peso recibido';
              }
              final peso = double.tryParse(value);
              if (peso == null || peso <= 0) {
                return 'Ingrese un peso válido';
              }
              if (peso > pesoOriginal) {
                return 'No puede exceder ${pesoOriginal.toStringAsFixed(1)} kg';
              }
              return null;
            },
          ),
          
          SizedBox(height: UIConstants.spacing12),
          
          // Merma calculada - IDÉNTICO AL RECICLADOR pero con colores del Transformador
          Container(
            padding: EdgeInsetsConstants.paddingAll12,
            decoration: BoxDecoration(
              color: porcentajeMerma > 10
                ? BioWayColors.warning.withValues(alpha: 0.05)
                : Colors.orange[50],
              borderRadius: BorderRadiusConstants.borderRadiusSmall,
              border: Border.all(
                color: porcentajeMerma > 10
                  ? BioWayColors.warning.withValues(alpha: 0.3)
                  : Colors.orange[200]!,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.trending_down,
                  color: porcentajeMerma > 10 ? BioWayColors.warning : Colors.orange,
                  size: UIConstants.iconSizeSmall,
                ),
                SizedBox(width: UIConstants.spacing8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Merma:',
                        style: TextStyle(
                          fontSize: UIConstants.fontSizeSmall,
                          color: BioWayColors.textGrey,
                        ),
                        ),
                        Text(
                          '${merma.toStringAsFixed(1)} kg (${porcentajeMerma.toStringAsFixed(1)}%)',
                          style: TextStyle(
                            fontSize: UIConstants.fontSizeMedium,
                            fontWeight: FontWeight.bold,
                            color: porcentajeMerma > 10 ? BioWayColors.warning : Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.orange,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.orange,
        elevation: UIConstants.elevationNone,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Recepción de Materiales',
          style: TextStyle(
            fontSize: UIConstants.fontSizeLarge,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsetsConstants.paddingAll16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Información del transportista
              Container(
                padding: EdgeInsetsConstants.paddingAll16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: UIConstants.opacityVeryLow),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.local_shipping,
                          color: Colors.orange,
                          size: UIConstants.iconSizeMedium,
                        ),
                        SizedBox(width: UIConstants.spacing12),
                        const Text(
                          'Información de Entrega',
                          style: TextStyle(
                            fontSize: UIConstants.fontSizeBody + 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: UIConstants.spacing16),
                    TextFormField(
                      controller: _transportistaController,
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'Transportista',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadiusConstants.borderRadiusMedium,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: UIConstants.spacing16),
              
              // Lista de lotes
              Container(
                padding: EdgeInsetsConstants.paddingAll16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: UIConstants.opacityVeryLow),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.precision_manufacturing,
                          color: Colors.orange,
                          size: UIConstants.iconSizeMedium,
                        ),
                        SizedBox(width: UIConstants.spacing12),
                        Text(
                          'Materiales Recibidos (${_lotes.length})',
                          style: const TextStyle(
                            fontSize: UIConstants.fontSizeBody + 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: UIConstants.spacing16),
                    ..._lotes.map((lote) => _buildLoteInfo(lote)),
                    
                    // Resumen de totales si hay múltiples lotes
                    if (_lotes.length > 1) ...[
                      SizedBox(height: UIConstants.spacing16),
                      _buildResumenTotales(),
                    ],
                  ],
                ),
              ),
              
              SizedBox(height: UIConstants.spacing16),
              
              // Información del procesamiento
              Container(
                padding: EdgeInsetsConstants.paddingAll16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: UIConstants.opacityVeryLow),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.settings,
                          color: Colors.orange,
                          size: UIConstants.iconSizeMedium,
                        ),
                        SizedBox(width: UIConstants.spacing12),
                        const Text(
                          'Datos de Procesamiento',
                          style: TextStyle(
                            fontSize: UIConstants.fontSizeBody + 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: UIConstants.spacing16),
                    
                    // Tipo de procesamiento
                    const Text(
                      'Tipo de Procesamiento',
                      style: TextStyle(
                        fontSize: UIConstants.fontSizeMedium,
                        fontWeight: FontWeight.w600,
                        color: BioWayColors.textGrey,
                      ),
                    ),
                    SizedBox(height: UIConstants.spacing8),
                    Wrap(
                      spacing: UIConstants.spacing8,
                      children: [
                        ChoiceChip(
                          label: const Text('Pellets'),
                          selected: _tipoProcesamiento == 'pellets',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _tipoProcesamiento = 'pellets';
                              });
                            }
                          },
                          selectedColor: Colors.orange.withValues(alpha: UIConstants.opacityMediumLow),
                          backgroundColor: Colors.grey[100],
                          labelStyle: TextStyle(
                            color: _tipoProcesamiento == 'pellets'
                                ? Colors.orange
                                : Colors.grey[700],
                            fontWeight: _tipoProcesamiento == 'pellets'
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          checkmarkColor: Colors.orange,
                        ),
                        ChoiceChip(
                          label: const Text('Hojuelas'),
                          selected: _tipoProcesamiento == 'hojuelas',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _tipoProcesamiento = 'hojuelas';
                              });
                            }
                          },
                          selectedColor: Colors.orange.withValues(alpha: UIConstants.opacityMediumLow),
                          backgroundColor: Colors.grey[100],
                          labelStyle: TextStyle(
                            color: _tipoProcesamiento == 'hojuelas'
                                ? Colors.orange
                                : Colors.grey[700],
                            fontWeight: _tipoProcesamiento == 'hojuelas'
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          checkmarkColor: Colors.orange,
                        ),
                        ChoiceChip(
                          label: const Text('Otros'),
                          selected: _tipoProcesamiento == 'otros',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _tipoProcesamiento = 'otros';
                              });
                            }
                          },
                          selectedColor: Colors.orange.withValues(alpha: UIConstants.opacityMediumLow),
                          backgroundColor: Colors.grey[100],
                          labelStyle: TextStyle(
                            color: _tipoProcesamiento == 'otros'
                                ? Colors.orange
                                : Colors.grey[700],
                            fontWeight: _tipoProcesamiento == 'otros'
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          checkmarkColor: Colors.orange,
                        ),
                      ],
                    ),
                    
                    SizedBox(height: UIConstants.spacing16),
                    
                    // Calidad del Material con marco gris
                    const field_label.FieldLabel(
                      text: 'Calidad del Material',
                      isRequired: true,
                    ),
                    SizedBox(height: UIConstants.spacing8),
                    Container(
                      padding: EdgeInsetsConstants.paddingAll12,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadiusConstants.borderRadiusMedium,
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextFormField(
                        controller: _calidadMaterialController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Describe el estado del material: limpieza, compactación, contaminación, etc.',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: UIConstants.fontSizeMedium,
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: UIConstants.spacing12, vertical: UIConstants.spacing8),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor describa la calidad del material';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: UIConstants.spacing16),
              
              // Observaciones
              Container(
                padding: EdgeInsetsConstants.paddingAll16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: UIConstants.opacityVeryLow),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.comment,
                          color: Colors.orange,
                          size: UIConstants.iconSizeMedium,
                        ),
                        SizedBox(width: UIConstants.spacing12),
                        const Text(
                          'Observaciones',
                          style: TextStyle(
                            fontSize: UIConstants.fontSizeBody + 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: UIConstants.spacing16),
                    
                    // Observaciones con marco gris
                    const field_label.FieldLabel(
                      text: 'Observaciones adicionales',
                      isRequired: false,
                    ),
                    SizedBox(height: UIConstants.spacing8),
                    Container(
                      padding: EdgeInsetsConstants.paddingAll12,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadiusConstants.borderRadiusMedium,
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextFormField(
                        controller: _observacionesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Ingresa comentarios adicionales sobre la recepción del material (opcional)',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: UIConstants.fontSizeMedium,
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: UIConstants.spacing12, vertical: UIConstants.spacing8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: UIConstants.spacing16),
              
              // Datos del Responsable
              Container(
                padding: EdgeInsetsConstants.paddingAll16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: UIConstants.opacityVeryLow),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
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
                          color: Colors.orange,
                          size: UIConstants.iconSizeMedium,
                        ),
                        SizedBox(width: UIConstants.spacing12),
                        const Expanded(
                          child: Text(
                            'Datos del Responsable que Recibe el Material',
                            style: TextStyle(
                              fontSize: UIConstants.fontSizeBody + 2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Text(
                          '*',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: UIConstants.fontSizeBody + 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: UIConstants.spacing16),
                    
                    // Nombre del Operador
                    const field_label.FieldLabel(
                      text: 'Nombre del Operador',
                      isRequired: true,
                    ),
                    SizedBox(height: UIConstants.spacing8),
                    TextFormField(
                      controller: _operadorController,
                      decoration: SharedInputDecorations.ecoceStyle(
                        hintText: 'Ingrese el nombre completo',
                        primaryColor: Colors.orange,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingrese el nombre del operador';
                        }
                        if (value.length < 3) {
                          return 'El nombre debe tener al menos 3 caracteres';
                        }
                        return null;
                      },
                    ),
                    
                    SizedBox(height: UIConstants.spacing20),
                    
                    // Firma del Operador
                    const field_label.FieldLabel(
                      text: 'Firma',
                      isRequired: true,
                    ),
                    SizedBox(height: UIConstants.spacing8),
                    GestureDetector(
                      onTap: _signaturePoints.isEmpty ? _captureSignature : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: _signaturePoints.isNotEmpty ? 150 : 100,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: _signaturePoints.isNotEmpty 
                              ? Colors.orange.withValues(alpha: 0.05)
                              : Colors.grey[50],
                          borderRadius: BorderRadiusConstants.borderRadiusMedium,
                          border: Border.all(
                            color: _signaturePoints.isNotEmpty 
                                ? Colors.orange 
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
                                      size: UIConstants.iconSizeLarge,
                                      color: Colors.grey[400],
                                    ),
                                    SizedBox(height: UIConstants.spacing8),
                                    Text(
                                      'Toque para firmar',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: UIConstants.fontSizeMedium,
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
                                            borderRadius: BorderRadius.circular(7),
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
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                          child: IconButton(
                                            onPressed: _captureSignature,
                                            icon: Icon(
                                              Icons.edit,
                                              color: Colors.orange,
                                              size: UIConstants.iconSizeMedium,
                                            ),
                                            constraints: const BoxConstraints(
                                              minWidth: 32,
                                              minHeight: 32,
                                            ),
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
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                          child: IconButton(
                                            onPressed: () {
                                              setState(() {
                                                _signaturePoints.clear();
                                              });
                                            },
                                            icon: Icon(Icons.clear, size: UIConstants.iconSizeMedium - 4),
                                            color: Colors.red,
                                            padding: EdgeInsets.all(UIConstants.spacing8),
                                            constraints: const BoxConstraints(
                                              minWidth: UIConstants.iconSizeLarge + UIConstants.spacing12,
                                              minHeight: UIConstants.iconSizeLarge + UIConstants.spacing12,
                                            ),
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
              
              SizedBox(height: UIConstants.spacing24),
              
              // Botón de enviar
              SizedBox(
                height: UIConstants.buttonHeightLarge,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
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
                              width: UIConstants.iconSizeMedium - 4,
                              height: UIConstants.iconSizeMedium - 4,
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
                          'Confirmar Recepción',
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
}