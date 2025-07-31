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
import '../../../services/transformacion_service.dart';
import '../../../services/user_session_service.dart';
import '../../../services/firebase/firebase_storage_service.dart';
import '../../../models/lotes/lote_unificado_model.dart';
import '../shared/widgets/signature_dialog.dart';
import '../shared/widgets/photo_evidence_widget.dart';
import '../shared/widgets/weight_input_widget.dart';
import '../shared/widgets/unified_container.dart';
import '../shared/widgets/field_label.dart';
import '../shared/utils/dialog_utils.dart';
import 'transformador_documentacion_screen.dart';
import 'utils/transformador_navigation_helper.dart';

class TransformadorFormularioSalida extends StatefulWidget {
  final String? loteId; // Individual
  final List<String>? lotesIds; // Múltiples
  final double? peso;
  final List<String>? tiposAnalisis;
  final String? productoFabricado;
  final String? composicionMaterial;
  final String? tipoPolimero;
  
  const TransformadorFormularioSalida({
    super.key,
    this.loteId, // Individual
    this.lotesIds, // Múltiples
    this.peso,
    this.tiposAnalisis,
    this.productoFabricado,
    this.composicionMaterial,
    this.tipoPolimero,
  });

  @override
  State<TransformadorFormularioSalida> createState() => _TransformadorFormularioSalidaState();
}

class _TransformadorFormularioSalidaState extends State<TransformadorFormularioSalida> {
  final _formKey = GlobalKey<FormState>();
  final Color _primaryColor = Colors.orange;
  
  // Servicios
  final LoteService _loteService = LoteService();
  final LoteUnificadoService _loteUnificadoService = LoteUnificadoService();
  final TransformacionService _transformacionService = TransformacionService();
  final UserSessionService _userSession = UserSessionService();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  
  // Variables para manejar múltiples lotes
  late List<String> _loteIds;
  bool _esProcesamientoMultiple = false;
  double _pesoTotalOriginal = 0.0;
  
  // Controladores
  final TextEditingController _pesoSalidaController = TextEditingController();
  final TextEditingController _operadorController = TextEditingController();
  final TextEditingController _comentariosController = TextEditingController();
  final TextEditingController _productoGeneradoController = TextEditingController();
  final TextEditingController _cantidadGeneradaController = TextEditingController();
  final TextEditingController _mermaController = TextEditingController();
  final TextEditingController _productoFabricadoController = TextEditingController();
  final TextEditingController _compuestoController = TextEditingController();
  
  
  // Variables para los procesos aplicados (tipos de proceso del transformador)
  final Map<String, bool> _procesosAplicados = {
    'Inyección': false,
    'Rotomoldeo': false,
    'Extrusión': false,
    'Termoformado': false,
    'Pultrusión': false,
    'Soplado': false,
    'Laminado': false,
    'Plástico corrugado': false,
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
  
  // Variables para el transformador
  String? _tipoPolimero; // Se extrae del lote
  final double _porcentajeMaterialReciclado = 33.0; // Fijo
  String? _transformacionId; // ID del megalote si existe
  bool _hasUnsavedChanges = false;
  List<String> _existingPhotoUrls = [];
  bool _hasImages = false;

  @override
  void initState() {
    super.initState();
    
    // Determinar si es procesamiento múltiple o individual
    if (widget.lotesIds != null && widget.lotesIds!.isNotEmpty) {
      _loteIds = widget.lotesIds!;
      _esProcesamientoMultiple = widget.lotesIds!.length > 1;
    } else if (widget.loteId != null) {
      _loteIds = [widget.loteId!];
      _esProcesamientoMultiple = false;
    } else {
      _loteIds = [];
      _esProcesamientoMultiple = false;
    }
    
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
    _mermaController.dispose();
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
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      double pesoTotal = 0.0;
      Set<String> tiposPolimero = {};
      
      // Cargar información de los lotes
      for (String loteId in _loteIds) {
        final lote = await _loteUnificadoService.obtenerLotePorId(loteId);
        if (lote != null) {
          pesoTotal += lote.pesoActual;
          tiposPolimero.add(lote.datosGenerales.tipoMaterial);
        }
      }
      
      // Verificar que todos los lotes sean del mismo material
      if (tiposPolimero.length > 1) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Materiales diferentes'),
              content: const Text(
                'Los lotes seleccionados contienen diferentes tipos de material. '
                'Solo se pueden procesar juntos lotes del mismo tipo de material.'
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop(); // Salir del formulario
                  },
                  child: const Text('Entendido'),
                ),
              ],
            ),
          );
          return;
        }
      }
      
      // Establecer el tipo de polímero
      _tipoPolimero = tiposPolimero.first;
      
      // Verificar si existe una transformación guardada para estos lotes
      final transformacionExistente = await _checkExistingTransformacion();
      if (transformacionExistente != null) {
        _transformacionId = transformacionExistente.id;
        await _loadSavedData(transformacionExistente.data() as Map<String, dynamic>);
      }
      
      setState(() {
        _pesoTotalOriginal = pesoTotal;
        if (_cantidadGeneradaController.text.isEmpty) {
          _cantidadGeneradaController.text = pesoTotal.toStringAsFixed(2);
        }
        _isLoading = false;
      });
    } catch (e) {
      print('Error al inicializar formulario: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<DocumentSnapshot?> _checkExistingTransformacion() async {
    try {
      // Buscar transformación existente con estos lotes y estado 'en_proceso'
      final query = await FirebaseFirestore.instance
          .collection('transformaciones')
          .where('tipo', isEqualTo: 'agrupacion_transformador')
          .where('estado', isEqualTo: 'en_proceso')
          .where('usuario_id', isEqualTo: _userSession.getUserData()?['userId'] ?? _userSession.getUserData()?['uid'])
          .get();
      
      for (var doc in query.docs) {
        final data = doc.data();
        final lotesEntrada = List<String>.from(
          (data['lotes_entrada'] as List).map((lote) => lote['lote_id'])
        );
        
        // Verificar si contiene los mismos lotes
        if (lotesEntrada.length == _loteIds.length &&
            lotesEntrada.toSet().containsAll(_loteIds)) {
          return doc;
        }
      }
      
      return null;
    } catch (e) {
      print('Error al buscar transformación existente: $e');
      return null;
    }
  }
  
  Future<void> _loadSavedData(Map<String, dynamic> data) async {
    setState(() {
      // Cargar procesos aplicados
      if (data['procesos_aplicados'] != null) {
        final procesos = List<String>.from(data['procesos_aplicados']);
        for (var proceso in procesos) {
          if (_procesosAplicados.containsKey(proceso)) {
            _procesosAplicados[proceso] = true;
          }
        }
      }
      
      // Cargar campos de texto
      _productoFabricadoController.text = data['producto_fabricado'] ?? '';
      _compuestoController.text = data['compuesto_67'] ?? '';
      _cantidadGeneradaController.text = (data['cantidad_producto'] ?? _pesoTotalOriginal).toString();
      _comentariosController.text = data['observaciones'] ?? '';
      
      // Cargar firma si existe
      if (data['firma_operador'] != null) {
        _signatureUrl = data['firma_operador'];
        _hasSignature = true;
      }
      
      // Cargar fotos si existen
      if (data['evidencias_foto'] != null) {
        _existingPhotoUrls = List<String>.from(data['evidencias_foto']);
        _hasImages = _existingPhotoUrls.isNotEmpty;
      }
    });
  }
  
  Future<void> _guardarBorrador() async {
    if (_transformacionId == null) {
      // Crear nueva transformación si no existe
      final transformacionData = await _prepareTransformacionData();
      final docRef = await FirebaseFirestore.instance
          .collection('transformaciones')
          .add(transformacionData);
      _transformacionId = docRef.id;
    } else {
      // Actualizar transformación existente
      final updateData = await _prepareTransformacionData();
      await FirebaseFirestore.instance
          .collection('transformaciones')
          .doc(_transformacionId)
          .update(updateData);
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Borrador guardado'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  
  Future<Map<String, dynamic>> _prepareTransformacionData() async {
    final userData = await _userSession.getUserProfile();
    
    // Preparar datos de los lotes
    List<Map<String, dynamic>> lotesEntrada = [];
    for (String loteId in _loteIds) {
      final lote = await _loteUnificadoService.obtenerLotePorId(loteId);
      if (lote != null) {
        lotesEntrada.add({
          'lote_id': loteId,
          'peso': lote.pesoActual,
          'tipo_material': lote.datosGenerales.tipoMaterial,
        });
      }
    }
    
    return {
      'tipo': 'agrupacion_transformador',
      'estado': 'en_proceso',
      'fecha_inicio': FieldValue.serverTimestamp(),
      'lotes_entrada': lotesEntrada,
      'peso_total_entrada': _pesoTotalOriginal,
      'procesos_aplicados': _procesosAplicados.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList(),
      'producto_fabricado': _productoFabricadoController.text.trim(),
      'compuesto_67': _compuestoController.text.trim(),
      'cantidad_producto': double.tryParse(_cantidadGeneradaController.text) ?? 0,
      'porcentaje_material_reciclado': _porcentajeMaterialReciclado,
      'tipo_polimero': _tipoPolimero,
      'observaciones': _comentariosController.text.trim(),
      'usuario_id': userData?['userId'] ?? userData?['uid'] ?? '',
      'usuario_folio': userData?['ecoceFolio'] ?? userData?['folio'] ?? '',
      'firma_operador': _signatureUrl,
      'evidencias_foto': _existingPhotoUrls,
      'ultima_actualizacion': FieldValue.serverTimestamp(),
    };
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
        // Guardar borrador después de firmar
        _guardarBorrador();
      },
      primaryColor: _primaryColor,
    );
  }
  
  void _markAsUnsaved() {
    setState(() {
      _hasUnsavedChanges = true;
    });
  }
  
  bool _checkUnsavedChanges() {
    return _hasUnsavedChanges || 
           _productoFabricadoController.text.isNotEmpty ||
           _compuestoController.text.isNotEmpty ||
           _cantidadGeneradaController.text != _pesoTotalOriginal.toStringAsFixed(2) ||
           _comentariosController.text.isNotEmpty ||
           _procesosAplicados.values.any((selected) => selected) ||
           _hasSignature ||
           _photos.isNotEmpty;
  }
  
  bool _isFormValid() {
    return _productoFabricadoController.text.isNotEmpty &&
           _compuestoController.text.isNotEmpty &&
           _cantidadGeneradaController.text.isNotEmpty &&
           _procesosAplicados.values.any((selected) => selected) &&
           _hasSignature &&
           _photos.isNotEmpty;
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
      
      // Procesamiento según sea individual o múltiple
      if (_esProcesamientoMultiple) {
        // Crear transformación (megalote) del transformador
        // Primero obtener los lotes
        List<LoteUnificadoModel> lotes = [];
        for (String loteId in _loteIds) {
          final lote = await _loteUnificadoService.obtenerLotePorId(loteId);
          if (lote != null) {
            lotes.add(lote);
          }
        }
        
        if (lotes.isEmpty) {
          throw Exception('No se pudieron obtener los lotes');
        }
        
        // Preparar datos de los lotes
        List<Map<String, dynamic>> lotesEntrada = [];
        for (var lote in lotes) {
          lotesEntrada.add({
            'lote_id': lote.id,
            'peso': lote.pesoActual,
            'tipo_material': lote.datosGenerales.tipoMaterial,
          });
          
          // Marcar lote como consumido en transformación
          // Mark lot as consumed in transformation
          await FirebaseFirestore.instance
              .collection('lotes')
              .doc(lote.id)
              .collection('datos_generales')
              .doc('info')
              .update({
            'consumido_en_transformacion': true,
            'transformacion_id': _transformacionId ?? '',
          });
        }
        
        // Crear o actualizar la transformación
        final transformacionData = {
          'tipo': 'agrupacion_transformador',
          'estado': 'documentacion',
          'fecha_inicio': FieldValue.serverTimestamp(),
          'lotes_entrada': lotesEntrada,
          'peso_total_entrada': _pesoTotalOriginal,
          'procesos_aplicados': procesosSeleccionados,
          'producto_fabricado': _productoFabricadoController.text.trim(),
          'compuesto_67': _compuestoController.text.trim(),
          'cantidad_producto': double.tryParse(_cantidadGeneradaController.text) ?? 0,
          'porcentaje_material_reciclado': _porcentajeMaterialReciclado,
          'tipo_polimero': _tipoPolimero,
          'observaciones': _comentariosController.text.trim(),
          'usuario_id': userProfile['userId'] ?? userProfile['uid'] ?? '',
          'usuario_folio': userProfile['ecoceFolio'] ?? userProfile['folio'] ?? '',
          'firma_operador': _signatureUrl,
          'evidencias_foto': photoUrls,
          'fecha_procesamiento': FieldValue.serverTimestamp(),
        };
        
        if (_transformacionId != null) {
          // Actualizar transformación existente
          await FirebaseFirestore.instance
              .collection('transformaciones')
              .doc(_transformacionId)
              .update(transformacionData);
        } else {
          // Crear nueva transformación
          final docRef = await FirebaseFirestore.instance
              .collection('transformaciones')
              .add(transformacionData);
          _transformacionId = docRef.id;
          
          // Actualizar IDs de lotes consumidos
          for (var lote in lotes) {
            // Mark lot as consumed in transformation
            await FirebaseFirestore.instance
                .collection('lotes')
                .doc(lote.id)
                .collection('datos_generales')
                .doc('info')
                .update({
              'consumido_en_transformacion': true,
              'transformacion_id': _transformacionId!,
            });
          }
        }
        
      } else {
        // Procesamiento individual - comportamiento original
        await _loteUnificadoService.actualizarProcesoTransformador(
          loteId: _loteIds.first,
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
      }
      
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
        await Future.delayed(const Duration(milliseconds: 1500));
        
        // Navegar según el tipo de procesamiento
        if (mounted) {
          if (_esProcesamientoMultiple) {
            // Para procesamiento múltiple (megalotes), volver a producción con tab Documentación
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/transformador_produccion',
              (route) => false,
              arguments: {
                'initialTab': 1, // Tab de Documentación
                'showMegalotes': true, // Force show megalotes
              },
            );
          } else {
            // Para lotes individuales, ir a documentación
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => TransformadorDocumentacionScreen(
                  loteId: _loteIds.first,
                  material: widget.tipoPolimero ?? _tipoPolimero ?? 'Material',
                  peso: widget.peso ?? _pesoTotalOriginal,
                ),
              ),
            );
            
            // If documentation was completed or user pressed back, return to production
            if (mounted) {
              // Determine which tab to show based on whether documentation was completed
              final tabIndex = result == true ? 2 : 1; // Completados if true, Documentación if false
              
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/transformador_produccion',
                (route) => false,
                arguments: {'initialTab': tabIndex},
              );
            }
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
        title: Text(
          _esProcesamientoMultiple 
            ? 'Procesamiento de ${_loteIds.length} Lotes' 
            : 'Formulario de Salida',
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
                          Expanded(
                            child: Text(
                              _esProcesamientoMultiple 
                                ? 'Procesando ${_loteIds.length} lotes/sublotes'
                                : 'Lote: ${_loteIds.isNotEmpty ? _loteIds.first : ""}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _primaryColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_esProcesamientoMultiple) ...[
                        Text(
                          'Peso total: ${_pesoTotalOriginal.toStringAsFixed(2)} kg',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                        if (_loteIds.isNotEmpty)
                          Text(
                            'Lotes seleccionados:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ..._loteIds.take(3).map((id) => Text(
                          '• ${id.substring(0, id.length > 8 ? 8 : id.length)}...',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        )).toList(),
                        if (_loteIds.length > 3)
                          Text(
                            '• y ${_loteIds.length - 3} más...',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ] else ...[
                        if (widget.productoFabricado != null)
                          Text(
                            'Producto: ${widget.productoFabricado}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        Text(
                          'Peso inicial: ${widget.peso ?? _pesoTotalOriginal} kg',
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
                PhotoEvidenceWidget(
                  title: '', // Empty title since SectionCard already provides it
                  onPhotosChanged: (photos) {
                    setState(() {
                      _photos = photos;
                    });
                  },
                  primaryColor: _primaryColor,
                  isRequired: true,
                  showCounter: true,
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
                  onChanged: (_) => _markAsUnsaved(),
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