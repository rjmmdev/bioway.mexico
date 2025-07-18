import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../utils/colors.dart';

class FiltersSheet extends StatefulWidget {
  final String? selectedMaterial;
  final String? selectedUbicacion;
  final Function(String?, String?) onApplyFilters;
  
  const FiltersSheet({
    super.key,
    this.selectedMaterial,
    this.selectedUbicacion,
    required this.onApplyFilters,
  });

  @override
  State<FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<FiltersSheet> {
  String? _tempSelectedMaterial;
  String? _tempSelectedUbicacion;
  
  final List<String> _materials = [
    'PET',
    'HDPE',
    'LDPE',
    'PP',
    'PS',
    'PVC',
    'Otros'
  ];
  
  final List<String> _ubicaciones = [
    'Acopiador Norte',
    'Acopiador Sur',
    'Acopiador Este',
    'Acopiador Oeste',
    'Planta de Separación Norte',
    'Planta de Separación Sur',
    'Reciclador Este',
    'Reciclador Oeste',
    'Transformador Norte',
    'Transformador Sur',
    'En Tránsito',
    'Laboratorio Central'
  ];

  @override
  void initState() {
    super.initState();
    _tempSelectedMaterial = widget.selectedMaterial;
    _tempSelectedUbicacion = widget.selectedUbicacion;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Container(
      height: screenHeight * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: EdgeInsets.only(top: screenWidth * 0.03),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filtros',
                  style: TextStyle(
                    fontSize: screenWidth * 0.05,
                    fontWeight: FontWeight.bold,
                    color: BioWayColors.darkGreen,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _tempSelectedMaterial = null;
                      _tempSelectedUbicacion = null;
                    });
                  },
                  child: const Text('Limpiar'),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
              children: [
                // Material Filter
                _buildFilterSection(
                  title: 'Tipo de Material',
                  icon: Icons.category,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _materials.map((material) {
                      final isSelected = _tempSelectedMaterial == material;
                      return FilterChip(
                        label: Text(material),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _tempSelectedMaterial = selected ? material : null;
                          });
                          HapticFeedback.lightImpact();
                        },
                        selectedColor: BioWayColors.primaryGreen.withValues(alpha: 0.2),
                        checkmarkColor: BioWayColors.primaryGreen,
                        labelStyle: TextStyle(
                          color: isSelected ? BioWayColors.primaryGreen : Colors.grey[700],
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                
                SizedBox(height: screenWidth * 0.06),
                
                // Location Filter
                _buildFilterSection(
                  title: 'Ubicación Actual',
                  icon: Icons.location_on,
                  child: Column(
                    children: _ubicaciones.map((ubicacion) {
                      final isSelected = _tempSelectedUbicacion == ubicacion;
                      return RadioListTile<String>(
                        title: Text(
                          ubicacion,
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        value: ubicacion,
                        groupValue: _tempSelectedUbicacion,
                        onChanged: (value) {
                          setState(() {
                            _tempSelectedUbicacion = value;
                          });
                          HapticFeedback.lightImpact();
                        },
                        activeColor: BioWayColors.primaryGreen,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom Buttons
          Container(
            padding: EdgeInsets.all(screenWidth * 0.04),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: Colors.grey[400]!,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.04),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        widget.onApplyFilters(
                          _tempSelectedMaterial,
                          _tempSelectedUbicacion,
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BioWayColors.primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Aplicar',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: BioWayColors.primaryGreen,
              size: 20,
            ),
            SizedBox(width: screenWidth * 0.02),
            Text(
              title,
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.bold,
                color: BioWayColors.darkGreen,
              ),
            ),
          ],
        ),
        SizedBox(height: screenWidth * 0.03),
        child,
      ],
    );
  }
}