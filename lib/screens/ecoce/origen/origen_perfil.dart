import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import 'origen_crear_lote_screen.dart';
import 'origen_lotes_screen.dart';
import 'origen_ayuda.dart';
import 'origen_inicio_screen.dart';
import 'widgets/origen_bottom_navigation.dart';

class OrigenPerfilScreen extends StatefulWidget {
  const OrigenPerfilScreen({super.key});

  @override
  State<OrigenPerfilScreen> createState() => _OrigenPerfilScreenState();
}

class _OrigenPerfilScreenState extends State<OrigenPerfilScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Índice para la navegación del bottom bar
  int _selectedIndex = 3; // Perfil está seleccionado
  
  // Datos del centro (en producción vendrían de la base de datos)
  final String _nombreCentro = "Centro de Acopio La Esperanza";
  final String _tipoCentro = "Centro de Acopio";
  final String _folioCentro = "A0000001";
  final String _nombreResponsable = "Juan Pérez González";
  
  // Información del centro
  final Map<String, dynamic> _informacionBasica = {
    'nombreComercial': 'Centro de Acopio La Esperanza S.A. de C.V.',
    'rfc': '',
    'telefono': '+52 55 1234 5678',
    'correo': 'contacto@laesperanza.mx',
  };
  
  final Map<String, dynamic> _direccion = {
    'calle': 'Av. Insurgentes Sur 1234',
    'colonia': 'Del Valle Centro',
    'ciudad': 'Ciudad de México',
    'estado': 'CDMX',
    'codigoPostal': '03100',
  };
  
  // Información operativa basada en los datos de registro de acopiador/planta separación
  final Map<String, dynamic> _informacionOperativa = {
    'capacidadPrensado': {
      'largo': '2.5 metros',
      'ancho': '1.8 metros', 
      'pesoMaximo': '800 kg',
    },
    'tiposMateriales': [
      'PE Limpio',
      'PE Sucio', 
      'Multicapa PE/PP',
      'LDPE',
      'HDPE',
      'BOPP',
      'Stretch Film'
    ],
    'tieneTransporte': true,
    'linkRedSocial': 'www.laesperanza.mx',
  };
  
  // Actualizado con los 4 documentos requeridos
  final List<Map<String, dynamic>> _documentos = [
    {
      'nombre': 'Constancia de Situación Fiscal',
      'estado': 'Subido',
      'fecha': '15/07/2025',
      'icono': Icons.description,
      'archivo': 'const_sit_fiscal_2025.pdf',
    },
    {
      'nombre': 'Comprobante de Domicilio',
      'estado': 'Pendiente',
      'fecha': null,
      'icono': Icons.home_work,
      'archivo': null,
    },
    {
      'nombre': 'Carátula de Banco',
      'estado': 'Subido',
      'fecha': '10/07/2025',
      'icono': Icons.account_balance,
      'archivo': 'estado_cuenta_julio.pdf',
    },
    {
      'nombre': 'INE',
      'estado': 'Pendiente',
      'fecha': null,
      'icono': Icons.badge,
      'archivo': null,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }


  void _subirDocumento(String documento) {
    HapticFeedback.lightImpact();
    // TODO: Implementar carga de documentos
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Subiendo: $documento'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _compartirDireccionGoogleMaps() {
    HapticFeedback.lightImpact();
    // Crear la dirección completa para Google Maps
    final direccionCompleta = '${_direccion['calle']}, ${_direccion['colonia']}, ${_direccion['ciudad']}, ${_direccion['estado']} ${_direccion['codigoPostal']}';
    
    // TODO: En producción, usar url_launcher para abrir Google Maps
    // final url = 'https://maps.google.com/?q=${Uri.encodeComponent(direccionCompleta)}';
    
    // Por ahora, copiar al portapapeles
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Dirección copiada: $direccionCompleta'),
            ),
          ],
        ),
        backgroundColor: BioWayColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _navigateToNewLot() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const OrigenCrearLoteScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _onBottomNavTapped(int index) {
    HapticFeedback.lightImpact();
    
    if (index == _selectedIndex) return;
    
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const OrigenInicioScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const OrigenLotesScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const OrigenAyudaScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
        break;
      case 3:
        // Ya estamos en perfil
        break;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header compacto y optimizado
            SliverToBoxAdapter(
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      BioWayColors.ecoceGreen,
                      BioWayColors.ecoceGreen.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Patrón de fondo sutil
                    Positioned(
                      right: -80,
                      top: -80,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                    ),
                    // Contenido principal
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // Información principal compacta
                            Row(
                              children: [
                                // Avatar compacto
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.store,
                                    size: 32,
                                    color: BioWayColors.ecoceGreen,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Información del centro
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _nombreCentro,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                      const SizedBox(height: 6),
                                      // Información clave en una sola línea
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 4,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.9),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.verified,
                                                  size: 14,
                                                  color: BioWayColors.ecoceGreen,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _folioCentro,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: BioWayColors.ecoceGreen,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.location_on,
                                                  size: 12,
                                                  color: Colors.white,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _direccion['estado'],
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Pestañas compactas
                            Container(
                              height: 40,
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: TabBar(
                                controller: _tabController,
                                indicator: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(17),
                                ),
                                labelColor: BioWayColors.ecoceGreen,
                                unselectedLabelColor: Colors.white.withOpacity(0.8),
                                labelStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                unselectedLabelStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                indicatorSize: TabBarIndicatorSize.tab,
                                dividerColor: Colors.transparent,
                                tabs: const [
                                  Tab(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text('Información'),
                                    ),
                                  ),
                                  Tab(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text('Documentos'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Contenido principal
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -30),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 30, 0, 0),
                    child: Column(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.7,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildInformacionTab(),
                              _buildDocumentosTab(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 100), // Espacio para el FAB
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // Floating Action Button
      floatingActionButton: OrigenFloatingActionButton(
        onPressed: _navigateToNewLot,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Bottom Navigation Bar con FAB
      bottomNavigationBar: OrigenBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onBottomNavTapped,
        onFabPressed: _navigateToNewLot,
      ),
    );
  }

  Widget _buildInformacionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjeta de estado RFC
          if (_informacionBasica['rfc'].isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.withOpacity(0.1),
                    Colors.orange.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange[700],
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'RFC Pendiente',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tienes 10 días restantes para completar tu documentación fiscal',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange[700],
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Contacto
          _buildSeccionModerna(
            titulo: 'Información de Contacto',
            icono: Icons.contact_phone,
            color: BioWayColors.primaryGreen,
            children: [
              _buildCampoModerno(
                icono: Icons.phone,
                label: 'Teléfono',
                value: _informacionBasica['telefono'],
              ),
              _buildCampoModerno(
                icono: Icons.email,
                label: 'Correo Electrónico',
                value: _informacionBasica['correo'],
              ),
              if (_informacionBasica['rfc'].isEmpty)
                _buildCampoModerno(
                  icono: Icons.article,
                  label: 'RFC',
                  value: 'Pendiente por registrar',
                  isWarning: true,
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Dirección compacta
          _buildSeccionModerna(
            titulo: 'Ubicación',
            icono: Icons.location_on,
            color: Colors.blue,
            children: [
              _buildCampoModerno(
                icono: Icons.home,
                label: 'Dirección Completa',
                value: '${_direccion['calle']}, ${_direccion['colonia']}, ${_direccion['ciudad']}, ${_direccion['estado']} ${_direccion['codigoPostal']}',
              ),
              const SizedBox(height: 12),
              // Botón de Google Maps
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _compartirDireccionGoogleMaps,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map,
                          size: 20,
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Compartir ubicación en Google Maps',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.open_in_new,
                          size: 16,
                          color: Colors.blue[700],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Información Operativa
          _buildSeccionModerna(
            titulo: 'Capacidad Operativa',
            icono: Icons.settings,
            color: Colors.purple,
            children: [
              _buildCampoModerno(
                icono: Icons.person,
                label: 'Responsable',
                value: _nombreResponsable,
              ),
              _buildCapacidadPrensado(),
              _buildMaterialesChips(),
              _buildCampoModerno(
                icono: Icons.local_shipping,
                label: 'Servicio de Transporte',
                value: _informacionOperativa['tieneTransporte'] ? 'Disponible' : 'No disponible',
                valueColor: _informacionOperativa['tieneTransporte'] ? Colors.green : Colors.grey,
              ),
            ],
          ),
          
          const SizedBox(height: 100), // Espacio para el FAB
        ],
      ),
    );
  }

  Widget _buildDocumentosTab() {
    // Calcular documentos pendientes
    int documentosPendientes = _documentos.where((doc) => doc['estado'] == 'Pendiente').length;
    int documentosSubidos = _documentos.where((doc) => doc['estado'] == 'Subido').length;
    
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen compacto de documentos
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: documentosPendientes > 0 
                ? Colors.orange.shade50
                : Colors.green.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: documentosPendientes > 0 
                  ? Colors.orange.shade200
                  : Colors.green.shade200,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Icono y texto principal
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      documentosPendientes > 0 
                        ? Icons.assignment_late
                        : Icons.assignment_turned_in,
                      color: documentosPendientes > 0 
                        ? Colors.orange.shade700
                        : Colors.green.shade700,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        documentosPendientes > 0 
                          ? 'Faltan $documentosPendientes documentos'
                          : '¡Documentación completa!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: documentosPendientes > 0 
                            ? Colors.orange.shade700
                            : Colors.green.shade700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Barra de progreso
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: documentosSubidos / _documentos.length,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      documentosPendientes > 0 
                        ? Colors.orange.shade600
                        : Colors.green.shade600,
                    ),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$documentosSubidos/${_documentos.length} completados',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Advertencia RFC si aplica
          if (_informacionBasica['rfc'].isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange.shade700,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Recuerda que debes proporcionar tu RFC antes de que venzan los 14 días desde tu registro.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange.shade700,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          
          const Text(
            'Documentos Requeridos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          // Lista de documentos con nuevo diseño
          // Lista de documentos rediseñada
          ..._documentos.map((doc) => _buildDocumentoCompacto(doc)).toList(),
          
          const SizedBox(height: 100), // Espacio para el FAB
        ],
      ),
    );
  }



  // Métodos helper para el nuevo diseño
  Widget _buildSeccionModerna({
    required String titulo,
    required IconData icono,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icono, color: color, size: 24),
                const SizedBox(width: 12),
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildCampoModerno({
    required IconData icono,
    required String label,
    required String value,
    bool isWarning = false,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade100,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isWarning 
                  ? Colors.orange.withOpacity(0.1)
                  : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icono,
              color: isWarning ? Colors.orange : Colors.grey[600],
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
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
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? (isWarning ? Colors.orange[700] : Colors.black87),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapacidadPrensado() {
    final capacidad = _informacionOperativa['capacidadPrensado'] as Map<String, dynamic>;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade100,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.compress,
                  color: Colors.grey[600],
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Capacidad de Prensado',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: BioWayColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        capacidad['largo'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Largo',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        capacidad['ancho'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Ancho',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        capacidad['pesoMaximo'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Peso Máx.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialesChips() {
    final materiales = _informacionOperativa['tiposMateriales'] as List<String>;
    final coloresMateriales = {
      'PE Limpio': const Color(0xFF4CAF50),
      'PE Sucio': const Color(0xFF8BC34A),
      'Multicapa PE/PP': const Color(0xFF2196F3),
      'LDPE': const Color(0xFF03A9F4),
      'HDPE': const Color(0xFF00BCD4),
      'BOPP': const Color(0xFF9C27B0),
      'Stretch Film': const Color(0xFF673AB7),
    };
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade100,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.recycling,
                  color: Colors.grey[600],
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Materiales que Recibe',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: materiales.map((material) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: coloresMateriales[material]?.withOpacity(0.1) ?? Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: coloresMateriales[material]?.withOpacity(0.3) ?? Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  material,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: coloresMateriales[material] ?? Colors.grey[700],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }


  Widget _buildDocumentoCompacto(Map<String, dynamic> documento) {
    final bool isSubido = documento['estado'] == 'Subido';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSubido 
            ? Colors.green.shade200
            : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isSubido ? null : () => _subirDocumento(documento['nombre']),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Icono del documento
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSubido 
                      ? Colors.green.shade50
                      : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    documento['icono'],
                    color: isSubido 
                      ? Colors.green.shade700
                      : Colors.grey.shade600,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                // Información del documento
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        documento['nombre'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isSubido && documento['fecha'] != null
                          ? 'Subido el ${documento['fecha']}'
                          : 'Toca para subir',
                        style: TextStyle(
                          fontSize: 12,
                          color: isSubido 
                            ? Colors.green.shade600
                            : Colors.grey.shade500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Estado del documento
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSubido 
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSubido 
                      ? Icons.check_circle
                      : Icons.upload_file,
                    color: isSubido 
                      ? Colors.green.shade600
                      : Colors.orange.shade600,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}