import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../utils/colors.dart';
import '../widgets/step_widgets.dart';
import '../../../../services/firebase/ecoce_profile_service.dart';
import '../../../../services/firebase/auth_service.dart';
import '../../../../services/firebase/firebase_manager.dart';
import '../../../../services/document_service.dart';

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
  final Map<String, PlatformFile?> _platformFiles = {
    'const_sit_fis': null,
    'comp_domicilio': null,
    'banco_caratula': null,
    'ine': null,
  };
  bool _isUploadingDocuments = false;
  
  // Location data
  LatLng? _selectedLocation;
  String? _selectedAddress;
  
  // Services
  final EcoceProfileService _profileService = EcoceProfileService();
  final AuthService _authService = AuthService();
  final DocumentService _documentService = DocumentService();

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
      // Obtener tipo de usuario y subtipo
      String tipoUsuario = _getTipoUsuario();
      String subtipo = _getSubtipo();
      
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
      double? latitud;
      double? longitud;
      if (_selectedLocation != null) {
        linkMaps = 'https://www.google.com/maps/search/?api=1&query=${_selectedLocation!.latitude},${_selectedLocation!.longitude}';
        latitud = _selectedLocation!.latitude;
        longitud = _selectedLocation!.longitude;
      }
      
      // Primero, crear la solicitud sin documentos para obtener el ID
      setState(() {
        _isUploadingDocuments = true;
      });
      
      // Crear solicitud de cuenta en Firebase (sin crear usuario en Auth)
      final solicitudId = await _profileService.createAccountRequest(
        tipoUsuario: tipoUsuario,
        email: _controllers['email']!.text.trim(),
        password: _controllers['password']!.text,
        subtipo: subtipo,
        nombre: _controllers['nombreComercial']!.text.trim(),
        rfc: _controllers['rfc']!.text.trim(),
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
        documentos: {}, // Inicialmente vacío, se actualizará después
        linkMaps: linkMaps,
        latitud: latitud,
        longitud: longitud,
      );
      
      // Ahora subir los documentos usando el ID de la solicitud
      final uploadedDocs = <String, String?>{};
      
      for (final entry in _platformFiles.entries) {
        if (entry.value != null) {
          try {
            final url = await _documentService.uploadDocument(
              userId: solicitudId, // Usar el ID de la solicitud
              documentType: entry.key,
              file: entry.value!,
              solicitudId: solicitudId,
            );
            uploadedDocs[entry.key] = url;
          } catch (e) {
            // Log error - En producción usar un servicio de logging
            // Continuar con otros documentos aunque uno falle
          }
        }
      }
      
      // Actualizar la solicitud con las URLs de los documentos
      if (uploadedDocs.isNotEmpty) {
        await _updateSolicitudDocuments(solicitudId, uploadedDocs);
      }
      
      setState(() {
        _isLoading = false;
        _isUploadingDocuments = false;
      });
      
      _showSuccessDialog();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = _getErrorMessage(e.toString());
      });
    }
  }
  
  String _getTipoUsuario() {
    switch (providerType) {
      case 'Acopiador':
      case 'Planta de Separación':
        return 'origen';
      case 'Reciclador':
        return 'reciclador';
      case 'Transformador':
        return 'transformador';
      case 'Transportista':
        return 'transportista';
      case 'Laboratorio':
        return 'laboratorio';
      default:
        return 'origen';
    }
  }
  
  String _getSubtipo() {
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
        return 'A'; // Por defecto acopiador para usuarios origen
    }
  }
  
  String _getErrorMessage(String error) {
    if (error.contains('email-already-in-use')) {
      return 'Este correo ya está registrado';
    } else if (error.contains('weak-password')) {
      return 'La contraseña debe tener al menos 6 caracteres';
    } else if (error.contains('invalid-email')) {
      return 'El correo no es válido';
    } else if (error.contains('network-request-failed')) {
      return 'Error de conexión. Verifica tu internet';
    } else if (error.contains('too-many-requests')) {
      return 'Demasiados intentos. Intenta más tarde';
    } else {
      return 'Error al registrar. Intenta nuevamente.';
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 500,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icono de éxito
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: BioWayColors.success.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle_outline,
                      size: 35,
                      color: BioWayColors.success,
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Título
                  Text(
                    '¡Registro exitoso!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: BioWayColors.darkGreen,
                    ),
                  ),
                  SizedBox(height: 8),
                  
                  // Mensaje de solicitud enviada
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: BioWayColors.lightGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Solicitud enviada',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: BioWayColors.primaryGreen,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Mensaje de aprobación pendiente
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: BioWayColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: BioWayColors.warning.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.pending_actions,
                              color: BioWayColors.warning,
                              size: 24,
                            ),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Cuenta pendiente de aprobación',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: BioWayColors.darkGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tu cuenta necesita ser aprobada por ECOCE antes de que puedas acceder.',
                          style: TextStyle(
                            fontSize: 13,
                            color: BioWayColors.textGrey,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: BioWayColors.lightGrey),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Text(
                                  'Próximos pasos:',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: BioWayColors.darkGreen,
                                  ),
                                ),
                              ),
                              SizedBox(height: 8),
                              _buildCompactStep('1', 'ECOCE revisará tus documentos'),
                              _buildCompactStep('2', 'Recibirás notificación por correo'),
                              _buildCompactStep('3', 'Podrás iniciar sesión al ser aprobado'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  
                  // Información adicional
                  Text(
                    'Tu folio se asignará al aprobar tu cuenta',
                    style: TextStyle(
                      fontSize: 11,
                      color: BioWayColors.textGrey,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  
                  // Botón
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BioWayColors.primaryGreen,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Entendido',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: BioWayColors.petBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: BioWayColors.petBlue,
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: BioWayColors.textGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStep(String number, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: BioWayColors.petBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: BioWayColors.petBlue,
                ),
              ),
            ),
          ),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: BioWayColors.textGrey,
                height: 1.3,
              ),
            ),
          ),
        ],
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
          platformFiles: _platformFiles,
          onFileSelected: _handleFileSelected,
          onNext: _nextStep,
          onPrevious: _navigateBack,
          isUploading: _isUploadingDocuments,
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
    
    // Obtener materiales según el subtipo de usuario origen
    final subtipo = _getSubtipo();
    final materialesList = _getMaterialesBySubtipo(subtipo);
    
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
  
  List<Map<String, String>> _getMaterialesBySubtipo(String subtipo) {
    switch (subtipo) {
      case 'A': // Acopiador (Usuario Origen)
      case 'P': // Planta de Separación (Usuario Origen)
        return [
          {'id': 'ecoce_epf_poli', 'label': 'EPF - Poli (PE)'},
          {'id': 'ecoce_epf_pp', 'label': 'EPF - PP'},
          {'id': 'ecoce_epf_multi', 'label': 'EPF - Multi'},
        ];
      case 'R': // Reciclador
        return [
          {'id': 'material_separado', 'label': 'Material Separado'},
          {'id': 'material_pacas', 'label': 'Pacas'},
          {'id': 'material_sacos', 'label': 'Sacos'},
          {'id': 'material_procesado', 'label': 'Material Procesado'},
        ];
      case 'T': // Transformador
        return [
          {'id': 'pellets_pe', 'label': 'Pellets PE'},
          {'id': 'pellets_pp', 'label': 'Pellets PP'},
          {'id': 'flakes_pet', 'label': 'Flakes PET'},
          {'id': 'material_procesado', 'label': 'Material Procesado'},
        ];
      case 'V': // Transportista
        return [
          {'id': 'transporte_general', 'label': 'Transporte General'},
          {'id': 'carga_pesada', 'label': 'Carga Pesada'},
          {'id': 'contenedores', 'label': 'Contenedores'},
        ];
      case 'L': // Laboratorio
        return [
          {'id': 'analisis_composicion', 'label': 'Análisis de Composición'},
          {'id': 'pruebas_calidad', 'label': 'Pruebas de Calidad'},
          {'id': 'certificacion', 'label': 'Certificación'},
        ];
      default:
        return [
          {'id': 'ecoce_epf_poli', 'label': 'EPF - Poli (PE)'},
          {'id': 'ecoce_epf_pp', 'label': 'EPF - PP'},
          {'id': 'ecoce_epf_multi', 'label': 'EPF - Multi'},
        ];
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

  void _handleFileSelected(String key, PlatformFile? file, String? url) {
    setState(() {
      if (file != null) {
        _platformFiles[key] = file;
        _selectedFiles[key] = url ?? 'pending';
      } else {
        _platformFiles[key] = null;
        _selectedFiles[key] = null;
      }
    });
  }
  
  Future<void> _updateSolicitudDocuments(String solicitudId, Map<String, String?> documents) async {
    try {
      final updates = <String, dynamic>{};
      
      // Mapear las URLs a la estructura de datos de la solicitud
      documents.forEach((key, url) {
        if (url != null) {
          updates['datos_perfil.ecoce_$key'] = url;
        }
      });
      
      // Actualizar directamente en Firestore
      if (updates.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('solicitudes_cuentas')
            .doc(solicitudId)
            .update(updates);
      }
    } catch (e) {
      // Log error - En producción usar un servicio de logging
    }
  }
}