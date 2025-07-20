// Archivo: widgets/material_selector.dart
import 'package:flutter/material.dart';
import '../../../../utils/colors.dart';
import '../../../ecoce/shared/utils/material_utils.dart';

class MaterialSelector extends StatelessWidget {
  final Set<String> selectedMaterials;
  final Function(String) onMaterialToggle;
  final List<Map<String, String>>? customMaterials;

  const MaterialSelector({
    super.key,
    required this.selectedMaterials,
    required this.onMaterialToggle,
    this.customMaterials,
  });

  static const List<Map<String, dynamic>> _materials = [
    {'id': 'pe_limpio', 'name': 'PE Limpio', 'color': BioWayColors.petBlue, 'desc': 'Polietileno sin contaminación'},
    {'id': 'pe_sucio', 'name': 'PE Sucio', 'color': BioWayColors.info, 'desc': 'Polietileno con residuos'},
    {'id': 'multicapa_pe_pp', 'name': 'Multicapa PE/PP', 'color': BioWayColors.ppOrange, 'desc': 'Laminados PE/PP'},
    {'id': 'multicapa_pe_pet', 'name': 'Multicapa PE/PET', 'color': BioWayColors.warning, 'desc': 'Laminados PE/PET'},
    {'id': 'multicapa_pe_pa', 'name': 'Multicapa PE/PA', 'color': BioWayColors.otherPurple, 'desc': 'PE/Poliamida'},
    {'id': 'multicapa_pe_evoh', 'name': 'Multicapa PE/EVOH', 'color': BioWayColors.deepGreen, 'desc': 'Barrera de oxígeno'},
    {'id': 'bopp', 'name': 'BOPP', 'color': BioWayColors.hdpeGreen, 'desc': 'Polipropileno biorientado'},
    {'id': 'cpp', 'name': 'CPP', 'color': BioWayColors.success, 'desc': 'Polipropileno cast'},
    {'id': 'ldpe', 'name': 'LDPE', 'color': BioWayColors.turquoise, 'desc': 'Polietileno baja densidad'},
    {'id': 'hdpe', 'name': 'HDPE', 'color': BioWayColors.ecoceGreen, 'desc': 'Polietileno alta densidad'},
    {'id': 'lldpe', 'name': 'LLDPE', 'color': BioWayColors.primaryGreen, 'desc': 'PE lineal baja densidad'},
    {'id': 'metalizado', 'name': 'Film Metalizado', 'color': BioWayColors.metalGrey, 'desc': 'Con capa de aluminio'},
    {'id': 'stretch', 'name': 'Stretch Film', 'color': BioWayColors.darkGrey, 'desc': 'Film estirable'},
    {'id': 'termoencogible', 'name': 'Termoencogible', 'color': BioWayColors.error, 'desc': 'Film retráctil'},
  ];
  
  List<Widget> _buildMaterialItems() {
    // Use custom materials if provided, otherwise use default
    if (customMaterials != null && customMaterials!.isNotEmpty) {
      return customMaterials!.map((material) {
        // Convert custom material format to match MaterialItem expectations
        final materialData = {
          'id': material['id'],
          'name': material['label'] ?? material['id'],
          'color': _getColorForMaterial(material['id'] ?? ''),
          'desc': '', // Custom materials don't have descriptions
        };
        return MaterialItem(
          material: materialData,
          isSelected: selectedMaterials.contains(material['id']),
          onTap: () => onMaterialToggle(material['id'] ?? ''),
        );
      }).toList();
    }
    
    // Use default materials
    return _materials.map((material) {
      return MaterialItem(
        material: material,
        isSelected: selectedMaterials.contains(material['id']),
        onTap: () => onMaterialToggle(material['id']),
      );
    }).toList();
  }
  
  Color _getColorForMaterial(String materialId) {
    // Try to use MaterialUtils first
    final color = MaterialUtils.getMaterialColor(materialId.toUpperCase());
    
    // If MaterialUtils returns default grey, use custom logic for special cases
    if (color == BioWayColors.darkGrey) {
      // Assign colors based on material type for custom materials
      if (materialId.contains('poli') || materialId.contains('pe')) {
        return BioWayColors.petBlue;
      } else if (materialId.contains('pp')) {
        return BioWayColors.ppOrange;
      } else if (materialId.contains('multi')) {
        return BioWayColors.warning;
      } else if (materialId.contains('pellets')) {
        return BioWayColors.success;
      } else if (materialId.contains('hojuelas')) {
        return BioWayColors.hdpeGreen;
      } else if (materialId.contains('muestra')) {
        return BioWayColors.info;
      } else {
        return BioWayColors.primaryGreen;
      }
    }
    
    return color;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BioWayColors.lightGrey.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BioWayColors.lightGrey, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.recycling, color: BioWayColors.petBlue, size: 24),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Materiales EPF\'s que recibes *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: BioWayColors.darkGreen,
                      ),
                    ),
                    Text(
                      'Empaques Plásticos Flexibles postconsumo',
                      style: TextStyle(fontSize: 12, color: BioWayColors.textGrey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Selecciona todos los tipos de materiales flexibles que acopias',
            style: TextStyle(fontSize: 14, color: BioWayColors.textGrey),
          ),
          const SizedBox(height: 16),

          // Grid de materiales usando Wrap para mejor responsive
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _buildMaterialItems(),
          ),
        ],
      ),
    );
  }
}

class MaterialItem extends StatelessWidget {
  final Map<String, dynamic> material;
  final bool isSelected;
  final VoidCallback onTap;

  const MaterialItem({
    super.key,
    required this.material,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? (material['color'] as Color).withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? material['color'] : BioWayColors.lightGrey,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: material['color'], width: 2),
                color: isSelected ? material['color'] : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    material['name'],
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? material['color'] : BioWayColors.darkGreen,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    material['desc'],
                    style: const TextStyle(
                      fontSize: 10,
                      color: BioWayColors.textGrey,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}