import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import '../../../utils/colors.dart';
import '../../../services/lote_service.dart';
import '../../../services/lote_unificado_service.dart';
import '../../../services/user_session_service.dart';
import '../../../services/firebase/firebase_storage_service.dart';
import '../../../services/firebase/firebase_manager.dart';
import '../../../services/transformacion_service.dart';
import '../../../models/lotes/lote_unificado_model.dart';
import '../shared/utils/dialog_utils.dart';
import 'reciclador_documentacion.dart';
import '../shared/widgets/photo_evidence_widget.dart';
import '../shared/widgets/weight_input_widget.dart';
import '../shared/widgets/signature_dialog.dart';
import '../shared/widgets/signature_painter.dart';

class RecicladorFormularioSalida extends StatefulWidget {
  final String? loteId; // Para compatibilidad con lote individual
  final double? pesoOriginal; // Peso registrado en la entrada
  final List<String>? lotesIds; // Para procesamiento múltiple

  const RecicladorFormularioSalida({
    super.key,
    this.loteId,
    this.pesoOriginal,
    this.lotesIds,
  }) : assert(
         (loteId != null && pesoOriginal != null) || lotesIds != null,
         'Debe proporcionar loteId y pesoOriginal o lotesIds',
       );

  @override
  State<RecicladorFormularioSalida> createState() => _RecicladorFormularioSalidaState();
}

class _RecicladorFormularioSalidaState extends State<RecicladorFormularioSalida> {
  final _formKey = GlobalKey<FormState>();
  final LoteService _loteService = LoteService();
  final LoteUnificadoService _loteUnificadoService = LoteUnificadoService();
  final TransformacionService _transformacionService = TransformacionService();
  final UserSessionService _userSession = UserSessionService();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  
  // Controladores
  final TextEditingController _pesoResultanteController = TextEditingController();
  final TextEditingController _operadorController = TextEditingController();
  final TextEditingController _comentariosController = TextEditingController();
  
  // Variables para cálculos
  double _mermaCalculada = 0.0;
  double _pesoNetoAprovechable = 0.0;
  double _pesoTotalOriginal = 0.0; // Para múltiples lotes
  
  // Estados
  bool _isMultipleLotes = false;
  List<LoteUnificadoModel> _lotesParaProcesar = [];
  bool _isLoading = false;
  
  // Variables para procesos aplicados
  final Map<String, bool> _procesosAplicados = {
    'Lavado': false,
    'Triturado': false,
    'Compactado': false,
    'Formulado': false,
    'Pelletizado': true, // Seleccionado por defecto
  };
  
  // Variables para la firma
  List<Offset?> _signaturePoints = [];
  bool _hasSignature = false;
  String? _signatureUrl;
  
  // Variables para las imágenes
  bool _hasImages = false;
  List<File> _photoFiles = [];
  List<String> _existingPhotoUrls = []; // URLs de fotos ya guardadas
  
  // Variables para tipo de polímero y presentación
  String? _tipoPoliSalida;
  String? _presentacionSalida;

  @override
  void initState() {
    super.initState();
    _isMultipleLotes = widget.lotesIds != null && widget.lotesIds!.length > 1;
    _pesoResultanteController.addListener(_calcularMerma);
    _initializeUserAndLoadData();
  }
  
  Future<void> _initializeUserAndLoadData() async {
    try {
      // Verificar autenticación
      print('[RecicladorFormularioSalida] Verificando autenticación...');
      
      // Primero intentar obtener el perfil del usuario
      final userProfile = await _userSession.getCurrentUserProfile();
      if (userProfile == null) {
        print('[RecicladorFormularioSalida] No se pudo obtener el perfil del usuario');
        if (!mounted) return;
        
        DialogUtils.showErrorDialog(
          context: context,
          title: 'Error de Sesión',
          message: 'No se pudo cargar tu perfil. Por favor cierra sesión y vuelve a iniciar.',
        ).then((_) {
          Navigator.of(context).pushNamedAndRemoveUntil('/ecoce_login', (route) => false);
        });
        return;
      }
      
      // Initialize operator
      final userData = _userSession.getUserData();
      print('[RecicladorFormularioSalida] Usuario cargado: ${userData?['nombre']} (${userData?['uid']})');
      _operadorController.text = userData?['nombre'] ?? '';
      
      // Cargar datos del lote
      await _loadLoteData();
    } catch (e) {
      print('[RecicladorFormularioSalida] Error al inicializar: $e');
      if (!mounted) return;
      
      DialogUtils.showErrorDialog(
        context: context,
        title: 'Error',
        message: 'Error al cargar los datos: ${e.toString()}',
      );
    }
  }
  
  Future<void> _loadLoteData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      if (widget.lotesIds != null && widget.lotesIds!.isNotEmpty) {
        // Cargar múltiples lotes (incluso si es solo uno)
        double pesoTotal = 0;
        _lotesParaProcesar.clear();
        
        for (final loteId in widget.lotesIds!) {
          final lote = await _loteUnificadoService.obtenerLotePorId(loteId);
          if (lote != null && lote.puedeSerTransformado) {
            _lotesParaProcesar.add(lote);
            // Usar el peso actual del lote que ya considera las muestras de laboratorio
            pesoTotal += lote.pesoActual;
            
            print('Lote $loteId - Peso actual: ${lote.pesoActual} kg');
          }
        }
        
        print('Peso total calculado: $pesoTotal kg');
        print('Número de lotes a procesar: ${_lotesParaProcesar.length}');
        
        setState(() {
          _pesoTotalOriginal = pesoTotal;
          _pesoNetoAprovechable = pesoTotal;
          _isMultipleLotes = widget.lotesIds!.length > 1;
          print('Peso neto aprovechable asignado: $_pesoNetoAprovechable kg');
        });
      } else if (widget.loteId != null) {
        // Cargar lote individual
        final lote = await _loteUnificadoService.obtenerLotePorId(widget.loteId!);
        
        if (lote == null) {
          print('Lote no encontrado');
          setState(() {
            _pesoTotalOriginal = widget.pesoOriginal ?? 0.0;
            _pesoNetoAprovechable = widget.pesoOriginal ?? 0.0;
            _isLoading = false;
          });
          return;
        }
        
        // Agregar el lote a la lista para procesamiento
        if (lote.puedeSerTransformado) {
          _lotesParaProcesar.add(lote);
        }
        
        // Usar el peso actual del lote que ya considera las muestras de laboratorio
        setState(() {
          _pesoTotalOriginal = lote.pesoActual;
          _pesoNetoAprovechable = lote.pesoActual;
        });
      
      // Para los datos específicos del formulario de salida, necesitamos consultarlos directamente
      // porque el modelo no incluye todos los campos
      final firebaseManager = FirebaseManager();
      final app = firebaseManager.currentApp;
      final firestore = app != null 
          ? FirebaseFirestore.instanceFor(app: app)
          : FirebaseFirestore.instance;
      
      final recicladorDoc = await firestore
          .collection('lotes')
          .doc(widget.loteId)
          .collection('reciclador')
          .doc('data')
          .get();
      
      if (recicladorDoc.exists) {
        print('[FORMULARIO_SALIDA] Documento reciclador existe');
        final rawData = recicladorDoc.data();
        print('[FORMULARIO_SALIDA] Tipo de rawData: ${rawData?.runtimeType}');
        
        if (rawData != null) {
          print('[FORMULARIO_SALIDA] rawData no es null, intentando convertir');
          
          // Validar que rawData sea un Map antes de convertir
          if (rawData is! Map) {
            print('[FORMULARIO_SALIDA] ERROR: rawData no es Map, es: ${rawData.runtimeType}');
            print('[FORMULARIO_SALIDA] Contenido de rawData: $rawData');
            throw Exception('Datos del reciclador no son válidos: se esperaba Map pero se recibió ${rawData.runtimeType}');
          }
          
          // Asegurar que data es un Map<String, dynamic>
          final Map<String, dynamic> data = Map<String, dynamic>.from(rawData);
          print('[FORMULARIO_SALIDA] Conversión exitosa a Map<String, dynamic>');
          
          setState(() {
          // NO sobrescribir el peso neto aprovechable si ya fue calculado desde pesoActual
          // Solo usar este valor si no tenemos un peso calculado
          if (_pesoNetoAprovechable == 0) {
            final pesoNeto = data['peso_neto'];
            final pesoEntrada = data['peso_entrada'];
            final pesoOriginal = widget.pesoOriginal;
            
            // Manejar diferentes tipos de datos (int o double)
            if (pesoNeto != null) {
              _pesoNetoAprovechable = pesoNeto is int ? pesoNeto.toDouble() : (pesoNeto as double);
            } else if (pesoEntrada != null) {
              _pesoNetoAprovechable = pesoEntrada is int ? pesoEntrada.toDouble() : (pesoEntrada as double);
            } else if (pesoOriginal != null) {
              _pesoNetoAprovechable = pesoOriginal;
            }
          }
          
          // Cargar datos de salida guardados previamente
          if (data['peso_neto_salida'] != null) {
            final pesoSalida = data['peso_neto_salida'];
            final pesoDouble = pesoSalida is int ? pesoSalida.toDouble() : (pesoSalida as double);
            if (pesoDouble > 0) {
              _pesoResultanteController.text = pesoDouble.toString();
            }
          }
          
          // Cargar operador de salida si existe
          if (data['operador_salida_nombre'] != null && data['operador_salida_nombre'].isNotEmpty) {
            _operadorController.text = data['operador_salida_nombre'];
          }
          
          // Cargar procesos aplicados
          if (data['procesos_aplicados'] != null && data['procesos_aplicados'] is List) {
            // Solo sobrescribir si hay datos guardados
            final procesosGuardados = data['procesos_aplicados'] as List;
            if (procesosGuardados.isNotEmpty) {
              // Limpiar todas las selecciones antes de cargar las guardadas
              _procesosAplicados.forEach((key, value) {
                _procesosAplicados[key] = false;
              });
              // Cargar los procesos guardados
              for (String proceso in procesosGuardados) {
                if (_procesosAplicados.containsKey(proceso)) {
                  _procesosAplicados[proceso] = true;
                }
              }
            }
            // Si no hay procesos guardados, mantener Pelletizado seleccionado por defecto
          }
          
          // Cargar tipo de polímero seleccionado
          if (data['tipo_poli_salida'] != null && data['tipo_poli_salida'].isNotEmpty) {
            _tipoPoliSalida = data['tipo_poli_salida'];
          }
          
          // Cargar presentación seleccionada
          if (data['presentacion_salida'] != null && data['presentacion_salida'].isNotEmpty) {
            _presentacionSalida = data['presentacion_salida'];
          }
          
          // Cargar observaciones
          if (data['comentarios_salida'] != null && data['comentarios_salida'].isNotEmpty) {
            _comentariosController.text = data['comentarios_salida'];
          }
          
          // Cargar firma si existe
          if (data['firma_salida'] != null && data['firma_salida'].isNotEmpty) {
            _hasSignature = true;
            _signatureUrl = data['firma_salida'];
          }
          
          // Cargar fotos guardadas
          if (data['evidencias_foto_salida'] != null && 
              data['evidencias_foto_salida'] is List && 
              (data['evidencias_foto_salida'] as List).isNotEmpty) {
            _hasImages = true;
            _existingPhotoUrls = List<String>.from(data['evidencias_foto_salida']);
          }
          });
        }
      } else {
        // Si no existe el documento y no tenemos peso calculado, usar el peso original
        setState(() {
          if (_pesoNetoAprovechable == 0) {
            _pesoNetoAprovechable = widget.pesoOriginal ?? 0.0;
          }
        });
      }
    }
    } catch (e) {
      print('Error al cargar datos del lote unificado: $e');
      // Fallback al peso original
      setState(() {
        _pesoNetoAprovechable = widget.pesoOriginal ?? 0.0;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  

  @override
  void dispose() {
    _pesoResultanteController.removeListener(_calcularMerma);
    _pesoResultanteController.dispose();
    _operadorController.dispose();
    _comentariosController.dispose();
    super.dispose();
  }

  void _calcularMerma() {
    final pesoResultante = double.tryParse(_pesoResultanteController.text) ?? 0.0;
    setState(() {
      _mermaCalculada = _pesoNetoAprovechable - pesoResultante;
    });
  }
  
  Color _getMaterialColor(String material) {
    switch (material) {
      case 'PEBD':
        return BioWayColors.pebdPink;
      case 'PP':
        return BioWayColors.ppPurple;
      case 'Multilaminado':
        return BioWayColors.multilaminadoBrown;
      default:
        return BioWayColors.ecoceGreen;
    }
  }

  void _showSignatureDialog() async {
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
          _signaturePoints = points;
          _hasSignature = points.isNotEmpty;
        });
      },
      primaryColor: BioWayColors.ecoceGreen,
    );
  }


  void _onPhotosChanged(List<File> photos) {
    setState(() {
      _photoFiles = photos;
      _hasImages = photos.isNotEmpty;
    });
  }

  // Guardar formulario (parcial o completo)
  Future<void> _guardarFormulario({bool esGuardadoParcial = false}) async {
    // Para guardado parcial, no validar campos obligatorios
    if (!esGuardadoParcial && !_formKey.currentState!.validate()) {
      return;
    }
    
    // Para guardado completo, validar campos requeridos
    if (!esGuardadoParcial) {
      // Validar que al menos un proceso esté seleccionado
      if (!_procesosAplicados.values.any((selected) => selected)) {
        _showErrorSnackBar('Por favor, seleccione al menos un proceso aplicado');
        return;
      }
      
      if (!_hasSignature) {
        _showErrorSnackBar('Por favor, agregue su firma');
        return;
      }
      
      if (!_hasImages) {
        _showErrorSnackBar('Por favor, agregue al menos una evidencia fotográfica');
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Importar el servicio unificado
      final loteUnificadoService = LoteUnificadoService();
      
      // Preparar datos para actualizar
      Map<String, dynamic> datosActualizacion = {};
      
      // Obtener procesos seleccionados ANTES de usarlos
      List<String> procesosSeleccionados = [];
      _procesosAplicados.forEach((proceso, seleccionado) {
        if (seleccionado) {
          procesosSeleccionados.add(proceso);
        }
      });
      
      // Solo subir firma si existe y no ha sido subida antes
      if (_hasSignature && _signatureUrl == null && _signaturePoints.isNotEmpty) {
        final signatureImage = await _captureSignature();
        if (signatureImage != null) {
          _signatureUrl = await _storageService.uploadImage(
            signatureImage,
            'lotes/reciclador/firmas_salida',
          );
        }
      }
      if (_signatureUrl != null) {
        datosActualizacion['firma_salida'] = _signatureUrl;
      }

      // Solo subir nuevas fotos
      List<String> photoUrls = [];
      if (_hasImages) {
        for (int i = 0; i < _photoFiles.length; i++) {
          final url = await _storageService.uploadImage(
            _photoFiles[i],
            'lotes/reciclador/evidencias_salida',
          );
          if (url != null) {
            photoUrls.add(url);
          }
        }
      }
      if (photoUrls.isNotEmpty) {
        datosActualizacion['evidencias_foto_salida'] = photoUrls;
      }

      // Agregar procesos aplicados
      if (procesosSeleccionados.isNotEmpty) {
        datosActualizacion['procesos_aplicados'] = procesosSeleccionados;
      }

      // Agregar datos del formulario
      if (_pesoResultanteController.text.isNotEmpty) {
        final pesoResultante = double.tryParse(_pesoResultanteController.text) ?? 0.0;
        datosActualizacion['peso_neto_salida'] = pesoResultante;
        datosActualizacion['peso_procesado'] = pesoResultante; // Campo esperado por el modelo
        datosActualizacion['merma'] = _mermaCalculada;
        datosActualizacion['merma_proceso'] = _mermaCalculada; // Campo esperado por el modelo
      }
      
      if (_operadorController.text.isNotEmpty) {
        datosActualizacion['operador_salida_nombre'] = _operadorController.text.trim();
      }
      
      if (_comentariosController.text.isNotEmpty) {
        datosActualizacion['comentarios_salida'] = _comentariosController.text.trim();
      }

      // Guardar tipo de polímero y presentación si están seleccionados
      if (_tipoPoliSalida != null) {
        datosActualizacion['tipo_poli_salida'] = _tipoPoliSalida;
      } else if (!esGuardadoParcial) {
        // Solo requerir si es guardado completo
        datosActualizacion['tipo_poli_salida'] = 'Mixto';
      }
      
      if (_presentacionSalida != null) {
        datosActualizacion['presentacion_salida'] = _presentacionSalida;
      } else if (!esGuardadoParcial) {
        // Solo requerir si es guardado completo
        datosActualizacion['presentacion_salida'] = 'Pacas';
      }

      // Si es guardado completo, agregar fecha de salida
      if (!esGuardadoParcial) {
        datosActualizacion['fecha_salida'] = FieldValue.serverTimestamp();
      }

      // SIEMPRE crear transformación (megalote) - incluso para lotes individuales
      if (!esGuardadoParcial) {
        // Asegurar que tenemos los lotes a procesar
        if (_lotesParaProcesar.isEmpty) {
          // Si no se cargaron los lotes, intentar cargarlos
          final lotesIds = widget.lotesIds ?? (widget.loteId != null ? [widget.loteId!] : []);
          
          for (final loteId in lotesIds) {
            final lote = await _loteUnificadoService.obtenerLotePorId(loteId);
            if (lote != null && lote.puedeSerTransformado) {
              _lotesParaProcesar.add(lote);
            }
          }
        }
        
        // Verificar que tenemos lotes para procesar
        if (_lotesParaProcesar.isEmpty) {
          throw Exception('No hay lotes válidos para procesar');
        }
        
        // Verificar autenticación antes de crear transformación
        print('[RecicladorFormularioSalida] Verificando autenticación antes de crear transformación...');
        final currentProfile = await _userSession.getCurrentUserProfile();
        if (currentProfile == null) {
          print('[RecicladorFormularioSalida] ERROR: No hay perfil de usuario');
          throw Exception('Sesión expirada. Por favor cierra sesión y vuelve a iniciar.');
        }
        
        final userData = _userSession.getUserData();
        if (userData == null || userData['uid'] == null) {
          print('[RecicladorFormularioSalida] ERROR: No hay datos de usuario o UID');
          throw Exception('Datos de usuario incompletos. Por favor cierra sesión y vuelve a iniciar.');
        }
        
        print('[RecicladorFormularioSalida] Usuario autenticado correctamente: ${userData['uid']}');
        
        // Crear transformación con los lotes (uno o varios)
        final transformacionId = await _transformacionService.crearTransformacion(
          lotes: _lotesParaProcesar,
          mermaProceso: _mermaCalculada,
          procesoAplicado: procesosSeleccionados.isNotEmpty ? procesosSeleccionados.join(', ') : null,
          observaciones: _comentariosController.text.trim().isNotEmpty ? _comentariosController.text.trim() : null,
        );
        
        // NO actualizar los lotes individuales cuando se crea una transformación
        // Los lotes originales se marcan como consumidos en el TransformacionService
        // y no deben aparecer como completados
      } else {
        // Solo actualizar datos sin crear transformación (guardado parcial)
        final lotesIds = widget.lotesIds ?? (widget.loteId != null ? [widget.loteId!] : []);
        
        for (final loteId in lotesIds) {
          await _loteUnificadoService.actualizarDatosProceso(
            loteId: loteId,
            proceso: 'reciclador',
            datos: datosActualizacion,
          );
        }
      }

      if (mounted) {
        if (esGuardadoParcial) {
          DialogUtils.showSuccessDialog(
            context: context,
            title: 'Guardado',
            message: 'Los cambios se han guardado correctamente',
            onPressed: () {
              Navigator.pop(context);
            },
          );
        } else {
          // Navegar sin mostrar diálogo de éxito
          Navigator.of(context).popUntil((route) => route.isFirst);
          Navigator.pushReplacementNamed(context, '/reciclador_lotes', arguments: {'initialTab': 1});
        }
      }
    } catch (e) {
        if (mounted) {
          DialogUtils.showErrorDialog(
            context: context,
            title: 'Error',
            message: 'No se pudo registrar la salida: ${e.toString()}',
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: BioWayColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // Método comentado - ya no se usa
  // void _showSuccessAndNavigate() {
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(20),
  //         ),
  //         content: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             Icon(
  //               Icons.check_circle,
  //               color: BioWayColors.success,
  //               size: 80,
  //             ),
  //             const SizedBox(height: 20),
  //             const Text(
  //               'Formulario Completado',
  //               style: TextStyle(
  //                 fontSize: 20,
  //                 fontWeight: FontWeight.bold,
  //               ),
  //             ),
  //             const SizedBox(height: 10),
  //             Text(
  //               'Se ha creado una transformación (megalote) con ${_lotesParaProcesar.length} ${_lotesParaProcesar.length == 1 ? "lote" : "lotes"}.\n\nLos lotes han sido procesados y marcados como consumidos.\n\nAhora debe cargar la documentación requerida.',
  //               textAlign: TextAlign.center,
  //               style: TextStyle(
  //                 fontSize: 16,
  //                 color: BioWayColors.textGrey,
  //               ),
  //             ),
  //           ],
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop(); // Cerrar el diálogo
  //               // Todos los casos van a la pantalla de lotes, pestaña completados
  //               Navigator.of(context).popUntil((route) => route.isFirst);
  //               Navigator.pushReplacementNamed(context, '/reciclador_lotes');
  //             },
  //             child: Text(
  //               'Continuar',
  //               style: TextStyle(
  //                 color: BioWayColors.ecoceGreen,
  //                 fontWeight: FontWeight.bold,
  //                 fontSize: 16,
  //               ),
  //             ),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BioWayColors.backgroundGrey,
      appBar: AppBar(
        backgroundColor: BioWayColors.ecoceGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Text(
          _isMultipleLotes 
            ? 'Procesar ${widget.lotesIds?.length ?? 0} Lotes'
            : 'Formulario de Salida',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Header verde
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: BioWayColors.ecoceGreen,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Registra la salida del material',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _isMultipleLotes
                      ? '${widget.lotesIds?.length ?? 0} lotes seleccionados'
                      : 'Lote ${widget.loteId}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Formulario
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Mostrar lotes seleccionados si es procesamiento múltiple
                    if (_isMultipleLotes && _lotesParaProcesar.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: BioWayColors.ecoceGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: BioWayColors.ecoceGreen.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.merge_type,
                                  color: BioWayColors.ecoceGreen,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Lotes a procesar juntos',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${_lotesParaProcesar.length} lotes seleccionados',
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
                            const SizedBox(height: 12),
                            // Limitar la altura si hay muchos lotes
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: _lotesParaProcesar.length > 5 ? 200 : double.infinity,
                              ),
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: Column(
                                  children: _lotesParaProcesar.map((lote) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.grey.withValues(alpha: 0.2),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: _getMaterialColor(lote.datosGenerales.tipoMaterial),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              'Lote ${lote.id.substring(0, 8).toUpperCase()}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            flex: 3,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  lote.datosGenerales.tipoMaterial,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: _getMaterialColor(lote.datosGenerales.tipoMaterial),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  '${lote.pesoActual.toStringAsFixed(2)} kg',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey[700],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )).toList(),
                                ),
                              ),
                            ),
                            // Mostrar peso total
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: BioWayColors.ecoceGreen.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Peso total a procesar:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${_pesoTotalOriginal.toStringAsFixed(2)} kg',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: BioWayColors.ecoceGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    // Tarjeta de Características del Lote
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
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
                                '📦',
                                style: TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Características del Lote',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: BioWayColors.darkGreen,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          // Peso Resultante
                          WeightInputWidget(
                            controller: _pesoResultanteController,
                            label: 'Peso Resultante',
                            primaryColor: BioWayColors.ecoceGreen,
                            quickAddValues: const [50, 100, 250, 500],
                            isRequired: true,
                            maxValue: _pesoNetoAprovechable > 0 ? _pesoNetoAprovechable : null,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa el peso recibido';
                              }
                              final peso = double.tryParse(value);
                              if (peso == null || peso <= 0) {
                                return 'Ingresa un peso válido';
                              }
                              if (peso > _pesoNetoAprovechable) {
                                return 'El peso no puede ser mayor al peso neto aprovechable ($_pesoNetoAprovechable kg)';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Merma calculada
                          Text(
                            'Merma calculada',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: BioWayColors.textGrey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                            decoration: BoxDecoration(
                              color: _mermaCalculada > 0 
                                  ? Colors.orange.withValues(alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _mermaCalculada > 0
                                    ? Colors.orange.withValues(alpha: 0.3)
                                    : Colors.grey.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_mermaCalculada.toStringAsFixed(3)} kg',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _mermaCalculada > 0 ? Colors.orange : Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Peso neto aprovechable: ${_pesoNetoAprovechable.toStringAsFixed(2)} kg',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Procesos Aplicados
                          Row(
                            children: [
                              Text(
                                'Procesos Aplicados',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: BioWayColors.textGrey,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '*',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: BioWayColors.error,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ..._procesosAplicados.entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _procesosAplicados[entry.key] = !entry.value;
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: entry.value 
                                          ? BioWayColors.ecoceGreen 
                                          : BioWayColors.lightGrey,
                                      width: entry.value ? 2 : 1,
                                    ),
                                    color: entry.value 
                                        ? BioWayColors.ecoceGreen.withValues(alpha: 0.1)
                                        : Colors.transparent,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: entry.value 
                                                ? BioWayColors.ecoceGreen 
                                                : BioWayColors.lightGrey,
                                            width: 2,
                                          ),
                                          color: entry.value 
                                              ? BioWayColors.ecoceGreen 
                                              : Colors.transparent,
                                        ),
                                        child: entry.value
                                            ? const Icon(
                                                Icons.check,
                                                size: 16,
                                                color: Colors.white,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        entry.key,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: entry.value ? FontWeight.w600 : FontWeight.normal,
                                          color: entry.value 
                                              ? BioWayColors.ecoceGreen 
                                              : BioWayColors.textGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Tarjeta de Datos del Responsable
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
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
                                style: TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Datos del Responsable',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: BioWayColors.darkGreen,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          // Nombre del Operador
                          Row(
                            children: [
                              Text(
                                'Nombre del Operador',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: BioWayColors.textGrey,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '*',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: BioWayColors.error,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _operadorController,
                            maxLength: 50,
                            decoration: InputDecoration(
                              hintText: 'Ingresa el nombre completo',
                              filled: true,
                              fillColor: BioWayColors.backgroundGrey,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: BioWayColors.ecoceGreen.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: BioWayColors.ecoceGreen,
                                  width: 2,
                                ),
                              ),
                              counterText: '',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa el nombre del operador';
                              }
                              if (value.length < 3) {
                                return 'El nombre debe tener al menos 3 caracteres';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Firma del Operador
                          Row(
                            children: [
                              Text(
                                'Firma del Operador',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: BioWayColors.textGrey,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '*',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: BioWayColors.error,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _hasSignature ? null : () => _showSignatureDialog(),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: _hasSignature ? 150 : 100,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: _hasSignature 
                                    ? BioWayColors.ecoceGreen.withValues(alpha: 0.05)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _hasSignature 
                                      ? BioWayColors.ecoceGreen 
                                      : Colors.grey[300]!,
                                  width: _hasSignature ? 2 : 1,
                                ),
                              ),
                              child: !_hasSignature
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
                                            'Toca para firmar',
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
                                            child: AspectRatio(
                                              aspectRatio: 2.0,
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
                                                                color: BioWayColors.ecoceGreen,
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
                                                                    size: 30,
                                                                  ),
                                                                  const SizedBox(height: 4),
                                                                  Text(
                                                                    'Error al cargar',
                                                                    style: TextStyle(
                                                                      color: Colors.red[300],
                                                                      fontSize: 10,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                          },
                                                        )
                                                      : FittedBox(
                                                          fit: BoxFit.contain,
                                                          child: SizedBox(
                                                            width: 300,
                                                            height: 300,
                                                            child: CustomPaint(
                                                              painter: SignaturePainter(
                                                                points: _signaturePoints,
                                                                color: BioWayColors.darkGreen,
                                                                strokeWidth: 2.0,
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
                                                      blurRadius: 4,
                                                    ),
                                                  ],
                                                ),
                                                child: IconButton(
                                                  onPressed: () => _showSignatureDialog(),
                                                  icon: Icon(
                                                    Icons.edit,
                                                    color: BioWayColors.ecoceGreen,
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
                                                      color: Colors.black.withValues(alpha: 0.1),
                                                      blurRadius: 4,
                                                    ),
                                                  ],
                                                ),
                                                child: IconButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      _signaturePoints = [];
                                                      _hasSignature = false;
                                                      _signatureUrl = null;
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
                    
                    const SizedBox(height: 20),
                    
                    // Mostrar fotos existentes si las hay
                    if (_existingPhotoUrls.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
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
                                Icon(Icons.photo_library, color: BioWayColors.ecoceGreen),
                                const SizedBox(width: 8),
                                Text(
                                  'Evidencias Guardadas',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: BioWayColors.darkGreen,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _existingPhotoUrls.map((url) {
                                return Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: BioWayColors.ecoceGreen.withValues(alpha: 0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.network(
                                      url,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded /
                                                    loadingProgress.expectedTotalBytes!
                                                : null,
                                            color: BioWayColors.ecoceGreen,
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey[200],
                                          child: Icon(
                                            Icons.broken_image,
                                            color: Colors.grey[400],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    
                    // Tarjeta de Evidencia Fotográfica para agregar nuevas
                    PhotoEvidenceWidget(
                      title: _existingPhotoUrls.isEmpty ? 'Evidencia Fotográfica' : 'Agregar Más Evidencias',
                      maxPhotos: 3 - _existingPhotoUrls.length, // Ajustar el máximo según las existentes
                      minPhotos: _existingPhotoUrls.isEmpty ? 1 : 0,
                      isRequired: _existingPhotoUrls.isEmpty,
                      onPhotosChanged: _onPhotosChanged,
                      primaryColor: BioWayColors.ecoceGreen,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Tarjeta de Comentarios
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
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
                                style: TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Comentarios',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: BioWayColors.darkGreen,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          TextFormField(
                            controller: _comentariosController,
                            maxLength: 150,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'Ingresa comentarios adicionales (opcional)',
                              filled: true,
                              fillColor: BioWayColors.backgroundGrey,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: BioWayColors.ecoceGreen.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: BioWayColors.ecoceGreen,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Botones de acción
                    Row(
                      children: [
                        // Botón guardar parcial
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: OutlinedButton(
                              onPressed: _isLoading ? null : () => _guardarFormulario(esGuardadoParcial: true),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: BioWayColors.ecoceGreen,
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              child: Text(
                                'Guardar Cambios',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: BioWayColors.ecoceGreen,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Botón confirmar
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : () => _guardarFormulario(esGuardadoParcial: false),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: BioWayColors.ecoceGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                elevation: 3,
                              ),
                              child: const Text(
                                'Siguiente',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
            ], // Close Column children
          ), // Close Column
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  color: BioWayColors.ecoceGreen,
                ),
              ),
            ),
        ],
      ),
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
      print('Error al capturar firma: $e');
      return null;
    }
  }
}

/// Painter personalizado para dibujar la firma
class SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  final Color color;
  final double strokeWidth;

  SignaturePainter({
    required this.points,
    required this.color,
    this.strokeWidth = 2.0,
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
  bool shouldRepaint(SignaturePainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
