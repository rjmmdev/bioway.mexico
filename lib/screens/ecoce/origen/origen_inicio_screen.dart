import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../utils/colors.dart';
import '../../../utils/format_utils.dart';
import '../../../utils/ui_constants.dart';
import '../../../services/user_session_service.dart';
import '../../../models/ecoce/ecoce_profile_model.dart';
import '../../../models/lotes/lote_origen_model.dart';
import '../../../services/lote_service.dart';
import 'origen_crear_lote_screen.dart';
import 'origen_lotes_screen.dart';
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
  
  // Servicios
  final UserSessionService _sessionService = UserSessionService();
  final LoteService _loteService = LoteService();
  
  // Datos del usuario
  EcoceProfileModel? _userProfile;
  bool _isLoading = true;
  
  // Lotes reales desde Firestore
  List<LoteOrigenModel> _lotesRecientes = [];
  int _totalLotes = 0;
  double _totalPeso = 0.0;
  
  // Estadísticas completas (todos los lotes creados)
  int _totalLotesCreados = 0;
  double _totalPesoProcesado = 0.0;

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

  
  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadLotes();
    _loadEstadisticasCompletas();
  }
  
  @override
  void dispose() {
    super.dispose();
  }
  
  Future<void> _loadLotes() async {
    // Escuchar cambios en los lotes de origen (solo los que están actualmente en origen)
    _loteService.getLotesOrigen().listen((lotes) {
      if (mounted) {
        setState(() {
          _lotesRecientes = lotes.take(3).toList(); // Solo los 3 más recientes
          _totalLotes = lotes.length;
          _totalPeso = lotes.fold(0.0, (sum, lote) => sum + (lote.pesoNace ?? 0.0));
        });
      }
    });
  }
  
  Future<void> _loadEstadisticasCompletas() async {
    // Escuchar cambios en las estadísticas completas (TODOS los lotes creados)
    _loteService.getEstadisticasOrigenCompletas().listen((stats) {
      if (mounted) {
        setState(() {
          _totalLotesCreados = stats['totalLotes'] ?? 0;
          _totalPesoProcesado = stats['pesoTotal'] ?? 0.0;
        });
      }
    });
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
        Navigator.pushReplacementNamed(context, '/origen_lotes');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/origen_ayuda');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/origen_perfil');
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
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // Prevenir que el botón atrás cierre la sesión
      },
      child: Scaffold(
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
                    _primaryColor.withValues(alpha: UIConstants.opacityVeryHigh),
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
                        width: UIConstants.qrSizeSmall,
                        height: UIConstants.qrSizeSmall,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: UIConstants.opacityVeryLow),
                        ),
                      ),
                    ),
                    // Contenido
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        UIConstants.spacing20, 
                        MediaQuery.of(context).padding.top + UIConstants.spacing20, 
                        UIConstants.spacing20, 
                        UIConstants.spacing24
                      ),
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
                                width: UIConstants.logoWidthSmall,
                                height: UIConstants.logoHeightSmall,
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: UIConstants.spacing12,
                                  vertical: UIConstants.spacing4 + 2, // 6
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: UIConstants.opacityMediumLow),
                                  borderRadius: BorderRadiusConstants.borderRadiusXLarge,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: UIConstants.fontSizeMedium,
                                      color: Colors.white.withValues(alpha: UIConstants.opacityAlmostFull),
                                    ),
                                    SizedBox(width: UIConstants.spacing4 + 2), // 6
                                    Text(
                                      FormatUtils.formatDate(DateTime.now()),
                                      style: TextStyle(
                                        fontSize: UIConstants.fontSizeXSmall + 1, // 12
                                        color: Colors.white.withValues(alpha: UIConstants.opacityAlmostFull),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: UIConstants.spacing12),
                          // Nombre del centro
                          Text(
                            _nombreCentro,
                            style: TextStyle(
                              fontSize: UIConstants.fontSizeTitle + 2, // 26
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
                            runSpacing: UIConstants.spacing8,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: UIConstants.spacing12,
                                  vertical: UIConstants.spacing4 + 2, // 6
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: UIConstants.opacityAlmostFull),
                                  borderRadius: BorderRadiusConstants.borderRadiusXLarge,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.store,
                                      size: UIConstants.iconSizeSmall,
                                      color: _primaryColor,
                                    ),
                                    SizedBox(width: UIConstants.spacing4 + 2), // 6
                                    Text(
                                      _tipoCentro,
                                      style: TextStyle(
                                        fontSize: UIConstants.fontSizeSmall,
                                        fontWeight: FontWeight.w600,
                                        color: _primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: UIConstants.spacing12,
                                  vertical: UIConstants.spacing4 + 2, // 6
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadiusConstants.borderRadiusXLarge,
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
                          SizedBox(height: UIConstants.spacing16),
                          // Estadísticas con UnifiedStatCard
                          Row(
                            children: [
                              // Estadística de Lotes
                              Expanded(
                                child: UnifiedStatCard.horizontal(
                                  title: 'Lotes creados',
                                  value: _totalLotesCreados.toString(),
                                  icon: Icons.inventory_2,
                                  color: Colors.blue,
                                  height: UIConstants.statCardHeight,
                                ),
                              ),
                              SizedBox(width: UIConstants.spacing12),
                              // Estadística de Material
                              Expanded(
                                child: UnifiedStatCard.horizontal(
                                  title: 'Material procesado',
                                  value: (_totalPesoProcesado / 1000).toStringAsFixed(1),
                                  unit: 'ton',
                                  icon: Icons.scale,
                                  color: Colors.green,
                                  height: UIConstants.statCardHeight,
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
                          height: UIConstants.buttonHeightLarge,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                _primaryColor,
                                _primaryColor.withValues(alpha: UIConstants.opacityVeryHigh),
                              ],
                            ),
                            borderRadius: BorderRadiusConstants.borderRadiusLarge,
                            boxShadow: [
                              BoxShadow(
                                color: _primaryColor.withValues(alpha: UIConstants.opacityMedium),
                                blurRadius: UIConstants.elevationXHigh,
                                offset: Offset(0, UIConstants.spacing4 + 2), // 6
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadiusConstants.borderRadiusLarge,
                            child: InkWell(
                              borderRadius: BorderRadiusConstants.borderRadiusLarge,
                              onTap: _navigateToNewLot,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: UIConstants.spacing16, vertical: UIConstants.spacing12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: UIConstants.iconContainerSmall,
                                      height: UIConstants.iconContainerSmall,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: UIConstants.opacityMediumLow),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
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
                                          Text(
                                            'Registrar Nuevo Lote',
                                            style: TextStyle(
                                              fontSize: UIConstants.fontSizeBody,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            'Genera código QR para tu material',
                                            style: TextStyle(
                                              fontSize: UIConstants.fontSizeSmall,
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
                        
                        // Sección de lotes recientes
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Lotes Recientes',
                              style: TextStyle(
                                fontSize: UIConstants.fontSizeXLarge,
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
                                      fontSize: UIConstants.fontSizeMedium,
                                      color: _primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: UIConstants.spacing4),
                                  Icon(
                                    Icons.arrow_forward,
                                    size: UIConstants.iconSizeSmall,
                                    color: _primaryColor,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Lista de lotes con nuevo diseño
                        if (_lotesRecientes.isEmpty)
                          Container(
                            padding: EdgeInsetsConstants.paddingAll32,
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    size: UIConstants.iconSizeEmpty,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: UIConstants.spacing16),
                                  Text(
                                    'Aún no hay lotes creados',
                                    style: TextStyle(
                                      fontSize: UIConstants.fontSizeBody,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: UIConstants.spacing8),
                                  Text(
                                    'Presiona el botón + para crear tu primer lote',
                                    style: TextStyle(
                                      fontSize: UIConstants.fontSizeMedium,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ..._lotesRecientes.map((lote) => OrigenLoteCard(
                            lote: {
                              'id': lote.id,
                              'firebaseId': lote.id,
                              'material': lote.tipoPoli,
                              'peso': lote.pesoNace,
                              'presentacion': lote.presentacion,
                              'fuente': lote.fuente,
                              'fecha': lote.fechaNace,
                              'estado': 'activo',
                            },
                            onQRTap: () => _showQRCode({
                              'firebaseId': lote.id!,
                              'material': lote.tipoPoli,
                              'peso': lote.pesoNace,
                              'presentacion': lote.presentacion,
                              'fuente': lote.fuente,
                              'fecha': lote.fechaNace,
                            }),
                            showActions: true,
                          )),
                        
                        SizedBox(height: UIConstants.spacing40 + UIConstants.spacing40 + UIConstants.spacing20), // 100 - Espacio para el FAB
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
        primaryColor: _primaryColor,
        items: EcoceNavigationConfigs.origenItems,
        fabConfig: FabConfig(
          icon: Icons.add,
          onPressed: _navigateToNewLot,
          tooltip: 'Nuevo Lote',
        ),
      ),
      floatingActionButton: EcoceFloatingActionButton(
        onPressed: _navigateToNewLot,
        icon: Icons.add,
        backgroundColor: _primaryColor,
        tooltip: 'Nuevo Lote',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }





}