import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../utils/colors.dart'; // ACTUALIZADA
import '../../../widgets/common/gradient_background.dart'; // ACTUALIZADA
import '../../../services/bioway/bioway_auth_service.dart';
import '../../../services/firebase/auth_service.dart';
import '../../../services/firebase/firebase_manager.dart';
import '../../../widgets/common/location_picker_widget.dart';

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

  // Estados
  int _currentPage = 0;
  int _totalPages = 4; // Se ajustará según el tipo de usuario
  bool _isEmailVerified = false;
  String? _userId; // ID del usuario después de crear la cuenta

  // Form keys para cada paso
  final _formKeyStep2 = GlobalKey<FormState>();
  final _formKeyStep4 = GlobalKey<FormState>();

  // Controladores de los campos
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  // Campos para Brindador
  final _addressController = TextEditingController();
  final _numExtController = TextEditingController();
  final _cpController = TextEditingController();
  final _stateController = TextEditingController();
  final _cityController = TextEditingController();
  final _colonyController = TextEditingController();
  double? _selectedLatitude;
  double? _selectedLongitude;

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
  
  // Servicio de autenticación
  late final BioWayAuthService _bioWayAuthService;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animationController.forward();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      // Inicializar Firebase para BioWay
      await _authService.initializeForPlatform(FirebasePlatform.bioway);
      debugPrint('✅ Firebase inicializado para BioWay en registro');
      
      // Ahora es seguro crear la instancia de BioWayAuthService
      _bioWayAuthService = BioWayAuthService();
    } catch (e) {
      debugPrint('❌ Error al inicializar Firebase para BioWay: $e');
      // Crear la instancia de todos modos para evitar errores
      _bioWayAuthService = BioWayAuthService();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
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

  // Crear cuenta con solo email y contraseña
  Future<void> _createAccount() async {
    if (!(_formKeyStep2.currentState?.validate() ?? false)) {
      return;
    }
    
    // Validar contraseñas coinciden
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Las contraseñas no coinciden'),
          backgroundColor: BioWayColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    
    setState(() => _isLoading = true);

    try {
      // Inicializar Firebase para BioWay
      await _authService.initializeForPlatform(FirebasePlatform.bioway);
      
      // Crear cuenta usando el servicio
      final userId = await _bioWayAuthService.crearCuenta(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      setState(() {
        _userId = userId;
      });
        
      if (mounted) {
        setState(() => _isLoading = false);
        
        // Mostrar mensaje de éxito y avanzar a verificación
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Cuenta creada. Revisa tu correo para verificar.'),
            backgroundColor: BioWayColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        
        _nextPage();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        
        String errorMessage = 'Error al crear cuenta';
        if (e.toString().contains('email-already-in-use')) {
          errorMessage = 'Este correo ya está registrado';
        } else if (e.toString().contains('weak-password')) {
          errorMessage = 'La contraseña debe tener al menos 6 caracteres';
        } else if (e.toString().contains('invalid-email')) {
          errorMessage = 'Correo electrónico inválido';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
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

  // Verificar si el correo fue verificado
  Future<void> _checkEmailVerification() async {
    setState(() => _isLoading = true);
    
    try {
      final isVerified = await _bioWayAuthService.verificarCorreo();
      
      if (isVerified) {
        setState(() {
          _isEmailVerified = true;
          _isLoading = false;
        });
        
        _nextPage();
      } else {
        setState(() => _isLoading = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('El correo aún no ha sido verificado'),
            backgroundColor: BioWayColors.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error al verificar el correo'),
          backgroundColor: BioWayColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // Completar registro con información adicional
  Future<void> _completeRegistration() async {
    if (!_acceptedPrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Debes aceptar los términos y condiciones'),
          backgroundColor: BioWayColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    
    setState(() => _isLoading = true);

    try {
      if (_selectedUserType == 'brindador') {
        // Completar registro de Brindador
        await _bioWayAuthService.completarRegistroBrindador(
          userId: _userId!,
          nombre: _fullNameController.text.trim(),
          telefono: _phoneController.text.trim(),
          latitud: _selectedLatitude ?? 0.0,
          longitud: _selectedLongitude ?? 0.0,
          direccion: _addressController.text.trim(),
        );
      } else if (_selectedUserType == 'recolector') {
        // Completar registro de Recolector
        await _bioWayAuthService.completarRegistroRecolector(
          userId: _userId!,
          nombre: _fullNameController.text.trim(),
          telefono: _phoneController.text.trim(),
          empresa: _selectedCompany,
        );
      } else if (_selectedUserType == 'centro_acopio') {
        // Completar registro de Centro de Acopio
        await _bioWayAuthService.completarRegistroCentroAcopio(
          userId: _userId!,
          nombre: _fullNameController.text.trim(),
          telefono: _phoneController.text.trim(),
          latitud: _selectedLatitude ?? 0.0,
          longitud: _selectedLongitude ?? 0.0,
          direccion: _addressController.text.trim(),
          nombreCentro: _fullNameController.text.trim(),
        );
      }

      if (mounted) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('¡Registro completado exitosamente!'),
            backgroundColor: BioWayColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        // Volver a la pantalla de login
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al completar registro: ${e.toString()}'),
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

  void _nextPage() {
    if (_currentPage == 0 && _selectedUserType != null) {
      // Después de seleccionar tipo de usuario, ir a crear cuenta
      _animateToNextPage();
    } else if (_currentPage == 1) {
      // Después de crear cuenta, llamar a _createAccount
      _createAccount();
    } else if (_currentPage == 2 && _isEmailVerified) {
      // Después de verificar email, ir a información adicional
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
      debugPrint('Error al abrir URL: $e');
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
    } else if (_selectedUserType == 'recolector') {
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
    } else {
      title = '¿Qué es un Centro de Acopio?';
      description = 'Los Centros de Acopio son establecimientos especializados en la recepción y gestión de materiales reciclables.';
      features = [
        'Gestiona tu inventario de materiales reciclables de forma digital',
        'Conecta con brindadores y recolectores de tu zona',
        'Genera reportes de impacto ambiental y financiero',
        'Optimiza tus operaciones con herramientas de gestión'
      ];
      icon = Icons.warehouse;
      color = BioWayColors.info;
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
                      color: color.withValues(alpha: 0.1),
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
                      color: color.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withValues(alpha: 0.2)),
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
                  color: isActive || isPast ? BioWayColors.primaryGreen : Colors.white.withValues(alpha: 0.3),
                  border: Border.all(
                    color: isActive || isPast ? BioWayColors.primaryGreen : Colors.white.withValues(alpha: 0.5),
                    width: 2,
                  ),
                  boxShadow: isActive
                      ? [
                    BoxShadow(
                      color: BioWayColors.primaryGreen.withValues(alpha: 0.4),
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
                      color: isActive || isPast ? Colors.white : Colors.white.withValues(alpha: 0.7),
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
                  color: isPast ? BioWayColors.primaryGreen : Colors.white.withValues(alpha: 0.3),
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
              const SizedBox(height: 16),
              _buildUserTypeCard(
                icon: Icons.warehouse,
                title: 'Centro de Acopio',
                subtitle: 'Establecimiento de\nrecolección',
                value: 'centro_acopio',
                isSelected: _selectedUserType == 'centro_acopio',
              ),
            ],
          ),

          const SizedBox(height: 30),

          // Información adicional
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
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

  // PASO 4A: Información específica para Brindador (con mapa)
  Widget _buildBrindadorAdditionalInfoStep() {
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
            'Ubicación de tu Hogar',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Selecciona tu ubicación para conectar con recolectores cercanos',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 24),

          Form(
            key: _formKeyStep4,
            child: Column(
              children: [
                // Nombre completo
                _buildTextField(
                  controller: _fullNameController,
                  hintText: 'Nombre completo',
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Selector de ubicación con mapa
                GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LocationPickerWidget(
                          title: 'Selecciona tu ubicación',
                          onLocationSelected: (location, address) {
                            setState(() {
                              _selectedLatitude = location.latitude;
                              _selectedLongitude = location.longitude;
                              
                              // Parsear la dirección devuelta
                              final addressParts = address.split(', ');
                              if (addressParts.isNotEmpty) {
                                _addressController.text = addressParts[0];
                                if (addressParts.length > 1) {
                                  _colonyController.text = addressParts[1];
                                }
                                if (addressParts.length > 2) {
                                  _cityController.text = addressParts[2];
                                }
                                if (addressParts.length > 3) {
                                  final stateAndCP = addressParts[3].split(' ');
                                  if (stateAndCP.isNotEmpty) {
                                    _stateController.text = stateAndCP[0];
                                    if (stateAndCP.length > 1) {
                                      _cpController.text = stateAndCP[1];
                                    }
                                  }
                                }
                              }
                            });
                          },
                          initialLocation: _selectedLatitude != null && _selectedLongitude != null
                              ? LatLng(_selectedLatitude!, _selectedLongitude!)
                              : null,
                          initialAddress: _addressController.text.isNotEmpty
                              ? '${_addressController.text}, ${_colonyController.text}, ${_cityController.text}'
                              : null,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.map_outlined,
                          color: BioWayColors.primaryGreen,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _addressController.text.isNotEmpty
                                    ? 'Ubicación seleccionada'
                                    : 'Seleccionar ubicación en el mapa',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _addressController.text.isNotEmpty
                                      ? BioWayColors.darkGreen
                                      : Colors.grey[600],
                                ),
                              ),
                              if (_addressController.text.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '${_addressController.text} ${_numExtController.text}, ${_colonyController.text}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: BioWayColors.primaryGreen,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Número exterior (opcional)
                _buildTextField(
                  controller: _numExtController,
                  hintText: 'Número exterior (opcional)',
                  icon: Icons.numbers,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 16),

                // Campos de dirección (solo lectura, se llenan con el mapa)
                _buildTextField(
                  controller: _addressController,
                  hintText: 'Calle',
                  icon: Icons.location_on_outlined,
                  readOnly: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor selecciona tu ubicación en el mapa';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _colonyController,
                  hintText: 'Colonia',
                  icon: Icons.home,
                  readOnly: true,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _cityController,
                        hintText: 'Municipio',
                        icon: Icons.location_city,
                        readOnly: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTextField(
                        controller: _stateController,
                        hintText: 'Estado',
                        icon: Icons.map,
                        readOnly: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _cpController,
                  hintText: 'Código Postal',
                  icon: Icons.pin_drop,
                  readOnly: true,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),

                // Aviso de privacidad
                _buildPrivacySection(),
              ],
            ),
          ),
          const SizedBox(height: 80),
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
                  color: Colors.black.withValues(alpha: 0.1),
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
              color: BioWayColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: BioWayColors.info.withValues(alpha: 0.3)),
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

  // PASO 2: Crear cuenta (email y contraseña)
  Widget _buildAccountCreationStep() {
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
            'Ingresa tu correo y contraseña para comenzar',
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
                // Email
                _buildTextField(
                  controller: _emailController,
                  hintText: 'Correo electrónico',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu correo';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Por favor ingresa un correo válido';
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
                  inputFormatters: [LengthLimitingTextInputFormatter(20)],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa una contraseña';
                    }
                    if (value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
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
                  inputFormatters: [LengthLimitingTextInputFormatter(20)],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor confirma tu contraseña';
                    }
                    if (value != _passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
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
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // PASO 3: Verificación de email
  Widget _buildEmailVerificationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.email_outlined,
              size: 60,
              color: BioWayColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Verifica tu correo',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Hemos enviado un correo de verificación a:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _emailController.text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.white70,
                  size: 24,
                ),
                const SizedBox(height: 12),
                Text(
                  'Revisa tu bandeja de entrada y haz clic en el enlace de verificación.\n\nUna vez verificado, presiona "Verificar" para continuar.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _checkEmailVerification,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: BioWayColors.primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(BioWayColors.primaryGreen),
                      ),
                    )
                  : Icon(Icons.check_circle_outline),
              label: Text(
                _isLoading ? 'Verificando...' : 'Verificar',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () async {
              try {
                await _bioWayAuthService.reenviarCorreoVerificacion();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Correo de verificación reenviado'),
                    backgroundColor: BioWayColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Error al reenviar correo'),
                    backgroundColor: BioWayColors.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
            child: const Text(
              'Reenviar correo de verificación',
              style: TextStyle(
                color: Colors.white,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // PASO 4A: Información específica para Brindador (con mapa)

  // PASO 2C: Información específica para Centro de Acopio
  Widget _buildCentroAcopioInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Icon(
            Icons.warehouse,
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
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
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
            color: Colors.black.withValues(alpha: 0.1),
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
            color: Colors.black.withValues(alpha: 0.1),
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
            color: Colors.black.withValues(alpha: 0.1),
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
                  ? (_isLoading ? null : _completeRegistration)
                  : _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: BioWayColors.primaryGreen,
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.3),
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
                          color: Colors.white.withValues(alpha: 0.2),
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

                    // Paso 2: Creación de cuenta
                    _buildAccountCreationStep(),
                    
                    // Paso 3: Verificación de email
                    _buildEmailVerificationStep(),
                    
                    // Paso 4: Información adicional según tipo de usuario
                    if (_selectedUserType == 'brindador')
                      _buildBrindadorAdditionalInfoStep()
                    else if (_selectedUserType == 'recolector')
                      _buildRecolectorInfoStep()
                    else if (_selectedUserType == 'centro_acopio')
                      _buildCentroAcopioInfoStep()
                    else
                      Container(), // Placeholder for null selected type
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