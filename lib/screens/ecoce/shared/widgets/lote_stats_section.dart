import 'package:flutter/material.dart';

/// Sección de estadísticas reutilizable para lotes
class LoteStatsSection extends StatelessWidget {
  final int lotesCount;
  final double pesoTotal;
  final Color tabColor;
  final bool showInTons;
  final String? customLotesLabel;
  final String? customPesoLabel;
  
  const LoteStatsSection({
    super.key,
    required this.lotesCount,
    required this.pesoTotal,
    required this.tabColor,
    this.showInTons = false,
    this.customLotesLabel,
    this.customPesoLabel,
  });

  @override
  Widget build(BuildContext context) {
    final pesoDisplay = showInTons 
      ? '${(pesoTotal / 1000).toStringAsFixed(2)} ton'
      : '${pesoTotal.toStringAsFixed(1)} kg';
      
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          // Número de lotes
          Expanded(
            child: _buildStatCard(
              icon: Icons.inventory_2,
              iconColor: tabColor,
              value: lotesCount.toString(),
              label: customLotesLabel ?? 'Lotes',
            ),
          ),
          const SizedBox(width: 10),
          // Peso total
          Expanded(
            child: _buildStatCard(
              icon: Icons.scale,
              iconColor: Colors.orange,
              value: pesoDisplay,
              label: customPesoLabel ?? 'Peso Total',
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}