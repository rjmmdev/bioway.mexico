import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/colors.dart';
import '../../../services/lote_service.dart';
import '../../../services/lote_unificado_service.dart';
import '../../../services/user_session_service.dart';
import '../../../services/firebase/firebase_storage_service.dart';
import '../shared/widgets/signature_dialog.dart';
import '../shared/widgets/photo_evidence_widget.dart';
import '../shared/widgets/weight_input_widget.dart';
import '../shared/widgets/unified_container.dart';
import '../shared/widgets/field_label.dart';
import 'transformador_documentacion_screen.dart';

class TransformadorFormularioSalida extends StatefulWidget {
  final String loteId;
  final double peso;
  final List<String> tiposAnalisis;
  final String productoFabricado;
  final String composicionMaterial;
  final String? tipoPolimero;
  
  const TransformadorFormularioSalida({
    super.key,
    required this.loteId,
    required this.peso,
    required this.tiposAnalisis,
    required this.productoFabricado,
    required this.composicionMaterial,
    this.tipoPolimero,
  });

  @override
  State<TransformadorFormularioSalida> createState() => _TransformadorFormularioSalidaState();
}

class _TransformadorFormularioSalidaState extends State<TransformadorFormularioSalida> {
  final _formKey = GlobalKey<FormState>();
  final Color _primaryColor = BioWayColors.ecoceGreen;
  
  // Servicios
  final LoteService _loteService = LoteService();
  final LoteUnificadoService _loteUnificadoService = LoteUnificadoService();
  final UserSessionService _userSession = UserSessionService();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  
  // Controladores
  final TextEditingController _pesoSalidaController = TextEditingController();
  final TextEditingController _operadorController = TextEditingController();
  final TextEditingController _comentariosController = TextEditingController();
  final TextEditingController _productoGeneradoController = TextEditingController();
  final TextEditingController _cantidadGeneradaController = TextEditingController();
  
  
  // Variables para los procesos aplicados
  final Map<String, bool> _procesosAplicados = {
    'Triturado': false,
    'Lavado': false,
    'Secado': false,
    'Extrusión': false,
    'Pelletizado': false,
    'Clasificación': false,
    'Control de calidad': false,
    'Empaquetado': false,
  };
  
  // Variables para la firma
  List<Offset?> _signaturePoints = [];
  bool _hasSignature = false;
  
  // Variables para las fotos
  List<File> _photos = [];
  
  // ScrollController
  final ScrollController _scrollController = ScrollController();
  
  // FocusNodes
  final FocusNode _operadorFocus = FocusNode();
  final FocusNode _comentariosFocus = FocusNode();
  final FocusNode _productoFocus = FocusNode();
  final FocusNode _cantidadFocus = FocusNode();
  
  // Estado de carga
  bool _isLoading = false;
  String? _signatureUrl;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    
    // Listener para el campo de comentarios
    _comentariosFocus.addListener(() {
      if (_comentariosFocus.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _pesoSalidaController.dispose();
    _operadorController.dispose();
    _comentariosController.dispose();
    _productoGeneradoController.dispose();
    _cantidadGeneradaController.dispose();
    _scrollController.dispose();
    _operadorFocus.dispose();
    _comentariosFocus.dispose();
    _productoFocus.dispose();
    _cantidadFocus.dispose();
    super.dispose();
  }
  
  void _initializeForm() async {
    final userData = _userSession.getUserData();
    if (userData != null) {
      _operadorController.text = userData['nombre'] ?? '';
    }
  }

  void _showSignatureDialog() {
    SignatureDialog.show(
      context: context,
      title: 'Firma del Operador',
      initialSignature: _signaturePoints,
      onSignatureSaved: (points) {
        setState(() {
          _signaturePoints = List.from(points);
          _hasSignature = points.isNotEmpty;
        });
      },
      primaryColor: _primaryColor,
    );
  }

  void _procesarSalida() async {
    // Validar formulario
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    
    // Validar que haya al menos un proceso aplicado seleccionado
    final procesosSeleccionados = _procesosAplicados.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
    
    if (procesosSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor seleccione al menos un proceso aplicado'),
          backgroundColor: BioWayColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    
    // Validar firma
    if (!_hasSignature) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor capture la firma del responsable'),
          backgroundColor: BioWayColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    
    // Validar fotos
    if (_photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor agregue al menos una fotografía'),
          backgroundColor: BioWayColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Obtener datos del usuario
      final userProfile = await _userSession.getUserProfile();
      if (userProfile == null) {
        throw Exception('No se pudo obtener el perfil del usuario');
      }
      
      // Subir firma a Storage
      if (_signaturePoints.isNotEmpty) {
        final signatureImage = await _captureSignature();
        if (signatureImage != null) {
          _signatureUrl = await _storageService.uploadImage(
            signatureImage,
            'lotes/transformador/salida/firmas',
          );
        }
      }
      
      // Subir fotos a Storage
      List<String> photoUrls = [];
      for (int i = 0; i < _photos.length; i++) {
        final url = await _storageService.uploadImage(
          _photos[i],
          'lotes/transformador/salida/evidencias',
        );
        if (url != null) {
          photoUrls.add(url);
        }
      }
      
      // Actualizar el lote en el Sistema Unificado
      await _loteUnificadoService.actualizarProcesoTransformador(
        loteId: widget.loteId,
        datosTransformador: {
          'peso_salida': double.parse(_pesoSalidaController.text),
          'producto_generado': _productoGeneradoController.text.trim(),
          'cantidad_generada': _cantidadGeneradaController.text.trim(),
          'procesos_aplicados': procesosSeleccionados,
          'operador_salida': _operadorController.text.trim(),
          'firma_salida': _signatureUrl,
          'evidencias_salida': photoUrls,
          'comentarios_salida': _comentariosController.text.trim(),
          'fecha_salida': DateTime.now(),
          'estado': 'documentacion',
        },
      );
      
      if (mounted) {
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Proceso de salida registrado exitosamente'),
            backgroundColor: BioWayColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        
        // Wait a moment for the database update to propagate
        await Future.delayed(const Duration(milliseconds: 1000));
        
        // Navegar a la pantalla de documentación
        if (mounted) {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => TransformadorDocumentacionScreen(
                loteId: widget.loteId,
                material: widget.tipoPolimero ?? 'Material',
                peso: widget.peso,
              ),
            ),
          );
          
          // If documentation was completed or user pressed back, return to production
          if (mounted) {
            // Determine which tab to show based on whether documentation was completed
            final tabIndex = result == true ? 2 : 1; // Completados if true, Documentación if false
            
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/transformador_produccion',
              (route) => false,
              arguments: {'initialTab': tabIndex},
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear el lote: ${e.toString()}'),
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildProcesosAplicadosGrid() {
    final entries = _procesosAplicados.entries.toList();
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Row(
          children: [
            Checkbox(
              value: entry.value,
              onChanged: (bool? value) {
                setState(() {
                  _procesosAplicados[entry.key] = value ?? false;
                });
              },
              activeColor: _primaryColor,
            ),
            Expanded(
              child: Text(
                entry.key,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        );
      },
    );
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

      for (int i = 0; i < _signaturePoints.length - 1; i++) {
        if (_signaturePoints[i] != null && _signaturePoints[i + 1] != null) {
          canvas.drawLine(_signaturePoints[i]!, _signaturePoints[i + 1]!, paint);
        }
      }

      final picture = recorder.endRecording();
      final img = await picture.toImage(300, 200);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        final buffer = byteData.buffer.asUint8List();
        
        // Guardar temporalmente
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png');
        await file.writeAsBytes(buffer);
        
        return file;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error al capturar firma: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _primaryColor,
        elevation: 0,
        title: const Text(
          'Formulario de Salida',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              children: [
            // Sección de información del lote
            SectionCard(
              icon: '📦',
              title: 'Información del Lote',
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.qr_code_2,
                            color: _primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Lote: ${widget.loteId}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Producto: ${widget.productoFabricado}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        'Peso inicial: ${widget.peso} kg',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                      if (widget.tipoPolimero != null)
                        Text(
                          'Polímero: ${widget.tipoPolimero}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Sección de peso de salida
            SectionCard(
              icon: '⚖️',
              title: 'Peso de Salida',
              children: [
                WeightInputWidget(
                  controller: _pesoSalidaController,
                  label: 'Peso de salida en kilogramos',
                  primaryColor: _primaryColor,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese el peso de salida';
                    }
                    final peso = double.tryParse(value);
                    if (peso == null || peso <= 0) {
                      return 'Por favor ingrese un peso válido';
                    }
                    return null;
                  },
                ),
              ],
            ),
            
            // Sección de procesos aplicados
            SectionCard(
              icon: '🔬',
              title: 'Procesos Aplicados *',
              children: [
                _buildProcesosAplicadosGrid(),
              ],
            ),
            
            // Sección de producto generado
            SectionCard(
              icon: '📦',
              title: 'Producto Generado',
              children: [
                TextFormField(
                  controller: _productoGeneradoController,
                  focusNode: _productoFocus,
                  maxLength: 50,
                  decoration: InputDecoration(
                    hintText: 'Ej: Pellets de PET',
                    counter: Text(
                      '${_productoGeneradoController.text.length}/50',
                      style: const TextStyle(fontSize: 12),
                    ),
                    prefixIcon: Icon(
                      Icons.inventory_2,
                      color: _primaryColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey[300]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese el producto generado';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {}); // Para actualizar el contador
                  },
                ),
              ],
            ),
            
            // Sección de cantidad generada
            SectionCard(
              icon: '🧪',
              title: 'Cantidad Generada',
              children: [
                TextFormField(
                  controller: _cantidadGeneradaController,
                  focusNode: _cantidadFocus,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Ej: 500 unidades',
                    prefixIcon: Icon(
                      Icons.numbers,
                      color: _primaryColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey[300]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese la cantidad generada';
                    }
                    return null;
                  },
                ),
              ],
            ),
            
            // Sección de datos del responsable
            SectionCard(
              icon: '👤',
              title: 'Datos del Responsable',
              children: [
                TextFormField(
                  controller: _operadorController,
                  focusNode: _operadorFocus,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Nombre del operador',
                    hintText: 'Ej: Juan Pérez',
                    prefixIcon: Icon(
                      Icons.person,
                      color: _primaryColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey[300]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese el nombre del operador';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Botón para firma
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FieldLabel(
                      text: 'Firma del responsable',
                      isRequired: true,
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _showSignatureDialog,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        height: 150,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _hasSignature
                                ? Colors.green
                                : Colors.grey[300]!,
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[50],
                        ),
                        child: Center(
                          child: _hasSignature
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      size: 48,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Firma capturada',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Toque para modificar',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.draw,
                                      size: 48,
                                      color: _primaryColor,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Toque para firmar',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: _primaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            // Sección de evidencia fotográfica
            SectionCard(
              icon: '📷',
              title: 'Evidencia Fotográfica',
              children: [
                PhotoEvidenceFormField(
                  onPhotosChanged: (photos) {
                    setState(() {
                      _photos = photos;
                    });
                  },
                  primaryColor: _primaryColor,
                  isRequired: true,
                ),
              ],
            ),
            
            // Sección de comentarios
            SectionCard(
              icon: '💬',
              title: 'Comentarios',
              children: [
                TextFormField(
                  controller: _comentariosController,
                  focusNode: _comentariosFocus,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Comentarios adicionales (opcional)',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey[300]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Botón de procesar salida
            ElevatedButton(
              onPressed: _procesarSalida,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
              child: const Text(
                'Procesar Salida',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(height: 32),
              ],
            ),
          ),
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: CircularProgressIndicator(
                  color: _primaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}