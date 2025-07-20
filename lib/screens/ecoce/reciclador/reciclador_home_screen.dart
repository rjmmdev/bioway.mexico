import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import '../../../services/user_session_service.dart';
import '../../../models/ecoce/ecoce_profile_model.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import '../shared/widgets/unified_stat_card.dart';
import '../shared/widgets/unified_container.dart';
import '../shared/widgets/quick_action_button.dart';
import '../shared/widgets/loading_wrapper.dart';
import 'reciclador_services.dart';
import 'reciclador_lot_management_screen.dart';
import 'reciclador_forms_screen.dart';
import 'reciclador_documentacion.dart';
import 'reciclador_lote_qr_screen.dart';

/// Main home screen for reciclador role
class RecicladorHomeScreen extends StatefulWidget {
  const RecicladorHomeScreen({super.key});

  @override
  State<RecicladorHomeScreen> createState() => _RecicladorHomeScreenState();
}

class _RecicladorHomeScreenState extends State<RecicladorHomeScreen> {
  final UserSessionService _sessionService = UserSessionService();
  
  EcoceProfileModel? _userProfile;
  bool _isLoading = true;

  // Statistics (mock data for now)
  final int _lotesRecibidos = 45;
  final int _lotesCreados = 38;
  final double _pesoProcesado = 1250.5;

  // Recent lots with different states
  final List<Map<String, dynamic>> _lotesRecientes = [
    {
      'id': 'LOTE-2024-001',
      'fecha': DateTime.now().subtract(const Duration(hours: 2)),
      'peso': 125.5,
      'material': 'PEBD',
      'origen': 'Acopiador Norte',
      'presentacion': 'Pacas',
      'estado': LotState.salida,
    },
    {
      'id': 'LOTE-2024-002',
      'fecha': DateTime.now().subtract(const Duration(hours: 5)),
      'peso': 89.3,
      'material': 'PP',
      'origen': 'Planta Separación Sur',
      'presentacion': 'Sacos',
      'estado': LotState.documentacion,
      'pesoSalida': 87.5,
      'merma': 2.0,
    },
    {
      'id': 'LOTE-2024-003',
      'fecha': DateTime.now().subtract(const Duration(days: 1)),
      'peso': 200.8,
      'material': 'Multi',
      'origen': 'Acopiador Centro',
      'presentacion': 'Pacas',
      'estado': LotState.finalizado,
      'pesoSalida': 195.0,
      'merma': 2.9,
      'destino': 'Transformador XYZ',
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

  void _navigateToScanLots() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RecicladorLotManagementScreen(),
      ),
    );
  }

  void _navigateToLotManagement() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const RecicladorLotManagementScreen(),
      ),
    );
  }

  void _handleLotTap(Map<String, dynamic> lote) {
    switch (lote['estado'] as LotState) {
      case LotState.salida:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecicladorFormsScreen.salida(
              lotData: lote,
            ),
          ),
        );
        break;
      case LotState.documentacion:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecicladorDocumentacion(
              lotId: lote['id'] ?? 'LOTE-${DateTime.now().millisecondsSinceEpoch}',
            ),
          ),
        );
        break;
      case LotState.finalizado:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecicladorLoteQRScreen(
              loteId: lote['id'] ?? '',
              material: lote['material'] ?? '',
              pesoOriginal: (lote['peso'] ?? 0.0).toDouble(),
              pesoFinal: (lote['pesoSalida'] ?? lote['peso'] ?? 0.0).toDouble(),
              presentacion: lote['presentacion'] ?? 'Pacas',
              origen: lote['origen'] ?? '',
              fechaEntrada: lote['fecha'] as DateTime?,
              fechaSalida: DateTime.now(),
              mostrarMensajeExito: false,
            ),
          ),
        );
        break;
    }
  }

  void _onBottomNavTapped(int index) {
    if (index == 0) return; // Already on home
    
    switch (index) {
      case 1:
        Navigator.pushReplacementNamed(context, '/reciclador_lotes');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/reciclador_ayuda');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/reciclador_perfil');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingWrapper(
      isLoading: _isLoading,
      hasError: !_isLoading && _userProfile == null,
      onRetry: _loadUserData,
      primaryColor: BioWayColors.recycleOrange,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                GradientHeader(
                  title: _userProfile?.ecoceNombre ?? 'Reciclador',
                  subtitle: 'Gestión de Reciclaje',
                  icon: Icons.recycling,
                  gradientColors: [
                    BioWayColors.recycleOrange,
                    BioWayColors.recycleOrange.withValues(alpha: 0.8),
                  ],
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _userProfile?.ecoceFolio ?? 'R0000001',
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
                        icon: Icons.inbox_rounded,
                        label: 'Lotes Recibidos',
                        value: _lotesRecibidos.toString(),
                        iconColor: BioWayColors.recycleOrange,
                        width: 140,
                      ),
                      const SizedBox(width: 12),
                      StatisticCard(
                        icon: Icons.output_rounded,
                        label: 'Lotes Creados',
                        value: _lotesCreados.toString(),
                        iconColor: BioWayColors.success,
                        width: 140,
                      ),
                      const SizedBox(width: 12),
                      StatisticCard(
                        icon: Icons.scale_rounded,
                        label: 'Peso Procesado',
                        value: RecicladorServices.formatWeight(_pesoProcesado),
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
                              label: 'Escanear\nLotes',
                              backgroundColor: BioWayColors.recycleOrange,
                              onPressed: _navigateToScanLots,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: QuickActionButton(
                              icon: Icons.inventory_2,
                              label: 'Administrar\nLotes',
                              backgroundColor: BioWayColors.petBlue,
                              onPressed: _navigateToLotManagement,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Recent Lots
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Lotes Recientes',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: BioWayColors.darkGreen,
                            ),
                          ),
                          TextButton(
                            onPressed: _navigateToLotManagement,
                            child: const Text('Ver todos'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ..._lotesRecientes.map((lote) => _buildLoteCard(lote)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: EcoceBottomNavigation(
          selectedIndex: 0,
          onItemTapped: _onBottomNavTapped,
          primaryColor: BioWayColors.recycleOrange,
          items: EcoceNavigationConfigs.recicladorItems,
        ),
        floatingActionButton: EcoceFloatingActionButton(
          onPressed: _navigateToScanLots,
          icon: Icons.add,
          backgroundColor: BioWayColors.recycleOrange,
          tooltip: 'Escanear Lotes',
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  Widget _buildLoteCard(Map<String, dynamic> lote) {
    final estado = lote['estado'] as LotState;
    final material = lote['material'] as String;
    final materialColor = RecicladorServices.getMaterialColor(material);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        child: InkWell(
          onTap: () => _handleLotTap(lote),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: materialColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    RecicladorServices.getMaterialIcon(material),
                    color: materialColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lote['id'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: BioWayColors.darkGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${material} • ${RecicladorServices.formatWeight(lote['peso'])} • ${lote['presentacion']}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              lote['origen'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: estado.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getEstadoIcon(estado),
                            size: 14,
                            color: estado.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            estado.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: estado.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      RecicladorServices.getTimeAgo(lote['fecha']),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getEstadoIcon(LotState estado) {
    switch (estado) {
      case LotState.salida:
        return Icons.output;
      case LotState.documentacion:
        return Icons.description;
      case LotState.finalizado:
        return Icons.check_circle;
    }
  }
}