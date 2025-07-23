import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import '../../../utils/colors.dart';
import '../../../services/user_session_service.dart';
import '../../../services/image_service.dart';
import '../../../services/lote_service.dart';
import '../../../services/firebase/firebase_storage_service.dart';
import '../../../models/lotes/lote_transportista_model.dart';
import '../shared/widgets/signature_dialog.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import '../shared/widgets/form_widgets.dart';
import '../shared/widgets/photo_evidence_widget.dart';
import '../shared/widgets/lote_card_unified.dart';
import '../shared/utils/dialog_utils.dart';

class TransporteFormularioCargaScreen extends StatefulWidget {
  final List<Map<String, dynamic>> lotes;
  
  const TransporteFormularioCargaScreen({
    super.key,
    required this.lotes,
  });

  @override
  State<TransporteFormularioCargaScreen> createState() => _TransporteFormularioCargaScreenState();
}

class _TransporteFormularioCargaScreenState extends State<TransporteFormularioCargaScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserSessionService _userSession = UserSessionService();
  final LoteService _loteService = LoteService();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  
  // Controladores
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _placasController = TextEditingController();
  final TextEditingController _pesoController = TextEditingController();
  final TextEditingController _comentariosController = TextEditingController();
  
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
    double pesoTotal = widget.lotes.fold(0.0, (sum, lote) => sum + (lote['peso'] as double));
    _pesoController.text = pesoTotal.toStringAsFixed(1);
  }
  
  @override
  void dispose() {
    _nombreController.dispose();
    _placasController.dispose();
    _pesoController.dispose();
    _comentariosController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      
      if (photo != null) {
        // Optimizar la imagen
        final compressedImage = await ImageService.optimizeImageForDatabase(File(photo.path));
        
        setState(() {
          _evidenciaFoto = compressedImage;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al capturar imagen: $e'),
            backgroundColor: BioWayColors.error,
          ),
        );
      }
    }
  }
  
  void _showSignatureDialog() {
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

      // Calcular tipo de polímero predominante
      final tipoPolimeros = await _loteService.calcularTipoPolimeroPredominante(
        widget.lotes.map((l) => l['id'] as String).toList()
      );
      String tipoPredominante = 'Mixto';
      if (tipoPolimeros.isNotEmpty) {
        tipoPredominante = tipoPolimeros.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
      }

      // Calcular peso total
      final pesoTotal = await _loteService.calcularPesoTotal(
        widget.lotes.map((l) => l['id'] as String).toList()
      );

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

      // Crear el modelo del lote de transportista
      final loteTransportista = LoteTransportistaModel(
        fechaRecepcion: DateTime.now(),
        lotesEntrada: widget.lotes.map((l) => l['id'] as String).toList(),
        tipoOrigen: tipoPredominante,
        direccionOrigen: widget.lotes.first['centro_acopio'] ?? 'Sin dirección',
        pesoRecibido: pesoTotal,
        nombreOpe: _nombreController.text.trim(),
        placas: _placasController.text.trim(),
        firmaSalida: _signatureUrl,
        comentariosEntrada: _comentariosController.text.trim(),
        eviFotoEntrada: photoUrls,
        estado: 'en_transporte',
      );

      // Crear el lote en Firestore
      final loteId = await _loteService.crearLoteTransportista(loteTransportista);
      
      if (mounted) {
        DialogUtils.showSuccessDialog(
          context: context,
          title: 'Éxito',
          message: 'Carga confirmada exitosamente',
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
      DialogUtils.showErrorDialog(
        context: context,
        title: 'Error',
        message: 'No se pudo confirmar la carga: ${e.toString()}',
      );
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
      print('Error al capturar firma: $e');
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: BioWayColors.primaryGreen,
        elevation: 0,
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
            fontSize: 20,
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
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Acordeón de lotes
                  _buildLotesAccordion(),
                  
                  const SizedBox(height: 16),
                  
                  // Cuadro informativo
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF90CAF9)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: BioWayColors.info),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'La información se aplicará a todos los lotes seleccionados',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1565C0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Información del Transporte
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
                              '🚚',
                              style: TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Información del Transporte',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: BioWayColors.darkGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
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
                        const SizedBox(height: 16),
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
                        const SizedBox(height: 20),
                        // Peso total no editable
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: BioWayColors.backgroundGrey,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: BioWayColors.primaryGreen.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.scale,
                                color: BioWayColors.primaryGreen,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Peso Total a Transportar',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: BioWayColors.textGrey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_pesoController.text} kg',
                                      style: TextStyle(
                                        fontSize: 18,
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
                  
                  const SizedBox(height: 24),
                  
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
                  
                  const SizedBox(height: 24),
                  
                  // Firma del Responsable
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
                              '✍️',
                              style: TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Firma del Responsable',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: BioWayColors.darkGreen,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '*',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: BioWayColors.error,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
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
                                                    _firma = [];
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
                  
                  // Comentarios
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
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 100), // Espacio para el botón fijo
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
        padding: const EdgeInsets.all(20),
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
            height: 48,
            child: ElevatedButton(
              key: const Key('btn_confirmar_carga'),
              onPressed: _isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: BioWayColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 2,
              ),
              child: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Confirmar Carga',
                    style: TextStyle(
                      fontSize: 16,
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
              padding: const EdgeInsets.all(16),
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
                            fontSize: 16,
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
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        if (!_lotesExpanded && widget.lotes.length > 1)
                          Text(
                            'y ${widget.lotes.length - 1} más...',
                            style: TextStyle(
                              fontSize: 14,
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
  
  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: BioWayColors.darkGreen,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
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
              fontSize: 12,
            ),
            counterText: '',
          ),
        ),
      ],
    );
  }
}