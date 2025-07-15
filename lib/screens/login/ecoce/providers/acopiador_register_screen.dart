import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../utils/colors.dart';

class AcopiadorRegisterScreen extends StatefulWidget {
  const AcopiadorRegisterScreen({super.key});

  @override
  State<AcopiadorRegisterScreen> createState() => _AcopiadorRegisterScreenState();
}

class _AcopiadorRegisterScreenState extends State<AcopiadorRegisterScreen>
    with SingleTickerProviderStateMixin {
  // Controladores de pasos
  int _currentStep = 1;
  static const int _totalSteps = 4;

  // Form keys para cada paso
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();
  final _step3FormKey = GlobalKey<FormState>();
  final _step4FormKey = GlobalKey<FormState>();

  // Controladores para todos los campos
  final _nombreComercialController = TextEditingController();
  final _rfcController = TextEditingController();
  final _nombreContactoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _telefonoOficinaController = TextEditingController();
  final _codigoPostalController = TextEditingController();
  final _direccionController = TextEditingController();
  final _numExtController = TextEditingController();
  final _coloniaController = TextEditingController();
  final _ciudadController = TextEditingController();
  final _estadoController = TextEditingController();
  final _referenciasController = TextEditingController();
  final _dimensionesController = TextEditingController();
  final _pesoController = TextEditingController();
  final _linkRedSocialController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Estados
  bool _isLoading = false;
  String _generatedFolio = '';
  bool _isSearchingCP = false;
  final Set<String> _selectedMaterials = {};
  bool _hasTransport = false;
  bool _acceptTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Archivos seleccionados (simulado)
  Map<String, String?> _selectedFiles = {
    'const_sit_fis': null,
    'comp_domicilio': null,
    'banco_caratula': null,
    'ine': null,
  };

  // Animación
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Lista de materiales EPF's
  static const List<Map<String, dynamic>> _materials = [
    {'id': 'pe_limpio', 'name': 'PE Limpio', 'color': BioWayColors.petBlue, 'desc': 'Polietileno sin contaminación'},
    {'id': 'pe_sucio', 'name': 'PE Sucio', 'color': BioWayColors.info, 'desc': 'Polietileno con residuos'},
    {'id': 'multicapa_pe_pp', 'name': 'Multicapa PE/PP', 'color': BioWayColors.ppOrange, 'desc': 'Laminados PE/PP'},
    {'id': 'multicapa_pe_pet', 'name': 'Multicapa PE/PET', 'color': BioWayColors.warning, 'desc': 'Laminados PE/PET'},
    {'id': 'multicapa_pe_pa', 'name': 'Multicapa PE/PA', 'color': BioWayColors.otherPurple, 'desc': 'PE/Poliamida'},
    {'id': 'multicapa_pe_evoh', 'name': 'Multicapa PE/EVOH', 'color': BioWayColors.deepGreen, 'desc': 'Barrera de oxígeno'},
    {'id': 'bopp', 'name': 'BOPP', 'color': BioWayColors.hdpeGreen, 'desc': 'Polipropileno biorientado'},
    {'id': 'cpp', 'name': 'CPP', 'color': BioWayColors.success, 'desc': 'Polipropileno cast'},
    {'id': 'ldpe', 'name': 'LDPE', 'color': BioWayColors.turquoise, 'desc': 'Polietileno baja densidad'},
    {'id': 'hdpe', 'name': 'HDPE', 'color': BioWayColors.ecoceGreen, 'desc': 'Polietileno alta densidad'},
    {'id': 'lldpe', 'name': 'LLDPE', 'color': BioWayColors.primaryGreen, 'desc': 'PE lineal baja densidad'},
    {'id': 'metalizado', 'name': 'Film Metalizado', 'color': BioWayColors.metalGrey, 'desc': 'Con capa de aluminio'},
    {'id': 'stretch', 'name': 'Stretch Film', 'color': BioWayColors.darkGrey, 'desc': 'Film estirable'},
    {'id': 'termoencogible', 'name': 'Termoencogible', 'color': BioWayColors.error, 'desc': 'Film retráctil'},
  ];

  @override
  void initState() {
    super.initState();
    _generateFolio();
    _setupAnimation();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _nombreComercialController.dispose();
    _rfcController.dispose();
    _nombreContactoController.dispose();
    _telefonoController.dispose();
    _telefonoOficinaController.dispose();
    _codigoPostalController.dispose();
    _direccionController.dispose();
    _numExtController.dispose();
    _coloniaController.dispose();
    _ciudadController.dispose();
    _estadoController.dispose();
    _referenciasController.dispose();
    _dimensionesController.dispose();
    _pesoController.dispose();
    _linkRedSocialController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _generateFolio() {
    _generatedFolio = '';
  }

  void _navigateBack() {
    HapticFeedback.lightImpact();
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _nextStep() {
    // Para diseño visual - siempre permite avanzar
    if (_currentStep < _totalSteps) {
      setState(() {
        _currentStep++;
        _animationController.reset();
        _animationController.forward();
      });
    }
  }

  Widget _buildProgressIndicator() {
    return SizedBox(
      height: 60,
      child: Row(
        children: List.generate(_totalSteps * 2 - 1, (index) {
          if (index % 2 == 0) {
            final stepNumber = (index ~/ 2) + 1;
            final isActive = stepNumber == _currentStep;
            final isCompleted = stepNumber < _currentStep;

            return Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive || isCompleted
                    ? BioWayColors.petBlue
                    : BioWayColors.lightGrey,
                border: Border.all(
                  color: isActive
                      ? BioWayColors.petBlue
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                )
                    : Text(
                  stepNumber.toString(),
                  style: TextStyle(
                    color: isActive ? Colors.white : BioWayColors.textGrey,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          } else {
            final lineIndex = index ~/ 2;
            final isCompleted = lineIndex < _currentStep - 1;

            return Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: isCompleted
                    ? BioWayColors.petBlue
                    : BioWayColors.lightGrey,
              ),
            );
          }
        }),
      ),
    );
  }

  Widget _buildStepTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paso $_currentStep de $_totalSteps',
          style: const TextStyle(
            fontSize: 14,
            color: BioWayColors.petBlue,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: BioWayColors.darkGreen,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: BioWayColors.textGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildStep1BasicInfo() {
    return Form(
      key: _step1FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle(
            'Información Básica',
            'Datos principales de tu centro de acopio',
          ),
          const SizedBox(height: 32),

          // Nombre Comercial
          TextFormField(
            controller: _nombreComercialController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Nombre Comercial *',
              hintText: 'Ej: Centro de Acopio San Juan',
              prefixIcon: const Icon(Icons.business, color: BioWayColors.petBlue),
              filled: true,
              fillColor: BioWayColors.lightGrey.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: BioWayColors.lightGrey,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: BioWayColors.petBlue,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // RFC (Opcional)
          TextFormField(
            controller: _rfcController,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              LengthLimitingTextInputFormatter(13),
              FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
            ],
            decoration: InputDecoration(
              labelText: 'RFC (Opcional)',
              hintText: 'XXXX000000XXX',
              helperText: 'Tienes 30 días para proporcionarlo',
              prefixIcon: const Icon(Icons.article, color: BioWayColors.petBlue),
              filled: true,
              fillColor: BioWayColors.lightGrey.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: BioWayColors.lightGrey,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: BioWayColors.petBlue,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Nombre del Contacto
          TextFormField(
            controller: _nombreContactoController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Nombre del Contacto *',
              hintText: 'Nombre completo',
              prefixIcon: const Icon(Icons.person, color: BioWayColors.petBlue),
              filled: true,
              fillColor: BioWayColors.lightGrey.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: BioWayColors.lightGrey,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: BioWayColors.petBlue,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Teléfonos en fila
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _telefonoController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(15),
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Teléfono Móvil *',
                    hintText: '10 dígitos',
                    prefixIcon: const Icon(Icons.phone_android, color: BioWayColors.petBlue),
                    filled: true,
                    fillColor: BioWayColors.lightGrey.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: BioWayColors.lightGrey,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: BioWayColors.petBlue,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _telefonoOficinaController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(15),
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Teléfono Oficina',
                    hintText: 'Opcional',
                    prefixIcon: const Icon(Icons.phone, color: BioWayColors.petBlue),
                    filled: true,
                    fillColor: BioWayColors.lightGrey.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: BioWayColors.lightGrey,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: BioWayColors.petBlue,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),

          // Botón Continuar
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: BioWayColors.petBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continuar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Location() {
    return Form(
      key: _step2FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle(
            'Ubicación',
            'Dirección de tu centro de acopio',
          ),
          const SizedBox(height: 32),

          // Código Postal
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  BioWayColors.petBlue.withOpacity(0.05),
                  BioWayColors.petBlue.withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: BioWayColors.petBlue.withOpacity(0.2),
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
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Código Postal',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: BioWayColors.darkGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ingresa tu código postal para facilitar la búsqueda',
                  style: TextStyle(
                    fontSize: 14,
                    color: BioWayColors.textGrey,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _codigoPostalController,
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
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: BioWayColors.lightGrey,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: BioWayColors.petBlue,
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          if (value.length == 5) {
                            setState(() {
                              _isSearchingCP = true;
                            });
                            Future.delayed(const Duration(seconds: 1), () {
                              if (mounted) {
                                setState(() {
                                  _isSearchingCP = false;
                                  _coloniaController.text = 'Centro';
                                  _ciudadController.text = 'Querétaro';
                                  _estadoController.text = 'Querétaro';
                                });
                              }
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: _isSearchingCP ? 40 : 0,
                      child: _isSearchingCP
                          ? const CircularProgressIndicator(
                        strokeWidth: 2,
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
          ),
          const SizedBox(height: 24),

          // Dirección - Calle y Número
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _direccionController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Nombre de calle *',
                    hintText: 'Ej: Av. Universidad',
                    prefixIcon: const Icon(Icons.home, color: BioWayColors.petBlue),
                    filled: true,
                    fillColor: BioWayColors.lightGrey.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: BioWayColors.lightGrey,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: BioWayColors.petBlue,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _numExtController,
                  keyboardType: TextInputType.text,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Núm. Exterior *',
                    hintText: '123',
                    prefixIcon: const Icon(Icons.numbers, color: BioWayColors.petBlue),
                    filled: true,
                    fillColor: BioWayColors.lightGrey.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: BioWayColors.lightGrey,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: BioWayColors.petBlue,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Colonia
          TextFormField(
            controller: _coloniaController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Colonia *',
              hintText: 'Nombre de la colonia',
              prefixIcon: const Icon(Icons.location_city, color: BioWayColors.petBlue),
              filled: true,
              fillColor: BioWayColors.lightGrey.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: BioWayColors.lightGrey,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: BioWayColors.petBlue,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Ciudad y Estado en fila
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _ciudadController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Ciudad *',
                    hintText: 'Ciudad',
                    prefixIcon: const Icon(Icons.location_city, color: BioWayColors.petBlue),
                    filled: true,
                    fillColor: BioWayColors.lightGrey.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: BioWayColors.lightGrey,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: BioWayColors.petBlue,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _estadoController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Estado *',
                    hintText: 'Estado',
                    prefixIcon: const Icon(Icons.map, color: BioWayColors.petBlue),
                    filled: true,
                    fillColor: BioWayColors.lightGrey.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: BioWayColors.lightGrey,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: BioWayColors.petBlue,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Referencias de ubicación
          TextFormField(
            controller: _referenciasController,
            maxLines: 3,
            maxLength: 150,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Referencias de ubicación *',
              hintText: 'Ej: Frente a la iglesia, entrada lateral',
              alignLabelWithHint: true,
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 60),
                child: Icon(Icons.near_me, color: BioWayColors.petBlue),
              ),
              filled: true,
              fillColor: BioWayColors.lightGrey.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: BioWayColors.lightGrey,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: BioWayColors.petBlue,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Vista previa del mapa
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: BioWayColors.lightGrey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: BioWayColors.lightGrey,
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
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
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _codigoPostalController.text.length == 5
                                ? 'Mapa de la zona ${_codigoPostalController.text}'
                                : 'El mapa se mostrará al ingresar el CP',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_codigoPostalController.text.length == 5)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: ElevatedButton.icon(
                        onPressed: () {},
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
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),

          // Botones de navegación
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildStep3Operations() {
    return Form(
      key: _step3FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle(
            'Información Operativa',
            'Materiales EPF\'s y capacidad de tu centro',
          ),
          const SizedBox(height: 32),

          // Selección de materiales EPF's
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: BioWayColors.lightGrey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: BioWayColors.lightGrey,
                width: 1,
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
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Materiales EPF\'s que recibes *',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: BioWayColors.darkGreen,
                            ),
                          ),
                          Text(
                            'Empaques Plásticos Flexibles postconsumo',
                            style: TextStyle(
                              fontSize: 12,
                              color: BioWayColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Selecciona todos los tipos de materiales flexibles que acopias',
                  style: TextStyle(
                    fontSize: 14,
                    color: BioWayColors.textGrey,
                  ),
                ),
                const SizedBox(height: 16),

                // Grid de materiales
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _materials.map((material) {
                    return _MaterialItem(
                      material: material,
                      isSelected: _selectedMaterials.contains(material['id']),
                      onTap: () {
                        setState(() {
                          if (_selectedMaterials.contains(material['id'])) {
                            _selectedMaterials.remove(material['id']);
                          } else {
                            _selectedMaterials.add(material['id']);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Transporte propio
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: BioWayColors.lightGrey,
                width: 1,
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
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '¿Cuentas con transporte propio?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: BioWayColors.darkGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Para recolección de materiales',
                        style: TextStyle(
                          fontSize: 14,
                          color: BioWayColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _hasTransport,
                  onChanged: (value) {
                    setState(() {
                      _hasTransport = value;
                    });
                  },
                  activeColor: BioWayColors.petBlue,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Capacidad de prensado (OBLIGATORIO para Acopiador)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  BioWayColors.petBlue.withOpacity(0.05),
                  BioWayColors.petBlue.withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: BioWayColors.petBlue.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.compress,
                      color: BioWayColors.petBlue,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Capacidad de Prensado',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: BioWayColors.darkGreen,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: BioWayColors.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'OBLIGATORIO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Información importante para coordinar la logística',
                  style: TextStyle(
                    fontSize: 14,
                    color: BioWayColors.textGrey,
                  ),
                ),
                const SizedBox(height: 16),

                // Dimensiones
                TextFormField(
                  controller: _dimensionesController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Dimensiones (metros) *',
                    hintText: 'Ej: 15.25 X 15.20',
                    helperText: 'Formato: largo X ancho',
                    prefixIcon: const Icon(Icons.straighten, color: BioWayColors.petBlue),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: BioWayColors.lightGrey,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: BioWayColors.petBlue,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Peso
                TextFormField(
                  controller: _pesoController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,3}')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Peso máximo (kg) *',
                    hintText: 'Ej: 500.5',
                    prefixIcon: const Icon(Icons.scale, color: BioWayColors.petBlue),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: BioWayColors.lightGrey,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: BioWayColors.petBlue,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Link de red social (opcional)
          TextFormField(
            controller: _linkRedSocialController,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: 'Página web o red social (opcional)',
              hintText: 'https://www.ejemplo.com',
              prefixIcon: const Icon(Icons.language, color: BioWayColors.petBlue),
              filled: true,
              fillColor: BioWayColors.lightGrey.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: BioWayColors.lightGrey,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: BioWayColors.petBlue,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),

          // Botones de navegación
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildStep4Credentials() {
    return Form(
      key: _step4FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle(
            'Credenciales de Acceso',
            'Correo, contraseña y términos',
          ),
          const SizedBox(height: 32),

          // Sección de credenciales
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: BioWayColors.lightGrey,
                width: 1,
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
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Datos de Acceso',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: BioWayColors.darkGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Correo electrónico
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico *',
                    hintText: 'ejemplo@correo.com',
                    prefixIcon: const Icon(Icons.email, color: BioWayColors.petBlue),
                    filled: true,
                    fillColor: BioWayColors.lightGrey.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: BioWayColors.lightGrey,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: BioWayColors.petBlue,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Contraseña
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña *',
                    hintText: 'Mínimo 6 caracteres',
                    prefixIcon: const Icon(Icons.lock, color: BioWayColors.petBlue),
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
                    filled: true,
                    fillColor: BioWayColors.lightGrey.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: BioWayColors.lightGrey,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: BioWayColors.petBlue,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Confirmar contraseña
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirmar contraseña *',
                    hintText: 'Repite tu contraseña',
                    prefixIcon: const Icon(Icons.lock_outline, color: BioWayColors.petBlue),
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
                    filled: true,
                    fillColor: BioWayColors.lightGrey.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: BioWayColors.lightGrey,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: BioWayColors.petBlue,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Documentos fiscales opcionales
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: BioWayColors.lightGrey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: BioWayColors.lightGrey,
                width: 1,
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
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Documentos Fiscales',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: BioWayColors.darkGreen,
                          ),
                        ),
                        Text(
                          'Opcional - Puedes subirlos después',
                          style: TextStyle(
                            fontSize: 12,
                            color: BioWayColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Lista de documentos
                _buildDocumentUpload(
                  'Constancia de Situación Fiscal',
                  'const_sit_fis',
                  Icons.description,
                ),
                const SizedBox(height: 12),
                _buildDocumentUpload(
                  'Comprobante de Domicilio',
                  'comp_domicilio',
                  Icons.home_work,
                ),
                const SizedBox(height: 12),
                _buildDocumentUpload(
                  'Carátula de Estado de Cuenta',
                  'banco_caratula',
                  Icons.account_balance,
                ),
                const SizedBox(height: 12),
                _buildDocumentUpload(
                  'INE/Identificación Oficial',
                  'ine',
                  Icons.badge,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Términos y condiciones
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  BioWayColors.petBlue.withOpacity(0.05),
                  BioWayColors.petBlue.withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: BioWayColors.petBlue.withOpacity(0.3),
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
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Términos y Condiciones',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: BioWayColors.darkGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _acceptTerms,
                      onChanged: (value) {
                        setState(() {
                          _acceptTerms = value ?? false;
                        });
                      },
                      activeColor: BioWayColors.petBlue,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'He leído y acepto los términos y condiciones de uso y el aviso de privacidad de ECOCE.',
                              style: TextStyle(
                                fontSize: 14,
                                color: BioWayColors.darkGreen,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 16,
                              children: [
                                TextButton(
                                  onPressed: () {},
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Ver términos y condiciones',
                                    style: TextStyle(
                                      color: BioWayColors.petBlue,
                                      fontSize: 12,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {},
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Ver aviso de privacidad',
                                    style: TextStyle(
                                      color: BioWayColors.petBlue,
                                      fontSize: 12,
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
          ),
          const SizedBox(height: 40),

          // Botones de navegación
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _currentStep--;
                      _animationController.reset();
                      _animationController.forward();
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: BioWayColors.petBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Anterior',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Generar folio al completar
                    final timestamp = DateTime.now().millisecondsSinceEpoch;
                    final randomDigits = (timestamp % 10000000).toString().padLeft(7, '0');
                    final folio = 'A$randomDigits';

                    // Mostrar diálogo de éxito con el folio
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return Dialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: BioWayColors.success.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_circle,
                                    size: 40,
                                    color: BioWayColors.success,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  '¡Registro exitoso!',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: BioWayColors.darkGreen,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Tu cuenta ha sido creada correctamente',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: BioWayColors.textGrey,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: BioWayColors.petBlue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: BioWayColors.petBlue.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      const Text(
                                        'Tu folio de registro es:',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: BioWayColors.darkGreen,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        folio,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: BioWayColors.darkGreen,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      Navigator.of(context).pop();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: BioWayColors.petBlue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    child: const Text(
                                      'Continuar',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BioWayColors.success,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check,
                        color: Colors.white,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Completar Registro',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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

  Widget _buildDocumentUpload(String title, String key, IconData icon) {
    final hasFile = _selectedFiles[key] != null;

    return InkWell(
      onTap: () {
        // Simular selección de archivo
        setState(() {
          _selectedFiles[key] = hasFile ? null : '$title.pdf';
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: hasFile
              ? BioWayColors.success.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasFile
                ? BioWayColors.success
                : BioWayColors.lightGrey,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: hasFile ? BioWayColors.success : BioWayColors.textGrey,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: hasFile ? FontWeight.bold : FontWeight.normal,
                      color: hasFile ? BioWayColors.success : BioWayColors.darkGreen,
                    ),
                  ),
                  Text(
                    hasFile ? _selectedFiles[key]! : 'Toca para seleccionar archivo PDF',
                    style: const TextStyle(
                      fontSize: 12,
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

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _currentStep--;
                _animationController.reset();
                _animationController.forward();
              });
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: BioWayColors.petBlue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Anterior',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: BioWayColors.petBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Continuar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _navigateBack();
        }
      },
      child: Scaffold(
        backgroundColor: BioWayColors.backgroundGrey,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: _navigateBack,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: BioWayColors.lightGrey.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: BioWayColors.darkGreen,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: BioWayColors.petBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.warehouse,
                                  color: BioWayColors.petBlue,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Registro Acopiador',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: BioWayColors.darkGreen,
                                      ),
                                    ),
                                    Text(
                                      'Centro de acopio de materiales',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: BioWayColors.textGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildProgressIndicator(),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - 40,
                          ),
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
        return _buildStep1BasicInfo();
      case 2:
        return _buildStep2Location();
      case 3:
        return _buildStep3Operations();
      case 4:
        return _buildStep4Credentials();
      default:
        return const SizedBox.shrink();
    }
  }
}

// Widget optimizado para los items de material
class _MaterialItem extends StatelessWidget {
  final Map<String, dynamic> material;
  final bool isSelected;
  final VoidCallback onTap;

  const _MaterialItem({
    required this.material,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? material['color'].withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? material['color']
                : BioWayColors.lightGrey,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: material['color'],
                  width: 2,
                ),
                color: isSelected
                    ? material['color']
                    : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                Icons.check,
                size: 16,
                color: Colors.white,
              )
                  : null,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    material['name'],
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected
                          ? material['color']
                          : BioWayColors.darkGreen,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    material['desc'],
                    style: const TextStyle(
                      fontSize: 10,
                      color: BioWayColors.textGrey,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}