import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import 'origen_crear_lote_screen.dart';
import 'origen_lotes_screen.dart';
import 'origen_ayuda.dart';

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
  
  final Map<String, dynamic> _informacionOperativa = {
    'capacidadMaxima': '50 toneladas/mes',
    'tiposMateriales': 'PET, HDPE, PP',
    'horarioOperacion': 'Lun-Sáb 8:00 AM - 6:00 PM',
    'responsable': 'Juan Pérez González',
  };
  
  final List<Map<String, dynamic>> _documentos = [
    {
      'nombre': 'Constancia de Situación Fiscal',
      'estado': 'Subido',
      'fecha': '15/05/2024',
      'icono': Icons.description_outlined,
    },
    {
      'nombre': 'Comprobante de Domicilio',
      'estado': 'Pendiente',
      'fecha': null,
      'icono': Icons.home_outlined,
    },
    {
      'nombre': 'Licencia de Operación',
      'estado': 'Subido',
      'fecha': '20/05/2024',
      'icono': Icons.badge_outlined,
    },
    {
      'nombre': 'Permiso Ambiental',
      'estado': 'En revisión',
      'fecha': '22/05/2024',
      'icono': Icons.eco_outlined,
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

  void _editarCampo(String campo) {
    HapticFeedback.lightImpact();
    // TODO: Implementar edición de campos
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Editando: $campo'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 220,
              backgroundColor: BioWayColors.ecoceGreen,
              automaticallyImplyLeading: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: BioWayColors.ecoceGreen,
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icono del centro
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.factory,
                            size: 48,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Nombre del centro
                        Text(
                          _nombreCentro,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 8),
                        // Tipo y folio
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _tipoCentro,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _folioCentro,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: BioWayColors.ecoceGreen,
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
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.grey[600],
                    indicatorColor: BioWayColors.ecoceGreen,
                    indicatorWeight: 3,
                    tabs: const [
                      Tab(text: 'Información'),
                      Tab(text: 'Documentos'),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab de Información
            _buildInformacionTab(),
            // Tab de Documentos
            _buildDocumentosTab(),
          ],
        ),
      ),
      // Bottom Navigation Bar con FAB
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          color: Colors.white,
          child: SizedBox(
            height: 65,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
            _buildBottomNavItem(Icons.home_outlined, Icons.home, 'Inicio', 0),
            _buildBottomNavItem(Icons.inventory_2_outlined, Icons.inventory_2, 'Lotes', 1),
            const SizedBox(width: 80), // Espacio para el FAB
            _buildBottomNavItem(Icons.help_outline, Icons.help, 'Ayuda', 2),
            _buildBottomNavItem(Icons.person_outline, Icons.person, 'Perfil', 3),
              ],
            ),
          ),
        ),
      ),

      // Floating Action Button
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              BioWayColors.ecoceGreen,
              BioWayColors.ecoceGreen.withOpacity(0.8),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: BioWayColors.ecoceGreen.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
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
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(
            Icons.add,
            size: 32,
            color: Colors.white,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildInformacionTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Información Básica
          _buildSeccion(
            titulo: 'Información Básica',
            icono: Icons.business,
            children: [
              _buildCampoInfo('Nombre Comercial', _informacionBasica['nombreComercial']),
              _buildCampoInfo(
                'RFC', 
                _informacionBasica['rfc'].isEmpty ? 'No registrado' : _informacionBasica['rfc'],
                advertencia: _informacionBasica['rfc'].isEmpty,
              ),
              _buildCampoInfo('Teléfono', _informacionBasica['telefono']),
              _buildCampoInfo('Correo Electrónico', _informacionBasica['correo']),
            ],
          ),
          
          // Dirección
          _buildSeccion(
            titulo: 'Dirección',
            icono: Icons.location_on,
            children: [
              _buildCampoInfo('Calle', _direccion['calle']),
              _buildCampoInfo('Colonia', _direccion['colonia']),
              _buildCampoInfo('Ciudad', _direccion['ciudad']),
              _buildCampoInfo('Estado', _direccion['estado']),
              _buildCampoInfo('Código Postal', _direccion['codigoPostal']),
            ],
          ),
          
          // Información Operativa
          _buildSeccion(
            titulo: 'Información Operativa',
            icono: Icons.settings,
            children: [
              _buildCampoInfo('Capacidad Máxima', _informacionOperativa['capacidadMaxima']),
              _buildCampoInfo('Tipos de Materiales', _informacionOperativa['tiposMateriales']),
              _buildCampoInfo('Horario de Operación', _informacionOperativa['horarioOperacion']),
              _buildCampoInfo('Responsable', _informacionOperativa['responsable']),
            ],
          ),
          
          const SizedBox(height: 100), // Espacio para el FAB
        ],
      ),
    );
  }

  Widget _buildDocumentosTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Advertencia RFC
          if (_informacionBasica['rfc'].isEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'RFC Pendiente',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Tienes 10 días para subir tus documentos',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          // Lista de documentos
          ...List.generate(
            _documentos.length,
            (index) => _buildDocumentoItem(_documentos[index]),
          ),
          
          const SizedBox(height: 100), // Espacio para el FAB
        ],
      ),
    );
  }

  Widget _buildSeccion({
    required String titulo,
    required IconData icono,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icono, color: BioWayColors.ecoceGreen, size: 24),
                const SizedBox(width: 12),
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
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

  Widget _buildCampoInfo(String label, String valor, {bool advertencia = false}) {
    return InkWell(
      onTap: () => _editarCampo(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    valor,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (advertencia)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning,
                          size: 14,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Pendiente: 10 días para subir tus documentos',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentoItem(Map<String, dynamic> documento) {
    Color estadoColor;
    IconData estadoIcono;
    
    switch (documento['estado']) {
      case 'Subido':
        estadoColor = Colors.green;
        estadoIcono = Icons.check_circle;
        break;
      case 'En revisión':
        estadoColor = Colors.orange;
        estadoIcono = Icons.schedule;
        break;
      case 'Pendiente':
      default:
        estadoColor = Colors.grey;
        estadoIcono = Icons.upload_file;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: estadoColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            documento['icono'],
            color: estadoColor,
            size: 24,
          ),
        ),
        title: Text(
          documento['nombre'],
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        subtitle: Row(
          children: [
            Icon(estadoIcono, size: 16, color: estadoColor),
            const SizedBox(width: 4),
            Text(
              documento['estado'],
              style: TextStyle(
                color: estadoColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (documento['fecha'] != null) ...[
              const SizedBox(width: 8),
              Text(
                '• ${documento['fecha']}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ],
        ),
        trailing: documento['estado'] == 'Pendiente'
            ? ElevatedButton(
                onPressed: () => _subirDocumento(documento['nombre']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BioWayColors.ecoceGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Subir'),
              )
            : IconButton(
                icon: const Icon(Icons.visibility_outlined),
                color: Colors.grey[600],
                onPressed: () {
                  // TODO: Ver documento
                },
              ),
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, IconData activeIcon, String label, int index) {
    final isSelected = _selectedIndex == index;
    
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            
            if (isSelected) return;
            
            switch (index) {
              case 0:
                Navigator.pop(context);
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
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? BioWayColors.ecoceGreen : Colors.grey,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? BioWayColors.ecoceGreen : Colors.grey,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}