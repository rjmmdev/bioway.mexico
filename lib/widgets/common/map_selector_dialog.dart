import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import '../../utils/colors.dart';
import '../../utils/ui_constants.dart';

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
  Map<String, String>? _addressComponents;
  bool _isLoadingAddress = false;

  _MapSelectorDialogState() : _currentPosition = LatLng(0, 0);

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.initialPosition;
    // Trigger initial geocoding after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getAddressFromLatLng();
    });
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
    _getAddressFromLatLng();
  }

  Future<void> _getAddressFromLatLng() async {
    setState(() {
      _isLoadingAddress = true;
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _currentPosition.latitude,
        _currentPosition.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        
        // Separar calle y número exterior
        String streetFull = place.street ?? '';
        String streetName = '';
        String streetNumber = '';
        
        // Patrones comunes para detectar números en direcciones
        // Busca números al final de la cadena (más común en México)
        // Captura números como: 123, 123A, 123-A, 123 A, S/N
        final RegExp regExpEndNumber = RegExp(r'(.+?)\s+(\d+[\s-]?[A-Za-z]?|S\/N|s\/n)$');
        // Busca números al principio (formato anglosajón)
        final RegExp regExpStartNumber = RegExp(r'^(\d+[\s-]?[A-Za-z]?)\s+(.+)$');
        
        if (regExpEndNumber.hasMatch(streetFull)) {
          // Número al final (más común en México)
          final match = regExpEndNumber.firstMatch(streetFull);
          streetName = match?.group(1)?.trim() ?? '';
          streetNumber = match?.group(2)?.trim() ?? '';
        } else if (regExpStartNumber.hasMatch(streetFull)) {
          // Número al principio
          final match = regExpStartNumber.firstMatch(streetFull);
          streetNumber = match?.group(1)?.trim() ?? '';
          streetName = match?.group(2)?.trim() ?? '';
        } else {
          // No se encontró un patrón claro, usar la calle completa
          streetName = streetFull;
        }
        
        setState(() {
          _addressComponents = {
            'calle': streetName,
            'numero_exterior': streetNumber,
            'colonia': place.subLocality ?? '',
            'municipio': place.locality ?? '',
            'estado': place.administrativeArea ?? '',
            'cp': place.postalCode ?? '',
            'pais': place.country ?? '',
          };
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingAddress = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(UIConstants.spacing20),
      child: Container(
        width: screenWidth * 0.9,
        height: screenHeight * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadiusConstants.borderRadiusXLarge,
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsetsConstants.paddingAll20,
              decoration: BoxDecoration(
                color: BioWayColors.primaryGreen,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(UIConstants.spacing20),
                  topRight: Radius.circular(UIConstants.spacing20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Colors.white,
                    size: UIConstants.iconSizeMedium,
                  ),
                  SizedBox(width: UIConstants.spacing12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: UIConstants.fontSizeLarge,
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
              padding: EdgeInsets.symmetric(horizontal: UIConstants.spacing20, vertical: UIConstants.spacing12),
              color: BioWayColors.lightGreen.withValues(alpha: UIConstants.opacityVeryLow),
              child: Row(
                children: [
                  Icon(
                    Icons.touch_app,
                    color: BioWayColors.primaryGreen,
                    size: UIConstants.iconSizeBody,
                  ),
                  SizedBox(width: UIConstants.spacing8),
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
                      zoom: UIConstants.mapZoomDefault,
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
                          duration: Duration(milliseconds: UIConstants.animationDurationShort),
                          transform: Matrix4.translationValues(
                            0,
                            _isMoving ? -UIConstants.spacing10 : 0,
                            0,
                          ),
                          child: Icon(
                            Icons.location_on,
                            size: UIConstants.iconSizeDialog,
                            color: BioWayColors.error,
                            shadows: [
                              Shadow(
                                blurRadius: UIConstants.blurRadiusMedium,
                                color: Colors.black.withValues(alpha: 0.3),
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                        ),
                        // Sombra del marcador
                        AnimatedContainer(
                          duration: Duration(milliseconds: UIConstants.animationDurationShort),
                          width: _isMoving ? UIConstants.spacing15 : UIConstants.spacing10,
                          height: UIConstants.spacing4,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: UIConstants.opacityLow),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Información de coordenadas y dirección
                  Positioned(
                    top: UIConstants.spacing10,
                    left: UIConstants.spacing10,
                    right: UIConstants.spacing10,
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsetsConstants.paddingAll12,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: UIConstants.opacityVeryHigh),
                            borderRadius: BorderRadiusConstants.borderRadiusMedium,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: UIConstants.opacityVeryLow),
                                blurRadius: UIConstants.blurRadiusSmall,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.gps_fixed,
                                size: UIConstants.iconSizeSmall,
                                color: BioWayColors.darkGreen,
                              ),
                              SizedBox(width: UIConstants.spacing8),
                              Expanded(
                                child: Text(
                                  'Lat: ${_currentPosition.latitude.toStringAsFixed(6)}, '
                                  'Lng: ${_currentPosition.longitude.toStringAsFixed(6)}',
                                  style: TextStyle(
                                    fontSize: UIConstants.fontSizeSmall,
                                    color: BioWayColors.darkGreen,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_addressComponents != null) ...[
                          SizedBox(height: UIConstants.spacing8),
                          Container(
                            padding: EdgeInsetsConstants.paddingAll12,
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
                            child: _isLoadingAddress
                                ? Center(
                                    child: SizedBox(
                                      width: UIConstants.iconSizeBody,
                                      height: UIConstants.iconSizeBody,
                                      child: CircularProgressIndicator(
                                        strokeWidth: UIConstants.borderWidthMedium,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          BioWayColors.primaryGreen,
                                        ),
                                      ),
                                    ),
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            size: UIConstants.iconSizeSmall,
                                            color: BioWayColors.darkGreen,
                                          ),
                                          SizedBox(width: UIConstants.spacing8),
                                          Text(
                                            'Dirección detectada:',
                                            style: TextStyle(
                                              fontSize: UIConstants.fontSizeSmall,
                                              fontWeight: FontWeight.bold,
                                              color: BioWayColors.darkGreen,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: UIConstants.spacing4),
                                      Text(
                                        '${_addressComponents!['calle']}, ${_addressComponents!['colonia']}, '
                                        '${_addressComponents!['municipio']}, ${_addressComponents!['estado']} '
                                        '${_addressComponents!['cp']}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: BioWayColors.textGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Botones
            Container(
              padding: EdgeInsetsConstants.paddingAll20,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(UIConstants.spacing20),
                  bottomRight: Radius.circular(UIConstants.spacing20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: UIConstants.spacing16),
                        side: BorderSide(color: BioWayColors.textGrey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadiusConstants.borderRadiusMedium,
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
                  SizedBox(width: UIConstants.spacing16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop({
                          'position': _currentPosition,
                          'addressComponents': _addressComponents,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BioWayColors.primaryGreen,
                        padding: EdgeInsets.symmetric(vertical: UIConstants.spacing16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadiusConstants.borderRadiusMedium,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check, color: Colors.white),
                          SizedBox(width: UIConstants.spacing8),
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