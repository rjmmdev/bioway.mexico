import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../utils/colors.dart';
import '../../shared/utils/material_utils.dart';

class LoteCard extends StatelessWidget {
  final Map<String, dynamic> lote;
  final VoidCallback onTap;
  
  const LoteCard({
    super.key,
    required this.lote,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    final materialColor = MaterialUtils.getMaterialColor(lote['material']);
    final materialIcon = MaterialUtils.getMaterialIcon(lote['material']);
    
    return Container(
      margin: EdgeInsets.only(bottom: screenWidth * 0.03),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.all(screenWidth * 0.04),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Material Icon Container
                Container(
                  width: isTablet ? 70 : 60,
                  height: isTablet ? 70 : 60,
                  decoration: BoxDecoration(
                    color: materialColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    materialIcon,
                    color: materialColor,
                    size: isTablet ? 32 : 28,
                  ),
                ),
                
                SizedBox(width: screenWidth * 0.04),
                
                // Lote Information
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            lote['id'],
                            style: TextStyle(
                              fontSize: screenWidth * (isTablet ? 0.028 : 0.04),
                              fontWeight: FontWeight.bold,
                              color: BioWayColors.darkGreen,
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.02,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getEstadoColor(lote['estado']).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              lote['estado'],
                              style: TextStyle(
                                fontSize: screenWidth * (isTablet ? 0.02 : 0.025),
                                fontWeight: FontWeight.w600,
                                color: _getEstadoColor(lote['estado']),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: screenWidth * 0.01),
                      
                      Row(
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: isTablet ? 18 : 16,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: screenWidth * 0.01),
                          Text(
                            lote['material'],
                            style: TextStyle(
                              fontSize: screenWidth * (isTablet ? 0.024 : 0.032),
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.04),
                          Icon(
                            Icons.scale_outlined,
                            size: isTablet ? 18 : 16,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: screenWidth * 0.01),
                          Text(
                            '${lote['peso'].toStringAsFixed(1)} kg',
                            style: TextStyle(
                              fontSize: screenWidth * (isTablet ? 0.024 : 0.032),
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: screenWidth * 0.01),
                      
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: isTablet ? 18 : 16,
                            color: Colors.grey[500],
                          ),
                          SizedBox(width: screenWidth * 0.01),
                          Expanded(
                            child: Text(
                              lote['ubicacionActual'],
                              style: TextStyle(
                                fontSize: screenWidth * (isTablet ? 0.022 : 0.03),
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Arrow Icon
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: isTablet ? 20 : 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'En Proceso':
        return BioWayColors.warning;
      case 'Completado':
        return BioWayColors.success;
      case 'Pendiente':
        return BioWayColors.primaryGreen;
      default:
        return Colors.grey;
    }
  }
}