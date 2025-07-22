import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../utils/colors.dart';
import '../../../utils/format_utils.dart';
import '../../../services/firebase/ecoce_profile_service.dart';
import '../../../services/firebase/auth_service.dart';
import 'laboratorio_escaneo.dart';
import 'laboratorio_gestion_muestras.dart';
import 'laboratorio_formulario.dart';
import 'laboratorio_documentacion.dart';
import '../shared/ecoce_ayuda_screen.dart';
import '../shared/ecoce_perfil_screen.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import 'widgets/laboratorio_muestra_card.dart';
import '../shared/widgets/unified_stat_card.dart';
import '../shared/utils/navigation_utils.dart';

class LaboratorioInicioScreen extends StatefulWidget {
  const LaboratorioInicioScreen({super.key});

  @override
  State<LaboratorioInicioScreen> createState() => _LaboratorioInicioScreenState();
}

class _LaboratorioInicioScreenState extends State<LaboratorioInicioScreen> {
  // Índice para la navegación del bottom bar
  final int _selectedIndex = 0;
  
  // Servicios
  final EcoceProfileService _profileService = EcoceProfileService();
  final AuthService _authService = AuthService();
  
  // Datos del usuario
  String _nombreLaboratorio = "Cargando...";
  String _folioLaboratorio = "L0000000";
  int _muestrasRecibidas = 0;
  double _materialAnalizado = 0.0; // en kg
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    try {
      final User? currentUser = _authService.currentUser;
      if (currentUser != null) {
        final profile = await _profileService.getProfile(currentUser.uid);
        if (profile != null && mounted) {
          setState(() {
            _nombreLaboratorio = profile.ecoceNombre ?? "Laboratorio";
            _folioLaboratorio = profile.ecoceFolio ?? "L0000000";
            // Los valores de estadísticas se cargarían de la base de datos
            _muestrasRecibidas = 128; // TODO: Cargar de Firebase
            _materialAnalizado = 856.5; // TODO: Cargar de Firebase
          });
        }
      }
    } catch (e) {
      debugPrint('Error cargando datos del usuario: $e');
    }
  }

  // Lista de muestras con diferentes estados (datos de ejemplo)
  final List<Map<String, dynamic>> _muestrasRecientes = [
    {
      'id': 'M001',
      'fecha': '14/07/2025',
      'peso': 2.5,
      'material': 'PEBD',
      'origen': 'Reciclador Norte',
      'presentacion': 'Muestra',
      'estado': 'formulario', // Requiere formulario
    },
    {
      'id': 'M002',
      'fecha': '14/07/2025',
      'peso': 1.8,
      'material': 'PP',
      'origen': 'Reciclador Sur',
      'presentacion': 'Muestra',
      'estado': 'documentacion', // Requiere documentación
    },
    {
      'id': 'M003',
      'fecha': '13/07/2025',
      'peso': 3.2,
      'material': 'Multilaminado',
      'origen': 'Reciclador Centro',
      'presentacion': 'Muestra',
      'estado': 'finalizado', // Completado
    },
    {
      'id': 'M004',
      'fecha': '13/07/2025',
      'peso': 2.0,
      'material': 'PEBD',
      'origen': 'Reciclador Este',
      'presentacion': 'Muestra',
      'estado': 'formulario', // Requiere formulario
    },
  ];

  void _navigateToNewMuestra() {
    HapticFeedback.lightImpact();
    NavigationUtils.navigateWithSlide(
      context,
      const LaboratorioEscaneoScreen(),
    );
  }

  void _navigateToMuestrasControl() {
    HapticFeedback.lightImpact();
    NavigationUtils.navigateWithSlide(
      context,
      const LaboratorioGestionMuestras(),
    );
  }

  void _onBottomNavTapped(int index) {
    HapticFeedback.lightImpact();
    
    if (index == _selectedIndex) return;
    
    switch (index) {
      case 0:
        // Ya estamos en inicio
        break;
      case 1:
        NavigationUtils.navigateWithFade(
          context,
          const LaboratorioGestionMuestras(),
        );
        break;
      case 2:
        NavigationUtils.navigateWithFade(
          context,
          const EcoceAyudaScreen(),
        );
        break;
      case 3:
        NavigationUtils.navigateWithFade(
          context,
          const EcocePerfilScreen(),
        );
        break;
    }
  }

  // Obtener texto del botón según el estado
  String _getActionButtonText(String estado) {
    switch (estado) {
      case 'formulario':
        return 'Formulario';
      case 'documentacion':
        return 'Ingresar Documentación';
      case 'finalizado':
        return '';
      default:
        return '';
    }
  }

  // Obtener color del botón según el estado
  Color _getActionButtonColor(String estado) {
    switch (estado) {
      case 'formulario':
        return BioWayColors.error; // Rojo
      case 'documentacion':
        return BioWayColors.warning; // Naranja
      case 'finalizado':
        return BioWayColors.success; // Verde
      default:
        return BioWayColors.ecoceGreen;
    }
  }

  // Manejar tap en muestra según su estado
  void _handleMuestraTap(Map<String, dynamic> muestra) {
    HapticFeedback.lightImpact();
    
    switch (muestra['estado']) {
      case 'formulario':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LaboratorioFormulario(
              muestraId: muestra['id'],
              peso: muestra['peso'].toDouble(),
            ),
          ),
        );
        break;
      case 'documentacion':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LaboratorioDocumentacion(
              muestraId: muestra['id'],
            ),
          ),
        );
        break;
      case 'finalizado':
        // No hacer nada para muestras finalizadas
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header moderno con gradiente
            SliverToBoxAdapter(
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF9333EA), // Purple para laboratorio
                      const Color(0xFF9333EA).withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Patrón de fondo
                    Positioned(
                      right: -50,
                      top: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -30,
                      bottom: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    // Contenido
                    Padding(
                      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Logo ECOCE y fecha
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Logo ECOCE
                              SvgPicture.asset(
                                'assets/logos/ecoce_logo.svg',
                                width: 70,
                                height: 35,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 14,
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      FormatUtils.formatDate(DateTime.now()),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withValues(alpha: 0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Nombre del laboratorio
                          Text(
                            _nombreLaboratorio,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.visible,
                          ),
                          const SizedBox(height: 8),
                          // Badge con tipo y folio
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.science,
                                      size: 16,
                                      color: const Color(0xFF9333EA), // Purple para laboratorio
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Laboratorio',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF9333EA), // Purple para laboratorio
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF9333EA), // Purple para laboratorio
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _folioLaboratorio,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Estadísticas con UnifiedStatCard
                          SizedBox(
                            height: 70,
                            child: Row(
                              children: [
                                // Estadística de Muestras Recibidas
                                Expanded(
                                  child: UnifiedStatCard.horizontal(
                                    title: 'Muestras recibidas',
                                    value: _muestrasRecibidas.toString(),
                                    icon: Icons.science,
                                    color: Colors.blue,
                                    height: 70,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Estadística de Material Analizado
                                Expanded(
                                  child: UnifiedStatCard.horizontal(
                                    title: 'Material analizado',
                                    value: _materialAnalizado.toStringAsFixed(1),
                                    unit: 'kg',
                                    icon: Icons.analytics,
                                    color: Colors.purple,
                                    height: 70,
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

            // Contenido principal
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.only(top: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Acción rápida con diseño unificado
                      Container(
                        width: double.infinity,
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF9333EA), // Purple para laboratorio
                              const Color(0xFF9333EA).withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF9333EA).withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _navigateToNewMuestra,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.add_circle_outline,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Registrar Nueva Muestra',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          'Escanea código QR del lote',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.white.withValues(alpha: 0.9),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.white.withValues(alpha: 0.8),
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Sección de muestras recientes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Muestras Recientes',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          TextButton(
                            onPressed: _navigateToMuestrasControl,
                            child: Row(
                              children: [
                                Text(
                                  'Ver todos',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: const Color(0xFF9333EA), // Purple para laboratorio
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward,
                                  size: 16,
                                  color: const Color(0xFF9333EA), // Purple para laboratorio
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Lista de muestras con nuevo diseño y botones según estado
                      ..._muestrasRecientes.map((muestra) {
                        // Para muestras finalizadas, no mostrar botón de acción
                        if (muestra['estado'] == 'finalizado') {
                          return LaboratorioMuestraCard(
                            muestra: muestra,
                            onTap: null,
                            showActionButton: false,
                            showActions: false,
                          );
                        }
                        
                        // Para otros estados, mostrar botón debajo
                        return LaboratorioMuestraCard(
                          muestra: muestra,
                          onTap: () => _handleMuestraTap(muestra),
                          showActionButton: true,
                          actionButtonText: _getActionButtonText(muestra['estado']),
                          actionButtonColor: _getActionButtonColor(muestra['estado']),
                          onActionPressed: () => _handleMuestraTap(muestra),
                          showActions: true, // Mostrar flecha lateral
                        );
                      }),
                      
                      const SizedBox(height: 100), // Espacio para el FAB
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      
      // Bottom Navigation Bar con FAB
      bottomNavigationBar: EcoceBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onBottomNavTapped,
        primaryColor: const Color(0xFF9333EA), // Purple color for laboratorio
        items: const [
          NavigationItem(
            icon: Icons.home,
            label: 'Inicio',
            testKey: 'laboratorio_nav_inicio',
          ),
          NavigationItem(
            icon: Icons.science,
            label: 'Muestras',
            testKey: 'laboratorio_nav_muestras',
          ),
          NavigationItem(
            icon: Icons.help_outline,
            label: 'Ayuda',
            testKey: 'laboratorio_nav_ayuda',
          ),
          NavigationItem(
            icon: Icons.person,
            label: 'Perfil',
            testKey: 'laboratorio_nav_perfil',
          ),
        ],
        fabConfig: FabConfig(
          icon: Icons.add,
          onPressed: _navigateToNewMuestra,
          tooltip: 'Nueva muestra',
        ),
      ),
      
      // Floating Action Button
      floatingActionButton: EcoceFloatingActionButton(
        onPressed: _navigateToNewMuestra,
        icon: Icons.add,
        backgroundColor: const Color(0xFF9333EA),
        tooltip: 'Nueva muestra',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }
}