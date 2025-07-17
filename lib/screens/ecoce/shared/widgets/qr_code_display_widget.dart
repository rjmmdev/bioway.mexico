import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../utils/colors.dart';

/// Widget compartido para mostrar códigos QR con información de lotes
/// Puede ser utilizado por cualquier tipo de usuario del sistema
class QRCodeDisplayWidget extends StatelessWidget {
  // Información básica del lote
  final String loteId;
  final String material;
  final double peso;
  final String presentacion;
  final String origen;
  final DateTime? fechaCreacion;
  
  // Información adicional opcional
  final double? pesoFinal;
  final DateTime? fechaSalida;
  final Map<String, dynamic>? datosAdicionales;
  final List<String>? documentos;
  
  // Personalización
  final String titulo;
  final String subtitulo;
  final Color colorPrincipal;
  final IconData? iconoPrincipal;
  final bool mostrarSeccionDocumentos;
  final bool mostrarPesoFinal;
  final String? tipoUsuario;
  
  // Callbacks
  final VoidCallback? onDescargar;
  final VoidCallback? onImprimir;
  final VoidCallback? onCompartir;

  const QRCodeDisplayWidget({
    super.key,
    required this.loteId,
    required this.material,
    required this.peso,
    required this.presentacion,
    required this.origen,
    this.fechaCreacion,
    this.pesoFinal,
    this.fechaSalida,
    this.datosAdicionales,
    this.documentos,
    this.titulo = 'Código QR del Lote',
    this.subtitulo = 'QR Code',
    this.colorPrincipal = const Color(0xFF4CAF50),
    this.iconoPrincipal,
    this.mostrarSeccionDocumentos = false,
    this.mostrarPesoFinal = false,
    this.tipoUsuario,
    this.onDescargar,
    this.onImprimir,
    this.onCompartir,
  });

  String get _fechaFormateada {
    final fecha = fechaCreacion ?? DateTime.now();
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  String get _fechaSalidaFormateada {
    final fecha = fechaSalida ?? DateTime.now();
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  String get _qrData {
    final Map<String, dynamic> qrInfo = {
      'loteId': loteId,
      'material': material,
      'peso': peso,
      'presentacion': presentacion,
      'origen': origen,
      'fechaCreacion': _fechaFormateada,
      if (pesoFinal != null) 'pesoFinal': pesoFinal,
      if (fechaSalida != null) 'fechaSalida': _fechaSalidaFormateada,
      if (datosAdicionales != null) ...datosAdicionales!,
      if (documentos != null && documentos!.isNotEmpty) 'documentos': documentos,
      if (tipoUsuario != null) 'procesadoPor': tipoUsuario,
    };
    
    return qrInfo.toString();
  }

  Color _getMaterialColor(String material) {
    switch (material) {
      case 'PET':
        return BioWayColors.petBlue;
      case 'HDPE':
        return BioWayColors.hdpeGreen;
      case 'PP':
        return BioWayColors.ppOrange;
      case 'PEBD':
      case 'Poli':
        return const Color(0xFF2196F3);
      case 'Multi':
      case 'Multilaminado':
        return BioWayColors.otherPurple;
      default:
        return Colors.grey;
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
      case 'PEBD':
      case 'Poli':
        return Icons.shopping_bag;
      case 'Multi':
      case 'Multilaminado':
        return Icons.layers;
      default:
        return Icons.recycling;
    }
  }

  void _handleDescargar(BuildContext context) {
    HapticFeedback.lightImpact();
    
    if (onDescargar != null) {
      onDescargar!();
    } else {
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
  }

  void _handleImprimir(BuildContext context) {
    HapticFeedback.lightImpact();
    
    if (onImprimir != null) {
      onImprimir!();
    } else {
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
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // Título con icono opcional
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (iconoPrincipal != null) ...[
                Icon(
                  iconoPrincipal,
                  color: colorPrincipal,
                  size: 24,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // QR Code Container
          Container(
            width: 200,
            height: 200,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorPrincipal.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: QrImageView(
              data: _qrData,
              version: QrVersions.auto,
              size: 184,
              backgroundColor: Colors.transparent,
              errorCorrectionLevel: QrErrorCorrectLevel.H,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // ID del lote
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: colorPrincipal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorPrincipal.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  tipoUsuario == 'reciclador' ? Icons.verified : Icons.fingerprint,
                  color: colorPrincipal,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  loteId,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorPrincipal.withOpacity(0.9),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Información del lote
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  icon: _getMaterialIcon(material),
                  label: 'Material',
                  value: material,
                  color: _getMaterialColor(material),
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  icon: Icons.scale_outlined,
                  label: mostrarPesoFinal ? 'Peso Original' : 'Peso',
                  value: '$peso kg',
                  color: Colors.blue,
                ),
                if (mostrarPesoFinal && pesoFinal != null) ...[
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    icon: Icons.compress,
                    label: 'Peso Final',
                    value: '$pesoFinal kg',
                    color: Colors.indigo,
                  ),
                ],
                const SizedBox(height: 16),
                _buildPresentacionRow(
                  label: 'Presentación',
                  value: presentacion,
                  color: Colors.green,
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  icon: tipoUsuario == 'origen' ? Icons.factory_outlined : Icons.location_on_outlined,
                  label: tipoUsuario == 'origen' ? 'Fuente' : 'Origen',
                  value: origen,
                  color: Colors.purple,
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Fecha de creación',
                  value: _fechaFormateada,
                  color: Colors.orange,
                ),
                if (fechaSalida != null) ...[
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    icon: Icons.logout,
                    label: 'Fecha de salida',
                    value: _fechaSalidaFormateada,
                    color: BioWayColors.success,
                  ),
                ],
                if (mostrarSeccionDocumentos && documentos != null && documentos!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    icon: Icons.folder_copy,
                    label: 'Documentación',
                    value: '${documentos!.length} archivos',
                    color: BioWayColors.info,
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Botones de acción
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleDescargar(context),
                  icon: const Icon(Icons.download),
                  label: const Text('Descargar QR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorPrincipal,
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
                  onPressed: () => _handleImprimir(context),
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
          
          if (onCompartir != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: onCompartir,
                icon: const Icon(Icons.share),
                label: const Text('Compartir'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ],
      ),
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