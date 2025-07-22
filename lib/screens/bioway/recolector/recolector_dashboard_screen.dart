import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../utils/colors.dart';
import '../../../utils/bioway_levels.dart';
import '../../../models/bioway/bioway_user.dart';
import '../../../models/bioway/residuo.dart';
import 'recolector_historial_screen.dart';
import 'recolector_mapa_screen.dart';

class RecolectorDashboardScreen extends StatefulWidget {
  const RecolectorDashboardScreen({super.key});

  @override
  State<RecolectorDashboardScreen> createState() => _RecolectorDashboardScreenState();
}

class _RecolectorDashboardScreenState extends State<RecolectorDashboardScreen> {
  // Datos hardcoded para testing
  late BioWayUser _mockUser;
  late List<Residuo> _residuosDisponibles;

  @override
  void initState() {
    super.initState();
    _initializeMockData();
  }

  void _initializeMockData() {
    // Usuario recolector mock
    _mockUser = BioWayUser(
      uid: 'recolector_123',
      nombre: 'Carlos Recolector',
      email: 'carlos@recolector.com',
      tipoUsuario: 'recolector',
      bioCoins: 2500,
      nivel: 'BioWay',
      fechaRegistro: DateTime.now().subtract(const Duration(days: 60)),
      direccion: 'Calle Principal 789',
      numeroExterior: '789',
      codigoPostal: '03100',
      estado: 'Ciudad de México',
      municipio: 'Benito Juárez',
      colonia: 'Del Valle',
      totalResiduosRecolectados: 45,
      totalKgReciclados: 120.5,
      totalCO2Evitado: 250.8,
      vehiculo: 'Camioneta Nissan',
      capacidadKg: 500.0,
    );

    // Residuos disponibles mock
    _residuosDisponibles = _generateMockResiduos();
  }

  List<Residuo> _generateMockResiduos() {
    return [
      Residuo(
        id: 'res_001',
        brindadorId: 'brindador_001',
        brindadorNombre: 'María García',
        materiales: {'plastico': 5.0, 'vidrio': 3.0},
        estado: 'activo',
        fechaCreacion: DateTime.now().subtract(const Duration(hours: 2)),
        latitud: 19.3834,
        longitud: -99.1755,
        direccion: 'Av. Insurgentes 234, Del Valle',
        fotos: [],
        comentarioBrindador: 'Botellas de plástico y vidrio limpias',
        puntosEstimados: 240,
        co2Estimado: 8.5,
      ),
      Residuo(
        id: 'res_002',
        brindadorId: 'brindador_002',
        brindadorNombre: 'Juan Hernández',
        materiales: {'papel': 10.0, 'metal': 2.0},
        estado: 'activo',
        fechaCreacion: DateTime.now().subtract(const Duration(hours: 4)),
        latitud: 19.3900,
        longitud: -99.1700,
        direccion: 'Calle Puebla 567, Roma Norte',
        fotos: [],
        comentarioBrindador: 'Periódicos y latas de aluminio',
        puntosEstimados: 320,
        co2Estimado: 12.0,
      ),
      Residuo(
        id: 'res_003',
        brindadorId: 'brindador_003',
        brindadorNombre: 'Ana López',
        materiales: {'plastico': 8.0, 'papel': 5.0},
        estado: 'activo',
        fechaCreacion: DateTime.now().subtract(const Duration(hours: 6)),
        latitud: 19.3950,
        longitud: -99.1650,
        direccion: 'Av. Álvaro Obregón 890, Roma Sur',
        fotos: [],
        comentarioBrindador: 'Envases de plástico y cartón',
        puntosEstimados: 460,
        co2Estimado: 15.5,
      ),
    ];
  }

  /// Header con información del recolector
  Widget _buildHeader() {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      height: 140 + topPadding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: BioWayColors.backgroundGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: topPadding + 12,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha:0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SvgPicture.asset(
                  'assets/logos/bioway_logo.svg',
                  width: 32,
                  height: 32,
                  colorFilter: ColorFilter.mode(
                    BioWayColors.primaryGreen,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.04),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hola, ${_mockUser.nombre}",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                    Text(
                      "Recolector Nivel ${BioWayLevels.getDisplayName(_mockUser.nivel)}",
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              // Botón de notificaciones
              IconButton(
                icon: Stack(
                  children: [
                    const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: BioWayColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  // TODO: Implementar notificaciones
                },
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          // Estadísticas rápidas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickStat(
                icon: Icons.recycling,
                value: '${_mockUser.totalResiduosRecolectados}',
                label: 'Recolectados',
              ),
              _buildQuickStat(
                icon: Icons.scale,
                value: '${_mockUser.totalKgReciclados?.toStringAsFixed(0)} kg',
                label: 'Reciclados',
              ),
              _buildQuickStat(
                icon: Icons.eco,
                value: '${_mockUser.totalCO2Evitado.toStringAsFixed(0)} kg',
                label: 'CO2 Evitado',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          SizedBox(width: MediaQuery.of(context).size.width * 0.02),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Sección de residuos disponibles
  Widget _buildResiduosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.05),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Residuos Disponibles',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: _navigateToMap,
                icon: Icon(
                  Icons.map,
                  size: 20,
                  color: BioWayColors.primaryGreen,
                ),
                label: Text(
                  'Ver mapa',
                  style: TextStyle(
                    color: BioWayColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Lista de residuos
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.05),
            itemCount: _residuosDisponibles.length,
            itemBuilder: (context, index) {
              final residuo = _residuosDisponibles[index];
              return _buildResiduoCard(residuo);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResiduoCard(Residuo residuo) {
    return GestureDetector(
      onTap: () => _showResiduoDetail(residuo),
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con tiempo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    BioWayColors.primaryGreen.withValues(alpha:0.1),
                    BioWayColors.primaryGreen.withValues(alpha:0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    residuo.brindadorNombre ?? 'Usuario',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: BioWayColors.primaryGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getTimeAgo(residuo.fechaCreacion),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Contenido
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Materiales
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: residuo.materiales.entries.map((entry) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getMaterialColor(entry.key).withValues(alpha:0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _getMaterialColor(entry.key),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${entry.key}: ${entry.value} kg',
                            style: TextStyle(
                              color: _getMaterialColor(entry.key),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.015),
                    // Dirección
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        SizedBox(width: MediaQuery.of(context).size.width * 0.01),
                        Expanded(
                          child: Text(
                            residuo.direccion,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Footer con puntos
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.monetization_on,
                              color: BioWayColors.primaryGreen,
                              size: 20,
                            ),
                            SizedBox(width: MediaQuery.of(context).size.width * 0.01),
                            Text(
                              '${residuo.puntosEstimados} pts',
                              style: TextStyle(
                                color: BioWayColors.primaryGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                BioWayColors.primaryGreen,
                                BioWayColors.mediumGreen,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Recolectar',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Acciones rápidas
  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Acciones Rápidas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.qr_code_scanner,
                  label: 'Escanear QR',
                  color: BioWayColors.primaryGreen,
                  onTap: _handleScanQR,
                ),
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.03),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.history,
                  label: 'Historial',
                  color: BioWayColors.info,
                  onTap: _navigateToHistory,
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.015),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.route,
                  label: 'Ruta Óptima',
                  color: BioWayColors.warning,
                  onTap: _handleOptimizeRoute,
                ),
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.03),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.bar_chart,
                  label: 'Estadísticas',
                  color: BioWayColors.success,
                  onTap: _handleViewStats,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha:0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Métodos auxiliares
  Color _getMaterialColor(String material) {
    switch (material.toLowerCase()) {
      case 'plastico':
        return const Color(0xFF4CAF50);
      case 'vidrio':
        return const Color(0xFF2196F3);
      case 'papel':
        return const Color(0xFF795548);
      case 'metal':
        return const Color(0xFF9E9E9E);
      case 'organico':
        return const Color(0xFF8BC34A);
      case 'electronico':
        return const Color(0xFF607D8B);
      default:
        return Colors.grey;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours}h';
    } else {
      return 'Hace ${difference.inDays}d';
    }
  }

  // Navegación y acciones
  void _navigateToMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecolectorMapaScreen(
          residuosDisponibles: _residuosDisponibles,
        ),
      ),
    );
  }

  void _navigateToHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RecolectorHistorialScreen(),
      ),
    );
  }

  void _handleScanQR() {
    // TODO: Implementar escaneo QR
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Función de escaneo QR en desarrollo'),
        backgroundColor: BioWayColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _handleOptimizeRoute() {
    // TODO: Implementar optimización de ruta
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Calculando ruta óptima...'),
        backgroundColor: BioWayColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _handleViewStats() {
    // TODO: Implementar estadísticas
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Estadísticas en desarrollo'),
        backgroundColor: BioWayColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showResiduoDetail(Residuo residuo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Contenido
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          color: BioWayColors.primaryGreen,
                          size: 24,
                        ),
                        SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                        Expanded(
                          child: Text(
                            residuo.brindadorNombre ?? 'Usuario',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: BioWayColors.success.withValues(alpha:0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Activo',
                            style: TextStyle(
                              color: BioWayColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.025),
                    // Materiales
                    const Text(
                      'Materiales a recolectar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.015),
                    ...residuo.materiales.entries.map((entry) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getMaterialColor(entry.key).withValues(alpha:0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getMaterialColor(entry.key),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.recycling,
                              color: _getMaterialColor(entry.key),
                              size: 20,
                            ),
                            SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                            Text(
                              entry.key.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${entry.value} kg',
                              style: TextStyle(
                                color: _getMaterialColor(entry.key),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.025),
                    // Información adicional
                    if (residuo.comentarioBrindador != null) ...[
                      const Text(
                        'Comentarios',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          residuo.comentarioBrindador!,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.025),
                    ],
                    // Dirección
                    const Text(
                      'Ubicación',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: BioWayColors.primaryGreen,
                          size: 20,
                        ),
                        SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                        Expanded(
                          child: Text(
                            residuo.direccion,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.025),
                    // Recompensa
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            BioWayColors.primaryGreen.withValues(alpha:0.1),
                            BioWayColors.mediumGreen.withValues(alpha:0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: BioWayColors.primaryGreen.withValues(alpha:0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Puntos a otorgar',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                              Row(
                                children: [
                                  Icon(
                                    Icons.monetization_on,
                                    color: BioWayColors.primaryGreen,
                                    size: 24,
                                  ),
                                  SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                                  Text(
                                    '${residuo.puntosEstimados}',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: BioWayColors.primaryGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'CO2 evitado',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                              Row(
                                children: [
                                  Icon(
                                    Icons.eco,
                                    color: BioWayColors.success,
                                    size: 24,
                                  ),
                                  SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                                  Text(
                                    '${residuo.co2Estimado?.toStringAsFixed(1)} kg',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: BioWayColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                    // Botón de acción
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(context);
                          _handleCollectResidue(residuo);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BioWayColors.primaryGreen,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                        icon: const Icon(
                          Icons.directions_car,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Ir a recolectar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
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
    );
  }

  void _handleCollectResidue(Residuo residuo) {
    // TODO: Implementar lógica de recolección
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Iniciando recolección de residuo ${residuo.id}'),
        backgroundColor: BioWayColors.success,
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
      backgroundColor: BioWayColors.backgroundGrey,
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
          setState(() {
            _residuosDisponibles = _generateMockResiduos();
          });
        },
        color: BioWayColors.primaryGreen,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                    _buildResiduosSection(),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                    _buildQuickActions(),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.04),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}