import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import '../origen/widgets/origen_bottom_navigation.dart';
import '../reciclador/widgets/reciclador_bottom_navigation.dart';
import '../transporte/widgets/transporte_bottom_navigation.dart';

class PlaceholderPerfilScreen extends StatefulWidget {
  final String nombreUsuario;
  final String tipoUsuario;
  final String folioUsuario;
  final String iconCode; // 'store', 'recycling', 'local_shipping'
  final Color primaryColor;
  final String? nombreEmpresa;

  const PlaceholderPerfilScreen({
    super.key,
    required this.nombreUsuario,
    required this.tipoUsuario,
    required this.folioUsuario,
    required this.iconCode,
    required this.primaryColor,
    this.nombreEmpresa,
  });

  @override
  State<PlaceholderPerfilScreen> createState() => _PlaceholderPerfilScreenState();
}

class _PlaceholderPerfilScreenState extends State<PlaceholderPerfilScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Información del usuario basada en la estructura real
  final Map<String, dynamic> _informacionUsuario = {
    'nombre': 'Centro de Acopio La Esperanza SA de CV',
    'rfc': 'XAXX010101000',
    'nombre_contacto': 'Juan Pérez González',
    'tel_contacto': '+52 555 123 4567',
    'tel_empresa': '+52 555 987 6543',
    'correo_contacto': 'contacto@laesperanza.mx',
    'calle': 'Av. Insurgentes Sur',
    'num_ext': '1234',
    'cp': '03100',
    'ref_ubi': 'Frente a la iglesia, entrada lateral por la farmacia',
    'poligono_loc': 'Zona Norte CDMX',
    'fecha_reg': '2024-01-15',
    'lista_materiales': 'PET, HDPE, PP, LDPE, PS, PVC, Otros plásticos',
    'transporte': true,
    'link_red_social': 'www.laesperanza.mx',
    // Campos específicos para acopiadores
    'dim_cap': '15.25 X 15.20',
    'peso_cap': 850.5,
  };
  
  // Documentos con su estado
  final List<Map<String, dynamic>> _documentos = [
    {
      'nombre': 'Constancia de Situación Fiscal',
      'campo': 'const_sit_fis',
      'estado': 'Subido',
      'fecha': '15/01/2024',
      'icono': Icons.article_outlined,
    },
    {
      'nombre': 'Comprobante de Domicilio',
      'campo': 'comp_domicilio',
      'estado': 'Pendiente',
      'fecha': null,
      'icono': Icons.home_work_outlined,
    },
    {
      'nombre': 'Carátula de Banco',
      'campo': 'banco_caratula',
      'estado': 'Subido',
      'fecha': '20/01/2024',
      'icono': Icons.account_balance_outlined,
    },
    {
      'nombre': 'INE',
      'campo': 'ine',
      'estado': 'Subido',
      'fecha': '15/01/2024',
      'icono': Icons.badge_outlined,
    },
  ];

  // Métricas de actividad
  final Map<String, dynamic> _metricas = {
    'materialesRecibidos': 12450.5, // kg
    'operacionesCompletadas': 234,
    'ultimaActividad': DateTime.now().subtract(const Duration(hours: 2)),
    'calificacion': 4.8,
  };

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

  IconData _getIconFromCode(String code) {
    switch (code) {
      case 'store':
        return Icons.store;
      case 'recycling':
        return Icons.recycling;
      case 'local_shipping':
        return Icons.local_shipping;
      default:
        return Icons.person;
    }
  }

  String _getTipoActorCode() {
    switch (widget.iconCode) {
      case 'store':
        return widget.folioUsuario.startsWith('A') ? 'A' : 'P';
      case 'recycling':
        return 'R';
      case 'local_shipping':
        return 'V';
      default:
        return 'A';
    }
  }

  void _copiarAlPortapapeles(String texto, String mensaje) {
    Clipboard.setData(ClipboardData(text: texto));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: widget.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _mostrarGoogleMaps() {
    HapticFeedback.lightImpact();
    final direccion = '${_informacionUsuario['calle']} ${_informacionUsuario['num_ext']}, CP ${_informacionUsuario['cp']}';
    _copiarAlPortapapeles(direccion, 'Dirección copiada');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: widget.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradiente de fondo
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          widget.primaryColor,
                          widget.primaryColor.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  // Patrón decorativo
                  Positioned(
                    right: -50,
                    top: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -100,
                    bottom: -100,
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                  // Contenido del header
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 56, // Posición desde abajo para dejar espacio para las tabs
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          // Avatar más pequeño
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              _getIconFromCode(widget.iconCode),
                              size: 30,
                              color: widget.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Información del usuario
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Nombre
                                Text(
                                  widget.nombreUsuario,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                // ID y tipo en una fila
                                Row(
                                  children: [
                                    // ID
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.qr_code,
                                            size: 14,
                                            color: Colors.white.withOpacity(0.9),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            widget.folioUsuario,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Tipo
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        widget.tipoUsuario,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_informacionUsuario['calificacion'] != null) ...[
                                  const SizedBox(height: 6),
                                  // Calificación
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${_metricas['calificacion']}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
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
                  ),
                ],
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: widget.primaryColor,
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: widget.primaryColor,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(text: 'General'),
                    Tab(text: 'Documentos'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildGeneralTab(),
            _buildDocumentosTab(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: _shouldShowFab() ? FloatingActionButtonLocation.centerDocked : null,
    );
  }


  Widget _buildGeneralTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información fiscal
          _buildInfoSection(
            titulo: 'Información Fiscal',
            icono: Icons.receipt_long_outlined,
            children: [
              _buildInfoItem('RFC', _informacionUsuario['rfc'] ?? 'Pendiente de registro'),
              _buildInfoItem('Razón Social', widget.nombreEmpresa ?? widget.nombreUsuario),
              _buildInfoItem('Fecha de Registro', _formatDate(_informacionUsuario['fecha_reg'])),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Información de contacto
          _buildInfoSection(
            titulo: 'Contacto',
            icono: Icons.contact_phone_outlined,
            children: [
              _buildInfoItem('Responsable', _informacionUsuario['nombre_contacto']),
              _buildCopyableItem('Teléfono Personal', _informacionUsuario['tel_contacto']),
              _buildCopyableItem('Teléfono Empresa', _informacionUsuario['tel_empresa']),
              _buildCopyableItem('Correo', _informacionUsuario['correo_contacto']),
              if (_informacionUsuario['link_red_social'] != null)
                _buildLinkItem('Sitio Web', _informacionUsuario['link_red_social']),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Ubicación
          _buildInfoSection(
            titulo: 'Ubicación',
            icono: Icons.location_on_outlined,
            children: [
              _buildInfoItem('Dirección', 
                '${_informacionUsuario['calle']} ${_informacionUsuario['num_ext']}, CP ${_informacionUsuario['cp']}'),
              _buildInfoItem('Referencias', _informacionUsuario['ref_ubi']),
              _buildInfoItem('Polígono Asignado', _informacionUsuario['poligono_loc']),
              _buildMapButton(),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Información operativa
          _buildInfoSection(
            titulo: 'Información Operativa',
            icono: Icons.settings_outlined,
            children: [
              _buildMaterialsList(),
              if (_getTipoActorCode() != 'V')
                _buildInfoItem('Transporte Propio', 
                  _informacionUsuario['transporte'] ? 'Sí' : 'No'),
              if (_getTipoActorCode() == 'A' || _getTipoActorCode() == 'P') ...[
                _buildInfoItem('Capacidad de Prensado', 
                  '${_informacionUsuario['dim_cap']} metros'),
                _buildInfoItem('Peso Máximo', 
                  '${_informacionUsuario['peso_cap']} kg'),
              ],
            ],
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDocumentosTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Lista de documentos
          ..._documentos.map<Widget>((doc) => _buildDocumentoCard(doc)).toList(),
        ],
      ),
    );
  }



  Widget _buildInfoSection({
    required String titulo,
    required IconData icono,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icono,
                    color: widget.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: BioWayColors.darkGrey,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[200]),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyableItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: () => _copiarAlPortapapeles(value, '$label copiado'),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.copy,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: () => _copiarAlPortapapeles(value, 'Link copiado'),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.link,
                      size: 16,
                      color: widget.primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: widget.primaryColor,
                          decoration: TextDecoration.underline,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _mostrarGoogleMaps,
          icon: const Icon(Icons.map),
          label: const Text('Ver en Google Maps'),
          style: OutlinedButton.styleFrom(
            foregroundColor: widget.primaryColor,
            side: BorderSide(color: widget.primaryColor),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialsList() {
    final materiales = _informacionUsuario['lista_materiales'].split(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Materiales que Recibe',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: materiales.map<Widget>((material) {
            final color = _getMaterialColor(material);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: color.withOpacity(0.3),
                ),
              ),
              child: Text(
                material,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Color _getMaterialColor(String material) {
    switch (material.toUpperCase()) {
      case 'PET':
        return BioWayColors.petBlue;
      case 'HDPE':
        return Colors.lightBlue;
      case 'PP':
        return BioWayColors.ppOrange;
      case 'LDPE':
        return Colors.indigo;
      case 'PS':
        return Colors.purple;
      case 'PVC':
        return Colors.red;
      default:
        return Colors.grey[700]!;
    }
  }

  Widget _buildDocumentoCard(Map<String, dynamic> doc) {
    final bool isSubido = doc['estado'] == 'Subido';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: !isSubido ? () {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Subiendo ${doc['nombre']}...'),
                backgroundColor: widget.primaryColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          } : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSubido 
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    doc['icono'],
                    color: isSubido ? Colors.green[700] : Colors.grey[600],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc['nombre'],
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isSubido && doc['fecha'] != null
                            ? 'Subido el ${doc['fecha']}'
                            : 'Documento pendiente',
                        style: TextStyle(
                          fontSize: 13,
                          color: isSubido 
                              ? Colors.green[600]
                              : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSubido 
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSubido ? Icons.visibility : Icons.assignment_late,
                    color: isSubido 
                        ? Colors.green[600]
                        : Colors.orange[600],
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

  Widget _buildMetricCard({
    required String titulo,
    required String valor,
    required IconData icono,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icono,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String date) {
    try {
      final parts = date.split('-');
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    } catch (e) {
      return date;
    }
  }

  bool _shouldShowFab() {
    return widget.iconCode == 'store' || widget.iconCode == 'recycling';
  }

  Widget? _buildFloatingActionButton() {
    switch (widget.iconCode) {
      case 'store':
        return OrigenFloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, '/origen_crear_lote');
          },
        );
      case 'recycling':
        return RecicladorFloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, '/reciclador_escaneo');
          },
        );
      default:
        return null;
    }
  }

  Widget _buildBottomNavigation() {
    switch (widget.iconCode) {
      case 'store':
        return OrigenBottomNavigation(
          selectedIndex: 3,
          onItemTapped: (index) {
            if (index == 3) return; // Ya estamos en perfil
            
            // Navegación a otras pantallas según el índice
            switch (index) {
              case 0:
                Navigator.pushReplacementNamed(context, '/origen_inicio');
                break;
              case 1:
                Navigator.pushReplacementNamed(context, '/origen_lotes');
                break;
              case 2:
                Navigator.pushReplacementNamed(context, '/origen_ayuda');
                break;
            }
          },
          onFabPressed: () {
            Navigator.pushNamed(context, '/origen_crear_lote');
          },
        );
      
      case 'recycling':
        return RecicladorBottomNavigation(
          selectedIndex: 3,
          onItemTapped: (index) {
            if (index == 3) return; // Ya estamos en perfil
            
            // Navegación a otras pantallas según el índice
            switch (index) {
              case 0:
                Navigator.pushReplacementNamed(context, '/reciclador_inicio');
                break;
              case 1:
                Navigator.pushReplacementNamed(context, '/reciclador_lotes');
                break;
              case 2:
                Navigator.pushReplacementNamed(context, '/reciclador_ayuda');
                break;
            }
          },
          onFabPressed: () {
            Navigator.pushNamed(context, '/reciclador_escaneo');
          },
        );
      
      case 'local_shipping':
        return TransporteBottomNavigation(
          selectedIndex: 3,
          onItemTapped: (index) {
            if (index == 3) return; // Ya estamos en perfil
            
            // Navegación a otras pantallas según el índice
            switch (index) {
              case 0:
                Navigator.pushReplacementNamed(context, '/transporte_inicio');
                break;
              case 1:
                Navigator.pushReplacementNamed(context, '/transporte_entregar');
                break;
              case 2:
                Navigator.pushReplacementNamed(context, '/transporte_ayuda');
                break;
            }
          },
        );
      
      default:
        // Fallback para otros tipos de usuario
        return Container();
    }
  }
}