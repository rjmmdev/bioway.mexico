import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import '../../../models/lotes/lote_unificado_model.dart';
import '../../../services/lote_unificado_service.dart';
import '../shared/utils/dialog_utils.dart';
import '../shared/widgets/loading_indicator.dart';
import 'origen_config.dart';
import 'origen_inicio_screen.dart';
import 'widgets/origen_lote_unificado_card.dart';
import '../shared/widgets/qr_code_display_widget.dart';

class OrigenLoteDetalleScreen extends StatefulWidget {
  final String firebaseId;
  final String material;
  final double peso;
  final String presentacion;
  final String fuente;
  final DateTime? fechaCreacion;
  final bool mostrarMensajeExito;

  const OrigenLoteDetalleScreen({
    super.key,
    required this.firebaseId,
    required this.material,
    required this.peso,
    required this.presentacion,
    required this.fuente,
    this.fechaCreacion,
    this.mostrarMensajeExito = false,
  });

  @override
  State<OrigenLoteDetalleScreen> createState() => _OrigenLoteDetalleScreenState();
}

class _OrigenLoteDetalleScreenState extends State<OrigenLoteDetalleScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  final LoteUnificadoService _loteService = LoteUnificadoService();
  LoteUnificadoModel? _loteCompleto;
  bool _isLoadingLote = true;

  Color get _primaryColor => OrigenUserConfig.current.color;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    if (widget.mostrarMensajeExito) {
      _animationController.forward();
    }
    
    // Cargar el lote completo
    _cargarLoteCompleto();
  }
  
  Future<void> _cargarLoteCompleto() async {
    try {
      print('=== CARGANDO LOTE COMPLETO ===');
      print('ID del lote: ${widget.firebaseId}');
      
      final lote = await _loteService.obtenerLotePorId(widget.firebaseId);
      
      if (lote != null) {
        print('Lote cargado exitosamente');
        print('Datos generales: ${lote.datosGenerales.toJson()}');
        
        if (lote.origen != null) {
          print('Datos de origen encontrados:');
          print('- Firma: ${lote.origen?.firmaOperador}');
          print('- Evidencias: ${lote.origen?.evidenciasFoto}');
          print('- Condiciones: ${lote.origen?.condiciones}');
          print('- Comentarios: ${lote.origen?.comentarios}');
        } else {
          print('No hay datos de origen en el lote');
        }
      } else {
        print('El lote es null');
      }
      
      if (mounted) {
        setState(() {
          _loteCompleto = lote;
          _isLoadingLote = false;
        });
      }
    } catch (e) {
      print('ERROR al cargar lote: $e');
      if (mounted) {
        setState(() {
          _isLoadingLote = false;
        });
        DialogUtils.showErrorDialog(
          context: context,
          title: 'Error',
          message: 'No se pudo cargar la información completa del lote',
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _descargarCodigoQR() async {
    HapticFeedback.lightImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Código QR descargado exitosamente'),
        backgroundColor: BioWayColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _imprimirEtiqueta() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Enviando a impresora...'),
        backgroundColor: BioWayColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _compartir() {
    HapticFeedback.lightImpact();
    // TODO: Implementar compartir
  }

  void _irAInicio() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const OrigenInicioScreen()),
    );
  }
  


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: widget.mostrarMensajeExito 
          ? IconButton(
              icon: const Icon(Icons.close, color: Colors.black),
              onPressed: _irAInicio,
            )
          : IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
        title: Text(
          widget.mostrarMensajeExito ? 'Lote Creado' : 'Detalles del Lote',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Mensaje de éxito (solo si se muestra)
              if (widget.mostrarMensajeExito) ...[
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            BioWayColors.success,
                            BioWayColors.success.withValues(alpha:0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: BioWayColors.success.withValues(alpha:0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha:0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '¡Lote creado exitosamente!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'ID: ${widget.firebaseId}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha:0.9),
                                    fontSize: 14,
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
              ],

              // Vista previa del lote
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vista previa',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    OrigenLoteUnificadoCard(
                      lote: _loteCompleto ?? LoteUnificadoModel(
                        id: widget.firebaseId,
                        datosGenerales: DatosGeneralesLote(
                          id: widget.firebaseId,
                          fechaCreacion: widget.fechaCreacion ?? DateTime.now(),
                          creadoPor: '',
                          tipoMaterial: widget.material,
                          pesoInicial: widget.peso,
                          peso: widget.peso,
                          estadoActual: 'en_origen',
                          procesoActual: 'origen',
                          historialProcesos: ['origen'],
                          qrCode: 'LOTE-${widget.material}-${widget.firebaseId}',
                          materialPresentacion: widget.presentacion,
                          materialFuente: widget.fuente,
                        ),
                        origen: null,
                        transporte: null,
                        reciclador: null,
                        laboratorio: null,
                        transformador: null,
                      ),
                      showActions: false,
                    ),
                  ],
                ),
              ),

              // Código QR usando el widget compartido
              QRCodeDisplayWidget(
                loteId: widget.firebaseId,
                material: widget.material,
                peso: widget.peso,
                presentacion: widget.presentacion,
                origen: widget.fuente,
                fechaCreacion: widget.fechaCreacion,
                titulo: 'Código QR del Lote',
                colorPrincipal: _primaryColor,
                tipoUsuario: 'origen',
                onDescargar: _descargarCodigoQR,
                onImprimir: _imprimirEtiqueta,
                onCompartir: _compartir,
              ),
              
              // Información sobre transferencia automática
              if (!_isLoadingLote && _loteCompleto != null && 
                  _loteCompleto!.datosGenerales.procesoActual == 'origen') ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: BioWayColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: BioWayColors.info.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: BioWayColors.info,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Transferencia Automática',
                              style: TextStyle(
                                color: BioWayColors.info,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'El transportista debe escanear el código QR para recibir este lote',
                              style: TextStyle(
                                color: BioWayColors.info.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (widget.mostrarMensajeExito) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _irAInicio,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Ir al inicio',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _primaryColor,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

}