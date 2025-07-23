import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../utils/colors.dart';
import '../../../models/bioway/material_reciclable.dart' as bioway_material;
import '../../../config/google_maps_config.dart';

class RecolectorMapaScreen extends StatefulWidget {
  const RecolectorMapaScreen({super.key});

  @override
  State<RecolectorMapaScreen> createState() => _RecolectorMapaScreenState();
}

class _RecolectorMapaScreenState extends State<RecolectorMapaScreen> {
  final List<bioway_material.MaterialReciclable> materiales = bioway_material.MaterialReciclable.materiales;
  final Set<String> selectedFilters = {};
  
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  
  // Posición inicial (Ciudad de México)
  final CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(GoogleMapsConfig.defaultLatitude, GoogleMapsConfig.defaultLongitude),
    zoom: GoogleMapsConfig.defaultZoom,
  );
  
  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }
  
  void _loadMarkers() {
    // Puntos de recolección simulados
    final List<Map<String, dynamic>> puntosRecoleccion = [
      {
        'id': '1',
        'lat': 19.4326,
        'lng': -99.1332,
        'nombre': 'Centro de Acopio Norte',
        'direccion': 'Av. Insurgentes Norte 123',
        'materiales': ['plastico', 'papel', 'vidrio'],
        'cantidad': 45.5,
      },
      {
        'id': '2',
        'lat': 19.4280,
        'lng': -99.1380,
        'nombre': 'Punto Verde Polanco',
        'direccion': 'Horacio 234, Polanco',
        'materiales': ['plastico', 'metal', 'electronico'],
        'cantidad': 32.0,
      },
      {
        'id': '3',
        'lat': 19.4360,
        'lng': -99.1290,
        'nombre': 'Reciclaje Condesa',
        'direccion': 'Amsterdam 567, Condesa',
        'materiales': ['vidrio', 'papel', 'organico'],
        'cantidad': 28.5,
      },
      {
        'id': '4',
        'lat': 19.4250,
        'lng': -99.1350,
        'nombre': 'EcoPunto Roma',
        'direccion': 'Álvaro Obregón 890, Roma Norte',
        'materiales': ['plastico', 'papel', 'metal'],
        'cantidad': 52.0,
      },
      {
        'id': '5',
        'lat': 19.4390,
        'lng': -99.1310,
        'nombre': 'Centro Comunitario Juárez',
        'direccion': 'Bucareli 345, Juárez',
        'materiales': ['organico', 'papel', 'vidrio'],
        'cantidad': 18.5,
      },
    ];
    
    setState(() {
      _markers.clear();
      
      for (final punto in puntosRecoleccion) {
        // Filtrar por materiales seleccionados
        if (selectedFilters.isNotEmpty) {
          final materialesPunto = List<String>.from(punto['materiales']);
          final tieneMatSeleccionado = materialesPunto.any((mat) => selectedFilters.contains(mat));
          if (!tieneMatSeleccionado) continue;
        }
        
        _markers.add(
          Marker(
            markerId: MarkerId(punto['id']),
            position: LatLng(punto['lat'], punto['lng']),
            infoWindow: InfoWindow(
              title: punto['nombre'],
              snippet: '${punto['cantidad']} kg disponibles',
              onTap: () => _showPuntoDetails(punto),
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        );
      }
    });
  }
  
  void _showPuntoDetails(Map<String, dynamic> punto) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                punto['nombre'],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      punto['direccion'],
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Materiales disponibles:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: BioWayColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (punto['materiales'] as List).map((matId) {
                  final material = materiales.firstWhere((m) => m.id == matId);
                  return Chip(
                    label: Text(material.nombre),
                    backgroundColor: material.color.withOpacity(0.2),
                    labelStyle: TextStyle(color: material.color),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: BioWayColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.scale, color: BioWayColors.success),
                    const SizedBox(width: 8),
                    Text(
                      '${punto['cantidad']} kg disponibles para recolectar',
                      style: TextStyle(
                        color: BioWayColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BioWayColors.backgroundGrey,
      body: SafeArea(
        child: Stack(
          children: [
            // Mapa de Google
            GoogleMap(
              initialCameraPosition: _initialPosition,
              onMapCreated: (controller) {
                _mapController = controller;
              },
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),
            
            // Header con filtros
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Puntos de recolección',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: BioWayColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Filtra por tipo de material',
                      style: TextStyle(
                        fontSize: 14,
                        color: BioWayColors.textGrey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Chips de filtros
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Filtro "Todos"
                          _buildFilterChip(
                            label: 'Todos',
                            isSelected: selectedFilters.isEmpty,
                            onTap: () {
                              setState(() {
                                selectedFilters.clear();
                              });
                              _loadMarkers();
                            },
                          ),
                          const SizedBox(width: 8),
                          // Filtros por material
                          ...materiales.map((material) {
                            final isSelected = selectedFilters.contains(material.id);
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _buildFilterChip(
                                label: material.nombre,
                                color: material.color,
                                isSelected: isSelected,
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      selectedFilters.remove(material.id);
                                    } else {
                                      selectedFilters.add(material.id);
                                    }
                                  });
                                  _loadMarkers();
                                },
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Botón de ubicación actual
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  // Centrar en ubicación actual
                  if (_mapController != null) {
                    _mapController!.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        const LatLng(
                          GoogleMapsConfig.defaultLatitude,
                          GoogleMapsConfig.defaultLongitude,
                        ),
                        GoogleMapsConfig.defaultZoom,
                      ),
                    );
                  }
                },
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.my_location,
                  color: BioWayColors.primaryGreen,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? (color ?? BioWayColors.primaryGreen).withOpacity(0.2)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? (color ?? BioWayColors.primaryGreen)
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected 
                ? (color ?? BioWayColors.primaryGreen)
                : BioWayColors.textGrey,
          ),
        ),
      ),
    );
  }
}