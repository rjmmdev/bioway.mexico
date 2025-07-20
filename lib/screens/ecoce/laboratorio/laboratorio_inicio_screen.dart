import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import '../../../services/user_session_service.dart';
import '../../../models/ecoce/ecoce_profile_model.dart';
import '../shared/widgets/unified_stat_card.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';

class LaboratorioInicioScreen extends StatefulWidget {
  const LaboratorioInicioScreen({super.key});

  @override
  State<LaboratorioInicioScreen> createState() => _LaboratorioInicioScreenState();
}

class _LaboratorioInicioScreenState extends State<LaboratorioInicioScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Servicio de sesión
  final UserSessionService _sessionService = UserSessionService();
  
  // Datos del usuario
  EcoceProfileModel? _userProfile;
  bool _isLoading = true;
  
  // Datos del usuario autenticado
  String get _nombreLaboratorio => _userProfile?.ecoceNombre ?? 'Cargando...';
  String get _folioLaboratorio => _userProfile?.ecoceFolio ?? 'PENDIENTE';
  
  // Estadísticas (temporalmente hardcodeadas hasta tener API)
  final int _muestrasAnalizadas = 156;
  final int _certificadosEmitidos = 142;
  final int _muestrasPendientes = 8;
  
  // Lista de muestras recientes
  final List<Map<String, dynamic>> _muestrasRecientes = [
    {
      'id': 'LAB_2025_001',
      'origen': 'RECICLADOR DEL NORTE',
      'material': 'PET',
      'fecha': '19/07/2025',
      'estado': 'En análisis',
      'estadoColor': BioWayColors.warning,
      'tipoAnalisis': 'Composición química',
    },
    {
      'id': 'LAB_2025_002',
      'origen': 'TRANSFORMADOR CENTRAL',
      'material': 'HDPE',
      'fecha': '18/07/2025',
      'estado': 'Completado',
      'estadoColor': BioWayColors.success,
      'tipoAnalisis': 'Propiedades mecánicas',
    },
    {
      'id': 'LAB_2025_003',
      'origen': 'PLANTA DE SEPARACIÓN SUR',
      'material': 'PP',
      'fecha': '17/07/2025',
      'estado': 'Pendiente',
      'estadoColor': BioWayColors.info,
      'tipoAnalisis': 'Contaminantes',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    try {
      final profile = await _sessionService.getCurrentUserProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToNuevaMuestra() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Función de nueva muestra en desarrollo'),
        backgroundColor: BioWayColors.info,
      ),
    );
  }

  void _navigateToAnalisis() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Función de análisis en desarrollo'),
        backgroundColor: BioWayColors.info,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Center(
          child: CircularProgressIndicator(
            color: BioWayColors.otherPurple,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Header con gradiente
          Container(
            padding: const EdgeInsets.only(top: 40, bottom: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  BioWayColors.otherPurple,
                  BioWayColors.otherPurple.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Text(
                    'Laboratorio',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.06,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _nombreLaboratorio,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: screenWidth * 0.04,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Contenido principal
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await Future.delayed(const Duration(seconds: 1));
              },
              color: BioWayColors.otherPurple,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Información del laboratorio
                      _buildInfoSection(screenWidth),
                      SizedBox(height: screenHeight * 0.02),
                      
                      // Estadísticas
                      _buildStatsSection(screenWidth, isTablet),
                      SizedBox(height: screenHeight * 0.02),
                      
                      // Acciones rápidas
                      _buildQuickActions(screenWidth),
                      SizedBox(height: screenHeight * 0.02),
                      
                      // Muestras recientes
                      _buildRecentSamples(screenWidth),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: EcoceBottomNavigation(
        selectedIndex: 0,
        onItemTapped: (index) {
          // Manejar navegación según el índice
          switch (index) {
            case 0:
              // Ya estamos en inicio
              break;
            case 1:
              // Navegar a otra pantalla
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Navegación en desarrollo'),
                  backgroundColor: BioWayColors.info,
                ),
              );
              break;
            case 2:
              Navigator.pushNamed(context, '/laboratorio_perfil');
              break;
          }
        },
        items: const [
          NavigationItem(
            icon: Icons.home,
            label: 'Inicio',
          ),
          NavigationItem(
            icon: Icons.science,
            label: 'Análisis',
          ),
          NavigationItem(
            icon: Icons.person,
            label: 'Perfil',
          ),
        ],
        primaryColor: BioWayColors.otherPurple,
      ),
    );
  }

  Widget _buildInfoSection(double screenWidth) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: BioWayColors.otherPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.science,
              color: BioWayColors.otherPurple,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nombreLaboratorio,
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.bold,
                    color: BioWayColors.darkGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Folio: $_folioLaboratorio',
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(double screenWidth, bool isTablet) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isTablet ? 3 : 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: isTablet ? 1.5 : 1.3,
      children: [
        UnifiedStatCard(
          label: 'Muestras\nAnalizadas',
          value: _muestrasAnalizadas.toString(),
          icon: Icons.analytics,
          iconColor: BioWayColors.success,
          unit: 'total',
        ),
        UnifiedStatCard(
          label: 'Certificados\nEmitidos',
          value: _certificadosEmitidos.toString(),
          icon: Icons.verified,
          iconColor: BioWayColors.petBlue,
          unit: 'total',
        ),
        UnifiedStatCard(
          label: 'Muestras\nPendientes',
          value: _muestrasPendientes.toString(),
          icon: Icons.pending_actions,
          iconColor: BioWayColors.warning,
          unit: 'en espera',
        ),
      ],
    );
  }

  Widget _buildQuickActions(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acciones Rápidas',
          style: TextStyle(
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeight.bold,
            color: BioWayColors.darkGreen,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _navigateToNuevaMuestra();
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        BioWayColors.otherPurple,
                        BioWayColors.otherPurple.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: BioWayColors.otherPurple.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.add_circle_outline,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nueva Muestra',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.035,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _navigateToAnalisis();
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        BioWayColors.info,
                        BioWayColors.info.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: BioWayColors.info.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.science_outlined,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Análisis',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.035,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentSamples(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Muestras Recientes',
          style: TextStyle(
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeight.bold,
            color: BioWayColors.darkGreen,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(_muestrasRecientes.length, (index) {
          final muestra = _muestrasRecientes[index];
          return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Detalle de muestra ${muestra['id']} en desarrollo'),
                  backgroundColor: BioWayColors.info,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: muestra['estadoColor'].withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.science,
                      color: muestra['estadoColor'],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          muestra['id'],
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.bold,
                            color: BioWayColors.darkGreen,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${muestra['origen']} - ${muestra['material']}',
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          muestra['tipoAnalisis'],
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: muestra['estadoColor'].withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: muestra['estadoColor'],
                            width: 1,
                          ),
                        ),
                        child: Text(
                          muestra['estado'],
                          style: TextStyle(
                            fontSize: screenWidth * 0.03,
                            fontWeight: FontWeight.w600,
                            color: muestra['estadoColor'],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        muestra['fecha'],
                        style: TextStyle(
                          fontSize: screenWidth * 0.03,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );}),
      ],
    );
  }
}