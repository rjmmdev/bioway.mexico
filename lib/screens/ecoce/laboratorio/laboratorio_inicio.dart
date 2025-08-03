import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../../utils/format_utils.dart';
import '../../../services/firebase/ecoce_profile_service.dart';
import '../../../services/firebase/auth_service.dart';
import '../../../services/lote_unificado_service.dart';
import 'laboratorio_gestion_muestras.dart';
import 'laboratorio_registro_muestras.dart';
import 'laboratorio_toma_muestra_megalote_screen.dart';
import '../shared/ecoce_ayuda_screen.dart';
import '../shared/ecoce_perfil_screen.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import '../shared/widgets/unified_stat_card.dart';
import '../shared/widgets/shared_qr_scanner_screen.dart';
import '../shared/utils/navigation_utils.dart';
import '../../../utils/qr_utils.dart';

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
    final LoteUnificadoService _loteUnificadoService = LoteUnificadoService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Datos del usuario
  String _nombreLaboratorio = "Cargando...";
  String _folioLaboratorio = "L0000000";
  int _muestrasRecibidas = 0;
  double _materialAnalizado = 0.0; // en kg
  
  // Stream para muestras del laboratorio
  StreamSubscription? _statsSubscription;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadStatistics();
    _setupLotesStream();
    _setupStatisticsListener();
  }
  
  void _setupLotesStream() {
    // Las muestras solo se obtienen por escaneo QR
    // No hay acceso directo a megalotes
  }
  
  void _setupStatisticsListener() {
    // Escuchar cambios en las transformaciones para actualizar estadísticas
    _statsSubscription = _firestore
        .collection('transformaciones')
        .where('muestras_laboratorio', isNotEqualTo: null)
        .snapshots()
        .listen((_) {
      // Cuando hay cambios, recargar estadísticas
      _loadStatistics();
    });
  }
  
  @override
  void dispose() {
    _statsSubscription?.cancel();
    super.dispose();
  }
  
  Future<void> _loadStatistics() async {
    try {
      // Usar el nuevo método de estadísticas del servicio
      final estadisticas = await _loteUnificadoService.obtenerEstadisticasLaboratorio();
      
      if (mounted) {
        setState(() {
          _muestrasRecibidas = estadisticas['muestrasRecibidas'] ?? 0;
          _materialAnalizado = (estadisticas['materialAnalizado'] ?? 0.0).toDouble();
        });
      }
    } catch (e) {
      debugPrint('Error cargando estadísticas: $e');
      if (mounted) {
        setState(() {
          _muestrasRecibidas = 0;
          _materialAnalizado = 0.0;
        });
      }
    }
  }
  
  Future<void> _loadUserData() async {
    try {
      final User? currentUser = _authService.currentUser;
      if (currentUser != null) {
        final profile = await _profileService.getProfile(currentUser.uid);
        if (profile != null && mounted) {
          setState(() {
            _nombreLaboratorio = profile.ecoceNombre;
            _folioLaboratorio = profile.ecoceFolio;
          });
        }
      }
    } catch (e) {
      debugPrint('Error cargando datos del usuario: $e');
    }
  }


  void _navigateToNewMuestra() async {
    HapticFeedback.lightImpact();
    
    // Navegar directamente al escáner QR (como Reciclador y Transformador)
    final qrCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const SharedQRScannerScreen(),
      ),
    );
    
    if (qrCode != null && mounted) {
      // Verificar si es un código QR de muestra de megalote
      if (qrCode.startsWith('MUESTRA-MEGALOTE-')) {
        // Es una muestra de megalote, ir directamente al formulario
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LaboratorioTomaMuestraMegaloteScreen(
              qrCode: qrCode,
            ),
          ),
        );
      } else {
        // Es un lote normal, extraer el ID y procesar
        final loteId = QRUtils.extractLoteIdFromQR(qrCode);
        
        // Navegar a la pantalla de registro de muestras
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LaboratorioRegistroMuestrasScreen(
              initialMuestraId: loteId,
              isMegaloteSample: false,
            ),
          ),
        );
      }
    }
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



  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
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
                      
                      // Mensaje informativo sobre el flujo de trabajo
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              Icon(
                                Icons.qr_code_scanner,
                                size: 64,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Toma de muestras por código QR',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Escanea el código QR de muestra\ngenerado por el Reciclador',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[400],
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _navigateToNewMuestra,
                                icon: const Icon(Icons.qr_code_scanner),
                                label: const Text('Escanear Código QR'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF9333EA),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
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