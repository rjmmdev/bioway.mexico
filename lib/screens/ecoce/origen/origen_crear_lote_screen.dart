import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';
import '../../../utils/colors.dart';
import '../../../services/image_service.dart';
import '../reciclador/widgets/image_preview.dart';
import 'origen_lote_detalle_screen.dart';

class OrigenCrearLoteScreen extends StatefulWidget {
  const OrigenCrearLoteScreen({super.key});

  @override
  State<OrigenCrearLoteScreen> createState() => _OrigenCrearLoteScreenState();
}

class _OrigenCrearLoteScreenState extends State<OrigenCrearLoteScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores para los campos de texto
  final TextEditingController _fuenteController = TextEditingController();
  final TextEditingController _pesoController = TextEditingController();
  final TextEditingController _condicionesController = TextEditingController();
  final TextEditingController _operadorController = TextEditingController();
  final TextEditingController _comentariosController = TextEditingController();

  // Variables para los selectores
  String? _tipoPolimeroSeleccionado;
  String _presentacionSeleccionada = 'Pacas';

  // Lista de tipos de polímeros disponibles
  final List<String> _tiposPolimeros = [
    'Poli',
    'PP',
    'Multi'
  ];


  // Variables para la firma
  List<Offset?> _signaturePoints = [];
  bool _hasSignature = false;
  
  // Variables para la imagen
  File? _selectedImage;
  bool _hasImage = false;


  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _fuenteController.dispose();
    _pesoController.dispose();
    _condicionesController.dispose();
    _operadorController.dispose();
    _comentariosController.dispose();
    super.dispose();
  }

  void _showSignatureDialog() {
    List<Offset?> tempSignaturePoints = [];
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.edit, color: BioWayColors.ecoceGreen),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Firma del Operador',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: Container(
                width: MediaQuery.of(context).size.width * 0.95,
                height: 400,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: BioWayColors.ecoceGreen.withOpacity(0.5),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      GestureDetector(
                        onPanStart: (details) {
                          setDialogState(() {
                            tempSignaturePoints.add(details.localPosition);
                          });
                        },
                        onPanUpdate: (details) {
                          setDialogState(() {
                            tempSignaturePoints.add(details.localPosition);
                          });
                        },
                        onPanEnd: (details) {
                          tempSignaturePoints.add(null);
                        },
                        child: CustomPaint(
                          painter: SignaturePainter(tempSignaturePoints),
                          size: Size.infinite,
                        ),
                      ),
                      if (tempSignaturePoints.isEmpty)
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.draw,
                                color: Colors.grey.shade400,
                                size: 50,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Dibuja tu firma aquí',
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      tempSignaturePoints.clear();
                    });
                  },
                  child: Text(
                    'Limpiar',
                    style: TextStyle(color: BioWayColors.error),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: tempSignaturePoints.isNotEmpty
                      ? () {
                          setState(() {
                            _signaturePoints = List.from(tempSignaturePoints);
                            _hasSignature = true;
                          });
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Firma guardada correctamente'),
                              backgroundColor: BioWayColors.success,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BioWayColors.ecoceGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
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
                leading: Icon(Icons.camera_alt, color: BioWayColors.ecoceGreen),
                title: const Text('Tomar foto'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: BioWayColors.ecoceGreen),
                title: const Text('Seleccionar de galería'),
                onTap: () {
                  Navigator.pop(context);
                  _selectFromGallery();
                },
              ),
              if (_hasImage)
                ListTile(
                  leading: Icon(Icons.delete, color: BioWayColors.error),
                  title: const Text('Eliminar imagen'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedImage = null;
                      _hasImage = false;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _takePhoto() async {
    try {
      final File? photo = await ImageService.takePhoto();
      if (photo != null && mounted) {
        setState(() {
          _selectedImage = photo;
          _hasImage = true;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Foto capturada correctamente'),
              backgroundColor: BioWayColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error al acceder a la cámara'),
            backgroundColor: BioWayColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _selectFromGallery() async {
    try {
      final File? image = await ImageService.pickFromGallery();
      if (image != null && mounted) {
        setState(() {
          _selectedImage = image;
          _hasImage = true;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Imagen seleccionada correctamente'),
              backgroundColor: BioWayColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error al acceder a la galería'),
            backgroundColor: BioWayColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
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

  void _generarLote() {
    // Sin validaciones - Solo para diseño visual
    
    // Generar datos automáticos
    final String firebaseId = 'FID_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final DateTime fechaCreacion = DateTime.now();
    
    // Navegar a la pantalla de detalle con mensaje de éxito
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrigenLoteDetalleScreen(
          firebaseId: firebaseId,
          material: _tipoPolimeroSeleccionado ?? 'Poli',
          peso: double.tryParse(_pesoController.text) ?? 100,
          presentacion: _presentacionSeleccionada,
          fuente: _fuenteController.text.isEmpty ? 'Fuente de ejemplo' : _fuenteController.text,
          fechaCreacion: fechaCreacion,
          mostrarMensajeExito: true,
        ),
      ),
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
          'Crear Nuevo Lote',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
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
                  'Complete la información del nuevo lote',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Centro de Acopio - Origen',
                    style: TextStyle(
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
                    // Sección: Información del Material
                    _buildSectionCard(
                      icon: '📦',
                      title: 'Información del Material',
                      children: [
                        // Fuente del Material (hasta 50 caracteres)
                        _buildFieldLabel('Fuente del Material'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _fuenteController,
                          maxLength: 50,
                          decoration: _buildInputDecoration(
                            hintText: 'Ej: Programa Escolar Norte',
                          ),
                          // Sin validación para diseño visual
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Presentación del Material (selección con iconos)
                        _buildFieldLabel('Presentación del Material'),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildPresentacionOption(
                                svgPath: 'assets/images/icons/pacas.svg',
                                label: 'Pacas',
                                isSelected: _presentacionSeleccionada == 'Pacas',
                                onTap: () {
                                  setState(() {
                                    _presentacionSeleccionada = 'Pacas';
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildPresentacionOption(
                                svgPath: 'assets/images/icons/sacos.svg',
                                label: 'Sacos',
                                isSelected: _presentacionSeleccionada == 'Sacos',
                                onTap: () {
                                  setState(() {
                                    _presentacionSeleccionada = 'Sacos';
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Tipo de Polímero (lista desplegable)
                        _buildFieldLabel('Tipo de Polímero'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _tipoPolimeroSeleccionado,
                          decoration: _buildInputDecoration(
                            hintText: 'Selecciona el tipo de polímero',
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
                        _buildFieldLabel('Peso'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _pesoController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d{0,5}\.?\d{0,3}')),
                                ],
                                decoration: _buildInputDecoration(
                                  hintText: 'XXXXX.XXX',
                                ),
                                // Sin validación para diseño visual
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                              decoration: BoxDecoration(
                                color: BioWayColors.ecoceGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: BioWayColors.ecoceGreen.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'kg',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: BioWayColors.ecoceGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Condiciones del Material (hasta 100 caracteres)
                        _buildFieldLabel('Condiciones del Material'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _condicionesController,
                          maxLength: 100,
                          maxLines: 3,
                          decoration: _buildInputDecoration(
                            hintText: 'Describe el estado del material: limpieza, compactación, contaminación, etc.',
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Sección: Datos del Responsable
                    _buildSectionCard(
                      icon: '👤',
                      title: 'Datos del Responsable',
                      children: [
                        // Nombre del Operador (hasta 50 caracteres)
                        _buildFieldLabel('Nombre del Operador'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _operadorController,
                          maxLength: 50,
                          decoration: _buildInputDecoration(
                            hintText: 'Ingresa el nombre completo',
                          ),
                          // Sin validación para diseño visual
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Firma del Operador
                        _buildFieldLabel('Firma del Operador'),
                        const SizedBox(height: 8),
                        _buildSignatureArea(),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Sección: Evidencia Fotográfica
                    _buildSectionCard(
                      icon: '📷',
                      title: 'Evidencia Fotográfica',
                      children: [
                        _buildImageArea(),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Sección: Comentarios Adicionales
                    _buildSectionCard(
                      icon: '💬',
                      title: 'Comentarios',
                      children: [
                        TextFormField(
                          controller: _comentariosController,
                          maxLength: 150,
                          maxLines: 4,
                          decoration: _buildInputDecoration(
                            hintText: 'Ingresa comentarios adicionales (opcional)',
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
                        onPressed: _generarLote,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BioWayColors.ecoceGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 3,
                        ),
                        child: const Text(
                          'Generar Lote y Código QR',
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

  Widget _buildSectionCard({
    required String icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
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
          Row(
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: BioWayColors.darkGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: BioWayColors.textGrey,
      ),
    );
  }

  InputDecoration _buildInputDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: BioWayColors.backgroundGrey,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: BioWayColors.ecoceGreen.withOpacity(0.3),
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
    );
  }

  Widget _buildSignatureArea() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _hasSignature 
            ? Colors.white 
            : BioWayColors.backgroundGrey,
        border: Border.all(
          color: _hasSignature 
              ? BioWayColors.ecoceGreen 
              : BioWayColors.ecoceGreen.withOpacity(0.3),
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
                        width: MediaQuery.of(context).size.width * 0.95,
                        height: 400,
                        child: CustomPaint(
                          painter: SignaturePainter(_signaturePoints),
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
                            color: BioWayColors.success.withOpacity(0.1),
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
                            color: BioWayColors.ecoceGreen,
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
                      color: BioWayColors.ecoceGreen,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Firmar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: BioWayColors.ecoceGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImageArea() {
    return InkWell(
      onTap: _showImageOptions,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: BioWayColors.backgroundGrey,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hasImage
                ? BioWayColors.ecoceGreen
                : BioWayColors.ecoceGreen.withOpacity(0.3),
            width: _hasImage ? 2 : 1,
          ),
        ),
        child: _hasImage && _selectedImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: () {
                        // Mostrar imagen en pantalla completa
                        showDialog(
                          context: context,
                          builder: (context) => ImagePreviewDialog(
                            image: _selectedImage!,
                            title: 'Evidencia fotográfica',
                          ),
                        );
                      },
                      child: Image.file(
                        _selectedImage!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => ImagePreviewDialog(
                                    image: _selectedImage!,
                                    title: 'Evidencia fotográfica',
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.fullscreen,
                                color: Colors.grey,
                                size: 20,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: _showImageOptions,
                              icon: Icon(
                                Icons.edit,
                                color: BioWayColors.ecoceGreen,
                                size: 20,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo,
                    size: 50,
                    color: BioWayColors.ecoceGreen.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Agregar evidencia',
                    style: TextStyle(
                      fontSize: 16,
                      color: BioWayColors.ecoceGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Toca para tomar foto o seleccionar',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPresentacionOption({
    required String svgPath,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? BioWayColors.ecoceGreen.withOpacity(0.1) : BioWayColors.backgroundGrey,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? BioWayColors.ecoceGreen : BioWayColors.ecoceGreen.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            SvgPicture.asset(
              svgPath,
              width: 40,
              height: 40,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? BioWayColors.ecoceGreen : BioWayColors.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

}

// Painter para la firma
class SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) => true;
}