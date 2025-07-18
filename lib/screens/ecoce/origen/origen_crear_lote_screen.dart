import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';
import 'dart:async';
import '../../../utils/colors.dart';
import 'origen_config.dart';
import '../shared/widgets/signature_dialog.dart';
import '../shared/widgets/photo_evidence_widget.dart';
import '../shared/widgets/weight_input_widget.dart';
import '../shared/widgets/section_card.dart';
import '../shared/widgets/field_label.dart';
import '../shared/utils/material_utils.dart';
import 'origen_lote_detalle_screen.dart';

class OrigenCrearLoteScreen extends StatefulWidget {
  const OrigenCrearLoteScreen({super.key});

  @override
  State<OrigenCrearLoteScreen> createState() => _OrigenCrearLoteScreenState();
}

class _OrigenCrearLoteScreenState extends State<OrigenCrearLoteScreen> {
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

  // Variables para los selectores
  String? _tipoPolimeroSeleccionado;
  String _presentacionSeleccionada = 'Pacas';
  String? _fuenteMaterialSeleccionada;

  // Variables para la firma
  List<Offset?> _signaturePoints = [];
  bool _hasSignature = false;
  

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
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
          fuente: _fuenteMaterialSeleccionada ?? 'Fuente no especificada',
          fechaCreacion: fechaCreacion,
          mostrarMensajeExito: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final horizontalPadding = screenWidth * 0.03; // 3% del ancho de pantalla
    final verticalPadding = screenHeight * 0.02; // 2% del alto de pantalla
    
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
        resizeToAvoidBottomInset: false,
        body: Column(
        children: [
          // Header verde
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            decoration: BoxDecoration(
              color: _primaryColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(screenWidth * 0.08),
                bottomRight: Radius.circular(screenWidth * 0.08),
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
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.03,
                    vertical: screenHeight * 0.008,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(screenWidth * 0.05),
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
              physics: const ClampingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding * 0.8,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Sección: Información del Material
                    SectionCard(
                      icon: '📦',
                      title: 'Información del Material',
                      children: [
                        // Fuente del Material
                        const FieldLabel(text: 'Fuente del Material'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _fuenteMaterialSeleccionada,
                          decoration: _buildInputDecoration(
                            hintText: 'Selecciona la fuente del material',
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
                                      color: _primaryColor.withOpacity(0.7),
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
                        const FieldLabel(text: 'Presentación del Material'),
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
                                    });
                                  }
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
                                  if (_presentacionSeleccionada != 'Sacos') {
                                    setState(() {
                                      _presentacionSeleccionada = 'Sacos';
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Tipo de Polímero (lista desplegable)
                        const FieldLabel(text: 'Tipo de Polímero'),
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
                        WeightInputWidget(
                          controller: _pesoController,
                          label: 'Peso del Material',
                          primaryColor: _primaryColor,
                          quickAddValues: const [100, 250, 500, 1000],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Condiciones del Material (hasta 100 caracteres)
                        const FieldLabel(text: 'Condiciones del Material'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _condicionesController,
                          maxLength: 100,
                          maxLines: 3,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          decoration: _buildInputDecoration(
                            hintText: 'Describe el estado del material: limpieza, compactación, contaminación, etc.',
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Sección: Datos del Responsable
                    SectionCard(
                      icon: '👤',
                      title: 'Datos del Responsable',
                      children: [
                        // Nombre del Operador (hasta 50 caracteres)
                        const FieldLabel(text: 'Nombre del Operador'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _operadorController,
                          maxLength: 50,
                          keyboardType: TextInputType.name,
                          textInputAction: TextInputAction.next,
                          decoration: _buildInputDecoration(
                            hintText: 'Ingresa el nombre completo',
                          ),
                          // Sin validación para diseño visual
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Firma del Operador
                        const FieldLabel(text: 'Firma del Operador'),
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
                    SectionCard(
                      icon: '💬',
                      title: 'Comentarios',
                      children: [
                        TextFormField(
                          controller: _comentariosController,
                          maxLength: 150,
                          maxLines: 4,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
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
                    // Espacio adicional para el teclado
                    SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }



  // Caché para las decoraciones de input
  final Map<String, InputDecoration> _inputDecorationCache = {};

  InputDecoration _buildInputDecoration({required String hintText}) {
    // Revisar si ya existe en caché
    if (_inputDecorationCache.containsKey(hintText)) {
      return _inputDecorationCache[hintText]!;
    }
    
    final screenWidth = MediaQuery.of(context).size.width;
    final borderRadius = BorderRadius.circular(12);
    
    final decoration = InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        fontSize: 14,
        color: Colors.grey,
      ),
      filled: true,
      fillColor: BioWayColors.backgroundGrey,
      border: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(
          color: _primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(
          color: _primaryColor,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(
          color: Colors.red,
          width: 2,
        ),
      ),
      counterText: '',
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    );
    
    // Guardar en caché
    _inputDecorationCache[hintText] = decoration;
    return decoration;
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
    final screenWidth = MediaQuery.of(context).size.width;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: screenWidth * 0.05),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor.withOpacity(0.1) : BioWayColors.backgroundGrey,
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          border: Border.all(
            color: isSelected ? _primaryColor : _primaryColor.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              svgPath,
              width: screenWidth * 0.1,
              height: screenWidth * 0.1,
              colorFilter: ColorFilter.mode(
                isSelected ? _primaryColor : BioWayColors.textGrey,
                BlendMode.srcIn,
              ),
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