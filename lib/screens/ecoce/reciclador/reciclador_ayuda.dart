import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import '../shared/utils/navigation_utils.dart';
import 'reciclador_inicio.dart';
import 'reciclador_administracion_lotes.dart';
import 'reciclador_perfil.dart';
import 'reciclador_escaneo.dart';

class RecicladorAyudaScreen extends StatefulWidget {
  const RecicladorAyudaScreen({super.key});

  @override
  State<RecicladorAyudaScreen> createState() => _RecicladorAyudaScreenState();
}

class _RecicladorAyudaScreenState extends State<RecicladorAyudaScreen> with SingleTickerProviderStateMixin {
  // Índice para la navegación del bottom bar
  final int _selectedIndex = 2; // Ayuda está seleccionado
  
  // Controlador para la animación del header
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Videos tutoriales específicos para reciclador
  final List<Map<String, dynamic>> _videosTutoriales = [
    {
      'titulo': 'Escaneo de lotes entrantes',
      'descripcion': 'Cómo recibir y registrar material',
      'duracion': '4:15',
      'vistas': '3.2k',
      'nuevo': true,
    },
    {
      'titulo': 'Proceso de clasificación',
      'descripcion': 'Separa materiales por tipo',
      'duracion': '6:30',
      'vistas': '2.8k',
      'nuevo': false,
    },
    {
      'titulo': 'Pesaje y documentación',
      'descripcion': 'Registra pesos y genera reportes',
      'duracion': '5:20',
      'vistas': '2.1k',
      'nuevo': false,
    },
    {
      'titulo': 'Proceso de salida',
      'descripcion': 'Completa el ciclo de reciclaje',
      'duracion': '3:45',
      'vistas': '1.9k',
      'nuevo': true,
    },
  ];
  
  // FAQs populares para reciclador
  final List<Map<String, dynamic>> _faqsPopulares = [
    {
      'pregunta': '¿Cómo escaneo múltiples lotes a la vez?',
      'respuesta': 'En la pantalla de escaneo, puedes agregar varios lotes antes de procesar. Simplemente escanea cada código QR y se irán agregando a la lista.',
      'votos': 245,
      'categoria': 'Escaneo',
    },
    {
      'pregunta': '¿Qué diferencia hay entre peso bruto y peso neto?',
      'respuesta': 'El peso bruto incluye el material con impurezas, mientras que el peso neto es el material aprovechable después de limpieza.',
      'votos': 189,
      'categoria': 'Pesaje',
    },
    {
      'pregunta': '¿Cómo calculo la merma del material?',
      'respuesta': 'La merma se calcula automáticamente al ingresar el peso resultante. Es la diferencia entre el peso neto aprovechable y el peso final.',
      'votos': 156,
      'categoria': 'Procesos',
    },
  ];
  
  @override
  void initState() {
    super.initState();
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
  
  void _descargarManual() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Descargando Manual del Reciclador...'),
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
  
  void _abrirWhatsApp() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Abriendo WhatsApp...'),
        backgroundColor: const Color(0xFF25D366), // WhatsApp green
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
  
  void _reproducirVideo(Map<String, dynamic> video) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reproduciendo: ${video['titulo']}'),
        backgroundColor: BioWayColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
  
  void _abrirFAQ(Map<String, dynamic> faq) {
    HapticFeedback.lightImpact();
    _mostrarRespuestaCompleta(faq);
  }
  
  void _mostrarRespuestaCompleta(Map<String, dynamic> faq) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.4,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Contenido
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Categoría
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: BioWayColors.ecoceGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          faq['categoria'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: BioWayColors.ecoceGreen,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Pregunta
                      Text(
                        faq['pregunta'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Respuesta
                      Text(
                        faq['respuesta'],
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Votos y acciones
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.thumb_up_outlined,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${faq['votos']} útil',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _contactarSoporte();
                            },
                            icon: const Icon(Icons.help_outline, size: 18),
                            label: const Text('Necesito más ayuda'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: BioWayColors.ecoceGreen,
                              side: BorderSide(color: BioWayColors.ecoceGreen),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _contactarSoporte();
                              },
                              icon: const Icon(Icons.headset_mic_outlined),
                              label: const Text('Contactar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: BioWayColors.ecoceGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _contactarSoporte() {
    _abrirWhatsApp();
  }
  
  void _navigateToNewLot() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const QRScannerScreen(),
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
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const RecicladorHomeScreen(),
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
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const RecicladorAdministracionLotes(),
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
                const RecicladorPerfilScreen(),
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
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // Header moderno con búsqueda
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        BioWayColors.ecoceGreen,
                        BioWayColors.ecoceGreen.withOpacity(0.85),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      // Título y descripción
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.support_agent,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Centro de Ayuda',
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          height: 1.1,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Todo para gestionar tu centro',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Curva decorativa
                      CustomPaint(
                        size: const Size(double.infinity, 30),
                        painter: _CurvePainter(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Contenido principal
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Videos Tutoriales - Sección Principal
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Videos Tutoriales',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.play_circle_filled,
                                      size: 16,
                                      color: Colors.red.shade600,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${_videosTutoriales.length} videos',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.red.shade600,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Aprende los procesos de reciclaje paso a paso',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Lista de videos
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _videosTutoriales.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final video = _videosTutoriales[index];
                              return _buildVideoCard(video);
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Acceso rápido simplificado
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Recursos',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildQuickAccessCard(
                                  icon: Icons.picture_as_pdf,
                                  title: 'Manual PDF',
                                  subtitle: 'Guía del reciclador',
                                  color: Colors.deepOrange,
                                  onTap: _descargarManual,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildQuickAccessCard(
                                  icon: Icons.chat,
                                  title: 'WhatsApp',
                                  subtitle: 'Soporte técnico',
                                  color: const Color(0xFF25D366),
                                  onTap: _abrirWhatsApp,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Preguntas frecuentes
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Preguntas Populares',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {},
                                  child: Text(
                                    'Ver todas',
                                    style: TextStyle(
                                      color: BioWayColors.ecoceGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Lista de FAQs
                          ..._faqsPopulares.map((faq) => _buildFAQItem(faq)),
                          
                          const SizedBox(height: 20),
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
      
      // Bottom Navigation Bar con FAB
      bottomNavigationBar: EcoceBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onBottomNavTapped,
        primaryColor: BioWayColors.ecoceGreen,
        items: EcoceNavigationConfigs.recicladorItems,
        fabConfig: FabConfig(
          icon: Icons.add,
          onPressed: _navigateToNewLot,
        ),
      ),

      // Floating Action Button
      floatingActionButton: EcoceFloatingActionButton(
        onPressed: _navigateToNewLot,
        icon: Icons.add,
        backgroundColor: BioWayColors.ecoceGreen,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
  
  Widget _buildQuickAccessCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildVideoCard(Map<String, dynamic> video) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _reproducirVideo(video),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
              // Thumbnail del video
              Container(
                width: 120,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Placeholder
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.grey.shade800,
                            Colors.grey.shade900,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    // Play button
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.black87,
                        size: 30,
                      ),
                    ),
                    // Duración
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
                          video['duracion'],
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    // Badge NUEVO
                    if (video['nuevo'] == true)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'NUEVO',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Información del video
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video['titulo'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      video['descripcion'],
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${video['vistas']} vistas',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFAQItem(Map<String, dynamic> faq) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _abrirFAQ(faq),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade100,
                width: 1,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: BioWayColors.ecoceGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    'Q',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: BioWayColors.ecoceGreen,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      faq['pregunta'],
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: BioWayColors.ecoceGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            faq['categoria'],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: BioWayColors.ecoceGreen,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.thumb_up_outlined,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${faq['votos']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Painter para la curva decorativa
class _CurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF8F9FA)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(size.width / 2, 30, size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}