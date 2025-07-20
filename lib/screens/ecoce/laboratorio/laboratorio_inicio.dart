import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import '../../../utils/format_utils.dart';
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

  // Datos de ejemplo para el laboratorio (en producción vendrían de la base de datos)
  final String _nombreLaboratorio = "Laboratorio Central de Análisis";
  final String _folioLaboratorio = "L0000001";
  final int _muestrasRecibidas = 128;
  final double _materialAnalizado = 856.5; // en kg

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
                      BioWayColors.ecoceGreen.withValues(alpha: 0.8),
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
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
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
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
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
                          const SizedBox(height: 8),
                          // Nombre del laboratorio
                          Text(
                            _nombreLaboratorio,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 4),
                          // Badge con tipo y folio
                          Row(
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
                                      color: BioWayColors.ecoceGreen,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Laboratorio',
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
                                  _folioLaboratorio,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Estadísticas
                          Row(
                            children: [
                              // Card de Muestras Recibidas
                              Expanded(
                                child: StatisticCard(
                                  label: 'Muestras recibidas',
                                  value: _muestrasRecibidas.toString(),
                                  icon: Icons.science,
                                  iconColor: Colors.blue,
                                  height: 70,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Card de Material Analizado
                              Expanded(
                                child: StatisticCard(
                                  label: 'Material analizado',
                                  value: _materialAnalizado.toStringAsFixed(1),
                                  unit: 'kg',
                                  icon: Icons.analytics,
                                  iconColor: Colors.purple,
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
                              BioWayColors.ecoceGreen,
                              BioWayColors.ecoceGreen.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: BioWayColors.ecoceGreen.withValues(alpha: 0.3),
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
                                      Icons.qr_code_scanner,
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
                                          'Escanear Nueva Muestra',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          'Registra entrada de muestra',
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
        backgroundColor: const Color(0xFF9333EA), // Purple color for laboratorio
        tooltip: 'Nueva muestra',
        heroTag: 'laboratorio_fab',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}