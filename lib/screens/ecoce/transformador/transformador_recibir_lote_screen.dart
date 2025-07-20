import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import '../../../utils/colors.dart';
import '../shared/widgets/signature_dialog.dart';
import '../shared/widgets/photo_evidence_widget.dart';
import '../shared/widgets/weight_input_widget.dart';
import '../shared/widgets/section_card.dart';
import '../shared/widgets/field_label.dart';
import 'transformador_lote_detalle_screen.dart';

class TransformadorRecibirLoteScreen extends StatefulWidget {
  const TransformadorRecibirLoteScreen({super.key});

  @override
  State<TransformadorRecibirLoteScreen> createState() => _TransformadorRecibirLoteScreenState();
}

class _TransformadorRecibirLoteScreenState extends State<TransformadorRecibirLoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final Color _primaryColor = BioWayColors.ecoceGreen;
  
  // Controladores
  final TextEditingController _pesoController = TextEditingController();
  final TextEditingController _operadorController = TextEditingController();
  final TextEditingController _comentariosController = TextEditingController();
  final TextEditingController _productoFabricadoController = TextEditingController();
  final TextEditingController _composicionMaterialController = TextEditingController();
  
  // Variable para el tipo de polímero
  String? _tipoPolimero;
  
  // Variables para los tipos de análisis
  final Map<String, bool> _tiposAnalisis = {
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
  bool _hasSignature = false;
  
  // Variables para las fotos
  List<File> _photos = [];
  
  // ScrollController
  final ScrollController _scrollController = ScrollController();
  
  // FocusNodes
  final FocusNode _operadorFocus = FocusNode();
  final FocusNode _comentariosFocus = FocusNode();
  final FocusNode _productoFocus = FocusNode();
  final FocusNode _composicionFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    
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
    _pesoController.dispose();
    _operadorController.dispose();
    _comentariosController.dispose();
    _productoFabricadoController.dispose();
    _composicionMaterialController.dispose();
    _scrollController.dispose();
    _operadorFocus.dispose();
    _comentariosFocus.dispose();
    _productoFocus.dispose();
    _composicionFocus.dispose();
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

  void _generarLote() {
    // Validar formulario
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Validar tipo de polímero
    if (_tipoPolimero == null || _tipoPolimero!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor seleccione el tipo de polímero'),
          backgroundColor: BioWayColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    
    // Validar que haya al menos un tipo de análisis seleccionado
    final analisisSeleccionados = _tiposAnalisis.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
    
    if (analisisSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor seleccione al menos un tipo de análisis'),
          backgroundColor: BioWayColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    
    // Validar firma
    if (!_hasSignature) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor capture la firma del responsable'),
          backgroundColor: BioWayColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
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
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    
    // Generar datos automáticos
    final String firebaseId = 'FID_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final DateTime fechaCreacion = DateTime.now();
    
    // Navegar a la pantalla de detalle
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransformadorLoteDetalleScreen(
          firebaseId: firebaseId,
          peso: double.tryParse(_pesoController.text) ?? 0,
          tiposAnalisis: analisisSeleccionados,
          productoFabricado: _productoFabricadoController.text,
          composicionMaterial: _composicionMaterialController.text,
          fechaCreacion: fechaCreacion,
          mostrarMensajeExito: true,
          tipoPolimero: _tipoPolimero,
        ),
      ),
    );
  }

  Widget _buildTiposAnalisisGrid() {
    final entries = _tiposAnalisis.entries.toList();
    
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
                  _tiposAnalisis[entry.key] = value ?? false;
                });
              },
              activeColor: _primaryColor,
            ),
            Expanded(
              child: Text(
                entry.key,
                style: const TextStyle(fontSize: 14),
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
      appBar: AppBar(
        backgroundColor: _primaryColor,
        elevation: 0,
        title: const Text(
          'Crear Nuevo Lote',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            // Sección de peso
            SectionCard(
              icon: '⚖️',
              title: 'Peso del Material',
              children: [
                WeightInputWidget(
                  controller: _pesoController,
                  label: 'Peso en kilogramos',
                  primaryColor: _primaryColor,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese el peso';
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
            
            // Sección de tipo de polímero
            SectionCard(
              icon: '🧬',
              title: 'Tipo de Polímero',
              children: [
                DropdownButtonFormField<String>(
                  value: _tipoPolimero,
                  decoration: InputDecoration(
                    hintText: 'Seleccione el tipo de polímero',
                    prefixIcon: Icon(
                      Icons.category,
                      color: _primaryColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey[300]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'PEBD',
                      child: Text('PEBD'),
                    ),
                    DropdownMenuItem(
                      value: 'PP',
                      child: Text('PP'),
                    ),
                    DropdownMenuItem(
                      value: 'Multilaminado',
                      child: Text('Multilaminado'),
                    ),
                  ],
                  onChanged: (String? newValue) {
                    setState(() {
                      _tipoPolimero = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor seleccione el tipo de polímero';
                    }
                    return null;
                  },
                ),
              ],
            ),
            
            // Sección de tipos de análisis
            SectionCard(
              icon: '🔬',
              title: 'Tipo de análisis realizado *',
              children: [
                _buildTiposAnalisisGrid(),
              ],
            ),
            
            // Sección de producto fabricado
            SectionCard(
              icon: '📦',
              title: 'Producto fabricado',
              children: [
                TextFormField(
                  controller: _productoFabricadoController,
                  focusNode: _productoFocus,
                  maxLength: 50,
                  decoration: InputDecoration(
                    hintText: 'Ej: Botellas PET',
                    counter: Text(
                      '${_productoFabricadoController.text.length}/50',
                      style: const TextStyle(fontSize: 12),
                    ),
                    prefixIcon: Icon(
                      Icons.inventory_2,
                      color: _primaryColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey[300]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese el producto fabricado';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {}); // Para actualizar el contador
                  },
                ),
              ],
            ),
            
            // Sección de composición del material
            SectionCard(
              icon: '🧪',
              title: 'Composición del material',
              children: [
                TextFormField(
                  controller: _composicionMaterialController,
                  focusNode: _composicionFocus,
                  maxLength: 100,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Describa la composición del material al 67%',
                    alignLabelWithHint: true,
                    counter: Text(
                      '${_composicionMaterialController.text.length}/100',
                      style: const TextStyle(fontSize: 12),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey[300]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor describa la composición del material';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {}); // Para actualizar el contador
                  },
                ),
              ],
            ),
            
            // Sección de datos del responsable
            SectionCard(
              icon: '👤',
              title: 'Datos del Responsable',
              children: [
                TextFormField(
                  controller: _operadorController,
                  focusNode: _operadorFocus,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Nombre del operador',
                    hintText: 'Ej: Juan Pérez',
                    prefixIcon: Icon(
                      Icons.person,
                      color: _primaryColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey[300]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _primaryColor,
                        width: 2,
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
                const SizedBox(height: 20),
                // Botón para firma
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FieldLabel(
                      text: 'Firma del responsable',
                      isRequired: true,
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _showSignatureDialog,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        height: 150,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _hasSignature
                                ? Colors.green
                                : Colors.grey[300]!,
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[50],
                        ),
                        child: Center(
                          child: _hasSignature
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      size: 48,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Firma capturada',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Toque para modificar',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.draw,
                                      size: 48,
                                      color: _primaryColor,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Toque para firmar',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: _primaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            // Sección de evidencia fotográfica
            SectionCard(
              icon: '📷',
              title: 'Evidencia Fotográfica',
              children: [
                PhotoEvidenceFormField(
                  onPhotosChanged: (photos) {
                    setState(() {
                      _photos = photos;
                    });
                  },
                  primaryColor: _primaryColor,
                  isRequired: true,
                ),
              ],
            ),
            
            // Sección de comentarios
            SectionCard(
              icon: '💬',
              title: 'Comentarios',
              children: [
                TextFormField(
                  controller: _comentariosController,
                  focusNode: _comentariosFocus,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Comentarios adicionales (opcional)',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey[300]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Botón de generar lote
            ElevatedButton(
              onPressed: _generarLote,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
              child: const Text(
                'Generar Lote y Código QR',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}