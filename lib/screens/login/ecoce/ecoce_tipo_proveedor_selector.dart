import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import '../../../widgets/common/gradient_background.dart';
import 'providers/acopiador_register_screen.dart';
import 'providers/planta_separacion_register_screen.dart';
import 'providers/reciclador_register_screen.dart';
import 'providers/transformador_register_screen.dart';
import 'providers/transportista_register_screen.dart';
import 'providers/laboratorio_register_screen.dart';

/// Modelo para representar un tipo de proveedor
class ProviderType {
  final String code;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final Widget Function() screenBuilder;

  const ProviderType({
    required this.code,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.screenBuilder,
  });
}

class ECOCETipoProveedorSelector extends StatefulWidget {
  const ECOCETipoProveedorSelector({super.key});

  @override
  State<ECOCETipoProveedorSelector> createState() => _ECOCETipoProveedorSelectorState();
}

class _ECOCETipoProveedorSelectorState extends State<ECOCETipoProveedorSelector>
    with TickerProviderStateMixin {
  // Lista de tipos de proveedores (sin Desarrollo de Mercado)
  final List<ProviderType> _providerTypes = [
    ProviderType(
      code: 'A',
      name: 'Acopiador',
      description: 'Centro de acopio de materiales reciclables',
      icon: Icons.warehouse,
      color: BioWayColors.darkGreen,
      screenBuilder: () => const AcopiadorRegisterScreen(),
    ),
    ProviderType(
      code: 'PS',
      name: 'Planta de Separación',
      description: 'Clasificación y separación de materiales',
      icon: Icons.factory,
      color: BioWayColors.ecoceGreen,
      screenBuilder: () => const PlantaSeparacionRegisterScreen(),
    ),
    ProviderType(
      code: 'R',
      name: 'Reciclador',
      description: 'Procesamiento de materiales reciclables',
      icon: Icons.recycling,
      color: BioWayColors.recycleOrange,
      screenBuilder: () => const RecicladorRegisterScreen(),
    ),
    ProviderType(
      code: 'T',
      name: 'Transformador',
      description: 'Manufactura con material reciclado',
      icon: Icons.auto_fix_high,
      color: BioWayColors.petBlue,
      screenBuilder: () => const TransformadorRegisterScreen(),
    ),
    ProviderType(
      code: 'TR',
      name: 'Transportista',
      description: 'Logística de materiales reciclables',
      icon: Icons.local_shipping,
      color: BioWayColors.deepBlue,
      screenBuilder: () => const TransportistaRegisterScreen(),
    ),
    ProviderType(
      code: 'L',
      name: 'Laboratorio',
      description: 'Análisis y certificación de calidad',
      icon: Icons.science,
      color: BioWayColors.otherPurple,
      screenBuilder: () => const LaboratorioRegisterScreen(),
    ),
  ];

  // Controladores de animación
  late AnimationController _headerController;
  late AnimationController _listController;
  late List<AnimationController> _itemControllers;

  // Animaciones
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late List<Animation<double>> _itemAnimations;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    // Header animation
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _headerFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOut,
    ));

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutCubic,
    ));

    // List animation
    _listController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Individual item animations
    _itemControllers = List.generate(
      _providerTypes.length,
          (index) => AnimationController(
        duration: Duration(milliseconds: 400 + (index * 50)),
        vsync: this,
      ),
    );

    _itemAnimations = _itemControllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutCubic,
      ));
    }).toList();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _headerController.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    _listController.forward();

    // Animate items one by one
    for (int i = 0; i < _itemControllers.length; i++) {
      await Future.delayed(const Duration(milliseconds: 80));
      if (mounted) {
        _itemControllers[i].forward();
      }
    }
  }

  @override
  void dispose() {
    _headerController.dispose();
    _listController.dispose();
    for (var controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _navigateBack() {
    HapticFeedback.lightImpact();
    Navigator.pop(context);
  }

  void _navigateToProviderRegister(ProviderType provider) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => provider.screenBuilder(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
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
                        Text(
                          'Registro ECOCE',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: BioWayColors.ecoceGreen,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Sistema de Trazabilidad',
                          style: TextStyle(
                            fontSize: 12,
                            color: BioWayColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: BioWayColors.ecoceGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.recycling,
                      color: BioWayColors.ecoceGreen,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Header animado
                    AnimatedBuilder(
                      animation: _headerController,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: _headerFadeAnimation,
                          child: SlideTransition(
                            position: _headerSlideAnimation,
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: BioWayColors.ecoceGreen.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.business,
                                    size: 60,
                                    color: BioWayColors.ecoceGreen,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Selecciona tu tipo de proveedor',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: BioWayColors.darkGreen,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Cada tipo tiene campos específicos adaptados a su función en la cadena de trazabilidad',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: BioWayColors.textGrey,
                                      height: 1.4,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Lista de tipos de proveedores
                    ...List.generate(_providerTypes.length, (index) {
                      final provider = _providerTypes[index];
                      return AnimatedBuilder(
                        animation: _itemAnimations[index],
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(
                              0,
                              50 * (1 - _itemAnimations[index].value),
                            ),
                            child: Opacity(
                              opacity: _itemAnimations[index].value,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildProviderCard(provider),
                              ),
                            ),
                          );
                        },
                      );
                    }),

                    const SizedBox(height: 20),

                    // Information card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: BioWayColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: BioWayColors.info.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: BioWayColors.info,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Proceso de verificación',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: BioWayColors.darkGreen,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Después del registro, recibirás un código de verificación por correo electrónico para activar tu cuenta.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: BioWayColors.textGrey,
                                    height: 1.4,
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderCard(ProviderType provider) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToProviderRegister(provider),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Code badge
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: provider.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    provider.code,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: provider.color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: provider.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  provider.icon,
                  color: provider.color,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: BioWayColors.darkGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      provider.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: BioWayColors.textGrey,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}