import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import '../../../utils/colors.dart';
import '../../../utils/ui_constants.dart';
import '../../../services/user_session_service.dart';
import '../../../services/carga_transporte_service.dart';
import '../../../services/firebase/firebase_storage_service.dart';
import '../shared/widgets/signature_dialog.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import '../shared/widgets/photo_evidence_widget.dart';
import '../shared/widgets/lote_card_unified.dart';
import '../shared/utils/dialog_utils.dart';
import '../shared/widgets/unified_container.dart';
import '../shared/widgets/field_label.dart' as field_label;
import '../shared/utils/shared_input_decorations.dart';

class TransporteFormularioCargaScreen extends StatefulWidget {
  final List<Map<String, dynamic>> lotes;
  final Map<String, dynamic> datosOrigen;
  
  const TransporteFormularioCargaScreen({
    super.key,
    required this.lotes,
    required this.datosOrigen,
  });

  @override
  State<TransporteFormularioCargaScreen> createState() => _TransporteFormularioCargaScreenState();
}

class _TransporteFormularioCargaScreenState extends State<TransporteFormularioCargaScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserSessionService _userSession = UserSessionService();
  final CargaTransporteService _cargaService = CargaTransporteService();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  
  // Controladores
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _placasController = TextEditingController();
  final TextEditingController _pesoController = TextEditingController();
  final TextEditingController _comentariosController = TextEditingController();
  final TextEditingController _operadorController = TextEditingController();
  
  // Estados
  bool _isLoading = false;
  bool _lotesExpanded = false;
  File? _evidenciaFoto;
  List<File> _photoFiles = [];
  List<Offset?> _firma = [];
  String? _signatureUrl;
  
  @override
  void initState() {
    super.initState();
    _initializeForm();
  }
  
  void _initializeForm() {
    final userData = _userSession.getUserData();
    _nombreController.text = userData?['nombre'] ?? '';
    
    // Calcular peso total
    double pesoTotal = widget.lotes.fold(0.0, (previousValue, lote) => previousValue + (lote['peso'] as double));
    _pesoController.text = pesoTotal.toStringAsFixed(1);
  }
  
  @override
  void dispose() {
    _nombreController.dispose();
    _placasController.dispose();
    _pesoController.dispose();
    _comentariosController.dispose();
    _operadorController.dispose();
    super.dispose();
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
      initialSignature: _firma,
      onSignatureSaved: (signature) {
        setState(() {
          _firma = signature;
        });
      },
      primaryColor: const Color(0xFF3AA45B),
    );
  }
  
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_evidenciaFoto == null && _photoFiles.isEmpty) {
      DialogUtils.showErrorDialog(
        context: context,
        title: 'Evidencia requerida',
        message: 'Por favor capture al menos una evidencia fotográfica',
      );
      return;
    }
    
    if (_firma.isEmpty) {
      DialogUtils.showErrorDialog(
        context: context,
        title: 'Firma requerida',
        message: 'Por favor capture la firma del responsable',
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Obtener datos del usuario actual
      final userProfile = await _userSession.getUserProfile();
      if (userProfile == null) {
        throw Exception('No se pudo obtener el perfil del usuario');
      }

      // Subir firma a Storage
      if (_firma.isNotEmpty) {
        final signatureImage = await _captureSignature();
        if (signatureImage != null) {
          _signatureUrl = await _storageService.uploadImage(
            signatureImage,
            'lotes/transportista/firmas',
          );
        }
      }

      // Subir fotos a Storage
      List<String> photoUrls = [];
      if (_evidenciaFoto != null) {
        _photoFiles = [_evidenciaFoto!];
      }
      
      for (int i = 0; i < _photoFiles.length; i++) {
        final url = await _storageService.uploadImage(
          _photoFiles[i],
          'lotes/transportista/evidencias',
        );
        if (url != null) {
          photoUrls.add(url);
        }
      }

      // Crear la carga usando el servicio de carga
      await _cargaService.crearCarga(
        lotesIds: widget.lotes.map((l) => l['id'] as String).toList(),
        transportistaFolio: userProfile['folio'] ?? 'V0000001',
        origenUsuarioId: widget.datosOrigen['id'],
        origenUsuarioFolio: widget.datosOrigen['folio'],
        origenUsuarioNombre: widget.datosOrigen['nombre'],
        origenUsuarioTipo: widget.datosOrigen['tipo'],
        vehiculoPlacas: _placasController.text.trim(),
        nombreConductor: _nombreController.text.trim(),
        nombreOperador: _operadorController.text.trim(),
        pesoTotalRecogido: double.parse(_pesoController.text),
        firmaRecogida: _signatureUrl,
        evidenciasFotoRecogida: photoUrls,
        comentariosRecogida: _comentariosController.text.trim(),
      );
      
      if (mounted) {
        DialogUtils.showSuccessDialog(
          context: context,
          title: 'Éxito',
          message: 'Carga creada exitosamente con ${widget.lotes.length} lote${widget.lotes.length > 1 ? 's' : ''}.',
          onPressed: () {
            // Navegar a la pestaña de entregar
            Navigator.pushReplacementNamed(
              context,
              '/transporte_entregar',
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        DialogUtils.showErrorDialog(
          context: context,
          title: 'Error',
          message: 'No se pudo confirmar la carga: ${e.toString()}',
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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

      for (int i = 0; i < _firma.length - 1; i++) {
        if (_firma[i] != null && _firma[i + 1] != null) {
          canvas.drawLine(_firma[i]!, _firma[i + 1]!, paint);
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
  
  void _onBottomNavTapped(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/transporte_inicio');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/transporte_entregar');
        break;
      case 2:
        Navigator.pushNamed(context, '/transporte_ayuda');
        break;
      case 3:
        Navigator.pushNamed(context, '/transporte_perfil');
        break;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        // Volver a la pantalla anterior
        Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
        backgroundColor: BioWayColors.primaryGreen,
        elevation: UIConstants.elevationNone,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Formulario de Carga',
          style: TextStyle(
            fontSize: UIConstants.fontSizeXLarge,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsetsConstants.paddingAll16,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información del origen
                  _buildOrigenInfo(),
                  
                  SizedBox(height: UIConstants.spacing16),
                  
                  // Acordeón de lotes
                  _buildLotesAccordion(),
                  
                  SizedBox(height: UIConstants.spacing16),
                  
                  // Cuadro informativo
                  Container(
                    padding: EdgeInsetsConstants.paddingAll16,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF90CAF9)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: BioWayColors.info),
                        SizedBox(width: UIConstants.spacing12),
                        const Expanded(
                          child: Text(
                            'La información se aplicará a todos los lotes seleccionados',
                            style: TextStyle(
                              fontSize: UIConstants.fontSizeMedium,
                              color: Color(0xFF1565C0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: UIConstants.spacing24),
                  
                  // Información del Transporte
                  Container(
                    width: double.infinity,
                    padding: EdgeInsetsConstants.paddingAll20,
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
                              '🚚',
                              style: TextStyle(fontSize: UIConstants.fontSizeTitle),
                            ),
                            SizedBox(width: UIConstants.spacing8 + 2),
                            Text(
                              'Información del Transporte',
                              style: TextStyle(
                                fontSize: UIConstants.fontSizeLarge,
                                fontWeight: FontWeight.bold,
                                color: BioWayColors.darkGreen,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: UIConstants.spacing20),
                        _buildTextField(
                          controller: _nombreController,
                          label: 'Nombre del Transportista',
                          hint: 'Ingrese el nombre completo',
                          keyId: 'input_nombre_ope',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Este campo es obligatorio';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: UIConstants.spacing16),
                        _buildTextField(
                          controller: _placasController,
                          label: 'Placas del Vehículo',
                          hint: 'Ej: ABC-123',
                          keyId: 'input_placas',
                          textCapitalization: TextCapitalization.characters,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Este campo es obligatorio';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: UIConstants.spacing20),
                        // Peso total no editable
                        Container(
                          padding: EdgeInsetsConstants.paddingAll16,
                          decoration: BoxDecoration(
                            color: BioWayColors.backgroundGrey,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: BioWayColors.primaryGreen.withValues(alpha: 0.3),
                              width: UIConstants.dividerThickness,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.scale,
                                color: BioWayColors.primaryGreen,
                                size: UIConstants.iconSizeMedium,
                              ),
                              SizedBox(width: UIConstants.spacing12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Peso Total a Transportar',
                                      style: TextStyle(
                                        fontSize: UIConstants.fontSizeMedium,
                                        fontWeight: FontWeight.w600,
                                        color: BioWayColors.textGrey,
                                      ),
                                    ),
                                    SizedBox(height: UIConstants.spacing4),
                                    Text(
                                      '${_pesoController.text} kg',
                                      style: TextStyle(
                                        fontSize: UIConstants.fontSizeLarge,
                                        fontWeight: FontWeight.bold,
                                        color: BioWayColors.darkGreen,
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
                  ),
                  
                  SizedBox(height: UIConstants.spacing24),
                  
                  // Evidencia Fotográfica usando el widget compartido
                  PhotoEvidenceFormField(
                    title: 'Evidencia Fotográfica',
                    maxPhotos: 3,
                    minPhotos: 1,
                    isRequired: true,
                    onPhotosChanged: (photos) {
                      setState(() {
                        _evidenciaFoto = photos.isNotEmpty ? photos.first : null;
                      });
                    },
                    primaryColor: BioWayColors.primaryGreen,
                  ),
                  
                  SizedBox(height: UIConstants.spacing24),
                  
                  // Sección: Datos del Responsable
                  Container(
                    width: double.infinity,
                    padding: EdgeInsetsConstants.paddingAll20,
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
                              style: TextStyle(fontSize: UIConstants.fontSizeTitle),
                            ),
                            SizedBox(width: UIConstants.spacing8 + 2),
                            Expanded(
                              child: Text(
                                'Datos del Responsable que Entrega el Material',
                                style: TextStyle(
                                  fontSize: UIConstants.fontSizeLarge,
                                  fontWeight: FontWeight.bold,
                                  color: BioWayColors.darkGreen,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
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
                      const SizedBox(height: 8),
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
                            return 'Ingresa el nombre';
                          }
                          if (value.length < 3) {
                            return 'El nombre debe tener al menos 3 caracteres';
                          }
                          return null;
                        },
                      ),
                      
                      SizedBox(height: UIConstants.spacing20),
                      
                      // Firma del Operador
                      const field_label.FieldLabel(text: 'Firma', isRequired: true),
                      const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _firma.isEmpty ? _showSignatureDialog : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: _firma.isNotEmpty ? 150 : 100,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: _firma.isNotEmpty 
                                  ? BioWayColors.primaryGreen.withValues(alpha: 0.05)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _firma.isNotEmpty 
                                    ? BioWayColors.primaryGreen 
                                    : Colors.grey[300]!,
                                width: _firma.isNotEmpty ? 2 : 1,
                              ),
                            ),
                            child: _firma.isEmpty
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
                                        padding: EdgeInsets.all(UIConstants.spacing12),
                                        child: Center(
                                          child: AspectRatio(
                                            aspectRatio: 2.0,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Colors.grey[200]!,
                                                  width: UIConstants.dividerThickness,
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
                                                      painter: SignaturePainter(_firma),
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
                                                onPressed: _showSignatureDialog,
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
                                                    _firma = [];
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
                  
                  SizedBox(height: UIConstants.spacing24),
                  
                  // Comentarios
                  Container(
                    width: double.infinity,
                    padding: EdgeInsetsConstants.paddingAll20,
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
                          key: const Key('input_comentarios'),
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Comentarios adicionales (opcional)',
                            hintStyle: TextStyle(color: const Color(0xFF9A9A9A)),
                            filled: true,
                            fillColor: BioWayColors.backgroundGrey,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: BioWayColors.primaryGreen.withValues(alpha: 0.3),
                                width: UIConstants.dividerThickness,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
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
                  
                  SizedBox(height: UIConstants.qrSizeSmall), // Espacio para el botón fijo
                ],
              ),
            ),
          ),
          
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      
      // Botón confirmar fijo
      bottomSheet: Container(
        padding: EdgeInsetsConstants.paddingAll20,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: UIConstants.buttonHeightMedium,
            child: ElevatedButton(
              key: const Key('btn_confirmar_carga'),
              onPressed: _isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: BioWayColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: UIConstants.elevationSmall,
              ),
              child: _isLoading 
                ? const SizedBox(
                    width: UIConstants.iconSizeMedium,
                    height: UIConstants.iconSizeMedium,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Confirmar Carga',
                    style: TextStyle(
                      fontSize: UIConstants.fontSizeBody,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            ),
          ),
        ),
      ),
      
      bottomNavigationBar: EcoceBottomNavigation(
        selectedIndex: 0,
        onItemTapped: _onBottomNavTapped,
        primaryColor: BioWayColors.primaryGreen,
        items: const [
          NavigationItem(
            icon: Icons.qr_code_scanner_rounded,
            label: 'Recoger',
            testKey: 'transporte_nav_recoger',
          ),
          NavigationItem(
            icon: Icons.local_shipping_rounded,
            label: 'Entregar',
            testKey: 'transporte_nav_entregar',
          ),
          NavigationItem(
            icon: Icons.help_outline_rounded,
            label: 'Ayuda',
            testKey: 'transporte_nav_ayuda',
          ),
          NavigationItem(
            icon: Icons.person_outline_rounded,
            label: 'Perfil',
            testKey: 'transporte_nav_perfil',
          ),
        ],
        fabConfig: null,
      ),
      ),
    );
  }
  
  Widget _buildLotesAccordion() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _lotesExpanded = !_lotesExpanded;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: EdgeInsetsConstants.paddingAll16,
              key: const Key('panel_lotes_transportar'),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lotes a transportar (${widget.lotes.length})',
                          style: const TextStyle(
                            fontSize: UIConstants.fontSizeBody,
                            fontWeight: FontWeight.bold,
                            color: BioWayColors.darkGreen,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (!_lotesExpanded) ...
                          widget.lotes.take(1).map((lote) => 
                            Text(
                              '${lote['id']} - ${lote['material']} - ${lote['peso']} kg',
                              style: TextStyle(
                                fontSize: UIConstants.fontSizeMedium,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        if (!_lotesExpanded && widget.lotes.length > 1)
                          Text(
                            'y ${widget.lotes.length - 1} más...',
                            style: TextStyle(
                              fontSize: UIConstants.fontSizeMedium,
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    _lotesExpanded ? Icons.expand_less : Icons.expand_more,
                    color: BioWayColors.primaryGreen,
                  ),
                ],
              ),
            ),
          ),
          if (_lotesExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: Colors.grey.shade200),
                  const SizedBox(height: 8),
                  ...widget.lotes.map((lote) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: LoteCard.simple(
                      lote: lote,
                      onTap: () {},
                    ),
                  )),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildOrigenInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BioWayColors.primaryGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: BioWayColors.primaryGreen.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: BioWayColors.primaryGreen,
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                'Recogiendo de:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: BioWayColors.darkGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.datosOrigen['nombre'],
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: BioWayColors.darkGreen,
            ),
          ),
          SizedBox(height: UIConstants.spacing4),
          Text(
            'Folio: ${widget.datosOrigen['folio']}',
            style: TextStyle(
              fontSize: 14,
              color: BioWayColors.textGrey,
            ),
          ),
          SizedBox(height: UIConstants.spacing4),
          Text(
            widget.datosOrigen['direccion'],
            style: TextStyle(
              fontSize: 14,
              color: BioWayColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String keyId,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
    String? suffixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
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
          controller: controller,
          key: Key(keyId),
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9A9A9A)),
            suffixText: suffixText,
            filled: true,
            fillColor: BioWayColors.backgroundGrey,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: BioWayColors.primaryGreen.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: BioWayColors.primaryGreen,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFE74C3C),
                width: 2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFE74C3C),
                width: 2,
              ),
            ),
            errorStyle: const TextStyle(
              color: Color(0xFFE74C3C),
              fontSize: UIConstants.fontSizeSmall,
            ),
            counterText: '',
          ),
        ),
      ],
    );
  }
}