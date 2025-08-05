import 'package:flutter/material.dart';
import '../../../../utils/ui_constants.dart';

class StatisticCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final String? unit;

  const StatisticCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
    this.width,
    this.height,
    this.unit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isCompact = height != null && height! < 100;
    
    // Determinar el color de fondo según el color principal
    Color backgroundGradientColor;
    if (color == Colors.blue) {
      backgroundGradientColor = Colors.blue.shade50;
    } else if (color == Colors.green) {
      backgroundGradientColor = Colors.green.shade50;
    } else if (color == Colors.purple) {
      backgroundGradientColor = Colors.purple.shade50;
    } else if (color == Colors.orange) {
      backgroundGradientColor = Colors.orange.shade50;
    } else {
      backgroundGradientColor = color.withValues(alpha: UIConstants.opacityVeryLow);
    }
    
    return Container(
      width: width,
      height: height ?? UIConstants.buttonHeightLarge + UIConstants.spacing16,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            backgroundGradientColor,
          ],
        ),
        borderRadius: BorderRadiusConstants.borderRadiusLarge,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: UIConstants.opacityLow),
            blurRadius: UIConstants.blurRadiusLarge,
            offset: Offset(0, UIConstants.spacing10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Icono de fondo decorativo
          Positioned(
            right: -UIConstants.spacing10,
            bottom: -UIConstants.spacing10,
            child: Icon(
              icon == Icons.inbox ? Icons.inbox_outlined : 
              icon == Icons.add_box ? Icons.add_box_outlined :
              icon == Icons.scale ? Icons.scale_outlined : 
              icon == Icons.inventory_2 ? Icons.inventory_2_outlined : icon,
              size: UIConstants.iconSizeDialog,
              color: color.withValues(alpha: UIConstants.opacityVeryLow),
            ),
          ),
          // Contenido
          Padding(
            padding: EdgeInsetsConstants.paddingAll12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      width: UIConstants.buttonHeightSmall,
                      height: UIConstants.buttonHeightSmall,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: UIConstants.opacityLow),
                        borderRadius: BorderRadius.circular(UIConstants.spacing10),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: UIConstants.iconSizeBody + 2,
                      ),
                    ),
                    SizedBox(width: UIConstants.spacing10),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (unit != null)
                            Row(
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  value,
                                  style: TextStyle(
                                    fontSize: UIConstants.fontSizeLarge,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    height: 1,
                                  ),
                                ),
                                SizedBox(width: UIConstants.spacing4),
                                Text(
                                  unit!,
                                  style: TextStyle(
                                    fontSize: UIConstants.fontSizeMedium,
                                    fontWeight: FontWeight.w600,
                                    color: color,
                                    height: 1,
                                  ),
                                ),
                              ],
                            )
                          else
                            Text(
                              value,
                              style: TextStyle(
                                fontSize: isCompact ? 20 : 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                height: 1,
                              ),
                            ),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: UIConstants.fontSizeSmall - 1,
                              color: Colors.grey[600],
                              height: 1.1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}