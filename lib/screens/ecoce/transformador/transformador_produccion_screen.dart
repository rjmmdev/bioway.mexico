import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import 'transformador_lote_detail_screen.dart';

class TransformadorProduccionScreen extends StatefulWidget {
  const TransformadorProduccionScreen({super.key});

  @override
  State<TransformadorProduccionScreen> createState() => _TransformadorProduccionScreenState();
}

class _TransformadorProduccionScreenState extends State<TransformadorProduccionScreen> 
    with SingleTickerProviderStateMixin {
  final int _selectedIndex = 1; // Producción está en índice 1
  late TabController _tabController;
  int _selectedTabIndex = 0;
  
  // Datos de ejemplo
  final double _capacidadUtilizada = 85;
  final double _materialProcesado = 1.2;
  
  // Lista de lotes en proceso
  final List<Map<String, dynamic>> _lotesEnProceso = [
    {
      'id': 'Firebase_ID_3k8m2p7',
      'fechaInicio': '14/07/2025 08:30',
      'fechaISO': '2025-07-14T08:30:00',
      'peso': 450.0,
      'estado': 'EN PROCESO',
      'estadoColor': Colors.blue,
      'procesosAplicados': ['Lavado', 'Secado', 'Extrusión'],
      'producto': 'Perfiles PVC',
      'tiposAnalisis': ['Extrusión', 'Termoformado'],
      'composicion': 'PVC reciclado 75%, aditivos estabilizantes 5%, pigmentos 2%',
      'origen': 'RECICLADOR PLASTICOS DEL NORTE',
      'comentarios': 'Proceso de extrusión a temperatura controlada de 180°C',
    },
    {
      'id': 'Firebase_ID_5n2h9j4',
      'fechaInicio': '14/07/2025 10:15',
      'fechaISO': '2025-07-14T10:15:00',
      'peso': 320.0,
      'estado': 'EN PROCESO',
      'estadoColor': Colors.blue,
      'procesosAplicados': ['Trituración', 'Lavado', 'Clasificación', 'Secado'],
      'producto': 'Láminas transparentes',
      'tiposAnalisis': ['Laminado', 'Termoformado', 'Soplado'],
      'composicion': 'PET reciclado 85%, aditivos UV 3%, clarificantes 2%',
      'origen': 'CENTRO DE ACOPIO SUSTENTABLE',
      'comentarios': 'Material de alta transparencia para empaques',
    },
    {
      'id': 'Firebase_ID_7p4k1m8',
      'fechaInicio': '14/07/2025 12:00',
      'fechaISO': '2025-07-14T12:00:00',
      'peso': 280.0,
      'estado': 'EN PROCESO',
      'estadoColor': Colors.blue,
      'procesosAplicados': ['Lavado', 'Extrusión'],
      'producto': 'Tuberías HDPE',
      'tiposAnalisis': ['Extrusión', 'Inyección'],
      'composicion': 'HDPE reciclado 80%, HDPE virgen 18%, antioxidantes 2%',
      'origen': 'PLANTA DE RECICLAJE INDUSTRIAL',
      'comentarios': 'Producción para cliente industrial',
    },
  ];
  
  // Lista de lotes completados
  final List<Map<String, dynamic>> _lotesCompletados = [
    {
      'id': 'Firebase_ID_1a3b5c7',
      'fechaInicio': '13/07/2025 14:00',
      'fechaISO': '2025-07-13T14:00:00',
      'fechaFin': '14/07/2025 06:00',
      'peso': 500.0,
      'estado': 'COMPLETADO',
      'estadoColor': Colors.green,
      'procesosAplicados': ['Lavado', 'Secado', 'Extrusión', 'Empaque'],
      'producto': 'Contenedores industriales',
      'tiposAnalisis': ['Inyección', 'Rotomoldeo'],
      'composicion': 'PP reciclado 70%, PP virgen 28%, estabilizadores 2%',
      'origen': 'RECICLADOR ZONA INDUSTRIAL',
      'comentarios': 'Lote completado con éxito, calidad certificada ISO 9001',
    },
    {
      'id': 'Firebase_ID_2d4e6f8',
      'fechaInicio': '13/07/2025 09:00',
      'fechaISO': '2025-07-13T09:00:00',
      'fechaFin': '13/07/2025 18:00',
      'peso': 350.0,
      'estado': 'COMPLETADO',
      'estadoColor': Colors.green,
      'procesosAplicados': ['Trituración', 'Lavado', 'Secado'],
      'producto': 'Bolsas de plástico',
      'tiposAnalisis': ['Soplado', 'Laminado'],
      'composicion': 'LDPE reciclado 90%, aditivos biodegradables 10%',
      'origen': 'ACOPIADOR MUNICIPAL',
      'comentarios': 'Producción ecológica con aditivos biodegradables',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onBottomNavTapped(int index) {
    HapticFeedback.lightImpact();
    
    if (index == _selectedIndex) return;
    
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/transformador_inicio');
        break;
      case 1:
        // Ya estamos en producción
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/transformador_ayuda');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/transformador_perfil');
        break;
    }
  }

  void _onAddPressed() {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, '/transformador_recibir_lote');
  }

  void _verDetallesLote(Map<String, dynamic> lote) {
    HapticFeedback.lightImpact();
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

  Widget _buildCapacidadCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '📊',
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              const Text(
                'Capacidad de Producción - Hoy',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    '$_capacidadUtilizada%',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  Text(
                    'Capacidad Utilizada',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              Container(
                height: 60,
                width: 1,
                color: Colors.blue.shade200,
              ),
              Column(
                children: [
                  Text(
                    '$_materialProcesado t',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  Text(
                    'Material Procesado',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Barra de progreso
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _capacidadUtilizada / 100,
              minHeight: 12,
              backgroundColor: Colors.blue.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Máxima eficiencia: ${(100 - _capacidadUtilizada).toInt()}% restante disponible',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoteCard(Map<String, dynamic> lote) {
    final bool isCompletado = lote['estado'] == 'COMPLETADO';
    final productoColor = _getProductoColor(lote['producto'] ?? '');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _verDetallesLote(lote),
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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Icono del producto
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              productoColor.withValues(alpha: 0.2),
                              productoColor.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getProductoIcon(lote['producto'] ?? ''),
                          color: productoColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Información del lote
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Primera línea: Estado y ID
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: lote['estadoColor'].withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    lote['estado'],
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: lote['estadoColor'],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    lote['id'],
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Segunda línea: Producto
                            Text(
                              lote['producto'] ?? 'Producto en proceso',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 4),
                            // Tercera línea: Peso, Inicio/Fin, Procesos y Composición
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    _buildCompactChip(
                                      Icons.scale_outlined,
                                      '${lote['peso']} kg',
                                      Colors.blue,
                                    ),
                                    _buildCompactChip(
                                      Icons.access_time,
                                      isCompletado && lote['fechaFin'] != null
                                          ? 'Fin: ${lote['fechaFin'].split(' ')[0]}'
                                          : 'Inicio: ${lote['fechaInicio'].split(' ')[0]}',
                                      isCompletado ? Colors.green : Colors.orange,
                                    ),
                                    if ((lote['procesosAplicados'] as List<String>).isNotEmpty)
                                      _buildCompactChip(
                                        Icons.settings,
                                        '${(lote['procesosAplicados'] as List<String>).length} procesos',
                                        Colors.purple,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // Composición
                                Text(
                                  lote['composicion'] ?? '',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Flecha de navegación
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: () => _verDetallesLote(lote),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.grey.shade400,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Botón de acción inferior con QR para completados
                InkWell(
                  onTap: () => _verDetallesLote(lote),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: (isCompletado ? Colors.green : BioWayColors.ecoceGreen).withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isCompletado ? Icons.qr_code : Icons.remove_red_eye,
                          color: isCompletado ? Colors.green : BioWayColors.ecoceGreen,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isCompletado ? 'Ver Código QR' : 'Ver Detalles',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isCompletado ? Colors.green : BioWayColors.ecoceGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
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

  Color _getProductoColor(String producto) {
    // Asignar colores basados en el tipo de producto
    if (producto.toLowerCase().contains('pvc') || producto.toLowerCase().contains('perfil')) {
      return Colors.deepPurple;
    } else if (producto.toLowerCase().contains('pet') || producto.toLowerCase().contains('lámina')) {
      return Colors.teal;
    } else if (producto.toLowerCase().contains('hdpe') || producto.toLowerCase().contains('tubería')) {
      return Colors.blue;
    } else if (producto.toLowerCase().contains('pp') || producto.toLowerCase().contains('contenedor')) {
      return Colors.indigo;
    } else if (producto.toLowerCase().contains('ldpe') || producto.toLowerCase().contains('bolsa')) {
      return Colors.orange;
    } else {
      return BioWayColors.ecoceGreen;
    }
  }

  IconData _getProductoIcon(String producto) {
    // Asignar iconos basados en el tipo de producto
    if (producto.toLowerCase().contains('perfil')) {
      return Icons.straighten;
    } else if (producto.toLowerCase().contains('lámina')) {
      return Icons.layers;
    } else if (producto.toLowerCase().contains('tubería') || producto.toLowerCase().contains('tubo')) {
      return Icons.view_column;
    } else if (producto.toLowerCase().contains('contenedor')) {
      return Icons.inventory_2;
    } else if (producto.toLowerCase().contains('bolsa')) {
      return Icons.shopping_bag;
    } else if (producto.toLowerCase().contains('botella') || producto.toLowerCase().contains('envase')) {
      return Icons.local_drink;
    } else {
      return Icons.recycling;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        // Detectar swipe hacia la derecha (volver a inicio)
        if (details.primaryVelocity! > 100) {
          Navigator.pushReplacementNamed(context, '/transformador_inicio');
        }
        // Detectar swipe hacia la izquierda (ir a ayuda)
        else if (details.primaryVelocity! < -100) {
          Navigator.pushReplacementNamed(context, '/transformador_ayuda');
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Container(
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
                      // Contenido del header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Control de Producción',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Gestión de procesos y capacidad',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Card de Capacidad
              SliverToBoxAdapter(
                child: _buildCapacidadCard(),
              ),
              
              // Tabs
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    controller: _tabController,
                    indicatorColor: BioWayColors.ecoceGreen,
                    indicatorWeight: 3,
                    labelColor: BioWayColors.ecoceGreen,
                    unselectedLabelColor: Colors.grey,
                    labelStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                    ),
                    tabs: const [
                      Tab(text: 'En Proceso'),
                      Tab(text: 'Completados'),
                    ],
                  ),
                ),
              ),
              
              // Contenido de los tabs
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: _selectedTabIndex == 0
                        ? _lotesEnProceso.map((lote) => _buildLoteCard(lote)).toList()
                        : _lotesCompletados.map((lote) => _buildLoteCard(lote)).toList(),
                  ),
                ),
              ),
              
              // Espacio para el bottom nav
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
        
        // Bottom Navigation Bar
        bottomNavigationBar: EcoceBottomNavigation(
          selectedIndex: _selectedIndex,
          onItemTapped: _onBottomNavTapped,
          primaryColor: BioWayColors.ecoceGreen,
          items: EcoceNavigationConfigs.transformadorItems,
          fabConfig: FabConfig(
            icon: Icons.add,
            onPressed: _onAddPressed,
          ),
        ),
        
        // Floating Action Button
        floatingActionButton: EcoceFloatingActionButton(
          onPressed: _onAddPressed,
          icon: Icons.add,
          backgroundColor: BioWayColors.ecoceGreen,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }
}

// Delegate para el TabBar pegajoso
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height + 16;
  @override
  double get maxExtent => _tabBar.preferredSize.height + 16;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFFF5F5F5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        child: _tabBar,
      ),
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}