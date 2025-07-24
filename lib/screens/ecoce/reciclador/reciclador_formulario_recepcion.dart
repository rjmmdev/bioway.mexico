import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/colors.dart';
import '../../../services/lote_service.dart';
import '../../../services/lote_unificado_service.dart';
import '../../../services/user_session_service.dart';
import '../../../services/firebase/firebase_storage_service.dart';
import '../../../services/firebase/auth_service.dart';
import '../../../services/carga_transporte_service.dart';
import '../../../models/lotes/lote_reciclador_model.dart';
import '../shared/widgets/weight_input_widget.dart';
import '../shared/widgets/signature_dialog.dart';
import '../shared/widgets/form_widgets.dart';
import '../shared/widgets/dialog_utils.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import '../shared/widgets/required_field_label.dart';

/// Painter personalizado para dibujar la firma con el color definido
class SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  final double strokeWidth;

  SignaturePainter({
    required this.points,
    this.strokeWidth = 2.0,
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
  final LoteService _loteService = LoteService();
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
  final TextEditingController _pesoRecibidoController = TextEditingController();
  final TextEditingController _mermaController = TextEditingController();
  
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
  }

  void _initializeForm() async {
    final userData = _userSession.getUserData();
    setState(() {
      _isLoading = false;
    });
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

  void _calcularMerma() {
    final pesoOriginal = double.tryParse(_pesoTotalOriginalController.text) ?? 0;
    final pesoRecibido = double.tryParse(_pesoRecibidoController.text) ?? 0;
    final merma = pesoOriginal - pesoRecibido;
    _mermaController.text = merma.toStringAsFixed(1);
  }

  void _captureSignature() {
    SignatureDialog.show(
      context: context,
      title: 'Firma del Operador',
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
        
        // Obtener el ID del usuario actual (reciclador)
        final currentUserId = _authService.currentUser?.uid;
        final currentUserData = _userSession.getUserData();
        
        print('=== DATOS DEL USUARIO RECICLADOR ===');
        print('User ID: $currentUserId');
        print('User Folio: ${currentUserData?['folio']}');
        print('User Nombre: ${currentUserData?['nombre']}');
        
        // Crear o actualizar el proceso reciclador con la información de recepción
        await _loteUnificadoService.crearOActualizarProceso(
          loteId: loteId,
          proceso: 'reciclador',
          datos: {
            'usuario_id': currentUserId,
            'reciclador_id': currentUserId, // Agregar explícitamente el reciclador_id
            'usuario_folio': currentUserData?['folio'] ?? '',
            'fecha_recepcion': FieldValue.serverTimestamp(),
            'peso_entrada': lote['peso'],
            'peso_recibido': double.tryParse(_pesoRecibidoController.text) ?? lote['peso'],
            'peso_neto': double.tryParse(_pesoRecibidoController.text) ?? lote['peso'], // Agregar peso_neto
            'merma_recepcion': double.tryParse(_mermaController.text) ?? 0,
            'firma_operador': _signatureUrl,
            'operador_nombre': _operadorController.text.trim(), // Agregar nombre del operador
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
      if (userProfile != null) {
        final currentTotal = userProfile['ecoce_lotes_totales_recibidos'] ?? 0;
        await _userSession.updateCurrentUserProfile({
          'ecoce_lotes_totales_recibidos': currentTotal + _lotes.length,
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
      
      final size = const Size(300, 150);
      
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
      print('Error al subir firma: $e');
      return null;
    }
  }

  Widget _buildLoteInfo(Map<String, dynamic> lote) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: BioWayColors.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.inventory_2,
              color: BioWayColors.primaryGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lote['material'] ?? 'Material sin especificar',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${lote['peso']} kg - ${lote['origen_nombre'] ?? 'Sin origen'}',
                  style: TextStyle(
                    fontSize: 12,
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

    return WillPopScope(
      onWillPop: () async {
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
        
        return shouldLeave ?? false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: BioWayColors.primaryGreen,
          elevation: 0,
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
              
              if (shouldLeave == true && mounted) {
                Navigator.pop(context);
              }
            },
          ),
        title: const Text(
          'Recepción de Materiales',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Información del transportista
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
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
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Información de Entrega',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Mensaje informativo
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Transportista identificado mediante código QR',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
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
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
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
              
              const SizedBox(height: 16),
              
              // Lista de lotes
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
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
                          style: TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Lotes Recibidos (${_lotes.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Tipo de Material (si todos los lotes son del mismo tipo)
                    if (_lotes.isNotEmpty && _lotes.every((lote) => lote['material'] == _lotes.first['material'])) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: BioWayColors.primaryGreen.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: BioWayColors.primaryGreen.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.category,
                              size: 20,
                              color: BioWayColors.primaryGreen,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _lotes.first['material'] ?? 'Material sin especificar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: BioWayColors.primaryGreen,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: BioWayColors.primaryGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Uniforme',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: BioWayColors.primaryGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    ..._lotes.map((lote) => _buildLoteInfo(lote)),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Pesos y merma
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
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
                          style: TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 10),
                        const RequiredFieldLabel(
                          label: 'Control de Peso',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _pesoTotalOriginalController,
                      enabled: false,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Peso Total Declarado (kg)',
                        prefixIcon: Icon(Icons.scale),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _pesoRecibidoController,
                      keyboardType: TextInputType.number,
                      decoration: 'Peso Recibido Real (kg)'.toRequiredInputDecoration(
                        hint: 'Ingrese el peso real que usted recibió',
                        prefixIcon: Icon(Icons.scale),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese el peso recibido';
                        }
                        final peso = double.tryParse(value);
                        if (peso == null || peso <= 0) {
                          return 'Ingrese un peso válido';
                        }
                        return null;
                      },
                      onChanged: (value) => _calcularMerma(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _mermaController,
                      enabled: false,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Merma Calculada (kg)',
                        prefixIcon: Icon(Icons.trending_down),
                        helperText: 'Diferencia entre peso declarado y recibido',
                        helperStyle: TextStyle(fontSize: 12),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Firma
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
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
                          Icons.draw,
                          color: BioWayColors.primaryGreen,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const RequiredFieldLabel(
                          label: 'Firma del Operador',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _signaturePoints.isEmpty ? _captureSignature : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: _signaturePoints.isNotEmpty ? 150 : 100,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: _signaturePoints.isNotEmpty 
                              ? BioWayColors.primaryGreen.withOpacity(0.05)
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
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
                                      child: _signaturePoints.isNotEmpty
                                          ? AspectRatio(
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
                                                          strokeWidth: 2.0,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )
                                          : const Text(
                                              'Firma capturada',
                                              style: TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.w600,
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
                                                color: Colors.black.withOpacity(0.1),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                          child: IconButton(
                                            onPressed: _captureSignature,
                                            icon: Icon(
                                              Icons.edit,
                                              color: BioWayColors.primaryGreen,
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
                                                color: Colors.black.withOpacity(0.1),
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
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Botón de enviar
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BioWayColors.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
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
                                fontSize: 16,
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
              
              const SizedBox(height: 32),
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
          
          if (shouldLeave == true) {
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

  @override
  void dispose() {
    _transportistaController.dispose();
    _pesoTotalOriginalController.dispose();
    _pesoRecibidoController.dispose();
    _mermaController.dispose();
    super.dispose();
  }
}