import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/colors.dart';
import '../../widgets/common/gradient_background.dart';

class BioWayRegisterScreen extends StatefulWidget {
  const BioWayRegisterScreen({super.key});

  @override
  State<BioWayRegisterScreen> createState() => _BioWayRegisterScreenState();
}

class _BioWayRegisterScreenState extends State<BioWayRegisterScreen>
    with SingleTickerProviderStateMixin {
  // Controladores
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Estados
  int _currentPage = 0;
  int _totalPages = 3; // Se ajustará según el tipo de usuario

  // Form keys para cada paso
  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();
  final _formKeyStep3 = GlobalKey<FormState>();

  // Controladores de los campos
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Campos para Brindador
  final _addressController = TextEditingController();
  final _numExtController = TextEditingController();
  final _cpController = TextEditingController();
  final _stateController = TextEditingController();
  final _cityController = TextEditingController();
  final _colonyController = TextEditingController();

  // Campos para Recolector
  String? _selectedCompany;

  // Estados del formulario
  String? _selectedUserType;
  bool _acceptedPrivacy = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Lista de empresas/asociaciones para recolectores
  final List<String> _companies = [
    'Ninguna',
    'Reciclaje Verde S.A.',
    'EcoMéxico',
    'Asociación de Recicladores Unidos',
    'Cooperativa Ambiental del Norte',
    'Grupo Sustentable México',
    'Red de Reciclaje Ciudadano',
    'Otra',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    _numExtController.dispose();
    _cpController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _colonyController.dispose();
    super.dispose();
  }

  void _navigateBack() {
    HapticFeedback.lightImpact();
    Navigator.pop(context);
  }

  Future<void> _register() async {
    // Por ahora solo simula el registro
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isLoading = false);

      String userType = _selectedUserType == 'brindador' ? 'Brindador' : 'Recolector';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registro exitoso como $userType'),
          backgroundColor: BioWayColors.success,
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
    if (_currentPage == 0 && _selectedUserType != null) {
      // Después de seleccionar tipo de usuario
      _animateToNextPage();
    } else if (_currentPage == 1) {
      // Después de información adicional
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
    const String url = 'https://bioway.com.mx/bioway-politica.html';

    try {
      await launchUrl(Uri.parse(url));
    } catch (e) {
      print('Error al abrir URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir la política de privacidad: $e'),
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

  // Método para mostrar alerta informativa del tipo de usuario
  void _showUserTypeAlert() {
    if (_selectedUserType == null) return;

    String title;
    String description;
    List<String> features;
    IconData icon;
    Color color;

    if (_selectedUserType == 'brindador') {
      title = '¿Qué es un Brindador?';
      description = 'Los Brindadores son personas que reciclan desde casa, brindando/donando sus materiales reciclables de forma responsable.';
      features = [
        'Recicla desde casa con guía paso a paso para separar y preparar materiales',
        'Gana puntos por brindar reciclables limpios y separados',
        'Conoce el impacto real de tu contribución en la reducción de emisiones',
        'Participa en el programa de recompensas de la comunidad'
      ];
      icon = Icons.home_outlined;
      color = BioWayColors.primaryGreen;
    } else {
      title = '¿Qué es un Recolector?';
      description = 'Los Recolectores dignifican su labor recogiendo materiales reciclables ya limpios y separados usando BioWay.';
      features = [
        'Usa el mapa interactivo para ubicar materiales disponibles y optimizar rutas',
        'Recibe materiales ya limpios y separados, aumentando tus ingresos',
        'Trabaja en condiciones más seguras y dignas',
        'Accede a horarios fijos si no tienes dispositivo móvil'
      ];
      icon = Icons.person_pin_circle;
      color = BioWayColors.mediumGreen;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: BoxConstraints(
              maxWidth: 400,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header con ícono
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 40,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Título
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: BioWayColors.darkGreen,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),

                  // Descripción
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: BioWayColors.textGrey,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Features
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Con BioWay podrás:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: BioWayColors.darkGreen,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...features.map((feature) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 3),
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  feature,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: BioWayColors.textGrey,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Botón de cerrar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text(
                        'Continuar',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
                  color: isActive || isPast ? BioWayColors.primaryGreen : Colors.white.withOpacity(0.3),
                  border: Border.all(
                    color: isActive || isPast ? BioWayColors.primaryGreen : Colors.white.withOpacity(0.5),
                    width: 2,
                  ),
                  boxShadow: isActive
                      ? [
                    BoxShadow(
                      color: BioWayColors.primaryGreen.withOpacity(0.4),
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
                  color: isPast ? BioWayColors.primaryGreen : Colors.white.withOpacity(0.3),
                ),
            ],
          );
        }),
      ),
    );
  }

  // PASO 1: Selección de tipo de usuario con información descriptiva
  Widget _buildUserTypeStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Icon(
            Icons.people_alt_rounded,
            size: 60,
            color: Colors.white,
          ),
          const SizedBox(height: 20),
          const Text(
            '¿Qué tipo de usuario eres?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Selecciona tu rol en BioWay',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),

          // Opciones de usuario
          Column(
            children: [
              _buildUserTypeCard(
                icon: Icons.home_outlined,
                title: 'Brindador',
                subtitle: 'Persona que recicla\ndesde casa',
                value: 'brindador',
                isSelected: _selectedUserType == 'brindador',
              ),
              const SizedBox(height: 16),
              _buildUserTypeCard(
                icon: Icons.person_pin_circle,
                title: 'Recolector',
                subtitle: 'Reciclador\nindependiente',
                value: 'recolector',
                isSelected: _selectedUserType == 'recolector',
              ),
            ],
          ),

          const SizedBox(height: 30),

          // Información adicional
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.white70, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Toca cualquier opción para conocer más detalles sobre ese tipo de usuario.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 80), // Espacio para los botones
        ],
      ),
    );
  }

  // PASO 2A: Información específica para Brindador
  Widget _buildBrindadorInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Icon(
            Icons.location_on,
            size: 50,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          const Text(
            'Ubicación del Centro',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ingresa la dirección de tu centro de acopio',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 24),

          Form(
            key: _formKeyStep2,
            child: Column(
              children: [
                // Calle y número
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildTextField(
                        controller: _addressController,
                        hintText: 'Calle',
                        icon: Icons.location_on_outlined,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTextField(
                        controller: _numExtController,
                        hintText: 'Núm.',
                        icon: Icons.numbers,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Código postal con búsqueda
                _buildCPField(),
                const SizedBox(height: 16),

                // Estado
                _buildTextField(
                  controller: _stateController,
                  hintText: 'Estado',
                  icon: Icons.map,
                  readOnly: true,
                ),
                const SizedBox(height: 16),

                // Municipio
                _buildTextField(
                  controller: _cityController,
                  hintText: 'Municipio',
                  icon: Icons.location_city,
                  readOnly: true,
                ),
                const SizedBox(height: 16),

                // Colonia
                _buildTextField(
                  controller: _colonyController,
                  hintText: 'Colonia',
                  icon: Icons.home,
                  readOnly: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 80), // Espacio para los botones
        ],
      ),
    );
  }

  // PASO 2B: Información específica para Recolector (MEJORADO)
  Widget _buildRecolectorInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Icon(
            Icons.business,
            size: 50,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          const Text(
            'Información Adicional',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Información opcional sobre tu actividad',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 24),

          // Container para la pregunta y el dropdown - CORREGIDO
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                // Título de la sección
                Text(
                  '¿Perteneces a alguna empresa o asociación?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: BioWayColors.darkGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Esta información nos ayuda a brindarte mejores servicios',
                  style: TextStyle(
                    fontSize: 12,
                    color: BioWayColors.textGrey,
                  ),
                ),
                const SizedBox(height: 16),

                // Dropdown mejorado
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: BioWayColors.backgroundGrey,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedCompany,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.business_outlined,
                        color: BioWayColors.primaryGreen,
                        size: 22,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    hint: Text(
                      'Selecciona una opción',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    items: _companies.map((company) {
                      return DropdownMenuItem<String>(
                        value: company,
                        child: Text(
                          company,
                          style: const TextStyle(
                            fontSize: 14,
                            color: BioWayColors.darkGreen,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCompany = value;
                      });
                    },
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    style: const TextStyle(
                      fontSize: 14,
                      color: BioWayColors.darkGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Información sobre beneficios - MEJORADA
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: BioWayColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: BioWayColors.info.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: BioWayColors.info, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Beneficios de pertenecer a una empresa',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: BioWayColors.info,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildBenefit('Acceso a materiales específicos'),
                _buildBenefit('Rutas de recolección asignadas'),
                _buildBenefit('Tarifas preferenciales'),
                _buildBenefit('Capacitación y certificaciones'),
                _buildBenefit('Soporte técnico especializado'),
                _buildBenefit('Programas de incentivos adicionales'),
              ],
            ),
          ),

          const SizedBox(height: 80), // Espacio para los botones
        ],
      ),
    );
  }

  // PASO 3: Información de cuenta (común para ambos)
  Widget _buildAccountInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Icon(
            Icons.account_circle,
            size: 50,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          const Text(
            'Crear tu Cuenta',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Estos datos serán verificados por correo',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 24),

          Form(
            key: _formKeyStep3,
            child: Column(
              children: [
                // Nombre completo (limitado a 10 caracteres)
                _buildTextField(
                  controller: _fullNameController,
                  hintText: 'Nombre completo',
                  icon: Icons.person_outline,
                  inputFormatters: [LengthLimitingTextInputFormatter(10)],
                ),
                const SizedBox(height: 16),

                // Email
                _buildTextField(
                  controller: _emailController,
                  hintText: 'Correo electrónico',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: BioWayColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: BioWayColors.info.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: BioWayColors.info, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Se enviará un código de verificación a este correo',
                          style: TextStyle(
                            fontSize: 12,
                            color: BioWayColors.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Contraseña (limitada a 10 caracteres)
                _buildTextField(
                  controller: _passwordController,
                  hintText: 'Contraseña',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  customObscure: _obscurePassword,
                  inputFormatters: [LengthLimitingTextInputFormatter(10)],
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: BioWayColors.primaryGreen,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Confirmar contraseña
                _buildTextField(
                  controller: _confirmPasswordController,
                  hintText: 'Confirmar Contraseña',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  customObscure: _obscureConfirmPassword,
                  inputFormatters: [LengthLimitingTextInputFormatter(10)],
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      color: BioWayColors.primaryGreen,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Aviso de privacidad
                _buildPrivacySection(),
              ],
            ),
          ),
          const SizedBox(height: 80), // Espacio para los botones
        ],
      ),
    );
  }

  Widget _buildBenefit(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: BioWayColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: BioWayColors.info,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedUserType = value;
        });
        // Mostrar alerta informativa inmediatamente después de seleccionar
        Future.delayed(const Duration(milliseconds: 200), () {
          _showUserTypeAlert();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? BioWayColors.primaryGreen : Colors.white,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? BioWayColors.darkGreen : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.grey.shade600 : Colors.white70,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) ...[
              Icon(
                Icons.check_circle,
                color: BioWayColors.primaryGreen,
                size: 24,
              ),
            ] else ...[
              Icon(
                Icons.info_outline,
                color: Colors.white70,
                size: 20,
              ),
            ],
          ],
        ),
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
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 20),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: BioWayColors.primaryGreen, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildCPField() {
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
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _cpController,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Código Postal',
                hintStyle: const TextStyle(fontSize: 14),
                prefixIcon: Icon(Icons.location_on, color: Colors.grey.shade600, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    bottomLeft: Radius.circular(15),
                  ),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    bottomLeft: Radius.circular(15),
                  ),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    bottomLeft: Radius.circular(15),
                  ),
                  borderSide: BorderSide(color: BioWayColors.primaryGreen, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              keyboardType: TextInputType.number,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: BioWayColors.primaryGreen,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.search, color: Colors.white, size: 20),
              onPressed: () {
                // Simular búsqueda de CP
                setState(() {
                  _stateController.text = 'Aguascalientes';
                  _cityController.text = 'Aguascalientes';
                  _colonyController.text = 'Centro';
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection() {
    return Container(
      padding: const EdgeInsets.all(12),
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
            'Términos y Condiciones',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: BioWayColors.darkGreen,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Transform.scale(
                scale: 0.9,
                child: Checkbox(
                  value: _acceptedPrivacy,
                  onChanged: (value) => setState(() => _acceptedPrivacy = value ?? false),
                  activeColor: BioWayColors.primaryGreen,
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
                        const TextSpan(text: 'He leído y acepto el '),
                        TextSpan(
                          text: 'aviso de privacidad',
                          style: TextStyle(
                            color: BioWayColors.primaryGreen,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        const TextSpan(text: ' de BIOWAY.'),
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
              onPressed: (_currentPage == 0 && _selectedUserType == null)
                  ? null
                  : (_currentPage == _totalPages - 1)
                  ? (_isLoading ? null : _register)
                  : _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: BioWayColors.primaryGreen,
                disabledBackgroundColor: Colors.white.withOpacity(0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: _isLoading
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(BioWayColors.primaryGreen),
                  strokeWidth: 2,
                ),
              )
                  : Text(
                _currentPage == _totalPages - 1 ? 'Registrarse' : 'Siguiente',
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
      body: GradientBackground(
        showPattern: true,
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
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
                      child: Text(
                        'Crear Cuenta',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Espacio para balancear
                  ],
                ),
              ),

              // Indicador de pasos
              _buildStepIndicator(),

              // Contenido
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  children: [
                    // Paso 1: Tipo de usuario
                    _buildUserTypeStep(),

                    // Paso 2: Información específica según tipo
                    if (_selectedUserType == 'brindador')
                      _buildBrindadorInfoStep()
                    else
                      _buildRecolectorInfoStep(),

                    // Paso 3: Información de cuenta
                    _buildAccountInfoStep(),
                  ],
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
      ),
    );
  }
}