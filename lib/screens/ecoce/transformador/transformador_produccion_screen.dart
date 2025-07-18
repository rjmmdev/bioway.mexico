import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';

class TransformadorProduccionScreen extends StatefulWidget {
  const TransformadorProduccionScreen({super.key});

  @override
  State<TransformadorProduccionScreen> createState() => _TransformadorProduccionScreenState();
}

class _TransformadorProduccionScreenState extends State<TransformadorProduccionScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Datos de producción
  final double _capacidadUtilizada = 85.0;
  final double _materialProcesado = 1.2; // toneladas
  
  // Lista de lotes en proceso
  final List<Map<String, dynamic>> _lotesEnProceso = [
    {
      'id': 'Firebase_ID_3x9k2m1',
      'fechaInicio': '14/07/2025 08:30',
      'material': 'PELLETS',
      'peso': 120,
      'estado': 'EN PROCESO',
      'procesos': ['Lavado', 'Molido', 'Extrusión'],
    },
    {
      'id': 'Firebase_ID_4m2p7k8',
      'fechaInicio': '14/07/2025 10:15',
      'material': 'HOJUELAS',
      'peso': 85,
      'estado': 'EN PROCESO',
      'procesos': ['Clasificación', 'Lavado', 'Secado'],
    },
    {
      'id': 'Firebase_ID_5n1q3r9',
      'fechaInicio': '13/07/2025 14:45',
      'material': 'PELLETS',
      'peso': 150,
      'estado': 'EN PROCESO',
      'procesos': ['Molido', 'Lavado', 'Extrusión', 'Enfriamiento'],
    },
  ];
  
  // Lista de lotes completados
  final List<Map<String, dynamic>> _lotesCompletados = [
    {
      'id': 'Firebase_ID_1a5h7k3',
      'fechaInicio': '13/07/2025 09:00',
      'fechaFin': '13/07/2025 16:30',
      'material': 'PELLETS',
      'peso': 200,
      'estado': 'COMPLETADO',
      'procesos': ['Lavado', 'Molido', 'Extrusión', 'Enfriamiento', 'Empaque'],
    },
    {
      'id': 'Firebase_ID_2b8m4p6',
      'fechaInicio': '12/07/2025 11:00',
      'fechaFin': '13/07/2025 08:00',
      'material': 'HOJUELAS',
      'peso': 175,
      'estado': 'COMPLETADO',
      'procesos': ['Clasificación', 'Lavado', 'Secado', 'Empaque'],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Header que cubre todo el ancho
          Container(
            width: double.infinity,
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
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  // Patrón de fondo
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
                  // Contenido
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const Text(
                          'Control de Producción',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Gestión de procesos y capacidad',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Capacidad Card y Tabs en un área scrollable
          Expanded(
            child: Column(
              children: [
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Card de Capacidad
                        _buildCapacityCard(),
                        const SizedBox(height: 20),
                        
                        // Tabs
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicator: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            labelColor: BioWayColors.ecoceGreen,
                            unselectedLabelColor: Colors.grey[600],
                            labelStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            labelPadding: const EdgeInsets.symmetric(horizontal: 24),
                            tabs: const [
                              Tab(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text('En Proceso'),
                                ),
                              ),
                              Tab(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text('Completados'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // TabBarView para los lotes
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab En Proceso
                      _buildLotesList(_lotesEnProceso),
                      // Tab Completados
                      _buildLotesList(_lotesCompletados),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapacityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
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
              const Text(
                '📊',
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              const Text(
                'Capacidad de Producción - Hoy',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    '${_capacidadUtilizada.toInt()}%',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  Text(
                    'Capacidad Utilizada',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.grey[300],
              ),
              Column(
                children: [
                  Text(
                    '$_materialProcesado t',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  Text(
                    'Material Procesado',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Barra de progreso
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _capacidadUtilizada / 100,
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Máxima eficiencia: ${(100 - _capacidadUtilizada).toInt()}% restante disponible',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLotesList(List<Map<String, dynamic>> lotes) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 16, bottom: 100), // Espacio para el FAB y navegación
        itemCount: lotes.length,
        itemBuilder: (context, index) {
          final lote = lotes[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildLoteCard(lote),
          );
        },
      ),
    );
  }

  Widget _buildLoteCard(Map<String, dynamic> lote) {
    final bool isCompleted = lote['estado'] == 'COMPLETADO';
    
    return Container(
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
      child: Column(
        children: [
          // Header amarillo
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber[400],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  lote['id'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                if (isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'COMPLETADO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fecha de inicio
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Inicio: ${lote['fechaInicio']}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    if (isCompleted) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Fin: ${lote['fechaFin']}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                
                // Información del lote
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLoteInfo(
                      Icons.recycling_outlined,
                      lote['material'],
                      'Material',
                    ),
                    Container(
                      height: 30,
                      width: 1,
                      color: Colors.grey[300],
                    ),
                    _buildLoteInfo(
                      Icons.scale_outlined,
                      '${lote['peso']} kg',
                      'Peso',
                    ),
                    Container(
                      height: 30,
                      width: 1,
                      color: Colors.grey[300],
                    ),
                    _buildLoteInfo(
                      Icons.check_circle_outline,
                      lote['estado'],
                      'Estado',
                      isStatus: true,
                      statusColor: isCompleted ? Colors.green : Colors.blue,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Procesos aplicados
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Proceso aplicado:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (lote['procesos'] as List<String>).map((proceso) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            proceso,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Botón de acción
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      // TODO: Implementar acción
                    },
                    icon: Icon(
                      isCompleted ? Icons.visibility : Icons.update,
                      size: 18,
                    ),
                    label: Text(
                      isCompleted ? 'Ver Detalles' : 'Actualizar Estado',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BioWayColors.ecoceGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

  Widget _buildLoteInfo(IconData icon, String value, String label, 
      {bool isStatus = false, Color? statusColor}) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(height: 4),
        if (isStatus && statusColor != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        else
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}