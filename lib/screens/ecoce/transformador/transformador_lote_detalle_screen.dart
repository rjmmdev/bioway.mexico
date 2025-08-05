import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import '../../../utils/ui_constants.dart';
import 'transformador_inicio_screen.dart';
import '../shared/widgets/qr_code_display_widget.dart';

class TransformadorLoteDetalleScreen extends StatefulWidget {
  final String firebaseId;
  final double peso;
  final List<String> tiposAnalisis;
  final String productoFabricado;
  final String composicionMaterial;
  final DateTime? fechaCreacion;
  final bool mostrarMensajeExito;
  final List<String>? procesosAplicados;
  final String? comentarios;
  final String? tipoPolimero;

  const TransformadorLoteDetalleScreen({
    super.key,
    required this.firebaseId,
    required this.peso,
    required this.tiposAnalisis,
    required this.productoFabricado,
    required this.composicionMaterial,
    this.fechaCreacion,
    this.mostrarMensajeExito = false,
    this.procesosAplicados,
    this.comentarios,
    this.tipoPolimero,
  });

  @override
  State<TransformadorLoteDetalleScreen> createState() => _TransformadorLoteDetalleScreenState();
}

class _TransformadorLoteDetalleScreenState extends State<TransformadorLoteDetalleScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final Color _primaryColor = Colors.orange;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: Duration(milliseconds: UIConstants.animationDurationLong),
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

  String get _fechaFormateada {
    final fecha = widget.fechaCreacion ?? DateTime.now();
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  void _navegarAInicio() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const TransformadorInicioScreen(),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {IconData? icon}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: UIConstants.spacing8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: isSmallScreen ? 18 : 20,
              color: _primaryColor,
            ),
            SizedBox(width: UIConstants.spacing8),
          ],
          SizedBox(
            width: isSmallScreen ? 100 : 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 14,
                color: Colors.black87,
              ),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Preparar datos adicionales para el QR
    final Map<String, dynamic> datosAdicionales = {
      'tiposAnalisis': widget.tiposAnalisis,
      'productoFabricado': widget.productoFabricado,
      'composicionMaterial': widget.composicionMaterial,
      'tipoUsuario': 'transformador',
      if (widget.tipoPolimero != null) 'tipoPolimero': widget.tipoPolimero,
    };
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: UIConstants.elevationNone,
        title: Text(
          widget.mostrarMensajeExito ? 'Lote Creado' : 'Detalles del Lote',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: UIConstants.fontSizeLarge,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: widget.mostrarMensajeExito 
          ? IconButton(
              icon: const Icon(Icons.close, color: Colors.black),
              onPressed: _navegarAInicio,
            )
          : IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsetsConstants.paddingAll16,
          child: Column(
            children: [
              // Mensaje de éxito animado
              if (widget.mostrarMensajeExito)
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      margin: EdgeInsets.only(bottom: UIConstants.spacing24),
                      padding: EdgeInsetsConstants.paddingAll20,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            BioWayColors.success,
                            BioWayColors.success.withValues(alpha: UIConstants.opacityVeryHigh),
                          ],
                        ),
                        borderRadius: BorderRadiusConstants.borderRadiusLarge,
                        boxShadow: [
                          BoxShadow(
                            color: BioWayColors.success.withValues(alpha: UIConstants.opacityMediumLow),
                            blurRadius: UIConstants.blurRadiusLarge,
                            offset: Offset(0, UIConstants.spacing8 + 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: UIConstants.buttonHeightLarge,
                            height: UIConstants.buttonHeightLarge,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: UIConstants.opacityMediumLow),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: UIConstants.iconSizeLarge,
                            ),
                          ),
                          SizedBox(width: UIConstants.spacing16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '¡Lote creado exitosamente!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: UIConstants.fontSizeBody + 2,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: UIConstants.spacing4),
                                Text(
                                  'ID: ${widget.firebaseId}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: UIConstants.opacityAlmostFull),
                                    fontSize: UIConstants.fontSizeMedium,
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
              
              // Vista previa del lote - Card informativa
              Container(
                margin: EdgeInsets.only(bottom: UIConstants.spacing24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vista previa',
                      style: TextStyle(
                        fontSize: UIConstants.fontSizeMedium,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: UIConstants.spacing12),
                    Container(
                      padding: EdgeInsetsConstants.paddingAll20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadiusConstants.borderRadiusMedium,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: UIConstants.opacityVeryLow),
                            blurRadius: UIConstants.blurRadiusMedium,
                            offset: Offset(0, UIConstants.spacing4 + 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsetsConstants.paddingAll12,
                                decoration: BoxDecoration(
                                  color: _primaryColor.withValues(alpha: UIConstants.opacityLow),
                                  borderRadius: BorderRadiusConstants.borderRadiusMedium,
                                ),
                                child: Icon(
                                  Icons.factory,
                                  color: _primaryColor,
                                  size: UIConstants.iconSizeMedium,
                                ),
                              ),
                              SizedBox(width: UIConstants.spacing16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Lote ${widget.firebaseId}',
                                      style: const TextStyle(
                                        fontSize: UIConstants.fontSizeBody,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: UIConstants.spacing4),
                                    Text(
                                      widget.productoFabricado,
                                      style: TextStyle(
                                        fontSize: UIConstants.fontSizeMedium,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: UIConstants.spacing20),
                          _buildInfoRow('Peso:', '${widget.peso} kg', icon: Icons.scale),
                          _buildInfoRow('Producto:', widget.productoFabricado, icon: Icons.inventory_2),
                          if (widget.tipoPolimero != null)
                            _buildInfoRow('Tipo de polímero:', widget.tipoPolimero!, icon: Icons.science_outlined),
                          _buildInfoRow('Análisis:', widget.tiposAnalisis.join(', '), icon: Icons.science),
                          if (widget.procesosAplicados != null && widget.procesosAplicados!.isNotEmpty)
                            _buildInfoRow('Procesos aplicados:', widget.procesosAplicados!.join(', '), icon: Icons.settings),
                          _buildInfoRow('Fecha:', _fechaFormateada, icon: Icons.calendar_today),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Código QR usando el widget compartido
              QRCodeDisplayWidget(
                loteId: widget.firebaseId,
                material: widget.productoFabricado, // Producto fabricado
                peso: widget.peso,
                presentacion: widget.productoFabricado, // Usar producto como presentación
                origen: 'Transformador ${widget.firebaseId}', // Origen del transformador
                fechaCreacion: widget.fechaCreacion,
                datosAdicionales: datosAdicionales,
                titulo: 'Código QR del Lote Transformado',
                subtitulo: widget.tipoPolimero != null ? 'Tipo de polímero: ${widget.tipoPolimero}' : 'QR Code',
                colorPrincipal: _primaryColor,
                iconoPrincipal: Icons.factory,
                tipoUsuario: 'transformador',
              ),

              // Información adicional del lote
              SizedBox(height: UIConstants.spacing24),
              Container(
                padding: EdgeInsetsConstants.paddingAll20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadiusConstants.borderRadiusMedium,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: _primaryColor,
                          size: UIConstants.iconSizeMedium,
                        ),
                        SizedBox(width: UIConstants.spacing8),
                        const Text(
                          'Información Adicional',
                          style: TextStyle(
                            fontSize: UIConstants.fontSizeBody + 2,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: UIConstants.spacing16),
                    Container(
                      padding: EdgeInsetsConstants.paddingAll16,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadiusConstants.borderRadiusMedium,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Composición del Material',
                            style: TextStyle(
                              fontSize: UIConstants.fontSizeMedium,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: UIConstants.spacing8),
                          Text(
                            widget.composicionMaterial,
                            style: TextStyle(
                              fontSize: UIConstants.fontSizeMedium,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.comentarios != null && widget.comentarios!.isNotEmpty) ...[
                      SizedBox(height: UIConstants.spacing16),
                      Container(
                        padding: EdgeInsetsConstants.paddingAll16,
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadiusConstants.borderRadiusMedium,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Comentarios',
                              style: TextStyle(
                                fontSize: UIConstants.fontSizeMedium,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: UIConstants.spacing8),
                            Text(
                              widget.comentarios!,
                              style: TextStyle(
                                fontSize: UIConstants.fontSizeMedium,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (widget.mostrarMensajeExito) ...[
                SizedBox(height: UIConstants.spacing32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _navegarAInicio,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      padding: EdgeInsets.symmetric(vertical: UIConstants.spacing16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadiusConstants.borderRadiusMedium,
                      ),
                    ),
                    child: const Text(
                      'Ir al inicio',
                      style: TextStyle(
                        fontSize: UIConstants.fontSizeBody,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],

              SizedBox(height: UIConstants.spacing40),
            ],
          ),
        ),
      ),
    );
  }
}