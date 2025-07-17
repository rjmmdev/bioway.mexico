import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../utils/colors.dart';
import 'reciclador_inicio.dart';
import 'widgets/reciclador_lote_card.dart';
import '../shared/widgets/qr_code_display_widget.dart';

class RecicladorLoteQRScreen extends StatefulWidget {
  final String loteId;
  final String material;
  final double pesoOriginal;
  final double? pesoFinal;
  final String presentacion;
  final String origen;
  final DateTime? fechaEntrada;
  final DateTime? fechaSalida;
  final Map<String, dynamic>? datosFormularioSalida;
  final List<String>? documentosCargados;
  final bool mostrarMensajeExito;

  const RecicladorLoteQRScreen({
    super.key,
    required this.loteId,
    required this.material,
    required this.pesoOriginal,
    this.pesoFinal,
    required this.presentacion,
    required this.origen,
    this.fechaEntrada,
    this.fechaSalida,
    this.datosFormularioSalida,
    this.documentosCargados,
    this.mostrarMensajeExito = false,
  });

  @override
  State<RecicladorLoteQRScreen> createState() => _RecicladorLoteQRScreenState();
}

class _RecicladorLoteQRScreenState extends State<RecicladorLoteQRScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String get _fechaEntradaFormateada {
    final fecha = widget.fechaEntrada ?? DateTime.now();
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  String get _fechaSalidaFormateada {
    final fecha = widget.fechaSalida ?? DateTime.now();
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }


  Future<void> _descargarCodigoQR() async {
    HapticFeedback.lightImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Código QR de reciclaje descargado exitosamente'),
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
        content: const Text('Enviando etiqueta de reciclaje a impresora...'),
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
    // TODO: Implementar compartir información del lote reciclado
  }

  void _irAInicio() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const RecicladorHomeScreen()),
      (route) => false,
    );
  }

  Color _getMaterialColor(String material) {
    switch (material) {
      case 'PEBD':
        return BioWayColors.pebdPink;
      case 'PP':
        return BioWayColors.ppPurple;
      case 'Multilaminado':
        return BioWayColors.multilaminadoBrown;
      default:
        return BioWayColors.ecoceGreen;
    }
  }

  IconData _getMaterialIcon(String material) {
    switch (material) {
      case 'PEBD':
        return Icons.shopping_bag;
      case 'PP':
        return Icons.kitchen;
      case 'Multilaminado':
        return Icons.layers;
      default:
        return Icons.recycling;
    }
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
          widget.mostrarMensajeExito ? 'Proceso Completado' : 'Certificado de Reciclaje',
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
                            BioWayColors.success.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: BioWayColors.success.withOpacity(0.3),
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
                              color: Colors.white.withOpacity(0.2),
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
                                  '¡Proceso de reciclaje completado!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Lote: ${widget.loteId}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
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
                      'Vista previa del lote procesado',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    RecicladorLoteCard(
                      lote: {
                        'id': widget.loteId,
                        'material': widget.material,
                        'peso': widget.pesoFinal ?? widget.pesoOriginal,
                        'presentacion': widget.presentacion,
                        'origen': widget.origen,
                        'fecha': _fechaSalidaFormateada,
                        'estado': 'finalizado',
                      },
                      showActions: false,
                      onTap: null,
                    ),
                  ],
                ),
              ),

              // Código QR usando el widget compartido
              QRCodeDisplayWidget(
                loteId: widget.loteId,
                material: widget.material,
                peso: widget.pesoOriginal,
                pesoFinal: widget.pesoFinal,
                presentacion: widget.presentacion,
                origen: widget.origen,
                fechaCreacion: widget.fechaEntrada,
                fechaSalida: widget.fechaSalida,
                titulo: 'Certificado de Material Reciclado',
                colorPrincipal: BioWayColors.ecoceGreen,
                iconoPrincipal: Icons.recycling,
                tipoUsuario: 'reciclador',
                mostrarPesoFinal: true,
                mostrarSeccionDocumentos: true,
                documentos: widget.documentosCargados,
                datosAdicionales: {
                  'estadoFinal': 'Completado',
                  'certificado': true,
                  if (widget.datosFormularioSalida != null) ...widget.datosFormularioSalida!,
                },
                onDescargar: _descargarCodigoQR,
                onImprimir: _imprimirEtiqueta,
                onCompartir: _compartir,
              ),

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
                        color: BioWayColors.ecoceGreen,
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