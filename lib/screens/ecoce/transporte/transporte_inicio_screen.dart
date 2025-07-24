import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../utils/colors.dart';
import '../../../utils/format_utils.dart';
import '../../../services/user_session_service.dart';
import '../../../models/ecoce/ecoce_profile_model.dart';
import '../../../services/lote_service.dart';
import '../../../services/carga_transporte_service.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import '../shared/widgets/unified_stat_card.dart';
import '../shared/utils/material_utils.dart';
import '../shared/utils/dialog_utils.dart';
import 'transporte_entregar_screen.dart';
import 'transporte_escanear_carga_screen.dart';

class TransporteInicioScreen extends StatefulWidget {
  const TransporteInicioScreen({super.key});

  @override
  State<TransporteInicioScreen> createState() => _TransporteInicioScreenState();
}

class _TransporteInicioScreenState extends State<TransporteInicioScreen> {
  final UserSessionService _sessionService = UserSessionService();
  final LoteService _loteService = LoteService();
  final CargaTransporteService _cargaService = CargaTransporteService();
  
  EcoceProfileModel? _userProfile;
  
  // Estadísticas del transportista
  int _viajesRealizados = 0;
  int _lotesTransportados = 0;  // Ahora mostrará el número de lotes en tránsito
  double _kilometrosRecorridos = 0.0;
  int _entregas = 0;

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
          // Actualizar la estadística de lotes transportados con el conteo actual
          _lotesTransportados = lotesFormateados.length;
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
      // Obtener el userId del transportista actual
      final userData = _sessionService.getUserData();
      final userId = userData?['uid'] ?? '';
      
      if (userId.isEmpty) {
        return;
      }
      
      // Obtener todos los lotes del transportista actual
      final todosLotesStream = _loteService.getLotesTransportistaByUserId(
        userId: userId,
      );
      final todosLotes = await todosLotesStream.first;

      int viajes = 0;
      int entregas = 0;
      
      for (final lote in todosLotes) {
        viajes++;
        
        // Contar entregas completadas
        if (lote.estado == 'entregado') {
          entregas++;
        }
      }

      if (mounted) {
        setState(() {
          _viajesRealizados = viajes;
          _entregas = entregas;
          // _lotesTransportados se actualiza en _loadLotesEnTransito()
          // _kilometrosRecorridos se mantiene en 0 por ahora
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
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header moderno con gradiente
            SliverToBoxAdapter(
              child: Container(
                height: 320,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      BioWayColors.deepBlue,
                      BioWayColors.deepBlue.withValues(alpha: 0.8),
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
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                          const SizedBox(height: 8),
                          // Nombre del transportista
                          Text(
                            _nombreTransportista,
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
                                      Icons.local_shipping,
                                      size: 16,
                                      color: BioWayColors.deepBlue,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Transportista',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: BioWayColors.deepBlue,
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
                                  color: BioWayColors.deepBlue,
                                  borderRadius: BorderRadius.circular(20),
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
                          const SizedBox(height: 16),
                          // Estadísticas con UnifiedStatCard
                          Row(
                            children: [
                              // Estadística de Viajes Realizados
                              Expanded(
                                child: UnifiedStatCard.horizontal(
                                  title: 'Viajes realizados',
                                  value: _viajesRealizados.toString(),
                                  icon: Icons.route,
                                  color: BioWayColors.petBlue,
                                  height: 70,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Estadística de Lotes en Tránsito (disponibles para entregar)
                              Expanded(
                                child: UnifiedStatCard.horizontal(
                                  title: 'Lotes en tránsito',
                                  value: _lotesEnTransito.length.toString(),
                                  icon: Icons.inventory_2,
                                  color: BioWayColors.ppPurple,
                                  height: 70,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Segunda fila con Entregas realizadas centrado
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Estadística de Entregas
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.45,
                                child: UnifiedStatCard.horizontal(
                                  title: 'Entregas realizadas',
                                  value: _entregas.toString(),
                                  icon: Icons.local_shipping,
                                  color: BioWayColors.primaryGreen,
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

                      // Acciones rápidas con diseño unificado en dos filas
                      // Primer botón - Recoger Materiales
                      Container(
                        width: double.infinity,
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              BioWayColors.primaryGreen,
                              BioWayColors.primaryGreen.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: BioWayColors.primaryGreen.withValues(alpha: 0.3),
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
                            onTap: _navigateToRecoger,
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
                                          'Recoger Materiales',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          'Escanear lotes para transporte',
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
                      const SizedBox(height: 12),
                      // Segundo botón - Entregar Materiales
                      Container(
                        width: double.infinity,
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              BioWayColors.deepBlue,
                              BioWayColors.deepBlue.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: BioWayColors.deepBlue.withValues(alpha: 0.3),
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
                            onTap: _navigateToEntregar,
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
                                      Icons.local_shipping,
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
                                          'Entregar Materiales',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          'Gestionar entregas de lotes',
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
                      const SizedBox(height: 24),

                      // Lotes en tránsito
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: BioWayColors.warning.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.local_shipping,
                                  color: BioWayColors.warning,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Lotes en Tránsito',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: BioWayColors.darkGreen,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: BioWayColors.warning.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_lotesEnTransito.length}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: BioWayColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      if (_isLoadingLotes)
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.2),
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
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.local_shipping_outlined,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No hay lotes en tránsito',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Escanea nuevos lotes para comenzar',
                                  style: TextStyle(
                                    fontSize: 14,
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
                      
                      const SizedBox(height: 60), // Espacio para el bottom nav
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
                            const SizedBox(width: 8),
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
                        const SizedBox(height: 6),
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
                        const SizedBox(height: 4),
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
          const SizedBox(width: 4),
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
          const SizedBox(width: 4),
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