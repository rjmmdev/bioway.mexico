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
import '../../../models/lotes/lote_transformador_model.dart';
import '../shared/widgets/weight_input_widget.dart';
import '../shared/widgets/signature_dialog.dart';
import '../shared/widgets/form_widgets.dart';
import '../shared/widgets/dialog_utils.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';


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
  final TextEditingController _calidadMaterialController = TextEditingController();
  final TextEditingController _observacionesController = TextEditingController();
  
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

  void _initializeForm() async {
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
      _pesoRecibidoController.text = pesoTotal.toString();
    }
  }

  void _captureSignature() {
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
      primaryColor: BioWayColors.ppPurple,
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
        message: 'Por favor capture la firma del responsable antes de continuar.',
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

      // Marcar entrega como completada
      if (_datosEntrega != null && _datosEntrega!['entrega_id'] != null) {
        await _cargaService.completarEntrega(
          entregaId: _datosEntrega!['entrega_id'],
          firmaEntrega: _signatureUrl!,
          evidenciasFotoEntrega: [],
          comentariosEntrega: _observacionesController.text,
        );
      }

      // Procesar cada lote recibido
      for (final lote in _lotes) {
        // Actualizar el lote en el sistema unificado para reflejar que fue recibido por el transformador
        await _loteUnificadoService.transferirLote(
          loteId: lote['id'],
          procesoDestino: 'transformador',
          usuarioDestinoFolio: _userSession.getUserData()?['folio'] ?? '',
          datosIniciales: {
            'usuario_id': _authService.currentUser?.uid,
            'fecha_entrada': FieldValue.serverTimestamp(),
            'peso_entrada': lote['peso'],
            'peso_recibido': double.tryParse(_pesoRecibidoController.text) ?? lote['peso'],
            'tipo_procesamiento': _tipoProcesamiento,
            'calidad_material': _calidadMaterialController.text,
            'transportista_folio': _datosEntrega!['transportista_folio'],
            'firma_responsable': _signatureUrl,
            'observaciones': _observacionesController.text,
            'estado_procesamiento': 'pendiente',
          },
        );

        // Crear registro en la colección de lotes del transformador (para compatibilidad)
        // Crear modelo de lote transformador
        final loteTransformador = LoteTransformadorModel(
          userId: _authService.currentUser!.uid,
          lotesRecibidos: [lote['id']],
          pesoIngreso: double.tryParse(_pesoRecibidoController.text) ?? 0,
          proveedor: lote['origen_nombre'] ?? 'Sin especificar',
          productoFabricado: _tipoProcesamiento == 'pellets' ? 'Pellets' : 
                           _tipoProcesamiento == 'hojuelas' ? 'Hojuelas' : 'Otros',
          comentarios: _observacionesController.text,
          firmaRecibe: _signatureUrl!,
          operadorRecibe: _userSession.getUserData()?['nombre'] ?? 'Sin nombre',
          tipoPolimero: lote['material'] ?? 'Mixto',
          composicionMaterial: _calidadMaterialController.text,
          estado: 'pendiente',
          fechaCreacion: DateTime.now(),
        );
        await _loteService.crearLoteTransformador(loteTransformador);
      }

      if (mounted) {
        DialogUtils.showSuccessDialog(
          context,
          title: 'Recepción Exitosa',
          message: 'Los materiales han sido recibidos correctamente. Puede proceder con el procesamiento.',
          onAccept: () {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/transformador_inicio',
              (route) => false,
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
      final size = const Size(300, 150);
      
      // Fondo blanco
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.white,
      );
      
      // Dibujar la firma con color personalizado
      final paint = Paint()
        ..color = BioWayColors.ppPurple
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2.0;
      
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
              color: BioWayColors.ppPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.precision_manufacturing,
              color: BioWayColors.ppPurple,
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
            color: BioWayColors.ppPurple,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: BioWayColors.ppPurple,
        elevation: 0,
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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _transportistaController,
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'Transportista',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                        Icon(
                          Icons.precision_manufacturing,
                          color: BioWayColors.ppPurple,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Materiales Recibidos (${_lotes.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ..._lotes.map((lote) => _buildLoteInfo(lote)),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Información del procesamiento
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
                          Icons.settings,
                          color: Colors.orange,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Datos de Procesamiento',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Tipo de procesamiento
                    const Text(
                      'Tipo de Procesamiento',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: BioWayColors.textGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
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
                          selectedColor: BioWayColors.ppPurple.withOpacity(0.2),
                          backgroundColor: Colors.grey[100],
                          labelStyle: TextStyle(
                            color: _tipoProcesamiento == 'pellets'
                                ? BioWayColors.ppPurple
                                : Colors.grey[700],
                            fontWeight: _tipoProcesamiento == 'pellets'
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          checkmarkColor: BioWayColors.ppPurple,
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
                          selectedColor: BioWayColors.ppPurple.withOpacity(0.2),
                          backgroundColor: Colors.grey[100],
                          labelStyle: TextStyle(
                            color: _tipoProcesamiento == 'hojuelas'
                                ? BioWayColors.ppPurple
                                : Colors.grey[700],
                            fontWeight: _tipoProcesamiento == 'hojuelas'
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          checkmarkColor: BioWayColors.ppPurple,
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
                          selectedColor: BioWayColors.ppPurple.withOpacity(0.2),
                          backgroundColor: Colors.grey[100],
                          labelStyle: TextStyle(
                            color: _tipoProcesamiento == 'otros'
                                ? BioWayColors.ppPurple
                                : Colors.grey[700],
                            fontWeight: _tipoProcesamiento == 'otros'
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          checkmarkColor: BioWayColors.ppPurple,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Peso y calidad
                    TextFormField(
                      controller: _pesoTotalOriginalController,
                      enabled: false,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Peso Total Entregado (kg)',
                        prefixIcon: Icon(Icons.scale),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _pesoRecibidoController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Peso Recibido (kg)',
                        prefixIcon: Icon(Icons.scale),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _calidadMaterialController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Calidad del Material',
                        prefixIcon: Icon(Icons.star),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor describa la calidad del material';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Observaciones
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
                          Icons.comment,
                          color: Colors.orange,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Observaciones',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _observacionesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Observaciones adicionales (opcional)',
                        prefixIcon: Icon(Icons.comment),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
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
                          color: BioWayColors.ppPurple,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Firma del Responsable',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _captureSignature,
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _signaturePoints.isEmpty
                                ? Colors.grey[300]!
                                : BioWayColors.ppPurple,
                            width: 2,
                          ),
                        ),
                        child: _signaturePoints.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.touch_app,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Toque para firmar',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: CustomPaint(
                                  size: const Size(double.infinity, 150),
                                  painter: SignaturePainter(
                                    _signaturePoints,
                                    strokeWidth: 2.0,
                                  ),
                                ),
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
                    backgroundColor: BioWayColors.ppPurple,
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
        selectedIndex: 1, // Recibir
        onItemTapped: (index) {
          HapticFeedback.lightImpact();
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/transformador_inicio');
              break;
            case 1:
              break; // Ya estamos aquí
            case 2:
              Navigator.pushReplacementNamed(context, '/transformador_produccion');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/transformador_perfil');
              break;
          }
        },
        primaryColor: BioWayColors.ppPurple,
        items: const [
          NavigationItem(
            icon: Icons.home_rounded,
            label: 'Inicio',
            testKey: 'transformador_nav_inicio',
          ),
          NavigationItem(
            icon: Icons.qr_code_scanner_rounded,
            label: 'Recibir',
            testKey: 'transformador_nav_recibir',
          ),
          NavigationItem(
            icon: Icons.precision_manufacturing_rounded,
            label: 'Producción',
            testKey: 'transformador_nav_produccion',
          ),
          NavigationItem(
            icon: Icons.person_outline_rounded,
            label: 'Perfil',
            testKey: 'transformador_nav_perfil',
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _transportistaController.dispose();
    _pesoTotalOriginalController.dispose();
    _pesoRecibidoController.dispose();
    _calidadMaterialController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }
}