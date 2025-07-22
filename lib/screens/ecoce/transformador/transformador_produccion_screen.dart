import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import '../../../services/user_session_service.dart';
import '../../../models/ecoce/ecoce_profile_model.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import '../shared/utils/user_type_helper.dart';
import 'transformador_lote_detalle_screen.dart';

class TransformadorProduccionScreen extends StatefulWidget {
  final int? initialTab;
  
  const TransformadorProduccionScreen({super.key, this.initialTab});

  @override
  State<TransformadorProduccionScreen> createState() => _TransformadorProduccionScreenState();
}

class _TransformadorProduccionScreenState extends State<TransformadorProduccionScreen> 
    with SingleTickerProviderStateMixin {
  final UserSessionService _sessionService = UserSessionService();
  final int _selectedIndex = 1; // Producción está en índice 1
  late TabController _tabController;
  int _selectedTabIndex = 0;
  
  EcoceProfileModel? _userProfile;
  bool _isLoading = true;
  
  // Filtros
  String _selectedPolimero = 'Todos';
  String _selectedTiempo = 'Este Mes';
  List<String> _selectedProcesos = [];
  
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
      'tipoPolimero': 'Multilaminado',
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
      'tipoPolimero': 'PP',
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
      'tipoPolimero': 'PEBD',
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
      'tipoPolimero': 'PP',
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
      'tipoPolimero': 'PEBD',
      'tiposAnalisis': ['Soplado', 'Laminado'],
      'composicion': 'LDPE reciclado 90%, aditivos biodegradables 10%',
      'origen': 'ACOPIADOR MUNICIPAL',
      'comentarios': 'Producción ecológica con aditivos biodegradables',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2, 
      vsync: this,
      initialIndex: widget.initialTab ?? 0,
    );
    _selectedTabIndex = widget.initialTab ?? 0;
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
    _loadUserProfile();
  }
  
  Future<void> _loadUserProfile() async {
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onBottomNavTapped(int index) {
    UserTypeHelper.handleNavigation(
      context,
      _userProfile?.ecoceTipoActor,
      index,
      1, // Current index (producción)
    );
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
        builder: (context) => TransformadorLoteDetalleScreen(
          firebaseId: lote['id'],
          peso: lote['peso'].toDouble(),
          tiposAnalisis: lote['tiposAnalisis'] ?? ['Extrusión', 'Inyección'],
          productoFabricado: lote['producto'] ?? 'Producto no especificado',
          composicionMaterial: lote['composicion'] ?? 'Material reciclado procesado según estándares de calidad',
          fechaCreacion: DateTime.parse(lote['fechaISO'] ?? DateTime.now().toIso8601String()),
          procesosAplicados: lote['procesosAplicados'] ?? [],
          comentarios: lote['comentarios'],
          tipoPolimero: lote['tipoPolimero'],
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
                            // Segunda línea: Producto y tipo de polímero
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    lote['producto'] ?? 'Producto en proceso',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                if (lote['tipoPolimero'] != null) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurple.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.deepPurple.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.science_outlined,
                                          size: 12,
                                          color: Colors.deepPurple,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          lote['tipoPolimero'],
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.deepPurple,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
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
                // Botón de acción inferior - documentación para tab 0
                InkWell(
                  onTap: () {
                    if (_selectedTabIndex == 0) {
                      // En pestaña de Documentación, ir a ingresar documentación
                      Navigator.pushNamed(
                        context,
                        '/transformador_documentacion',
                        arguments: {
                          'loteId': lote['id'],
                          'material': lote['producto'],
                          'peso': lote['peso'],
                        },
                      );
                    } else {
                      // En completados, ver detalles
                      _verDetallesLote(lote);
                    }
                  },
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: (_selectedTabIndex == 0 ? BioWayColors.warning : Colors.green).withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _selectedTabIndex == 0 ? Icons.description : Icons.qr_code,
                          color: _selectedTabIndex == 0 ? BioWayColors.warning : Colors.green,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _selectedTabIndex == 0 ? 'Ingresar Documentación' : 'Ver Código QR',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _selectedTabIndex == 0 ? BioWayColors.warning : Colors.green,
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

  List<Map<String, dynamic>> get _lotesFiltrados {
    List<Map<String, dynamic>> lotes = _selectedTabIndex == 0 ? _lotesEnProceso : _lotesCompletados;
    
    return lotes.where((lote) {
      // Filtrar por polímero
      if (_selectedPolimero != 'Todos' && lote['tipoPolimero'] != _selectedPolimero) {
        return false;
      }
      
      // Filtrar por tiempo
      final fechaISO = DateTime.parse(lote['fechaISO']);
      final now = DateTime.now();
      switch (_selectedTiempo) {
        case 'Esta Semana':
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          if (!fechaISO.isAfter(weekStart)) return false;
          break;
        case 'Este Mes':
          if (fechaISO.month != now.month || fechaISO.year != now.year) return false;
          break;
        case 'Últimos tres meses':
          final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
          if (!fechaISO.isAfter(threeMonthsAgo)) return false;
          break;
        case 'Este Año':
          if (fechaISO.year != now.year) return false;
          break;
      }
      
      // Filtrar por procesos
      if (_selectedProcesos.isNotEmpty) {
        final procesosLote = List<String>.from(lote['procesosAplicados'] ?? []);
        // Verificar que el lote tenga al menos uno de los procesos seleccionados
        bool tieneProcesoSeleccionado = false;
        for (String proceso in _selectedProcesos) {
          if (procesosLote.contains(proceso)) {
            tieneProcesoSeleccionado = true;
            break;
          }
        }
        if (!tieneProcesoSeleccionado) return false;
      }
      
      return true;
    }).toList();
  }

  Map<String, dynamic> _getEstadisticas() {
    final lotesFiltrados = _lotesFiltrados;
    
    if (lotesFiltrados.isEmpty) {
      return {
        'total': 0,
        'pesoTotal': 0.0,
        'procesoMasComun': 'N/A',
      };
    }
    
    // Peso total
    double pesoTotal = 0.0;
    Map<String, int> conteoProcesos = {};
    
    for (var lote in lotesFiltrados) {
      pesoTotal += lote['peso'] as double;
      
      // Contar procesos
      List<String> procesos = List<String>.from(lote['procesosAplicados'] ?? []);
      for (String proceso in procesos) {
        conteoProcesos[proceso] = (conteoProcesos[proceso] ?? 0) + 1;
      }
    }
    
    // Proceso más común
    String procesoMasComun = 'N/A';
    if (conteoProcesos.isNotEmpty) {
      var entrada = conteoProcesos.entries.reduce((a, b) => a.value > b.value ? a : b);
      procesoMasComun = entrada.key;
    }
    
    return {
      'total': lotesFiltrados.length,
      'pesoTotal': pesoTotal,
      'procesoMasComun': procesoMasComun,
    };
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: SafeArea(
        child: Column(
          children: [
            // Header estático
            Container(
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
            
            // Tabs
            Container(
              color: const Color(0xFFF5F5F5),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                elevation: 2,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: _selectedTabIndex == 0 ? Colors.orange : BioWayColors.ecoceGreen,
                  indicatorWeight: 3,
                  labelColor: _selectedTabIndex == 0 ? Colors.orange : BioWayColors.ecoceGreen,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                  ),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text('Documentación'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text('Completados'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Contenido con TabBarView
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(),
                children: [
                  // Tab de Documentación
                  SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _buildFilterSection(),
                        _buildStatisticsCard(),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: _lotesFiltrados.isEmpty
                              ? _buildEmptyState()
                              : Column(
                                  children: [
                                    ..._lotesFiltrados.map((lote) => _buildLoteCard(lote)),
                                    const SizedBox(height: 100), // Espacio para el bottom nav
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                  // Tab de Completados
                  SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _buildFilterSection(),
                        _buildStatisticsCard(),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: _lotesFiltrados.isEmpty
                              ? _buildEmptyState()
                              : Column(
                                  children: [
                                    ..._lotesFiltrados.map((lote) => _buildLoteCard(lote)),
                                    const SizedBox(height: 100), // Espacio para el bottom nav
                                  ],
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

  Widget _buildFilterSection() {
    final bool isDocumentacion = _selectedTabIndex == 0;
    final Color activeColor = isDocumentacion ? Colors.orange : BioWayColors.ecoceGreen;
    
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Filtro de polímeros (chips horizontales scrollables)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Todos', 'PEBD', 'PP', 'Multilaminado'].map((polimero) {
                final isSelected = _selectedPolimero == polimero;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(polimero),
                    selected: isSelected,
                    selectedColor: activeColor.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? activeColor : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) {
                      setState(() {
                        _selectedPolimero = polimero;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          // Filtro de tiempo (fila completa)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButton<String>(
              value: _selectedTiempo,
              isExpanded: true,
              underline: const SizedBox(),
              icon: Icon(Icons.arrow_drop_down, color: isDocumentacion ? activeColor : null),
              items: ['Hoy', 'Esta Semana', 'Este Mes', 'Este Año']
                  .map((tiempo) => DropdownMenuItem(
                        value: tiempo,
                        child: Text(tiempo),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTiempo = value!;
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          // Filtro de procesos (fila completa)
          InkWell(
            onTap: _showProcesosFilterDialog,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _selectedProcesos.isNotEmpty
                    ? activeColor.withValues(alpha: 0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _selectedProcesos.isNotEmpty
                      ? activeColor
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    size: 20,
                    color: _selectedProcesos.isNotEmpty
                        ? activeColor
                        : Colors.grey.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedProcesos.isEmpty
                        ? 'Filtrar por procesos'
                        : '${_selectedProcesos.length} procesos seleccionados',
                    style: TextStyle(
                      color: _selectedProcesos.isNotEmpty
                          ? activeColor
                          : Colors.grey.shade700,
                      fontWeight: _selectedProcesos.isNotEmpty
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProcesosFilterDialog() {
    final bool isDocumentacion = _selectedTabIndex == 0;
    final Color activeColor = isDocumentacion ? Colors.orange : BioWayColors.ecoceGreen;
    
    final procesosList = [
      'Lavado',
      'Secado',
      'Trituración',
      'Extrusión',
      'Inyección',
      'Soplado',
      'Termoformado',
      'Laminado',
      'Rotomoldeo',
      'Clasificación',
      'Empaque'
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.filter_list, color: activeColor),
                  const SizedBox(width: 12),
                  const Text('Filtrar por Proceso'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: procesosList.map((proceso) {
                    final isSelected = _selectedProcesos.contains(proceso);
                    return CheckboxListTile(
                      title: Text(proceso),
                      value: isSelected,
                      activeColor: activeColor,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            _selectedProcesos.add(proceso);
                          } else {
                            _selectedProcesos.remove(proceso);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      _selectedProcesos.clear();
                    });
                  },
                  child: Text(
                    'Limpiar',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: activeColor,
                  ),
                  child: const Text('Aplicar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatisticsCard() {
    final estadisticas = _getEstadisticas();
    final bool isDocumentacion = _selectedTabIndex == 0;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDocumentacion ? Colors.orange : BioWayColors.ecoceGreen,
            isDocumentacion 
                ? Colors.orange.withValues(alpha: 0.8)
                : BioWayColors.ecoceGreen.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDocumentacion 
                ? Colors.orange.withValues(alpha: 0.3)
                : BioWayColors.ecoceGreen.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(
                'Estadísticas Filtradas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatisticItem(
                'Lotes',
                estadisticas['total'].toString(),
                Icons.inventory_2_outlined,
              ),
              _buildStatisticItem(
                'Peso Total',
                '${estadisticas['pesoTotal'].toStringAsFixed(1)} kg',
                Icons.scale_outlined,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatisticItem(
            'Proceso Más Común',
            estadisticas['procesoMasComun'],
            Icons.settings,
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_alt_off_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay lotes con los filtros seleccionados',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta ajustar los filtros',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}