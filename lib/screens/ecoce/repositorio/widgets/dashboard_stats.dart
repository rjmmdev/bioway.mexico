import 'package:flutter/material.dart';
import '../../../../utils/colors.dart';

class DashboardStats extends StatelessWidget {
  final int totalLotes;
  final double totalPeso;
  final Color primaryColor;
  
  const DashboardStats({
    super.key,
    required this.totalLotes,
    required this.totalPeso,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return Container(
      margin: EdgeInsets.all(screenWidth * 0.04),
      padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor,
            primaryColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Dashboard General',
            style: TextStyle(
              fontSize: screenWidth * (isTablet ? 0.03 : 0.045),
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: screenWidth * 0.04),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  icon: Icons.inventory_2_rounded,
                  value: totalLotes.toString(),
                  label: 'Total de Lotes',
                  color: Colors.white,
                ),
              ),
              Container(
                height: 60,
                width: 1,
                color: Colors.white24,
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  icon: Icons.scale_rounded,
                  value: '${(totalPeso / 1000).toStringAsFixed(1)}',
                  label: 'Toneladas',
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return Column(
      children: [
        Icon(
          icon,
          color: color.withValues(alpha: 0.9),
          size: isTablet ? 32 : 28,
        ),
        SizedBox(height: screenWidth * 0.02),
        Text(
          value,
          style: TextStyle(
            fontSize: screenWidth * (isTablet ? 0.06 : 0.08),
            fontWeight: FontWeight.bold,
            color: color,
            height: 1,
          ),
        ),
        SizedBox(height: screenWidth * 0.01),
        Text(
          label,
          style: TextStyle(
            fontSize: screenWidth * (isTablet ? 0.024 : 0.032),
            color: color.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}