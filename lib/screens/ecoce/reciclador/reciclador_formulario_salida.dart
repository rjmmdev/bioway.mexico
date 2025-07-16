import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:ui' as ui;
import '../../../utils/colors.dart';
import '../../../services/image_service.dart';
import 'widgets/image_preview.dart';
import 'reciclador_documentacion.dart';

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
  
  // Controladores
  final TextEditingController _pesoRecibidoController = TextEditingController();
  final TextEditingController _operadorController = TextEditingController();
  final TextEditingController _comentariosController = TextEditingController();
  
  // Variables para cálculos
  double _mermaCalculada = 0.0;
  
  // Variables para la firma
  List<Offset?> _signaturePoints = [];
  bool _hasSignature = false;
  
  // Variables para la imagen
  File? _selectedImage;
  bool _hasImage = false;

  @override
  void initState() {
    super.initState();
    _pesoRecibidoController.addListener(_calcularMerma);
  }

  @override
  void dispose() {
    _pesoRecibidoController.removeListener(_calcularMerma);
    _pesoRecibidoController.dispose();
    _operadorController.dispose();
    _comentariosController.dispose();
    super.dispose();
  }

  void _calcularMerma() {
    final pesoRecibido = double.tryParse(_pesoRecibidoController.text) ?? 0.0;
    setState(() {
      _mermaCalculada = widget.pesoOriginal - pesoRecibido;
    });
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
                  const Text('Firma del Operador'),
                ],
              ),
              content: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: 300,
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
      if (photo != null) {
        setState(() {
          _selectedImage = photo;
          _hasImage = true;
        });
        
        // Mostrar mensaje de éxito
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
        
        // Mostrar tamaño de la imagen si es muy grande
        final double sizeInMB = ImageService.getImageSizeInMB(photo);
        if (sizeInMB > 5) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Nota: La imagen pesa ${sizeInMB}MB'),
              backgroundColor: BioWayColors.warning,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
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

  void _selectFromGallery() async {
    try {
      final File? image = await ImageService.pickFromGallery();
      if (image != null) {
        setState(() {
          _selectedImage = image;
          _hasImage = true;
        });
        
        // Mostrar mensaje de éxito
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
        
        // Mostrar tamaño de la imagen si es muy grande
        final double sizeInMB = ImageService.getImageSizeInMB(image);
        if (sizeInMB > 5) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Nota: La imagen pesa ${sizeInMB}MB'),
              backgroundColor: BioWayColors.warning,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
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

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (!_hasSignature) {
        _showErrorSnackBar('Por favor, agregue su firma');
        return;
      }
      
      if (!_hasImage) {
        _showErrorSnackBar('Por favor, agregue una evidencia fotográfica');
        return;
      }

      // Aquí iría la lógica para guardar los datos
      _showSuccessAndNavigate();
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
                  'Registra la salida del material',
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
                          
                          // Peso total recibido
                          Text(
                            'Peso total recibido',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: BioWayColors.textGrey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _pesoRecibidoController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d{0,5}\.?\d{0,3}')),
                                  ],
                                  decoration: InputDecoration(
                                    hintText: 'XXXXX.XXX',
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
                                  ),
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
                                  ? Colors.orange.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _mermaCalculada > 0
                                    ? Colors.orange.withOpacity(0.3)
                                    : Colors.grey.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${_mermaCalculada.toStringAsFixed(3)} kg',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _mermaCalculada > 0 ? Colors.orange : Colors.grey[700],
                                  ),
                                ),
                                Text(
                                  'Peso original: ${widget.pesoOriginal.toStringAsFixed(3)} kg',
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
                          Text(
                            'Nombre del Operador',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: BioWayColors.textGrey,
                            ),
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
                          Text(
                            'Firma del Operador',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: BioWayColors.textGrey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Área de visualización de firma o botón
                          Container(
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
                                          height: 200,
                                          width: double.infinity,
                                          color: Colors.white,
                                          child: FittedBox(
                                            fit: BoxFit.contain,
                                            alignment: Alignment.center,
                                            child: SizedBox(
                                              width: MediaQuery.of(context).size.width * 0.9,
                                              height: 300,
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
                                    child: Container(
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
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Tarjeta de Evidencia Fotográfica
                    Container(
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
                              const Text(
                                '📷',
                                style: TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Evidencia Fotográfica',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: BioWayColors.darkGreen,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          // Área de imagen
                          InkWell(
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
                                  style: _hasImage ? BorderStyle.solid : BorderStyle.solid,
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
                          ),
                        ],
                      ),
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
        ],
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