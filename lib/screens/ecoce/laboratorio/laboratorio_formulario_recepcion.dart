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
import '../../../models/lotes/lote_laboratorio_model.dart';
import '../shared/widgets/weight_input_widget.dart';
import '../shared/widgets/signature_dialog.dart';
import '../shared/widgets/form_widgets.dart';
import '../shared/widgets/dialog_utils.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';


class LaboratorioFormularioRecepcion extends StatefulWidget {
  final List<Map<String, dynamic>> lotes;
  final Map<String, dynamic> datosEntrega;
  
  const LaboratorioFormularioRecepcion({
    super.key,
    required this.lotes,
    required this.datosEntrega,
  });

  @override
  State<LaboratorioFormularioRecepcion> createState() => _LaboratorioFormularioRecepcionState();
}

class _LaboratorioFormularioRecepcionState extends State<LaboratorioFormularioRecepcion> {
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
  final TextEditingController _pesoMuestraController = TextEditingController();
  final TextEditingController _observacionesController = TextEditingController();
  final TextEditingController _condicionesController = TextEditingController();
  
  // Firma
  List<Offset?> _signaturePoints = [];
  String? _signatureUrl;
  
  // Tipo de análisis
  final List<String> _tiposAnalisis = [
    'Composición Química',
    'Resistencia Mecánica',
    'Pureza del Material',
    'Contaminantes',
    'Índice de Fluidez',
    'Densidad',
    'Otros'
  ];
  List<String> _analisisSeleccionados = [];
  
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
    }
  }

  void _captureSignature() {
    SignatureDialog.show(
      context: context,
      title: 'Firma del Técnico',
      initialSignature: _signaturePoints,
      onSignatureSaved: (points) {
        setState(() {
          _signaturePoints = List.from(points);
          _signatureUrl = null;
        });
      },
      primaryColor: BioWayColors.petBlue,
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_analisisSeleccionados.isEmpty) {
      DialogUtils.showErrorDialog(
        context,
        title: 'Análisis Requeridos',
        message: 'Por favor seleccione al menos un tipo de análisis a realizar.',
      );
      return;
    }

    if (_signaturePoints.isEmpty) {
      DialogUtils.showErrorDialog(
        context,
        title: 'Firma Requerida',
        message: 'Por favor capture la firma del técnico antes de continuar.',
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
        // Actualizar el lote en el sistema unificado para reflejar que fue recibido por el laboratorio
        await _loteUnificadoService.transferirLote(
          loteId: lote['id'],
          procesoDestino: 'laboratorio',
          usuarioDestinoFolio: _userSession.getUserData()?['folio'] ?? '',
          datosIniciales: {
            'usuario_id': _authService.currentUser?.uid,
            'fecha_entrada': FieldValue.serverTimestamp(),
            'peso_muestra': double.tryParse(_pesoMuestraController.text) ?? 0,
            'transportista_folio': _datosEntrega!['transportista_folio'],
            'firma_tecnico': _signatureUrl,
            'observaciones': _observacionesController.text,
            'condiciones_muestra': _condicionesController.text,
            'tipos_analisis': _analisisSeleccionados,
            'estado_analisis': 'pendiente',
          },
        );

        // Crear registro en la colección de lotes del laboratorio (para compatibilidad)
        // Crear modelo de lote laboratorio
        final loteLaboratorio = LoteLaboratorioModel(
          userId: _authService.currentUser!.uid,
          tipoMaterial: lote['material'] ?? 'Mixto',
          pesoMuestra: double.tryParse(_pesoMuestraController.text) ?? 0,
          proveedor: lote['origen_nombre'] ?? 'Sin especificar',
          loteOrigen: lote['id'],
          observaciones: _observacionesController.text,
          estado: 'pendiente',
        );
        await _loteService.crearLoteLaboratorio(loteLaboratorio);
      }

      if (mounted) {
        DialogUtils.showSuccessDialog(
          context,
          title: 'Recepción Exitosa',
          message: 'Las muestras han sido recibidas correctamente. Puede proceder con los análisis.',
          onAccept: () {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/laboratorio_inicio',
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
        ..color = BioWayColors.petBlue
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
        'firmas/laboratorio/${_authService.currentUser?.uid}',
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
              color: BioWayColors.petBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.science,
              color: BioWayColors.petBlue,
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
            color: BioWayColors.petBlue,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: BioWayColors.petBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Recepción de Muestras',
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
                          Icons.science,
                          color: BioWayColors.petBlue,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Muestras Recibidas (${_lotes.length})',
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
              
              // Información de la muestra
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
                          Icons.scale,
                          color: Colors.blue,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Datos de la Muestra',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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
                      controller: _pesoMuestraController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Peso de Muestra Tomada (kg)',
                        prefixIcon: Icon(Icons.science),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese el peso de la muestra';
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
                      controller: _condicionesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Condiciones de la Muestra',
                        prefixIcon: Icon(Icons.assignment),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor describa las condiciones de la muestra';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Tipos de análisis
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
                          Icons.biotech,
                          color: BioWayColors.ppPurple,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Análisis a Realizar',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tiposAnalisis.map((tipo) {
                        final isSelected = _analisisSeleccionados.contains(tipo);
                        return FilterChip(
                          label: Text(tipo),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _analisisSeleccionados.add(tipo);
                              } else {
                                _analisisSeleccionados.remove(tipo);
                              }
                            });
                          },
                          backgroundColor: Colors.grey[100],
                          selectedColor: BioWayColors.petBlue.withOpacity(0.2),
                          checkmarkColor: BioWayColors.petBlue,
                          labelStyle: TextStyle(
                            color: isSelected ? BioWayColors.petBlue : Colors.grey[700],
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        );
                      }).toList(),
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
                          color: BioWayColors.petBlue,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Firma del Técnico',
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
                                : BioWayColors.petBlue,
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
                    backgroundColor: BioWayColors.petBlue,
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
              Navigator.pushReplacementNamed(context, '/laboratorio_inicio');
              break;
            case 1:
              break; // Ya estamos aquí
            case 2:
              Navigator.pushReplacementNamed(context, '/laboratorio_muestras');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/laboratorio_perfil');
              break;
          }
        },
        primaryColor: BioWayColors.petBlue,
        items: const [
          NavigationItem(
            icon: Icons.home_rounded,
            label: 'Inicio',
            testKey: 'laboratorio_nav_inicio',
          ),
          NavigationItem(
            icon: Icons.qr_code_scanner_rounded,
            label: 'Recibir',
            testKey: 'laboratorio_nav_recibir',
          ),
          NavigationItem(
            icon: Icons.science_rounded,
            label: 'Muestras',
            testKey: 'laboratorio_nav_muestras',
          ),
          NavigationItem(
            icon: Icons.person_outline_rounded,
            label: 'Perfil',
            testKey: 'laboratorio_nav_perfil',
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _transportistaController.dispose();
    _pesoTotalOriginalController.dispose();
    _pesoMuestraController.dispose();
    _observacionesController.dispose();
    _condicionesController.dispose();
    super.dispose();
  }
}