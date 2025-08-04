import 'package:flutter/material.dart';
import '../../../../utils/colors.dart';

/// Sección de filtros reutilizable para lotes
class LoteFilterSection extends StatelessWidget {
  final String selectedMaterial;
  final String selectedTime;
  final String? selectedPresentacion; // Ahora es opcional
  final bool showMegaloteFilter;
  final bool showOnlyMegalotes;
  final ValueChanged<String> onMaterialChanged;
  final ValueChanged<String> onTimeChanged;
  final ValueChanged<String>? onPresentacionChanged; // Ahora es opcional
  final VoidCallback? onMegaloteFilterToggle;
  final int megaloteCount;
  final Color tabColor;
  final bool showSelectionIndicator;
  final String? selectionIndicatorText;
  
  const LoteFilterSection({
    super.key,
    required this.selectedMaterial,
    required this.selectedTime,
    this.selectedPresentacion, // Ahora es opcional
    required this.onMaterialChanged,
    required this.onTimeChanged,
    this.onPresentacionChanged, // Ahora es opcional
    required this.tabColor,
    this.showMegaloteFilter = false,
    this.showOnlyMegalotes = false,
    this.onMegaloteFilterToggle,
    this.megaloteCount = 0,
    this.showSelectionIndicator = false,
    this.selectionIndicatorText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Indicador de selección múltiple
          if (showSelectionIndicator && selectionIndicatorText != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: BioWayColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: BioWayColors.info.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: BioWayColors.info,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selectionIndicatorText!,
                      style: TextStyle(
                        fontSize: 13,
                        color: BioWayColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // Filtro de materiales
          SizedBox(
            height: 40,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: ['Todos', 'PEBD', 'PP', 'Multilaminado'].map((material) {
                  final isSelected = selectedMaterial == material;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(material),
                      selected: isSelected,
                      selectedColor: tabColor.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        color: isSelected ? tabColor : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) => onMaterialChanged(material),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Filtros de tiempo y presentación (condicional)
          Row(
            children: [
              Expanded(
                child: _buildDropdownFilter(
                  label: 'Tiempo',
                  value: selectedTime,
                  items: ['Todos', 'Hoy', 'Esta semana', 'Este mes'],
                  onChanged: (value) => onTimeChanged(value!),
                ),
              ),
              // Solo mostrar filtro de presentación si está disponible
              if (selectedPresentacion != null && onPresentacionChanged != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdownFilter(
                    label: 'Presentación',
                    value: selectedPresentacion!,
                    items: ['Todas', 'Pacas', 'Costales', 'Separados', 'Sacos'],
                    onChanged: (value) => onPresentacionChanged!(value!),
                  ),
                ),
              ],
            ],
          ),
          
          // Filtro de megalotes (opcional)
          if (showMegaloteFilter && onMegaloteFilterToggle != null) ...[
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: showOnlyMegalotes 
                  ? Colors.deepPurple.withValues(alpha: 0.1)
                  : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: showOnlyMegalotes 
                    ? Colors.deepPurple.withValues(alpha: 0.3)
                    : Colors.grey[300]!,
                ),
              ),
              child: InkWell(
                onTap: onMegaloteFilterToggle,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.merge_type,
                        size: 20,
                        color: showOnlyMegalotes 
                          ? Colors.deepPurple
                          : Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Mostrar solo Megalotes',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: showOnlyMegalotes 
                            ? FontWeight.bold
                            : FontWeight.normal,
                          color: showOnlyMegalotes 
                            ? Colors.deepPurple
                            : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: showOnlyMegalotes 
                            ? Colors.deepPurple
                            : Colors.grey[400],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$megaloteCount',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildDropdownFilter({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: BioWayColors.backgroundGrey,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: BioWayColors.darkGreen),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 14,
                  color: BioWayColors.darkGreen,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}