import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../utils/colors.dart';
import '../widgets/common_fields_form.dart';

class PlantaSeparacionRegisterScreen extends StatefulWidget {
  const PlantaSeparacionRegisterScreen({super.key});

  @override
  State<PlantaSeparacionRegisterScreen> createState() => _PlantaSeparacionRegisterScreenState();
}

class _PlantaSeparacionRegisterScreenState extends State<PlantaSeparacionRegisterScreen>
    with SingleTickerProviderStateMixin {
  // Form keys
  final _formKey = GlobalKey<FormState>();

  // Form data
  late CommonFormData _formData;

  // Campos específicos de Planta de Separación (opcionales)
  final _dimensionesController = TextEditingController();
  final _pesoController = TextEditingController();

  // Estados
  bool _isLoading = false;
  String _generatedFolio = '';
  bool _includeCapacity = false; // Para mostrar/ocultar campos opcionales

  // Animación
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _formData = CommonFormData(tipoActor: 'Planta de Separación');
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
    _dimensionesController.dispose();
    _pesoController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _generateFolio() {
    // Simulación de generación de folio
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final lastDigits = (timestamp % 10000).toString().padLeft(4, '0');
    _generatedFolio = 'P0000$lastDigits';
  }

  void _navigateBack() {
    HapticFeedback.lightImpact();
    Navigator.pop(context);
  }

  Future<void> _submitForm() async {
    // Validar formulario principal
    final isCommonValid = _formKey.currentState?.validate() ?? false;

    if (!isCommonValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor completa todos los campos obligatorios'),
          backgroundColor: BioWayColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    // Validar materiales
    if (_formData.listaMateriales.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Selecciona al menos un material'),
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

    // Simular envío al servidor
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isLoading = false);

      // Mostrar diálogo de éxito
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
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
                Text(
                  'Tu folio de registro es:',
                  style: TextStyle(
                    fontSize: 16,
                    color: BioWayColors.textGrey,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: BioWayColors.hdpeGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _generatedFolio,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: BioWayColors.hdpeGreen,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: BioWayColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.email,
                        color: BioWayColors.info,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tu cuenta ha sido creada. Revisa tu correo para verificar tu cuenta.',
                          style: TextStyle(
                            fontSize: 13,
                            color: BioWayColors.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context); // Volver al selector
                    Navigator.pop(context); // Volver al login
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BioWayColors.hdpeGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Volver al inicio'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BioWayColors.ecoceLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
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
              child: Row(
                children: [
                  IconButton(
                    onPressed: _navigateBack,
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: BioWayColors.hdpeGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        color: BioWayColors.hdpeGreen,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: BioWayColors.hdpeGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'P',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: BioWayColors.hdpeGreen,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Registro Planta de Separación',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: BioWayColors.darkGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Clasificación de materiales',
                          style: TextStyle(
                            fontSize: 12,
                            color: BioWayColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.sort,
                    color: BioWayColors.hdpeGreen,
                    size: 32,
                  ),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Folio generado
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              BioWayColors.hdpeGreen.withOpacity(0.1),
                              BioWayColors.hdpeGreen.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: BioWayColors.hdpeGreen.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.qr_code_2,
                              color: BioWayColors.hdpeGreen,
                              size: 40,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Folio asignado:',
                              style: TextStyle(
                                fontSize: 14,
                                color: BioWayColors.darkGreen,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _generatedFolio,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: BioWayColors.hdpeGreen,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Formulario común
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: CommonFieldsForm(
                          formKey: _formKey,
                          formData: _formData,
                          showTransportField: true,
                          onDataChanged: (data) {
                            setState(() {
                              _formData = data;
                            });
                          },
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Campos opcionales de capacidad
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Título con switch
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: BioWayColors.hdpeGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.compress,
                                    color: BioWayColors.hdpeGreen,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Capacidad de Prensado',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: BioWayColors.darkGreen,
                                          ),
                                        ),
                                        Text(
                                          'Opcional',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: BioWayColors.textGrey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: _includeCapacity,
                                    onChanged: (value) {
                                      setState(() {
                                        _includeCapacity = value;
                                        if (!value) {
                                          // Limpiar campos si se desactiva
                                          _dimensionesController.clear();
                                          _pesoController.clear();
                                        }
                                      });
                                    },
                                    activeColor: BioWayColors.hdpeGreen,
                                  ),
                                ],
                              ),
                            ),

                            // Campos opcionales
                            if (_includeCapacity) ...[
                              const SizedBox(height: 20),
                              _buildDimensionsField(),
                              const SizedBox(height: 16),
                              _buildWeightField(),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: BioWayColors.info.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: BioWayColors.info.withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: BioWayColors.info,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Incluir esta información puede mejorar la coordinación logística',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: BioWayColors.info,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Botón de envío
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BioWayColors.hdpeGreen,
                            elevation: _isLoading ? 0 : 3,
                            shadowColor: BioWayColors.hdpeGreen.withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                              : const Text(
                            'Completar Registro',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDimensionsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.straighten, color: BioWayColors.hdpeGreen, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Dimensiones (Metros)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: BioWayColors.darkGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _dimensionesController,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: '15.25 X 15.20',
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            helperText: 'Formato: largo X ancho (ejemplo: 15.25 X 15.20)',
            helperStyle: const TextStyle(fontSize: 12),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: BioWayColors.hdpeGreen, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildWeightField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.fitness_center, color: BioWayColors.hdpeGreen, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Peso máximo (Kg)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: BioWayColors.darkGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _pesoController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,3}')),
          ],
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: '500.5',
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            helperText: 'Peso máximo que puede prensar en kilogramos',
            helperStyle: const TextStyle(fontSize: 12),
            suffixText: 'Kg',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: BioWayColors.hdpeGreen, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}