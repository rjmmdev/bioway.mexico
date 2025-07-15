
// Archivo: acopiador_register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../utils/colors.dart';
import '../widgets/form_field_builder.dart';
import '../widgets/step_widgets.dart';
import '../widgets/material_selector.dart';
import '../widgets/document_uploader.dart';

class AcopiadorRegisterScreen extends StatefulWidget {
  const AcopiadorRegisterScreen({super.key});

  @override
  State<AcopiadorRegisterScreen> createState() => _AcopiadorRegisterScreenState();
}

class _AcopiadorRegisterScreenState extends State<AcopiadorRegisterScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 1;
  static const int _totalSteps = 4;

  // Controladores para todos los campos
  final Map<String, TextEditingController> _controllers = {
    'nombreComercial': TextEditingController(),
    'rfc': TextEditingController(),
    'nombreContacto': TextEditingController(),
    'telefono': TextEditingController(),
    'telefonoOficina': TextEditingController(),
    'codigoPostal': TextEditingController(),
    'direccion': TextEditingController(),
    'numExt': TextEditingController(),
    'colonia': TextEditingController(),
    'ciudad': TextEditingController(),
    'estado': TextEditingController(),
    'referencias': TextEditingController(),
    'dimensiones': TextEditingController(),
    'peso': TextEditingController(),
    'linkRedSocial': TextEditingController(),
    'email': TextEditingController(),
    'password': TextEditingController(),
    'confirmPassword': TextEditingController(),
  };

  // Estados
  bool _isSearchingCP = false;
  final Set<String> _selectedMaterials = {};
  bool _hasTransport = false;
  bool _acceptTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  Map<String, String?> _selectedFiles = {
    'const_sit_fis': null,
    'comp_domicilio': null,
    'banco_caratula': null,
    'ine': null,
  };

  // Animación
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    _controllers.values.forEach((controller) => controller.dispose());
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
    final folio = 'A${(timestamp % 10000000).toString().padLeft(7, '0')}';
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
      onPopInvoked: (didPop) {
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
                onBackPressed: _navigateBack,
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
          isSearchingCP: _isSearchingCP,
          onCPChanged: _handleCPSearch,
          onNext: _nextStep,
          onPrevious: _navigateBack,
        );
      case 3:
        return OperationsStep(
          controllers: _controllers,
          selectedMaterials: _selectedMaterials,
          hasTransport: _hasTransport,
          onMaterialToggle: _toggleMaterial,
          onTransportChanged: (value) => setState(() => _hasTransport = value),
          onNext: _nextStep,
          onPrevious: _navigateBack,
        );
      case 4:
        return CredentialsStep(
          controllers: _controllers,
          selectedFiles: _selectedFiles,
          acceptTerms: _acceptTerms,
          obscurePassword: _obscurePassword,
          obscureConfirmPassword: _obscureConfirmPassword,
          onFileToggle: _toggleFile,
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

  void _handleCPSearch(String cp) {
    if (cp.length == 5) {
      setState(() => _isSearchingCP = true);
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _isSearchingCP = false;
            _controllers['colonia']!.text = 'Centro';
            _controllers['ciudad']!.text = 'Querétaro';
            _controllers['estado']!.text = 'Querétaro';
          });
        }
      });
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