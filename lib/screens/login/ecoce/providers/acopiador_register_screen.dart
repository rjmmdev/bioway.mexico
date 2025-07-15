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
  final int _totalSteps = 4;

  // Form keys para cada paso
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();
  final _step3FormKey = GlobalKey<FormState>();
  final _step4FormKey = GlobalKey<FormState>();

  // Datos del formulario (almacenamos todo aquí)
  final Map<String, dynamic> _formData = {
    'tipo_actor': 'A', // A para Acopiador
    'folio': '',
    // Paso 1: Información básica
    'nombre': '', // nombre_comercial
    'rfc': '',
    'nombre_contacto': '',
    'tel_contacto': '', // teléfono móvil
    'tel_empresa': '', // teléfono oficina
    // Paso 2: Ubicación
    'calle': '',
    'num_ext': '',
    'cp': '',
    'colonia': '',
    'ciudad': '',
    'estado': '',
    'ref_ubi': '', // referencias
    'link_maps': '', // se generará automáticamente
    'poligono_loc': '', // se asignará automáticamente
    // Paso 3: Información operativa
    'lista_materiales': '',
    'transporte': false,
    'dim_cap': '', // dimensiones capacidad (obligatorio para acopiador)
    'peso_cap': '', // peso capacidad (obligatorio para acopiador)
    'link_red_social': '', // opcional
    // Paso 4: Credenciales y documentos
    'correo_contacto': '',
    'password': '',
    'confirmPassword': '',
    'const_sit_fis': null, // archivo PDF opcional
    'comp_domicilio': null, // archivo PDF opcional
    'banco_caratula': null, // archivo PDF opcional
    'ine': null, // archivo PDF opcional
    'acceptTerms': false,
    'fecha_reg': '', // se asignará automáticamente
  };

  // Controladores Paso 1
  final _nombreComercialController = TextEditingController();
  final _rfcController = TextEditingController();
  final _nombreContactoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _telefonoOficinaController = TextEditingController();

  // Controladores Paso 2
  final _codigoPostalController = TextEditingController();
  final _direccionController = TextEditingController();
  final _numExtController = TextEditingController();
  final _coloniaController = TextEditingController();
  final _ciudadController = TextEditingController();
  final _estadoController = TextEditingController();
  final _referenciasController = TextEditingController();

  // Estados
  bool _isLoading = false;
  String _generatedFolio = '';
  bool _isSearchingCP = false;

  // Animación
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _generateFolio();
    _setupAnimation();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
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
    _animationController.dispose();
    super.dispose();
  }

  void _generateFolio() {
    // El folio se generará al completar el registro
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
    // Guardar datos del paso actual (sin validación por ahora - solo diseño visual)
    switch (_currentStep) {
      case 1:
        _formData['nombre'] = _nombreComercialController.text;
        _formData['rfc'] = _rfcController.text;
        _formData['nombre_contacto'] = _nombreContactoController.text;
        _formData['tel_contacto'] = _telefonoController.text;
        _formData['tel_empresa'] = _telefonoOficinaController.text;
        break;
      case 2:
        _formData['calle'] = _direccionController.text;
        _formData['num_ext'] = _numExtController.text;
        _formData['cp'] = _codigoPostalController.text;
        _formData['colonia'] = _coloniaController.text;
        _formData['ciudad'] = _ciudadController.text;
        _formData['estado'] = _estadoController.text;
        _formData['ref_ubi'] = _referenciasController.text;
        // link_maps y poligono_loc se generarán automáticamente
        break;
    // Los demás casos se implementarán en los siguientes pasos
    }

    // Navegar al siguiente paso sin validación
    if (_currentStep < _totalSteps) {
      setState(() {
        _currentStep++;
        _animationController.reset();
        _animationController.forward();
      });
    }
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: List.generate(_totalSteps * 2 - 1, (index) {
          // Índices pares son círculos, impares son líneas
          if (index % 2 == 0) {
            // Círculo del paso
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
            // Línea conectora
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
          style: TextStyle(
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
          style: TextStyle(
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
              prefixIcon: Icon(Icons.business, color: BioWayColors.petBlue),
              filled: true,
              fillColor: BioWayColors.lightGrey.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: BioWayColors.lightGrey,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: BioWayColors.petBlue,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: BioWayColors.error,
                  width: 1,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'El nombre comercial es obligatorio';
              }
              return null;
            },
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
              prefixIcon: Icon(Icons.article, color: BioWayColors.petBlue),
              filled: true,
              fillColor: BioWayColors.lightGrey.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: BioWayColors.lightGrey,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
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
              prefixIcon: Icon(Icons.person, color: BioWayColors.petBlue),
              filled: true,
              fillColor: BioWayColors.lightGrey.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: BioWayColors.lightGrey,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: BioWayColors.petBlue,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: BioWayColors.error,
                  width: 1,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'El nombre del contacto es obligatorio';
              }
              return null;
            },
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
                    prefixIcon: Icon(Icons.phone_android, color: BioWayColors.petBlue),
                    filled: true,
                    fillColor: BioWayColors.lightGrey.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: BioWayColors.lightGrey,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: BioWayColors.petBlue,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: BioWayColors.error,
                        width: 1,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Teléfono obligatorio';
                    }
                    return null;
                  },
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
                    prefixIcon: Icon(Icons.phone, color: BioWayColors.petBlue),
                    filled: true,
                    fillColor: BioWayColors.lightGrey.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: BioWayColors.lightGrey,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
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
                    Icon(
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
                          prefixIcon: Icon(
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
                            borderSide: BorderSide(
                              color: BioWayColors.lightGrey,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: BioWayColors.petBlue,
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          if (value.length == 5) {
                            // Simular búsqueda de código postal
                            setState(() {
                              _isSearchingCP = true;
                            });
                            Future.delayed(const Duration(seconds: 1), () {
                              setState(() {
                                _isSearchingCP = false;
                                // Simular datos encontrados
                                _coloniaController.text = 'Centro';
                                _ciudadController.text = 'Querétaro';
                                _estadoController.text = 'Querétaro';
                              });
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
                    prefixIcon: Icon(Icons.home, color: BioWayColors.petBlue),
                    filled: true,
                    fillColor: BioWayColors.lightGrey.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: BioWayColors.lightGrey,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
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
                    prefixIcon: Icon(Icons.numbers, color: BioWayColors.petBlue),
                    filled: true,
                    fillColor: BioWayColors.lightGrey.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: BioWayColors.lightGrey,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
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
              prefixIcon: Icon(Icons.location_city, color: BioWayColors.petBlue),
              filled: true,
              fillColor: BioWayColors.lightGrey.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: BioWayColors.lightGrey,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
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
                    prefixIcon: Icon(Icons.location_city, color: BioWayColors.petBlue),
                    filled: true,
                    fillColor: BioWayColors.lightGrey.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: BioWayColors.lightGrey,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
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
                    prefixIcon: Icon(Icons.map, color: BioWayColors.petBlue),
                    filled: true,
                    fillColor: BioWayColors.lightGrey.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: BioWayColors.lightGrey,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
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
              prefixIcon: Padding(
                padding: const EdgeInsets.only(bottom: 60),
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
                borderSide: BorderSide(
                  color: BioWayColors.lightGrey,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
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
                  // Botón de ubicación exacta
                  if (_codigoPostalController.text.length == 5)
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
                    side: BorderSide(color: BioWayColors.petBlue),
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
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Operations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepTitle(
          'Información Operativa',
          'Materiales y capacidad de tu centro',
        ),
        const SizedBox(height: 32),

        // Placeholder para el paso 3
        Container(
          height: 300,
          decoration: BoxDecoration(
            color: BioWayColors.lightGrey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: BioWayColors.lightGrey,
              width: 2,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.recycling,
                  size: 48,
                  color: BioWayColors.petBlue,
                ),
                const SizedBox(height: 16),
                Text(
                  'Materiales y capacidad',
                  style: TextStyle(
                    fontSize: 16,
                    color: BioWayColors.textGrey,
                  ),
                ),
              ],
            ),
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
                  side: BorderSide(color: BioWayColors.petBlue),
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
        ),
      ],
    );
  }

  Widget _buildStep4Credentials() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepTitle(
          'Credenciales de Acceso',
          'Correo, contraseña y términos',
        ),
        const SizedBox(height: 32),

        // Placeholder para el paso 4
        Container(
          height: 300,
          decoration: BoxDecoration(
            color: BioWayColors.lightGrey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: BioWayColors.lightGrey,
              width: 2,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock,
                  size: 48,
                  color: BioWayColors.petBlue,
                ),
                const SizedBox(height: 16),
                Text(
                  'Credenciales y términos',
                  style: TextStyle(
                    fontSize: 16,
                    color: BioWayColors.textGrey,
                  ),
                ),
              ],
            ),
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
                  side: BorderSide(color: BioWayColors.petBlue),
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
                  final lastDigits = (timestamp % 10000).toString().padLeft(4, '0');
                  final folio = 'A0000$lastDigits';

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
                                    // Aquí se navegaría a la pantalla de verificación
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _navigateBack();
        return false;
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
                                child: Icon(
                                  Icons.warehouse,
                                  color: BioWayColors.petBlue,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
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
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: _currentStep == 1
                        ? _buildStep1BasicInfo()
                        : _currentStep == 2
                        ? _buildStep2Location()
                        : _currentStep == 3
                        ? _buildStep3Operations()
                        : _buildStep4Credentials(),
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