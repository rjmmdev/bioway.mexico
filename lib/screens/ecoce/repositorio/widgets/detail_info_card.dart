import 'package:flutter/material.dart';
import '../../../../utils/colors.dart';

class DetailInfoCard extends StatelessWidget {
  final String title;
  final Map<String, String> info;
  final Color primaryColor;
  
  const DetailInfoCard({
    super.key,
    required this.title,
    required this.info,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      margin: EdgeInsets.only(bottom: screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(screenWidth * 0.04),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Column(
              children: info.entries.map((entry) {
                return Padding(
                  padding: EdgeInsets.only(bottom: screenWidth * 0.03),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: screenWidth * 0.032,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Expanded(
                        flex: 3,
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            fontSize: screenWidth * 0.032,
                            fontWeight: FontWeight.w600,
                            color: BioWayColors.darkGreen,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}