import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import 'origen_crear_lote_screen.dart';
import 'origen_lotes_screen.dart';
import 'origen_ayuda.dart';
import 'origen_perfil.dart';
import 'origen_codigo_qr.dart';
import 'widgets/lote_card.dart';
import 'widgets/stat_card.dart';
import 'widgets/quick_action_card.dart';

class OrigenInicioScreen extends StatefulWidget {
  const OrigenInicioScreen({super.key});

  @override
  State<OrigenInicioScreen> createState() => _OrigenInicioScreenState();
}

class _OrigenInicioScreenState extends State<OrigenInicioScreen> {
  // Índice para la navegación del bottom bar
  int _selectedIndex = 0;

  // Datos del centro de acopio (en producción vendrían de la base de datos)
  final String _nombreCentro = "Centro de Acopio La Esperanza";
  final String _folioCentro = "A0000001";
  final int _lotesCreados = 127;
  final double _materialProcesado = 4.5; // en toneladas

  // Lista de lotes recientes con IDs de Firebase
  final List<Map<String, dynamic>> _lotesRecientes = [
    {
      'firebaseId': 'FID_1x7h9k3',
      'material': 'PEBD',
      'peso': 150.0,
      'presentacion': 'Pacas',
      'fuente': 'Programa Escolar Norte',
      'fecha': '15/07/2025',
    },
    {
      'firebaseId': 'FID_2y8j0l4',
      'material': 'PP',
      'peso': 200.5,
      'presentacion': 'Sacos',
      'fuente': 'Recolección Municipal',
      'fecha': '14/07/2025',
    },
    {
      'firebaseId': 'FID_3z9k1m5',
      'material': 'Multi',
      'peso': 175.0,
      'presentacion': 'Pacas',
      'fuente': 'Centro Comunitario Sur',
      'fecha': '14/07/2025',
    },
  ];

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

  void _downloadLote(String firebaseId) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Descargando lote $firebaseId...'),
        backgroundColor: BioWayColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showQRCode(Map<String, dynamic> lote) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            OrigenCodigoQRScreen(
              firebaseId: lote['firebaseId'],
              material: lote['material'],
              peso: lote['peso'].toDouble(),
              presentacion: lote['presentacion'],
              fuente: lote['fuente'],
              fechaCreacion: DateTime.now(),
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
        Navigator.push(
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
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const OrigenAyudaScreen(),
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
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const OrigenPerfilScreen(),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header moderno con gradiente
            SliverToBoxAdapter(
              child: Container(
                height: 280,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      BioWayColors.ecoceGreen,
                      BioWayColors.ecoceGreen.withOpacity(0.8),
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
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Saludo y fecha
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Buen día 👋',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.9),
                                ),
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
                                      '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
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
                          const SizedBox(height: 16),
                          // Nombre del centro
                          Text(
                            _nombreCentro,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 8),
                          // Badge con tipo y folio
                          Row(
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
                                      color: BioWayColors.ecoceGreen,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Centro de Acopio',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: BioWayColors.ecoceGreen,
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
                          const SizedBox(height: 30),
                          // Tarjetas de estadísticas mejoradas
                          Row(
                            children: [
                              Expanded(
                                child: StatCard(
                                  icon: Icons.inventory_2,
                                  iconColor: BioWayColors.primaryGreen,
                                  value: _lotesCreados.toString(),
                                  label: 'Lotes Creados',
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: StatCard(
                                  icon: Icons.scale,
                                  iconColor: Colors.blue,
                                  value: '$_materialProcesado',
                                  label: 'Toneladas',
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
              child: Transform.translate(
                offset: const Offset(0, -30),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Acciones rápidas con nuevo diseño
                        Row(
                          children: [
                            Expanded(
                              child: QuickActionCard(
                                icon: Icons.add_circle,
                                title: 'Nuevo Lote',
                                subtitle: 'Registrar material',
                                color: BioWayColors.ecoceGreen,
                                onTap: _navigateToNewLot,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: QuickActionCard(
                                icon: Icons.inventory_2,
                                title: 'Ver Lotes',
                                subtitle: 'Historial completo',
                                color: Colors.blue,
                                onTap: _navigateToLotes,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 30),
                        
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
                                      color: BioWayColors.ecoceGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward,
                                    size: 16,
                                    color: BioWayColors.ecoceGreen,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Lista de lotes con nuevo diseño
                        ..._lotesRecientes.map((lote) => LoteCard(
                          lote: lote,
                          onQRTap: () => _showQRCode(lote),
                          onDownloadTap: () => _downloadLote(lote['firebaseId']),
                        )),
                        
                        const SizedBox(height: 100), // Espacio para el FAB
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // Bottom Navigation Bar con FAB
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          color: Colors.white,
          child: SizedBox(
            height: 65,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBottomNavItem(Icons.home_outlined, Icons.home, 'Inicio', 0),
                _buildBottomNavItem(Icons.inventory_2_outlined, Icons.inventory_2, 'Lotes', 1),
                const SizedBox(width: 80), // Espacio para el FAB
                _buildBottomNavItem(Icons.help_outline, Icons.help, 'Ayuda', 2),
                _buildBottomNavItem(Icons.person_outline, Icons.person, 'Perfil', 3),
              ],
            ),
          ),
        ),
      ),

      // Floating Action Button
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              BioWayColors.ecoceGreen,
              BioWayColors.ecoceGreen.withOpacity(0.8),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: BioWayColors.ecoceGreen.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _navigateToNewLot,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(
            Icons.add,
            size: 32,
            color: Colors.white,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }





  Widget _buildBottomNavItem(IconData icon, IconData activeIcon, String label, int index) {
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onBottomNavTapped(index),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? BioWayColors.ecoceGreen : Colors.grey,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? BioWayColors.ecoceGreen : Colors.grey,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}