import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/colors.dart';
import '../../../utils/format_utils.dart';
import '../../../utils/qr_utils.dart';
import '../../../services/lote_unificado_service.dart';
import '../../../models/lotes/lote_unificado_model.dart';
import '../shared/widgets/shared_qr_scanner_screen.dart';
import 'lote_trazabilidad_screen.dart';

/// Pantalla principal del repositorio con diseño moderno y profesional
class RepositorioInicioScreen extends StatefulWidget {
  const RepositorioInicioScreen({super.key});

  @override
  State<RepositorioInicioScreen> createState() => _RepositorioInicioScreenState();
}

class _RepositorioInicioScreenState extends State<RepositorioInicioScreen> 
    with TickerProviderStateMixin {
  final LoteUnificadoService _loteService = LoteUnificadoService();
  final TextEditingController _searchController = TextEditingController();
  
  // Estados
  Stream<List<LoteUnificadoModel>>? _lotesStream;
  String _selectedFilter = 'todos';
  String _searchQuery = '';
  
  // Animaciones
  late AnimationController _headerController;
  late AnimationController _filterController;
  late Animation<double> _headerAnimation;
  late Animation<double> _filterAnimation;
  
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadLotes();
  }
  
  void _setupAnimations() {
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _filterController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _headerAnimation = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutCubic,
    );
    _filterAnimation = CurvedAnimation(
      parent: _filterController,
      curve: Curves.easeOutCubic,
    );
    
    _headerController.forward();
    _filterController.forward();
  }
  
  void _loadLotes() {
    setState(() {
      _lotesStream = _loteService.obtenerTodosLosLotes();
    });
  }
  
  void _filterLotes() {
    setState(() {
      _lotesStream = _loteService.buscarLotes(
        query: _searchQuery.isEmpty ? null : _searchQuery,
        proceso: _selectedFilter == 'todos' ? null : _selectedFilter,
      );
    });
  }
  
  
  void _scanQR() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const SharedQRScannerScreen(),
      ),
    );
    
    if (result != null && mounted) {
      // Extraer el ID del lote usando la utilidad
      final loteId = QRUtils.extractLoteIdFromQR(result);
      _navigateToDetail(loteId);
    }
  }
  
  void _navigateToDetail(String loteId) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            LoteTrazabilidadScreen(loteId: loteId),
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
      ),
    );
  }
  
  void _handleLogout() async {
    HapticFeedback.lightImpact();
    
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas salir del repositorio?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: BioWayColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    
    if (shouldLogout == true && mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // App Bar personalizado
          _buildSliverAppBar(),
          
          // Barra de búsqueda y filtros
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _filterAnimation,
              child: _buildSearchAndFilters(),
            ),
          ),
          
          // Lista de lotes
          _buildLotesList(),
        ],
      ),
    );
  }
  
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: BioWayColors.primaryGreen,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Repositorio de Lotes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                BioWayColors.primaryGreen,
                BioWayColors.primaryGreen.withOpacity(0.8),
                BioWayColors.mediumGreen,
              ],
            ),
          ),
          child: Stack(
            children: [
              // Patrón de fondo sutil
              Positioned(
                right: -30,
                bottom: -20,
                child: Icon(
                  Icons.inventory_2,
                  size: 120,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: _handleLogout,
          tooltip: 'Cerrar Sesión',
        ),
      ],
    );
  }
  
  
  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        children: [
          // Barra de búsqueda
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _filterLotes();
              },
              decoration: InputDecoration(
                hintText: 'Buscar por ID, material o usuario...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[600]),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                          _filterLotes();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Filtros
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip(
                  label: 'Todos',
                  value: 'todos',
                  icon: Icons.all_inclusive,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Origen',
                  value: 'origen',
                  icon: Icons.source,
                  color: const Color(0xFF2E7D32),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Transporte',
                  value: 'transporte',
                  icon: Icons.local_shipping,
                  color: const Color(0xFF1976D2),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Reciclador',
                  value: 'reciclador',
                  icon: Icons.recycling,
                  color: const Color(0xFF388E3C),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Laboratorio',
                  value: 'laboratorio',
                  icon: Icons.science,
                  color: const Color(0xFF7B1FA2),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Transformador',
                  value: 'transformador',
                  icon: Icons.precision_manufacturing,
                  color: const Color(0xFFD32F2F),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChip({
    required String label,
    required String value,
    required IconData icon,
    Color? color,
  }) {
    final isSelected = _selectedFilter == value;
    final chipColor = color ?? BioWayColors.primaryGreen;
    
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : chipColor,
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedFilter = value;
        });
        _filterLotes();
      },
      selectedColor: chipColor,
      backgroundColor: Colors.white,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : chipColor,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? chipColor : Colors.grey[300]!,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    );
  }
  
  Widget _buildLotesList() {
    return StreamBuilder<List<LoteUnificadoModel>>(
      stream: _lotesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.hasError) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar lotes',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _loadLotes,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }
        
        final lotes = snapshot.data ?? [];
        
        if (lotes.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No se encontraron lotes',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (_selectedFilter != 'todos' || _searchController.text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedFilter = 'todos';
                          _searchController.clear();
                          _searchQuery = '';
                        });
                        _loadLotes();
                      },
                      child: const Text('Limpiar filtros'),
                    ),
                  ],
                ],
              ),
            ),
          );
        }
        
        return SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final lote = lotes[index];
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 300 + (index * 50)),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: _buildLoteCard(lote),
                );
              },
              childCount: lotes.length,
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildLoteCard(LoteUnificadoModel lote) {
    final proceso = lote.datosGenerales.procesoActual;
    final color = _getProcesoColor(proceso);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 0,
        child: InkWell(
          onTap: () => _navigateToDetail(lote.id),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                // Header con gradiente
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.1),
                        color.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Ícono del proceso
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getProcesoIcon(proceso),
                          color: color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // ID y QR
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.qr_code_2,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'ID: ${lote.id.substring(0, 8).toUpperCase()}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getProcesoLabel(proceso),
                              style: TextStyle(
                                fontSize: 12,
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
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
                          color: color,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'ACTIVO',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Contenido
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Información principal
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoItem(
                              icon: Icons.category,
                              label: 'Material',
                              value: lote.datosGenerales.tipoMaterial,
                              color: _getMaterialColor(lote.datosGenerales.tipoMaterial),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildInfoItem(
                              icon: Icons.scale,
                              label: 'Peso',
                              value: '${lote.datosGenerales.peso.toStringAsFixed(1)} kg',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Información secundaria
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoItem(
                              icon: Icons.calendar_today,
                              label: 'Creado',
                              value: FormatUtils.formatDate(lote.datosGenerales.fechaCreacion),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildInfoItem(
                              icon: Icons.person,
                              label: 'Usuario',
                              value: _getUsuarioActual(lote),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      // Timeline preview
                      if (lote.datosGenerales.historialProcesos.length > 1) ...[
                        const SizedBox(height: 16),
                        _buildTimelinePreview(lote),
                      ],
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
  
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
    double fontSize = 14,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: color ?? Colors.grey[800],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildTimelinePreview(LoteUnificadoModel lote) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timeline,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: lote.datosGenerales.historialProcesos.map((proceso) {
                  final isLast = proceso == lote.datosGenerales.historialProcesos.last;
                  final isCurrent = proceso == lote.datosGenerales.procesoActual;
                  
                  return Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isCurrent 
                              ? _getProcesoColor(proceso)
                              : _getProcesoColor(proceso).withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getProcesoIcon(proceso),
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 24,
                          height: 2,
                          color: Colors.grey[300],
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: Colors.grey[400],
          ),
        ],
      ),
    );
  }
  
  String _getUsuarioActual(LoteUnificadoModel lote) {
    switch (lote.datosGenerales.procesoActual) {
      case 'origen':
        return lote.origen?.usuarioFolio ?? 'N/A';
      case 'transporte':
        return lote.transporte?.usuarioFolio ?? 'N/A';
      case 'reciclador':
        return lote.reciclador?.usuarioFolio ?? 'N/A';
      case 'laboratorio':
        return lote.analisisLaboratorio.isNotEmpty 
            ? lote.analisisLaboratorio.first.usuarioFolio 
            : 'N/A';
      case 'transformador':
        return lote.transformador?.usuarioFolio ?? 'N/A';
      default:
        return 'N/A';
    }
  }
  
  Color _getProcesoColor(String proceso) {
    switch (proceso) {
      case 'origen':
        return const Color(0xFF2E7D32);
      case 'transporte':
        return const Color(0xFF1976D2);
      case 'reciclador':
        return const Color(0xFF388E3C);
      case 'laboratorio':
        return const Color(0xFF7B1FA2);
      case 'transformador':
        return const Color(0xFFD32F2F);
      default:
        return Colors.grey;
    }
  }
  
  IconData _getProcesoIcon(String proceso) {
    switch (proceso) {
      case 'origen':
        return Icons.source;
      case 'transporte':
        return Icons.local_shipping;
      case 'reciclador':
        return Icons.recycling;
      case 'laboratorio':
        return Icons.science;
      case 'transformador':
        return Icons.precision_manufacturing;
      default:
        return Icons.circle;
    }
  }
  
  String _getProcesoLabel(String proceso) {
    switch (proceso) {
      case 'origen':
        return 'Origen';
      case 'transporte':
        return 'Transporte';
      case 'reciclador':
        return 'Reciclador';
      case 'laboratorio':
        return 'Laboratorio';
      case 'transformador':
        return 'Transformador';
      default:
        return proceso;
    }
  }
  
  Color _getMaterialColor(String material) {
    if (material.toLowerCase().contains('pebd')) {
      return BioWayColors.pebdPink;
    } else if (material.toLowerCase().contains('pp')) {
      return BioWayColors.ppPurple;
    } else if (material.toLowerCase().contains('multilaminado')) {
      return BioWayColors.multilaminadoBrown;
    }
    return Colors.grey;
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _headerController.dispose();
    _filterController.dispose();
    super.dispose();
  }
}