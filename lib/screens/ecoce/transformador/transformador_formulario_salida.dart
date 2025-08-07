import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../utils/colors.dart';
import '../../../utils/ui_constants.dart';
import '../../../services/lote_service.dart';
import '../../../services/lote_unificado_service.dart';
import '../../../services/transformacion_service.dart';
import '../../../services/user_session_service.dart';
import '../../../services/firebase/firebase_storage_service.dart';
import '../../../services/firebase/auth_service.dart';
import '../../../services/firebase/firebase_manager.dart';
import '../../../models/lotes/lote_unificado_model.dart';
import '../shared/widgets/signature_dialog.dart';
import '../shared/widgets/photo_evidence_widget.dart';
import '../shared/widgets/weight_input_widget.dart';
import '../shared/widgets/field_label.dart';
import '../shared/utils/dialog_utils.dart';
import 'utils/transformador_navigation_helper.dart';

// Painter personalizado para la firma con color naranja
class TransformadorSignaturePainter extends CustomPainter {
  final List<Offset?> points;
  final Color color;
  final double strokeWidth;

  TransformadorSignaturePainter({
    required this.points,
    required this.color,
    this.strokeWidth = UIConstants.strokeWidth,
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
  bool shouldRepaint(TransformadorSignaturePainter oldDelegate) => true;
}

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
  final AuthService _authService = AuthService();
  final FirebaseManager _firebaseManager = FirebaseManager();
  
  // Obtener Firestore de la instancia correcta (multi-tenant)
  FirebaseFirestore get _firestore {
    final app = _firebaseManager.currentApp;
    if (app != null) {
      return FirebaseFirestore.instanceFor(app: app);
    }
    return FirebaseFirestore.instance;
  }
  
  // Variables para manejar múltiples lotes
  late List<String> _loteIds;
  bool _esProcesamientoMultiple = false;
  double _pesoTotalOriginal = 0.0;
  
  // Controladores para peso individual por lote (NUEVO)
  final Map<String, TextEditingController> _pesosRecibidosControllers = {};
  final Map<String, double> _mermasCalculadas = {};
  final Map<String, double> _pesosBrutos = {}; // Para almacenar el peso original de cada lote
  
  // Controladores
  final TextEditingController _pesoSalidaController = TextEditingController(); // Se mantendrá para compatibilidad
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
    // Limpiar controladores dinámicos
    _pesosRecibidosControllers.forEach((_, controller) {
      controller.dispose();
    });
    _pesoSalidaController.dispose();
    _operadorController.dispose();
    _comentariosController.dispose();
    _productoGeneradoController.dispose();
    _cantidadGeneradaController.dispose();
    _mermaController.dispose();
    _productoFabricadoController.dispose();
    _compuestoController.dispose();
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
      
      // Cargar información de los lotes y crear controladores dinámicos
      for (String loteId in _loteIds) {
        final lote = await _loteUnificadoService.obtenerLotePorId(loteId);
        if (lote != null) {
          final pesoLote = lote.pesoActual;
          pesoTotal += pesoLote;
          tiposPolimero.add(lote.datosGenerales.tipoMaterial);
          
          // Almacenar peso bruto original
          _pesosBrutos[loteId] = pesoLote;
          
          // Crear controlador para este lote si es procesamiento múltiple
          if (_esProcesamientoMultiple) {
            _pesosRecibidosControllers[loteId] = TextEditingController();
            _mermasCalculadas[loteId] = 0.0;
          }
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
          _cantidadGeneradaController.text = '0.00';
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
      final query = await _firestore
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
        // Note: _signaturePoints will remain empty but _signatureUrl indicates saved signature
      }
      
      // Cargar fotos si existen
      if (data['evidencias_foto'] != null) {
        _existingPhotoUrls = List<String>.from(data['evidencias_foto']);
        _hasImages = _existingPhotoUrls.isNotEmpty;
      }
    });
  }
  
  Future<void> _guardarBorrador() async {
    // Validar que tengamos el peso de salida antes de guardar
    if (_pesoSalidaController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor ingrese el peso de salida antes de guardar'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    
    if (_transformacionId == null) {
      // Verificar primero si ya existe una transformación para estos lotes
      final authUid = _authService.currentUser?.uid;
      if (authUid == null) return;
      
      final existingQuery = await _firestore
          .collection('transformaciones')
          .where('tipo', isEqualTo: 'agrupacion_transformador')
          .where('usuario_id', isEqualTo: authUid)
          .where('estado', isEqualTo: 'en_proceso')
          .get();
      
      // Buscar si alguna transformación tiene los mismos lotes
      for (var doc in existingQuery.docs) {
        final data = doc.data();
        final existingLotes = (data['lotes_entrada'] as List<dynamic>?) ?? [];
        final existingLoteIds = existingLotes.map((l) => l['lote_id']).toSet();
        
        if (_loteIds.toSet().intersection(existingLoteIds).isNotEmpty) {
          _transformacionId = doc.id;
          break;
        }
      }
      
      if (_transformacionId == null) {
        // Crear nueva transformación solo si no existe
        final transformacionData = await _prepareTransformacionData();
        final docRef = await _firestore
            .collection('transformaciones')
            .add(transformacionData);
        _transformacionId = docRef.id;
      } else {
        // Actualizar la existente
        final updateData = await _prepareTransformacionData();
        await _firestore
            .collection('transformaciones')
            .doc(_transformacionId)
            .set(updateData, SetOptions(merge: true));
      }
    } else {
      // Actualizar transformación existente
      final updateData = await _prepareTransformacionData();
      await _firestore
          .collection('transformaciones')
          .doc(_transformacionId)
          .set(updateData, SetOptions(merge: true));
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
    // Obtener el UID del AuthService que maneja multi-tenant
    final currentUser = _authService.currentUser;
    
    if (currentUser == null) {
      throw Exception('Usuario no autenticado');
    }
    
    final authUid = currentUser.uid;
    final userData = _userSession.getUserData();
    final userFolio = userData?['folio'] ?? '';
    
    // Preparar datos de los lotes con porcentajes
    List<Map<String, dynamic>> lotesEntrada = [];
    double pesoTotal = 0;
    
    // Primero calcular peso total
    for (String loteId in _loteIds) {
      final lote = await _loteUnificadoService.obtenerLotePorId(loteId);
      if (lote != null) {
        pesoTotal += lote.pesoActual;
      }
    }
    
    // Luego crear lotes con porcentajes
    for (String loteId in _loteIds) {
      final lote = await _loteUnificadoService.obtenerLotePorId(loteId);
      if (lote != null) {
        final peso = lote.pesoActual;
        final porcentaje = pesoTotal > 0 ? (peso / pesoTotal) * 100 : 0;
        
        lotesEntrada.add({
          'lote_id': loteId,
          'peso': peso,
          'porcentaje': porcentaje,
          'tipo_material': lote.datosGenerales.tipoMaterial,
        });
      }
    }
    
    // Calcular merma
    final pesoSalida = double.tryParse(_pesoSalidaController.text) ?? _pesoTotalOriginal;
    final cantidadGenerada = double.tryParse(_cantidadGeneradaController.text) ?? 0;
    final mermaProceso = _pesoTotalOriginal - pesoSalida;
    
    final procesosSeleccionados = _procesosAplicados.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
    
    return {
      'tipo': 'agrupacion_transformador',
      'usuario_id': authUid,
      'usuario_folio': userFolio,
      'fecha_inicio': Timestamp.fromDate(DateTime.now()),
      'estado': 'en_proceso',
      'lotes_entrada': lotesEntrada,
      'peso_total_entrada': _pesoTotalOriginal,
      'peso_disponible': pesoSalida,
      'peso_salida': pesoSalida,
      'merma_proceso': mermaProceso >= 0 ? mermaProceso : 0,
      'sublotes_generados': [],
      'documentos_asociados': {},
      'procesos_aplicados': procesosSeleccionados,
      'producto_fabricado': _productoFabricadoController.text.trim(),
      'compuesto_67': _compuestoController.text.trim(),
      'cantidad_producto': cantidadGenerada,
      'porcentaje_material_reciclado': _porcentajeMaterialReciclado,
      'tipo_polimero': _tipoPolimero,
      'proceso_aplicado': procesosSeleccionados.isNotEmpty ? procesosSeleccionados.join(', ') : null,
      'observaciones': _comentariosController.text.trim(),
      'firma_operador': _signatureUrl,
      'evidencias_foto': _existingPhotoUrls,
      'ultima_actualizacion': Timestamp.fromDate(DateTime.now()),
      'muestras_laboratorio': [],
    };
  }

  void _showSignatureDialog() async {
    // Primero ocultar el teclado
    FocusScope.of(context).unfocus();
    
    // Esperar un breve momento para que el teclado se oculte completamente
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (!mounted) return;
    
    SignatureDialog.show(
      context: context,
      title: 'Firma del Operador',
      initialSignature: _signaturePoints,
      onSignatureSaved: (points) {
        setState(() {
          _signaturePoints = List.from(points);
        });
        // NO guardar borrador automáticamente después de firmar para evitar duplicados
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
           _signaturePoints.isNotEmpty ||
           _photos.isNotEmpty;
  }
  
  bool _isFormValid() {
    return _productoFabricadoController.text.isNotEmpty &&
           _compuestoController.text.isNotEmpty &&
           _cantidadGeneradaController.text.isNotEmpty &&
           _procesosAplicados.values.any((selected) => selected) &&
           _signaturePoints.isNotEmpty &&
           _photos.isNotEmpty;
  }

  // Métodos auxiliares para cálculo de pesos y mermas
  double _calcularPesoNetoTotal() {
    if (!_esProcesamientoMultiple) {
      return double.tryParse(_pesoSalidaController.text) ?? _pesoTotalOriginal;
    }
    
    double total = 0.0;
    _pesosRecibidosControllers.forEach((loteId, controller) {
      final peso = double.tryParse(controller.text);
      if (peso != null && peso > 0) {
        total += peso;
      }
    });
    return total;
  }
  
  double _calcularMermaTotal() {
    final pesoNeto = _calcularPesoNetoTotal();
    return _pesoTotalOriginal - pesoNeto;
  }
  
  double _calcularPorcentajeMerma() {
    if (_pesoTotalOriginal == 0) return 0;
    final merma = _calcularMermaTotal();
    return (merma / _pesoTotalOriginal) * 100;
  }
  
  void _calcularMermaIndividual(String loteId) {
    if (!_esProcesamientoMultiple) return;
    
    final pesoBruto = _pesosBrutos[loteId] ?? 0;
    final controllerNeto = _pesosRecibidosControllers[loteId];
    if (controllerNeto == null) return;
    
    final pesoNeto = double.tryParse(controllerNeto.text) ?? 0;
    
    setState(() {
      if (pesoNeto > 0 && pesoNeto <= pesoBruto) {
        _mermasCalculadas[loteId] = pesoBruto - pesoNeto;
      } else {
        _mermasCalculadas[loteId] = 0;
      }
    });
  }

  void _procesarSalida() async {
    // Validar formulario
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Validación específica para procesamiento múltiple
    if (_esProcesamientoMultiple) {
      // Verificar que todos los lotes tengan peso ingresado
      for (String loteId in _loteIds) {
        final controller = _pesosRecibidosControllers[loteId];
        if (controller == null || controller.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Por favor ingrese el peso para todos los lotes'),
              backgroundColor: BioWayColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadiusConstants.borderRadiusSmall,
              ),
            ),
          );
          return;
        }
      }
      
      // Confirmación si la merma total es mayor al 10%
      final porcentajeMerma = _calcularPorcentajeMerma();
      if (porcentajeMerma > 10) {
        final confirmar = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange, size: 28),
                SizedBox(width: 12),
                Text('Merma Elevada'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'La merma total es del ${porcentajeMerma.toStringAsFixed(1)}%, '
                  'lo cual supera el 10% esperado.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Peso bruto total: ${_pesoTotalOriginal.toStringAsFixed(2)} kg'),
                      Text('Peso neto total: ${_calcularPesoNetoTotal().toStringAsFixed(2)} kg'),
                      Text('Merma total: ${_calcularMermaTotal().toStringAsFixed(2)} kg'),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  '¿Está seguro de continuar con estos valores?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Revisar valores'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                child: Text('Continuar de todos modos'),
              ),
            ],
          ),
        );
        
        if (confirmar != true) {
          return;
        }
      }
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
            borderRadius: BorderRadiusConstants.borderRadiusSmall,
          ),
        ),
      );
      return;
    }
    
    // Validar firma
    if (_signaturePoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor capture la firma del responsable'),
          backgroundColor: BioWayColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusConstants.borderRadiusSmall,
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
            borderRadius: BorderRadiusConstants.borderRadiusSmall,
          ),
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Obtener el UID del AuthService que maneja multi-tenant (como hace el Reciclador)
      final currentUser = _authService.currentUser;
      
      if (currentUser == null) {
        throw Exception('Usuario no autenticado. Por favor cierre sesión y vuelva a iniciar.');
      }
      
      final authUid = currentUser.uid;
      print('=== USUARIO FIREBASE AUTH (Multi-tenant) ===');
      print('Firebase Auth UID: $authUid');
      
      // Obtener datos adicionales del usuario para el folio
      final userData = _userSession.getUserData();
      final userFolio = userData?['folio'] ?? '';
      
      print('Usuario Folio: $userFolio');
      print('=== VERIFICACIÓN DE USUARIO ===');
      print('UID de Auth: $authUid');
      print('Folio del usuario: $userFolio');
      
      if (authUid.isEmpty) {
        throw Exception('No se pudo obtener el ID del usuario autenticado');
      }
      
      if (userFolio.isEmpty) {
        throw Exception('No se pudo obtener el folio del usuario');
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
        // Primero obtener y validar los lotes
        List<LoteUnificadoModel> lotes = [];
        for (String loteId in _loteIds) {
          final lote = await _loteUnificadoService.obtenerLotePorId(loteId);
          if (lote != null) {
            // Verificar que el lote está en proceso transformador
            if (lote.datosGenerales.procesoActual != 'transformador') {
              throw Exception('El lote ${lote.id} no está disponible para el transformador');
            }
            
            // Verificar que no esté ya consumido
            final datosGeneralesDoc = await _firestore
                .collection('lotes')
                .doc(loteId)
                .collection('datos_generales')
                .doc('info')
                .get();
            
            if (datosGeneralesDoc.exists && 
                datosGeneralesDoc.data()?['consumido_en_transformacion'] == true) {
              throw Exception('El lote ${lote.id} ya fue procesado en otra transformación');
            }
            
            lotes.add(lote);
          } else {
            throw Exception('No se pudo obtener el lote $loteId');
          }
        }
        
        if (lotes.isEmpty) {
          throw Exception('No se pudieron obtener los lotes');
        }
        
        // Preparar datos de los lotes con pesos individuales procesados
        List<Map<String, dynamic>> lotesEntrada = [];
        double pesoTotalProcesado = 0;
        
        // Usar pesos procesados individuales si están disponibles
        for (var lote in lotes) {
          double pesoProcesado;
          
          if (_esProcesamientoMultiple && _pesosRecibidosControllers.containsKey(lote.id)) {
            // Usar el peso neto individual ingresado
            pesoProcesado = double.tryParse(_pesosRecibidosControllers[lote.id]!.text) ?? lote.pesoActual;
          } else {
            // Para lote único, usar el peso del campo general
            pesoProcesado = double.tryParse(_pesoSalidaController.text) ?? lote.pesoActual;
          }
          
          pesoTotalProcesado += pesoProcesado;
          
          lotesEntrada.add({
            'lote_id': lote.id,
            'peso': lote.pesoActual, // Peso original
            'peso_procesado': pesoProcesado, // NUEVO: Peso neto real aprovechable
            'tipo_material': lote.datosGenerales.tipoMaterial,
          });
        }
        
        // Calcular porcentajes basados en el peso procesado
        for (var loteData in lotesEntrada) {
          final pesoProcesado = loteData['peso_procesado'] as double;
          loteData['porcentaje'] = pesoTotalProcesado > 0 
            ? (pesoProcesado / pesoTotalProcesado) * 100 
            : 0;
        }
        
        // Crear o actualizar la transformación
        // IMPORTANTE: Usar el mismo formato que el Reciclador con Timestamp
        
        // Debugging: Verificar que tenemos los campos requeridos
        print('=== CREANDO TRANSFORMACIÓN ===');
        print('usuario_id (Firebase Auth): $authUid');
        print('usuario_folio: $userFolio');
        print('tipo: agrupacion_transformador');
        print('Verificando que UID coincide con Auth: ${authUid == _authService.currentUser?.uid}');
        
        // Calcular merma usando el método auxiliar que considera múltiples lotes
        final pesoSalida = _calcularPesoNetoTotal();
        final cantidadGenerada = double.tryParse(_cantidadGeneradaController.text) ?? 0;
        final mermaProceso = _calcularMermaTotal();
        
        final transformacionData = {
          'tipo': 'agrupacion_transformador',
          'usuario_id': authUid, // Usar el UID de Firebase Auth directamente
          'usuario_folio': userFolio,
          'fecha_inicio': Timestamp.fromDate(DateTime.now()), // CONVERTIR A TIMESTAMP como el Reciclador
          'estado': 'documentacion',
          'lotes_entrada': lotesEntrada,
          'peso_total_entrada': _pesoTotalOriginal,
          'peso_disponible': pesoSalida, // Peso disponible después de merma
          'peso_salida': pesoSalida, // Peso de salida real en kg
          'merma_proceso': mermaProceso >= 0 ? mermaProceso : 0, // Campo REQUERIDO por el modelo
          'sublotes_generados': [], // Campo REQUERIDO - lista vacía inicial
          'documentos_asociados': {}, // Campo REQUERIDO - mapa vacío inicial
          // Campos específicos del transformador
          'procesos_aplicados': procesosSeleccionados,
          'producto_fabricado': _productoFabricadoController.text.trim(),
          'compuesto_67': _compuestoController.text.trim(),
          'cantidad_producto': cantidadGenerada,
          'porcentaje_material_reciclado': _porcentajeMaterialReciclado,
          'tipo_polimero': _tipoPolimero,
          'proceso_aplicado': procesosSeleccionados.isNotEmpty ? procesosSeleccionados.join(', ') : null,
          'observaciones': _comentariosController.text.trim(),
          'firma_operador': _signatureUrl,
          'evidencias_foto': photoUrls,
          'fecha_procesamiento': Timestamp.fromDate(DateTime.now()), // CONVERTIR A TIMESTAMP
          'muestras_laboratorio': [], // Campo para compatibilidad
        };
        
        // Verificar si ya existe una transformación para estos lotes
        if (_transformacionId == null) {
          // Buscar si ya existe una transformación con estos lotes para evitar duplicados
          final existingQuery = await _firestore
              .collection('transformaciones')
              .where('tipo', isEqualTo: 'agrupacion_transformador')
              .where('usuario_id', isEqualTo: authUid)
              .get();
          
          // Verificar si alguna transformación existente tiene los mismos lotes
          String? existingId;
          for (var doc in existingQuery.docs) {
            final data = doc.data();
            final existingLotes = (data['lotes_entrada'] as List<dynamic>?) ?? [];
            final existingLoteIds = existingLotes.map((l) => l['lote_id']).toSet();
            final currentLoteIds = lotesEntrada.map((l) => l['lote_id']).toSet();
            
            // Verificar igualdad exacta: mismo número de lotes y todos coinciden
            if (existingLoteIds.length == currentLoteIds.length &&
                existingLoteIds.containsAll(currentLoteIds)) {
              existingId = doc.id;
              break;
            }
          }
          
          if (existingId != null) {
            // Actualizar la transformación existente
            print('Actualizando transformación existente encontrada: $existingId');
            _transformacionId = existingId;
            await _firestore
                .collection('transformaciones')
                .doc(_transformacionId)
                .set(transformacionData, SetOptions(merge: true));
          } else {
            // Crear nueva transformación
            print('Creando nueva transformación...');
            try {
              final docRef = await _firestore
                  .collection('transformaciones')
                  .add(transformacionData);
              _transformacionId = docRef.id;
              print('Transformación creada con ID: $_transformacionId');
            } catch (e) {
              print('ERROR al crear transformación: $e');
              throw Exception('Error al crear megalote: $e');
            }
          }
        } else {
          // Actualizar transformación existente usando set con merge para evitar problemas
          print('Actualizando transformación existente: $_transformacionId');
          await _firestore
              .collection('transformaciones')
              .doc(_transformacionId)
              .set(transformacionData, SetOptions(merge: true));
        }
        
        // Ahora sí marcar todos los lotes como consumidos con el ID correcto
        print('Marcando ${lotes.length} lotes como consumidos...');
        for (var lote in lotes) {
          try {
            await _firestore
                .collection('lotes')
                .doc(lote.id)
                .collection('datos_generales')
                .doc('info')
                .set({
              'consumido_en_transformacion': true,
              'transformacion_id': _transformacionId!,
              'fecha_consumo': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
            print('Lote ${lote.id} marcado como consumido');
          } catch (e) {
            print('ERROR al marcar lote ${lote.id} como consumido: $e');
            // Continuar con los demás lotes
          }
        }
        
      } else {
        // Procesamiento individual - TAMBIÉN debe crear transformación para las estadísticas
        print('PROCESAMIENTO INDIVIDUAL - Creando transformación para un solo lote...');
        
        // Obtener información del lote único
        final loteDoc = await _firestore
            .collection('lotes')
            .doc(_loteIds.first)
            .collection('datos_generales')
            .doc('info')
            .get();
        
        final tipoMaterial = loteDoc.data()?['tipo_material'] ?? _tipoPolimero ?? 'Material';
        final pesoLote = (loteDoc.data()?['peso_actual'] ?? 
                         loteDoc.data()?['peso_nace'] ?? 
                         widget.peso ?? 0).toDouble();
        
        // Crear entrada para el lote único
        final loteEntrada = {
          'lote_id': _loteIds.first,
          'peso': pesoLote,
          'tipo_material': tipoMaterial,
          'porcentaje': 100.0, // Un solo lote = 100%
        };
        
        // Calcular valores
        final pesoSalida = double.tryParse(_pesoSalidaController.text) ?? pesoLote;
        final cantidadGenerada = double.tryParse(_cantidadGeneradaController.text) ?? 0;
        final mermaProceso = pesoLote - pesoSalida;
        
        // Crear transformación para lote individual
        final transformacionData = {
          'tipo': 'agrupacion_transformador',
          'usuario_id': authUid,
          'usuario_folio': userFolio,
          'fecha_inicio': Timestamp.fromDate(DateTime.now()),
          'estado': 'documentacion',
          'lotes_entrada': [loteEntrada], // Array con un solo lote
          'peso_total_entrada': pesoLote,
          'peso_disponible': pesoSalida,
          'peso_salida': pesoSalida,
          'merma_proceso': mermaProceso >= 0 ? mermaProceso : 0,
          'sublotes_generados': [],
          'documentos_asociados': {},
          // Campos específicos del transformador
          'procesos_aplicados': procesosSeleccionados,
          'producto_fabricado': _productoGeneradoController.text.trim(),
          'compuesto_67': _compuestoController.text.trim(),
          'cantidad_producto': cantidadGenerada,
          'porcentaje_material_reciclado': _porcentajeMaterialReciclado,
          'tipo_polimero': tipoMaterial,
          'proceso_aplicado': procesosSeleccionados.isNotEmpty ? procesosSeleccionados.join(', ') : null,
          'observaciones': _comentariosController.text.trim(),
          'firma_operador': _signatureUrl,
          'evidencias_foto': photoUrls,
          'fecha_procesamiento': Timestamp.fromDate(DateTime.now()),
          'muestras_laboratorio': [],
          'es_lote_individual': true, // Marcar que es procesamiento individual
        };
        
        // Verificar si ya existe una transformación para este lote individual
        final existingQuery = await _firestore
            .collection('transformaciones')
            .where('tipo', isEqualTo: 'agrupacion_transformador')
            .where('usuario_id', isEqualTo: authUid)
            .get();
        
        // Buscar transformación existente con este lote
        String? existingId;
        for (var doc in existingQuery.docs) {
          final data = doc.data();
          final existingLotes = (data['lotes_entrada'] as List<dynamic>?) ?? [];
          if (existingLotes.any((l) => l['lote_id'] == _loteIds.first)) {
            existingId = doc.id;
            break;
          }
        }
        
        if (existingId != null) {
          // Actualizar transformación existente
          print('Actualizando transformación individual existente: $existingId');
          _transformacionId = existingId;
          await _firestore
              .collection('transformaciones')
              .doc(_transformacionId)
              .set(transformacionData, SetOptions(merge: true));
        } else {
          // Crear nueva transformación
          print('Creando transformación para lote individual...');
          try {
            final docRef = await _firestore
                .collection('transformaciones')
                .add(transformacionData);
            _transformacionId = docRef.id;
            print('Transformación individual creada con ID: $_transformacionId');
          } catch (e) {
            print('ERROR al crear transformación individual: $e');
            throw Exception('Error al crear megalote individual: $e');
          }
        }
        
        // Marcar el lote como consumido
        print('Marcando lote individual como consumido...');
        await _firestore
            .collection('lotes')
            .doc(_loteIds.first)
            .collection('datos_generales')
            .doc('info')
            .set({
          'consumido_en_transformacion': true,
          'transformacion_id': _transformacionId!,
          'fecha_consumo': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        // También actualizar los datos del transformador en el lote
        await _loteUnificadoService.actualizarProcesoTransformador(
          loteId: _loteIds.first,
          datosTransformador: {
            'peso_salida': pesoSalida,
            'peso_procesado': pesoSalida, // NUEVO: Guardar también como peso_procesado para consistencia
            'producto_generado': _productoGeneradoController.text.trim(),
            'cantidad_generada': cantidadGenerada.toString(),
            'procesos_aplicados': procesosSeleccionados,
            'operador_salida': _operadorController.text.trim(),
            'firma_salida': _signatureUrl,
            'evidencias_salida': photoUrls,
            'comentarios_salida': _comentariosController.text.trim(),
            'fecha_salida': DateTime.now(),
            'estado': 'documentacion',
            'transformacion_id': _transformacionId, // Vincular con la transformación
          },
        );
        
        print('Procesamiento individual completado exitosamente');
      }
      
      if (mounted) {
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Proceso de salida registrado exitosamente'),
            backgroundColor: BioWayColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadiusConstants.borderRadiusSmall,
            ),
          ),
        );
        
        // Wait a moment for the database update to propagate
        await Future.delayed(const Duration(milliseconds: 1500));
        
        // Navegar a la pantalla de Producción en la pestaña de Documentación
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/transformador_produccion',
            (route) => false,
            arguments: {
              'initialTab': 1, // Tab de Documentación
            },
          );
        }
      }
    } catch (e) {
      // Log detallado del error para debugging
      print('=== ERROR EN TRANSFORMADOR FORMULARIO SALIDA ===');
      print('Error completo: $e');
      print('Stack trace: ${StackTrace.current}');
      print('Es procesamiento múltiple: $_esProcesamientoMultiple');
      print('Lotes a procesar: $_loteIds');
      
      if (mounted) {
        // Mejorar el mensaje de error según el tipo
        String errorMessage = 'Error al procesar la salida';
        
        if (e.toString().contains('no está disponible')) {
          errorMessage = 'Uno o más lotes no están disponibles para procesar';
        } else if (e.toString().contains('ya fue procesado')) {
          errorMessage = 'Uno o más lotes ya fueron procesados anteriormente';
        } else if (e.toString().contains('No se pudo obtener')) {
          errorMessage = 'Error al obtener información de los lotes';
        } else if (e.toString().contains('permission')) {
          // Mostrar el error completo para debugging
          errorMessage = 'Error de permisos: ${e.toString()}';
          print('Error de permisos detectado: $e');
        } else {
          errorMessage = 'Error: ${e.toString().replaceAll('Exception: ', '')}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: BioWayColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
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
                style: TextStyle(fontSize: UIConstants.fontSizeMedium),
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

  Widget _buildSeccionPesoMultiple() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de la sección
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: UIConstants.spacing16,
            vertical: UIConstants.spacing12,
          ),
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.1),
            borderRadius: BorderRadiusConstants.borderRadiusMedium,
          ),
          child: Row(
            children: [
              Icon(
                Icons.scale,
                color: _primaryColor,
                size: UIConstants.iconSizeMedium,
              ),
              SizedBox(width: UIConstants.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Control de Peso Individual por Lote',
                      style: TextStyle(
                        fontSize: UIConstants.fontSizeBody,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: UIConstants.spacing4),
                    Text(
                      'Ingrese el peso neto aprovechable de cada lote',
                      style: TextStyle(
                        fontSize: UIConstants.fontSizeMedium,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: UIConstants.spacing16),
        
        // Lista de lotes con campos de peso individual
        ..._loteIds.map((loteId) {
          final pesoBruto = _pesosBrutos[loteId] ?? 0;
          final controller = _pesosRecibidosControllers[loteId];
          final merma = _mermasCalculadas[loteId] ?? 0;
          final porcentajeMerma = pesoBruto > 0 ? (merma / pesoBruto) * 100 : 0;
          
          return Container(
            margin: EdgeInsets.only(bottom: UIConstants.spacing16),
            padding: EdgeInsets.all(UIConstants.spacing16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadiusConstants.borderRadiusMedium,
              border: Border.all(
                color: porcentajeMerma > 10 
                  ? Colors.orange.withOpacity(0.5)
                  : Colors.grey.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ID del lote
                Row(
                  children: [
                    Icon(
                      Icons.inventory_2,
                      size: UIConstants.iconSizeSmall,
                      color: _primaryColor,
                    ),
                    SizedBox(width: UIConstants.spacing8),
                    Text(
                      'Lote: ${loteId.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(
                        fontSize: UIConstants.fontSizeMedium,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: UIConstants.spacing12),
                
                // Peso bruto
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Peso bruto:',
                      style: TextStyle(
                        fontSize: UIConstants.fontSizeMedium,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${pesoBruto.toStringAsFixed(2)} kg',
                      style: const TextStyle(
                        fontSize: UIConstants.fontSizeMedium,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: UIConstants.spacing12),
                
                // Campo de peso neto
                const FieldLabel(
                  text: 'Peso neto aprovechable (kg)',
                  isRequired: true,
                ),
                SizedBox(height: UIConstants.spacing8),
                TextFormField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: 'Ingrese el peso real aprovechable',
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadiusConstants.borderRadiusMedium,
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadiusConstants.borderRadiusMedium,
                      borderSide: BorderSide(color: _primaryColor, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadiusConstants.borderRadiusMedium,
                      borderSide: const BorderSide(color: BioWayColors.error, width: 2),
                    ),
                  ),
                  onChanged: (value) {
                    _calcularMermaIndividual(loteId);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese el peso neto';
                    }
                    final peso = double.tryParse(value);
                    if (peso == null || peso <= 0) {
                      return 'Por favor ingrese un peso válido';
                    }
                    if (peso > pesoBruto) {
                      return 'El peso neto no puede ser mayor al peso bruto';
                    }
                    return null;
                  },
                ),
                
                // Indicador de merma si existe
                if (merma > 0) ...[
                  SizedBox(height: UIConstants.spacing12),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: UIConstants.spacing12,
                      vertical: UIConstants.spacing8,
                    ),
                    decoration: BoxDecoration(
                      color: porcentajeMerma > 10 
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadiusConstants.borderRadiusSmall,
                      border: Border.all(
                        color: porcentajeMerma > 10 
                          ? Colors.orange.withOpacity(0.3)
                          : Colors.green.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          porcentajeMerma > 10 ? Icons.warning : Icons.check_circle,
                          size: UIConstants.iconSizeSmall,
                          color: porcentajeMerma > 10 ? Colors.orange : Colors.green,
                        ),
                        SizedBox(width: UIConstants.spacing8),
                        Expanded(
                          child: Text(
                            'Merma: ${merma.toStringAsFixed(2)} kg (${porcentajeMerma.toStringAsFixed(1)}%)',
                            style: TextStyle(
                              fontSize: UIConstants.fontSizeSmall,
                              fontWeight: FontWeight.w600,
                              color: porcentajeMerma > 10 ? Colors.orange[700] : Colors.green[700],
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
        }).toList(),
        
        // Resumen de totales
        _buildResumenTotales(),
      ],
    );
  }
  
  Widget _buildResumenTotales() {
    final pesoNetoTotal = _calcularPesoNetoTotal();
    final mermaTotal = _calcularMermaTotal();
    final porcentajeMerma = _calcularPorcentajeMerma();
    
    return Container(
      margin: EdgeInsets.only(top: UIConstants.spacing8),
      padding: EdgeInsets.all(UIConstants.spacing16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _primaryColor.withOpacity(0.05),
            _primaryColor.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadiusConstants.borderRadiusMedium,
        border: Border.all(
          color: _primaryColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RESUMEN DE TOTALES',
            style: TextStyle(
              fontSize: UIConstants.fontSizeMedium,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: UIConstants.spacing12),
          
          // Peso bruto total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Peso bruto total:',
                style: TextStyle(fontSize: UIConstants.fontSizeMedium),
              ),
              Text(
                '${_pesoTotalOriginal.toStringAsFixed(2)} kg',
                style: const TextStyle(
                  fontSize: UIConstants.fontSizeMedium,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          SizedBox(height: UIConstants.spacing8),
          
          // Peso neto total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Peso neto total:',
                style: TextStyle(fontSize: UIConstants.fontSizeMedium),
              ),
              Text(
                '${pesoNetoTotal.toStringAsFixed(2)} kg',
                style: TextStyle(
                  fontSize: UIConstants.fontSizeMedium,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          
          SizedBox(height: UIConstants.spacing8),
          
          // Merma total
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: UIConstants.spacing12,
              vertical: UIConstants.spacing8,
            ),
            decoration: BoxDecoration(
              color: porcentajeMerma > 10 
                ? Colors.orange.withOpacity(0.1)
                : Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadiusConstants.borderRadiusSmall,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      porcentajeMerma > 10 ? Icons.warning : Icons.info,
                      size: UIConstants.iconSizeSmall,
                      color: porcentajeMerma > 10 ? Colors.orange : Colors.blue,
                    ),
                    SizedBox(width: UIConstants.spacing8),
                    const Text(
                      'Merma total:',
                      style: TextStyle(fontSize: UIConstants.fontSizeMedium),
                    ),
                  ],
                ),
                Text(
                  '${mermaTotal.toStringAsFixed(2)} kg (${porcentajeMerma.toStringAsFixed(1)}%)',
                  style: TextStyle(
                    fontSize: UIConstants.fontSizeMedium,
                    fontWeight: FontWeight.bold,
                    color: porcentajeMerma > 10 ? Colors.orange[700] : Colors.blue[700],
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _primaryColor,
        elevation: UIConstants.elevationNone,
        title: Text(
          _esProcesamientoMultiple 
            ? 'Procesamiento de ${_loteIds.length} Lotes' 
            : 'Formulario de Salida',
          style: TextStyle(
            fontSize: UIConstants.fontSizeLarge,
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
              padding: EdgeInsetsConstants.paddingAll20,
              children: [
            // Sección de información del lote
            Container(
              width: double.infinity,
              padding: EdgeInsetsConstants.paddingAll20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadiusConstants.borderRadiusMedium,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: UIConstants.opacityLow),
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
                      Icon(
                        Icons.inventory_2,
                        color: _primaryColor,
                        size: UIConstants.iconSizeMedium,
                      ),
                      SizedBox(width: UIConstants.spacing12),
                      Text(
                        'Información del Lote',
                        style: TextStyle(
                          fontSize: UIConstants.fontSizeBody + 2,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: UIConstants.spacing20),
                  Container(
                  padding: EdgeInsetsConstants.paddingAll12,
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadiusConstants.borderRadiusMedium,
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
                            size: UIConstants.iconSizeMedium - 4,
                          ),
                          SizedBox(width: UIConstants.spacing8),
                          Expanded(
                            child: Text(
                              _esProcesamientoMultiple 
                                ? 'Procesando ${_loteIds.length} lotes/sublotes'
                                : 'Lote: ${_loteIds.isNotEmpty ? _loteIds.first : ""}',
                              style: TextStyle(
                                fontSize: UIConstants.fontSizeMedium,
                                fontWeight: FontWeight.bold,
                                color: _primaryColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: UIConstants.spacing8),
                      if (_esProcesamientoMultiple) ...[
                        Text(
                          'Peso total: ${_pesoTotalOriginal.toStringAsFixed(2)} kg',
                          style: TextStyle(
                            fontSize: UIConstants.fontSizeSmall + 1,
                            color: Colors.grey[700],
                          ),
                        ),
                        if (_loteIds.isNotEmpty)
                          Text(
                            'Lotes seleccionados:',
                            style: TextStyle(
                              fontSize: UIConstants.fontSizeSmall + 1,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ..._loteIds.take(3).map((id) => Text(
                          '• ${id.substring(0, id.length > 8 ? 8 : id.length)}...',
                          style: TextStyle(
                            fontSize: UIConstants.fontSizeSmall,
                            color: Colors.grey[600],
                          ),
                        )).toList(),
                        if (_loteIds.length > 3)
                          Text(
                            '• y ${_loteIds.length - 3} más...',
                            style: TextStyle(
                              fontSize: UIConstants.fontSizeSmall,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ] else ...[
                        if (widget.productoFabricado != null)
                          Text(
                            'Producto: ${widget.productoFabricado}',
                            style: TextStyle(
                              fontSize: UIConstants.fontSizeSmall + 1,
                              color: Colors.grey[700],
                            ),
                          ),
                        Text(
                          'Peso inicial: ${widget.peso ?? _pesoTotalOriginal} kg',
                          style: TextStyle(
                            fontSize: UIConstants.fontSizeSmall + 1,
                            color: Colors.grey[700],
                          ),
                        ),
                        if (widget.tipoPolimero != null)
                          Text(
                            'Polímero: ${widget.tipoPolimero}',
                            style: TextStyle(
                              fontSize: UIConstants.fontSizeSmall + 1,
                              color: Colors.grey[700],
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                ],
              ),
            ),
            
            SizedBox(height: UIConstants.spacing20),
            
            // Sección de peso de salida
            Container(
              width: double.infinity,
              padding: EdgeInsetsConstants.paddingAll20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadiusConstants.borderRadiusMedium,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: UIConstants.opacityLow),
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
                      Icon(
                        Icons.scale,
                        color: _primaryColor,
                        size: UIConstants.iconSizeMedium,
                      ),
                      SizedBox(width: UIConstants.spacing12),
                      Text(
                        'Peso de Salida',
                        style: TextStyle(
                          fontSize: UIConstants.fontSizeBody + 2,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: UIConstants.spacing20),
                  
                  // Sección de peso - Individual o múltiple
                  if (_esProcesamientoMultiple) ...[
                    _buildSeccionPesoMultiple(),
                  ] else ...[
                    const FieldLabel(
                      text: 'Peso de salida (kg)',
                      isRequired: true,
                    ),
                    SizedBox(height: UIConstants.spacing8),
                    WeightInputWidget(
                      controller: _pesoSalidaController,
                      label: '',
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
            ),
            
            SizedBox(height: UIConstants.spacing20),
            
            // Sección de procesos aplicados
            Container(
              width: double.infinity,
              padding: EdgeInsetsConstants.paddingAll20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadiusConstants.borderRadiusMedium,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: UIConstants.opacityLow),
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
                      Icon(
                        Icons.science,
                        color: _primaryColor,
                        size: UIConstants.iconSizeMedium,
                      ),
                      SizedBox(width: UIConstants.spacing12),
                      Text(
                        'Procesos Aplicados *',
                        style: TextStyle(
                          fontSize: UIConstants.fontSizeBody + 2,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: UIConstants.spacing20),
                  _buildProcesosAplicadosGrid(),
                ],
              ),
            ),
            
            SizedBox(height: UIConstants.spacing20),
            
            // Sección de producto generado (combinada)
            Container(
              width: double.infinity,
              padding: EdgeInsetsConstants.paddingAll20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadiusConstants.borderRadiusMedium,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: UIConstants.opacityLow),
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
                      Icon(
                        Icons.precision_manufacturing,
                        color: _primaryColor,
                        size: UIConstants.iconSizeMedium,
                      ),
                      SizedBox(width: UIConstants.spacing12),
                      Text(
                        'Producto Generado',
                        style: TextStyle(
                          fontSize: UIConstants.fontSizeBody + 2,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: UIConstants.spacing20),
                  
                  // Campo de producto fabricado
                  const FieldLabel(
                    text: 'Producto fabricado',
                    isRequired: true,
                  ),
                  SizedBox(height: UIConstants.spacing8),
                  TextFormField(
                    controller: _productoGeneradoController,
                    focusNode: _productoFocus,
                    maxLength: 50,
                    decoration: InputDecoration(
                      hintText: 'Ej: Pellets de PET',
                      counter: Text(
                        '${_productoGeneradoController.text.length}/50',
                        style: TextStyle(fontSize: UIConstants.fontSizeSmall + 1),
                      ),
                      prefixIcon: Icon(
                        Icons.inventory_2,
                        color: _primaryColor,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadiusConstants.borderRadiusMedium,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadiusConstants.borderRadiusMedium,
                        borderSide: BorderSide(
                          color: Colors.grey[300]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadiusConstants.borderRadiusMedium,
                        borderSide: BorderSide(
                          color: _primaryColor,
                          width: UIConstants.strokeWidth,
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
                  
                  SizedBox(height: UIConstants.spacing16),
                  
                  // Campo de cantidad generada
                  const FieldLabel(
                    text: 'Cantidad generada',
                    isRequired: true,
                  ),
                  SizedBox(height: UIConstants.spacing8),
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
                        borderRadius: BorderRadiusConstants.borderRadiusMedium,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadiusConstants.borderRadiusMedium,
                        borderSide: BorderSide(
                          color: Colors.grey[300]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadiusConstants.borderRadiusMedium,
                        borderSide: BorderSide(
                          color: _primaryColor,
                          width: UIConstants.strokeWidth,
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
            ),
            
            SizedBox(height: UIConstants.spacing20),
            
            // Sección de datos del responsable
            Container(
              width: double.infinity,
              padding: EdgeInsetsConstants.paddingAll20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadiusConstants.borderRadiusMedium,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: UIConstants.opacityLow),
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
                      Icon(
                        Icons.person,
                        color: _primaryColor,
                        size: UIConstants.iconSizeMedium,
                      ),
                      SizedBox(width: UIConstants.spacing12),
                      Text(
                        'Datos del Responsable',
                        style: TextStyle(
                          fontSize: UIConstants.fontSizeBody + 2,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: UIConstants.spacing20),
                  const FieldLabel(
                    text: 'Nombre del operador',
                    isRequired: true,
                  ),
                  SizedBox(height: UIConstants.spacing8),
                TextFormField(
                  controller: _operadorController,
                  focusNode: _operadorFocus,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'Ej: Juan Pérez',
                    prefixIcon: Icon(
                      Icons.person,
                      color: _primaryColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadiusConstants.borderRadiusMedium,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadiusConstants.borderRadiusMedium,
                      borderSide: BorderSide(
                        color: Colors.grey[300]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadiusConstants.borderRadiusMedium,
                      borderSide: BorderSide(
                        color: _primaryColor,
                        width: UIConstants.strokeWidth,
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
                SizedBox(height: UIConstants.spacing20),
                // Botón para firma
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FieldLabel(
                      text: 'Firma del responsable',
                      isRequired: true,
                    ),
                    SizedBox(height: UIConstants.spacing8),
                    GestureDetector(
                      onTap: _signaturePoints.isEmpty ? () => _showSignatureDialog() : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: _signaturePoints.isNotEmpty ? 150 : 100,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: _signaturePoints.isNotEmpty 
                              ? _primaryColor.withValues(alpha: UIConstants.opacityVeryLow)
                              : Colors.grey[50],
                          borderRadius: BorderRadiusConstants.borderRadiusMedium,
                          border: Border.all(
                            color: _signaturePoints.isNotEmpty 
                                ? _primaryColor 
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
                                    SizedBox(height: UIConstants.spacing4),
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
                                        aspectRatio: UIConstants.signatureAspectRatio,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadiusConstants.borderRadiusSmall,
                                            border: Border.all(color: Colors.grey[200]!),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadiusConstants.borderRadiusSmall,
                                            child: FittedBox(
                                              fit: BoxFit.contain,
                                              child: SizedBox(
                                                width: UIConstants.signatureSize,
                                                height: UIConstants.signatureSize,
                                                child: _signatureUrl != null
                                                ? Image.network(
                                                    _signatureUrl!,
                                                    fit: BoxFit.contain,
                                                    loadingBuilder: (context, child, loadingProgress) {
                                                      if (loadingProgress == null) return child;
                                                      return Center(
                                                        child: CircularProgressIndicator(
                                                          value: loadingProgress.expectedTotalBytes != null
                                                              ? loadingProgress.cumulativeBytesLoaded /
                                                                  loadingProgress.expectedTotalBytes!
                                                              : null,
                                                          color: _primaryColor,
                                                        ),
                                                      );
                                                    },
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Center(
                                                        child: Column(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            Icon(
                                                              Icons.error_outline,
                                                              color: Colors.red[300],
                                                              size: UIConstants.iconSizeLarge - 2,
                                                            ),
                                                            SizedBox(height: UIConstants.spacing4),
                                                            Text(
                                                              'Error al cargar',
                                                              style: TextStyle(
                                                                fontSize: UIConstants.fontSizeSmall + 1,
                                                                color: Colors.red[300],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  )
                                                : CustomPaint(
                                                    size: Size(UIConstants.signatureSize, UIConstants.signatureSize / UIConstants.signatureAspectRatio),
                                                    painter: TransformadorSignaturePainter(
                                                      points: _signaturePoints,
                                                      color: _primaryColor,
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
                                            onPressed: _showSignatureDialog,
                                            icon: Icon(Icons.edit, size: UIConstants.iconSizeMedium - 4),
                                            color: _primaryColor,
                                            padding: EdgeInsets.all(UIConstants.spacing8),
                                            constraints: const BoxConstraints(
                                              minWidth: UIConstants.iconSizeLarge + UIConstants.spacing12,
                                              minHeight: UIConstants.iconSizeLarge + UIConstants.spacing12,
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
                ],
              ),
            ),
            
            SizedBox(height: UIConstants.spacing20),
            
            // Sección de evidencia fotográfica
            Container(
              width: double.infinity,
              padding: EdgeInsetsConstants.paddingAll20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadiusConstants.borderRadiusMedium,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: UIConstants.opacityLow),
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
                      Icon(
                        Icons.camera_alt,
                        color: _primaryColor,
                        size: UIConstants.iconSizeMedium,
                      ),
                      SizedBox(width: UIConstants.spacing12),
                      Text(
                        'Evidencia Fotográfica',
                        style: TextStyle(
                          fontSize: UIConstants.fontSizeBody + 2,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: UIConstants.spacing20),
                  PhotoEvidenceWidget(
                    title: '', // Empty title since we already have it
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
            ),
            
            SizedBox(height: UIConstants.spacing20),
            
            // Sección de comentarios
            Container(
              width: double.infinity,
              padding: EdgeInsetsConstants.paddingAll20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadiusConstants.borderRadiusMedium,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: UIConstants.opacityLow),
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
                      Icon(
                        Icons.comment,
                        color: _primaryColor,
                        size: UIConstants.iconSizeMedium,
                      ),
                      SizedBox(width: UIConstants.spacing12),
                      Text(
                        'Comentarios',
                        style: TextStyle(
                          fontSize: UIConstants.fontSizeBody + 2,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: UIConstants.spacing20),
                  const FieldLabel(
                    text: 'Comentarios adicionales',
                    isRequired: false,
                  ),
                  SizedBox(height: UIConstants.spacing8),
                  TextFormField(
                  controller: _comentariosController,
                  focusNode: _comentariosFocus,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Ingrese observaciones adicionales',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadiusConstants.borderRadiusMedium,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadiusConstants.borderRadiusMedium,
                      borderSide: BorderSide(
                        color: Colors.grey[300]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadiusConstants.borderRadiusMedium,
                      borderSide: BorderSide(
                        color: _primaryColor,
                        width: UIConstants.strokeWidth,
                      ),
                    ),
                  ),
                  onChanged: (_) => _markAsUnsaved(),
                ),
                ],
              ),
            ),
            
            SizedBox(height: UIConstants.spacing32),
            
            // Botón de procesar salida
            SizedBox(
              height: UIConstants.buttonHeightLarge,
              child: ElevatedButton(
                onPressed: _procesarSalida,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusConstants.borderRadiusMedium,
                  ),
                  elevation: UIConstants.elevationSmall,
                ),
                child: const Text(
                  'Procesar Salida',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: UIConstants.fontSizeBody,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            SizedBox(height: UIConstants.spacing32),
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