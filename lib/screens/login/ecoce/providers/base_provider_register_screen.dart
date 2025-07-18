import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../utils/colors.dart';
import '../widgets/step_widgets.dart';
import '../../../../services/firebase/ecoce_profile_service.dart';
import '../../../../services/firebase/auth_service.dart';
import '../../../../services/firebase/firebase_manager.dart';

abstract class BaseProviderRegisterScreen extends StatefulWidget {
  const BaseProviderRegisterScreen({super.key});
}

abstract class BaseProviderRegisterScreenState<T extends BaseProviderRegisterScreen> 
    extends State<T> with SingleTickerProviderStateMixin {
  int _currentStep = 1;
  static const int _totalSteps = 5;

  // Controladores para todos los campos
  final Map<String, TextEditingController> _controllers = {
    'nombreComercial': TextEditingController(),
    'rfc': TextEditingController(),
    'nombreContacto': TextEditingController(),
    'telefono': TextEditingController(),
    'telefonoOficina': TextEditingController(),
    'direccion': TextEditingController(),
    'numExt': TextEditingController(),
    'cp': TextEditingController(),
    'estado': TextEditingController(),
    'municipio': TextEditingController(),
    'colonia': TextEditingController(),
    'referencias': TextEditingController(),
    'largo': TextEditingController(),
    'ancho': TextEditingController(),
    'peso': TextEditingController(),
    'linkRedSocial': TextEditingController(),
    'email': TextEditingController(),
    'password': TextEditingController(),
    'confirmPassword': TextEditingController(),
  };

  // Estados
  final Set<String> _selectedMaterials = {};
  @protected
  bool hasTransport = false;
  bool _acceptTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  final Map<String, String?> _selectedFiles = {
    'const_sit_fis': null,
    'comp_domicilio': null,
    'banco_caratula': null,
    'ine': null,
  };
  
  // Location data
  LatLng? _selectedLocation;
  String? _selectedAddress;
  
  // Services
  final EcoceProfileService _profileService = EcoceProfileService();
  final AuthService _authService = AuthService();

  // Animación
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Métodos abstractos que cada pantalla debe implementar
  String get providerType;
  String get providerTitle;
  String get providerSubtitle;
  IconData get providerIcon;
  Color get providerColor;
  String get folioPrefix;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _initializeFirebase();
  }
  
  Future<void> _initializeFirebase() async {
    try {
      await _authService.initializeForPlatform(FirebasePlatform.ecoce);
    } catch (e) {
      print('Error initializing Firebase: $e');
    }
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _animationController.forward();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  void _navigateBack() {
    HapticFeedback.lightImpact();
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  void _navigateToSelector() {
    HapticFeedback.lightImpact();
    Navigator.pop(context);
  }

  void _nextStep() {
    if (_currentStep < _totalSteps) {
      setState(() {
        _currentStep++;
        _animationController.reset();
        _animationController.forward();
      });
    }
  }

  void _completeRegistration() async {
    // Validar contraseñas
    if (_controllers['password']!.text != _controllers['confirmPassword']!.text) {
      setState(() {
        _errorMessage = 'Las contraseñas no coinciden';
      });
      return;
    }
    
    // Validar términos
    if (!_acceptTerms) {
      setState(() {
        _errorMessage = 'Debes aceptar los términos y condiciones';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Obtener tipo de actor según el tipo de proveedor
      String tipoActor = _getTipoActor();
      
      // Preparar dimensiones de capacidad si aplica
      Map<String, double>? dimensionesCapacidad;
      double? pesoCapacidad;
      
      if (providerType == 'Acopiador' || providerType == 'Planta de Separación') {
        final largo = double.tryParse(_controllers['largo']!.text);
        final ancho = double.tryParse(_controllers['ancho']!.text);
        final peso = double.tryParse(_controllers['peso']!.text);
        
        if (largo != null && ancho != null) {
          dimensionesCapacidad = {'largo': largo, 'ancho': ancho};
        }
        pesoCapacidad = peso;
      }
      
      // Generar link de Google Maps si hay ubicación seleccionada
      String? linkMaps;
      if (_selectedLocation != null) {
        linkMaps = 'https://www.google.com/maps/search/?api=1&query=${_selectedLocation!.latitude},${_selectedLocation!.longitude}';
      }
      
      // Crear perfil en Firebase
      final profile = await _profileService.createOrigenProfile(
        email: _controllers['email']!.text.trim(),
        password: _controllers['password']!.text,
        tipoActor: tipoActor,
        nombre: _controllers['nombreComercial']!.text.trim(),
        rfc: _controllers['rfc']!.text.trim().isEmpty ? null : _controllers['rfc']!.text.trim(),
        nombreContacto: _controllers['nombreContacto']!.text.trim(),
        telefonoContacto: _controllers['telefono']!.text.trim(),
        telefonoEmpresa: _controllers['telefonoOficina']!.text.trim(),
        calle: _controllers['direccion']!.text.trim(),
        numExt: _controllers['numExt']!.text.trim(),
        cp: _controllers['cp']!.text.trim(),
        estado: _controllers['estado']!.text.trim(),
        municipio: _controllers['municipio']!.text.trim(),
        colonia: _controllers['colonia']!.text.trim(),
        referencias: _controllers['referencias']!.text.trim(),
        materiales: _selectedMaterials.toList(),
        transporte: hasTransport,
        linkRedSocial: _controllers['linkRedSocial']!.text.trim().isEmpty ? null : _controllers['linkRedSocial']!.text.trim(),
        dimensionesCapacidad: dimensionesCapacidad,
        pesoCapacidad: pesoCapacidad,
        documentos: _selectedFiles,
        linkMaps: linkMaps,
      );
      
      setState(() {
        _isLoading = false;
      });
      
      _showSuccessDialog(profile.ecoce_folio);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = _getErrorMessage(e.toString());
      });
    }
  }
  
  String _getTipoActor() {
    switch (providerType) {
      case 'Acopiador':
        return 'A';
      case 'Planta de Separación':
        return 'P';
      case 'Reciclador':
        return 'R';
      case 'Transformador':
        return 'T';
      case 'Transportista':
        return 'V';
      case 'Laboratorio':
        return 'L';
      default:
        return 'A';
    }
  }
  
  String _getErrorMessage(String error) {
    if (error.contains('email-already-in-use')) {
      return 'Este correo ya está registrado';
    } else if (error.contains('weak-password')) {
      return 'La contraseña debe tener al menos 6 caracteres';
    } else if (error.contains('invalid-email')) {
      return 'El correo no es válido';
    } else {
      return 'Error al registrar. Intenta nuevamente.';
    }
  }

  void _showSuccessDialog(String folio) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SuccessDialog(
        folio: folio,
        onContinue: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _navigateBack();
      },
      child: Scaffold(
        backgroundColor: BioWayColors.backgroundGrey,
        body: SafeArea(
          child: Column(
            children: [
              RegisterHeader(
                currentStep: _currentStep,
                totalSteps: _totalSteps,
                onBackPressed: _navigateToSelector,
                title: providerTitle,
                subtitle: providerSubtitle,
                icon: providerIcon,
                color: providerColor,
              ),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
                          child: _buildCurrentStep(),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 1:
        return BasicInfoStep(
          controllers: _controllers,
          onNext: _nextStep,
        );
      case 2:
        return LocationStep(
          controllers: _controllers,
          onNext: _nextStep,
          onPrevious: _navigateBack,
          onLocationSelected: (location, address) {
            setState(() {
              _selectedLocation = location;
              _selectedAddress = address;
            });
          },
          selectedLocation: _selectedLocation,
          selectedAddress: _selectedAddress,
        );
      case 3:
        return buildOperationsStep();
      case 4:
        return FiscalDataStep(
          selectedFiles: _selectedFiles,
          onFileToggle: _toggleFile,
          onNext: _nextStep,
          onPrevious: _navigateBack,
        );
      case 5:
        return Column(
          children: [
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            CredentialsStep(
              controllers: _controllers,
              acceptTerms: _acceptTerms,
              obscurePassword: _obscurePassword,
              obscureConfirmPassword: _obscureConfirmPassword,
              onTermsChanged: (value) => setState(() => _acceptTerms = value),
              onPasswordVisibilityToggle: () => setState(() => _obscurePassword = !_obscurePassword),
              onConfirmPasswordVisibilityToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              onComplete: _completeRegistration,
              onPrevious: _navigateBack,
              isLoading: _isLoading,
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // Método que puede ser sobrescrito por cada pantalla para personalizar el paso 3
  Widget buildOperationsStep() {
    // Solo acopiador y planta de separación tienen capacidad de prensado
    final showCapacity = providerType == 'Acopiador' || providerType == 'Planta de Separación';
    // Los transportistas siempre tienen transporte y no pueden cambiarlo
    final isTransportLocked = providerType == 'Transportista';
    
    // Obtener materiales según el tipo de usuario
    final tipoActor = _getTipoActor();
    final materialesList = _getMaterialesByTipo(tipoActor);
    
    return OperationsStep(
      controllers: _controllers,
      selectedMaterials: _selectedMaterials,
      hasTransport: hasTransport,
      onMaterialToggle: _toggleMaterial,
      onTransportChanged: isTransportLocked ? (value) {} : (value) => setState(() => hasTransport = value),
      onNext: _nextStep,
      onPrevious: _navigateBack,
      showCapacitySection: showCapacity,
      isTransportLocked: isTransportLocked,
      customMaterials: materialesList,
    );
  }
  
  List<Map<String, String>> _getMaterialesByTipo(String tipoActor) {
    switch (tipoActor) {
      case 'A': // Acopiador (Usuario Origen)
      case 'P': // Planta de Separación (Usuario Origen)
        return [
          {'id': 'ecoce_epf_poli', 'label': 'EPF - Poli (PE)'},
          {'id': 'ecoce_epf_pp', 'label': 'EPF - PP'},
          {'id': 'ecoce_epf_multi', 'label': 'EPF - Multi'},
        ];
      case 'R': // Reciclador
        return [
          {'id': 'ecoce_epf_separados', 'label': 'EPF separados por tipo'},
          {'id': 'ecoce_epf_semiseparados', 'label': 'EPF semiseparados'},
          {'id': 'ecoce_epf_pacas', 'label': 'EPF en pacas'},
          {'id': 'ecoce_epf_sacos', 'label': 'EPF en sacos'},
          {'id': 'ecoce_epf_granel', 'label': 'EPF a granel'},
          {'id': 'ecoce_epf_limpios', 'label': 'EPF limpios'},
          {'id': 'ecoce_epf_cont_leve', 'label': 'EPF con contaminación leve'},
        ];
      case 'T': // Transformador
        return [
          {'id': 'ecoce_pellets_poli', 'label': 'Pellets reciclados - Poli'},
          {'id': 'ecoce_pellets_pp', 'label': 'Pellets reciclados - PP'},
          {'id': 'ecoce_hojuelas_poli', 'label': 'Hojuelas recicladas - Poli'},
          {'id': 'ecoce_hojuelas_pp', 'label': 'Hojuelas recicladas - PP'},
        ];
      case 'L': // Laboratorio
        return [
          {'id': 'ecoce_muestra_pe', 'label': 'Muestras PE'},
          {'id': 'ecoce_muestra_pp', 'label': 'Muestras PP'},
          {'id': 'ecoce_muestra_multi', 'label': 'Muestras Multi'},
          {'id': 'ecoce_hojuelas', 'label': 'Hojuelas'},
          {'id': 'ecoce_pellets', 'label': 'Pellets reciclados'},
          {'id': 'ecoce_productos', 'label': 'Productos transformados'},
        ];
      default:
        return [];
    }
  }

  void _toggleMaterial(String materialId) {
    setState(() {
      if (_selectedMaterials.contains(materialId)) {
        _selectedMaterials.remove(materialId);
      } else {
        _selectedMaterials.add(materialId);
      }
    });
  }

  void _toggleFile(String key) {
    setState(() {
      _selectedFiles[key] = _selectedFiles[key] != null ? null : '$key.pdf';
    });
  }
}