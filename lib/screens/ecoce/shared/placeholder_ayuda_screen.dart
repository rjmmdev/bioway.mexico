import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';

class PlaceholderAyudaScreen extends StatelessWidget {
  final String tipoUsuario;
  final Color primaryColor;
  final Widget bottomNavigation;

  const PlaceholderAyudaScreen({
    super.key,
    required this.tipoUsuario,
    required this.primaryColor,
    required this.bottomNavigation,
  });

  void _reproducirVideo(BuildContext context, String titulo) {
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

  void _abrirGuia(BuildContext context, String titulo) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Abriendo: $titulo'),
        backgroundColor: primaryColor,
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
            backgroundColor: primaryColor,
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
                      primaryColor,
                      primaryColor.withOpacity(0.8),
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
                          'Centro de ayuda para $tipoUsuario',
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
                  // Mensaje placeholder
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          BioWayColors.info.withOpacity(0.1),
                          BioWayColors.info.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: BioWayColors.info.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
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
                                'Centro de Ayuda en Desarrollo',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Aquí encontrarás guías, tutoriales y soporte específico para $tipoUsuario',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: BioWayColors.info,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
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
                    context: context,
                    icon: Icons.play_circle_outline,
                    titulo: 'Primeros pasos',
                    descripcion: 'Aprende lo básico para comenzar',
                    color: primaryColor,
                  ),
                  
                  _buildGuiaCard(
                    context: context,
                    icon: Icons.assignment,
                    titulo: 'Procesos principales',
                    descripcion: 'Guía completa de las funciones principales',
                    color: BioWayColors.info,
                  ),
                  
                  _buildGuiaCard(
                    context: context,
                    icon: Icons.tips_and_updates,
                    titulo: 'Tips y mejores prácticas',
                    descripcion: 'Optimiza tu trabajo con estos consejos',
                    color: BioWayColors.success,
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
                          context: context,
                          titulo: 'Tutorial básico',
                          duracion: '5:30',
                        ),
                        const SizedBox(width: 16),
                        _buildVideoCard(
                          context: context,
                          titulo: 'Funciones avanzadas',
                          duracion: '8:15',
                        ),
                        const SizedBox(width: 16),
                        _buildVideoCard(
                          context: context,
                          titulo: 'Solución de problemas',
                          duracion: '6:45',
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Preguntas Frecuentes
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.help,
                              color: primaryColor,
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
                          '¿Cómo inicio mi primera operación?',
                          'Dirígete a la pantalla principal y sigue las instrucciones paso a paso.',
                        ),
                        const Divider(height: 24),
                        _buildFAQItem(
                          '¿Dónde encuentro mi historial?',
                          'En tu perfil puedes ver todo tu historial de actividades.',
                        ),
                        const Divider(height: 24),
                        _buildFAQItem(
                          '¿Cómo contacto soporte?',
                          'Usa el botón de soporte de emergencia al final de esta pantalla.',
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
                            HapticFeedback.mediumImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Contactando soporte...'),
                                backgroundColor: BioWayColors.error,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
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
      bottomNavigationBar: bottomNavigation,
    );
  }

  Widget _buildGuiaCard({
    required BuildContext context,
    required IconData icon,
    required String titulo,
    required String descripcion,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        child: InkWell(
          onTap: () => _abrirGuia(context, titulo),
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
    required BuildContext context,
    required String titulo,
    required String duracion,
  }) {
    return GestureDetector(
      onTap: () => _reproducirVideo(context, titulo),
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
                          color: primaryColor,
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