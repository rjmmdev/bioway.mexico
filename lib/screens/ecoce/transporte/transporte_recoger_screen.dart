import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../../../services/image_service.dart';
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
  
  // Variables de usuario (TODO: Obtener del auth)
  final String nombreOperador = 'Juan Pérez';
  final String folioOperador = 'V0000001';
  
  @override
  void initState() {
    super.initState();
    // Calcular peso total inicial
    double pesoTotal = widget.lotesSeleccionados.fold(
      0,
      (sum, lote) => sum + (lote['peso'] as double),
    );
    _pesoTotalController.text = pesoTotal.toStringAsFixed(1);
    
    // Inicializar nombre del transportista
    _nombreTransportistaController.text = nombreOperador;
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
          // TODO: Convertir firma a base64 y guardar en _firmaBase64
        });
      },
      primaryColor: const Color(0xFF3AA45B),
    );
  }

  Future<void> _takePicture() async {
    final File? image = await ImageService.takePhoto();
    
    if (image != null) {
      setState(() {
        _selectedImage = image;
        _hasImage = true;
        // TODO: Convertir imagen a base64 y guardar en _imagenBase64
      });
    }
  }

  Future<void> _pickFromGallery() async {
    final File? image = await ImageService.pickFromGallery();
    
    if (image != null) {
      setState(() {
        _selectedImage = image;
        _hasImage = true;
        // TODO: Convertir imagen a base64 y guardar en _imagenBase64
      });
    }
  }

  void _showImageOptions() {
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF3AA45B).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Color(0xFF3AA45B),
                ),
              ),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(context);
                _takePicture();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF3AA45B).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF3AA45B),
                ),
              ),
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
    if (_formKey.currentState!.validate()) {
      // TODO: Implementar POST /api/v1/transporte/entrada
      // Enviar:
      // - lotes_entrada: widget.lotesSeleccionados.map((l) => l['id']).toList()
      // - tipo_origen: 'acopio'
      // - direccion_origen: (geocodificación del centro de acopio)
      // - nombre_ope: _nombreTransportistaController.text
      // - placas: _placasController.text
      // - peso_recibido: _pesoTotalController.text
      // - evi_foto: _imagenBase64
      // - firma_salida: _firmaBase64
      // - comentarios: _comentariosController.text
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Carga confirmada exitosamente'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
      
      // Navegar de vuelta
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header con gradiente verde
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.02,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF3AA45B),
                    Color(0xFF68C76A),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      SizedBox(width: screenWidth * 0.03),
                      Text(
                        'Formulario de Carga',
                        style: TextStyle(
                          fontSize: screenWidth * 0.06,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Formulario
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: Column(
                      children: [
                        // Acordeón de lotes
                        Container(
                          key: const Key('panel_lotes_transportar'),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _mostrarTodosLotes = !_mostrarTodosLotes;
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: EdgeInsets.all(screenWidth * 0.04),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: widget.lotesSeleccionados
                                              .take(_mostrarTodosLotes ? widget.lotesSeleccionados.length : 3)
                                              .map((lote) => Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: screenWidth * 0.03,
                                                  vertical: screenHeight * 0.005,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFFF9C4),
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(
                                                    color: const Color(0xFFF9A825),
                                                  ),
                                                ),
                                                child: Text(
                                                  lote['firebaseId'] ?? lote['id'],
                                                  style: TextStyle(
                                                    fontSize: screenWidth * 0.03,
                                                    fontWeight: FontWeight.w600,
                                                    color: const Color(0xFF6F4E37),
                                                  ),
                                                ),
                                              ))
                                              .toList(),
                                        ),
                                      ),
                                      if (widget.lotesSeleccionados.length > 3)
                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              _mostrarTodosLotes = !_mostrarTodosLotes;
                                            });
                                          },
                                          child: Text(
                                            _mostrarTodosLotes ? 'Ver menos' : 'Ver más',
                                            style: const TextStyle(
                                              color: Color(0xFF3AA45B),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.02),

                        // Mensaje informativo
                        Container(
                          padding: EdgeInsets.all(screenWidth * 0.04),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF2196F3).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Color(0xFF2196F3),
                                size: 20,
                              ),
                              SizedBox(width: screenWidth * 0.03),
                              const Expanded(
                                child: Text(
                                  'La información se aplicará a todos los lotes seleccionados',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF0D47A1),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.03),

                        // Información del Transporte
                        Container(
                          padding: EdgeInsets.all(screenWidth * 0.04),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
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
                              Row(
                                children: [
                                  Icon(
                                    Icons.local_shipping,
                                    color: const Color(0xFF3AA45B),
                                    size: screenWidth * 0.06,
                                  ),
                                  SizedBox(width: screenWidth * 0.03),
                                  Text(
                                    'Información del Transporte',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.045,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: screenHeight * 0.02),

                              // Nombre del Transportista
                              TextFormField(
                                key: const Key('input_nombre_ope'),
                                controller: _nombreTransportistaController,
                                decoration: InputDecoration(
                                  labelText: 'Nombre del Transportista*',
                                  labelStyle: const TextStyle(
                                    color: Color(0xFF606060),
                                    fontSize: 14,
                                  ),
                                  hintText: 'Ingrese el nombre completo',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF9A9A9A),
                                    fontSize: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE0E0E0),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF3AA45B),
                                      width: 2,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE74C3C),
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Este campo es obligatorio';
                                  }
                                  return null;
                                },
                              ),

                              SizedBox(height: screenHeight * 0.02),

                              // Placas del Vehículo
                              TextFormField(
                                key: const Key('input_placas'),
                                controller: _placasController,
                                textCapitalization: TextCapitalization.characters,
                                decoration: InputDecoration(
                                  labelText: 'Placas del Vehículo*',
                                  labelStyle: const TextStyle(
                                    color: Color(0xFF606060),
                                    fontSize: 14,
                                  ),
                                  hintText: 'Ej: ABC-123',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF9A9A9A),
                                    fontSize: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE0E0E0),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF3AA45B),
                                      width: 2,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE74C3C),
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Este campo es obligatorio';
                                  }
                                  return null;
                                },
                              ),

                              SizedBox(height: screenHeight * 0.02),

                              // Peso Total Cargado
                              TextFormField(
                                key: const Key('input_peso_recibido'),
                                controller: _pesoTotalController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'Peso Total Cargado*',
                                  labelStyle: const TextStyle(
                                    color: Color(0xFF606060),
                                    fontSize: 14,
                                  ),
                                  hintText: '0.0',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF9A9A9A),
                                    fontSize: 14,
                                  ),
                                  suffixText: 'kg',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE0E0E0),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF3AA45B),
                                      width: 2,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE74C3C),
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Este campo es obligatorio';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.03),

                        // Evidencia Fotográfica
                        Container(
                          padding: EdgeInsets.all(screenWidth * 0.04),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
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
                              Row(
                                children: [
                                  Icon(
                                    Icons.camera_alt,
                                    color: const Color(0xFF3AA45B),
                                    size: screenWidth * 0.06,
                                  ),
                                  SizedBox(width: screenWidth * 0.03),
                                  Text(
                                    'Evidencia Fotográfica',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.045,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: screenHeight * 0.02),

                              GestureDetector(
                                onTap: _hasImage ? null : _showImageOptions,
                                child: Container(
                                  width: double.infinity,
                                  height: _hasImage ? null : screenHeight * 0.2,
                                  decoration: BoxDecoration(
                                    color: _hasImage ? null : const Color(0xFFF5F5F5),
                                    borderRadius: BorderRadius.circular(8),
                                    border: _hasImage ? null : Border.all(
                                      color: const Color(0xFF3AA45B),
                                      width: 2,
                                    ),
                                  ),
                                  child: _hasImage && _selectedImage != null
                                      ? Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.file(
                                                _selectedImage!,
                                                width: double.infinity,
                                                height: screenHeight * 0.2,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            Positioned(
                                              top: 8,
                                              right: 8,
                                              child: IconButton(
                                                onPressed: () {
                                                  setState(() {
                                                    _selectedImage = null;
                                                    _hasImage = false;
                                                  });
                                                },
                                                icon: Container(
                                                  padding: const EdgeInsets.all(4),
                                                  decoration: const BoxDecoration(
                                                    color: Colors.white,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.close,
                                                    color: Color(0xFFE74C3C),
                                                    size: 20,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      : Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.add_a_photo,
                                              size: screenWidth * 0.12,
                                              color: const Color(0xFF3AA45B),
                                            ),
                                            SizedBox(height: screenHeight * 0.01),
                                            Text(
                                              'Tomar o seleccionar foto',
                                              style: TextStyle(
                                                fontSize: screenWidth * 0.04,
                                                color: const Color(0xFF3AA45B),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.03),

                        // Firma del Responsable
                        Container(
                          padding: EdgeInsets.all(screenWidth * 0.04),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
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
                              Row(
                                children: [
                                  Icon(
                                    Icons.edit,
                                    color: const Color(0xFF3AA45B),
                                    size: screenWidth * 0.06,
                                  ),
                                  SizedBox(width: screenWidth * 0.03),
                                  Text(
                                    'Firma del Responsable',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.045,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: screenHeight * 0.02),

                              GestureDetector(
                                onTap: _showSignatureDialog,
                                child: Container(
                                  width: double.infinity,
                                  height: screenHeight * 0.15,
                                  decoration: BoxDecoration(
                                    color: _hasSignature ? Colors.white : const Color(0xFFF5F5F5),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _hasSignature 
                                          ? const Color(0xFF4CAF50) 
                                          : const Color(0xFFE0E0E0),
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
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF4CAF50),
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
                                              Icons.edit,
                                              size: screenWidth * 0.1,
                                              color: const Color(0xFF9A9A9A),
                                            ),
                                            SizedBox(height: screenHeight * 0.01),
                                            Text(
                                              'Toque para firmar',
                                              style: TextStyle(
                                                fontSize: screenWidth * 0.04,
                                                color: const Color(0xFF9A9A9A),
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.03),

                        // Comentarios
                        Container(
                          padding: EdgeInsets.all(screenWidth * 0.04),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
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
                              Row(
                                children: [
                                  Icon(
                                    Icons.comment,
                                    color: const Color(0xFF3AA45B),
                                    size: screenWidth * 0.06,
                                  ),
                                  SizedBox(width: screenWidth * 0.03),
                                  Text(
                                    'Comentarios',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.045,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: screenHeight * 0.02),

                              TextFormField(
                                key: const Key('input_comentarios'),
                                controller: _comentariosController,
                                maxLines: 3,
                                maxLength: 150,
                                decoration: InputDecoration(
                                  hintText: 'Observaciones adicionales (opcional)',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF9A9A9A),
                                    fontSize: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE0E0E0),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF3AA45B),
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.all(16),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.04),

                        // Botón Confirmar Carga
                        Container(
                          key: const Key('btn_confirmar_carga'),
                          width: double.infinity,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF3AA45B),
                                Color(0xFF68C76A),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _confirmarCarga,
                              borderRadius: BorderRadius.circular(8),
                              child: Center(
                                child: Text(
                                  'Confirmar Carga',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.045,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.1),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}