import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../utils/colors.dart';
import '../../../utils/format_utils.dart';
import '../../../services/user_session_service.dart';
import '../../../services/lote_service.dart';
import '../../../models/ecoce/ecoce_profile_model.dart';
import '../../../models/lotes/lote_transformador_model.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import '../shared/widgets/unified_stat_card.dart';
import '../shared/utils/material_utils.dart';
import '../shared/utils/user_type_helper.dart';
import 'transformador_lote_detalle_screen.dart';
import '../shared/screens/usuario_qr_screen.dart';
import '../shared/screens/receptor_recepcion_pasos_screen.dart';

class TransformadorInicioScreen extends StatefulWidget {
  const TransformadorInicioScreen({super.key});

  @override
  State<TransformadorInicioScreen> createState() => _TransformadorInicioScreenState();
}

class _TransformadorInicioScreenState extends State<TransformadorInicioScreen> {
  final UserSessionService _sessionService = UserSessionService();
  final LoteService _loteService = LoteService();
  final int _selectedIndex = 0;
  
  EcoceProfileModel? _userProfile;
  bool _isLoading = true;
  
  // Estadísticas del transformador
  int _lotesRecibidos = 0;
  int _productosCreados = 0;
  double _materialProcesado = 0.0; // en toneladas
  
  // Stream para lotes
  Stream<List<LoteTransformadorModel>>? _lotesStream;

  void _navigateToRecibirLotes() {
    HapticFeedback.lightImpact();
    // Usar el flujo de recepción por pasos igual que el reciclador
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ReceptorRecepcionPasosScreen(
          userType: 'transformador',
        ),
      ),
    );
  }

  void _navigateToDocumentacion() {
    HapticFeedback.lightImpact();
    // Navegar a la pantalla de producción con la pestaña de documentación seleccionada (tab 0)
    Navigator.pushReplacementNamed(
      context, 
      '/transformador_produccion',
      arguments: {'initialTab': 0},
    );
  }
  

  void _actualizarDocumentacion(String loteId, LoteTransformadorModel lote) {
    HapticFeedback.lightImpact();
    
    Navigator.pushNamed(
      context,
      '/transformador_documentacion',
      arguments: {
        'loteId': loteId,
        'material': lote.productoFabricado ?? 'Sin especificar',
        'peso': lote.pesoIngreso ?? 0.0,
      },
    );
  }

  void _onBottomNavTapped(int index) {
    UserTypeHelper.handleNavigation(
      context,
      _userProfile?.ecoceTipoActor,
      index,
      0, // Current index (inicio)
    );
  }

  void _onAddPressed() {
    HapticFeedback.lightImpact();
    // Usar el flujo de recepción por pasos igual que el reciclador
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ReceptorRecepcionPasosScreen(
          userType: 'transformador',
        ),
      ),
    );
  }

  void _navigateToLoteDetalle(LoteTransformadorModel lote) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransformadorLoteDetalleScreen(
          firebaseId: lote.id!,
          peso: lote.pesoIngreso ?? 0.0,
          tiposAnalisis: lote.tiposAnalisis ?? ['Extrusión', 'Inyección'],
          productoFabricado: lote.productoFabricado ?? 'Producto no especificado',
          composicionMaterial: lote.composicionMaterial ?? 'Material reciclado procesado según estándares de calidad',
          fechaCreacion: lote.fechaCreacion ?? DateTime.now(),
          procesosAplicados: lote.procesosAplicados ?? [],
          comentarios: lote.comentarios,
          tipoPolimero: lote.tipoPolimero ?? 'Sin especificar',
        ),
      ),
    );
  }

  // Convertir modelo a Map para el widget
  Map<String, dynamic> _loteToMap(LoteTransformadorModel lote) {
    // Determinar el material predominante
    String material = 'Sin especificar';
    if (lote.tipoPolimero != null && lote.tipoPolimero!.isNotEmpty) {
      material = lote.tipoPolimero!;
    }
    
    return {
      'id': lote.id,
      'origen': lote.proveedor ?? 'Sin origen',
      'material': material,
      'tipoPolimero': lote.tipoPolimero,
      'fecha': FormatUtils.formatDate(lote.fechaCreacion ?? DateTime.now()),
      'peso': lote.pesoIngreso ?? 0.0,
      'estado': _getEstadoDisplay(lote.estado ?? 'recibido'),
      'estadoColor': _getEstadoColor(lote.estado ?? 'recibido'),
      'producto': lote.productoFabricado,
      'tiposAnalisis': lote.tiposAnalisis,
      'composicion': lote.composicionMaterial,
      'comentarios': lote.comentarios,
      'procesosAplicados': lote.procesosAplicados,
    };
  }
  
  String _getEstadoDisplay(String estado) {
    switch (estado) {
      case 'recibido':
        return 'RECIBIDO';
      case 'procesando':
        return 'PROCESANDO';
      case 'documentacion':
        return 'DOCUMENTACIÓN';
      case 'finalizado':
        return 'FINALIZADO';
      default:
        return estado.toUpperCase();
    }
  }
  
  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'recibido':
        return Colors.blue;
      case 'procesando':
        return Colors.orange;
      case 'documentacion':
        return BioWayColors.warning;
      case 'finalizado':
        return BioWayColors.success;
      default:
        return Colors.grey;
    }
  }
  
  Widget _buildLoteCardFromModel(LoteTransformadorModel lote) {
    final loteMap = _loteToMap(lote);
    return _buildLoteCard(loteMap, lote);
  }

  Widget _buildLoteCard(Map<String, dynamic> lote, [LoteTransformadorModel? loteModel]) {
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
            if (loteModel != null) {
              _navigateToLoteDetalle(loteModel);
            }
          },
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
                          materialColor.withValues(alpha: 0.2),
                          materialColor.withValues(alpha: 0.1),
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
                            if (lote['tipoPolimero'] != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isCompact ? 6 : 8,
                                  vertical: isCompact ? 2 : 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  lote['tipoPolimero'],
                                  style: TextStyle(
                                    fontSize: isCompact ? 10 : 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Segunda línea: Origen y Producto
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
                        // Tercera línea: Chips informativos
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
                              Icons.calendar_today_outlined,
                              lote['fecha'] ?? '',
                              Colors.orange,
                              isCompact,
                            ),
                            if (lote['producto'] != null)
                              _buildProductChip(
                                lote['producto'],
                                _getProductoColor(lote['producto']),
                                isCompact,
                              ),
                            if (lote['estado'] != null)
                              _buildStatusChip(
                                lote['estado'],
                                lote['estadoColor'] ?? Colors.blue,
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
                      color: BioWayColors.ecoceGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          if (loteModel != null) {
                            _actualizarDocumentacion(lote['id'], loteModel);
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: EdgeInsets.all(isCompact ? 8 : 10),
                          child: Icon(
                            Icons.description,
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
        color: color.withValues(alpha: 0.1),
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

  Widget _buildProductChip(String product, Color color, bool isCompact) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8, 
        vertical: isCompact ? 3 : 4
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_2,
            size: isCompact ? 11 : 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              product,
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
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

  Color _getProductoColor(String producto) {
    // Asignar colores basados en el tipo de producto
    if (producto.toLowerCase().contains('pet') || producto.toLowerCase().contains('envase')) {
      return Colors.indigo;
    } else if (producto.toLowerCase().contains('ldpe') || producto.toLowerCase().contains('lámina')) {
      return Colors.teal;
    } else if (producto.toLowerCase().contains('hdpe') || producto.toLowerCase().contains('botella')) {
      return Colors.blue;
    } else if (producto.toLowerCase().contains('pp') || producto.toLowerCase().contains('polipropileno')) {
      return Colors.purple;
    } else if (producto.toLowerCase().contains('ps') || producto.toLowerCase().contains('poliestireno')) {
      return Colors.orange;
    } else {
      return BioWayColors.ecoceGreen;
    }
  }

  IconData _getProductoIcon(String producto) {
    // Asignar iconos basados en el tipo de producto
    if (producto.toLowerCase().contains('envase') || producto.toLowerCase().contains('botella')) {
      return Icons.local_drink;
    } else if (producto.toLowerCase().contains('lámina') || producto.toLowerCase().contains('hoja')) {
      return Icons.layers;
    } else if (producto.toLowerCase().contains('tubo') || producto.toLowerCase().contains('tubería')) {
      return Icons.view_column;
    } else if (producto.toLowerCase().contains('contenedor') || producto.toLowerCase().contains('caja')) {
      return Icons.inventory_2;
    } else if (producto.toLowerCase().contains('película') || producto.toLowerCase().contains('film')) {
      return Icons.wrap_text;
    } else {
      return Icons.recycling;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _setupLotesStream();
    _loadStatistics();
  }
  
  void _setupLotesStream() {
    _lotesStream = _loteService.getLotesTransformador();
  }
  
  Future<void> _loadStatistics() async {
    try {
      // Obtener todos los lotes del transformador
      final lotes = await _loteService.getLotesTransformador().first;
      
      if (mounted) {
        setState(() {
          _lotesRecibidos = lotes.length;
          _productosCreados = lotes.where((l) => l.estado == 'finalizado').length;
          // Convertir de kg a toneladas
          _materialProcesado = lotes.fold(0.0, (sum, lote) => sum + (lote.pesoIngreso ?? 0)) / 1000;
        });
      }
    } catch (e) {
      debugPrint('Error cargando estadísticas: $e');
    }
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

  String get _nombreEmpresa {
    return _userProfile?.ecoceNombre ?? 'Transformador';
  }

  String get _folioTransformador {
    return _userProfile?.ecoceFolio ?? 'T0000000';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header moderno con gradiente (estilo reciclador)
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
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
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
                          // Nombre de la empresa
                          Text(
                            _nombreEmpresa,
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
                                      Icons.factory,
                                      size: 16,
                                      color: BioWayColors.ecoceGreen,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Transformador',
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
                                  _folioTransformador,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Primera fila de estadísticas
                          Row(
                            children: [
                              // Card de Lotes Recibidos
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
                              // Card de Productos Creados
                              Expanded(
                                child: UnifiedStatCard.horizontal(
                                  title: 'Productos creados',
                                  value: _productosCreados.toString(),
                                  icon: Icons.add_box,
                                  color: BioWayColors.ppPurple,
                                  height: 70,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Segunda fila con Material Procesado centrado
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Card de Material Procesado centrada
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.45,
                                child: UnifiedStatCard.horizontal(
                                  title: 'Material procesado',
                                  value: '$_materialProcesado',
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
                        
                      // Acción rápida principal (estilo reciclador)
                      Container(
                        width: double.infinity,
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              BioWayColors.ecoceGreen,
                              BioWayColors.ecoceGreen.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: BioWayColors.ecoceGreen.withValues(alpha: 0.3),
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
                            onTap: _navigateToRecibirLotes,
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
                                          'Recibir Lotes',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          'Escanear lote entrante',
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
                      
                      const SizedBox(height: 16),
                      
                      // Botón secundario de documentación (más sutil)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: _navigateToDocumentacion,
                          icon: Icon(
                            Icons.description_outlined,
                            color: BioWayColors.ecoceGreen,
                          ),
                          label: const Text(
                            'Gestionar Documentación',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: BioWayColors.ecoceGreen,
                            side: BorderSide(
                              color: BioWayColors.ecoceGreen.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                        
                        const SizedBox(height: 24),
                        
                        // Sección Lotes en Proceso
                        const Text(
                          'Lotes en Proceso',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Lista de lotes con StreamBuilder
                        StreamBuilder<List<LoteTransformadorModel>>(
                          stream: _lotesStream,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 40),
                                  child: CircularProgressIndicator(
                                    color: BioWayColors.ecoceGreen,
                                  ),
                                ),
                              );
                            }
                            
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 40),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.inbox_outlined,
                                        size: 64,
                                        color: Colors.grey[300],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No hay lotes en proceso',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Escanea un código QR para comenzar',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            
                            final lotes = snapshot.data!;
                            return Column(
                              children: lotes.map((lote) => _buildLoteCardFromModel(lote)).toList(),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 100), // Espacio para el bottom nav
                      ],
                    ),
                  ),
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
}