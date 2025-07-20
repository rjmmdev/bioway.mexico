import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import '../../../services/user_session_service.dart';
import '../../../models/ecoce/ecoce_profile_model.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import '../shared/widgets/unified_stat_card.dart';
import '../shared/widgets/unified_container.dart';
import '../shared/widgets/quick_action_button.dart';
import '../shared/widgets/loading_wrapper.dart';
import 'transporte_services.dart';
import 'transporte_lot_management_screen.dart';
import 'transporte_delivery_screen.dart';

/// Main home screen for transporte role
class TransporteHomeScreen extends StatefulWidget {
  const TransporteHomeScreen({super.key});

  @override
  State<TransporteHomeScreen> createState() => _TransporteHomeScreenState();
}

class _TransporteHomeScreenState extends State<TransporteHomeScreen> {
  final UserSessionService _sessionService = UserSessionService();
  
  EcoceProfileModel? _userProfile;
  bool _isLoading = true;

  // Statistics (mock data for now)
  final int _lotesRecogidos = 67;
  final int _lotesEntregados = 52;
  final int _lotesEnTransito = 15;
  final double _pesoTransportado = 3456.7;

  // Recent activities
  final List<Map<String, dynamic>> _actividadesRecientes = [
    {
      'tipo': 'recoleccion',
      'descripcion': 'Recolección en Centro Acopio Norte',
      'lotes': 5,
      'peso': 245.5,
      'fecha': DateTime.now().subtract(const Duration(hours: 2)),
      'estado': 'completado',
    },
    {
      'tipo': 'entrega',
      'descripcion': 'Entrega a Recicladora del Sur',
      'lotes': 3,
      'peso': 180.0,
      'fecha': DateTime.now().subtract(const Duration(hours: 5)),
      'estado': 'completado',
    },
    {
      'tipo': 'recoleccion',
      'descripcion': 'Recolección en Planta Separación Este',
      'lotes': 8,
      'peso': 420.0,
      'fecha': DateTime.now().subtract(const Duration(days: 1)),
      'estado': 'en_transito',
    },
  ];
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
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

  void _navigateToPickup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TransporteLotManagementScreen(),
      ),
    );
  }

  void _navigateToDelivery() {
    if (_lotesEnTransito == 0) {
      _showNoLotsDialog();
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TransporteDeliveryScreen(),
      ),
    );
  }

  void _showNoLotsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: BioWayColors.warning,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text('Sin lotes en tránsito'),
          ],
        ),
        content: const Text(
          'No tienes lotes disponibles para entregar. Primero debes recoger lotes desde los centros de acopio.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToPickup();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: BioWayColors.ecoceGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Ir a Recoger',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _onBottomNavTapped(int index) {
    switch (index) {
      case 0:
        _navigateToPickup();
        break;
      case 1:
        _navigateToDelivery();
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/transporte_ayuda');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/transporte_perfil');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingWrapper(
      isLoading: _isLoading,
      hasError: !_isLoading && _userProfile == null,
      onRetry: _loadUserData,
      primaryColor: BioWayColors.petBlue,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                GradientHeader(
                  title: _userProfile?.ecoceNombre ?? 'Transportista',
                  subtitle: 'Gestión de Transporte',
                  icon: Icons.local_shipping,
                  gradientColors: [
                    BioWayColors.petBlue,
                    BioWayColors.petBlue.withValues(alpha: 0.8),
                  ],
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _userProfile?.ecoceFolio ?? 'T0000001',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                // Statistics
                Container(
                  height: 120,
                  margin: const EdgeInsets.only(top: 20),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      StatisticCard(
                        icon: Icons.download_rounded,
                        label: 'Recogidos',
                        value: _lotesRecogidos.toString(),
                        iconColor: BioWayColors.ecoceGreen,
                        width: 120,
                      ),
                      const SizedBox(width: 12),
                      StatisticCard(
                        icon: Icons.upload_rounded,
                        label: 'Entregados',
                        value: _lotesEntregados.toString(),
                        iconColor: BioWayColors.petBlue,
                        width: 120,
                      ),
                      const SizedBox(width: 12),
                      StatisticCard(
                        icon: Icons.local_shipping,
                        label: 'En Tránsito',
                        value: _lotesEnTransito.toString(),
                        iconColor: BioWayColors.warning,
                        width: 120,
                      ),
                      const SizedBox(width: 12),
                      StatisticCard(
                        icon: Icons.scale,
                        label: 'Transportado',
                        value: TransporteServices.formatWeight(_pesoTransportado),
                        iconColor: BioWayColors.info,
                        width: 140,
                      ),
                    ],
                  ),
                ),
                
                // Quick Actions
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Acciones Rápidas',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: BioWayColors.darkGreen,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: QuickActionButton(
                              icon: Icons.qr_code_scanner,
                              label: 'Recoger\nLotes',
                              backgroundColor: BioWayColors.ecoceGreen,
                              onPressed: _navigateToPickup,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: QuickActionButton(
                              icon: Icons.delivery_dining,
                              label: 'Entregar\nLotes',
                              backgroundColor: BioWayColors.petBlue,
                              onPressed: _navigateToDelivery,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Recent Activities
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Actividad Reciente',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: BioWayColors.darkGreen,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._actividadesRecientes.map((actividad) => _buildActividadCard(actividad)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: EcoceBottomNavigation(
          selectedIndex: -1, // No item selected on home
          onItemTapped: _onBottomNavTapped,
          primaryColor: BioWayColors.petBlue,
          items: TransporteServices.navigationItems,
        ),
      ),
    );
  }

  Widget _buildActividadCard(Map<String, dynamic> actividad) {
    final isRecoleccion = actividad['tipo'] == 'recoleccion';
    final color = isRecoleccion ? BioWayColors.ecoceGreen : BioWayColors.petBlue;
    final icon = isRecoleccion ? Icons.download_rounded : Icons.upload_rounded;
    final isEnTransito = actividad['estado'] == 'en_transito';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        child: InkWell(
          onTap: isEnTransito ? _navigateToDelivery : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
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
                        actividad['descripcion'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: BioWayColors.darkGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${actividad['lotes']} lotes',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.scale_outlined,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            TransporteServices.formatWeight(actividad['peso']),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        TransporteServices.formatDateTime(actividad['fecha']),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isEnTransito)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: BioWayColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_shipping,
                          size: 14,
                          color: BioWayColors.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'En tránsito',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: BioWayColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}