import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';
import '../../../utils/colors.dart';
import 'origen_config.dart';
import '../shared/widgets/signature_dialog.dart';
import '../shared/widgets/photo_evidence_widget.dart';
import 'origen_lote_detalle_screen.dart';

class OrigenCrearLoteScreen extends StatefulWidget {
  const OrigenCrearLoteScreen({super.key});

  @override
  State<OrigenCrearLoteScreen> createState() => _OrigenCrearLoteScreenState();
}

class _OrigenCrearLoteScreenState extends State<OrigenCrearLoteScreen> {
  final _formKey = GlobalKey<FormState>();

  Color get _primaryColor => OrigenUserConfig.current.color;
  
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
    'PEBD',
    'PP',
    'Multilaminado'
  ];


  // Variables para la firma
  List<Offset?> _signaturePoints = [];
  bool _hasSignature = false;
  

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

  // Sección de foto ahora manejada por PhotoEvidenceFormField del módulo shared

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
      ),
      body: Column(
        children: [
          // Header verde
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: _primaryColor,
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
                                color: _primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _primaryColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'kg',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _primaryColor,
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
                    PhotoEvidenceFormField(
                      title: 'Evidencia Fotográfica',
                      maxPhotos: 1,
                      minPhotos: 0,
                      onPhotosChanged: (_) {},
                      primaryColor: _primaryColor,
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
                          backgroundColor: _primaryColor,
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
          color: _primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: _primaryColor,
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
              ? _primaryColor 
              : _primaryColor.withOpacity(0.3),
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
          color: isSelected ? _primaryColor.withOpacity(0.1) : BioWayColors.backgroundGrey,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _primaryColor : _primaryColor.withOpacity(0.3),
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
                color: isSelected ? _primaryColor : BioWayColors.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

}