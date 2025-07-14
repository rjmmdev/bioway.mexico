import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/colors.dart';

class ECOCERegisterScreen extends StatefulWidget {
  const ECOCERegisterScreen({super.key});

  @override
  State<ECOCERegisterScreen> createState() => _ECOCERegisterScreenState();
}

class _ECOCERegisterScreenState extends State<ECOCERegisterScreen>
    with TickerProviderStateMixin {
  // Controladores
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  late AnimationController _headerController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;

  // Estados
  int _currentPage = 0;
  final int _totalPages = 3;

  // Form keys para cada paso
  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();
  final _formKeyStep3 = GlobalKey<FormState>();

  // Controladores de los campos
  final _companyNameController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _cpController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Estados del formulario
  String? _selectedCompanyType;
  String? _selectedMaterialTypes;
  bool _acceptedTerms = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Opciones para empresa
  final List<String> _companyTypes = [
    'Empresa de Reciclaje',
    'Centro de Acopio',
    'Cooperativa',
    'Asociación Civil',
    'Persona Física con Actividad Empresarial',
    'Institución Educativa',
    'Dependencia Gubernamental',
    'Otro',
  ];

  // Tipos de materiales que maneja
  final List<String> _materialOptions = [
    'PET (Botellas de Plástico)',
    'HDPE (Plásticos Duros)',
    'PP (Polipropileno)',
    'Vidrio',
    'Aluminio',
    'Cartón',
    'Papel',
    'Textiles',
    'Electrónicos',
    'Metales Ferrosos',
    'Otros Materiales',
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOut),
    );

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutCubic,
    ));
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _headerController.forward();
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _headerController.dispose();
    _pageController.dispose();
    // Dispose all controllers
    _companyNameController.dispose();
    _taxIdController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _cpController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _navigateBack() {
    HapticFeedback.lightImpact();
    Navigator.pop(context);
  }

  Future<void> _register() async {
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Solicitud de registro enviada. Recibirás una confirmación por correo.'),
          backgroundColor: BioWayColors.ecoceGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      Navigator.pop(context);
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _animateToNextPage();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _animateToNextPage() {
    _animationController.reverse().then((_) {
      _pageController
          .nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      )
          .then((_) {
        _animationController.forward();
      });
    });
  }

  void _showPrivacyDialog() async {
    const String url = 'https://ecoce.mx/politica-privacidad';

    try {
      await launchUrl(Uri.parse(url));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir la política de privacidad: $e'),
            backgroundColor: BioWayColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_totalPages, (index) {
          bool isActive = index == _currentPage;
          bool isPast = index < _currentPage;
          return Row(
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive || isPast ? BioWayColors.ecoceGreen : Colors.white.withOpacity(0.3),
                  border: Border.all(
                    color: isActive || isPast ? BioWayColors.ecoceGreen : Colors.white.withOpacity(0.5),
                    width: 2,
                  ),
                  boxShadow: isActive
                      ? [
                    BoxShadow(
                      color: BioWayColors.ecoceGreen.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isActive || isPast ? Colors.white : Colors.white.withOpacity(0.7),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              if (index < _totalPages - 1)
                Container(
                  width: MediaQuery.of(context).size.width * 0.15,
                  height: 2,
                  color: isPast ? BioWayColors.ecoceGreen : Colors.white.withOpacity(0.3),
                ),
            ],
          );
        }),
      ),
    );
  }

  // PASO 1: Información de la Empresa
  Widget _buildCompanyInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  BioWayColors.ecoceGreen,
                  BioWayColors.ecoceGreen.withOpacity(0.8),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: BioWayColors.ecoceGreen.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.business,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Información de la Empresa',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Datos básicos de tu organización',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),

          Form(
            key: _formKeyStep1,
            child: Column(
              children: [
                // Nombre de la empresa
                _buildTextField(
                  controller: _companyNameController,
                  hintText: 'Nombre de la Empresa',
                  icon: Icons.business_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa el nombre de la empresa';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // RFC/ID Fiscal
                _buildTextField(
                  controller: _taxIdController,
                  hintText: 'RFC / ID Fiscal',
                  icon: Icons.badge_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa el RFC o ID fiscal';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Tipo de empresa
                _buildDropdownField(
                  value: _selectedCompanyType,
                  hintText: 'Tipo de Organización',
                  icon: Icons.category_outlined,
                  items: _companyTypes,
                  onChanged: (value) => setState(() => _selectedCompanyType = value),
                ),
                const SizedBox(height: 20),

                // Información del contacto
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: BioWayColors.ecoceGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: BioWayColors.ecoceGreen.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Persona de Contacto',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: BioWayColors.ecoceGreen,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildTextField(
                        controller: _contactNameController,
                        hintText: 'Nombre del Contacto',
                        icon: Icons.person_outline,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 12),

                      _buildTextField(
                        controller: _contactPhoneController,
                        hintText: 'Teléfono',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 12),

                      _buildTextField(
                        controller: _contactEmailController,
                        hintText: 'Correo Electrónico',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        backgroundColor: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // PASO 2: Ubicación y Operación
  Widget _buildLocationOperationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  BioWayColors.ecoceGreen,
                  BioWayColors.ecoceGreen.withOpacity(0.8),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: BioWayColors.ecoceGreen.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.location_on,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Ubicación y Operación',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Dirección y tipo de materiales',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),

          Form(
            key: _formKeyStep2,
            child: Column(
              children: [
                // Dirección
                _buildTextField(
                  controller: _addressController,
                  hintText: 'Dirección Completa',
                  icon: Icons.location_on_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Ciudad y Estado
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _cityController,
                        hintText: 'Ciudad',
                        icon: Icons.location_city_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _stateController,
                        hintText: 'Estado',
                        icon: Icons.map_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Código Postal
                _buildTextField(
                  controller: _cpController,
                  hintText: 'Código Postal',
                  icon: Icons.pin_drop_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),

                // Tipos de materiales
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
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
                            Icons.recycling,
                            color: BioWayColors.ecoceGreen,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Materiales que Maneja',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: BioWayColors.ecoceDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Selecciona los tipos de materiales reciclables que tu empresa procesa',
                        style: TextStyle(
                          fontSize: 12,
                          color: BioWayColors.textGrey,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Lista de materiales con checkboxes
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _materialOptions.map((material) {
                          bool isSelected = _selectedMaterialTypes?.contains(material) ?? false;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                if (_selectedMaterialTypes == null) {
                                  _selectedMaterialTypes = material;
                                } else {
                                  List<String> currentMaterials = _selectedMaterialTypes!.split(', ');
                                  if (isSelected) {
                                    currentMaterials.remove(material);
                                  } else {
                                    currentMaterials.add(material);
                                  }
                                  _selectedMaterialTypes = currentMaterials.where((m) => m.isNotEmpty).join(', ');
                                  if (_selectedMaterialTypes!.isEmpty) {
                                    _selectedMaterialTypes = null;
                                  }
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? BioWayColors.ecoceGreen.withOpacity(0.1)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? BioWayColors.ecoceGreen
                                      : Colors.grey.shade300,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: BioWayColors.ecoceGreen,
                                    ),
                                  if (isSelected) const SizedBox(width: 4),
                                  Text(
                                    material,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isSelected
                                          ? BioWayColors.ecoceGreen
                                          : BioWayColors.textGrey,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // PASO 3: Credenciales de Acceso
  Widget _buildCredentialsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  BioWayColors.ecoceGreen,
                  BioWayColors.ecoceGreen.withOpacity(0.8),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: BioWayColors.ecoceGreen.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.security,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Credenciales de Acceso',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Crear tu cuenta de usuario',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),

          Form(
            key: _formKeyStep3,
            child: Column(
              children: [
                // Usuario
                _buildTextField(
                  controller: _usernameController,
                  hintText: 'Nombre de Usuario',
                  icon: Icons.account_circle_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa un nombre de usuario';
                    }
                    if (value.length < 4) {
                      return 'El usuario debe tener al menos 4 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Contraseña
                _buildTextField(
                  controller: _passwordController,
                  hintText: 'Contraseña',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  customObscure: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: BioWayColors.ecoceGreen,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa una contraseña';
                    }
                    if (value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirmar contraseña
                _buildTextField(
                  controller: _confirmPasswordController,
                  hintText: 'Confirmar Contraseña',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  customObscure: _obscureConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      color: BioWayColors.ecoceGreen,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor confirma tu contraseña';
                    }
                    if (value != _passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Información importante
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: BioWayColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: BioWayColors.info.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: BioWayColors.info, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Proceso de Verificación',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: BioWayColors.info,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tu solicitud será revisada por el equipo de ECOCE. Te contactaremos en un plazo máximo de 48 horas para completar el proceso de verificación.',
                        style: TextStyle(
                          fontSize: 12,
                          color: BioWayColors.info,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Términos y condiciones
                _buildTermsSection(),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    bool readOnly = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters,
    bool? customObscure,
    int maxLines = 1,
    Color? backgroundColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: customObscure ?? isPassword,
        readOnly: readOnly,
        keyboardType: keyboardType,
        validator: validator,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(fontSize: 14),
          prefixIcon: Icon(icon, color: BioWayColors.ecoceGreen, size: 20),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: backgroundColor ?? Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: BioWayColors.ecoceGreen.withOpacity(0.2),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: BioWayColors.ecoceGreen, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: maxLines > 1 ? 16 : 12,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String hintText,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(fontSize: 14),
          prefixIcon: Icon(icon, color: BioWayColors.ecoceGreen, size: 20),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: BioWayColors.ecoceGreen.withOpacity(0.2),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: BioWayColors.ecoceGreen, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: const TextStyle(
                fontSize: 14,
                color: BioWayColors.darkGreen,
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        isExpanded: true,
        dropdownColor: Colors.white,
      ),
    );
  }

  Widget _buildTermsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Términos y Condiciones ECOCE',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: BioWayColors.ecoceDark,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Transform.scale(
                scale: 0.9,
                child: Checkbox(
                  value: _acceptedTerms,
                  onChanged: (value) => setState(() => _acceptedTerms = value ?? false),
                  activeColor: BioWayColors.ecoceGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _showPrivacyDialog,
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.3),
                      children: [
                        const TextSpan(text: 'Acepto los '),
                        TextSpan(
                          text: 'términos y condiciones',
                          style: TextStyle(
                            color: BioWayColors.ecoceGreen,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        const TextSpan(text: ' del sistema de trazabilidad ECOCE y autorizo el tratamiento de mis datos personales conforme a la '),
                        TextSpan(
                          text: 'política de privacidad',
                          style: TextStyle(
                            color: BioWayColors.ecoceGreen,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          if (_currentPage > 0) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _previousPage,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  side: const BorderSide(color: Colors.white, width: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('Anterior', style: TextStyle(fontSize: 14)),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: (_currentPage == _totalPages - 1)
                  ? (_isLoading ? null : _register)
                  : _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: BioWayColors.ecoceGreen,
                disabledBackgroundColor: Colors.white.withOpacity(0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: _isLoading
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(BioWayColors.ecoceGreen),
                  strokeWidth: 2,
                ),
              )
                  : Text(
                _currentPage == _totalPages - 1 ? 'Enviar Solicitud' : 'Siguiente',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Fondo con patrón ECOCE
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    BioWayColors.ecoceGreen,
                    BioWayColors.ecoceGreen.withOpacity(0.8),
                    BioWayColors.ecoceLight,
                  ],
                ),
              ),
            ),
          ),

          // Patrón decorativo
          Positioned.fill(
            child: CustomPaint(
              painter: ECOCEPatternPainter(),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header animado
                AnimatedBuilder(
                  animation: _headerController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _headerFadeAnimation,
                      child: SlideTransition(
                        position: _headerSlideAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back_ios_new,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                onPressed: _navigateBack,
                              ),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        'ECOCE',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Registro',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 48), // Espacio para balancear
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Indicador de pasos
                _buildStepIndicator(),

                // Contenido
                Expanded(
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: PageView(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          onPageChanged: (index) => setState(() => _currentPage = index),
                          children: [
                            _buildCompanyInfoStep(),
                            _buildLocationOperationStep(),
                            _buildCredentialsStep(),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Botones de navegación
                _buildNavigationButtons(),

                // Link para iniciar sesión
                TextButton(
                  onPressed: _navigateBack,
                  child: const Text(
                    '¿Ya tienes cuenta? Inicia sesión',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Painter personalizado para el patrón de fondo de ECOCE
class ECOCEPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Círculo decorativo superior derecho
    paint.color = Colors.white.withOpacity(0.05);
    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.1),
      120,
      paint,
    );

    // Círculo decorativo inferior izquierdo
    paint.color = Colors.white.withOpacity(0.03);
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.8),
      150,
      paint,
    );

    // Líneas decorativas diagonales
    paint.color = Colors.white.withOpacity(0.02);
    paint.strokeWidth = 1;
    paint.style = PaintingStyle.stroke;

    for (int i = 0; i < 8; i++) {
      final x = size.width * (i / 7);
      final path = Path();
      path.moveTo(x, 0);
      path.lineTo(x + size.width * 0.2, size.height);
      canvas.drawPath(path, paint);
    }

    // Iconos de reciclaje sutiles
    paint.color = Colors.white.withOpacity(0.02);
    paint.style = PaintingStyle.fill;

    // Simular iconos pequeños de reciclaje
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.3), 8, paint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.6), 6, paint);
    canvas.drawCircle(Offset(size.width * 0.6, size.height * 0.2), 4, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}