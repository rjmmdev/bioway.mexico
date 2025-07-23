import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/colors.dart';
import '../../../services/lote_service.dart';
import '../../../services/user_session_service.dart';
import '../../../services/firebase/firebase_storage_service.dart';
import '../../../models/lotes/lote_reciclador_model.dart';
import '../shared/utils/dialog_utils.dart';
import 'reciclador_documentacion.dart';
import '../shared/widgets/photo_evidence_widget.dart';
import '../shared/widgets/weight_input_widget.dart';
import '../shared/widgets/signature_dialog.dart';

class RecicladorFormularioSalida extends StatefulWidget {
  final String loteId;
  final double pesoOriginal; // Peso registrado en la entrada

  const RecicladorFormularioSalida({
    super.key,
    required this.loteId,
    required this.pesoOriginal,
  });

  @override
  State<RecicladorFormularioSalida> createState() => _RecicladorFormularioSalidaState();
}

class _RecicladorFormularioSalidaState extends State<RecicladorFormularioSalida> {
  final _formKey = GlobalKey<FormState>();
  final LoteService _loteService = LoteService();
  final UserSessionService _userSession = UserSessionService();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  
  // Controladores
  final TextEditingController _pesoResultanteController = TextEditingController();
  final TextEditingController _operadorController = TextEditingController();
  final TextEditingController _comentariosController = TextEditingController();
  
  // Variables para cálculos
  double _mermaCalculada = 0.0;
  double _pesoNetoAprovechable = 0.0;
  
  // Estados
  bool _isLoading = false;
  LoteRecicladorModel? _loteReciclador;
  
  // Variables para procesos aplicados
  final Map<String, bool> _procesosAplicados = {
    'Lavado': false,
    'Triturado': false,
    'Compactado': false,
    'Formulado': false,
    'Pelletizado': false,
  };
  
  // Variables para la firma
  List<Offset?> _signaturePoints = [];
  bool _hasSignature = false;
  String? _signatureUrl;
  
  // Variables para las imágenes
  bool _hasImages = false;
  List<File> _photoFiles = [];

  @override
  void initState() {
    super.initState();
    _pesoResultanteController.addListener(_calcularMerma);
    _loadLoteData();
    _initializeForm();
  }
  
  Future<void> _loadLoteData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Obtener datos del lote de reciclador
      final lotes = await _loteService.getLotesReciclador().first;
      _loteReciclador = lotes.firstWhere((l) => l.id == widget.loteId);
      
      if (_loteReciclador != null) {
        setState(() {
          _pesoNetoAprovechable = _loteReciclador!.pesoNeto ?? _loteReciclador!.pesoBruto ?? 0.0;
        });
      }
    } catch (e) {
      print('Error al cargar lote: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _initializeForm() {
    final userData = _userSession.getUserData();
    _operadorController.text = userData?['nombre'] ?? '';
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

  void _showSignatureDialog() {
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

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
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

      setState(() {
        _isLoading = true;
      });

      try {
        // Subir firma a Storage
        if (_signaturePoints.isNotEmpty) {
          final signatureImage = await _captureSignature();
          if (signatureImage != null) {
            _signatureUrl = await _storageService.uploadImage(
              signatureImage,
              'lotes/reciclador/firmas_salida',
            );
          }
        }

        // Subir fotos a Storage
        List<String> photoUrls = [];
        for (int i = 0; i < _photoFiles.length; i++) {
          final url = await _storageService.uploadImage(
            _photoFiles[i],
            'lotes/reciclador/evidencias_salida',
          );
          if (url != null) {
            photoUrls.add(url);
          }
        }

        // Calcular tipo de polímero predominante
        Map<String, double> tipoPolimeros = {};
        if (_loteReciclador?.conjuntoLotes != null && _loteReciclador!.conjuntoLotes.isNotEmpty) {
          tipoPolimeros = await _loteService.calcularTipoPolimeroPredominante(_loteReciclador!.conjuntoLotes);
        }

        // Actualizar el lote de reciclador
        await _loteService.actualizarLoteReciclador(
          widget.loteId,
          {
            'ecoce_reciclador_procesos_aplicados': _procesosAplicados,
            'ecoce_reciclador_peso_final': double.parse(_pesoResultanteController.text),
            'ecoce_reciclador_merma': _mermaCalculada,
            'ecoce_reciclador_tipo_poli': tipoPolimeros,
            'ecoce_reciclador_sale_operador': _operadorController.text.trim(),
            'ecoce_reciclador_firma_salida': _signatureUrl,
            'ecoce_reciclador_evi_foto_salida': photoUrls,
            'ecoce_reciclador_comentarios_salida': _comentariosController.text.trim(),
            'ecoce_reciclador_fecha_salida': Timestamp.fromDate(DateTime.now()),
            'estado': 'documentacion',
          },
        );

        if (mounted) {
          _showSuccessAndNavigate();
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

  void _showSuccessAndNavigate() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: BioWayColors.success,
                size: 80,
              ),
              const SizedBox(height: 20),
              const Text(
                'Salida Registrada',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Se ha registrado correctamente la salida del lote ${widget.loteId}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: BioWayColors.textGrey,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Navegar a la pantalla de carga de documentación
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Navegando a carga de documentación...'),
                    backgroundColor: BioWayColors.info,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
                // Por ahora volvemos a administración de lotes
                // Navegar a la pantalla de documentación
                Navigator.of(context).pop(); // Cerrar el diálogo
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecicladorDocumentacion(
                      lotId: widget.loteId,
                    ),
                  ),
                );
              },
              child: Text(
                'Continuar',
                style: TextStyle(
                  color: BioWayColors.ecoceGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

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
        title: const Text(
          'Formulario de Salida',
          style: TextStyle(
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
                    'Lote ${widget.loteId}',
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
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa el peso recibido';
                              }
                              final peso = double.tryParse(value);
                              if (peso == null || peso <= 0) {
                                return 'Ingresa un peso válido';
                              }
                              if (peso > widget.pesoOriginal) {
                                return 'El peso no puede ser mayor al original';
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
                                  'Peso neto aprovechable: $_pesoNetoAprovechable kg',
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
                                                  child: FittedBox(
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
                    
                    // Tarjeta de Evidencia Fotográfica usando el widget compartido
                    PhotoEvidenceFormField(
                      title: 'Evidencia Fotográfica',
                      maxPhotos: 5,
                      minPhotos: 1,
                      isRequired: true,
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
                    
                    // Botón de confirmar
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BioWayColors.ecoceGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 3,
                        ),
                        child: const Text(
                          'Confirmar Salida de Material',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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
  bool shouldRepaint(SignaturePainter oldDelegate) => true;
}
