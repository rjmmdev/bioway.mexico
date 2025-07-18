import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import '../../config/google_maps_config.dart';
import '../../utils/colors.dart';
import 'map_selector_dialog.dart';

class SimpleMapWidget extends StatefulWidget {
  final String? estado;
  final String? municipio;
  final String? colonia;
  final String? codigoPostal;
  final Function(LatLng) onLocationSelected;
  final LatLng? initialLocation;

  const SimpleMapWidget({
    super.key,
    this.estado,
    this.municipio,
    this.colonia,
    this.codigoPostal,
    required this.onLocationSelected,
    this.initialLocation,
  });

  @override
  State<SimpleMapWidget> createState() => _SimpleMapWidgetState();
}

class _SimpleMapWidgetState extends State<SimpleMapWidget> {
  LatLng? _selectedPosition;
  bool _isSearching = false;
  String? _errorMessage;
  String? _selectedAddress;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _selectedPosition = widget.initialLocation!;
    }
  }

  Future<void> searchAddress() async {
    // Verificar que al menos haya algún dato
    if ((widget.estado?.isEmpty ?? true) && 
        (widget.municipio?.isEmpty ?? true) && 
        (widget.colonia?.isEmpty ?? true) && 
        (widget.codigoPostal?.isEmpty ?? true)) {
      setState(() {
        _errorMessage = 'Ingresa al menos un dato de ubicación';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      // Construir la dirección de búsqueda
      String searchQuery = '';
      if (widget.colonia?.isNotEmpty ?? false) searchQuery += '${widget.colonia}, ';
      if (widget.municipio?.isNotEmpty ?? false) searchQuery += '${widget.municipio}, ';
      if (widget.estado?.isNotEmpty ?? false) searchQuery += '${widget.estado}, ';
      if (widget.codigoPostal?.isNotEmpty ?? false) searchQuery += '${widget.codigoPostal}, ';
      searchQuery += 'México';

      // Buscar la ubicación
      List<Location> locations = await locationFromAddress(searchQuery);
      
      if (locations.isNotEmpty) {
        Location location = locations.first;
        LatLng initialPosition = LatLng(location.latitude, location.longitude);
        
        setState(() {
          _isSearching = false;
        });
        
        // Abrir el diálogo del mapa
        final LatLng? result = await showDialog<LatLng>(
          context: context,
          barrierDismissible: false,
          builder: (context) => MapSelectorDialog(
            initialPosition: initialPosition,
            title: 'Ajusta tu ubicación exacta',
          ),
        );
        
        if (result != null) {
          setState(() {
            _selectedPosition = result;
            _selectedAddress = '${widget.colonia ?? ''}, ${widget.municipio ?? ''}, ${widget.estado ?? ''}';
          });
          
          // Notificar la ubicación seleccionada
          widget.onLocationSelected(result);
        }
      } else {
        setState(() {
          _errorMessage = 'No se encontró la ubicación. Intenta con datos más específicos.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al buscar la ubicación. Verifica los datos ingresados.';
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Botón para generar mapa
        ElevatedButton.icon(
          onPressed: _isSearching ? null : searchAddress,
          icon: _isSearching 
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(Icons.map),
          label: Text(_isSearching ? 'Buscando...' : _selectedPosition != null ? 'Cambiar ubicación' : 'Generar mapa'),
          style: ElevatedButton.styleFrom(
            backgroundColor: BioWayColors.primaryGreen,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        
        if (_errorMessage != null) ...[
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: BioWayColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: BioWayColors.error.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: BioWayColors.error,
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: BioWayColors.error,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        
        if (_selectedPosition != null) ...[
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: BioWayColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: BioWayColors.success.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: BioWayColors.success,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Ubicación seleccionada',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: BioWayColors.darkGreen,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  _selectedAddress ?? '',
                  style: TextStyle(
                    color: BioWayColors.darkGreen,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Lat: ${_selectedPosition!.latitude.toStringAsFixed(6)}, Lng: ${_selectedPosition!.longitude.toStringAsFixed(6)}',
                  style: TextStyle(
                    color: BioWayColors.textGrey,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}