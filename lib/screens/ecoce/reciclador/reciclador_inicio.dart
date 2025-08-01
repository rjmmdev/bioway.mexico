import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../utils/colors.dart';
import '../../../utils/format_utils.dart';
import '../../../services/user_session_service.dart';
import '../../../services/lote_service.dart';
import '../../../services/lote_unificado_service.dart';
import '../../../services/transformacion_service.dart';
import '../../../models/ecoce/ecoce_profile_model.dart';
import '../../../models/lotes/lote_reciclador_model.dart';
import '../../../models/lotes/lote_unificado_model.dart';
import '../../../models/lotes/transformacion_model.dart';
import 'reciclador_formulario_salida.dart';
import 'reciclador_documentacion.dart';
import 'reciclador_lote_qr_screen.dart';
import 'reciclador_administracion_lotes.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import '../shared/widgets/unified_stat_card.dart';
import 'widgets/reciclador_lote_card.dart';
import '../shared/screens/receptor_recepcion_pasos_screen.dart';

class RecicladorInicio extends StatefulWidget {
  const RecicladorInicio({super.key});

  @override
  State<RecicladorInicio> createState() => _RecicladorInicioState();
}

class _RecicladorInicioState extends State<RecicladorInicio> with WidgetsBindingObserver {
  final UserSessionService _sessionService = UserSessionService();
  final LoteService _loteService = LoteService();
  final LoteUnificadoService _loteUnificadoService = LoteUnificadoService();
  final TransformacionService _transformacionService = TransformacionService();
  
  EcoceProfileModel? _userProfile;
  
  // Índice para la navegación del bottom bar
  final int _selectedIndex = 0;

  // Estadísticas reales (valores iniciales)
  int _lotesRecibidos = 0;
  int _megalotesCreados = 0;
  double _materialProcesado = 0.0; // en kg
  
  // Stream para lotes
  Stream<List<LoteRecicladorModel>>? _lotesStream;
  Stream<List<dynamic>>? _lotesUnificadosStream;
  Stream<List<TransformacionModel>>? _transformacionesStream;
  
  // Stream para estadísticas
  Stream<Map<String, dynamic>>? _estadisticasStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserProfile();
    _setupStreams();
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
      // Error ya manejado
    }
  }
  
  void _setupStreams() {
    _lotesStream = _loteService.getLotesReciclador();
    _lotesUnificadosStream = _loteUnificadoService.obtenerLotesRecicladorConPendientes();
    _transformacionesStream = _transformacionService.obtenerTransformacionesUsuario();
    _estadisticasStream = _loteUnificadoService.streamEstadisticasReciclador();
    
    // Cargar estadísticas iniciales
    _loadInitialStatistics();
  }
  
  Future<void> _loadInitialStatistics() async {
    try {
      print('=== CARGANDO ESTADÍSTICAS INICIALES RECICLADOR ===');
      
      // Obtener estadísticas del perfil del usuario (contador acumulativo)
      final userProfile = await _sessionService.getUserProfile();
      final lotesRecibidosTotal = userProfile?['estadisticas']?['lotes_recibidos'] ?? 
                                  userProfile?['ecoce_lotes_totales_recibidos'] ?? 0;
      
      // Obtener otras estadísticas del servicio
      final stats = await _loteUnificadoService.obtenerEstadisticasReciclador();
      print('Estadísticas obtenidas: $stats');
      print('Lotes recibidos del perfil: $lotesRecibidosTotal');
      
      if (mounted) {
        setState(() {
          _lotesRecibidos = lotesRecibidosTotal; // Usar el contador del perfil
          _megalotesCreados = stats['megalotesCreados'] ?? 0;
          _materialProcesado = stats['materialProcesado'] ?? 0.0;
        });
        print('Estado actualizado - Lotes: $_lotesRecibidos, Megalotes: $_megalotesCreados, Material: $_materialProcesado');
      }
    } catch (e) {
      print('ERROR cargando estadísticas: $e');
      // Error ya manejado con valores por defecto
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
  
  // Convertir lote unificado a Map
  Map<String, dynamic> _loteUnificadoToMap(LoteUnificadoModel lote) {
    final reciclador = lote.reciclador;
    
    // Determinar el estado basado en los datos del lote
    String estado = 'recibido';
    bool tieneDocumentacion = false;
    
    if (lote.datosGenerales.procesoActual != 'reciclador') {
      estado = 'finalizado';
    } else if (reciclador?.fechaSalida != null) {
      // Verificar si tiene documentación
      if (reciclador!.evidenciasFoto.isNotEmpty) {
        estado = 'finalizado';
        tieneDocumentacion = true;
      } else {
        estado = 'enviado'; // Procesado pero sin documentación
      }
    }
    
    return {
      'id': lote.id,
      'fecha': FormatUtils.formatDate(reciclador?.fechaEntrada ?? lote.datosGenerales.fechaCreacion),
      'peso': lote.pesoActual,
      'pesoEntrada': reciclador?.pesoEntrada ?? lote.pesoActual,
      'pesoSalida': lote.pesoActual, // Ya considera las muestras del laboratorio
      'material': lote.datosGenerales.tipoMaterial,
      'origen': lote.origen?.usuarioFolio ?? 'Sin origen',
      'presentacion': lote.datosGenerales.materialPresentacion ?? 'Sin especificar',
      'estado': estado,
      'reciclador': reciclador,
      'fechaEntrada': reciclador?.fechaEntrada ?? lote.datosGenerales.fechaCreacion,
      'fechaSalida': reciclador?.fechaSalida,
      'tieneDocumentacion': tieneDocumentacion,
      'documentos': reciclador?.evidenciasFoto ?? [],
      'pesoMuestrasLaboratorio': lote.pesoTotalMuestras,
    };
  }

  void _navigateToNewLot() async {
    HapticFeedback.lightImpact();
    // Navegar al flujo por pasos de recepción
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ReceptorRecepcionPasosScreen(
          userType: 'reciclador',
        ),
      ),
    );
    // Refresh statistics when returning from scanning
    _loadUserProfile();
  }

  void _navigateToLotControl() {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, '/reciclador_lotes');
  }
  
  void _navigateToLotControlCompletedTab() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RecicladorAdministracionLotes(
          initialTab: 1, // Pestaña Completados
        ),
      ),
    );
  }
  
  Widget _buildMegaloteCard(TransformacionModel transformacion) {
    final bool isComplete = transformacion.estado == 'completada';
    final hasAvailableWeight = transformacion.pesoDisponible > 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: null, // No hacer nada al tocar
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icono de megalote
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: BioWayColors.ecoceGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.merge_type,
                  color: BioWayColors.ecoceGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Información del megalote
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MEGALOTE ${transformacion.id.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.scale,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${transformacion.pesoDisponible.toStringAsFixed(2)} kg disponibles',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${transformacion.lotesEntrada.length} lotes',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Botón de ojo
              IconButton(
                onPressed: _navigateToLotControlCompletedTab,
                icon: Icon(
                  Icons.remove_red_eye_outlined,
                  color: BioWayColors.ecoceGreen,
                ),
                tooltip: 'Ver en lotes completados',
              ),
            ],
          ),
        ),
      ),
    );
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
        final reciclador = lote['reciclador'] as ProcesoRecicladorData?;
        final pesoOriginal = reciclador?.pesoEntrada ?? lote['peso'].toDouble();
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecicladorFormularioSalida(
              loteId: lote['id'],
              pesoOriginal: pesoOriginal,
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
        final reciclador = lote['reciclador'] as ProcesoRecicladorData?;
        final fechaEntrada = lote['fechaEntrada'] as DateTime;
        final fechaSalida = lote['fechaSalida'] as DateTime?;
        
        // Obtener nombres de documentos cargados
        List<String> documentosCargados = [];
        if (lote['tieneDocumentacion'] == true) {
          documentosCargados = ['Documentación completa'];
        }
        
        final pesoMuestras = lote['pesoMuestrasLaboratorio'] as double?;
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecicladorLoteQRScreen(
              loteId: lote['id'],
              material: lote['material'],
              pesoOriginal: lote['pesoEntrada'].toDouble(),
              pesoFinal: lote['pesoSalida'].toDouble(),
              presentacion: lote['presentacion'],
              origen: lote['origen'],
              fechaEntrada: fechaEntrada,
              fechaSalida: fechaSalida ?? DateTime.now(),
              documentosCargados: documentosCargados,
              pesoMuestrasLaboratorio: pesoMuestras,
            ),
          ),
        );
        break;
    }
  }


  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevenir que el botón atrás cierre la sesión
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
                          // Estadísticas con UnifiedStatCard y Stream
                          StreamBuilder<Map<String, dynamic>>(
                            stream: _estadisticasStream,
                            initialData: {
                              'lotesRecibidos': _lotesRecibidos,
                              'megalotesCreados': _megalotesCreados,
                              'materialProcesado': _materialProcesado,
                            },
                            builder: (context, snapshot) {
                              final stats = snapshot.data ?? {};
                              final lotesRecibidos = stats['lotesRecibidos'] ?? 0;
                              final megalotesCreados = stats['megalotesCreados'] ?? 0;
                              final materialProcesado = (stats['materialProcesado'] ?? 0.0) as double;
                              
                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      // Estadística de Lotes Recibidos
                                      Expanded(
                                        child: UnifiedStatCard.horizontal(
                                          title: 'Lotes recibidos',
                                          value: lotesRecibidos.toString(),
                                          icon: Icons.inbox,
                                          color: BioWayColors.petBlue,
                                          height: 70,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Estadística de Megalotes Creados
                                      Expanded(
                                        child: UnifiedStatCard.horizontal(
                                          title: 'Megalotes creados',
                                          value: megalotesCreados.toString(),
                                          icon: Icons.merge_type,
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
                                          value: (materialProcesado / 1000).toStringAsFixed(1),
                                          unit: 'ton',
                                          icon: Icons.scale,
                                          color: BioWayColors.ecoceGreen,
                                          height: 70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
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
                                          'Recibir Lote',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          'Recibir material del transportista',
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
                      
                      // Sección de megalotes recientes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.merge_type,
                                size: 24,
                                color: BioWayColors.ecoceGreen,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Megalotes Recientes',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () => _navigateToLotControlCompletedTab(),
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
                      
                      // Lista de megalotes con Stream de transformaciones
                      StreamBuilder<List<TransformacionModel>>(
                        stream: _transformacionesStream,
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
                                      Icons.merge_type,
                                      size: 60,
                                      color: Colors.grey.shade300,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No hay megalotes recientes',
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
                          
                          final transformaciones = snapshot.data!.take(5).toList(); // Mostrar solo 5 más recientes
                          
                          return Column(
                            children: transformaciones.map((transformacion) {
                              return _buildMegaloteCard(transformacion);
                            }).toList(),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 20), // Espacio inferior
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
          icon: Icons.add,
          onPressed: _navigateToNewLot,
          tooltip: 'Recibir lote',
        ),
      ),
      floatingActionButton: EcoceFloatingActionButton(
        onPressed: _navigateToNewLot,
        icon: Icons.add,
        backgroundColor: BioWayColors.ecoceGreen,
        tooltip: 'Recibir lote',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }
}