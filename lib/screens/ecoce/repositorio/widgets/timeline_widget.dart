import 'package:flutter/material.dart';
import '../../shared/utils/material_utils.dart';

class TimelineWidget extends StatelessWidget {
  final List<Map<String, dynamic>> events;
  
  const TimelineWidget({
    super.key,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Column(
      children: List.generate(events.length, (index) {
        final event = events[index];
        final isLast = index == events.length - 1;
        final isCompleted = event['isCompleted'] as bool;
        
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline Line and Dot
            Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isCompleted 
                        ? (event['color'] as Color).withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCompleted 
                          ? event['color'] as Color
                          : Colors.grey,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    event['icon'] as IconData,
                    color: isCompleted 
                        ? event['color'] as Color
                        : Colors.grey,
                    size: 20,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 80,
                    color: isCompleted 
                        ? (event['color'] as Color).withValues(alpha: 0.3)
                        : Colors.grey.withValues(alpha: 0.3),
                  ),
              ],
            ),
            
            SizedBox(width: screenWidth * 0.04),
            
            // Event Details
            Expanded(
              child: Container(
                margin: EdgeInsets.only(bottom: isLast ? 0 : 20),
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: BoxDecoration(
                  color: isCompleted 
                      ? (event['color'] as Color).withValues(alpha: 0.05)
                      : Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCompleted 
                        ? (event['color'] as Color).withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event['title'],
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.bold,
                        color: isCompleted 
                            ? event['color'] as Color
                            : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event['subtitle'],
                      style: TextStyle(
                        fontSize: screenWidth * 0.032,
                        color: Colors.grey[700],
                      ),
                    ),
                    if (event['date'] != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            MaterialUtils.formatDateTime(event['date']),
                            style: TextStyle(
                              fontSize: screenWidth * 0.028,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}