import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../utils/colors.dart';
import '../../../utils/format_utils.dart';
import '../../../services/user_session_service.dart';
import '../../../models/ecoce/ecoce_profile_model.dart';
import 'origen_crear_lote_screen.dart';
import 'origen_lotes_screen.dart';
import '../shared/ecoce_ayuda_screen.dart';
import '../shared/ecoce_perfil_screen.dart';
import 'origen_lote_detalle_screen.dart';
import 'widgets/origen_lote_card.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import '../shared/widgets/unified_stat_card.dart';

class OrigenInicioScreen extends StatefulWidget {
  const OrigenInicioScreen({super.key});

  @override
  State<OrigenInicioScreen> createState() => _OrigenInicioScreenState();
}

class _OrigenInicioScreenState extends State<OrigenInicioScreen> {
  // Índice para la navegación del bottom bar
  final int _selectedIndex = 0;
  
  // Servicio de sesión
  final UserSessionService _sessionService = UserSessionService();
  
  // Datos del usuario
  EcoceProfileModel? _userProfile;
  bool _isLoading = true;

  String get _nombreCentro => _userProfile?.ecoceNombre ?? 'Cargando...';
  String get _folioCentro => _userProfile?.ecoceFolio ?? 'PENDIENTE';
  String get _tipoCentro => _userProfile?.tipoActorLabel ?? 'Usuario Origen';
  Color get _primaryColor {
    if (_userProfile?.ecoceSubtipo == 'A') {
      return BioWayColors.darkGreen;
    } else if (_userProfile?.ecoceSubtipo == 'P') {
      return BioWayColors.ppPurple;
    }
    return BioWayColors.ecoceGreen;
  }

  final int _lotesCreados = 127;
  final double _materialProcesado = 4.5; // en toneladas

  // Lista de lotes recientes con IDs de Firebase
  final List<Map<String, dynamic>> _lotesRecientes = [
    {
      'id': 'FID_1x7h9k3',
      'firebaseId': 'FID_1x7h9k3',
      'material': 'PEBD',
      'peso': 150.0,
      'presentacion': 'Pacas',
      'fuente': 'Programa Escolar Norte',
      'fecha': DateTime.now().subtract(const Duration(days: 1)),
      'estado': 'activo',
    },
    {
      'id': 'FID_2y8j0l4',
      'firebaseId': 'FID_2y8j0l4',
      'material': 'PP',
      'peso': 200.5,
      'presentacion': 'Sacos',
      'fuente': 'Recolección Municipal',
      'fecha': DateTime.now().subtract(const Duration(days: 2)),
      'estado': 'activo',
    },
    {
      'id': 'FID_3z9k1m5',
      'firebaseId': 'FID_3z9k1m5',
      'material': 'Multi',
      'peso': 175.0,
      'presentacion': 'Pacas',
      'fuente': 'Centro Comunitario Sur',
      'fecha': DateTime.now().subtract(const Duration(days: 2)),
      'estado': 'activo',
    },
  ];
  
  @override
  void initState() {
    super.initState();
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

  void _navigateToNewLot() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const OrigenCrearLoteScreen(),
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

  void _navigateToLotes() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const OrigenLotesScreen(),
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


  void _showQRCode(Map<String, dynamic> lote) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            OrigenLoteDetalleScreen(
              firebaseId: lote['firebaseId'],
              material: lote['material'],
              peso: lote['peso'].toDouble(),
              presentacion: lote['presentacion'],
              fuente: lote['fuente'],
              fechaCreacion: lote['fecha'] ?? DateTime.now(),
              mostrarMensajeExito: false,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
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

  void _onBottomNavTapped(int index) {
    HapticFeedback.lightImpact();
    
    if (index == _selectedIndex) return;
    
    switch (index) {
      case 0:
        // Ya estamos en inicio
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const OrigenLotesScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const EcoceAyudaScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const EcocePerfilScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Center(
          child: CircularProgressIndicator(
            color: BioWayColors.ecoceGreen,
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          // Header moderno con gradiente que se extiende hasta arriba
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _primaryColor,
                    _primaryColor.withOpacity(0.8),
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
                          color: Colors.white.withOpacity(0.1),
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
                          color: Colors.white.withOpacity(0.05),
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
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 14,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      FormatUtils.formatDate(DateTime.now()),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Nombre del centro
                          Text(
                            _nombreCentro,
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
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.store,
                                      size: 16,
                                      color: _primaryColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _tipoCentro,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _folioCentro,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Estadísticas con UnifiedStatCard
                          Row(
                            children: [
                              // Estadística de Lotes
                              Expanded(
                                child: UnifiedStatCard.horizontal(
                                  title: 'Lotes creados',
                                  value: _lotesCreados.toString(),
                                  icon: Icons.inventory_2,
                                  color: Colors.blue,
                                  height: 70,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Estadística de Material
                              Expanded(
                                child: UnifiedStatCard.horizontal(
                                  title: 'Material procesado',
                                  value: '$_materialProcesado',
                                  unit: 'ton',
                                  icon: Icons.scale,
                                  color: Colors.green,
                                  height: 70,
                                ),
                              ),
                            ],
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
                        // Acción rápida única centrada más compacta
                        Container(
                          width: double.infinity,
                          height: 70,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                _primaryColor,
                                _primaryColor.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: _primaryColor.withOpacity(0.3),
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
                              onTap: _navigateToNewLot,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
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
                                            'Registrar Nuevo Lote',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            'Genera código QR para tu material',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.white.withOpacity(0.9),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.white.withOpacity(0.8),
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Sección de lotes recientes
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Lotes Recientes',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            TextButton(
                              onPressed: _navigateToLotes,
                              child: Row(
                                children: [
                                  Text(
                                    'Ver todos',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward,
                                    size: 16,
                                    color: _primaryColor,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Lista de lotes con nuevo diseño
                        ..._lotesRecientes.map((lote) => OrigenLoteCard(
                          lote: lote,
                          onQRTap: () => _showQRCode(lote),
                          showActions: true,
                        )),
                        
                        const SizedBox(height: 100), // Espacio para el FAB
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

      // Bottom Navigation Bar con FAB
      bottomNavigationBar: EcoceBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onBottomNavTapped,
        primaryColor: BioWayColors.ecoceGreen,
        items: EcoceNavigationConfigs.origenItems,
        fabConfig: FabConfig(
          icon: Icons.add,
          onPressed: _navigateToNewLot,
          tooltip: 'Nuevo Lote',
        ),
      ),
      
      // Floating Action Button
      floatingActionButton: EcoceFloatingActionButton(
        onPressed: _navigateToNewLot,
        icon: Icons.add,
        backgroundColor: _primaryColor,
        tooltip: 'Nuevo Lote',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }





}