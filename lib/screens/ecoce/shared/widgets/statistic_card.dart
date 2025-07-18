import 'package:flutter/material.dart';

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
      backgroundGradientColor = color.withOpacity(0.05);
    }
    
    return Container(
      width: width,
      height: height ?? 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            backgroundGradientColor,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Icono de fondo decorativo
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(
              icon == Icons.inbox ? Icons.inbox_outlined : 
              icon == Icons.add_box ? Icons.add_box_outlined :
              icon == Icons.scale ? Icons.scale_outlined : 
              icon == Icons.inventory_2 ? Icons.inventory_2_outlined : icon,
              size: 60,
              color: color.withOpacity(0.05),
            ),
          ),
          // Contenido
          Padding(
            padding: EdgeInsets.all(isCompact ? 12.0 : 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      width: isCompact ? 32 : 32,
                      height: isCompact ? 32 : 32,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: isCompact ? 18 : 18,
                      ),
                    ),
                    const SizedBox(width: 10),
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
                                    fontSize: isCompact ? 20 : 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  unit!,
                                  style: TextStyle(
                                    fontSize: isCompact ? 14 : 14,
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
                              fontSize: isCompact ? 11 : 11,
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