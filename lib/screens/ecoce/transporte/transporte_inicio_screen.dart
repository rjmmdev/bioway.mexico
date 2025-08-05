import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../utils/colors.dart';
import '../../../utils/format_utils.dart';
import '../../../utils/ui_constants.dart';
import '../../../services/user_session_service.dart';
import '../../../models/ecoce/ecoce_profile_model.dart';
import '../../../services/carga_transporte_service.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import '../shared/widgets/unified_stat_card.dart';
import '../shared/utils/material_utils.dart';
import 'transporte_entregar_screen.dart';
import 'transporte_escanear_carga_screen.dart';

class TransporteInicioScreen extends StatefulWidget {
  const TransporteInicioScreen({super.key});

  @override
  State<TransporteInicioScreen> createState() => _TransporteInicioScreenState();
}

class _TransporteInicioScreenState extends State<TransporteInicioScreen> {
  final UserSessionService _sessionService = UserSessionService();
  final CargaTransporteService _cargaService = CargaTransporteService();
  
  EcoceProfileModel? _userProfile;
  
  // Estadísticas del transportista
  int _lotesEnTransitoCount = 0;  // Número de lotes en tránsito
  int _entregasRealizadas = 0;  // Número de lotes entregados

  // Lotes en tránsito (se cargarán de Firebase)
  List<Map<String, dynamic>> _lotesEnTransito = [];
  bool _isLoadingLotes = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadLotesEnTransito();
    _loadEstadisticas();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _sessionService.getCurrentUserProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _loadLotesEnTransito() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingLotes = true;
    });

    try {
      // Obtener lotes individuales en transporte desde las cargas
      final lotesInfo = await _cargaService.getLotesEnTransporte();
      
      List<Map<String, dynamic>> lotesFormateados = [];
      
      for (var lote in lotesInfo) {
        // Formatear el lote para la vista
        lotesFormateados.add({
          'id': lote['lote_id'],
          'firebaseId': lote['lote_id'],
          'material': lote['material'],
          'peso': lote['peso'],
          'origen': '${lote['origen_nombre']} (${lote['origen_folio']})',
          'fecha_recogida': lote['fecha_recogida'],
          'estado': 'en_transito',
          'carga_id': lote['carga_id'],
        });
      }

      if (mounted) {
        setState(() {
          _lotesEnTransito = lotesFormateados;
          _isLoadingLotes = false;
          // Actualizar la estadística de lotes en tránsito con el conteo actual
          _lotesEnTransitoCount = lotesFormateados.length;
        });
      }
    } catch (e) {
      print('Error cargando lotes en tránsito: $e');
      if (mounted) {
        setState(() {
          _isLoadingLotes = false;
        });
      }
    }
  }

  Future<void> _loadEstadisticas() async {
    try {
      // Obtener el número de lotes entregados por el transportista
      final lotesEntregados = await _cargaService.obtenerNumeroLotesEntregados();
      
      if (mounted) {
        setState(() {
          _entregasRealizadas = lotesEntregados;
          // _lotesEnTransitoCount se actualiza en _loadLotesEnTransito()
        });
      }
    } catch (e) {
      print('Error cargando estadísticas: $e');
    }
  }

  String get _nombreTransportista {
    return _userProfile?.ecoceNombre ?? 'Transportista';
  }

  String get _folioTransportista {
    return _userProfile?.ecoceFolio ?? 'V0000000';
  }

  void _navigateToRecoger() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TransporteEscanearCargaScreen(),
      ),
    );
  }

  void _navigateToEntregar() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TransporteEntregarScreen(),
      ),
    );
  }

  void _onBottomNavTapped(int index) {
    switch (index) {
      case 0:
        break; // Ya estamos aquí
      case 1:
        Navigator.pushReplacementNamed(context, '/transporte_entregar');
        break;
      case 2:
        Navigator.pushNamed(context, '/transporte_ayuda');
        break;
      case 3:
        Navigator.pushNamed(context, '/transporte_perfil');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // Prevent back navigation on home screen
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header moderno con gradiente
            SliverToBoxAdapter(
              child: Container(
                height: UIConstants.qrSizeLarge,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      BioWayColors.deepBlue,
                      BioWayColors.deepBlue.withValues(alpha: UIConstants.opacityVeryHigh),
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
                      padding: EdgeInsets.fromLTRB(UIConstants.spacing16, UIConstants.spacing12, UIConstants.spacing16, UIConstants.spacing16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Logo y fecha
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
                                        fontSize: UIConstants.fontSizeXSmall,
                                        color: Colors.white.withValues(alpha: UIConstants.opacityAlmostFull),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: UIConstants.spacing8),
                          // Nombre del transportista
                          Text(
                            _nombreTransportista,
                            style: const TextStyle(
                              fontSize: UIConstants.fontSizeTitle,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                          SizedBox(height: UIConstants.spacing4),
                          // Badge con tipo y folio
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: UIConstants.spacing12,
                                  vertical: UIConstants.spacing4 + 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: UIConstants.opacityAlmostFull),
                                  borderRadius: BorderRadiusConstants.borderRadiusLarge,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.local_shipping,
                                      size: UIConstants.iconSizeSmall,
                                      color: BioWayColors.deepBlue,
                                    ),
                                    SizedBox(width: UIConstants.spacing4 + 2),
                                    Text(
                                      'Transportista',
                                      style: TextStyle(
                                        fontSize: UIConstants.fontSizeSmall,
                                        fontWeight: FontWeight.w600,
                                        color: BioWayColors.deepBlue,
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
                                  color: BioWayColors.deepBlue,
                                  borderRadius: BorderRadiusConstants.borderRadiusLarge,
                                ),
                                child: Text(
                                  _folioTransportista,
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
                          // Estadísticas con UnifiedStatCard en una sola fila
                          Row(
                            children: [
                              // Estadística de Lotes en Tránsito
                              Expanded(
                                child: UnifiedStatCard.horizontal(
                                  title: 'Lotes en tránsito',
                                  value: _lotesEnTransitoCount.toString(),
                                  icon: Icons.inventory_2,
                                  color: BioWayColors.warning,
                                  height: UIConstants.statCardHeight,
                                ),
                              ),
                              SizedBox(width: UIConstants.spacing12),
                              // Estadística de Entregas Realizadas
                              Expanded(
                                child: UnifiedStatCard.horizontal(
                                  title: 'Entregas realizadas',
                                  value: _entregasRealizadas.toString(),
                                  icon: Icons.check_circle,
                                  color: BioWayColors.primaryGreen,
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
                margin: EdgeInsets.only(top: UIConstants.spacing8 + 2),
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(UIConstants.radiusXLarge - 2),
                    topRight: Radius.circular(UIConstants.radiusXLarge - 2),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(UIConstants.spacing16, UIConstants.spacing20, UIConstants.spacing16, UIConstants.spacing20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Acciones rápidas con diseño unificado en dos filas
                      // Primer botón - Recoger Materiales
                      Container(
                        width: double.infinity,
                        height: UIConstants.buttonHeightLarge,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              BioWayColors.primaryGreen,
                              BioWayColors.primaryGreen.withValues(alpha: UIConstants.opacityVeryHigh),
                            ],
                          ),
                          borderRadius: BorderRadiusConstants.borderRadiusLarge,
                          boxShadow: [
                            BoxShadow(
                              color: BioWayColors.primaryGreen.withValues(alpha: UIConstants.opacityMedium),
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
                            onTap: _navigateToRecoger,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: UIConstants.spacing16, vertical: UIConstants.spacing12),
                              child: Row(
                                children: [
                                  Container(
                                    width: UIConstants.iconContainerMedium,
                                    height: UIConstants.iconContainerMedium,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: UIConstants.opacityMediumLow),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.qr_code_scanner,
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
                                          'Recoger Materiales',
                                          style: TextStyle(
                                            fontSize: UIConstants.fontSizeBody,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          'Escanear lotes para transporte',
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
                      SizedBox(height: UIConstants.spacing12),
                      // Segundo botón - Entregar Materiales
                      Container(
                        width: double.infinity,
                        height: UIConstants.buttonHeightLarge,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              BioWayColors.deepBlue,
                              BioWayColors.deepBlue.withValues(alpha: UIConstants.opacityVeryHigh),
                            ],
                          ),
                          borderRadius: BorderRadiusConstants.borderRadiusLarge,
                          boxShadow: [
                            BoxShadow(
                              color: BioWayColors.deepBlue.withValues(alpha: UIConstants.opacityMedium),
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
                            onTap: _navigateToEntregar,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: UIConstants.spacing16, vertical: UIConstants.spacing12),
                              child: Row(
                                children: [
                                  Container(
                                    width: UIConstants.iconContainerMedium,
                                    height: UIConstants.iconContainerMedium,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: UIConstants.opacityMediumLow),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.local_shipping,
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
                                          'Entregar Materiales',
                                          style: TextStyle(
                                            fontSize: UIConstants.fontSizeBody,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          'Gestionar entregas de lotes',
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
                      SizedBox(height: UIConstants.spacing24),

                      // Lotes en tránsito
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: BioWayColors.warning.withValues(alpha: UIConstants.opacityLow),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.local_shipping,
                                  color: BioWayColors.warning,
                                  size: UIConstants.iconSizeMedium,
                                ),
                              ),
                              SizedBox(width: UIConstants.spacing12),
                              const Text(
                                'Lotes en Tránsito',
                                style: TextStyle(
                                  fontSize: UIConstants.fontSizeLarge,
                                  fontWeight: FontWeight.bold,
                                  color: BioWayColors.darkGreen,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: BioWayColors.warning.withValues(alpha: UIConstants.opacityMediumLow),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_lotesEnTransito.length}',
                              style: TextStyle(
                                fontSize: UIConstants.fontSizeMedium,
                                fontWeight: FontWeight.bold,
                                color: BioWayColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: UIConstants.spacing16),
                      
                      if (_isLoadingLotes)
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadiusConstants.borderRadiusLarge,
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: UIConstants.opacityMediumLow),
                            ),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: BioWayColors.deepBlue,
                            ),
                          ),
                        )
                      else if (_lotesEnTransito.isEmpty) 
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadiusConstants.borderRadiusLarge,
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: UIConstants.opacityMediumLow),
                            ),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.local_shipping_outlined,
                                  size: UIConstants.iconSizeXLarge - UIConstants.spacing16,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: UIConstants.spacing16),
                                Text(
                                  'No hay lotes en tránsito',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: UIConstants.spacing8),
                                Text(
                                  'Escanea nuevos lotes para comenzar',
                                  style: TextStyle(
                                    fontSize: UIConstants.fontSizeMedium,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else ..._lotesEnTransito.map((lote) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildLoteEnTransitoCard(lote),
                        )),
                      
                      SizedBox(height: UIConstants.spacing40 + UIConstants.spacing20), // Espacio para el bottom nav
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: EcoceBottomNavigation(
        selectedIndex: 0,
        onItemTapped: _onBottomNavTapped,
        primaryColor: BioWayColors.deepBlue,
        items: const [
          NavigationItem(
            icon: Icons.qr_code_scanner_rounded,
            label: 'Recoger',
            testKey: 'transporte_nav_recoger',
          ),
          NavigationItem(
            icon: Icons.local_shipping_rounded,
            label: 'Entregar',
            testKey: 'transporte_nav_entregar',
          ),
          NavigationItem(
            icon: Icons.help_outline_rounded,
            label: 'Ayuda',
            testKey: 'transporte_nav_ayuda',
          ),
          NavigationItem(
            icon: Icons.person_outline_rounded,
            label: 'Perfil',
            testKey: 'transporte_nav_perfil',
          ),
        ],
      ),
      ),
    );
  }


  Widget _buildLoteEnTransitoCard(Map<String, dynamic> lote) {
    final materialColor = MaterialUtils.getMaterialColor(lote['material'] ?? '');
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 360;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            // Navegar a la pantalla de entregar
            Navigator.pushNamed(context, '/transporte_entregar');
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(isCompact ? 12 : 16),
              child: Row(
                children: [
                  // Icono del material
                  Container(
                    width: isCompact ? 42 : 48,
                    height: isCompact ? 42 : 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          materialColor.withValues(alpha:0.2),
                          materialColor.withValues(alpha:0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      MaterialUtils.getMaterialIcon(lote['material'] ?? ''),
                      color: materialColor,
                      size: isCompact ? 20 : 24,
                    ),
                  ),
                  SizedBox(width: isCompact ? 12 : 16),
                  // Información del lote
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Primera línea: Material y ID
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isCompact ? 6 : 8,
                                vertical: isCompact ? 2 : 3,
                              ),
                              decoration: BoxDecoration(
                                color: materialColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                lote['material'] ?? '',
                                style: TextStyle(
                                  fontSize: isCompact ? 10 : 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: UIConstants.spacing8),
                            Flexible(
                              child: Text(
                                'Lote ${lote['id'] ?? lote['firebaseId'] ?? ''}',
                                style: TextStyle(
                                  fontSize: isCompact ? 10 : 11,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: UIConstants.spacing4 + 2),
                        // Segunda línea: Origen
                        Text(
                          lote['origen'] ?? 'Origen desconocido',
                          style: TextStyle(
                            fontSize: isCompact ? 13 : 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        SizedBox(height: UIConstants.spacing4),
                        // Tercera línea: Peso, Presentación y Fecha
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            _buildCompactChip(
                              Icons.scale_outlined,
                              '${lote['peso']} kg',
                              Colors.blue,
                              isCompact,
                            ),
                            _buildCompactChip(
                              Icons.schedule,
                              _getTimeElapsed(lote['fecha_recogida']),
                              Colors.orange,
                              isCompact,
                            ),
                            if (lote['estado'] == 'en_transito')
                              _buildStatusChip(
                                'En tránsito',
                                BioWayColors.warning,
                                isCompact,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Botón de acción (solo icono)
                  SizedBox(width: isCompact ? 8 : 12),
                  Container(
                    decoration: BoxDecoration(
                      color: BioWayColors.deepBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          // Navegar a la pantalla de entregar
                          Navigator.pushNamed(context, '/transporte_entregar');
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: EdgeInsets.all(isCompact ? 8 : 10),
                          child: Icon(
                            Icons.visibility,
                            color: Colors.white,
                            size: isCompact ? 18 : 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactChip(IconData icon, String text, Color color, bool isCompact) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8, 
        vertical: isCompact ? 3 : 4
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isCompact ? 11 : 12,
            color: color,
          ),
          SizedBox(width: UIConstants.spacing4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: isCompact ? 10 : 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildStatusChip(String status, Color color, bool isCompact) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8,
        vertical: isCompact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_shipping,
            size: isCompact ? 11 : 12,
            color: color,
          ),
          SizedBox(width: UIConstants.spacing4),
          Text(
            status,
            style: TextStyle(
              fontSize: isCompact ? 10 : 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeElapsed(DateTime? pickupTime) {
    if (pickupTime == null) return 'Recién';
    
    final now = DateTime.now();
    final difference = now.difference(pickupTime);
    
    if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours}h';
    } else {
      return 'Hace ${difference.inDays}d';
    }
  }

}