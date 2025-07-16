import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';

class PlaceholderPerfilScreen extends StatefulWidget {
  final String nombreUsuario;
  final String tipoUsuario;
  final String folioUsuario;
  final String iconCode; // 'store', 'recycling', 'local_shipping'
  final Color primaryColor;
  final Widget bottomNavigation;
  final String? nombreEmpresa;

  const PlaceholderPerfilScreen({
    super.key,
    required this.nombreUsuario,
    required this.tipoUsuario,
    required this.folioUsuario,
    required this.iconCode,
    required this.primaryColor,
    required this.bottomNavigation,
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
    _tabController = TabController(length: 3, vsync: this);
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
            expandedHeight: 240,
            floating: false,
            pinned: true,
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
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Avatar con verificación
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _getIconFromCode(widget.iconCode),
                                  size: 40,
                                  color: widget.primaryColor,
                                ),
                              ),
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: BioWayColors.success,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                ),
                                child: const Icon(
                                  Icons.check,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Nombre y tipo
                          Text(
                            widget.nombreUsuario,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          // Badges de información
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildBadge(widget.folioUsuario, Icons.qr_code),
                              const SizedBox(width: 8),
                              _buildBadge(widget.tipoUsuario, Icons.category),
                              if (_informacionUsuario['calificacion'] != null) ...[
                                const SizedBox(width: 8),
                                _buildBadge(
                                  '${_metricas['calificacion']} ★',
                                  Icons.star,
                                  isHighlight: true,
                                ),
                              ],
                            ],
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
                    Tab(text: 'Actividad'),
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
            _buildActividadTab(),
          ],
        ),
      ),
      bottomNavigationBar: widget.bottomNavigation,
    );
  }

  Widget _buildBadge(String text, IconData icon, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isHighlight 
            ? Colors.amber.withOpacity(0.9)
            : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isHighlight ? Colors.amber[900] : widget.primaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isHighlight ? Colors.amber[900] : widget.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjeta de estado
          _buildStatusCard(),
          const SizedBox(height: 20),
          
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
    int documentosPendientes = _documentos.where((doc) => doc['estado'] == 'Pendiente').length;
    int documentosSubidos = _documentos.where((doc) => doc['estado'] == 'Subido').length;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Resumen de documentos
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: documentosPendientes > 0
                    ? [Colors.orange.shade50, Colors.orange.shade100]
                    : [Colors.green.shade50, Colors.green.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: documentosPendientes > 0 
                      ? Colors.orange.withOpacity(0.2)
                      : Colors.green.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Icon(
                        documentosPendientes > 0 
                            ? Icons.assignment_late
                            : Icons.assignment_turned_in,
                        color: documentosPendientes > 0 
                            ? Colors.orange[700]
                            : Colors.green[700],
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            documentosPendientes > 0 
                                ? 'Documentos Pendientes'
                                : '¡Documentación Completa!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: documentosPendientes > 0 
                                  ? Colors.orange[800]
                                  : Colors.green[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$documentosSubidos de ${_documentos.length} documentos subidos',
                            style: TextStyle(
                              fontSize: 14,
                              color: documentosPendientes > 0 
                                  ? Colors.orange[700]
                                  : Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${(documentosSubidos / _documentos.length * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: documentosPendientes > 0 
                              ? Colors.orange[700]
                              : Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: documentosSubidos / _documentos.length,
                    backgroundColor: Colors.white.withOpacity(0.5),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      documentosPendientes > 0 
                          ? Colors.orange[600]!
                          : Colors.green[600]!,
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Lista de documentos
          ..._documentos.map((doc) => _buildDocumentoCard(doc)).toList(),
        ],
      ),
    );
  }

  Widget _buildActividadTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Métricas principales
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  titulo: 'Material Total',
                  valor: '${(_metricas['materialesRecibidos'] / 1000).toStringAsFixed(1)} ton',
                  icono: Icons.scale_outlined,
                  color: widget.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  titulo: 'Operaciones',
                  valor: _metricas['operacionesCompletadas'].toString(),
                  icono: Icons.check_circle_outline,
                  color: BioWayColors.success,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Actividad reciente
          Text(
            'Actividad Reciente',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: BioWayColors.darkGrey,
            ),
          ),
          const SizedBox(height: 16),
          
          // Placeholder para historial
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.history,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Historial de Actividades',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Aquí se mostrará el historial completo de operaciones',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final bool tieneRFC = _informacionUsuario['rfc'] != null && _informacionUsuario['rfc'].isNotEmpty;
    
    if (tieneRFC) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              BioWayColors.success.withOpacity(0.1),
              BioWayColors.success.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: BioWayColors.success.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: BioWayColors.success.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.verified,
                color: BioWayColors.success,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cuenta Verificada',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: BioWayColors.darkGreen,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tu información fiscal está completa',
                    style: TextStyle(
                      fontSize: 14,
                      color: BioWayColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.1),
            Colors.orange.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange[700],
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RFC Pendiente',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Completa tu información fiscal antes del 30 de marzo',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
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
          children: materiales.map((material) {
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
                            : 'Toca para subir documento',
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
                    isSubido ? Icons.check : Icons.upload_file,
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
}