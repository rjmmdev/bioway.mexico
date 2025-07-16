// Archivo: widgets/material_selector.dart
import 'package:flutter/material.dart';
import '../../../../utils/colors.dart';

class MaterialSelector extends StatelessWidget {
  final Set<String> selectedMaterials;
  final Function(String) onMaterialToggle;

  const MaterialSelector({
    super.key,
    required this.selectedMaterials,
    required this.onMaterialToggle,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BioWayColors.lightGrey.withOpacity(0.3),
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
            children: _materials.map((material) {
              return MaterialItem(
                material: material,
                isSelected: selectedMaterials.contains(material['id']),
                onTap: () => onMaterialToggle(material['id']),
              );
            }).toList(),
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
          color: isSelected ? material['color'].withOpacity(0.1) : Colors.white,
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