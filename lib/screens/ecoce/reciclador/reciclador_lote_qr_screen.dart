import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../utils/colors.dart';
import 'reciclador_inicio.dart';
import 'widgets/reciclador_lote_card.dart';

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

  String get _qrData {
    // Generar datos para el código QR incluyendo todos los datos del proceso
    final Map<String, dynamic> qrInfo = {
      'loteId': widget.loteId,
      'material': widget.material,
      'pesoOriginal': widget.pesoOriginal,
      'pesoFinal': widget.pesoFinal ?? widget.pesoOriginal,
      'presentacion': widget.presentacion,
      'origen': widget.origen,
      'fechaEntrada': _fechaEntradaFormateada,
      'fechaSalida': _fechaSalidaFormateada,
      'procesoReciclaje': widget.datosFormularioSalida ?? {},
      'documentacion': widget.documentosCargados ?? [],
      'estadoFinal': 'Completado',
      'certificado': true,
    };
    
    return qrInfo.toString();
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
      case 'PET':
        return BioWayColors.petBlue;
      case 'HDPE':
        return BioWayColors.hdpeGreen;
      case 'PP':
        return BioWayColors.ppOrange;
      case 'Multi':
      case 'Multilaminado':
        return BioWayColors.otherPurple;
      default:
        return BioWayColors.ecoceGreen;
    }
  }

  IconData _getMaterialIcon(String material) {
    switch (material) {
      case 'PET':
        return Icons.local_drink;
      case 'HDPE':
        return Icons.cleaning_services;
      case 'PP':
        return Icons.kitchen;
      case 'Multi':
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
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.black87),
            onPressed: _compartir,
          ),
        ],
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

              // Código QR con información de reciclaje
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.recycling,
                          color: BioWayColors.ecoceGreen,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Certificado de Material Reciclado',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // QR Container
                    Container(
                      width: 200,
                      height: 200,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: BioWayColors.ecoceGreen.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.qr_code_2,
                            size: 120,
                            color: BioWayColors.ecoceGreen,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Código QR',
                            style: TextStyle(
                              fontSize: 14,
                              color: BioWayColors.ecoceGreen,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // ID del lote
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: BioWayColors.ecoceGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: BioWayColors.ecoceGreen.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified,
                            color: BioWayColors.ecoceGreen,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.loteId,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: BioWayColors.darkGreen,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Información del proceso de reciclaje
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          // Sección de información básica
                          _buildSectionTitle('Información del Lote'),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            icon: _getMaterialIcon(widget.material),
                            label: 'Material',
                            value: widget.material,
                            color: _getMaterialColor(widget.material),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            icon: Icons.scale_outlined,
                            label: 'Peso Original',
                            value: '${widget.pesoOriginal} kg',
                            color: Colors.blue,
                          ),
                          if (widget.pesoFinal != null) ...[
                            const SizedBox(height: 16),
                            _buildInfoRow(
                              icon: Icons.compress,
                              label: 'Peso Final',
                              value: '${widget.pesoFinal} kg',
                              color: Colors.indigo,
                            ),
                          ],
                          const SizedBox(height: 16),
                          _buildPresentacionRow(
                            label: 'Presentación',
                            value: widget.presentacion,
                            color: Colors.green,
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            icon: Icons.location_on_outlined,
                            label: 'Origen',
                            value: widget.origen,
                            color: Colors.purple,
                          ),
                          
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 24),
                          
                          // Sección de fechas del proceso
                          _buildSectionTitle('Proceso de Reciclaje'),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            icon: Icons.login,
                            label: 'Fecha de Entrada',
                            value: _fechaEntradaFormateada,
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            icon: Icons.logout,
                            label: 'Fecha de Salida',
                            value: _fechaSalidaFormateada,
                            color: BioWayColors.success,
                          ),
                          
                          // Información adicional del proceso
                          if (widget.datosFormularioSalida != null) ...[
                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 24),
                            _buildSectionTitle('Detalles del Proceso'),
                            const SizedBox(height: 12),
                            if (widget.datosFormularioSalida!['tipoProceso'] != null)
                              _buildInfoRow(
                                icon: Icons.engineering,
                                label: 'Tipo de Proceso',
                                value: widget.datosFormularioSalida!['tipoProceso'],
                                color: Colors.teal,
                              ),
                          ],
                          
                          // Documentación
                          if (widget.documentosCargados != null && widget.documentosCargados!.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 24),
                            _buildSectionTitle('Documentación Técnica'),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              icon: Icons.folder_copy,
                              label: 'Documentos Cargados',
                              value: '${widget.documentosCargados!.length} archivos',
                              color: BioWayColors.info,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _descargarCodigoQR,
                      icon: const Icon(Icons.download),
                      label: const Text('Descargar QR'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BioWayColors.ecoceGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _imprimirEtiqueta,
                      icon: const Icon(Icons.print),
                      label: const Text('Imprimir'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: Colors.grey[400]!,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              if (widget.mostrarMensajeExito) ...[
                const SizedBox(height: 16),
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

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: BioWayColors.ecoceGreen,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: color,
            size: 22,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPresentacionRow({
    required String label,
    required String value,
    required Color color,
  }) {
    final svgPath = value == 'Pacas' 
        ? 'assets/images/icons/pacas.svg' 
        : 'assets/images/icons/sacos.svg';
        
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: SvgPicture.asset(
              svgPath,
              width: 22,
              height: 22,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}