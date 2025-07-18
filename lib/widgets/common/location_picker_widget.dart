import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../config/google_maps_config.dart';
import '../../utils/colors.dart';

class LocationPickerWidget extends StatefulWidget {
  final Function(LatLng, String) onLocationSelected;
  final LatLng? initialLocation;
  final String? initialAddress;
  final String title;
  final bool showSearchBar;

  const LocationPickerWidget({
    super.key,
    required this.onLocationSelected,
    this.initialLocation,
    this.initialAddress,
    this.title = 'Seleccionar Ubicación',
    this.showSearchBar = true,
  });

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  String _selectedAddress = '';
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _selectedLocation = widget.initialLocation;
      _selectedAddress = widget.initialAddress ?? '';
      _updateMarker(_selectedLocation!);
    } else {
      _getCurrentLocation();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _selectedLocation = LatLng(
          GoogleMapsConfig.defaultLatitude,
          GoogleMapsConfig.defaultLongitude,
        );
      } else {
        Position position = await Geolocator.getCurrentPosition();
        _selectedLocation = LatLng(position.latitude, position.longitude);
      }

      _updateMarker(_selectedLocation!);
      _getAddressFromLatLng(_selectedLocation!);
      
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(_selectedLocation!),
        );
      }
    } catch (e) {
      _selectedLocation = LatLng(
        GoogleMapsConfig.defaultLatitude,
        GoogleMapsConfig.defaultLongitude,
      );
      _updateMarker(_selectedLocation!);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _selectedAddress = '${place.street ?? ''}, '
              '${place.subLocality ?? ''}, '
              '${place.locality ?? ''}, '
              '${place.administrativeArea ?? ''} '
              '${place.postalCode ?? ''}';
          _selectedAddress = _selectedAddress.replaceAll('  ', ' ').trim();
          if (_selectedAddress.endsWith(',')) {
            _selectedAddress = _selectedAddress.substring(0, _selectedAddress.length - 1);
          }
        });
      }
    } catch (e) {
      setState(() {
        _selectedAddress = 'Lat: ${position.latitude.toStringAsFixed(6)}, '
            'Lng: ${position.longitude.toStringAsFixed(6)}';
      });
    }
  }

  Future<void> _searchLocation() async {
    if (_searchController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      List<Location> locations = await locationFromAddress(_searchController.text);
      
      if (locations.isNotEmpty) {
        Location location = locations.first;
        LatLng newLocation = LatLng(location.latitude, location.longitude);
        
        setState(() {
          _selectedLocation = newLocation;
        });
        
        _updateMarker(newLocation);
        _getAddressFromLatLng(newLocation);
        
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(newLocation, GoogleMapsConfig.defaultZoom),
        );
      } else {
        _showSnackBar('No se encontraron resultados para esta búsqueda');
      }
    } catch (e) {
      _showSnackBar('Error al buscar la ubicación');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateMarker(LatLng position) {
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('selected_location'),
          position: position,
          infoWindow: InfoWindow(
            title: 'Ubicación seleccionada',
            snippet: _selectedAddress,
          ),
        ),
      );
    });
  }

  void _onMapTapped(LatLng position) {
    setState(() {
      _selectedLocation = position;
    });
    _updateMarker(position);
    _getAddressFromLatLng(position);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: BioWayColors.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
            tooltip: 'Mi ubicación',
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation ?? LatLng(
                GoogleMapsConfig.defaultLatitude,
                GoogleMapsConfig.defaultLongitude,
              ),
              zoom: GoogleMapsConfig.defaultZoom,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              if (_selectedLocation != null) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLng(_selectedLocation!),
                  );
                });
              }
            },
            onTap: _onMapTapped,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            mapToolbarEnabled: true,
            minMaxZoomPreference: MinMaxZoomPreference(
              GoogleMapsConfig.minZoom,
              GoogleMapsConfig.maxZoom,
            ),
          ),
          if (widget.showSearchBar)
            Positioned(
              top: screenHeight * 0.02,
              left: screenWidth * 0.04,
              right: screenWidth * 0.04,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Buscar dirección...',
                            border: InputBorder.none,
                            hintStyle: TextStyle(
                              fontSize: screenWidth * 0.04,
                            ),
                          ),
                          onSubmitted: (_) => _searchLocation(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _searchLocation,
                        color: BioWayColors.primaryGreen,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_selectedAddress.isNotEmpty)
            Positioned(
              bottom: screenHeight * 0.12,
              left: screenWidth * 0.04,
              right: screenWidth * 0.04,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                ),
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dirección seleccionada:',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      Text(
                        _selectedAddress,
                        style: TextStyle(fontSize: screenWidth * 0.035),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      floatingActionButton: _selectedLocation != null
          ? FloatingActionButton.extended(
              onPressed: () {
                widget.onLocationSelected(_selectedLocation!, _selectedAddress);
                Navigator.of(context).pop();
              },
              label: const Text('Confirmar ubicación'),
              icon: const Icon(Icons.check),
              backgroundColor: BioWayColors.primaryGreen,
              foregroundColor: Colors.white,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}