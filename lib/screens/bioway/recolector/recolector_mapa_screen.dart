import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import '../../../models/bioway/residuo.dart';

class RecolectorMapaScreen extends StatefulWidget {
  final List<Residuo> residuosDisponibles;
  
  const RecolectorMapaScreen({
    super.key,
    required this.residuosDisponibles,
  });

  @override
  State<RecolectorMapaScreen> createState() => _RecolectorMapaScreenState();
}

class _RecolectorMapaScreenState extends State<RecolectorMapaScreen> {
  String? _selectedMaterial;
  double _radioKm = 5.0;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BioWayColors.backgroundGrey,
      appBar: AppBar(
        title: const Text('Mapa de Residuos'),
        backgroundColor: BioWayColors.primaryGreen,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Placeholder del mapa
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey.shade200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Mapa de Google Maps',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Configuración pendiente',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Lista de residuos en la parte inferior
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 250,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Título
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${widget.residuosDisponibles.length} residuos disponibles',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: BioWayColors.primaryGreen.withValues(alpha:0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Radio: ${_radioKm.toStringAsFixed(0)} km',
                            style: TextStyle(
                              color: BioWayColors.primaryGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Lista horizontal de residuos
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: widget.residuosDisponibles.length,
                      itemBuilder: (context, index) {
                        final residuo = widget.residuosDisponibles[index];
                        return _buildResiduoMapCard(residuo);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          
          // Botón de centrar ubicación
          Positioned(
            right: 16,
            bottom: 280,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              foregroundColor: BioWayColors.primaryGreen,
              onPressed: _centerLocation,
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildResiduoMapCard(Residuo residuo) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showResiduoDetail(residuo),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    residuo.brindadorNombre ?? 'Usuario',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: BioWayColors.primaryGreen.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.directions,
                      color: BioWayColors.primaryGreen,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Materiales
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: residuo.materiales.entries.map((entry) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getMaterialColor(entry.key).withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${entry.key}: ${entry.value} kg',
                      style: TextStyle(
                        color: _getMaterialColor(entry.key),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Spacer(),
              // Footer
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      residuo.direccion,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.monetization_on,
                        color: BioWayColors.primaryGreen,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${residuo.puntosEstimados} pts',
                        style: TextStyle(
                          color: BioWayColors.primaryGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '~1.2 km',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getMaterialColor(String material) {
    switch (material.toLowerCase()) {
      case 'plastico':
        return const Color(0xFF4CAF50);
      case 'vidrio':
        return const Color(0xFF2196F3);
      case 'papel':
        return const Color(0xFF795548);
      case 'metal':
        return const Color(0xFF9E9E9E);
      case 'organico':
        return const Color(0xFF8BC34A);
      case 'electronico':
        return const Color(0xFF607D8B);
      default:
        return Colors.grey;
    }
  }
  
  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Título
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Filtrar Residuos',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(height: 1),
            // Contenido
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filtro por material
                    const Text(
                      'Tipo de Material',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildMaterialChip('Todos', null),
                        _buildMaterialChip('Plástico', 'plastico'),
                        _buildMaterialChip('Vidrio', 'vidrio'),
                        _buildMaterialChip('Papel', 'papel'),
                        _buildMaterialChip('Metal', 'metal'),
                        _buildMaterialChip('Orgánico', 'organico'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Filtro por distancia
                    const Text(
                      'Distancia Máxima',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _radioKm,
                            min: 1,
                            max: 20,
                            divisions: 19,
                            activeColor: BioWayColors.primaryGreen,
                            label: '${_radioKm.toStringAsFixed(0)} km',
                            onChanged: (value) {
                              setState(() {
                                _radioKm = value;
                              });
                            },
                          ),
                        ),
                        Text(
                          '${_radioKm.toStringAsFixed(0)} km',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: BioWayColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Botón aplicar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // TODO: Aplicar filtros
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BioWayColors.primaryGreen,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Aplicar Filtros',
                          style: TextStyle(
                            fontSize: 16,
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
      ),
    );
  }
  
  Widget _buildMaterialChip(String label, String? value) {
    final isSelected = _selectedMaterial == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMaterial = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? BioWayColors.primaryGreen 
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
  
  void _centerLocation() {
    // TODO: Implementar centrado en ubicación actual
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Centrando en tu ubicación...'),
        backgroundColor: BioWayColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
  
  void _showResiduoDetail(Residuo residuo) {
    // TODO: Mostrar detalle del residuo
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mostrando detalles de ${residuo.id}'),
        backgroundColor: BioWayColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}