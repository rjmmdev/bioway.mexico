import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import '../../../services/firebase/auth_service.dart';

class PendingApprovalScreen extends StatelessWidget {
  final String userName;
  final String userEmail;
  
  const PendingApprovalScreen({
    super.key,
    required this.userName,
    required this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return WillPopScope(
      onWillPop: () async {
        await _handleLogout(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: BioWayColors.backgroundGrey,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.all(screenWidth * 0.05),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icono animado
                    Container(
                      width: screenWidth * 0.3,
                      height: screenWidth * 0.3,
                      constraints: BoxConstraints(
                        maxWidth: 120,
                        maxHeight: 120,
                      ),
                      decoration: BoxDecoration(
                        color: BioWayColors.warning.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.hourglass_empty,
                          size: screenWidth * 0.15,
                          color: BioWayColors.warning,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.04),
                    
                    // Título
                    Text(
                      'Cuenta Pendiente de Aprobación',
                      style: TextStyle(
                        fontSize: screenWidth * 0.06,
                        fontWeight: FontWeight.bold,
                        color: BioWayColors.darkGreen,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    
                    // Nombre del usuario
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenHeight * 0.01,
                      ),
                      decoration: BoxDecoration(
                        color: BioWayColors.ecoceGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        userName,
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.w600,
                          color: BioWayColors.ecoceGreen,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    
                    // Card informativa
                    Container(
                      padding: EdgeInsets.all(screenWidth * 0.05),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.assignment_turned_in,
                            size: screenWidth * 0.1,
                            color: BioWayColors.ecoceGreen,
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          Text(
                            'Tu solicitud ha sido recibida',
                            style: TextStyle(
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.bold,
                              color: BioWayColors.darkGreen,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: screenHeight * 0.015),
                          Text(
                            'Un administrador de ECOCE está revisando tu documentación y aprobará tu cuenta en las próximas 24-48 horas.',
                            style: TextStyle(
                              fontSize: screenWidth * 0.035,
                              color: BioWayColors.textGrey,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    
                    // Información de notificación
                    Container(
                      padding: EdgeInsets.all(screenWidth * 0.04),
                      decoration: BoxDecoration(
                        color: BioWayColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: BioWayColors.info.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            color: BioWayColors.info,
                            size: screenWidth * 0.05,
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Notificación por correo',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.035,
                                    fontWeight: FontWeight.bold,
                                    color: BioWayColors.darkGreen,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Recibirás un correo en $userEmail cuando tu cuenta sea aprobada.',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.03,
                                    color: BioWayColors.textGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.04),
                    
                    // Botones
                    Column(
                      children: [
                        // Botón de cerrar sesión
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () => _handleLogout(context),
                            icon: Icon(Icons.logout),
                            label: Text(
                              'Cerrar Sesión',
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: BioWayColors.ecoceGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        
                        // Información de contacto
                        TextButton(
                          onPressed: () => _showContactInfo(context),
                          child: Text(
                            '¿Necesitas ayuda? Contáctanos',
                            style: TextStyle(
                              fontSize: screenWidth * 0.035,
                              color: BioWayColors.ecoceGreen,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Future<void> _handleLogout(BuildContext context) async {
    HapticFeedback.lightImpact();
    
    // Mostrar diálogo de confirmación
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('Cerrar Sesión'),
        content: Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: BioWayColors.ecoceGreen,
            ),
            child: Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
    
    if (shouldLogout == true) {
      await AuthService().signOut();
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/platform_selector',
        (route) => false,
      );
    }
  }
  
  void _showContactInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.support_agent,
              color: BioWayColors.ecoceGreen,
            ),
            SizedBox(width: 8),
            Text('Contacto de Soporte'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContactItem(Icons.email, 'soporte@ecoce.mx'),
            SizedBox(height: 12),
            _buildContactItem(Icons.phone, '01 800 ECOCE MX'),
            SizedBox(height: 12),
            _buildContactItem(Icons.access_time, 'Lun - Vie, 9:00 - 18:00'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContactItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: BioWayColors.textGrey),
        SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: BioWayColors.darkGreen,
          ),
        ),
      ],
    );
  }
}