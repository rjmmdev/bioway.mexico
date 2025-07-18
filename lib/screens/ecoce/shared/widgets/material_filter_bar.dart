import 'package:flutter/material.dart';
import '../utils/material_utils.dart';

class MaterialFilterBar extends StatelessWidget {
  final String selectedMaterial;
  final String selectedTime;
  final Function(String) onMaterialChanged;
  final Function(String) onTimeChanged;
  final List<String> materials;
  final List<String> timeOptions;

  const MaterialFilterBar({
    Key? key,
    required this.selectedMaterial,
    required this.selectedTime,
    required this.onMaterialChanged,
    required this.onTimeChanged,
    this.materials = const ['Todos', 'PEBD', 'PP', 'Multilaminado'],
    this.timeOptions = const ['Hoy', 'Semana', 'Mes', 'Todos'],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: materials.map((material) {
                  final isSelected = selectedMaterial == material;
                  final color = material == 'Todos' 
                      ? Colors.grey 
                      : MaterialUtils.getMaterialColor(material);
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(material),
                      selected: isSelected,
                      onSelected: (_) => onMaterialChanged(material),
                      backgroundColor: Colors.grey[200],
                      selectedColor: color.withOpacity(0.3),
                      labelStyle: TextStyle(
                        color: isSelected ? color : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      avatar: material != 'Todos' 
                          ? Icon(
                              MaterialUtils.getMaterialIcon(material),
                              size: 18,
                              color: isSelected ? color : Colors.grey[600],
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          DropdownButton<String>(
            value: selectedTime,
            underline: Container(),
            icon: const Icon(Icons.calendar_today, size: 18),
            items: timeOptions.map((time) {
              return DropdownMenuItem(
                value: time,
                child: Text(
                  time,
                  style: const TextStyle(fontSize: 14),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                onTimeChanged(value);
              }
            },
          ),
        ],
      ),
    );
  }
}