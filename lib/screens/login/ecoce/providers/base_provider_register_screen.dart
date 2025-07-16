import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../utils/colors.dart';
import '../widgets/step_widgets.dart';

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
  final Map<String, String?> _selectedFiles = {
    'const_sit_fis': null,
    'comp_domicilio': null,
    'banco_caratula': null,
    'ine': null,
  };

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

  void _completeRegistration() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final folio = '$folioPrefix${(timestamp % 10000000).toString().padLeft(7, '0')}';
    _showSuccessDialog(folio);
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
        return CredentialsStep(
          controllers: _controllers,
          acceptTerms: _acceptTerms,
          obscurePassword: _obscurePassword,
          obscureConfirmPassword: _obscureConfirmPassword,
          onTermsChanged: (value) => setState(() => _acceptTerms = value),
          onPasswordVisibilityToggle: () => setState(() => _obscurePassword = !_obscurePassword),
          onConfirmPasswordVisibilityToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          onComplete: _completeRegistration,
          onPrevious: _navigateBack,
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
    );
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