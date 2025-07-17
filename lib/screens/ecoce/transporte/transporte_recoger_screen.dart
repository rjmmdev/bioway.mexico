import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../../../utils/colors.dart';
import '../../../services/image_service.dart';
import '../reciclador/widgets/image_preview.dart';
import '../shared/widgets/signature_dialog.dart';

class TransporteRecogerScreen extends StatefulWidget {
  final List<Map<String, dynamic>> lotesSeleccionados;
  
  const TransporteRecogerScreen({
    super.key,
    required this.lotesSeleccionados,
  });

  @override
  State<TransporteRecogerScreen> createState() => _TransporteRecogerScreenState();
}

class _TransporteRecogerScreenState extends State<TransporteRecogerScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores
  final TextEditingController _nombreTransportistaController = TextEditingController();
  final TextEditingController _placasController = TextEditingController();
  final TextEditingController _pesoTotalController = TextEditingController();
  final TextEditingController _nombreEntregaController = TextEditingController();
  final TextEditingController _comentariosController = TextEditingController();
  
  // Variables para la firma
  List<Offset?> _signaturePoints = [];
  bool _hasSignature = false;
  
  // Variables para la imagen
  File? _selectedImage;
  bool _hasImage = false;
  
  // Estado de expansión de lotes
  bool _mostrarTodosLotes = false;
  
  @override
  void initState() {
    super.initState();
    // Calcular peso total inicial
    double pesoTotal = widget.lotesSeleccionados.fold(
      0,
      (sum, lote) => sum + (lote['peso'] as double),
    );
    _pesoTotalController.text = pesoTotal.toStringAsFixed(1);
  }
  
  @override
  void dispose() {
    _nombreTransportistaController.dispose();
    _placasController.dispose();
    _pesoTotalController.dispose();
    _nombreEntregaController.dispose();
    _comentariosController.dispose();
    super.dispose();
  }

  void _showSignatureDialog() {
    SignatureDialog.show(
      context: context,
      title: 'Firma del Responsable',
      initialSignature: _signaturePoints,
      onSignatureSaved: (points) {
        setState(() {
          _signaturePoints = List.from(points);
          _hasSignature = points.isNotEmpty;
        });
      },
      primaryColor: BioWayColors.deepBlue,
    );
  }

  Future<void> _takePicture() async {
    final File? image = await ImageService.takePhoto();
    
    if (image != null) {
      setState(() {
        _selectedImage = image;
        _hasImage = true;
      });
    }
  }

  Future<void> _pickFromGallery() async {
    final File? image = await ImageService.pickFromGallery();
    
    if (image != null) {
      setState(() {
        _selectedImage = image;
        _hasImage = true;
      });
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Seleccionar imagen',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(context);
                _takePicture();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Seleccionar de galería'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarCarga() {
    // Sin validaciones para diseño visual
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Carga confirmada exitosamente'),
        backgroundColor: BioWayColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BioWayColors.backgroundGrey,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 16),
                Text(
                  'Formulario de Carga',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: BioWayColors.deepBlue,
                  ),
                ),
                const SizedBox(height: 16),
                // Resumen de lotes seleccionados
                Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Lotes a Transportar',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: BioWayColors.darkGrey,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: BioWayColors.deepBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${widget.lotesSeleccionados.length} lotes',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: BioWayColors.deepBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Lista compacta de lotes
                    ...widget.lotesSeleccionados
                        .take(_mostrarTodosLotes ? widget.lotesSeleccionados.length : 3)
                        .map((lote) => _buildLoteCompacto(lote))
                        .toList(),
                    
                    if (widget.lotesSeleccionados.length > 3)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _mostrarTodosLotes = !_mostrarTodosLotes;
                          });
                        },
                        child: Text(
                          _mostrarTodosLotes ? 'Ver menos' : 'Ver más',
                          style: TextStyle(
                            color: BioWayColors.deepBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Mensaje informativo
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: BioWayColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: BioWayColors.info.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: BioWayColors.info,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Este formulario aplicará la misma información a todos los lotes seleccionados. Cada lote mantendrá su identidad individual.',
                        style: TextStyle(
                          fontSize: 14,
                          color: BioWayColors.darkGrey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Formulario principal
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información del Transporte
                    Row(
                      children: [
                        Icon(
                          Icons.local_shipping,
                          color: BioWayColors.deepBlue,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Información del Transporte',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: BioWayColors.darkGrey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Nombre del Transportista
                    _buildFieldLabel('Nombre del Transportista'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nombreTransportistaController,
                      maxLength: 50,
                      decoration: _buildInputDecoration(
                        hintText: 'Nombre completo',
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Placas del Vehículo
                    _buildFieldLabel('Placas del Vehículo'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _placasController,
                      maxLength: 15,
                      textCapitalization: TextCapitalization.characters,
                      decoration: _buildInputDecoration(
                        hintText: 'ABC-123-45',
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Peso Total Cargado
                    _buildFieldLabel('Peso Total Cargado'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _pesoTotalController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d{0,5}\.?\d{0,3}')),
                            ],
                            decoration: _buildInputDecoration(
                              hintText: 'XXXXX.XXX',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          decoration: BoxDecoration(
                            color: BioWayColors.lightGrey.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'kg',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: BioWayColors.darkGrey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Evidencia Fotográfica
                    Row(
                      children: [
                        Icon(
                          Icons.camera_alt,
                          color: BioWayColors.deepBlue,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Evidencia Fotográfica',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: BioWayColors.darkGrey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    GestureDetector(
                      onTap: _hasImage ? null : _showImageOptions,
                      child: Container(
                        width: double.infinity,
                        height: _hasImage ? null : 200,
                        decoration: BoxDecoration(
                          color: _hasImage ? null : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: _hasImage ? null : Border.all(
                            color: BioWayColors.lightGrey,
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: _hasImage
                            ? Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      _selectedImage!,
                                      width: double.infinity,
                                      height: 200,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => ImagePreviewDialog(
                                              image: _selectedImage!,
                                              title: 'Evidencia fotográfica',
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.fullscreen),
                                        label: const Text('Ver completa'),
                                      ),
                                      const SizedBox(width: 16),
                                      TextButton.icon(
                                        onPressed: _showImageOptions,
                                        icon: const Icon(Icons.edit),
                                        label: const Text('Cambiar'),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt_outlined,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Tomar Fotografía de la Carga',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: BioWayColors.darkGrey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Muestra los lotes en el vehículo',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: BioWayColors.textGrey,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Firma del Responsable
                    Row(
                      children: [
                        Icon(
                          Icons.draw,
                          color: BioWayColors.deepBlue,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Firma del Responsable',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: BioWayColors.darkGrey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Nombre de quien entrega
                    _buildFieldLabel('Nombre de quien entrega'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nombreEntregaController,
                      decoration: _buildInputDecoration(
                        hintText: 'Nombre completo de quien entrega',
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Área de firma
                    GestureDetector(
                      onTap: _showSignatureDialog,
                      child: Container(
                        width: double.infinity,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _hasSignature ? BioWayColors.success : BioWayColors.lightGrey,
                            width: 2,
                          ),
                        ),
                        child: _hasSignature
                            ? Stack(
                                children: [
                                  CustomPaint(
                                    painter: SignaturePainter(_signaturePoints),
                                    size: Size.infinite,
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: BioWayColors.success,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
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
                                      fontWeight: FontWeight.w600,
                                      color: BioWayColors.darkGrey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    child: Text(
                                      'La persona responsable del centro de acopio debe firmar para confirmar la salida del material',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: BioWayColors.textGrey,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    
                    if (_hasSignature) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: _showSignatureDialog,
                            icon: Icon(
                              Icons.edit,
                              size: 16,
                              color: BioWayColors.deepBlue,
                            ),
                            label: Text(
                              'Editar firma',
                              style: TextStyle(
                                color: BioWayColors.deepBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: 30),
                    
                    // Comentarios
                    Row(
                      children: [
                        Icon(
                          Icons.comment,
                          color: BioWayColors.deepBlue,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Comentarios (Opcional)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: BioWayColors.darkGrey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _comentariosController,
                      maxLines: 3,
                      maxLength: 150,
                      decoration: _buildInputDecoration(
                        hintText: 'Observaciones adicionales (opcional)',
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Botón de confirmar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _confirmarCarga,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BioWayColors.deepBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 3,
                    ),
                    child: const Text(
                      'Confirmar Carga',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildLoteCompacto(Map<String, dynamic> lote) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: BioWayColors.backgroundGrey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: BioWayColors.brightYellow.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              lote['id'],
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: BioWayColors.darkGrey,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            lote['material'],
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: BioWayColors.petBlue,
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.scale,
            size: 14,
            color: BioWayColors.textGrey,
          ),
          const SizedBox(width: 4),
          Text(
            '${lote['peso']} kg',
            style: TextStyle(
              fontSize: 14,
              color: BioWayColors.darkGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: BioWayColors.darkGrey,
      ),
    );
  }

  InputDecoration _buildInputDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: Colors.grey[500],
      ),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: BioWayColors.lightGrey,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: BioWayColors.lightGrey,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: BioWayColors.deepBlue,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: BioWayColors.error,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: BioWayColors.error,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}