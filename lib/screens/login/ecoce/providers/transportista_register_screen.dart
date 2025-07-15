import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../utils/colors.dart';
import '../widgets/common_fields_form.dart';

class TransportistaRegisterScreen extends StatefulWidget {
  const TransportistaRegisterScreen({super.key});

  @override
  State<TransportistaRegisterScreen> createState() => _TransportistaRegisterScreenState();
}

class _TransportistaRegisterScreenState extends State<TransportistaRegisterScreen>
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
    _formData = CommonFormData(tipoActor: 'Transportista');
    // IMPORTANTE: Auto-asignar transporte como true para transportistas
    _formData.transporte = true;
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
    // Simulación de generación de folio para Transportista
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final lastDigits = (timestamp % 10000).toString().padLeft(4, '0');
    _generatedFolio = 'V0000$lastDigits';
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
          content: const Text('Selecciona al menos un material que transportas'),
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
                    color: BioWayColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _generatedFolio,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: BioWayColors.info,
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
                    backgroundColor: BioWayColors.info,
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
                        color: BioWayColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        color: BioWayColors.info,
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
                                color: BioWayColors.info.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'V',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: BioWayColors.info,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Registro Transportista',
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
                          'Logística de materiales reciclables',
                          style: TextStyle(
                            fontSize: 12,
                            color: BioWayColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.local_shipping,
                    color: BioWayColors.info,
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
                              BioWayColors.info.withOpacity(0.1),
                              BioWayColors.info.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: BioWayColors.info.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.qr_code_2,
                              color: BioWayColors.info,
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
                                color: BioWayColors.info,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Aviso especial para transportistas
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: BioWayColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: BioWayColors.success.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.local_shipping,
                              color: BioWayColors.success,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Transporte propio confirmado',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: BioWayColors.darkGreen,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Como transportista, se registra automáticamente que cuentas con vehículos propios',
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

                      const SizedBox(height: 24),

                      // Formulario común - Sin el campo de transporte propio
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
                          showTransportField: false, // NO mostrar campo de transporte
                          onDataChanged: (data) {
                            setState(() {
                              _formData = data;
                              // Asegurar que siempre sea true
                              _formData.transporte = true;
                            });
                          },
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Información adicional para transportistas
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
                                  Icons.directions_bus,
                                  color: BioWayColors.info,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Servicios de Transporte ECOCE',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: BioWayColors.darkGreen,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildServiceItem(
                              'Rutas optimizadas entre proveedores',
                              Icons.route,
                            ),
                            _buildServiceItem(
                              'Tarifas preferenciales por volumen',
                              Icons.attach_money,
                            ),
                            _buildServiceItem(
                              'Trazabilidad GPS en tiempo real',
                              Icons.gps_fixed,
                            ),
                            _buildServiceItem(
                              'Documentación digital automatizada',
                              Icons.description,
                            ),
                            _buildServiceItem(
                              'Seguro de carga incluido',
                              Icons.security,
                            ),
                            _buildServiceItem(
                              'Capacitación en manejo de materiales',
                              Icons.school,
                            ),
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
                            backgroundColor: BioWayColors.info,
                            elevation: _isLoading ? 0 : 3,
                            shadowColor: BioWayColors.info.withOpacity(0.4),
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

  Widget _buildServiceItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: BioWayColors.info,
            size: 18,
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