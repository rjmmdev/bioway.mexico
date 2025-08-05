import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../utils/colors.dart';
import '../../../utils/format_utils.dart';
import '../../../utils/ui_constants.dart';
import '../../../services/user_session_service.dart';
import '../../../services/lote_service.dart';
import '../../../services/lote_unificado_service.dart';
import '../../../models/ecoce/ecoce_profile_model.dart';
import '../../../models/lotes/lote_transformador_model.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import '../shared/widgets/unified_stat_card.dart';
import '../shared/utils/material_utils.dart';
import '../shared/utils/user_type_helper.dart';
import 'transformador_lote_detalle_screen.dart';
import '../shared/screens/usuario_qr_screen.dart';
import '../shared/screens/receptor_recepcion_pasos_screen.dart';
import 'utils/transformador_navigation_helper.dart';
import 'transformador_main_screen.dart';

class TransformadorInicioScreen extends StatefulWidget {
  const TransformadorInicioScreen({super.key});

  @override
  State<TransformadorInicioScreen> createState() => _TransformadorInicioScreenState();
}

class _TransformadorInicioScreenState extends State<TransformadorInicioScreen> {
  final UserSessionService _sessionService = UserSessionService();
  final LoteService _loteService = LoteService();
  final LoteUnificadoService _loteUnificadoService = LoteUnificadoService();
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
    // Navegar a la pantalla de producción con la pestaña de documentación seleccionada
    TransformadorNavigationHelper.navigateToDocumentation(context, replacement: true);
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
    if (index == 0) return; // Ya estamos en inicio
    
    // Usar navegación optimizada para mantener estado
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => TransformadorMainScreen(
          initialIndex: index,
        ),
        transitionDuration: Duration.zero, // Sin animación para mayor fluidez
        reverseTransitionDuration: Duration.zero,
      ),
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
      margin: EdgeInsets.only(bottom: UIConstants.spacing12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            if (loteModel != null) {
              _navigateToLoteDetalle(loteModel);
            }
          },
          borderRadius: BorderRadiusConstants.borderRadiusMedium,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadiusConstants.borderRadiusMedium,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: UIConstants.opacityVeryLow + 0.01),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(isCompact ? UIConstants.spacing12 : UIConstants.spacing16),
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
                          materialColor.withValues(alpha: UIConstants.opacityMedium),
                          materialColor.withValues(alpha: UIConstants.opacityLow),
                        ],
                      ),
                      borderRadius: BorderRadiusConstants.borderRadiusMedium,
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
                                horizontal: isCompact ? UIConstants.spacing4 + 2 : UIConstants.spacing8,
                                vertical: isCompact ? UIConstants.spacing4 / 2 : UIConstants.spacing4 - 1,
                              ),
                              decoration: BoxDecoration(
                                color: materialColor,
                                borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
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
                            if (lote['tipoPolimero'] != null) ...[
                              SizedBox(width: UIConstants.spacing8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isCompact ? UIConstants.spacing4 + 2 : UIConstants.spacing8,
                                  vertical: isCompact ? UIConstants.spacing4 / 2 : UIConstants.spacing4 - 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.withValues(alpha: UIConstants.opacityLow),
                                  borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
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
                        SizedBox(height: UIConstants.spacing4 + 2),
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
                        SizedBox(height: UIConstants.spacing4),
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
                      color: Colors.orange,
                      borderRadius: BorderRadiusConstants.borderRadiusSmall,
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
                        borderRadius: BorderRadiusConstants.borderRadiusSmall,
                        child: Container(
                          padding: EdgeInsets.all(isCompact ? UIConstants.spacing8 : UIConstants.spacing8 + 2),
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
        horizontal: isCompact ? UIConstants.spacing4 + 2 : UIConstants.spacing8, 
        vertical: isCompact ? UIConstants.spacing4 - 1 : UIConstants.spacing4
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: UIConstants.opacityLow),
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

  Widget _buildProductChip(String product, Color color, bool isCompact) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? UIConstants.spacing4 + 2 : UIConstants.spacing8, 
        vertical: isCompact ? UIConstants.spacing4 - 1 : UIConstants.spacing4
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: UIConstants.opacityLow),
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
          SizedBox(width: UIConstants.spacing4),
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
        color: color.withValues(alpha: UIConstants.opacityLow),
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
      return Colors.orange;
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
      // Obtener estadísticas usando el servicio unificado
      final stats = await _loteUnificadoService.obtenerEstadisticasTransformador();
      
      if (mounted) {
        setState(() {
          _lotesRecibidos = stats['lotesRecibidos'] ?? 0;
          _productosCreados = stats['productosCreados'] ?? 0;
          _materialProcesado = stats['materialProcesado'] ?? 0.0; // Ya viene en toneladas
        });
      }
      
      debugPrint('Estadísticas cargadas - Lotes: $_lotesRecibidos, Productos: $_productosCreados, Material: $_materialProcesado t');
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
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: SafeArea(
          child: CustomScrollView(
          slivers: [
            // Header moderno con gradiente (estilo reciclador)
            SliverToBoxAdapter(
              child: Container(
                height: UIConstants.headerHeightWithStats,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.orange,
                      Colors.orange.withValues(alpha: UIConstants.opacityVeryHigh),
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
                          color: Colors.white.withValues(alpha: UIConstants.opacityLow),
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
                          color: Colors.white.withValues(alpha: UIConstants.opacityVeryLow),
                        ),
                      ),
                    ),
                    // Contenido
                    Padding(
                      padding: EdgeInsets.fromLTRB(UIConstants.spacing20, UIConstants.spacing12, UIConstants.spacing20, UIConstants.spacing16),
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
                                  vertical: UIConstants.spacing4 + 2, // 6
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: UIConstants.opacityMediumLow),
                                  borderRadius: BorderRadiusConstants.borderRadiusXLarge,
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
                                        fontSize: UIConstants.fontSizeSmall,
                                        color: Colors.white.withValues(alpha: UIConstants.opacityAlmostFull),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: UIConstants.spacing8),
                          // Nombre de la empresa
                          Text(
                            _nombreEmpresa,
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
                                      Icons.factory,
                                      size: 16,
                                      color: Colors.orange,
                                    ),
                                    SizedBox(width: UIConstants.spacing4 + 2),
                                    Text(
                                      'Transformador',
                                      style: TextStyle(
                                        fontSize: UIConstants.fontSizeSmall + 1,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange,
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
                                  color: Colors.orange,
                                  borderRadius: BorderRadiusConstants.borderRadiusLarge,
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
                          SizedBox(height: UIConstants.spacing8 + 2),
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
                                  height: UIConstants.statCardHeight,
                                ),
                              ),
                              SizedBox(width: UIConstants.spacing12),
                              // Card de Productos Creados
                              Expanded(
                                child: UnifiedStatCard.horizontal(
                                  title: 'Productos creados',
                                  value: _productosCreados.toString(),
                                  icon: Icons.add_box,
                                  color: BioWayColors.ppPurple,
                                  height: UIConstants.statCardHeight,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: UIConstants.spacing8 + 2),
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
                                  color: Colors.orange,
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
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(UIConstants.spacing16, UIConstants.spacing20, UIConstants.spacing16, UIConstants.spacing20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        
                      // Acción rápida principal (estilo reciclador)
                      Container(
                        width: double.infinity,
                        height: UIConstants.buttonHeightLarge,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.orange,
                              Colors.orange.withValues(alpha: UIConstants.opacityVeryHigh),
                            ],
                          ),
                          borderRadius: BorderRadiusConstants.borderRadiusLarge,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withValues(alpha: UIConstants.opacityMedium),
                              blurRadius: UIConstants.elevationXHigh,
                              offset: Offset(0, UIConstants.spacing4 + 2), // 6
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadiusConstants.borderRadiusMedium,
                          child: InkWell(
                            borderRadius: BorderRadiusConstants.borderRadiusMedium,
                            onTap: _navigateToRecibirLotes,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: UIConstants.spacing16, vertical: UIConstants.spacing12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: UIConstants.opacityMedium),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.qr_code_scanner,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  SizedBox(width: UIConstants.spacing16),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Recibir Lotes',
                                          style: TextStyle(
                                            fontSize: UIConstants.fontSizeBody,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          'Escanear lote entrante',
                                          style: TextStyle(
                                            fontSize: UIConstants.fontSizeSmall + 1,
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
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: UIConstants.spacing16),
                      
                      // Botón secundario de documentación (más sutil)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: _navigateToDocumentacion,
                          icon: Icon(
                            Icons.description_outlined,
                            color: Colors.orange,
                          ),
                          label: const Text(
                            'Gestionar Documentación',
                            style: TextStyle(
                              fontSize: UIConstants.fontSizeMedium,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            side: BorderSide(
                              color: Colors.orange.withValues(alpha: UIConstants.opacityMediumLow),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadiusConstants.borderRadiusMedium,
                            ),
                          ),
                        ),
                      ),
                        
                        SizedBox(height: UIConstants.spacing24),
                        
                        // Sección Lotes en Proceso
                        const Text(
                          'Lotes en Proceso',
                          style: TextStyle(
                            fontSize: UIConstants.fontSizeLarge,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: UIConstants.spacing16),
                        
                        // Lista de lotes con StreamBuilder
                        StreamBuilder<List<LoteTransformadorModel>>(
                          stream: _lotesStream,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: UIConstants.spacing40),
                                  child: CircularProgressIndicator(
                                    color: Colors.orange,
                                  ),
                                ),
                              );
                            }
                            
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: UIConstants.spacing40),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.inbox_outlined,
                                        size: 64,
                                        color: Colors.grey[300],
                                      ),
                                      SizedBox(height: UIConstants.spacing16),
                                      Text(
                                        'No hay lotes en proceso',
                                        style: TextStyle(
                                          fontSize: UIConstants.fontSizeBody,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      SizedBox(height: UIConstants.spacing8),
                                      Text(
                                        'Escanea un código QR para comenzar',
                                        style: TextStyle(
                                          fontSize: UIConstants.fontSizeMedium,
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
                        
                        SizedBox(height: UIConstants.spacing20), // Espacio al final
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        ),
      ),
    );
  }
}