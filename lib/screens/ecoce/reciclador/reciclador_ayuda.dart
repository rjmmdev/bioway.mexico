import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import 'widgets/reciclador_bottom_navigation.dart';
import 'reciclador_inicio.dart';
import 'reciclador_administracion_lotes.dart';
import 'reciclador_perfil.dart';

class RecicladorAyudaScreen extends StatelessWidget {
  const RecicladorAyudaScreen({super.key});

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
        backgroundColor: BioWayColors.ecoceGreen,
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
            backgroundColor: BioWayColors.ecoceGreen,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Centro de Ayuda',
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
                      BioWayColors.ecoceGreen,
                      BioWayColors.ecoceGreen.withOpacity(0.8),
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
                          'Todo lo que necesitas saber para gestionar tu centro de reciclaje',
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
                  // Acceso rápido
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          BioWayColors.success.withOpacity(0.1),
                          BioWayColors.success.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: BioWayColors.success.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.rocket_launch,
                          color: BioWayColors.success,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '¿Primera vez aquí?',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Comienza con nuestra guía rápida para recicladores',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: BioWayColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Procesos de Reciclaje
                  Text(
                    'Procesos de Reciclaje',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: BioWayColors.darkGrey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildGuiaCard(
                    context: context,
                    icon: Icons.qr_code_scanner,
                    titulo: 'Recepción de Material',
                    descripcion: 'Cómo escanear y registrar lotes entrantes',
                    color: BioWayColors.ecoceGreen,
                  ),
                  
                  _buildGuiaCard(
                    context: context,
                    icon: Icons.scale,
                    titulo: 'Pesaje y Clasificación',
                    descripcion: 'Registra pesos y categoriza los materiales',
                    color: BioWayColors.info,
                  ),
                  
                  _buildGuiaCard(
                    context: context,
                    icon: Icons.assignment_turned_in,
                    titulo: 'Proceso de Salida',
                    descripcion: 'Completa el proceso y genera documentación',
                    color: BioWayColors.success,
                  ),
                  
                  _buildGuiaCard(
                    context: context,
                    icon: Icons.description,
                    titulo: 'Documentación Técnica',
                    descripcion: 'Carga fichas técnicas y reportes',
                    color: BioWayColors.warning,
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
                          titulo: 'Escaneo de códigos QR',
                          duracion: '3:45',
                          tema: 'Básico',
                        ),
                        const SizedBox(width: 16),
                        _buildVideoCard(
                          context: context,
                          titulo: 'Registro de mermas',
                          duracion: '5:20',
                          tema: 'Intermedio',
                        ),
                        const SizedBox(width: 16),
                        _buildVideoCard(
                          context: context,
                          titulo: 'Generación de reportes',
                          duracion: '7:15',
                          tema: 'Avanzado',
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
                      color: BioWayColors.ecoceGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: BioWayColors.ecoceGreen.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.help,
                              color: BioWayColors.ecoceGreen,
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
                          'Puedes ingresar manualmente el ID del lote usando el botón "Ingresar manualmente" en la pantalla de escaneo.',
                        ),
                        const Divider(height: 24),
                        _buildFAQItem(
                          '¿Cómo calculo la merma del material?',
                          'El sistema calcula automáticamente la merma restando el peso de salida del peso de entrada.',
                        ),
                        const Divider(height: 24),
                        _buildFAQItem(
                          '¿Qué documentos debo cargar?',
                          'Debes cargar la Ficha Técnica del Pellet y el Reporte de Resultados de Reciclaje como mínimo.',
                        ),
                        const Divider(height: 24),
                        _buildFAQItem(
                          '¿Puedo editar un lote después de procesarlo?',
                          'No, una vez finalizado el proceso no se pueden editar los datos. Contacta a soporte si necesitas hacer cambios.',
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Tips de productividad
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: BioWayColors.info,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Tips de Productividad',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: BioWayColors.darkGrey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTip('Usa el filtro de búsqueda para encontrar lotes rápidamente'),
                        const SizedBox(height: 12),
                        _buildTip('Toma fotos claras para la evidencia fotográfica'),
                        const SizedBox(height: 12),
                        _buildTip('Revisa el peso antes de confirmar la salida'),
                        const SizedBox(height: 12),
                        _buildTip('Mantén los documentos organizados por fecha'),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Contacto de soporte
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
                          Icons.support_agent,
                          color: BioWayColors.error,
                          size: 32,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Soporte Técnico',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: BioWayColors.darkGrey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Disponible de Lunes a Viernes\n8:00 AM - 6:00 PM',
                          style: TextStyle(
                            fontSize: 14,
                            color: BioWayColors.textGrey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Llamando a soporte...'),
                                    backgroundColor: BioWayColors.error,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.phone, size: 20),
                              label: const Text('Llamar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: BioWayColors.error,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            OutlinedButton.icon(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Abriendo WhatsApp...'),
                                    backgroundColor: BioWayColors.success,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.chat, size: 20),
                              label: const Text('WhatsApp'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: BioWayColors.success,
                                side: BorderSide(color: BioWayColors.success),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                            ),
                          ],
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
      bottomNavigationBar: RecicladorBottomNavigation(
        selectedIndex: 2,
        onItemTapped: (index) {
          if (index == 2) return; // Ya estamos en Ayuda
          
          switch (index) {
            case 0:
              NavigationHelper.navigateWithReplacement(
                context: context,
                destination: const RecicladorHomeScreen(),
              );
              break;
            case 1:
              NavigationHelper.navigateWithReplacement(
                context: context,
                destination: const RecicladorAdministracionLotes(),
              );
              break;
            case 3:
              NavigationHelper.navigateWithReplacement(
                context: context,
                destination: const RecicladorPerfilScreen(),
              );
              break;
          }
        },
        onFabPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Función no disponible en esta pantalla'),
              backgroundColor: BioWayColors.info,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        },
      ),
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
    required String tema,
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
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        BioWayColors.ecoceGreen.withOpacity(0.8),
                        BioWayColors.ecoceGreen,
                      ],
                    ),
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
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getColorByTema(tema),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tema,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
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
                          color: BioWayColors.ecoceGreen,
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

  Color _getColorByTema(String tema) {
    switch (tema) {
      case 'Básico':
        return BioWayColors.success;
      case 'Intermedio':
        return BioWayColors.warning;
      case 'Avanzado':
        return BioWayColors.error;
      default:
        return BioWayColors.info;
    }
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

  Widget _buildTip(String tip) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle,
          color: BioWayColors.info,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            tip,
            style: TextStyle(
              fontSize: 14,
              color: BioWayColors.textGrey,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}