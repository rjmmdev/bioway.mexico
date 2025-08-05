import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../utils/colors.dart';
import '../../../../utils/ui_constants.dart';

/// Modelo optimizado para los datos del formulario común
class CommonFormData {
  // Datos básicos
  String tipoActor;
  String nombre = '';
  String rfc = '';
  String nombreContacto = '';
  String telContacto = '';
  String telEmpresa = '';
  String correoContacto = '';

  // Ubicación
  String calle = '';
  String numExt = '';
  String cp = '';
  String colonia = '';
  String ciudad = '';
  String estado = '';
  String refUbi = '';
  String linkMaps = '';
  String poligonoLoc = '';

  // Operativos
  Set<String> listaMateriales = <String>{}; // Cambiado a Set para mejor rendimiento
  bool transporte = false;
  String linkRedSocial = '';

  // Documentos
  Map<String, String?> documentos = {
    'const_sit_fis': null,
    'comp_domicilio': null,
    'banco_caratula': null,
    'ine': null,
  };

  // Credenciales
  String password = '';
  String confirmPassword = '';
  bool acceptTerms = false;

  CommonFormData({required this.tipoActor});

  // Método para validar si el formulario está completo
  bool get isBasicInfoValid =>
      nombre.isNotEmpty &&
          nombreContacto.isNotEmpty &&
          telContacto.isNotEmpty;

  bool get isLocationValid =>
      calle.isNotEmpty &&
          numExt.isNotEmpty &&
          cp.length == 5 &&
          colonia.isNotEmpty &&
          ciudad.isNotEmpty &&
          estado.isNotEmpty &&
          refUbi.isNotEmpty;

  bool get isOperationalValid =>
      listaMateriales.isNotEmpty;

  bool get isCredentialsValid =>
      correoContacto.isNotEmpty &&
          password.isNotEmpty &&
          confirmPassword.isNotEmpty &&
          password == confirmPassword &&
          acceptTerms;
}

/// Widget optimizado de formulario con campos comunes para todos los proveedores
class CommonFieldsForm extends StatefulWidget {
  final CommonFormData formData;
  final Function(CommonFormData) onDataChanged;
  final GlobalKey<FormState> formKey;

  // Banderas para mostrar solo secciones específicas (optimización)
  final bool showOnlyBasicInfo;
  final bool showOnlyLocationInfo;
  final bool showOnlyOperationalInfo;
  final bool showOnlyCredentialsAndDocuments;
  final bool showTransportField;

  const CommonFieldsForm({
    super.key,
    required this.formData,
    required this.onDataChanged,
    required this.formKey,
    this.showOnlyBasicInfo = false,
    this.showOnlyLocationInfo = false,
    this.showOnlyOperationalInfo = false,
    this.showOnlyCredentialsAndDocuments = false,
    this.showTransportField = true,
  });

  @override
  State<CommonFieldsForm> createState() => _CommonFieldsFormState();
}

class _CommonFieldsFormState extends State<CommonFieldsForm> {
  // Controladores optimizados - solo se crean los necesarios
  late final Map<String, TextEditingController> _controllers;

  // Estados
  bool _isSearchingCP = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Lista de materiales disponibles - constante para mejor memoria
  static const List<String> _availableMaterials = [
    'PET',
    'HDPE',
    'PP',
    'LDPE',
    'PS',
    'PVC',
    'Otros plásticos',
    'Cartón',
    'Papel',
    'Vidrio',
    'Metal',
    'Aluminio',
  ];

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _controllers = {
      if (widget.showOnlyBasicInfo || !_isStepSpecific()) ...{
        'nombre': TextEditingController(text: widget.formData.nombre),
        'rfc': TextEditingController(text: widget.formData.rfc),
        'nombreContacto': TextEditingController(text: widget.formData.nombreContacto),
        'telContacto': TextEditingController(text: widget.formData.telContacto),
        'telEmpresa': TextEditingController(text: widget.formData.telEmpresa),
      },
      if (widget.showOnlyLocationInfo || !_isStepSpecific()) ...{
        'calle': TextEditingController(text: widget.formData.calle),
        'numExt': TextEditingController(text: widget.formData.numExt),
        'cp': TextEditingController(text: widget.formData.cp),
        'colonia': TextEditingController(text: widget.formData.colonia),
        'ciudad': TextEditingController(text: widget.formData.ciudad),
        'estado': TextEditingController(text: widget.formData.estado),
        'refUbi': TextEditingController(text: widget.formData.refUbi),
      },
      if (widget.showOnlyOperationalInfo || !_isStepSpecific()) ...{
        'linkRedSocial': TextEditingController(text: widget.formData.linkRedSocial),
      },
      if (widget.showOnlyCredentialsAndDocuments || !_isStepSpecific()) ...{
        'correoContacto': TextEditingController(text: widget.formData.correoContacto),
        'password': TextEditingController(text: widget.formData.password),
        'confirmPassword': TextEditingController(text: widget.formData.confirmPassword),
      },
    };

    // Agregar listeners solo a los controladores necesarios
    _controllers.forEach((key, controller) {
      controller.addListener(() => _updateFormData(key, controller.text));
    });
  }

  bool _isStepSpecific() {
    return widget.showOnlyBasicInfo ||
        widget.showOnlyLocationInfo ||
        widget.showOnlyOperationalInfo ||
        widget.showOnlyCredentialsAndDocuments;
  }

  void _updateFormData(String field, String value) {
    switch (field) {
      case 'nombre':
        widget.formData.nombre = value;
        break;
      case 'rfc':
        widget.formData.rfc = value;
        break;
      case 'nombreContacto':
        widget.formData.nombreContacto = value;
        break;
      case 'telContacto':
        widget.formData.telContacto = value;
        break;
      case 'telEmpresa':
        widget.formData.telEmpresa = value;
        break;
      case 'calle':
        widget.formData.calle = value;
        break;
      case 'numExt':
        widget.formData.numExt = value;
        break;
      case 'cp':
        widget.formData.cp = value;
        if (value.length == 5) {
          _searchCP(value);
        }
        break;
      case 'colonia':
        widget.formData.colonia = value;
        break;
      case 'ciudad':
        widget.formData.ciudad = value;
        break;
      case 'estado':
        widget.formData.estado = value;
        break;
      case 'refUbi':
        widget.formData.refUbi = value;
        break;
      case 'linkRedSocial':
        widget.formData.linkRedSocial = value;
        break;
      case 'correoContacto':
        widget.formData.correoContacto = value;
        break;
      case 'password':
        widget.formData.password = value;
        break;
      case 'confirmPassword':
        widget.formData.confirmPassword = value;
        break;
    }
    widget.onDataChanged(widget.formData);
  }

  Future<void> _searchCP(String cp) async {
    setState(() {
      _isSearchingCP = true;
    });

    // Simular búsqueda de código postal
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isSearchingCP = false;
        // Simular datos encontrados
        if (_controllers['colonia'] != null) {
          _controllers['colonia']!.text = 'Centro';
          widget.formData.colonia = 'Centro';
        }
        if (_controllers['ciudad'] != null) {
          _controllers['ciudad']!.text = 'Querétaro';
          widget.formData.ciudad = 'Querétaro';
        }
        if (_controllers['estado'] != null) {
          _controllers['estado']!.text = 'Querétaro';
          widget.formData.estado = 'Querétaro';
        }
      });
      widget.onDataChanged(widget.formData);
    }
  }

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }@override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showOnlyBasicInfo || !_isStepSpecific())
            _buildBasicInfoSection(),
          if (widget.showOnlyLocationInfo || !_isStepSpecific())
            _buildLocationSection(),
          if (widget.showOnlyOperationalInfo || !_isStepSpecific())
            _buildOperationalSection(),
          if (widget.showOnlyCredentialsAndDocuments || !_isStepSpecific())
            _buildCredentialsSection(),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepTitle('Información Básica', 'Datos principales de tu centro de acopio'),
        SizedBox(height: UIConstants.spacing32),

        // Nombre Comercial
        _buildTextField(
          controller: _controllers['nombre']!,
          label: 'Nombre Comercial *',
          hint: 'Ej: Centro de Acopio San Juan',
          icon: Icons.business,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'El nombre comercial es obligatorio';
            }
            return null;
          },
        ),
        SizedBox(height: UIConstants.spacing20),

        // RFC (Opcional)
        _buildTextField(
          controller: _controllers['rfc']!,
          label: 'RFC (Opcional)',
          hint: 'XXXX000000XXX',
          icon: Icons.article,
          helperText: 'Tienes 30 días para proporcionarlo',
          inputFormatters: [
            LengthLimitingTextInputFormatter(13),
            FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
            TextInputFormatter.withFunction((oldValue, newValue) {
              return newValue.copyWith(text: newValue.text.toUpperCase());
            }),
          ],
        ),
        SizedBox(height: UIConstants.spacing20),

        // Nombre del Contacto
        _buildTextField(
          controller: _controllers['nombreContacto']!,
          label: 'Nombre del Contacto *',
          hint: 'Nombre completo',
          icon: Icons.person,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'El nombre del contacto es obligatorio';
            }
            return null;
          },
        ),
        SizedBox(height: UIConstants.spacing20),

        // Teléfonos en fila
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _controllers['telContacto']!,
                label: 'Teléfono Móvil *',
                hint: '10 dígitos',
                icon: Icons.phone_android,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(15),
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Teléfono obligatorio';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: UIConstants.spacing12),
            Expanded(
              child: _buildTextField(
                controller: _controllers['telEmpresa']!,
                label: 'Teléfono Oficina',
                hint: 'Opcional',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(15),
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]')),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepTitle('Ubicación', 'Dirección de tu centro de acopio'),
        SizedBox(height: UIConstants.spacing32),

        // Código Postal con búsqueda
        _buildCPSection(),
        SizedBox(height: UIConstants.spacing24),

        // Dirección - Calle y Número
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildTextField(
                controller: _controllers['calle']!,
                label: 'Nombre de calle *',
                hint: 'Ej: Av. Universidad',
                icon: Icons.home,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La calle es obligatoria';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: UIConstants.spacing12),
            Expanded(
              child: _buildTextField(
                controller: _controllers['numExt']!,
                label: 'Núm. Exterior *',
                hint: '123',
                icon: Icons.numbers,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Número obligatorio';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        SizedBox(height: UIConstants.spacing20),

        // Colonia
        _buildTextField(
          controller: _controllers['colonia']!,
          label: 'Colonia *',
          hint: 'Nombre de la colonia',
          icon: Icons.location_city,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'La colonia es obligatoria';
            }
            return null;
          },
        ),
        SizedBox(height: UIConstants.spacing20),

        // Ciudad y Estado en fila
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _controllers['ciudad']!,
                label: 'Ciudad *',
                hint: 'Ciudad',
                icon: Icons.location_city,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La ciudad es obligatoria';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: UIConstants.spacing12),
            Expanded(
              child: _buildTextField(
                controller: _controllers['estado']!,
                label: 'Estado *',
                hint: 'Estado',
                icon: Icons.map,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El estado es obligatorio';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        SizedBox(height: UIConstants.spacing24),

        // Referencias de ubicación
        _buildTextField(
          controller: _controllers['refUbi']!,
          label: 'Referencias de ubicación *',
          hint: 'Ej: Frente a la iglesia, entrada lateral',
          icon: Icons.near_me,
          maxLines: 3,
          maxLength: 150,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Las referencias son obligatorias';
            }
            return null;
          },
        ),
        SizedBox(height: UIConstants.spacing24),

        // Vista previa del mapa
        _buildMapPreview(),
      ],
    );
  }

  Widget _buildOperationalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepTitle('Información Operativa', 'Materiales y servicios'),
        SizedBox(height: UIConstants.spacing32),

        // Selección de materiales
        _buildMaterialsSection(),
        SizedBox(height: UIConstants.spacing24),

        // Transporte propio
        if (widget.showTransportField) _buildTransportSection(),
        if (widget.showTransportField) SizedBox(height: UIConstants.spacing24),

        // Link de red social (opcional)
        _buildTextField(
          controller: _controllers['linkRedSocial']!,
          label: 'Página web o red social (opcional)',
          hint: 'https://www.ejemplo.com',
          icon: Icons.language,
          keyboardType: TextInputType.url,
        ),
      ],
    );
  }

  Widget _buildCredentialsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepTitle('Credenciales de Acceso', 'Correo, contraseña y términos'),
        SizedBox(height: UIConstants.spacing32),

        // Sección de credenciales
        _buildCredentialsContainer(),
        SizedBox(height: UIConstants.spacing24),

        // Documentos fiscales opcionales
        _buildDocumentsSection(),
        SizedBox(height: UIConstants.spacing24),

        // Términos y condiciones
        _buildTermsSection(),
      ],
    );
  }

  Widget _buildStepTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: UIConstants.fontSizeTitle,
            fontWeight: FontWeight.bold,
            color: BioWayColors.darkGreen,
          ),
        ),
        SizedBox(height: UIConstants.spacing4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: UIConstants.fontSizeMedium,
            color: BioWayColors.textGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? helperText,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
    int maxLines = 1,
    int? maxLength,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      inputFormatters: inputFormatters,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      obscureText: obscureText,
      textCapitalization: maxLines == 1
          ? TextCapitalization.words
          : TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        prefixIcon: Icon(icon, color: BioWayColors.petBlue),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: BioWayColors.lightGrey.withValues(alpha: UIConstants.opacityMediumHigh),
        border: OutlineInputBorder(
          borderRadius: BorderRadiusConstants.borderRadiusMedium,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadiusConstants.borderRadiusMedium,
          borderSide: const BorderSide(
            color: BioWayColors.lightGrey,
            width: UIConstants.borderWidthThin,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadiusConstants.borderRadiusMedium,
          borderSide: const BorderSide(
            color: BioWayColors.petBlue,
            width: UIConstants.borderWidthThick - 0.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadiusConstants.borderRadiusMedium,
          borderSide: const BorderSide(
            color: BioWayColors.error,
            width: UIConstants.borderWidthThin,
          ),
        ),
        counterText: maxLength != null ? '' : null,
      ),
    );
  }Widget _buildCPSection() {
    return Container(
      padding: EdgeInsetsConstants.paddingAll20,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            BioWayColors.petBlue.withValues(alpha: UIConstants.opacityVeryLow),
            BioWayColors.petBlue.withValues(alpha: UIConstants.opacityVeryLow - 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadiusConstants.borderRadiusLarge,
        border: Border.all(
          color: BioWayColors.petBlue.withValues(alpha: UIConstants.opacityMediumLow),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.pin_drop,
                color: BioWayColors.petBlue,
                size: UIConstants.iconSizeMedium,
              ),
              SizedBox(width: UIConstants.spacing8),
              const Text(
                'Código Postal',
                style: TextStyle(
                  fontSize: UIConstants.fontSizeBody,
                  fontWeight: FontWeight.bold,
                  color: BioWayColors.darkGreen,
                ),
              ),
            ],
          ),
          SizedBox(height: UIConstants.spacing8),
          const Text(
            'Ingresa tu código postal para facilitar la búsqueda',
            style: TextStyle(
              fontSize: UIConstants.fontSizeMedium,
              color: BioWayColors.textGrey,
            ),
          ),
          SizedBox(height: UIConstants.spacing16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _controllers['cp']!,
                  keyboardType: TextInputType.number,
                  maxLength: 5,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(5),
                  ],
                  decoration: InputDecoration(
                    hintText: '00000',
                    counterText: '',
                    prefixIcon: const Icon(
                      Icons.location_searching,
                      color: BioWayColors.petBlue,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadiusConstants.borderRadiusMedium,
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadiusConstants.borderRadiusMedium,
                      borderSide: const BorderSide(
                        color: BioWayColors.lightGrey,
                        width: UIConstants.borderWidthThin,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadiusConstants.borderRadiusMedium,
                      borderSide: const BorderSide(
                        color: BioWayColors.petBlue,
                        width: UIConstants.borderWidthThick - 0.5,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.length != 5) {
                      return 'Ingresa un CP válido (5 dígitos)';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(width: UIConstants.spacing12),
              AnimatedContainer(
                duration: Duration(milliseconds: UIConstants.animationDurationMedium),
                width: _isSearchingCP ? UIConstants.iconContainerSmall : 0,
                child: _isSearchingCP
                    ? const CircularProgressIndicator(
                  strokeWidth: UIConstants.borderWidthThick - 0.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    BioWayColors.petBlue,
                  ),
                )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMapPreview() {
    return Container(
      height: UIConstants.qrSizeMedium,
      decoration: BoxDecoration(
        color: BioWayColors.lightGrey.withValues(alpha: UIConstants.opacityMedium),
        borderRadius: BorderRadiusConstants.borderRadiusLarge,
        border: Border.all(
          color: BioWayColors.lightGrey,
          width: UIConstants.borderWidthThin,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadiusConstants.borderRadiusLarge,
        child: Stack(
          children: [
            // Placeholder del mapa
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey.shade200,
                    Colors.grey.shade300,
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map,
                      size: UIConstants.iconSizeXLarge,
                      color: Colors.grey.shade400,
                    ),
                    SizedBox(height: UIConstants.spacing8),
                    Text(
                      widget.formData.cp.length == 5
                          ? 'Mapa de la zona ${widget.formData.cp}'
                          : 'El mapa se mostrará al ingresar el CP',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: UIConstants.fontSizeMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Botón de ubicación exacta
            if (widget.formData.cp.length == 5)
              Positioned(
                bottom: 16,
                right: 16,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Aquí se abriría el mapa completo
                  },
                  icon: const Icon(Icons.my_location, size: 18),
                  label: const Text('Ubicación exacta'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BioWayColors.petBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadiusConstants.borderRadiusXLarge,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialsSection() {
    return Container(
      padding: EdgeInsetsConstants.paddingAll20,
      decoration: BoxDecoration(
        color: BioWayColors.lightGrey.withValues(alpha: UIConstants.opacityMedium),
        borderRadius: BorderRadiusConstants.borderRadiusLarge,
        border: Border.all(
          color: BioWayColors.lightGrey,
          width: UIConstants.borderWidthThin,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.recycling,
                color: BioWayColors.petBlue,
                size: UIConstants.iconSizeMedium,
              ),
              SizedBox(width: UIConstants.spacing8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Materiales que recibes *',
                      style: TextStyle(
                        fontSize: UIConstants.fontSizeBody,
                        fontWeight: FontWeight.bold,
                        color: BioWayColors.darkGreen,
                      ),
                    ),
                    Text(
                      'Selecciona todos los tipos de materiales',
                      style: TextStyle(
                        fontSize: UIConstants.fontSizeSmall - 1,
                        color: BioWayColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: UIConstants.spacing16),

          // Grid optimizado de materiales usando Wrap para mejor responsive
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableMaterials.map((material) {
              final isSelected = widget.formData.listaMateriales.contains(material);
              return FilterChip(
                label: Text(material),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      widget.formData.listaMateriales.add(material);
                    } else {
                      widget.formData.listaMateriales.remove(material);
                    }
                  });
                  widget.onDataChanged(widget.formData);
                },
                selectedColor: BioWayColors.petBlue.withValues(alpha: 0.2),
                checkmarkColor: BioWayColors.petBlue,
                labelStyle: TextStyle(
                  color: isSelected
                      ? BioWayColors.petBlue
                      : BioWayColors.darkGreen,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),

          if (widget.formData.listaMateriales.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: UIConstants.spacing8),
              child: Text(
                'Debes seleccionar al menos un tipo de material',
                style: TextStyle(
                  color: BioWayColors.error,
                  fontSize: UIConstants.fontSizeSmall - 1,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTransportSection() {
    return Container(
      padding: EdgeInsetsConstants.paddingAll20,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadiusConstants.borderRadiusLarge,
        border: Border.all(
          color: BioWayColors.lightGrey,
          width: UIConstants.borderWidthThin,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.local_shipping,
                      color: BioWayColors.petBlue,
                      size: UIConstants.iconSizeMedium,
                    ),
                    SizedBox(width: UIConstants.spacing8),
                    const Text(
                      '¿Cuentas con transporte propio?',
                      style: TextStyle(
                        fontSize: UIConstants.fontSizeBody,
                        fontWeight: FontWeight.bold,
                        color: BioWayColors.darkGreen,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: UIConstants.spacing4),
                const Text(
                  'Para recolección de materiales',
                  style: TextStyle(
                    fontSize: UIConstants.fontSizeMedium,
                    color: BioWayColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: widget.formData.transporte,
            onChanged: (value) {
              setState(() {
                widget.formData.transporte = value;
              });
              widget.onDataChanged(widget.formData);
            },
            activeColor: BioWayColors.petBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialsContainer() {
    return Container(
      padding: EdgeInsetsConstants.paddingAll20,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadiusConstants.borderRadiusLarge,
        border: Border.all(
          color: BioWayColors.lightGrey,
          width: UIConstants.borderWidthThin,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_circle,
                color: BioWayColors.petBlue,
                size: UIConstants.iconSizeMedium,
              ),
              SizedBox(width: UIConstants.spacing8),
              const Text(
                'Datos de Acceso',
                style: TextStyle(
                  fontSize: UIConstants.fontSizeBody,
                  fontWeight: FontWeight.bold,
                  color: BioWayColors.darkGreen,
                ),
              ),
            ],
          ),
          SizedBox(height: UIConstants.spacing16),

          // Correo electrónico
          _buildTextField(
            controller: _controllers['correoContacto']!,
            label: 'Correo electrónico *',
            hint: 'ejemplo@correo.com',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'El correo es obligatorio';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Ingresa un correo válido';
              }
              return null;
            },
          ),
          SizedBox(height: UIConstants.spacing16),

          // Contraseña
          _buildTextField(
            controller: _controllers['password']!,
            label: 'Contraseña *',
            hint: 'Mínimo 6 caracteres',
            icon: Icons.lock,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                color: BioWayColors.textGrey,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'La contraseña es obligatoria';
              }
              if (value.length < 6) {
                return 'Mínimo 6 caracteres';
              }
              return null;
            },
          ),
          SizedBox(height: UIConstants.spacing16),

          // Confirmar contraseña
          _buildTextField(
            controller: _controllers['confirmPassword']!,
            label: 'Confirmar contraseña *',
            hint: 'Repite tu contraseña',
            icon: Icons.lock_outline,
            obscureText: _obscureConfirmPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                color: BioWayColors.textGrey,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Confirma tu contraseña';
              }
              if (value != widget.formData.password) {
                return 'Las contraseñas no coinciden';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection() {
    return Container(
      padding: EdgeInsetsConstants.paddingAll20,
      decoration: BoxDecoration(
        color: BioWayColors.lightGrey.withValues(alpha: UIConstants.opacityMedium),
        borderRadius: BorderRadiusConstants.borderRadiusLarge,
        border: Border.all(
          color: BioWayColors.lightGrey,
          width: UIConstants.borderWidthThin,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.folder_open,
                color: BioWayColors.petBlue,
                size: UIConstants.iconSizeMedium,
              ),
              SizedBox(width: UIConstants.spacing8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Documentos Fiscales',
                    style: TextStyle(
                      fontSize: UIConstants.fontSizeBody,
                      fontWeight: FontWeight.bold,
                      color: BioWayColors.darkGreen,
                    ),
                  ),
                  Text(
                    'Opcional - Puedes subirlos después',
                    style: TextStyle(
                      fontSize: UIConstants.fontSizeSmall - 1,
                      color: BioWayColors.textGrey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: UIConstants.spacing16),

          // Lista de documentos
          _buildDocumentUpload(
            'Constancia de Situación Fiscal',
            'const_sit_fis',
            Icons.description,
          ),
          SizedBox(height: UIConstants.spacing12),
          _buildDocumentUpload(
            'Comprobante de Domicilio',
            'comp_domicilio',
            Icons.home_work,
          ),
          SizedBox(height: UIConstants.spacing12),
          _buildDocumentUpload(
            'Carátula de Estado de Cuenta',
            'banco_caratula',
            Icons.account_balance,
          ),
          SizedBox(height: UIConstants.spacing12),
          _buildDocumentUpload(
            'INE/Identificación Oficial',
            'ine',
            Icons.badge,
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentUpload(String title, String key, IconData icon) {
    final hasFile = widget.formData.documentos[key] != null;

    return InkWell(
      onTap: () {
        setState(() {
          widget.formData.documentos[key] = hasFile ? null : '$title.pdf';
        });
        widget.onDataChanged(widget.formData);
      },
      borderRadius: BorderRadiusConstants.borderRadiusMedium,
      child: Container(
        padding: EdgeInsetsConstants.paddingAll12,
        decoration: BoxDecoration(
          color: hasFile
              ? BioWayColors.success.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadiusConstants.borderRadiusMedium,
          border: Border.all(
            color: hasFile
                ? BioWayColors.success
                : BioWayColors.lightGrey,
            width: UIConstants.borderWidthThin,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: hasFile ? BioWayColors.success : BioWayColors.textGrey,
              size: 24,
            ),
            SizedBox(width: UIConstants.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: UIConstants.fontSizeMedium,
                      fontWeight: hasFile ? FontWeight.bold : FontWeight.normal,
                      color: hasFile ? BioWayColors.success : BioWayColors.darkGreen,
                    ),
                  ),
                  Text(
                    hasFile ? widget.formData.documentos[key]! : 'Toca para seleccionar archivo PDF',
                    style: const TextStyle(
                      fontSize: UIConstants.fontSizeSmall - 1,
                      color: BioWayColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              hasFile ? Icons.check_circle : Icons.upload_file,
              color: hasFile ? BioWayColors.success : BioWayColors.textGrey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsSection() {
    return Container(
      padding: EdgeInsetsConstants.paddingAll20,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            BioWayColors.petBlue.withValues(alpha: UIConstants.opacityVeryLow),
            BioWayColors.petBlue.withValues(alpha: UIConstants.opacityVeryLow - 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadiusConstants.borderRadiusLarge,
        border: Border.all(
          color: BioWayColors.petBlue.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.gavel,
                color: BioWayColors.petBlue,
                size: UIConstants.iconSizeMedium,
              ),
              SizedBox(width: UIConstants.spacing8),
              const Text(
                'Términos y Condiciones',
                style: TextStyle(
                  fontSize: UIConstants.fontSizeBody,
                  fontWeight: FontWeight.bold,
                  color: BioWayColors.darkGreen,
                ),
              ),
            ],
          ),
          SizedBox(height: UIConstants.spacing16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: widget.formData.acceptTerms,
                onChanged: (value) {
                  setState(() {
                    widget.formData.acceptTerms = value ?? false;
                  });
                  widget.onDataChanged(widget.formData);
                },
                activeColor: BioWayColors.petBlue,
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: UIConstants.spacing12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'He leído y acepto los términos y condiciones de uso y el aviso de privacidad de ECOCE.',
                        style: TextStyle(
                          fontSize: UIConstants.fontSizeMedium,
                          color: BioWayColors.darkGreen,
                        ),
                      ),
                      SizedBox(height: UIConstants.spacing8),
                      Wrap(
                        spacing: 16,
                        children: [
                          TextButton(
                            onPressed: () {
                              // Abrir términos y condiciones
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Ver términos y condiciones',
                              style: TextStyle(
                                color: BioWayColors.petBlue,
                                fontSize: UIConstants.fontSizeSmall - 1,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // Abrir aviso de privacidad
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Ver aviso de privacidad',
                              style: TextStyle(
                                color: BioWayColors.petBlue,
                                fontSize: UIConstants.fontSizeSmall - 1,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}