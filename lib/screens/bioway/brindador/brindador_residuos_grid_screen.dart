import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import '../../../models/bioway/material_reciclable.dart' as bioway_material;
import 'brindador_tirar_screen.dart';

class BrindadorResiduosGridScreen extends StatefulWidget {
  final String selectedCantMin;

  const BrindadorResiduosGridScreen({
    super.key,
    required this.selectedCantMin,
  });

  @override
  State<BrindadorResiduosGridScreen> createState() => _BrindadorResiduosGridScreenState();
}

class _BrindadorResiduosGridScreenState extends State<BrindadorResiduosGridScreen> {
  final List<bioway_material.MaterialReciclable> materiales = bioway_material.MaterialReciclable.materiales;
  final Map<String, double> selectedMaterials = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BioWayColors.backgroundGrey,
      appBar: AppBar(
        title: const Text('Selecciona tus Residuos'),
        backgroundColor: BioWayColors.primaryGreen,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: BioWayColors.primaryGreen.withValues(alpha:0.1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: BioWayColors.primaryGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Cantidad mínima: ${widget.selectedCantMin}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: BioWayColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Selecciona los materiales que deseas brindar',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Grid de materiales
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: materiales.length,
                itemBuilder: (context, index) {
                  final material = materiales[index];
                  final isSelected = selectedMaterials.containsKey(material.id);
                  
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        if (isSelected) {
                          selectedMaterials.remove(material.id);
                        } else {
                          // Por defecto asignar cantidad mínima
                          // Extraer solo el número de la cadena "1 kg mínimo"
                          final cantidadStr = widget.selectedCantMin.split(' ').first;
                          selectedMaterials[material.id] = double.tryParse(cantidadStr) ?? 1.0;
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? material.color.withValues(alpha:0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected 
                              ? material.color 
                              : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: material.color.withValues(alpha:0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha:0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icono placeholder
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: material.color.withValues(alpha:0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getIconForMaterial(material.id),
                              color: material.color,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            material.nombre,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isSelected 
                                  ? material.color 
                                  : BioWayColors.textGrey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${material.puntosPerKg} pts/kg',
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected 
                                  ? material.color.withValues(alpha:0.8)
                                  : Colors.grey.shade600,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(height: 8),
                            Icon(
                              Icons.check_circle,
                              color: material.color,
                              size: 20,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Botón continuar
          Container(
            padding: const EdgeInsets.all(20),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedMaterials.isNotEmpty
                      ? () {
                          HapticFeedback.mediumImpact();
                          _showConfirmationDialog();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BioWayColors.primaryGreen,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: Text(
                    selectedMaterials.isNotEmpty
                        ? 'Continuar (${selectedMaterials.length} seleccionados)'
                        : 'Selecciona al menos un material',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForMaterial(String materialId) {
    switch (materialId) {
      case 'plastico':
        return Icons.local_drink;
      case 'vidrio':
        return Icons.wine_bar;
      case 'papel':
        return Icons.description;
      case 'metal':
        return Icons.recycling;
      case 'organico':
        return Icons.compost;
      case 'electronico':
        return Icons.devices;
      default:
        return Icons.recycling;
    }
  }

  void _showConfirmationDialog() {
    // Extraer solo el número de la cantidad mínima
    final cantidadStr = widget.selectedCantMin.split(' ').first;
    final cantidadMinima = double.tryParse(cantidadStr) ?? 1.0;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.info,
                color: BioWayColors.info,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Confirmación de cantidad',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Para brindar los materiales seleccionados, debes tener al menos ${cantidadMinima.toStringAsFixed(0)} kg de cada uno.',
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: BioWayColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: BioWayColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: BioWayColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Al continuar, confirmas que tienes la cantidad mínima requerida.',
                        style: TextStyle(
                          fontSize: 14,
                          color: BioWayColors.warning,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Materiales seleccionados:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...selectedMaterials.entries.map((entry) {
                final material = materiales.firstWhere((m) => m.id == entry.key);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: material.color,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${material.nombre}: ${entry.value} kg mínimo',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navegar a la pantalla de Tirar
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BrindadorTirarScreen(
                      selectedMaterials: selectedMaterials,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: BioWayColors.primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Confirmar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}