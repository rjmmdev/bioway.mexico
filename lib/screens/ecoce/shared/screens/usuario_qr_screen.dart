import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import '../../../../utils/colors.dart';
import '../../../../utils/format_utils.dart';
import '../../../../services/user_session_service.dart';
import '../../../../services/firebase/auth_service.dart';
import '../widgets/ecoce_bottom_navigation.dart';
import 'receptor_escanear_entrega_screen.dart';

class UsuarioQRScreen extends StatefulWidget {
  final String userType; // 'reciclador', 'laboratorio', 'transformador'
  final bool isReceivingFlow; // Indica si es parte del flujo de recepción
  
  const UsuarioQRScreen({
    super.key,
    required this.userType,
    this.isReceivingFlow = false,
  });

  @override
  State<UsuarioQRScreen> createState() => _UsuarioQRScreenState();
}

class _UsuarioQRScreenState extends State<UsuarioQRScreen> {
  final UserSessionService _userSession = UserSessionService();
  final AuthService _authService = AuthService();
  String? _qrData;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _generateUserQR();
  }
  
  void _generateUserQR() async {
    final userData = _userSession.getUserData();
    final userProfile = await _userSession.getUserProfile();
    final currentUser = _authService.currentUser;
    
    if (currentUser != null && userData != null) {
      // Generar QR con información del usuario
      final userId = currentUser.uid;
      
      // Convertir a string para el QR
      setState(() {
        _qrData = 'USER-${widget.userType.toUpperCase()}-$userId';
        _isLoading = false;
      });
    }
  }
  
  Color get _primaryColor {
    switch (widget.userType) {
      case 'reciclador':
        return BioWayColors.primaryGreen;
      case 'laboratorio':
        return BioWayColors.petBlue;
      case 'transformador':
        return BioWayColors.ppPurple;
      default:
        return BioWayColors.primaryGreen;
    }
  }
  
  IconData get _userIcon {
    switch (widget.userType) {
      case 'reciclador':
        return Icons.recycling;
      case 'laboratorio':
        return Icons.science;
      case 'transformador':
        return Icons.precision_manufacturing;
      default:
        return Icons.person;
    }
  }
  
  String get _userTypeLabel {
    switch (widget.userType) {
      case 'reciclador':
        return 'Reciclador';
      case 'laboratorio':
        return 'Laboratorio';
      case 'transformador':
        return 'Transformador';
      default:
        return 'Usuario';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final userData = _userSession.getUserData();
    final currentUser = _authService.currentUser;
    final userId = currentUser?.uid ?? 'Sin ID';
    final userName = userData?['nombre'] ?? 'Usuario';
    final userFolio = userData?['folio'] ?? 'Sin folio';
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: _primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Mi Código QR',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header con información del usuario
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _primaryColor,
                    _primaryColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _userIcon,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _userTypeLabel,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          userFolio,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // QR Code Container
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Título
                  Text(
                    'Código QR de Identificación',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // QR Code
                  Container(
                    width: 250,
                    height: 250,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _primaryColor.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: _isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                              color: _primaryColor,
                            ),
                          )
                        : QrImageView(
                            data: _qrData ?? '',
                            version: QrVersions.auto,
                            size: 218,
                            backgroundColor: Colors.white,
                            errorCorrectionLevel: QrErrorCorrectLevel.H,
                            eyeStyle: QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Colors.black,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Colors.black,
                            ),
                          ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // ID del usuario
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.fingerprint,
                          color: _primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          userId.length > 8 ? userId.substring(0, 8) : userId,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _primaryColor.withOpacity(0.9),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Instrucciones
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF90CAF9)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: BioWayColors.info,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Instrucciones',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1565C0),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Muestra este código QR al transportista cuando vayas a recibir materiales. '
                          'Este código te identifica como $_userTypeLabel autorizado.',
                          style: const TextStyle(
                            color: Color(0xFF1565C0),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Botón para continuar al proceso de recepción (solo si está en flujo de recepción)
            if (widget.isReceivingFlow)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navegar a la pantalla de escaneo de entrega
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReceptorEscanearEntregaScreen(
                          userType: widget.userType,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text(
                    'Continuar para Recibir Materiales',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            
            const SizedBox(height: 60), // Espacio para el bottom nav
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }
  
  Widget _buildBottomNavigation() {
    // No mostrar navegación inferior cuando está en flujo de recepción
    if (widget.isReceivingFlow) {
      return const SizedBox.shrink();
    }
    
    // Configuración específica por tipo de usuario
    switch (widget.userType) {
      case 'reciclador':
        return EcoceBottomNavigation(
          selectedIndex: -1, // Ningún ítem seleccionado
          onItemTapped: (index) {
            switch (index) {
              case 0:
                Navigator.pushReplacementNamed(context, '/reciclador_inicio');
                break;
              case 1:
                Navigator.pushReplacementNamed(context, '/reciclador_lotes');
                break;
              case 2:
                Navigator.pushReplacementNamed(context, '/reciclador_historial');
                break;
              case 3:
                Navigator.pushReplacementNamed(context, '/reciclador_perfil');
                break;
            }
          },
          primaryColor: BioWayColors.primaryGreen,
          items: const [
            NavigationItem(
              icon: Icons.home_rounded,
              label: 'Inicio',
              testKey: 'reciclador_nav_inicio',
            ),
            NavigationItem(
              icon: Icons.inventory_2_rounded,
              label: 'Lotes',
              testKey: 'reciclador_nav_lotes',
            ),
            NavigationItem(
              icon: Icons.history_rounded,
              label: 'Historial',
              testKey: 'reciclador_nav_historial',
            ),
            NavigationItem(
              icon: Icons.person_outline_rounded,
              label: 'Perfil',
              testKey: 'reciclador_nav_perfil',
            ),
          ],
        );
        
      case 'laboratorio':
        return EcoceBottomNavigation(
          selectedIndex: 1, // Recibir
          onItemTapped: (index) {
            switch (index) {
              case 0:
                Navigator.pushReplacementNamed(context, '/laboratorio_inicio');
                break;
              case 1:
                break; // Ya estamos aquí
              case 2:
                Navigator.pushReplacementNamed(context, '/laboratorio_muestras');
                break;
              case 3:
                Navigator.pushReplacementNamed(context, '/laboratorio_perfil');
                break;
            }
          },
          primaryColor: BioWayColors.petBlue,
          items: const [
            NavigationItem(
              icon: Icons.home_rounded,
              label: 'Inicio',
              testKey: 'laboratorio_nav_inicio',
            ),
            NavigationItem(
              icon: Icons.qr_code_scanner_rounded,
              label: 'Recibir',
              testKey: 'laboratorio_nav_recibir',
            ),
            NavigationItem(
              icon: Icons.science_rounded,
              label: 'Muestras',
              testKey: 'laboratorio_nav_muestras',
            ),
            NavigationItem(
              icon: Icons.person_outline_rounded,
              label: 'Perfil',
              testKey: 'laboratorio_nav_perfil',
            ),
          ],
        );
        
      case 'transformador':
        return EcoceBottomNavigation(
          selectedIndex: 1, // Recibir
          onItemTapped: (index) {
            switch (index) {
              case 0:
                Navigator.pushReplacementNamed(context, '/transformador_inicio');
                break;
              case 1:
                break; // Ya estamos aquí
              case 2:
                Navigator.pushReplacementNamed(context, '/transformador_produccion');
                break;
              case 3:
                Navigator.pushReplacementNamed(context, '/transformador_perfil');
                break;
            }
          },
          primaryColor: BioWayColors.ppPurple,
          items: const [
            NavigationItem(
              icon: Icons.home_rounded,
              label: 'Inicio',
              testKey: 'transformador_nav_inicio',
            ),
            NavigationItem(
              icon: Icons.qr_code_scanner_rounded,
              label: 'Recibir',
              testKey: 'transformador_nav_recibir',
            ),
            NavigationItem(
              icon: Icons.precision_manufacturing_rounded,
              label: 'Producción',
              testKey: 'transformador_nav_produccion',
            ),
            NavigationItem(
              icon: Icons.person_outline_rounded,
              label: 'Perfil',
              testKey: 'transformador_nav_perfil',
            ),
          ],
        );
        
      default:
        return const SizedBox.shrink();
    }
  }
}