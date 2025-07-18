import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../utils/colors.dart';

class MapSelectorDialog extends StatefulWidget {
  final LatLng initialPosition;
  final String title;

  const MapSelectorDialog({
    super.key,
    required this.initialPosition,
    this.title = 'Ajustar ubicación exacta',
  });

  @override
  State<MapSelectorDialog> createState() => _MapSelectorDialogState();
}

class _MapSelectorDialogState extends State<MapSelectorDialog> {
  GoogleMapController? _mapController;
  LatLng _currentPosition;
  bool _isMoving = false;

  _MapSelectorDialogState() : _currentPosition = LatLng(0, 0);

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.initialPosition;
  }

  void _onCameraMove(CameraPosition position) {
    setState(() {
      _currentPosition = position.target;
      _isMoving = true;
    });
  }

  void _onCameraIdle() {
    setState(() {
      _isMoving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(20),
      child: Container(
        width: screenWidth * 0.9,
        height: screenHeight * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: BioWayColors.primaryGreen,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Colors.white,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            
            // Instrucciones
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: BioWayColors.lightGreen.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(
                    Icons.touch_app,
                    color: BioWayColors.primaryGreen,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mueve el mapa para posicionar el marcador en tu ubicación exacta',
                      style: TextStyle(
                        fontSize: 13,
                        color: BioWayColors.darkGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Mapa
            Expanded(
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: widget.initialPosition,
                      zoom: 17.0,
                    ),
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                    onCameraMove: _onCameraMove,
                    onCameraIdle: _onCameraIdle,
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: true,
                    mapToolbarEnabled: false,
                    compassEnabled: true,
                  ),
                  
                  // Marcador fijo en el centro
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          transform: Matrix4.translationValues(
                            0,
                            _isMoving ? -10 : 0,
                            0,
                          ),
                          child: Icon(
                            Icons.location_on,
                            size: 50,
                            color: BioWayColors.error,
                            shadows: [
                              Shadow(
                                blurRadius: 12,
                                color: Colors.black.withValues(alpha: 0.3),
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                        ),
                        // Sombra del marcador
                        AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          width: _isMoving ? 15 : 10,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Información de coordenadas
                  Positioned(
                    top: 10,
                    left: 10,
                    right: 10,
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.gps_fixed,
                            size: 16,
                            color: BioWayColors.darkGreen,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Lat: ${_currentPosition.latitude.toStringAsFixed(6)}, '
                              'Lng: ${_currentPosition.longitude.toStringAsFixed(6)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: BioWayColors.darkGreen,
                                fontFamily: 'monospace',
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
            
            // Botones
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: BioWayColors.textGrey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: BioWayColors.textGrey,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(_currentPosition);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BioWayColors.primaryGreen,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Confirmar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
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

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}