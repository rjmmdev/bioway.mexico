import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import '../../../utils/colors.dart';
import 'origen_config.dart';
import '../shared/widgets/signature_dialog.dart';
import '../shared/widgets/photo_evidence_widget.dart';
import '../shared/widgets/weight_input_widget.dart';
import '../shared/widgets/unified_container.dart';
import '../shared/widgets/form_widgets.dart';
import '../shared/utils/input_decorations.dart';
import 'origen_lote_detalle_screen.dart';
import 'origen_confirmar_lote_screen.dart';
import '../../../models/lotes/lote_unificado_model.dart';
import '../../../services/lote_unificado_service.dart';
import '../../../services/firebase/firebase_storage_service.dart';
import '../../../services/user_session_service.dart';
import '../../../services/firebase/auth_service.dart';
import '../../../services/firebase/ecoce_profile_service.dart';
import '../shared/utils/dialog_utils.dart';
import '../shared/widgets/required_field_label.dart';

class OrigenCrearLoteScreen extends StatefulWidget {
  const OrigenCrearLoteScreen({super.key});

  @override
  State<OrigenCrearLoteScreen> createState() => _OrigenCrearLoteScreenState();
}

class _OrigenCrearLoteScreenState extends State<OrigenCrearLoteScreen> {
  final LoteUnificadoService _loteUnificadoService = LoteUnificadoService();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  final UserSessionService _userSession = UserSessionService();
  final AuthService _authService = AuthService();
  final EcoceProfileService _profileService = EcoceProfileService();
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isLoading = false;
  List<File> _photoFiles = [];
  // Constants
  static const List<String> _tiposPolimeros = [
    'PEBD',
    'PP',
    'Multilaminado'
  ];

  static const List<String> _fuentesMaterial = [
    'Recolectores informales o independientes',
    'Instituciones educativas (escuelas, universidades)',
    'Empresas y comercios (tiendas, oficinas, fábricas)',
    'Hogares y ciudadanos particulares',
    'Organizaciones civiles, ONGs y programas sociales',
    'Campañas, eventos especiales y plataformas digitales de reciclaje',
  ];

  static const List<IconData> _fuenteMaterialIcons = [
    Icons.people_outline, // Recolectores informales o independientes
    Icons.school, // Instituciones educativas
    Icons.business, // Empresas y comercios
    Icons.home, // Hogares y ciudadanos
    Icons.groups, // Organizaciones civiles
    Icons.campaign, // Campañas y eventos
  ];

  final _formKey = GlobalKey<FormState>();

  Color get _primaryColor => OrigenUserConfig.current.color;
  
  // Controladores para los campos de texto
  final TextEditingController _pesoController = TextEditingController();
  final TextEditingController _condicionesController = TextEditingController();
  final TextEditingController _operadorController = TextEditingController();
  final TextEditingController _comentariosController = TextEditingController();
  final TextEditingController _otraPresentacionController = TextEditingController();

  // Variables para los selectores
  String? _tipoPolimeroSeleccionado;
  String _presentacionSeleccionada = 'Pacas';
  String? _fuenteMaterialSeleccionada;
  bool _isPostConsumo = false;
  bool _isPreConsumo = false;

  // Variables para la firma
  List<Offset?> _signaturePoints = [];
  bool _hasSignature = false;
  String? _signatureUrl;
  
  // Variables para las imágenes
  bool _hasImages = false;
  List<String> _photoUrls = [];
  
  // ScrollController para manejar el auto-scroll
  final ScrollController _scrollController = ScrollController();
  
  // FocusNodes para los campos
  final FocusNode _condicionesFocus = FocusNode();
  final FocusNode _operadorFocus = FocusNode();
  final FocusNode _comentariosFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    
    // Listener para el campo de comentarios
    _comentariosFocus.addListener(() {
      if (_comentariosFocus.hasFocus) {
        // Esperar un momento para que el teclado aparezca
        Future.delayed(const Duration(milliseconds: 300), () {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _pesoController.dispose();
    _condicionesController.dispose();
    _operadorController.dispose();
    _comentariosController.dispose();
    _otraPresentacionController.dispose();
    _scrollController.dispose();
    _condicionesFocus.dispose();
    _operadorFocus.dispose();
    _comentariosFocus.dispose();
    super.dispose();
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

  void _onPhotosChanged(List<File> photos) {
    setState(() {
      _hasImages = photos.isNotEmpty;
      _photoFiles = photos;
    });
  }

  // Sección de foto ahora manejada por PhotoEvidenceFormField del módulo shared

  Future<void> _generarLote() async {
    // Validar formulario
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validaciones adicionales
    if (!_isPostConsumo && !_isPreConsumo) {
      DialogUtils.showErrorDialog(
        context: context,
        title: 'Campo requerido',
        message: 'Debes seleccionar al menos un tipo de origen (Post-consumo o Pre-consumo)',
      );
      return;
    }

    if (_fuenteMaterialSeleccionada == null) {
      DialogUtils.showErrorDialog(
        context: context,
        title: 'Campo requerido',
        message: 'Debes seleccionar la fuente del material',
      );
      return;
    }

    if (_tipoPolimeroSeleccionado == null) {
      DialogUtils.showErrorDialog(
        context: context,
        title: 'Campo requerido',
        message: 'Debes seleccionar el tipo de polímero',
      );
      return;
    }

    if (!_hasSignature) {
      DialogUtils.showErrorDialog(
        context: context,
        title: 'Firma requerida',
        message: 'Debes proporcionar la firma del operador',
      );
      return;
    }

    if (!_hasImages || _photoFiles.isEmpty) {
      DialogUtils.showErrorDialog(
        context: context,
        title: 'Evidencia requerida',
        message: 'Debes agregar al menos una foto de evidencia',
      );
      return;
    }

    // Determinar la presentación final
    String presentacionFinal = _presentacionSeleccionada;
    if (_presentacionSeleccionada == 'Otro' && _otraPresentacionController.text.isNotEmpty) {
      presentacionFinal = _otraPresentacionController.text;
    }

    // Navegar a la pantalla de confirmación
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrigenConfirmarLoteScreen(
          tipoPolimero: _tipoPolimeroSeleccionado!,
          presentacion: presentacionFinal,
          fuente: _fuenteMaterialSeleccionada!,
          isPostConsumo: _isPostConsumo,
          isPreConsumo: _isPreConsumo,
          peso: double.tryParse(_pesoController.text) ?? 0,
          condiciones: _condicionesController.text.trim(),
          nombreOperador: _operadorController.text.trim(),
          comentarios: _comentariosController.text.trim().isEmpty ? null : _comentariosController.text.trim(),
          signaturePoints: List.from(_signaturePoints),
          photoFiles: List.from(_photoFiles),
        ),
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final horizontalPadding = screenWidth * 0.03; // 3% del ancho de pantalla
    final verticalPadding = screenHeight * 0.02; // 2% del alto de pantalla
    
    return Scaffold(
        backgroundColor: BioWayColors.backgroundGrey,
        resizeToAvoidBottomInset: true,
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // SliverAppBar compacto con header
            SliverAppBar(
              expandedHeight: screenHeight * 0.1,
              floating: false,
              pinned: true,
              backgroundColor: _primaryColor,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
              ),
              title: const Text(
                'Crear Nuevo Lote',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    color: _primaryColor,
                  ),
                  child: SafeArea(
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: horizontalPadding + 56, // Espacio para el botón back
                          right: horizontalPadding,
                          bottom: verticalPadding * 0.5,
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.025,
                            vertical: screenHeight * 0.005,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha:0.2),
                            borderRadius: BorderRadius.circular(screenWidth * 0.04),
                          ),
                          child: Text(
                            'Centro de Acopio - Origen',
                            style: TextStyle(
                              fontSize: screenWidth * 0.032,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Formulario
            SliverPadding(
              padding: EdgeInsets.only(
                left: horizontalPadding,
                right: horizontalPadding,
                top: verticalPadding,
                bottom: 20,
              ),
              sliver: SliverToBoxAdapter(
                child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Sección: Información del Material
                    SectionCard(
                      icon: '📦',
                      title: 'Información del Material',
                      isRequired: true,
                      children: [
                        // Origen del Material
                        const FieldLabel(text: 'Origen del Material', isRequired: true),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: CheckboxListTile(
                                title: const Text('Post-consumo'),
                                value: _isPostConsumo,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _isPostConsumo = value ?? false;
                                  });
                                },
                                contentPadding: EdgeInsets.zero,
                                controlAffinity: ListTileControlAffinity.leading,
                                activeColor: _primaryColor,
                                dense: true,
                              ),
                            ),
                            Expanded(
                              child: CheckboxListTile(
                                title: const Text('Pre-consumo'),
                                value: _isPreConsumo,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _isPreConsumo = value ?? false;
                                  });
                                },
                                contentPadding: EdgeInsets.zero,
                                controlAffinity: ListTileControlAffinity.leading,
                                activeColor: _primaryColor,
                                dense: true,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Fuente del Material
                        const FieldLabel(text: 'Fuente del Material', isRequired: true),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _fuenteMaterialSeleccionada,
                          decoration: SharedInputDecorations.ecoceStyle(
                            hintText: 'Selecciona la fuente del material',
                            primaryColor: _primaryColor,
                          ),
                          isExpanded: true,
                          isDense: true,
                          menuMaxHeight: screenHeight * 0.5,
                          items: _fuentesMaterial.asMap().entries.map((entry) {
                            final index = entry.key;
                            final fuente = entry.value;
                            return DropdownMenuItem<String>(
                              value: fuente,
                              child: Tooltip(
                                message: fuente,
                                child: Row(
                                  children: [
                                    Icon(
                                      _fuenteMaterialIcons[index],
                                      size: screenWidth * 0.05,
                                      color: _primaryColor.withValues(alpha:0.7),
                                    ),
                                    SizedBox(width: screenWidth * 0.03),
                                    Expanded(
                                      child: Text(
                                        fuente,
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.035,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _fuenteMaterialSeleccionada = newValue;
                            });
                          },
                          selectedItemBuilder: (BuildContext context) {
                            return _fuentesMaterial.map<Widget>((String fuente) {
                              // Crear versiones cortas para mostrar cuando está seleccionado
                              String shortText = fuente;
                              if (fuente.contains('(')) {
                                shortText = fuente.substring(0, fuente.indexOf('(')).trim();
                              }
                              return Container(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  shortText,
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.035,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList();
                          },
                          // Sin validación para diseño visual
                        ),
                        
                        SizedBox(height: screenHeight * 0.025),
                        
                        // Presentación del Material (selección con iconos)
                        const FieldLabel(text: 'Presentación del Material', isRequired: true),
                        SizedBox(height: screenHeight * 0.015),
                        Row(
                          children: [
                            Expanded(
                              child: _buildPresentacionOption(
                                svgPath: 'assets/images/icons/pacas.svg',
                                label: 'Pacas',
                                isSelected: _presentacionSeleccionada == 'Pacas',
                                onTap: () {
                                  if (_presentacionSeleccionada != 'Pacas') {
                                    setState(() {
                                      _presentacionSeleccionada = 'Pacas';
                                      _otraPresentacionController.clear();
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildPresentacionOption(
                                svgPath: 'assets/images/icons/sacos.svg',
                                label: 'Sacos',
                                isSelected: _presentacionSeleccionada == 'Sacos',
                                onTap: () {
                                  if (_presentacionSeleccionada != 'Sacos') {
                                    setState(() {
                                      _presentacionSeleccionada = 'Sacos';
                                      _otraPresentacionController.clear();
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildPresentacionOption(
                                icon: Icons.more_horiz,
                                label: 'Otro',
                                isSelected: _presentacionSeleccionada == 'Otro',
                                onTap: () {
                                  if (_presentacionSeleccionada != 'Otro') {
                                    setState(() {
                                      _presentacionSeleccionada = 'Otro';
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        
                        // Campo de texto para "Otro"
                        if (_presentacionSeleccionada == 'Otro') ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _otraPresentacionController,
                            decoration: SharedInputDecorations.ecoceStyle(
                              hintText: 'Especifica la presentación',
                              primaryColor: _primaryColor,
                            ),
                            textCapitalization: TextCapitalization.sentences,
                            onChanged: (value) {
                              setState(() {});
                            },
                          ),
                        ],
                        
                        const SizedBox(height: 20),
                        
                        // Tipo de Polímero (lista desplegable)
                        const FieldLabel(text: 'Tipo de Polímero', isRequired: true),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _tipoPolimeroSeleccionado,
                          decoration: SharedInputDecorations.ecoceStyle(
                            hintText: 'Selecciona el tipo de polímero',
                            primaryColor: _primaryColor,
                          ),
                          items: _tiposPolimeros.map((String tipo) {
                            return DropdownMenuItem<String>(
                              value: tipo,
                              child: Text(tipo),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _tipoPolimeroSeleccionado = newValue;
                            });
                          },
                          // Sin validación para diseño visual
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Peso en kilogramos (decimal)
                        WeightInputWidget(
                          controller: _pesoController,
                          label: 'Peso del Material',
                          primaryColor: _primaryColor,
                          quickAddValues: const [100, 250, 500, 1000],
                          isRequired: true,
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Condiciones del Material (hasta 100 caracteres)
                        const FieldLabel(text: 'Condiciones del Material', isRequired: true),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _condicionesController,
                          focusNode: _condicionesFocus,
                          maxLength: 100,
                          maxLines: 3,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          enableInteractiveSelection: true,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: SharedInputDecorations.ecoceStyle(
                            hintText: 'Describe el estado del material: limpieza, compactación, contaminación, etc.',
                            primaryColor: _primaryColor,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Sección: Datos del Responsable
                    SectionCard(
                      icon: '👤',
                      title: 'Datos del Responsable',
                      isRequired: true,
                      children: [
                        // Nombre del Operador (hasta 50 caracteres)
                        const FieldLabel(text: 'Nombre del Operador', isRequired: true),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _operadorController,
                          focusNode: _operadorFocus,
                          maxLength: 50,
                          keyboardType: TextInputType.name,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: SharedInputDecorations.ecoceStyle(
                            hintText: 'Ingresa el nombre completo',
                            primaryColor: _primaryColor,
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
                        const FieldLabel(text: 'Firma del Operador', isRequired: true),
                        const SizedBox(height: 8),
                        _buildSignatureArea(),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Sección: Evidencia Fotográfica con múltiples fotos
                    PhotoEvidenceFormField(
                      title: 'Evidencia Fotográfica',
                      maxPhotos: 5,
                      minPhotos: 1,
                      isRequired: true,
                      onPhotosChanged: _onPhotosChanged,
                      primaryColor: _primaryColor,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Sección: Comentarios Adicionales
                    SectionCard(
                      icon: '💬',
                      title: 'Comentarios',
                      children: [
                        TextFormField(
                          controller: _comentariosController,
                          focusNode: _comentariosFocus,
                          maxLength: 150,
                          maxLines: 4,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.done,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: SharedInputDecorations.ecoceStyle(
                            hintText: 'Ingresa comentarios adicionales (opcional)',
                            primaryColor: _primaryColor,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Botón de confirmar
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _generarLote,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 3,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Continuar',
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
        ],
      ),
    );
  }




  Widget _buildSignatureArea() {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _hasSignature 
            ? Colors.white 
            : BioWayColors.backgroundGrey,
        border: Border.all(
          color: _hasSignature 
              ? _primaryColor 
              : _primaryColor.withValues(alpha:0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: _hasSignature
          ? ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Stack(
                children: [
                  // Mostrar la firma guardada
                  Container(
                    height: 250,
                    width: double.infinity,
                    color: Colors.white,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: screenWidth * 0.95,
                        height: 400,
                        child: CustomPaint(
                          painter: SignaturePainter(
                            _signaturePoints,
                            strokeWidth: screenWidth * 0.008,
                          ),
                          size: Size.infinite,
                        ),
                      ),
                    ),
                  ),
                  // Botón para editar firma
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: BioWayColors.success.withValues(alpha:0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: BioWayColors.success,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Firmado',
                                style: TextStyle(
                                  color: BioWayColors.success,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _showSignatureDialog,
                          icon: Icon(
                            Icons.edit,
                            color: _primaryColor,
                            size: 20,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          padding: EdgeInsets.zero,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            elevation: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : InkWell(
              onTap: _showSignatureDialog,
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 56,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.edit,
                      color: _primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Firmar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }


  Widget _buildPresentacionOption({
    String? svgPath,
    IconData? icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: screenWidth * 0.05),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor.withValues(alpha:0.1) : BioWayColors.backgroundGrey,
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          border: Border.all(
            color: isSelected ? _primaryColor : _primaryColor.withValues(alpha:0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (svgPath != null)
              SvgPicture.asset(
                svgPath,
                width: screenWidth * 0.1,
                height: screenWidth * 0.1,
              )
            else if (icon != null)
              Icon(
                icon,
                size: screenWidth * 0.1,
                color: isSelected ? _primaryColor : BioWayColors.textGrey,
              ),
            SizedBox(height: screenWidth * 0.02),
            Text(
              label,
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? _primaryColor : BioWayColors.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

}