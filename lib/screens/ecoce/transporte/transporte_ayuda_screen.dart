import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import 'widgets/transporte_bottom_navigation.dart';
import 'transporte_inicio_screen.dart';
import 'transporte_entregar_screen.dart';
import 'transporte_perfil_screen.dart';

class TransporteAyudaScreen extends StatefulWidget {
  const TransporteAyudaScreen({super.key});

  @override
  State<TransporteAyudaScreen> createState() => _TransporteAyudaScreenState();
}

class _TransporteAyudaScreenState extends State<TransporteAyudaScreen> {
  final int _selectedIndex = 2;

  void _onItemTapped(int index) {
    HapticFeedback.lightImpact();
    
    if (index == _selectedIndex) return;
    
    switch (index) {
      case 0:
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const TransporteInicioScreen(),
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
      case 1:
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const TransporteEntregarScreen(),
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
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const TransportePerfilScreen(),
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

  void _descargarManual() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Descargando Manual de Usuario...'),
        backgroundColor: BioWayColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        action: SnackBarAction(
          label: 'Ver',
          textColor: Colors.white,
          onPressed: () {
            // Abrir PDF
          },
        ),
      ),
    );
  }

  void _reproducirVideo(String titulo) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reproduciendo: $titulo'),
        backgroundColor: BioWayColors.info,
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
      backgroundColor: BioWayColors.backgroundGrey,
      body: CustomScrollView(
        slivers: [
          // Header con gradiente
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: BioWayColors.deepBlue,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Ayuda',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      BioWayColors.deepBlue,
                      BioWayColors.info,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Icon(
                        Icons.help_outline,
                        size: 60,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'Encuentra guías, tutoriales y respuestas',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Contenido
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Guías Paso a Paso
                  Text(
                    'Guías Paso a Paso',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: BioWayColors.darkGrey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildGuiaCard(
                    icon: Icons.qr_code_scanner,
                    titulo: 'Cómo escanear lotes',
                    descripcion: 'Aprende a escanear códigos QR para recoger materiales',
                    color: BioWayColors.petBlue,
                    onTap: () {
                      // TODO: Abrir guía detallada
                    },
                  ),
                  
                  _buildGuiaCard(
                    icon: Icons.local_shipping,
                    titulo: 'Proceso de entrega',
                    descripcion: 'Guía completa para entregar materiales en destino',
                    color: BioWayColors.ppOrange,
                    onTap: () {
                      // TODO: Abrir guía detallada
                    },
                  ),
                  
                  _buildGuiaCard(
                    icon: Icons.qr_code,
                    titulo: 'Generar QR de entrega',
                    descripcion: 'Crea códigos QR para que el receptor escanee',
                    color: BioWayColors.success,
                    onTap: () {
                      // TODO: Abrir guía detallada
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Videos Tutoriales
                  Text(
                    'Videos Tutoriales',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: BioWayColors.darkGrey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildVideoCard(
                          titulo: 'Primeros pasos como transportista',
                          duracion: '5:30',
                          thumbnail: 'assets/images/video_thumb_1.jpg',
                        ),
                        const SizedBox(width: 16),
                        _buildVideoCard(
                          titulo: 'Proceso completo de recolección',
                          duracion: '8:15',
                          thumbnail: 'assets/images/video_thumb_2.jpg',
                        ),
                        const SizedBox(width: 16),
                        _buildVideoCard(
                          titulo: 'Entrega y documentación',
                          duracion: '6:45',
                          thumbnail: 'assets/images/video_thumb_3.jpg',
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Recursos Adicionales
                  Text(
                    'Recursos Adicionales',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: BioWayColors.darkGrey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildRecursoItem(
                    icon: Icons.picture_as_pdf,
                    titulo: 'Manual del Transportista',
                    descripcion: 'Descarga el manual completo en PDF',
                    onTap: _descargarManual,
                  ),
                  
                  _buildRecursoItem(
                    icon: Icons.contact_support,
                    titulo: 'Soporte técnico',
                    descripcion: 'Contacta con nuestro equipo de ayuda',
                    onTap: () {
                      // TODO: Abrir chat o formulario de contacto
                    },
                  ),
                  
                  _buildRecursoItem(
                    icon: Icons.update,
                    titulo: 'Actualizaciones',
                    descripcion: 'Consulta las últimas mejoras del sistema',
                    onTap: () {
                      // TODO: Mostrar changelog
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Preguntas Frecuentes
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: BioWayColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: BioWayColors.info.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.help,
                              color: BioWayColors.info,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Preguntas Frecuentes',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: BioWayColors.darkGrey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildFAQItem(
                          '¿Qué hago si el código QR no escanea?',
                          'Puedes ingresar el ID del lote manualmente usando el enlace debajo del escáner.',
                        ),
                        const Divider(height: 24),
                        _buildFAQItem(
                          '¿Cuánto tiempo tengo para usar el QR de entrega?',
                          'El código QR expira después de 15 minutos por seguridad. Si expira, puedes generar uno nuevo.',
                        ),
                        const Divider(height: 24),
                        _buildFAQItem(
                          '¿Cómo verifico el peso en destino?',
                          'El receptor debe pesar los materiales y confirmar que coincidan con el peso registrado.',
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Contacto de emergencia
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          BioWayColors.error.withOpacity(0.1),
                          BioWayColors.warning.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: BioWayColors.error.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.emergency,
                          color: BioWayColors.error,
                          size: 32,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Soporte de Emergencia',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: BioWayColors.darkGrey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Para situaciones urgentes',
                          style: TextStyle(
                            fontSize: 14,
                            color: BioWayColors.textGrey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Llamar a soporte
                          },
                          icon: const Icon(Icons.phone),
                          label: const Text('Llamar ahora'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BioWayColors.error,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: TransporteBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildGuiaCard({
    required IconData icon,
    required String titulo,
    required String descripcion,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: BioWayColors.darkGrey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        descripcion,
                        style: TextStyle(
                          fontSize: 14,
                          color: BioWayColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: BioWayColors.lightGrey,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoCard({
    required String titulo,
    required String duracion,
    required String thumbnail,
  }) {
    return GestureDetector(
      onTap: () => _reproducirVideo(titulo),
      child: Container(
        width: 240,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail del video
            Stack(
              children: [
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.play_circle_outline,
                      size: 60,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      duracion,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Info del video
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: BioWayColors.darkGrey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.play_arrow,
                        size: 16,
                        color: BioWayColors.textGrey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Ver tutorial',
                        style: TextStyle(
                          fontSize: 12,
                          color: BioWayColors.deepBlue,
                          fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildRecursoItem({
    required IconData icon,
    required String titulo,
    required String descripcion,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: BioWayColors.deepBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: BioWayColors.deepBlue,
            size: 24,
          ),
        ),
        title: Text(
          titulo,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: BioWayColors.darkGrey,
          ),
        ),
        subtitle: Text(
          descripcion,
          style: TextStyle(
            fontSize: 14,
            color: BioWayColors.textGrey,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: BioWayColors.lightGrey,
          size: 16,
        ),
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildFAQItem(String pregunta, String respuesta) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          pregunta,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: BioWayColors.darkGrey,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          respuesta,
          style: TextStyle(
            fontSize: 14,
            color: BioWayColors.textGrey,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}