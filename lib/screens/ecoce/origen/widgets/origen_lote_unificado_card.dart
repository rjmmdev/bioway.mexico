import 'package:flutter/material.dart';
import 'package:app/models/lotes/lote_unificado_model.dart';
import 'package:app/screens/ecoce/shared/utils/material_utils.dart';
import 'package:app/utils/format_utils.dart';

/// Card widget para mostrar lotes unificados en la pantalla de origen
class OrigenLoteUnificadoCard extends StatelessWidget {
  final LoteUnificadoModel lote;
  final VoidCallback? onTap;
  final Color primaryColor;
  final bool showActions;

  const OrigenLoteUnificadoCard({
    super.key,
    required this.lote,
    this.onTap,
    this.primaryColor = const Color(0xFF2E7D32),
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final datosOrigen = lote.origen;
    
    if (datosOrigen == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap ?? () {},
      child: Container(
        margin: EdgeInsets.only(
          bottom: screenWidth * 0.03,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header con color del material
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: MaterialUtils.getMaterialColor(datosOrigen.tipoPoli),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
            ),
            
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Primera fila: ID y Estado
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // ID del lote
                      Row(
                        children: [
                          Icon(
                            Icons.qr_code_2,
                            size: screenWidth * 0.045,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Text(
                            lote.id.substring(0, 8).toUpperCase(),
                            style: TextStyle(
                              fontSize: screenWidth * 0.035,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      
                      // Estado actual
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.025,
                          vertical: screenWidth * 0.015,
                        ),
                        decoration: BoxDecoration(
                          color: _getEstadoColor(lote.datosGenerales.estadoActual).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getEstadoColor(lote.datosGenerales.estadoActual),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _getEstadoLabel(lote.datosGenerales.estadoActual),
                          style: TextStyle(
                            fontSize: screenWidth * 0.03,
                            fontWeight: FontWeight.w600,
                            color: _getEstadoColor(lote.datosGenerales.estadoActual),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: screenWidth * 0.03),
                  
                  // Segunda fila: Material y peso
                  Row(
                    children: [
                      // Tipo de material
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: screenWidth * 0.01,
                              height: screenWidth * 0.08,
                              decoration: BoxDecoration(
                                color: MaterialUtils.getMaterialColor(datosOrigen.tipoPoli),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Material',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.028,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  datosOrigen.tipoPoli,
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.035,
                                    fontWeight: FontWeight.w600,
                                    color: MaterialUtils.getMaterialColor(datosOrigen.tipoPoli),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Peso
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.03,
                          vertical: screenWidth * 0.02,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.scale,
                              size: screenWidth * 0.04,
                              color: primaryColor,
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            Text(
                              '${datosOrigen.pesoNace.toStringAsFixed(1)} kg',
                              style: TextStyle(
                                fontSize: screenWidth * 0.035,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: screenWidth * 0.03),
                  
                  // Tercera fila: Presentación y fuente
                  Row(
                    children: [
                      // Presentación
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              _getPresentacionIcon(datosOrigen.presentacion),
                              size: screenWidth * 0.04,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            Expanded(
                              child: Text(
                                datosOrigen.presentacion,
                                style: TextStyle(
                                  fontSize: screenWidth * 0.032,
                                  color: Colors.grey[700],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Fecha
                      Text(
                        FormatUtils.formatDate(datosOrigen.fechaEntrada),
                        style: TextStyle(
                          fontSize: screenWidth * 0.03,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  
                  // Cuarta fila: Fuente (si hay espacio)
                  if (datosOrigen.fuente.isNotEmpty) ...[
                    SizedBox(height: screenWidth * 0.02),
                    Row(
                      children: [
                        Icon(
                          Icons.source,
                          size: screenWidth * 0.035,
                          color: Colors.grey[500],
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        Expanded(
                          child: Text(
                            datosOrigen.fuente,
                            style: TextStyle(
                              fontSize: screenWidth * 0.03,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  // Indicador de proceso si no está en origen
                  if (lote.datosGenerales.historialProcesos.length > 1) ...[
                    SizedBox(height: screenWidth * 0.03),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.025,
                        vertical: screenWidth * 0.015,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.swap_horiz,
                            size: screenWidth * 0.035,
                            color: Colors.orange[700],
                          ),
                          SizedBox(width: screenWidth * 0.015),
                          Text(
                            'Ha pasado por ${lote.datosGenerales.historialProcesos.length} procesos',
                            style: TextStyle(
                              fontSize: screenWidth * 0.028,
                              color: Colors.orange[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPresentacionIcon(String presentacion) {
    switch (presentacion.toLowerCase()) {
      case 'pacas':
        return Icons.inventory_2;
      case 'sacos':
        return Icons.shopping_bag;
      default:
        return Icons.category;
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'en_origen':
        return Colors.green;
      case 'en_transporte':
        return Colors.blue;
      case 'en_reciclador':
        return Colors.orange;
      case 'en_laboratorio':
        return Colors.purple;
      case 'en_transformador':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getEstadoLabel(String estado) {
    switch (estado) {
      case 'en_origen':
        return 'En Origen';
      case 'en_transporte':
        return 'En Transporte';
      case 'en_reciclador':
        return 'En Reciclador';
      case 'en_laboratorio':
        return 'En Laboratorio';
      case 'en_transformador':
        return 'En Transformador';
      default:
        return estado;
    }
  }
}