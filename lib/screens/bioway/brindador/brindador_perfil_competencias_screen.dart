import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../utils/colors.dart';
import '../../../models/bioway/bioway_user.dart';
import '../../../models/bioway/material_reciclable.dart';
import '../../../models/bio_competencia.dart';
import '../../../widgets/bioway/bio_celebration_widget.dart';
import '../../../widgets/bioway/bio_motivational_popup.dart';

class BrindadorPerfilCompetenciasScreen extends StatefulWidget {
  const BrindadorPerfilCompetenciasScreen({super.key});

  @override
  State<BrindadorPerfilCompetenciasScreen> createState() => _BrindadorPerfilCompetenciasScreenState();
}

class _BrindadorPerfilCompetenciasScreenState extends State<BrindadorPerfilCompetenciasScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late BioWayUser mockUser;
  BioCompetencia? _miCompetencia;
  List<BioCompetencia> _rankingGlobal = [];
  bool _isLoading = true;
  bool _showCelebration = false;
  String _vistaActual = 'perfil'; // perfil, ranking, logros

  // Datos mock de materiales reciclados
  final Map<String, double> materialesReciclados = {
    'plastico': 85.5,
    'vidrio': 65.3,
    'papel': 45.0,
    'metal': 28.2,
    'organico': 15.0,
    'electronico': 6.5,
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animationController.repeat();
    _initializeMockData();
    _cargarDatos();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeMockData() {
    mockUser = BioWayUser(
      uid: 'mock_123',
      nombre: 'Juan Pérez',
      email: 'juan@example.com',
      tipoUsuario: 'brindador',
      bioCoins: 15780,
      nivel: 'Oro', // Nivel actualizado
      fechaRegistro: DateTime.now().subtract(const Duration(days: 180)),
      direccion: 'Av. Insurgentes Sur 123',
      numeroExterior: '456',
      codigoPostal: '03810',
      estado: 'Ciudad de México',
      municipio: 'Benito Juárez',
      colonia: 'Del Valle',
      totalResiduosBrindados: 123,
      totalKgReciclados: 245.5,
      totalCO2Evitado: 612.3,
    );
  }

  Future<void> _cargarDatos() async {
    await Future.delayed(const Duration(milliseconds: 800));

    _miCompetencia = BioCompetencia(
      userId: 'usuario_actual',
      userName: mockUser.nombre,
      userAvatar: '',
      bioImpulso: 5,
      bioImpulsoMaximo: 8,
      bioImpulsoActivo: true,
      ultimaActividad: DateTime.now().subtract(const Duration(days: 2)),
      reciclajesEstaSemana: 1,
      inicioSemanaActual: DateTime.now(),
      puntosSemanales: 3450,
      puntosTotales: mockUser.bioCoins,
      posicionRanking: 7,
      kgReciclados: mockUser.totalKgReciclados,
      co2Evitado: mockUser.totalCO2Evitado,
      nivel: 3,
      insigniaActual: '🥇',
    );

    // Generar ranking simplificado
    _rankingGlobal = List.generate(10, (index) {
      return BioCompetencia(
        userId: index == 6 ? 'usuario_actual' : 'user_$index',
        userName: index == 6 ? mockUser.nombre : 'Usuario ${index + 1}',
        userAvatar: '',
        bioImpulso: 15 - index,
        bioImpulsoMaximo: 15 - index,
        bioImpulsoActivo: true,
        ultimaActividad: DateTime.now().subtract(Duration(hours: index * 2)),
        reciclajesEstaSemana: 2,
        inicioSemanaActual: DateTime.now(),
        puntosSemanales: 8920 - (index * 850),
        puntosTotales: 45200 - (index * 3000),
        posicionRanking: index + 1,
        kgReciclados: 890.2 - (index * 80),
        co2Evitado: 2225.5 - (index * 200),
        nivel: index < 3 ? 5 : index < 6 ? 4 : 3,
        insigniaActual: index < 3 ? '💎' : index < 6 ? '🥇' : '🥈',
      );
    });

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      _buildHeader(),
                      _buildNavigationPills(),
                      Expanded(
                        child: _buildContent(),
                      ),
                    ],
                  ),
          ),
          if (_showCelebration)
            BioCelebrationWidget(
              title: '¡Felicidades!',
              message: '¡Nuevo logro desbloqueado!',
              onComplete: () {
                setState(() {
                  _showCelebration = false;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mockUser.nombre,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${mockUser.colonia}, ${mockUser.municipio}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _getLevelColor(mockUser.nivel),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  _getLevelIcon(mockUser.nivel),
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  mockUser.nivel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationPills() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildPill('Perfil', 'perfil', Icons.person_rounded),
          _buildPill('Ranking', 'ranking', Icons.leaderboard_rounded),
          _buildPill('Logros', 'logros', Icons.emoji_events_rounded),
        ],
      ),
    );
  }

  Widget _buildPill(String label, String value, IconData icon) {
    final isSelected = _vistaActual == value;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _vistaActual = value;
          });
          HapticFeedback.lightImpact();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? BioWayColors.primaryGreen : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? BioWayColors.primaryGreen : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_vistaActual) {
      case 'ranking':
        return _buildRankingView();
      case 'logros':
        return _buildLogrosView();
      default:
        return _buildPerfilView();
    }
  }

  Widget _buildPerfilView() {
    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildStatsOverview(),
          const SizedBox(height: 24),
          _buildImpactSection(),
          const SizedBox(height: 24),
          _buildMaterialsBreakdown(),
          const SizedBox(height: 24),
          _buildAccountActions(),
          const SizedBox(height: 20),
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
            BioWayColors.primaryGreen.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: BioWayColors.primaryGreen.withOpacity(0.3),
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
                value: mockUser.bioCoins.toString(),
                label: 'BioCoins',
                isLight: true,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildStatItem(
                icon: Icons.emoji_events,
                value: '#${_miCompetencia?.posicionRanking ?? '-'}',
                label: 'Ranking',
                isLight: true,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BioImpulso Semanal',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_miCompetencia?.bioImpulso ?? 0} semanas consecutivas',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _miCompetencia?.bioImpulsoActivo == true 
                        ? Colors.green 
                        : Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _miCompetencia?.bioImpulsoActivo == true ? 'Activo' : 'Inactivo',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    bool isLight = false,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: isLight ? Colors.white.withOpacity(0.9) : BioWayColors.primaryGreen,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isLight ? Colors.white : const Color(0xFF1A1A1A),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isLight ? Colors.white.withOpacity(0.8) : Colors.grey[600],
            ),
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tu Impacto Total',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildImpactCard(
                  icon: Icons.recycling,
                  value: '${mockUser.totalKgReciclados.toStringAsFixed(1)} kg',
                  label: 'Total reciclado',
                  color: BioWayColors.primaryGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildImpactCard(
                  icon: Icons.eco,
                  value: '${mockUser.totalCO2Evitado.toStringAsFixed(1)} kg',
                  label: 'CO₂ evitado',
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.green[700],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getImpactEquivalent(mockUser.totalCO2Evitado),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.green[700],
                    ),
                  ),
                ),
              ],
            ),
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
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsBreakdown() {
    final totalKg = materialesReciclados.values.reduce((a, b) => a + b);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          const Text(
            'Desglose por Material',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          ...materialesReciclados.entries.map((entry) {
            final material = MaterialReciclable.findById(entry.key);
            final percentage = (entry.value / totalKg * 100);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: (material?.color ?? Colors.grey).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _getIconForMaterial(entry.key),
                          color: material?.color ?? Colors.grey,
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
                                  material?.nombre ?? entry.key,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '${entry.value.toStringAsFixed(1)} kg',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: material?.color ?? Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percentage / 100,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  material?.color ?? Colors.grey,
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildAccountActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _handleLogout,
            style: ElevatedButton.styleFrom(
              backgroundColor: BioWayColors.darkGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.logout),
            label: const Text(
              'Cerrar Sesión',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _showDeleteAccountDialog,
          child: Text(
            'Eliminar cuenta',
            style: TextStyle(
              color: Colors.red[600],
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRankingView() {
    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildRankingHeader(),
          const SizedBox(height: 20),
          ..._rankingGlobal.map((competidor) {
            final esMiPerfil = competidor.userId == 'usuario_actual';
            return _buildRankingItem(competidor, esMiPerfil: esMiPerfil);
          }),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildRankingHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            BioWayColors.primaryGreen,
            BioWayColors.primaryGreen.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ranking General',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Top 10 recicladores de todos los tiempos',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingItem(BioCompetencia competidor, {bool esMiPerfil = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: esMiPerfil ? BioWayColors.primaryGreen.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: esMiPerfil
            ? Border.all(color: BioWayColors.primaryGreen, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getColorPorPosicion(competidor.posicionRanking),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${competidor.posicionRanking}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 20,
              backgroundColor: BioWayColors.lightGreen.withOpacity(0.3),
              child: Text(
                competidor.userName[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: BioWayColors.primaryGreen,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    competidor.userName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.recycling,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${competidor.kgReciclados.toStringAsFixed(0)} kg',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${competidor.puntosTotales}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: BioWayColors.primaryGreen,
                  ),
                ),
                Text(
                  'puntos',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogrosView() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildLogroCard(
          titulo: 'Primera vez',
          descripcion: 'Realiza tu primer reciclaje',
          bioCoins: 50,
          completada: true,
          icon: Icons.celebration_rounded,
          nivel: 'Bronce',
        ),
        _buildLogroCard(
          titulo: 'Nivel Bronce',
          descripcion: 'Alcanza 50 kg de CO₂ evitado',
          bioCoins: 100,
          completada: true,
          icon: Icons.shield_rounded,
          nivel: 'Bronce',
        ),
        _buildLogroCard(
          titulo: 'Nivel Plata',
          descripcion: 'Alcanza 200 kg de CO₂ evitado',
          bioCoins: 200,
          completada: true,
          icon: Icons.shield_rounded,
          nivel: 'Plata',
        ),
        _buildLogroCard(
          titulo: 'Nivel Oro',
          descripcion: 'Alcanza 500 kg de CO₂ evitado',
          bioCoins: 500,
          completada: true,
          icon: Icons.shield_rounded,
          nivel: 'Oro',
        ),
        _buildLogroCard(
          titulo: 'Nivel Platino',
          descripcion: 'Alcanza 1000 kg de CO₂ evitado',
          bioCoins: 1000,
          completada: false,
          icon: Icons.shield_rounded,
          nivel: 'Platino',
        ),
        _buildLogroCard(
          titulo: 'Nivel Diamante',
          descripcion: 'Alcanza 2000 kg de CO₂ evitado',
          bioCoins: 2000,
          completada: false,
          icon: Icons.shield_rounded,
          nivel: 'Diamante',
        ),
        _buildLogroCard(
          titulo: 'Racha Semanal',
          descripcion: 'Mantén tu BioImpulso por 4 semanas',
          bioCoins: 300,
          completada: _miCompetencia!.bioImpulsoMaximo >= 4,
          icon: Icons.local_fire_department,
          nivel: 'Especial',
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildLogroCard({
    required String titulo,
    required String descripcion,
    required int bioCoins,
    required bool completada,
    required IconData icon,
    required String nivel,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: completada ? BioWayColors.primaryGreen.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: completada
            ? Border.all(color: BioWayColors.primaryGreen, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: completada
                  ? _getLevelColor(nivel)
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              completada ? Icons.check_rounded : icon,
              color: completada ? Colors.white : Colors.grey[400],
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: completada ? BioWayColors.primaryGreen : const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  descripcion,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: completada 
                  ? BioWayColors.primaryGreen.withOpacity(0.1)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/svg/biocoin.svg',
                  width: 16,
                  height: 16,
                  colorFilter: ColorFilter.mode(
                    completada ? BioWayColors.primaryGreen : Colors.grey[400]!,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '+$bioCoins',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: completada ? BioWayColors.primaryGreen : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getLevelColor(String nivel) {
    switch (nivel) {
      case 'Bronce':
        return Colors.brown;
      case 'Plata':
        return Colors.grey;
      case 'Oro':
        return Colors.amber;
      case 'Platino':
        return Colors.blueGrey;
      case 'Diamante':
        return Colors.blue;
      case 'Especial':
        return Colors.purple;
      default:
        return BioWayColors.primaryGreen;
    }
  }

  IconData _getLevelIcon(String nivel) {
    switch (nivel) {
      case 'Bronce':
      case 'Plata':
      case 'Oro':
      case 'Platino':
      case 'Diamante':
        return Icons.shield;
      default:
        return Icons.eco;
    }
  }

  Color _getColorPorPosicion(int posicion) {
    if (posicion == 1) return Colors.amber;
    if (posicion == 2) return Colors.grey;
    if (posicion == 3) return Colors.brown;
    return BioWayColors.primaryGreen;
  }

  IconData _getIconForMaterial(String materialId) {
    switch (materialId) {
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
        return Icons.recycling;
    }
  }

  String _getImpactEquivalent(double co2) {
    if (co2 < 100) {
      return 'Equivale a plantar ${(co2 / 22).toStringAsFixed(0)} árboles';
    } else if (co2 < 500) {
      return 'Como sacar 1 auto de circulación por ${(co2 / 4.6).toStringAsFixed(0)} días';
    } else if (co2 < 1000) {
      return 'Igual a ${(co2 / 138).toStringAsFixed(1)} meses sin usar auto';
    } else {
      return 'Como plantar un bosque de ${(co2 / 22).toStringAsFixed(0)} árboles';
    }
  }

  void _handleLogout() {
    _showSnackBar('Sesión cerrada');
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  void _showDeleteAccountDialog() {
    final TextEditingController confirmController = TextEditingController();
    bool isButtonEnabled = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
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
                  const SizedBox(width: 12),
                  const Text('Eliminar Cuenta'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Esta acción es permanente y no se puede deshacer. Se eliminarán todos tus datos.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Escribe "ELIMINAR" para confirmar:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmController,
                    onChanged: (value) {
                      setState(() {
                        isButtonEnabled = value == 'ELIMINAR';
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'ELIMINAR',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: BioWayColors.error,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isButtonEnabled
                      ? () {
                          Navigator.of(dialogContext).pop();
                          _deleteAccount();
                        }
                      : null,
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
            );
          },
        );
      },
    );
  }

  void _deleteAccount() {
    _showSnackBar('Cuenta eliminada exitosamente');
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