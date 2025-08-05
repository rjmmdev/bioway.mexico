import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../../utils/format_utils.dart';
import '../../../utils/ui_constants.dart';
import '../../../services/firebase/ecoce_profile_service.dart';
import '../../../services/firebase/auth_service.dart';
import '../../../services/firebase/firebase_manager.dart';
// import '../../../services/lote_unificado_service.dart'; // No se usa actualmente
import '../../../services/muestra_laboratorio_service.dart';
import '../../../models/laboratorio/muestra_laboratorio_model.dart';
import 'laboratorio_gestion_muestras.dart';
import 'laboratorio_formulario.dart';
import 'laboratorio_documentacion.dart';
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
  final MuestraLaboratorioService _muestraService = MuestraLaboratorioService();
  final FirebaseManager _firebaseManager = FirebaseManager();
  late final FirebaseFirestore _firestore;
  
  // Datos del usuario
  String _nombreLaboratorio = "Cargando...";
  String _folioLaboratorio = "L0000000";
  int _muestrasRecibidas = 0;
  double _materialAnalizado = 0.0; // en kg
  
  // Muestras recientes
  List<MuestraLaboratorioModel> _muestrasRecientes = [];
  bool _isLoadingMuestras = false;
  
  // Stream para muestras del laboratorio
  StreamSubscription? _statsSubscription;
  
  @override
  void initState() {
    super.initState();
    
    // Inicializar Firestore con la instancia correcta
    final app = _firebaseManager.currentApp;
    if (app != null) {
      _firestore = FirebaseFirestore.instanceFor(app: app);
    } else {
      _firestore = FirebaseFirestore.instance;
    }
    
    _loadUserData();
    _loadStatistics();
    _loadMuestrasRecientes();
    _setupLotesStream();
    _setupStatisticsListener();
  }
  
  void _setupLotesStream() {
    // Las muestras solo se obtienen por escaneo QR
    // No hay acceso directo a megalotes
  }
  
  Future<void> _loadMuestrasRecientes() async {
    setState(() => _isLoadingMuestras = true);
    
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) return;
      
      // Cargar las 5 muestras más recientes
      final muestrasSnapshot = await _firestore
          .collection('muestras_laboratorio')
          .where('laboratorio_id', isEqualTo: userId)
          .limit(5)
          .get();
      
      // Ordenar manualmente por fecha
      final docs = muestrasSnapshot.docs.toList();
      if (docs.isNotEmpty) {
        docs.sort((a, b) {
          try {
            final fechaA = a.data()['fecha_toma'];
            final fechaB = b.data()['fecha_toma'];
            
            DateTime dateA;
            DateTime dateB;
            
            if (fechaA is Timestamp) {
              dateA = fechaA.toDate();
            } else if (fechaA is String) {
              dateA = DateTime.parse(fechaA);
            } else {
              dateA = DateTime.now();
            }
            
            if (fechaB is Timestamp) {
              dateB = fechaB.toDate();
            } else if (fechaB is String) {
              dateB = DateTime.parse(fechaB);
            } else {
              dateB = DateTime.now();
            }
            
            return dateB.compareTo(dateA); // Orden descendente
          } catch (e) {
            return 0;
          }
        });
      }
      
      // Convertir a modelos
      _muestrasRecientes = [];
      for (var doc in docs.take(5)) {
        try {
          final muestra = MuestraLaboratorioModel.fromMap(doc.data(), doc.id);
          _muestrasRecientes.add(muestra);
        } catch (e) {
          debugPrint('Error al parsear muestra: $e');
        }
      }
      
    } catch (e) {
      debugPrint('Error cargando muestras recientes: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingMuestras = false);
      }
    }
  }
  
  void _setupStatisticsListener() {
    // NUEVO SISTEMA: Escuchar cambios en la colección independiente de muestras
    final userId = _authService.currentUser?.uid;
    if (userId != null) {
      _statsSubscription = _firestore
          .collection('muestras_laboratorio')
          .where('laboratorio_id', isEqualTo: userId)
          .snapshots()
          .listen((_) {
        // Cuando hay cambios, recargar estadísticas y muestras recientes
        _loadStatistics();
        _loadMuestrasRecientes();
      });
    }
  }
  
  @override
  void dispose() {
    _statsSubscription?.cancel();
    super.dispose();
  }
  
  Future<void> _loadStatistics() async {
    try {
      // NUEVO SISTEMA: Obtener estadísticas desde el servicio independiente
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        debugPrint('[LABORATORIO] No hay usuario autenticado para estadísticas');
        return;
      }
      
      // Obtener todas las muestras del usuario a través de Firestore directamente
      final muestrasSnapshot = await _firestore
          .collection('muestras_laboratorio')
          .where('laboratorio_id', isEqualTo: userId)
          .get();
      
      // Calcular estadísticas
      int totalMuestras = muestrasSnapshot.docs.length;
      double pesoTotal = 0.0;
      
      for (var doc in muestrasSnapshot.docs) {
        final data = doc.data();
        final peso = (data['peso_muestra'] ?? 0.0);
        pesoTotal += peso is num ? peso.toDouble() : 0.0;
      }
      
      if (mounted) {
        setState(() {
          _muestrasRecibidas = totalMuestras;
          _materialAnalizado = pesoTotal;
        });
      }
      
      debugPrint('[LABORATORIO] Estadísticas actualizadas: $totalMuestras muestras, ${pesoTotal.toStringAsFixed(2)} kg');
    } catch (e) {
      debugPrint('[ERROR] Error cargando estadísticas: $e');
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
                height: UIConstants.qrSizeMedium + UIConstants.iconSizeDialog + UIConstants.iconSizeMedium,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF9333EA), // Purple para laboratorio
                      const Color(0xFF9333EA).withValues(alpha: UIConstants.opacityVeryHigh),
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
                        width: UIConstants.qrSizeMedium,
                        height: UIConstants.qrSizeMedium,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: UIConstants.opacityLow),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -30,
                      bottom: -30,
                      child: Container(
                        width: UIConstants.qrSizeSmall + UIConstants.iconContainerMedium,
                        height: UIConstants.qrSizeSmall + UIConstants.iconContainerMedium,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: UIConstants.opacityVeryLow),
                        ),
                      ),
                    ),
                    // Contenido
                    Padding(
                      padding: EdgeInsets.fromLTRB(UIConstants.spacing20, MediaQuery.of(context).padding.top + UIConstants.spacing16, UIConstants.spacing20, UIConstants.spacing24),
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
                                width: UIConstants.statCardHeight,
                                height: UIConstants.iconSizeMedium + UIConstants.spacing8 + 3,
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: UIConstants.spacing12,
                                  vertical: UIConstants.spacing4 + 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: UIConstants.opacityMediumLow),
                                  borderRadius: BorderRadiusConstants.borderRadiusLarge,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: UIConstants.fontSizeMedium,
                                      color: Colors.white.withValues(alpha: UIConstants.opacityAlmostFull),
                                    ),
                                    SizedBox(width: UIConstants.spacing4 + 2),
                                    Text(
                                      FormatUtils.formatDate(DateTime.now()),
                                      style: TextStyle(
                                        fontSize: UIConstants.fontSizeSmall,
                                        color: Colors.white.withValues(alpha: UIConstants.opacityAlmostFull),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: UIConstants.spacing12),
                          // Nombre del laboratorio
                          Text(
                            _nombreLaboratorio,
                            style: const TextStyle(
                              fontSize: UIConstants.fontSizeTitle + 2,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.visible,
                          ),
                          SizedBox(height: UIConstants.spacing8),
                          // Badge con tipo y folio
                          Wrap(
                            spacing: UIConstants.spacing8,
                            runSpacing: 8,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: UIConstants.spacing12,
                                  vertical: UIConstants.spacing4 + 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  borderRadius: BorderRadiusConstants.borderRadiusLarge,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.science,
                                      size: UIConstants.fontSizeBody,
                                      color: const Color(0xFF9333EA), // Purple para laboratorio
                                    ),
                                    SizedBox(width: UIConstants.spacing4 + 2),
                                    Text(
                                      'Laboratorio',
                                      style: TextStyle(
                                        fontSize: UIConstants.fontSizeSmall + 1,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF9333EA), // Purple para laboratorio
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: UIConstants.spacing8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: UIConstants.spacing12,
                                  vertical: UIConstants.spacing4 + 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF9333EA), // Purple para laboratorio
                                  borderRadius: BorderRadiusConstants.borderRadiusLarge,
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
                          SizedBox(height: UIConstants.spacing16),
                          // Estadísticas con UnifiedStatCard
                          SizedBox(
                            height: UIConstants.statCardHeight,
                            child: Row(
                              children: [
                                // Estadística de Muestras Recibidas
                                Expanded(
                                  child: UnifiedStatCard.horizontal(
                                    title: 'Muestras recibidas',
                                    value: _muestrasRecibidas.toString(),
                                    icon: Icons.science,
                                    color: Colors.blue,
                                    height: UIConstants.statCardHeight,
                                  ),
                                ),
                                SizedBox(width: UIConstants.spacing12),
                                // Estadística de Material Analizado
                                Expanded(
                                  child: UnifiedStatCard.horizontal(
                                    title: 'Material analizado',
                                    value: _materialAnalizado.toStringAsFixed(1),
                                    unit: 'kg',
                                    icon: Icons.analytics,
                                    color: Colors.purple,
                                    height: UIConstants.statCardHeight,
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
                margin: EdgeInsets.only(top: UIConstants.spacing8 + 2),
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(UIConstants.spacing16, UIConstants.spacing20, UIConstants.spacing16, UIConstants.spacing20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Acción rápida con diseño unificado
                      Container(
                        width: double.infinity,
                        height: UIConstants.statCardHeight,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF9333EA), // Purple para laboratorio
                              const Color(0xFF9333EA).withValues(alpha: UIConstants.opacityVeryHigh),
                            ],
                          ),
                          borderRadius: BorderRadiusConstants.borderRadiusLarge,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF9333EA).withValues(alpha: UIConstants.opacityMedium),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadiusConstants.borderRadiusLarge,
                          child: InkWell(
                            borderRadius: BorderRadiusConstants.borderRadiusLarge,
                            onTap: _navigateToNewMuestra,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: UIConstants.spacing16, vertical: UIConstants.spacing12),
                              child: Row(
                                children: [
                                  Container(
                                    width: UIConstants.iconSizeLarge,
                                    height: UIConstants.iconSizeLarge,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: UIConstants.opacityMediumLow),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.add_circle_outline,
                                      color: Colors.white,
                                      size: UIConstants.iconSizeMedium,
                                    ),
                                  ),
                                  SizedBox(width: UIConstants.spacing16),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Registrar Nueva Muestra',
                                          style: TextStyle(
                                            fontSize: UIConstants.fontSizeBody,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          'Escanea código QR del lote',
                                          style: TextStyle(
                                            fontSize: UIConstants.fontSizeSmall + 1,
                                            color: Colors.white.withValues(alpha: UIConstants.opacityAlmostFull),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.white.withValues(alpha: UIConstants.opacityVeryHigh),
                                    size: UIConstants.fontSizeLarge,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: UIConstants.spacing20),
                      
                      // Sección de muestras recientes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Muestras Recientes',
                            style: TextStyle(
                              fontSize: UIConstants.fontSizeXLarge,
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
                                    fontSize: UIConstants.fontSizeMedium,
                                    color: const Color(0xFF9333EA), // Purple para laboratorio
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: UIConstants.spacing4),
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
                      SizedBox(height: UIConstants.spacing16),
                      
                      // Lista de muestras recientes o mensaje informativo
                      if (_isLoadingMuestras)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: UIConstants.spacing40),
                            child: CircularProgressIndicator(
                              color: Color(0xFF9333EA),
                            ),
                          ),
                        )
                      else if (_muestrasRecientes.isEmpty)
                        Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: UIConstants.spacing40),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.qr_code_scanner,
                                  size: UIConstants.iconSizeXLarge - UIConstants.spacing16,
                                  color: Colors.grey[300],
                                ),
                                SizedBox(height: UIConstants.spacing16),
                                Text(
                                  'Toma de muestras por código QR',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: UIConstants.spacing8),
                                Text(
                                  'Escanea el código QR de muestra\ngenerado por el Reciclador',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: UIConstants.fontSizeMedium,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                SizedBox(height: UIConstants.spacing24),
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
                                      borderRadius: BorderRadiusConstants.borderRadiusRound,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Column(
                          children: _muestrasRecientes.map((muestra) => 
                            _buildMuestraCard(muestra)
                          ).toList(),
                        ),
                      
                      SizedBox(height: UIConstants.qrSizeSmall), // Espacio para el FAB
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
  
  Widget _buildMuestraCard(MuestraLaboratorioModel muestra) {
    final muestraId = muestra.id;
    final tipoDisplay = muestra.tipo == 'megalote' ? 'Megalote' : 'Lote';
    final origenDisplay = muestra.origenId.length > 8 ? muestra.origenId.substring(0, 8).toUpperCase() : muestra.origenId.toUpperCase();
    final peso = muestra.pesoMuestra;
    final fecha = muestra.fechaToma;
    
    // Determinar estado y color
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    switch (muestra.estado) {
      case 'pendiente_analisis':
        statusColor = const Color(0xFF9333EA);
        statusText = 'Pendiente de análisis';
        statusIcon = Icons.analytics;
        break;
      case 'analisis_completado':
        statusColor = Colors.orange;
        statusText = 'Pendiente de documentación';
        statusIcon = Icons.upload_file;
        break;
      case 'documentacion_completada':
        statusColor = Colors.green;
        statusText = 'Completada';
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Estado desconocido';
        statusIcon = Icons.help_outline;
    }
    
    return Container(
      margin: EdgeInsets.only(bottom: UIConstants.spacing12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadiusConstants.borderRadiusMedium,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: UIConstants.opacityVeryLow + 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadiusConstants.borderRadiusMedium,
        onTap: () => _navigateToMuestraDetail(muestra),
        child: Padding(
          padding: EdgeInsetsConstants.paddingAll16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con estilo consistente
              Row(
                children: [
                  // Icono de estado
                  Container(
                    width: UIConstants.iconSizeButton,
                    height: UIConstants.iconSizeButton,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: UIConstants.opacityLow),
                      borderRadius: BorderRadiusConstants.borderRadiusMedium,
                    ),
                    child: Icon(
                      muestra.tipo == 'megalote' ? Icons.science : Icons.biotech,
                      color: statusColor,
                      size: UIConstants.iconSizeMedium,
                    ),
                  ),
                  SizedBox(width: UIConstants.spacing12),
                  
                  // Información principal
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'MUESTRA: ${muestraId.length > 8 ? muestraId.substring(0, 8).toUpperCase() : muestraId.toUpperCase()}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: UIConstants.spacing8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: UIConstants.spacing4 + 2, vertical: UIConstants.spacing4 / 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF9333EA).withValues(alpha: UIConstants.opacityLow),
                                borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
                                border: Border.all(color: const Color(0xFF9333EA).withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    muestra.tipo == 'megalote' ? Icons.layers : Icons.inventory_2,
                                    size: UIConstants.fontSizeSmall,
                                    color: const Color(0xFF9333EA),
                                  ),
                                  SizedBox(width: UIConstants.spacing4 / 2),
                                  Text(
                                    tipoDisplay,
                                    style: const TextStyle(
                                      fontSize: UIConstants.fontSizeXSmall - 1,
                                      color: Color(0xFF9333EA),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Botón de acción
                  IconButton(
                    icon: Icon(
                      muestra.estado == 'pendiente_analisis' ? Icons.analytics : 
                      muestra.estado == 'analisis_completado' ? Icons.upload_file :
                      Icons.visibility,
                      color: statusColor,
                    ),
                    onPressed: () => _navigateToMuestraDetail(muestra),
                    tooltip: muestra.estado == 'pendiente_analisis' ? 'Realizar análisis' : 
                             muestra.estado == 'analisis_completado' ? 'Subir documentos' :
                             'Ver detalles',
                  ),
                ],
              ),
              
              SizedBox(height: UIConstants.spacing12),
              
              // Información adicional
              Row(
                children: [
                  _buildInfoItem(
                    icon: Icons.qr_code_2,
                    label: 'Origen',
                    value: origenDisplay,
                  ),
                  SizedBox(width: UIConstants.spacing16),
                  _buildInfoItem(
                    icon: Icons.scale,
                    label: 'Peso',
                    value: '${peso.toStringAsFixed(2)} kg',
                  ),
                  SizedBox(width: UIConstants.spacing16),
                  _buildInfoItem(
                    icon: Icons.calendar_today,
                    label: 'Fecha',
                    value: '${fecha.day}/${fecha.month}/${fecha.year}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: UIConstants.fontSizeMedium, color: Colors.grey[600]),
        SizedBox(width: UIConstants.spacing4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  void _navigateToMuestraDetail(MuestraLaboratorioModel muestra) {
    if (muestra.estado == 'pendiente_analisis') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LaboratorioFormulario(
            muestraId: muestra.id,
            transformacionId: muestra.origenId,
            datosMuestra: muestra.toMap(),
          ),
        ),
      ).then((_) {
        _loadMuestrasRecientes();
        _loadStatistics();
      });
    } else if (muestra.estado == 'analisis_completado') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LaboratorioDocumentacion(
            muestraId: muestra.id,
            transformacionId: muestra.origenId,
          ),
        ),
      ).then((_) {
        _loadMuestrasRecientes();
        _loadStatistics();
      });
    } else {
      // Para muestras completadas, navegar a la pantalla de gestión en la pestaña correspondiente
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const LaboratorioGestionMuestras(initialTab: 2),
        ),
      );
    }
  }
}