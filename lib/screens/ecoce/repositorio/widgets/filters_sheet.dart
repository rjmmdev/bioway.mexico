import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../utils/colors.dart';
import '../../../../utils/format_utils.dart';

class FiltersSheet extends StatefulWidget {
  final String? selectedMaterial;
  final String? selectedTipoActor;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final Function(Map<String, dynamic>) onApplyFilters;
  
  const FiltersSheet({
    super.key,
    this.selectedMaterial,
    this.selectedTipoActor,
    this.fechaInicio,
    this.fechaFin,
    required this.onApplyFilters,
  });

  @override
  State<FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<FiltersSheet> {
  String? _selectedMaterial;
  String? _selectedTipoActor;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  
  final List<String> _materiales = [
    'PET',
    'HDPE', 
    'LDPE',
    'PP',
    'PS',
    'PVC',
    'Multilaminado',
    'Mixto',
  ];
  
  final List<String> _tiposActor = [
    'Acopiador',
    'Planta de Separación',
    'Transportista',
    'Reciclador',
    'Laboratorio',
    'Transformador',
  ];

  @override
  void initState() {
    super.initState();
    _selectedMaterial = widget.selectedMaterial;
    _selectedTipoActor = widget.selectedTipoActor;
    _fechaInicio = widget.fechaInicio;
    _fechaFin = widget.fechaFin;
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
                      _selectedMaterial = null;
                      _selectedTipoActor = null;
                      _fechaInicio = null;
                      _fechaFin = null;
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
                    children: _materiales.map((material) {
                      final isSelected = _selectedMaterial == material;
                      return FilterChip(
                        label: Text(material),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedMaterial = selected ? material : null;
                          });
                          HapticFeedback.lightImpact();
                        },
                        selectedColor: BioWayColors.ecoceGreen.withValues(alpha: 0.2),
                        checkmarkColor: BioWayColors.ecoceGreen,
                        labelStyle: TextStyle(
                          color: isSelected ? BioWayColors.ecoceGreen : Colors.grey[700],
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                
                SizedBox(height: screenWidth * 0.06),
                
                // Actor Type Filter
                _buildFilterSection(
                  title: 'Tipo de Actor',
                  icon: Icons.person,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _tiposActor.map((tipo) {
                      final isSelected = _selectedTipoActor == tipo;
                      return FilterChip(
                        label: Text(tipo),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedTipoActor = selected ? tipo : null;
                          });
                          HapticFeedback.lightImpact();
                        },
                        selectedColor: BioWayColors.ecoceGreen.withValues(alpha: 0.2),
                        checkmarkColor: BioWayColors.ecoceGreen,
                        labelStyle: TextStyle(
                          color: isSelected ? BioWayColors.ecoceGreen : Colors.grey[700],
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                
                SizedBox(height: screenWidth * 0.06),
                
                // Date Range Filter
                _buildFilterSection(
                  title: 'Rango de Fechas',
                  icon: Icons.calendar_today,
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildDateButton(
                          label: 'Desde',
                          date: _fechaInicio,
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _fechaInicio ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: BioWayColors.ecoceGreen,
                                      onPrimary: Colors.white,
                                      onSurface: BioWayColors.darkGreen,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (date != null) {
                              setState(() {
                                _fechaInicio = date;
                              });
                            }
                          },
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.03),
                      Expanded(
                        child: _buildDateButton(
                          label: 'Hasta',
                          date: _fechaFin,
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _fechaFin ?? DateTime.now(),
                              firstDate: _fechaInicio ?? DateTime(2020),
                              lastDate: DateTime.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: BioWayColors.ecoceGreen,
                                      onPrimary: Colors.white,
                                      onSurface: BioWayColors.darkGreen,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (date != null) {
                              setState(() {
                                _fechaFin = date;
                              });
                            }
                          },
                        ),
                      ),
                    ],
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
                        widget.onApplyFilters({
                          'material': _selectedMaterial,
                          'tipoActor': _selectedTipoActor,
                          'fechaInicio': _fechaInicio,
                          'fechaFin': _fechaFin,
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BioWayColors.ecoceGreen,
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
              color: BioWayColors.ecoceGreen,
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

  Widget _buildDateButton({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 20,
              color: date != null ? BioWayColors.ecoceGreen : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    date != null ? FormatUtils.formatDate(date) : 'Seleccionar',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: date != null ? BioWayColors.darkGreen : Colors.grey[400],
                    ),
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