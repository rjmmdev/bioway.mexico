import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import '../../../services/user_session_service.dart';
import '../../../models/ecoce/ecoce_profile_model.dart';
import '../shared/widgets/unified_stat_card.dart';
import 'transformador_navigation.dart';
import 'transformador_lote_detail_screen.dart';

class TransformadorHomeScreen extends StatefulWidget {
  const TransformadorHomeScreen({super.key});

  @override
  State<TransformadorHomeScreen> createState() => _TransformadorHomeScreenState();
}

class _TransformadorHomeScreenState extends State<TransformadorHomeScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Servicio de sesión
  final UserSessionService _sessionService = UserSessionService();
  
  // Datos del usuario
  EcoceProfileModel? _userProfile;
  bool _isLoading = true;
  
  // Datos que vienen del perfil
  String get _nombreEmpresa => _userProfile?.ecoceNombre ?? 'Cargando...';
  String get _folioTransformador => _userProfile?.ecoceFolio ?? 'PENDIENTE';
  
  // Estadísticas (temporalmente hardcodeadas)
  final int _lotesRecibidos = 47;
  final int _productosCreados = 28;
  final double _materialProcesado = 4.5; // en toneladas
  
  // Lista de lotes en proceso
  final List<Map<String, dynamic>> _lotesEnProceso = [
    {
      'id': 'Firebase_ID_1x7h9k3',
      'origen': 'RECICLADOR PLASTICOS DEL NORTE',
      'material': 'PET',
      'fecha': '14/07/2025',
      'fechaISO': '2025-07-14T10:30:00',
      'peso': 120.0,
      'estado': 'RECIBIDO',
      'estadoColor': Colors.blue,
      'producto': 'Envases PET',
      'tiposAnalisis': ['Inyección', 'Extrusión'],
      'composicion': 'PET reciclado 70%, PET virgen 30%, estabilizadores UV 0.5%',
      'comentarios': 'Material de alta calidad, cumple con normas ISO 9001',
      'procesosAplicados': ['Lavado', 'Secado', 'Extrusión'],
    },
    {
      'id': 'Firebase_ID_2a9m5p1',
      'origen': 'CENTRO DE ACOPIO SUSTENTABLE',
      'material': 'LDPE',
      'fecha': '14/07/2025',
      'fechaISO': '2025-07-14T08:15:00',
      'peso': 85.5,
      'estado': 'RECIBIDO',
      'estadoColor': Colors.blue,
      'producto': 'Láminas LDPE',
      'tiposAnalisis': ['Soplado', 'Laminado', 'Termoformado'],
      'composicion': 'LDPE reciclado 80%, aditivos antioxidantes 2%, pigmentos 1%',
      'comentarios': 'Procesamiento especial requerido para cliente premium',
      'procesosAplicados': ['Trituración', 'Lavado', 'Laminado'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToRecibirLotes() {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, '/transformador_recibir_lote');
  }

  void _navigateToDocumentacion() {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, '/transformador_documentacion');
  }

  void _navigateToLoteDetalle(Map<String, dynamic> lote) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransformadorLoteDetailScreen(
          firebaseId: lote['id'],
          peso: lote['peso'].toDouble(),
          tiposAnalisis: lote['tiposAnalisis'] ?? ['Extrusión', 'Inyección'],
          productoFabricado: lote['producto'] ?? 'Producto no especificado',
          composicionMaterial: lote['composicion'] ?? 'Material reciclado procesado según estándares de calidad',
          fechaCreacion: DateTime.parse(lote['fechaISO'] ?? DateTime.now().toIso8601String()),
          procesosAplicados: lote['procesosAplicados'] ?? [],
          comentarios: lote['comentarios'],
        ),
      ),
    );
  }

  void _onBottomNavTapped(int index) {
    if (index == 0) return; // Already on home
    TransformadorNavigation.handleNavigation(context, index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        BioWayColors.petBlue,
                        BioWayColors.petBlue.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            // Logo o ícono
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.factory_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Información del transformador
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _nombreEmpresa,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.badge_outlined,
                                          size: 14,
                                          color: Colors.white70,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Folio: $_folioTransformador',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
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
                      // Estadísticas
                      Container(
                        height: 120,
                        margin: const EdgeInsets.only(bottom: 20),
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: [
                            StatisticCard(
                              icon: Icons.inbox_rounded,
                              label: 'Lotes Recibidos',
                              value: _lotesRecibidos.toString(),
                              iconColor: BioWayColors.petBlue,
                              width: 140,
                            ),
                            const SizedBox(width: 12),
                            StatisticCard(
                              icon: Icons.category_rounded,
                              label: 'Productos Creados',
                              value: _productosCreados.toString(),
                              iconColor: BioWayColors.success,
                              width: 140,
                            ),
                            const SizedBox(width: 12),
                            StatisticCard(
                              icon: Icons.scale_rounded,
                              label: 'Material Procesado',
                              value: _materialProcesado.toString(),
                              unit: 't',
                              iconColor: BioWayColors.warning,
                              width: 140,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Acciones rápidas
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Acciones rápidas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: BioWayColors.darkGreen,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickAction(
                              icon: Icons.add_box_rounded,
                              label: 'Recibir Lotes',
                              color: BioWayColors.petBlue,
                              onTap: _navigateToRecibirLotes,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickAction(
                              icon: Icons.description_rounded,
                              label: 'Documentación',
                              color: BioWayColors.warning,
                              onTap: _navigateToDocumentacion,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Lotes en proceso
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Lotes en proceso',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: BioWayColors.darkGreen,
                        ),
                      ),
                      Text(
                        '${_lotesEnProceso.length} activos',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Lista de lotes
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildLoteCard(_lotesEnProceso[index]),
                    childCount: _lotesEnProceso.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: TransformadorNavigation.buildBottomNavigation(
        selectedIndex: 0,
        onItemTapped: _onBottomNavTapped,
      ),
      floatingActionButton: TransformadorNavigation.buildFloatingActionButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: BioWayColors.darkGreen,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoteCard(Map<String, dynamic> lote) {
    final materialColor = TransformadorNavigation.getMaterialColor(lote['material'] ?? '');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToLoteDetalle(lote),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icono del material
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          materialColor.withValues(alpha: 0.2),
                          materialColor.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      TransformadorNavigation.getMaterialIcon(lote['material'] ?? ''),
                      color: materialColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Información del lote
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lote ${lote['id'] ?? ''}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lote['producto'] ?? 'Producto',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: BioWayColors.darkGreen,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.scale_outlined,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${lote['peso']} kg',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              lote['fecha'] ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Estado
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: (lote['estadoColor'] as Color).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      lote['estado'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: lote['estadoColor'] as Color,
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
}