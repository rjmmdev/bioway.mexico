import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import 'origen_crear_lote_screen.dart';
import 'origen_lotes_screen.dart';
import 'origen_perfil.dart';

class OrigenAyudaScreen extends StatefulWidget {
  const OrigenAyudaScreen({super.key});

  @override
  State<OrigenAyudaScreen> createState() => _OrigenAyudaScreenState();
}

class _OrigenAyudaScreenState extends State<OrigenAyudaScreen> {
  // Índice para la navegación del bottom bar
  int _selectedIndex = 2; // Ayuda está seleccionado
  
  final List<Map<String, dynamic>> _guiasPasoAPaso = [
    {
      'icono': Icons.add_circle_outline,
      'titulo': 'Cómo crear un nuevo lote',
      'descripcion': 'Aprende a registrar material entrante y generar códigos QR',
      'duracion': '5 min',
      'color': BioWayColors.primaryGreen,
    },
    {
      'icono': Icons.qr_code_scanner,
      'titulo': 'Cómo usar los códigos QR',
      'descripcion': 'Descubre cómo imprimir y pegar los códigos en tus lotes',
      'duracion': '3 min',
      'color': Colors.blue,
    },
    {
      'icono': Icons.analytics_outlined,
      'titulo': 'Cómo interpretar tus estadísticas',
      'descripcion': 'Entiende tus métricas de reciclaje y mejora tu rendimiento',
      'duracion': '4 min',
      'color': Colors.orange,
    },
  ];

  final List<Map<String, dynamic>> _videosTutoriales = [
    {
      'titulo': 'Registro de materiales',
      'duracion': '2:45',
      'thumbnail': 'assets/images/video1.jpg',
    },
    {
      'titulo': 'Gestión de lotes',
      'duracion': '3:20',
      'thumbnail': 'assets/images/video2.jpg',
    },
    {
      'titulo': 'Reportes mensuales',
      'duracion': '4:10',
      'thumbnail': 'assets/images/video3.jpg',
    },
  ];

  void _abrirGuia(String titulo) {
    HapticFeedback.lightImpact();
    // TODO: Navegar a la guía específica
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Abriendo guía: $titulo'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _reproducirVideo(String titulo) {
    HapticFeedback.lightImpact();
    // TODO: Reproducir video tutorial
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reproduciendo: $titulo'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _abrirRecurso(String recurso) {
    HapticFeedback.lightImpact();
    // TODO: Abrir recurso adicional
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Abriendo: $recurso'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          // Header verde
          SliverAppBar(
            expandedHeight: 200,
            backgroundColor: BioWayColors.ecoceGreen,
            automaticallyImplyLeading: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: BioWayColors.ecoceGreen,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '¿Cómo podemos ayudarte?',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Encuentra guías, tutoriales y respuestas a tus preguntas',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Contenido
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Guías Paso a Paso
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Guías Paso a Paso',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...List.generate(
                          _guiasPasoAPaso.length,
                          (index) => _buildGuiaItem(_guiasPasoAPaso[index]),
                        ),
                      ],
                    ),
                  ),

                  // Videos Tutoriales
                  Container(
                    color: const Color(0xFFF5F5F5),
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Videos Tutoriales',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 140,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _videosTutoriales.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: _buildVideoItem(_videosTutoriales[index]),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Recursos Adicionales
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recursos Adicionales',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildRecursoItem(
                          icono: Icons.description_outlined,
                          titulo: 'Manual de Usuario ECOCE',
                          descripcion: 'Documento completo con todas las funcionalidades',
                          onTap: () => _abrirRecurso('Manual de Usuario'),
                        ),
                        _buildRecursoItem(
                          icono: Icons.phone_outlined,
                          titulo: 'Soporte Técnico',
                          descripcion: 'Contacta con nuestro equipo de ayuda',
                          onTap: () => _abrirRecurso('Soporte Técnico'),
                        ),
                        _buildRecursoItem(
                          icono: Icons.help_outline,
                          titulo: 'Preguntas Frecuentes',
                          descripcion: 'Respuestas a las dudas más comunes',
                          onTap: () => _abrirRecurso('FAQ'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100), // Espacio para el FAB
                ],
              ),
            ),
          ),
        ],
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
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const OrigenCrearLoteScreen(),
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
          },
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

  Widget _buildGuiaItem(Map<String, dynamic> guia) {
    return InkWell(
      onTap: () => _abrirGuia(guia['titulo']),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade100,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (guia['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                guia['icono'],
                color: guia['color'],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    guia['titulo'],
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    guia['descripcion'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoItem(Map<String, dynamic> video) {
    return InkWell(
      onTap: () => _reproducirVideo(video['titulo']),
      borderRadius: BorderRadius.circular(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 160,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Thumbnail placeholder
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                // Play button
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.black,
                    size: 24,
                  ),
                ),
                // Duración
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      video['duracion'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 160,
            child: Text(
              video['titulo'],
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecursoItem({
    required IconData icono,
    required String titulo,
    required String descripcion,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade100,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: BioWayColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icono,
                color: BioWayColors.info,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    descripcion,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, IconData activeIcon, String label, int index) {
    final isSelected = _selectedIndex == index;
    
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            
            if (isSelected) return;
            
            switch (index) {
              case 0:
                Navigator.pop(context);
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
                // Ya estamos en ayuda
                break;
              case 3:
                Navigator.pushReplacement(
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
          },
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