import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import '../../../models/bioway/residuo.dart';

class RecolectorHistorialScreen extends StatefulWidget {
  const RecolectorHistorialScreen({super.key});

  @override
  State<RecolectorHistorialScreen> createState() => _RecolectorHistorialScreenState();
}

class _RecolectorHistorialScreenState extends State<RecolectorHistorialScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Datos mock
  late List<Residuo> _historialResiduos;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _generateMockData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  void _generateMockData() {
    _historialResiduos = [
      Residuo(
        id: 'hist_001',
        brindadorId: 'brindador_001',
        brindadorNombre: 'María García',
        materiales: {'plastico': 5.0, 'vidrio': 3.0},
        estado: 'recolectado',
        fechaCreacion: DateTime.now().subtract(const Duration(days: 1)),
        fechaRecoleccion: DateTime.now().subtract(const Duration(hours: 20)),
        latitud: 19.3834,
        longitud: -99.1755,
        direccion: 'Av. Insurgentes 234, Del Valle',
        fotos: [],
        puntosEstimados: 240,
        puntosOtorgados: 240,
        co2Estimado: 8.5,
        co2Evitado: 8.5,
        recolectorId: 'recolector_123',
      ),
      Residuo(
        id: 'hist_002',
        brindadorId: 'brindador_002',
        brindadorNombre: 'Juan Hernández',
        materiales: {'papel': 10.0, 'metal': 2.0},
        estado: 'recolectado',
        fechaCreacion: DateTime.now().subtract(const Duration(days: 2)),
        fechaRecoleccion: DateTime.now().subtract(const Duration(days: 1, hours: 18)),
        latitud: 19.3900,
        longitud: -99.1700,
        direccion: 'Calle Puebla 567, Roma Norte',
        fotos: [],
        puntosEstimados: 320,
        puntosOtorgados: 320,
        co2Estimado: 12.0,
        co2Evitado: 12.0,
        recolectorId: 'recolector_123',
      ),
      Residuo(
        id: 'hist_003',
        brindadorId: 'brindador_003',
        brindadorNombre: 'Ana López',
        materiales: {'plastico': 8.0, 'papel': 5.0},
        estado: 'recolectado',
        fechaCreacion: DateTime.now().subtract(const Duration(days: 3)),
        fechaRecoleccion: DateTime.now().subtract(const Duration(days: 2, hours: 16)),
        latitud: 19.3950,
        longitud: -99.1650,
        direccion: 'Av. Álvaro Obregón 890, Roma Sur',
        fotos: [],
        puntosEstimados: 460,
        puntosOtorgados: 460,
        co2Estimado: 15.5,
        co2Evitado: 15.5,
        recolectorId: 'recolector_123',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BioWayColors.backgroundGrey,
      appBar: AppBar(
        title: const Text('Historial de Recolecciones'),
        backgroundColor: BioWayColors.primaryGreen,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Hoy'),
            Tab(text: 'Esta Semana'),
            Tab(text: 'Este Mes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHistorialList(_getHoyResiduos()),
          _buildHistorialList(_getSemanaResiduos()),
          _buildHistorialList(_getMesResiduos()),
        ],
      ),
    );
  }
  
  List<Residuo> _getHoyResiduos() {
    final hoy = DateTime.now();
    return _historialResiduos.where((r) {
      final fecha = r.fechaRecoleccion!;
      return fecha.year == hoy.year && 
             fecha.month == hoy.month && 
             fecha.day == hoy.day;
    }).toList();
  }
  
  List<Residuo> _getSemanaResiduos() {
    final ahora = DateTime.now();
    final inicioSemana = ahora.subtract(Duration(days: ahora.weekday - 1));
    return _historialResiduos.where((r) {
      return r.fechaRecoleccion!.isAfter(inicioSemana);
    }).toList();
  }
  
  List<Residuo> _getMesResiduos() {
    final ahora = DateTime.now();
    return _historialResiduos.where((r) {
      final fecha = r.fechaRecoleccion!;
      return fecha.year == ahora.year && fecha.month == ahora.month;
    }).toList();
  }
  
  Widget _buildHistorialList(List<Residuo> residuos) {
    if (residuos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            Text(
              'No hay recolecciones en este período',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }
    
    // Calcular estadísticas
    final totalKg = residuos.fold<double>(
      0,
      (sum, r) => sum + r.materiales.values.fold(0.0, (s, v) => s + v),
    );
    final totalPuntos = residuos.fold<int>(
      0,
      (sum, r) => sum + (r.puntosOtorgados ?? 0),
    );
    final totalCO2 = residuos.fold<double>(
      0,
      (sum, r) => sum + (r.co2Evitado ?? 0),
    );
    
    return Column(
      children: [
        // Estadísticas del período
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                BioWayColors.primaryGreen,
                BioWayColors.mediumGreen,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: BioWayColors.primaryGreen.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatisticItem(
                '${residuos.length}',
                'Recolecciones',
                Icons.local_shipping,
              ),
              _buildStatisticItem(
                '${totalKg.toStringAsFixed(1)} kg',
                'Reciclados',
                Icons.scale,
              ),
              _buildStatisticItem(
                '$totalPuntos pts',
                'Otorgados',
                Icons.monetization_on,
              ),
              _buildStatisticItem(
                '${totalCO2.toStringAsFixed(1)} kg',
                'CO2 Evitado',
                Icons.eco,
              ),
            ],
          ),
        ),
        // Lista de recolecciones
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: residuos.length,
            itemBuilder: (context, index) {
              final residuo = residuos[index];
              return _buildHistorialCard(residuo);
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatisticItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.005),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
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
    );
  }
  
  Widget _buildHistorialCard(Residuo residuo) {
    final totalKg = residuo.materiales.values.fold(0.0, (sum, kg) => sum + kg);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showDetalleResiduo(residuo),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          residuo.brindadorNombre ?? 'Usuario',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                        Text(
                          _formatDate(residuo.fechaRecoleccion!),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: BioWayColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: BioWayColors.success,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Completado',
                          style: TextStyle(
                            color: BioWayColors.success,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Materiales
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: residuo.materiales.entries.map((entry) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getMaterialColor(entry.key).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${entry.key}: ${entry.value} kg',
                      style: TextStyle(
                        color: _getMaterialColor(entry.key),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              // Dirección
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
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
              const SizedBox(height: 12),
              // Footer con estadísticas
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMiniStat(
                      Icons.scale,
                      '$totalKg kg',
                      BioWayColors.info,
                    ),
                    _buildMiniStat(
                      Icons.monetization_on,
                      '${residuo.puntosOtorgados} pts',
                      BioWayColors.primaryGreen,
                    ),
                    _buildMiniStat(
                      Icons.eco,
                      '${residuo.co2Evitado?.toStringAsFixed(1)} kg CO2',
                      BioWayColors.success,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMiniStat(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
  
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
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Hoy ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Ayer ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
  
  void _showDetalleResiduo(Residuo residuo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
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
            // Título
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: BioWayColors.success,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Recolección Completada',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Contenido
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info del brindador
                    Text(
                      'Brindador',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                    Text(
                      residuo.brindadorNombre ?? 'Usuario',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                    // Fechas
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fecha de solicitud',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                              Text(
                                _formatFullDate(residuo.fechaCreacion),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fecha de recolección',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                              Text(
                                _formatFullDate(residuo.fechaRecoleccion!),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Materiales recolectados
                    const Text(
                      'Materiales Recolectados',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...residuo.materiales.entries.map((entry) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getMaterialColor(entry.key).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.recycling,
                              color: _getMaterialColor(entry.key),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
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
                    const SizedBox(height: 20),
                    // Resumen
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            BioWayColors.primaryGreen.withOpacity(0.1),
                            BioWayColors.mediumGreen.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Puntos Otorgados',
                                style: TextStyle(fontSize: 14),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.monetization_on,
                                    color: BioWayColors.primaryGreen,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${residuo.puntosOtorgados}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: BioWayColors.primaryGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'CO2 Evitado',
                                style: TextStyle(fontSize: 14),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.eco,
                                    color: BioWayColors.success,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${residuo.co2Evitado?.toStringAsFixed(1)} kg',
                                    style: TextStyle(
                                      fontSize: 18,
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatFullDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}