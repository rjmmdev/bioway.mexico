import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import '../shared/widgets/statistic_card.dart';

class TransformadorInicioScreen extends StatefulWidget {
  const TransformadorInicioScreen({super.key});

  @override
  State<TransformadorInicioScreen> createState() => _TransformadorInicioScreenState();
}

class _TransformadorInicioScreenState extends State<TransformadorInicioScreen> {
  final int _selectedIndex = 0;
  
  // Datos de ejemplo para el transformador
  final String _nombreEmpresa = "La Venta S.A. de C.V.";
  final String _folioTransformador = "T0000001";
  final int _lotesRecibidos = 47;
  final int _productosCreados = 28;
  final double _materialProcesado = 4.5; // en toneladas
  
  // Lista de lotes en proceso (datos de ejemplo)
  final List<Map<String, dynamic>> _lotesEnProceso = [
    {
      'id': 'Firebase_ID_1x7h9k3',
      'origen': 'RECICLADOR PLASTICOS DEL NORTE',
      'fecha': '14/07/2025',
      'material': 'PELLETS',
      'peso': 120,
      'estado': 'RECIBIDO',
      'estadoColor': Colors.blue,
    },
    {
      'id': 'Firebase_ID_2a9m5p1',
      'origen': 'CENTRO DE ACOPIO SUSTENTABLE',
      'fecha': '14/07/2025',
      'material': 'FLAKES',
      'peso': 85.5,
      'estado': 'RECIBIDO',
      'estadoColor': Colors.blue,
    },
  ];

  void _navigateToRecibirLotes() {
    HapticFeedback.lightImpact();
    // TODO: Navegar a pantalla de recepción de lotes
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navegando a Recibir Lotes...')),
    );
  }

  void _navigateToDocumentacion() {
    HapticFeedback.lightImpact();
    // TODO: Navegar a pantalla de documentación
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navegando a Documentación...')),
    );
  }

  void _actualizarDocumentacion(String loteId) {
    HapticFeedback.lightImpact();
    // TODO: Navegar a actualizar documentación del lote
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Actualizando documentación del lote $loteId')),
    );
  }

  void _onBottomNavTapped(int index) {
    HapticFeedback.lightImpact();
    
    if (index == _selectedIndex) return;
    
    switch (index) {
      case 0:
        // Ya estamos en inicio
        break;
      case 1:
        // TODO: Navegar a Producción
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Navegando a Producción...')),
        );
        break;
      case 2:
        // TODO: Navegar a Ayuda
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Navegando a Ayuda...')),
        );
        break;
      case 3:
        // TODO: Navegar a Perfil
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Navegando a Perfil...')),
        );
        break;
    }
  }

  void _onAddPressed() {
    HapticFeedback.lightImpact();
    // TODO: Acción del botón central
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Creando nuevo producto...')),
    );
  }

  Widget _buildLoteCard(Map<String, dynamic> lote) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Header amarillo con ID
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.amber[300],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.qr_code_2,
                  size: 20,
                  color: Colors.amber[900],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    lote['id'],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Contenido del lote
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Origen y fecha
                Text(
                  lote['origen'],
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Fecha: ${lote['fecha']}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                // Tres columnas con iconos
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Material
                    Column(
                      children: [
                        Icon(
                          Icons.recycling,
                          size: 24,
                          color: BioWayColors.ecoceGreen,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lote['material'],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    // Peso
                    Column(
                      children: [
                        Icon(
                          Icons.scale,
                          size: 24,
                          color: BioWayColors.ecoceGreen,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${lote['peso']} kg',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    // Estado
                    Column(
                      children: [
                        Icon(
                          Icons.domain,
                          size: 24,
                          color: BioWayColors.ecoceGreen,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: lote['estadoColor'].withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            lote['estado'],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: lote['estadoColor'],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Botón verde
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _actualizarDocumentacion(lote['id']),
                    icon: const Icon(Icons.update, size: 18),
                    label: const Text('Actualizar Documentación'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header moderno con gradiente (estilo reciclador)
            SliverToBoxAdapter(
              child: Container(
                height: 320,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      BioWayColors.ecoceGreen,
                      BioWayColors.ecoceGreen.withValues(alpha: 0.8),
                    ],
                  ),
                ),
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
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -30,
                      bottom: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    // Contenido
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Saludo y fecha
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Buen día 👋',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 14,
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withValues(alpha: 0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Nombre de la empresa
                          Text(
                            _nombreEmpresa,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 4),
                          // Badge con tipo y folio
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.factory,
                                      size: 16,
                                      color: BioWayColors.ecoceGreen,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Transformador',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: BioWayColors.ecoceGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _folioTransformador,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Primera fila de estadísticas
                          Row(
                            children: [
                              // Card de Lotes Recibidos
                              Expanded(
                                child: StatisticCard(
                                  title: 'Lotes recibidos',
                                  value: _lotesRecibidos.toString(),
                                  icon: Icons.inbox,
                                  color: Colors.blue,
                                  height: 70,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Card de Productos Creados
                              Expanded(
                                child: StatisticCard(
                                  title: 'Productos creados',
                                  value: _productosCreados.toString(),
                                  icon: Icons.add_box,
                                  color: Colors.purple,
                                  height: 70,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Segunda fila con Material Procesado centrado
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Card de Material Procesado centrada
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.45,
                                child: StatisticCard(
                                  title: 'Material procesado',
                                  value: '$_materialProcesado',
                                  unit: 'ton',
                                  icon: Icons.scale,
                                  color: Colors.green,
                                  height: 70,
                                ),
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
            
            // Contenido principal
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.only(top: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        
                      // Acción rápida principal (estilo reciclador)
                      Container(
                        width: double.infinity,
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              BioWayColors.ecoceGreen,
                              BioWayColors.ecoceGreen.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: BioWayColors.ecoceGreen.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _navigateToRecibirLotes,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.qr_code_scanner,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Recibir Lotes',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          'Escanear lote entrante',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.white.withValues(alpha: 0.9),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.white.withValues(alpha: 0.8),
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Botón secundario de documentación (más sutil)
                      OutlinedButton.icon(
                        onPressed: _navigateToDocumentacion,
                        icon: Icon(
                          Icons.description_outlined,
                          color: BioWayColors.ecoceGreen,
                        ),
                        label: const Text(
                          'Gestionar Documentación',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: BioWayColors.ecoceGreen,
                          side: BorderSide(
                            color: BioWayColors.ecoceGreen.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                        
                        const SizedBox(height: 24),
                        
                        // Sección Lotes en Proceso
                        const Text(
                          'Lotes en Proceso',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Lista de lotes
                        ..._lotesEnProceso.map((lote) => _buildLoteCard(lote)),
                        
                        const SizedBox(height: 100), // Espacio para el bottom nav
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      
      // Bottom Navigation Bar
      bottomNavigationBar: EcoceBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onBottomNavTapped,
        primaryColor: BioWayColors.ecoceGreen,
        items: EcoceNavigationConfigs.transformadorItems,
        fabConfig: FabConfig(
          icon: Icons.add,
          onPressed: _onAddPressed,
        ),
      ),
      
      // Floating Action Button
      floatingActionButton: EcoceFloatingActionButton(
        onPressed: _onAddPressed,
        icon: Icons.add,
        backgroundColor: BioWayColors.ecoceGreen,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}