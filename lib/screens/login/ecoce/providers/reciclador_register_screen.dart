import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../utils/colors.dart';
import '../widgets/common_fields_form.dart';

class RecicladorRegisterScreen extends StatefulWidget {
  const RecicladorRegisterScreen({super.key});

  @override
  State<RecicladorRegisterScreen> createState() => _RecicladorRegisterScreenState();
}

class _RecicladorRegisterScreenState extends State<RecicladorRegisterScreen>
    with SingleTickerProviderStateMixin {
  // Form keys
  final _formKey = GlobalKey<FormState>();

  // Form data
  late CommonFormData _formData;

  // Estados
  bool _isLoading = false;
  String _generatedFolio = '';

  // Animación
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _formData = CommonFormData(tipoActor: 'Reciclador');
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
    _animationController.dispose();
    super.dispose();
  }

  void _generateFolio() {
    // Simulación de generación de folio para Reciclador
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final lastDigits = (timestamp % 10000).toString().padLeft(4, '0');
    _generatedFolio = 'R0000$lastDigits';
  }

  void _navigateBack() {
    HapticFeedback.lightImpact();
    Navigator.pop(context);
  }

  Future<void> _submitForm() async {
    // Validar formulario
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
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
                    color: BioWayColors.ecoceGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _generatedFolio,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: BioWayColors.ecoceGreen,
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
                    backgroundColor: BioWayColors.ecoceGreen,
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
                        color: BioWayColors.ecoceGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        color: BioWayColors.ecoceGreen,
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
                                color: BioWayColors.ecoceGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'R',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: BioWayColors.ecoceGreen,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Registro Reciclador',
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
                          'Procesamiento de materiales',
                          style: TextStyle(
                            fontSize: 12,
                            color: BioWayColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.recycling,
                    color: BioWayColors.ecoceGreen,
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
                              BioWayColors.ecoceGreen.withOpacity(0.1),
                              BioWayColors.ecoceGreen.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: BioWayColors.ecoceGreen.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.qr_code_2,
                              color: BioWayColors.ecoceGreen,
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
                                color: BioWayColors.ecoceGreen,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Formulario común - El Reciclador solo usa campos comunes
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

                      // Información adicional específica para Reciclador
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: BioWayColors.info.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: BioWayColors.info.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: BioWayColors.info,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Información para Recicladores',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: BioWayColors.darkGreen,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildInfoItem('Como reciclador podrás procesar materiales de múltiples acopiadores'),
                            _buildInfoItem('Recibirás notificaciones de materiales disponibles en tu zona'),
                            _buildInfoItem('Podrás establecer tarifas preferenciales según el volumen'),
                            _buildInfoItem('Acceso a reportes de trazabilidad completa'),
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
                            backgroundColor: BioWayColors.ecoceGreen,
                            elevation: _isLoading ? 0 : 3,
                            shadowColor: BioWayColors.ecoceGreen.withOpacity(0.4),
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

  Widget _buildInfoItem(String text) {
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
              color: BioWayColors.info,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: BioWayColors.textGrey,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}