import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import '../../../utils/bioway_levels.dart';
import '../../../models/bioway/bioway_user.dart';

class RecolectorPerfilScreen extends StatefulWidget {
  const RecolectorPerfilScreen({super.key});

  @override
  State<RecolectorPerfilScreen> createState() => _RecolectorPerfilScreenState();
}

class _RecolectorPerfilScreenState extends State<RecolectorPerfilScreen> {
  // Datos mock del usuario
  late BioWayUser mockUser;
  
  // Datos mock de recolecciones por material
  final Map<String, double> materialesRecolectados = {
    'plastico': 45.5,
    'vidrio': 28.3,
    'papel': 18.0,
    'metal': 15.2,
    'organico': 10.0,
    'electronico': 3.5,
  };

  @override
  void initState() {
    super.initState();
    _initializeMockData();
  }

  void _initializeMockData() {
    mockUser = BioWayUser(
      uid: 'recolector_123',
      nombre: 'Carlos Recolector',
      email: 'carlos@recolector.com',
      tipoUsuario: 'recolector',
      bioCoins: 2500,
      nivel: BioWayLevels.getLevelByCO2(250.8),
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
      vehiculo: 'Camioneta Nissan NP300',
      capacidadKg: 500.0,
      licenciaConducir: 'CDMX123456789',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await Future.delayed(const Duration(seconds: 1));
                },
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildStatsOverview(),
                    const SizedBox(height: 24),
                    _buildTodayStats(),
                    const SizedBox(height: 24),
                    _buildImpactSection(),
                    const SizedBox(height: 24),
                    _buildMaterialsBreakdown(),
                    const SizedBox(height: 24),
                    _buildAccountActions(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            mockUser.nombre,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: BioWayColors.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_shipping,
                  size: 24,
                  color: BioWayColors.primaryGreen,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recolector Certificado',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: BioWayColors.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            BioWayColors.primaryGreen,
            BioWayColors.primaryGreen.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: BioWayColors.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.monetization_on,
                value: '${mockUser.bioCoins}',
                label: 'BioCoins',
                iconColor: Colors.amber,
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              _buildStatItem(
                icon: Icons.emoji_events,
                value: mockUser.nivel,
                label: 'Nivel',
                iconColor: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color iconColor,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: iconColor,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildTodayStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: BioWayColors.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.today,
                  color: BioWayColors.primaryGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Actividad de Hoy',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: BioWayColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSimpleStatCard(
                  icon: Icons.location_on,
                  value: '12',
                  label: 'Puntos\nvisitados',
                  color: BioWayColors.primaryGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSimpleStatCard(
                  icon: Icons.scale,
                  value: '250',
                  label: 'Kilos\nrecolectados',
                  color: BioWayColors.info,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSimpleStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 36,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: BioWayColors.textGrey,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }


  Widget _buildImpactSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.eco,
                color: BioWayColors.primaryGreen,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Mi Impacto Total',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: BioWayColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildImpactCard(
                  icon: Icons.recycling,
                  value: '${mockUser.totalKgReciclados} kg',
                  label: 'Total recolectado',
                  color: BioWayColors.primaryGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildImpactCard(
                  icon: Icons.cloud_off,
                  value: '${mockUser.totalCO2Evitado} kg',
                  label: 'CO₂ evitado',
                  color: BioWayColors.info,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImpactCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: BioWayColors.textGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }


  Widget _buildMaterialsBreakdown() {
    final total = materialesRecolectados.values.reduce((a, b) => a + b);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.pie_chart,
                color: BioWayColors.primaryGreen,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Materiales Recolectados',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: BioWayColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...materialesRecolectados.entries.map((entry) {
            final percentage = (entry.value / total * 100).toStringAsFixed(1);
            return _buildMaterialRow(
              material: entry.key,
              weight: entry.value,
              percentage: percentage,
              color: _getMaterialColor(entry.key),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMaterialRow({
    required String material,
    required double weight,
    required String percentage,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getMaterialIcon(material),
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getMaterialName(material),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '$weight kg',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Stack(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: double.parse(percentage) / 100,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 12,
              color: BioWayColors.textGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActions() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              ListTile(
                onTap: _handleLogout,
                leading: Icon(
                  Icons.logout,
                  color: BioWayColors.error,
                ),
                title: Text(
                  'Cerrar Sesión',
                  style: TextStyle(
                    color: BioWayColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: BioWayColors.error,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                onTap: _showDeleteAccountDialog,
                leading: const Icon(
                  Icons.delete_forever,
                  color: Colors.red,
                ),
                title: const Text(
                  'Eliminar Cuenta',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ],
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

  IconData _getMaterialIcon(String material) {
    switch (material.toLowerCase()) {
      case 'plastico':
        return Icons.local_drink;
      case 'vidrio':
        return Icons.wine_bar;
      case 'papel':
        return Icons.description;
      case 'metal':
        return Icons.recycling;
      case 'organico':
        return Icons.compost;
      case 'electronico':
        return Icons.devices;
      default:
        return Icons.help;
    }
  }

  String _getMaterialName(String material) {
    switch (material.toLowerCase()) {
      case 'plastico':
        return 'Plástico';
      case 'vidrio':
        return 'Vidrio';
      case 'papel':
        return 'Papel y Cartón';
      case 'metal':
        return 'Metal';
      case 'organico':
        return 'Orgánico';
      case 'electronico':
        return 'Electrónico';
      default:
        return material;
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning,
              color: BioWayColors.error,
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text('Eliminar Cuenta'),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que deseas eliminar tu cuenta? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(color: BioWayColors.textGrey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleDeleteAccount();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: BioWayColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _handleDeleteAccount() {
    _showSnackBar('Cuenta eliminada');
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  void _handleLogout() {
    _showSnackBar('Sesión cerrada');
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}