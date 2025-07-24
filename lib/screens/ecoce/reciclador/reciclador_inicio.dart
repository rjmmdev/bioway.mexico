import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../utils/colors.dart';
import '../../../utils/format_utils.dart';
import '../../../services/user_session_service.dart';
import '../../../services/lote_service.dart';
import '../../../models/ecoce/ecoce_profile_model.dart';
import '../../../models/lotes/lote_reciclador_model.dart';
import 'reciclador_formulario_salida.dart';
import 'reciclador_documentacion.dart';
import 'reciclador_lote_qr_screen.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import '../shared/widgets/unified_stat_card.dart';
import '../shared/widgets/quick_action_button.dart';
import 'widgets/reciclador_lote_card.dart';

class RecicladorInicio extends StatefulWidget {
  const RecicladorInicio({super.key});

  @override
  State<RecicladorInicio> createState() => _RecicladorInicioState();
}

class _RecicladorInicioState extends State<RecicladorInicio> with WidgetsBindingObserver {
  final UserSessionService _sessionService = UserSessionService();
  final LoteService _loteService = LoteService();
  
  EcoceProfileModel? _userProfile;
  bool _isLoading = true;
  
  // Índice para la navegación del bottom bar
  final int _selectedIndex = 0;

  // Estadísticas reales
  int _lotesRecibidos = 0;
  int _lotesCreados = 0;
  double _pesoProcesado = 0.0; // en kg
  
  // Stream para lotes
  Stream<List<LoteRecicladorModel>>? _lotesStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserProfile();
    _loadStatistics();
    _setupLotesStream();
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app returns to foreground
      _loadUserProfile();
      _loadStatistics();
    }
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _setupLotesStream() {
    _lotesStream = _loteService.getLotesReciclador();
  }
  
  Future<void> _loadStatistics() async {
    try {
      // Obtener todos los lotes del reciclador
      final lotes = await _loteService.getLotesReciclador().first;
      
      // Obtener el total de lotes recibidos del perfil
      final profile = await _sessionService.getCurrentUserProfile();
      final lotesRecibidosTotal = profile?.ecoceLotesTotalesRecibidos ?? 0;
      
      if (mounted) {
        setState(() {
          _lotesRecibidos = lotesRecibidosTotal;
          _lotesCreados = lotes.where((l) => l.estado == 'finalizado').length;
          _pesoProcesado = lotes.fold(0.0, (sum, lote) => sum + (lote.pesoResultante ?? lote.pesoNeto ?? lote.pesoBruto ?? 0.0));
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

  String get _nombreReciclador {
    return _userProfile?.ecoceNombre ?? 'Reciclador';
  }

  String get _folioReciclador {
    return _userProfile?.ecoceFolio ?? 'R0000000';
  }

  // Convertir modelo de lote a Map para el widget
  Map<String, dynamic> _loteToMap(LoteRecicladorModel lote) {
    return {
      'id': lote.id,
      'fecha': FormatUtils.formatDate(DateTime.now()), // We don't have fechaIngreso
      'peso': lote.pesoNeto ?? lote.pesoBruto ?? 0.0,
      'material': lote.tipoPoli?.entries.firstOrNull?.key ?? 'Mixto',
      'origen': 'Reciclador', // We don't have recibeProveedor
      'presentacion': 'Pacas', // Default presentation
      'estado': lote.estado,
    };
  }

  void _navigateToNewLot() async {
    HapticFeedback.lightImpact();
    await Navigator.pushNamed(context, '/reciclador_escaneo');
    // Refresh statistics when returning from scanning
    _loadUserProfile();
    _loadStatistics();
  }

  void _navigateToLotControl() {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, '/reciclador_lotes');
  }

  void _onBottomNavTapped(int index) {
    HapticFeedback.lightImpact();
    
    if (index == _selectedIndex) return;
    
    switch (index) {
      case 0:
        // Ya estamos en inicio
        break;
      case 1:
        Navigator.pushNamed(context, '/reciclador_lotes');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/reciclador_ayuda');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/reciclador_perfil');
        break;
    }
  }

  // Obtener texto del botón según el estado
  String _getActionButtonText(String estado) {
    switch (estado) {
      case 'recibido':
        return 'Formulario Salida';
      case 'salida':
        return 'Formulario Salida';
      case 'procesado':
        return 'Formulario Salida';
      case 'enviado':
        return 'Añadir Documentación';
      case 'finalizado':
        return 'Ver Código QR';
      default:
        return '';
    }
  }

  // Obtener color del botón según el estado
  Color _getActionButtonColor(String estado) {
    switch (estado) {
      case 'recibido':
        return BioWayColors.error; // Rojo para salida
      case 'salida':
        return BioWayColors.error; // Rojo para salida
      case 'procesado':
        return BioWayColors.error; // Rojo para salida
      case 'enviado':
        return BioWayColors.warning; // Naranja para documentación
      case 'finalizado':
        return BioWayColors.ecoceGreen; // Verde para finalizados
      default:
        return BioWayColors.ecoceGreen;
    }
  }

  // Manejar tap en lote según su estado
  void _handleLoteTap(Map<String, dynamic> lote) {
    HapticFeedback.lightImpact();
    
    switch (lote['estado']) {
      case 'recibido':
      case 'salida':
      case 'procesado':
        // Navegar a formulario de salida
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecicladorFormularioSalida(
              loteId: lote['id'],
              pesoOriginal: lote['peso'].toDouble(),
            ),
          ),
        );
        break;
      case 'enviado':
        // Navegar a documentación
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecicladorDocumentacion(
              lotId: lote['id'],
            ),
          ),
        );
        break;
      case 'finalizado':
        // Navegar a vista de QR
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecicladorLoteQRScreen(
              loteId: lote['id'],
              material: lote['material'],
              pesoOriginal: lote['peso'].toDouble(),
              pesoFinal: lote['peso'].toDouble(), // TODO: Obtener de la BD
              presentacion: lote['presentacion'],
              origen: lote['origen'],
              fechaEntrada: DateTime.now().subtract(const Duration(days: 5)), // TODO: Obtener de la BD
              fechaSalida: DateTime.now(),
              documentosCargados: ['Ficha Técnica', 'Reporte de Reciclaje'], // TODO: Obtener de la BD
            ),
          ),
        );
        break;
    }
  }

  Widget _buildQRButton(Map<String, dynamic> lote) {
    return Container(
      decoration: BoxDecoration(
        color: BioWayColors.ecoceGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        onPressed: () => _handleLoteTap(lote),
        icon: Icon(
          Icons.qr_code_2,
          color: BioWayColors.ecoceGreen,
          size: 22,
        ),
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 36,
        ),
        tooltip: 'Ver QR',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevenir que el botón atrás cierre la sesión
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: SafeArea(
        child: CustomScrollView(
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
                          // Nombre del reciclador
                          Text(
                            _nombreReciclador,
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
                                      Icons.recycling,
                                      size: 16,
                                      color: BioWayColors.ecoceGreen,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Reciclador',
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
                                  color: BioWayColors.ecoceGreen,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _folioReciclador,
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
                              // Estadística de Lotes Recibidos
                              Expanded(
                                child: UnifiedStatCard.horizontal(
                                  title: 'Lotes recibidos',
                                  value: _lotesRecibidos.toString(),
                                  icon: Icons.inbox,
                                  color: BioWayColors.petBlue,
                                  height: 70,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Estadística de Lotes Creados
                              Expanded(
                                child: UnifiedStatCard.horizontal(
                                  title: 'Lotes creados',
                                  value: _lotesCreados.toString(),
                                  icon: Icons.add_box,
                                  color: BioWayColors.ppPurple,
                                  height: 70,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Segunda fila con Material Procesado centrado
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Estadística de Material Procesado
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.45,
                                child: UnifiedStatCard.horizontal(
                                  title: 'Material procesado',
                                  value: (_pesoProcesado / 1000).toStringAsFixed(1),
                                  unit: 'ton',
                                  icon: Icons.scale,
                                  color: BioWayColors.ecoceGreen,
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
                      // Primer botón - Escanear Nuevo Lote
                      Container(
                        width: double.infinity,
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              BioWayColors.ecoceGreen,
                              BioWayColors.ecoceGreen.withValues(alpha:0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: BioWayColors.ecoceGreen.withValues(alpha:0.3),
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
                            onTap: _navigateToNewLot,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha:0.2),
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
                                          'Escanear Nuevo Lote',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          'Recibir material para procesamiento',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.white.withValues(alpha:0.9),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.white.withValues(alpha:0.8),
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Segundo botón - Control de Lotes
                      Container(
                        width: double.infinity,
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              BioWayColors.petBlue,
                              BioWayColors.petBlue.withValues(alpha:0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: BioWayColors.petBlue.withValues(alpha:0.3),
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
                            onTap: _navigateToLotControl,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha:0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.inventory_2,
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
                                          'Control de Lotes',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          'Gestionar inventario y crear lotes',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.white.withValues(alpha:0.9),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.white.withValues(alpha:0.8),
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Sección de lotes recientes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Lotes Recientes',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          TextButton(
                            onPressed: _navigateToLotControl,
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
                      
                      // Lista de lotes con Stream de datos reales
                      StreamBuilder<List<LoteRecicladorModel>>(
                        stream: _lotesStream,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(40),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(40),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.inventory_2_outlined,
                                      size: 60,
                                      color: Colors.grey.shade300,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No hay lotes recientes',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          
                          final lotes = snapshot.data!.take(5).toList(); // Mostrar solo 5 más recientes
                          
                          return Column(
                            children: lotes.map((loteModel) {
                              final lote = _loteToMap(loteModel);
                              
                              // Para lotes finalizados, mostrar botón QR debajo
                              if (lote['estado'] == 'finalizado') {
                                return RecicladorLoteCard(
                                  lote: lote,
                                  onTap: null, // No hacer nada al tocar la tarjeta
                                  showActionButton: true,
                                  actionButtonText: 'Ver código QR',
                                  actionButtonColor: BioWayColors.ecoceGreen,
                                  onActionPressed: () => _handleLoteTap(lote),
                                  showActions: false, // No mostrar flecha lateral
                                );
                              }
                              
                              // Para otros estados, mostrar botón debajo
                              return RecicladorLoteCard(
                                lote: lote,
                                onTap: null, // No hacer nada al tocar la tarjeta
                                showActionButton: true,
                                actionButtonText: _getActionButtonText(lote['estado']),
                                actionButtonColor: _getActionButtonColor(lote['estado']),
                                onActionPressed: () => _handleLoteTap(lote),
                                showActions: false, // No mostrar flecha lateral
                              );
                            }).toList(),
                          );
                        },
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
        items: EcoceNavigationConfigs.recicladorItems,
        primaryColor: BioWayColors.ecoceGreen,
        fabConfig: FabConfig(
          onPressed: _navigateToNewLot,
          icon: Icons.add,
          tooltip: 'Escanear Lote',
        ),
      ),
      
      // Floating Action Button
      floatingActionButton: EcoceFloatingActionButton(
        onPressed: _navigateToNewLot,
        icon: Icons.add,
        backgroundColor: BioWayColors.ecoceGreen,
        tooltip: 'Escanear Nuevo Lote',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }
}