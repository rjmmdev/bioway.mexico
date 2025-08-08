import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import '../../../utils/colors.dart';
import '../../../utils/ui_constants.dart';
import '../../../services/lote_unificado_service.dart';
import '../../../services/user_session_service.dart';
import '../../../services/firebase/firebase_storage_service.dart';
import '../../../services/firebase/auth_service.dart';
import '../../../services/firebase/firebase_manager.dart';
import '../../../services/carga_transporte_service.dart';
import '../shared/widgets/weight_input_widget.dart';
import '../shared/widgets/signature_dialog.dart';
import '../shared/widgets/dialog_utils.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import '../shared/widgets/required_field_label.dart';
import '../shared/widgets/field_label.dart' as field_label;
import '../shared/utils/shared_input_decorations.dart';

/// Painter personalizado para dibujar la firma con el color definido
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
      ..color = BioWayColors.darkGreen
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

class RecicladorFormularioRecepcion extends StatefulWidget {
  final List<Map<String, dynamic>> lotes;
  final Map<String, dynamic> datosEntrega;
  
  const RecicladorFormularioRecepcion({
    super.key,
    required this.lotes,
    required this.datosEntrega,
  });

  @override
  State<RecicladorFormularioRecepcion> createState() => _RecicladorFormularioRecepcionState();
}

class _RecicladorFormularioRecepcionState extends State<RecicladorFormularioRecepcion> {
  final _formKey = GlobalKey<FormState>();
  final LoteUnificadoService _loteUnificadoService = LoteUnificadoService();
  final CargaTransporteService _cargaService = CargaTransporteService();
  final UserSessionService _userSession = UserSessionService();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  final AuthService _authService = AuthService();
  final FirebaseManager _firebaseManager = FirebaseManager();

  // Datos pre-cargados
  Map<String, dynamic>? _datosEntrega;
  List<Map<String, dynamic>> _lotes = [];
  
  // Controladores
  final TextEditingController _transportistaController = TextEditingController();
  final TextEditingController _pesoTotalOriginalController = TextEditingController();
  final TextEditingController _operadorController = TextEditingController();
  final TextEditingController _comentariosController = TextEditingController();
  
  // Controladores para peso individual por lote
  final Map<String, TextEditingController> _pesosRecibidosControllers = {};
  final Map<String, double> _mermasCalculadas = {};
  
  // Totales calculados
  double _pesoNetoTotal = 0.0;
  double _mermaTotalCalculada = 0.0;
  
  // Firma
  List<Offset?> _signaturePoints = [];
  String? _signatureUrl;
  
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _datosEntrega = widget.datosEntrega;
    _lotes = widget.lotes;
    _initializeForm();
    _loadPreloadedData();
    _initializeWeightControllers();
  }

  void _initializeForm() async {
    // NO pre-cargar el nombre del operador - el usuario debe ingresarlo manualmente
    // Dejar el campo vacío para que el responsable ingrese su nombre
    // final userData = _userSession.getUserData();
    // _operadorController.text = userData?['nombre'] ?? '';
    setState(() {
      _isLoading = false;
    });
  }
  
  void _initializeWeightControllers() {
    // Crear un controlador de peso para cada lote
    for (final lote in _lotes) {
      final loteId = lote['id'] as String;
      _pesosRecibidosControllers[loteId] = TextEditingController();
      _mermasCalculadas[loteId] = 0.0;
    }
  }
  
  @override
  void dispose() {
    _transportistaController.dispose();
    _pesoTotalOriginalController.dispose();
    _operadorController.dispose();
    _comentariosController.dispose();
    
    // Limpiar controladores de peso individual
    for (final controller in _pesosRecibidosControllers.values) {
      controller.dispose();
    }
    
    super.dispose();
  }

  void _loadPreloadedData() {
    if (_datosEntrega != null) {
      // Pre-cargar datos del transportista
      final folioTransportista = _datosEntrega!['transportista_folio'] ?? '';
      final nombreTransportista = _datosEntrega!['transportista_nombre'] ?? '';
      
      // Mostrar nombre y folio si está disponible
      if (nombreTransportista.isNotEmpty) {
        _transportistaController.text = '$nombreTransportista ($folioTransportista)';
      } else {
        _transportistaController.text = folioTransportista;
      }
      
      // Pre-cargar peso total
      final pesoTotal = _datosEntrega!['peso_total'] ?? 0.0;
      _pesoTotalOriginalController.text = pesoTotal.toString();
      // No pre-cargar el peso recibido - dejar que el usuario lo ingrese
    }
  }

  void _calcularMermaIndividual(String loteId) {
    // Buscar el lote específico
    final lote = _lotes.firstWhere((l) => l['id'] == loteId);
    final pesoOriginal = (lote['peso'] ?? 0.0).toDouble();
    final pesoRecibido = double.tryParse(_pesosRecibidosControllers[loteId]?.text ?? '0') ?? 0;
    
    setState(() {
      // Validar que el peso recibido no sea mayor al peso bruto
      if (pesoRecibido > pesoOriginal) {
        _pesosRecibidosControllers[loteId]?.text = pesoOriginal.toString();
        _mermasCalculadas[loteId] = 0.0;
      } else {
        _mermasCalculadas[loteId] = pesoOriginal - pesoRecibido;
      }
      
      // Recalcular totales
      _calcularTotales();
    });
  }
  
  void _calcularTotales() {
    double pesoNetoTotal = 0.0;
    double mermaTotal = 0.0;
    
    for (final lote in _lotes) {
      final loteId = lote['id'] as String;
      final pesoRecibido = double.tryParse(_pesosRecibidosControllers[loteId]?.text ?? '0') ?? 0;
      pesoNetoTotal += pesoRecibido;
      mermaTotal += _mermasCalculadas[loteId] ?? 0.0;
    }
    
    setState(() {
      _pesoNetoTotal = pesoNetoTotal;
      _mermaTotalCalculada = mermaTotal;
    });
  }

  Future<void> _captureSignature() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();
    
    // Wait for keyboard to hide
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Check if still mounted
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
      primaryColor: BioWayColors.primaryGreen,
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
          message: 'Por favor ingrese el peso recibido para todos los lotes antes de continuar.',
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
          message: 'Por favor capture la firma del operador antes de continuar.',
        );
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Subir firma
      if (_signaturePoints.isNotEmpty) {
        _signatureUrl = await _uploadSignature();
        if (_signatureUrl == null) {
          throw Exception('Error al subir la firma');
        }
      }

      // Marcar entrega como completada
      if (_datosEntrega != null && _datosEntrega!['entrega_id'] != null) {
        await _cargaService.completarEntrega(
          entregaId: _datosEntrega!['entrega_id'],
          firmaEntrega: _signatureUrl!,
          evidenciasFotoEntrega: [],
          comentariosEntrega: '', // No comments field anymore
        );
      }

      // Obtener el ID del usuario actual (reciclador) antes del loop
      final currentUserId = _authService.currentUser?.uid;
      final currentUserData = _userSession.getUserData();
      
      // Obtener el carga_id del primer lote (todos deberían tener el mismo)
      String? cargaId;
      
      // Procesar cada lote recibido
      for (final lote in _lotes) {
        final loteId = lote['id'] as String;
        
        // Obtener información del transporte para conseguir el carga_id
        if (cargaId == null) {
          final transporteActivo = await _loteUnificadoService.obtenerTransporteActivo(loteId);
          if (transporteActivo != null && transporteActivo['carga_id'] != null) {
            cargaId = transporteActivo['carga_id'];
          }
        }
        
        debugPrint('=== DATOS DEL USUARIO RECICLADOR ===');
        debugPrint('User ID: $currentUserId');
        debugPrint('User Folio: ${currentUserData?['folio']}');
        debugPrint('User Nombre: ${currentUserData?['nombre']}');
        
        // Obtener los valores individuales de peso y merma para este lote
        final pesoRecibidoIndividual = double.tryParse(_pesosRecibidosControllers[loteId]?.text ?? '0') ?? 0;
        final mermaIndividual = _mermasCalculadas[loteId] ?? 0;
        
        // Crear o actualizar el proceso reciclador con la información de recepción individual
        await _loteUnificadoService.crearOActualizarProceso(
          loteId: loteId,
          proceso: 'reciclador',
          datos: {
            'usuario_id': currentUserId,
            'reciclador_id': currentUserId, // Agregar explícitamente el reciclador_id
            'usuario_folio': currentUserData?['folio'] ?? '',
            'fecha_recepcion': FieldValue.serverTimestamp(),
            'peso_entrada': lote['peso'],  // Peso original del lote
            'peso_recibido': pesoRecibidoIndividual,  // Peso neto individual
            'peso_neto': pesoRecibidoIndividual,  // Peso neto individual
            'peso_procesado': pesoRecibidoIndividual,  // NUEVO: Peso procesado = peso neto recibido para que pesoActual lo use
            'merma_recepcion': mermaIndividual,  // Merma individual calculada
            'firma_operador': _signatureUrl,
            'operador_nombre': _operadorController.text.trim(),
            'comentarios_recepcion': _comentariosController.text.trim(),
            'recepcion_completada': true, // Marcar que el reciclador completó su parte
          },
        );
        
        // Actualizar datos del transporte para marcar que fue recibido
        await _loteUnificadoService.actualizarProcesoTransporte(
          loteId: loteId,
          datos: {
            'recibido_por': _userSession.getUserData()?['folio'] ?? '',
            'fecha_recepcion_destinatario': FieldValue.serverTimestamp(),
          },
        );
        
        // Verificar si la transferencia está completa y transferir el lote
        await _loteUnificadoService.transferirLote(
          loteId: loteId,
          procesoDestino: 'reciclador',
          usuarioDestinoFolio: currentUserData?['folio'] ?? '',
          datosIniciales: {
            'usuario_id': currentUserId,
            'reciclador_id': currentUserId,
          }, // Asegurar que se use el ID correcto
        );
        
        // Depurar el estado del lote después de la transferencia
        await _loteUnificadoService.depurarEstadoLote(loteId);
        
        // Ya no es necesario crear registro en la colección antigua
        // Todo se maneja en la estructura unificada
      }

      // Actualizar el estado de la carga si tenemos el carga_id
      if (cargaId != null) {
        await _cargaService.actualizarEstadoCarga(cargaId);
      }

      // Actualizar estadísticas del usuario
      final userProfile = await _userSession.getUserProfile();
      if (userProfile != null && currentUserId != null) {
        // Actualizar contador en el perfil del usuario
        final firestore = FirebaseFirestore.instanceFor(app: _firebaseManager.currentApp!);
        await firestore
          .collection('ecoce_profiles/reciclador/usuarios')
          .doc(currentUserId)
          .update({
            'estadisticas.lotes_recibidos': FieldValue.increment(_lotes.length),
            'estadisticas.ultima_actualizacion': FieldValue.serverTimestamp(),
            'ecoce_lotes_totales_recibidos': FieldValue.increment(_lotes.length), // Mantener compatibilidad
          });
      }

      if (mounted) {
        DialogUtils.showSuccessDialog(
          context,
          title: 'Recepción Exitosa',
          message: 'Los lotes han sido recibidos correctamente.',
          onAccept: () {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/reciclador_lotes',
              (route) => false,
              arguments: {'initialTab': 0}, // Ir a la pestaña de Salida
            );
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
      final painter = SignaturePainter(
        points: _signaturePoints,
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
        'firmas/reciclador/${_authService.currentUser?.uid}',
      );
      
      // Eliminar archivo temporal
      await file.delete();
      
      return url;
    } catch (e) {
      debugPrint('Error al subir firma: $e');
      return null;
    }
  }

  Widget _buildLoteInfo(Map<String, dynamic> lote) {
    return Container(
      margin: EdgeInsets.only(bottom: UIConstants.spacing8),
      padding: EdgeInsetsConstants.paddingAll12,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadiusConstants.borderRadiusMedium,
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            width: UIConstants.iconContainerMedium,
            height: UIConstants.iconContainerMedium,
            decoration: BoxDecoration(
              color: BioWayColors.primaryGreen.withValues(alpha: UIConstants.opacityLow),
              borderRadius: BorderRadiusConstants.borderRadiusSmall,
            ),
            child: Icon(
              Icons.inventory_2,
              color: BioWayColors.primaryGreen,
              size: UIConstants.iconSizeMedium,
            ),
          ),
          SizedBox(width: UIConstants.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lote['material'] ?? 'Material sin especificar',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: UIConstants.fontSizeMedium,
                  ),
                ),
                Text(
                  '${lote['peso']} kg - ${lote['origen_nombre'] ?? 'Sin origen'}',
                  style: TextStyle(
                    fontSize: UIConstants.fontSizeXSmall,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildControlPesoIndividual(Map<String, dynamic> lote) {
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
            ? BioWayColors.warning.withValues(alpha: 0.5)
            : Colors.grey[300]!,
          width: porcentajeMerma > 10 ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con información del lote
          Row(
            children: [
              Icon(
                Icons.inventory_2,
                color: BioWayColors.primaryGreen,
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
              if (porcentajeMerma > 10)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: UIConstants.spacing8,
                    vertical: UIConstants.spacing4,
                  ),
                  decoration: BoxDecoration(
                    color: BioWayColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadiusConstants.borderRadiusSmall,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 14,
                        color: BioWayColors.warning,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Merma alta',
                        style: TextStyle(
                          fontSize: UIConstants.fontSizeXSmall,
                          color: BioWayColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          
          SizedBox(height: UIConstants.spacing16),
          
          // Peso bruto
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
          
          // Input peso neto
          const field_label.FieldLabel(
            text: 'Peso Neto Aprovechable',
            isRequired: true,
          ),
          SizedBox(height: UIConstants.spacing8),
          WeightInputWidget(
            controller: _pesosRecibidosControllers[loteId]!,
            label: 'Ingrese el peso real recibido',
            primaryColor: BioWayColors.primaryGreen,
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
          
          // Merma calculada
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
            color: BioWayColors.primaryGreen,
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        // Mostrar la misma alerta al presionar el botón de retroceso
        final shouldLeave = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('¿Abandonar proceso?'),
            content: const Text(
              'Si sales ahora, se cancelará el proceso de recepción de materiales y deberás comenzar desde cero.\n\n¿Estás seguro de que deseas salir?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BioWayColors.error,
                ),
                child: const Text('Salir'),
              ),
            ],
          ),
        );
        
        if (shouldLeave == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: BioWayColors.primaryGreen,
          elevation: UIConstants.elevationNone,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () async {
              HapticFeedback.lightImpact();
              
              // Mostrar alerta antes de salir
              final shouldLeave = await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  title: const Text('¿Abandonar proceso?'),
                  content: const Text(
                    'Si sales ahora, se cancelará el proceso de recepción de materiales y deberás comenzar desde cero.\n\n¿Estás seguro de que deseas salir?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BioWayColors.error,
                      ),
                      child: const Text('Salir'),
                    ),
                  ],
                ),
              );
              
              if (shouldLeave == true && context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
        title: const Text(
          'Recepción de Materiales',
          style: TextStyle(
            fontSize: UIConstants.fontSizeXLarge,
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
                  borderRadius: BorderRadiusConstants.borderRadiusLarge,
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
                          color: BioWayColors.deepBlue,
                          size: UIConstants.iconSizeMedium,
                        ),
                        SizedBox(width: UIConstants.spacing12),
                        const Text(
                          'Información de Entrega',
                          style: TextStyle(
                            fontSize: UIConstants.fontSizeLarge,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: UIConstants.spacing8),
                    // Mensaje informativo
                    Container(
                      padding: EdgeInsetsConstants.paddingAll12,
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadiusConstants.borderRadiusSmall,
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue[700],
                            size: UIConstants.iconSizeMedium,
                          ),
                          SizedBox(width: UIConstants.spacing8),
                          Expanded(
                            child: Text(
                              'Transportista identificado mediante código QR',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: UIConstants.fontSizeSmall,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: UIConstants.spacing16),
                    TextFormField(
                      controller: _transportistaController,
                      enabled: false,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Transportista',
                        prefixIcon: Icon(Icons.local_shipping, color: BioWayColors.deepBlue),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadiusConstants.borderRadiusMedium,
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadiusConstants.borderRadiusMedium,
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
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
                  borderRadius: BorderRadiusConstants.borderRadiusLarge,
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
                        const Text(
                          '📦',
                          style: TextStyle(fontSize: UIConstants.fontSizeTitle),
                        ),
                        SizedBox(width: UIConstants.spacing8 + 2),
                        Text(
                          'Lotes Recibidos (${_lotes.length})',
                          style: const TextStyle(
                            fontSize: UIConstants.fontSizeLarge,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: UIConstants.spacing16),
                    
                    // Tipo de Material (si todos los lotes son del mismo tipo)
                    if (_lotes.isNotEmpty && _lotes.every((lote) => lote['material'] == _lotes.first['material'])) ...[
                      Container(
                        padding: EdgeInsetsConstants.paddingAll12,
                        decoration: BoxDecoration(
                          color: BioWayColors.primaryGreen.withValues(alpha: UIConstants.opacityVeryLow),
                          borderRadius: BorderRadiusConstants.borderRadiusMedium,
                          border: Border.all(
                            color: BioWayColors.primaryGreen.withValues(alpha: UIConstants.opacityMediumLow),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.category,
                              size: UIConstants.iconSizeMedium,
                              color: BioWayColors.primaryGreen,
                            ),
                            SizedBox(width: UIConstants.spacing12),
                            Text(
                              _lotes.first['material'] ?? 'Material sin especificar',
                              style: TextStyle(
                                fontSize: UIConstants.fontSizeBody,
                                fontWeight: FontWeight.w600,
                                color: BioWayColors.primaryGreen,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: UIConstants.spacing8, vertical: UIConstants.spacing4),
                              decoration: BoxDecoration(
                                color: BioWayColors.primaryGreen.withValues(alpha: UIConstants.opacityLow),
                                borderRadius: BorderRadiusConstants.borderRadiusMedium,
                              ),
                              child: Text(
                                'Uniforme',
                                style: TextStyle(
                                  fontSize: UIConstants.fontSizeXSmall + 1,
                                  fontWeight: FontWeight.w600,
                                  color: BioWayColors.primaryGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: UIConstants.spacing16),
                    ],
                    
                    ..._lotes.map((lote) => _buildLoteInfo(lote)),
                  ],
                ),
              ),
              
              SizedBox(height: UIConstants.spacing16),
              
              // Sección de Control de Peso Individual por Lote
              Container(
                padding: EdgeInsetsConstants.paddingAll16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadiusConstants.borderRadiusLarge,
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
                        const Text(
                          '⚖️',
                          style: TextStyle(fontSize: UIConstants.fontSizeTitle),
                        ),
                        SizedBox(width: UIConstants.spacing8 + 2),
                        const RequiredFieldLabel(
                          label: 'Control de Peso Individual',
                        ),
                      ],
                    ),
                    SizedBox(height: UIConstants.spacing8),
                    
                    // Mensaje informativo
                    Container(
                      padding: EdgeInsetsConstants.paddingAll12,
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadiusConstants.borderRadiusSmall,
                        border: Border.all(color: Colors.amber[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.amber[700],
                            size: UIConstants.iconSizeMedium,
                          ),
                          SizedBox(width: UIConstants.spacing8),
                          Expanded(
                            child: Text(
                              'Registre el peso neto de cada lote para mantener la trazabilidad individual',
                              style: TextStyle(
                                color: Colors.amber[700],
                                fontSize: UIConstants.fontSizeSmall,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: UIConstants.spacing16),
                    
                    // Resumen de peso total
                    Container(
                      padding: EdgeInsetsConstants.paddingAll16,
                      decoration: BoxDecoration(
                        color: BioWayColors.primaryGreen.withValues(alpha: 0.05),
                        borderRadius: BorderRadiusConstants.borderRadiusMedium,
                        border: Border.all(
                          color: BioWayColors.primaryGreen.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.summarize,
                                color: BioWayColors.primaryGreen,
                                size: UIConstants.iconSizeMedium,
                              ),
                              SizedBox(width: UIConstants.spacing12),
                              Text(
                                'Resumen Total',
                                style: TextStyle(
                                  fontSize: UIConstants.fontSizeMedium,
                                  fontWeight: FontWeight.bold,
                                  color: BioWayColors.darkGreen,
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
                                  color: BioWayColors.textGrey,
                                ),
                              ),
                              Text(
                                '${_pesoTotalOriginalController.text} kg',
                                style: TextStyle(
                                  fontSize: UIConstants.fontSizeMedium,
                                  fontWeight: FontWeight.bold,
                                  color: BioWayColors.darkGreen,
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
                                  color: BioWayColors.textGrey,
                                ),
                              ),
                              Text(
                                '${_pesoNetoTotal.toStringAsFixed(1)} kg',
                                style: TextStyle(
                                  fontSize: UIConstants.fontSizeMedium,
                                  fontWeight: FontWeight.bold,
                                  color: BioWayColors.primaryGreen,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: UIConstants.spacing8),
                          Divider(color: Colors.grey[300]),
                          SizedBox(height: UIConstants.spacing8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Merma Total:',
                                style: TextStyle(
                                  fontSize: UIConstants.fontSizeMedium,
                                  color: BioWayColors.textGrey,
                                ),
                              ),
                              Text(
                                '${_mermaTotalCalculada.toStringAsFixed(1)} kg (${(_mermaTotalCalculada > 0 && double.tryParse(_pesoTotalOriginalController.text) != null ? (_mermaTotalCalculada / double.parse(_pesoTotalOriginalController.text) * 100) : 0).toStringAsFixed(1)}%)',
                                style: TextStyle(
                                  fontSize: UIConstants.fontSizeMedium,
                                  fontWeight: FontWeight.bold,
                                  color: _mermaTotalCalculada > 0 && double.tryParse(_pesoTotalOriginalController.text) != null && (_mermaTotalCalculada / double.parse(_pesoTotalOriginalController.text) * 100) > 10 
                                    ? BioWayColors.warning 
                                    : Colors.orange[700],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: UIConstants.spacing20),
                    
                    // Control individual por cada lote
                    Text(
                      'Control por Lote',
                      style: TextStyle(
                        fontSize: UIConstants.fontSizeMedium,
                        fontWeight: FontWeight.bold,
                        color: BioWayColors.textGrey,
                      ),
                    ),
                    SizedBox(height: UIConstants.spacing12),
                    
                    // Lista de controles de peso individual
                    ..._lotes.map((lote) => _buildControlPesoIndividual(lote)),
                  ],
                ),
              ),
              
              SizedBox(height: UIConstants.spacing16),
              
              // Sección: Datos del Responsable
              Container(
                width: double.infinity,
                padding: EdgeInsetsConstants.paddingAll20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadiusConstants.borderRadiusLarge,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: UIConstants.opacityVeryLow),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '👤',
                          style: TextStyle(fontSize: UIConstants.fontSizeTitle),
                        ),
                        SizedBox(width: UIConstants.spacing8 + 2),
                        Expanded(
                          child: Text(
                            'Datos del Responsable que Recibe el Material',
                            style: TextStyle(
                              fontSize: UIConstants.fontSizeLarge,
                              fontWeight: FontWeight.bold,
                              color: BioWayColors.darkGreen,
                            ),
                          ),
                        ),
                        SizedBox(width: UIConstants.spacing4),
                        const Text(
                          '*',
                          style: TextStyle(
                            fontSize: UIConstants.fontSizeLarge,
                            fontWeight: FontWeight.bold,
                            color: BioWayColors.error,
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
                    decoration: SharedInputDecorations.ecoceStyle(
                      hintText: 'Ingresa el nombre completo',
                      primaryColor: BioWayColors.primaryGreen,
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
                  
                  const SizedBox(height: 20),
                  
                  // Firma del Operador
                  const field_label.FieldLabel(text: 'Firma', isRequired: true),
                  SizedBox(height: UIConstants.spacing8),
                    GestureDetector(
                      onTap: _signaturePoints.isEmpty ? _captureSignature : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: _signaturePoints.isNotEmpty ? 150 : 100,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: _signaturePoints.isNotEmpty 
                              ? BioWayColors.primaryGreen.withValues(alpha: 0.05)
                              : Colors.grey[50],
                          borderRadius: BorderRadiusConstants.borderRadiusMedium,
                          border: Border.all(
                            color: _signaturePoints.isNotEmpty 
                                ? BioWayColors.primaryGreen 
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
                                              color: BioWayColors.primaryGreen,
                                              size: UIConstants.iconSizeMedium,
                                            ),
                                            constraints: const BoxConstraints(
                                              minWidth: 32,
                                              minHeight: 32,
                                            ),
                                            padding: EdgeInsets.zero,
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
                                            icon: const Icon(
                                              Icons.clear,
                                              color: Colors.red,
                                              size: UIConstants.iconSizeMedium,
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
                ),
              ),
              
              SizedBox(height: UIConstants.spacing16),
              
              // Sección de Comentarios
              Container(
                width: double.infinity,
                padding: EdgeInsetsConstants.paddingAll20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadiusConstants.borderRadiusLarge,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: UIConstants.opacityVeryLow),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '💬',
                          style: TextStyle(fontSize: UIConstants.fontSizeTitle),
                        ),
                        SizedBox(width: UIConstants.spacing8 + 2),
                        Text(
                          'Comentarios',
                          style: TextStyle(
                            fontSize: UIConstants.fontSizeLarge,
                            fontWeight: FontWeight.bold,
                            color: BioWayColors.darkGreen,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: UIConstants.spacing20),
                    TextFormField(
                      controller: _comentariosController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Comentarios adicionales (opcional)',
                        hintStyle: TextStyle(color: const Color(0xFF9A9A9A)),
                        filled: true,
                        fillColor: BioWayColors.backgroundGrey,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadiusConstants.borderRadiusMedium,
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadiusConstants.borderRadiusMedium,
                          borderSide: BorderSide(
                            color: BioWayColors.primaryGreen.withValues(alpha: UIConstants.opacityMedium),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadiusConstants.borderRadiusMedium,
                          borderSide: BorderSide(
                            color: BioWayColors.primaryGreen,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: UIConstants.spacing24),
              
              // Botón de enviar
              SizedBox(
                height: UIConstants.buttonHeight,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BioWayColors.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadiusConstants.borderRadiusLarge,
                    ),
                    elevation: UIConstants.elevationLow,
                  ),
                  child: _isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
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
      bottomNavigationBar: EcoceBottomNavigation(
        selectedIndex: -1, // Ninguno seleccionado ya que estamos en un formulario
        onItemTapped: (index) async {
          HapticFeedback.lightImpact();
          
          // Mostrar alerta antes de salir
          final shouldLeave = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('¿Abandonar proceso?'),
              content: const Text(
                'Si sales ahora, se cancelará el proceso de recepción de materiales y deberás comenzar desde cero.\n\n¿Estás seguro de que deseas salir?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BioWayColors.error,
                  ),
                  child: const Text('Salir'),
                ),
              ],
            ),
          );
          
          if (shouldLeave == true && context.mounted) {
            switch (index) {
              case 0:
                Navigator.pushReplacementNamed(context, '/reciclador_inicio');
                break;
              case 1:
                Navigator.pushReplacementNamed(context, '/reciclador_lotes');
                break;
              case 2:
                Navigator.pushReplacementNamed(context, '/reciclador_ayuda');
                break;
              case 3:
                Navigator.pushReplacementNamed(context, '/reciclador_perfil');
                break;
            }
          }
        },
        items: EcoceNavigationConfigs.recicladorItems,
        primaryColor: BioWayColors.ecoceGreen,
      ),
      ),
    );
  }

}
