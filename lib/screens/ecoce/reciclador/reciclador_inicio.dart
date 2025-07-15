import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import 'reciclador_escaneo.dart';

class RecicladorHomeScreen extends StatefulWidget {
  const RecicladorHomeScreen({super.key});

  @override
  State<RecicladorHomeScreen> createState() => _RecicladorHomeScreenState();
}

class _RecicladorHomeScreenState extends State<RecicladorHomeScreen> {
  // Índice para la navegación del bottom bar
  int _selectedIndex = 0;

  // Datos de ejemplo para el reciclador (en producción vendrían de la base de datos)
  final String _nombreReciclador = "Juan Pérez García";
  final String _folioReciclador = "R0001234";
  final int _lotesRecibidos = 45;
  final int _lotesCreados = 38;
  final double _pesoProcesado = 1250.5; // en kg

  // Lista de lotes finalizados recientes (datos de ejemplo)
  final List<Map<String, dynamic>> _lotesRecientes = [
    {
      'id': 'L001',
      'fecha': '14/07/2025',
      'peso': 125.5,
      'material': 'PET',
      'origen': 'Acopiador Norte'
    },
    {
      'id': 'L002',
      'fecha': '14/07/2025',
      'peso': 89.3,
      'material': 'HDPE',
      'origen': 'Planta Separación Sur'
    },
    {
      'id': 'L003',
      'fecha': '13/07/2025',
      'peso': 200.8,
      'material': 'PP',
      'origen': 'Acopiador Centro'
    },
    {
      'id': 'L004',
      'fecha': '13/07/2025',
      'peso': 156.2,
      'material': 'PET',
      'origen': 'Planta Separación Este'
    },
  ];

  void _navigateToNewLot() {
    // Navegar a la pantalla de escaneo QR
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QRScannerScreen(),
      ),
    );
  }

  void _navigateToLotControl() {
    // TODO: Implementar navegación a control de lotes
    setState(() {
      _selectedIndex = 1; // Cambiar al tab de lotes
    });
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // TODO: Implementar navegación a las diferentes pantallas
    String destination = '';
    switch (index) {
      case 0:
        destination = 'Inicio';
        break;
      case 1:
        destination = 'Lotes';
        break;
      case 2:
        destination = 'Ayuda';
        break;
      case 3:
        destination = 'Perfil';
        break;
    }

    if (index != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navegando a $destination...'),
          backgroundColor: BioWayColors.info,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BioWayColors.backgroundGrey,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header con información del reciclador
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
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: BioWayColors.ecoceGreen.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Información del reciclador
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _nombreReciclador,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Reciclador',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              _folioReciclador,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: BioWayColors.ecoceGreen,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Estadísticas
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatCard(
                            icon: Icons.inventory_2,
                            value: _lotesRecibidos.toString(),
                            label: 'Lotes\nRecibidos',
                          ),
                          _buildStatCard(
                            icon: Icons.add_box,
                            value: _lotesCreados.toString(),
                            label: 'Lotes\nCreados',
                          ),
                          _buildStatCard(
                            icon: Icons.scale,
                            value: '${_pesoProcesado.toStringAsFixed(1)} kg',
                            label: 'Peso\nProcesado',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Contenido principal
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Botones de acción
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.add_circle_outline,
                            label: 'Crear Nuevo Lote',
                            color: BioWayColors.ecoceGreen,
                            onPressed: _navigateToNewLot,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.list_alt,
                            label: 'Ver Lotes',
                            color: BioWayColors.info,
                            onPressed: _navigateToLotControl,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Título de lotes recientes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Lotes Finalizados Recientes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: BioWayColors.darkGreen,
                          ),
                        ),
                        TextButton(
                          onPressed: _navigateToLotControl,
                          child: Text(
                            'Ver todos',
                            style: TextStyle(
                              color: BioWayColors.ecoceGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Lista de lotes recientes
                    ..._lotesRecientes.map((lote) => _buildLoteCard(lote)).toList(),
                  ],
                ),
              ),
            ],
          ),
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
                _buildBottomNavItem(Icons.home, 'Inicio', 0),
                _buildBottomNavItem(Icons.inventory, 'Lotes', 1),
                const SizedBox(width: 80), // Espacio para el FAB
                _buildBottomNavItem(Icons.help_outline, 'Ayuda', 2),
                _buildBottomNavItem(Icons.person_outline, 'Perfil', 3),
              ],
            ),
          ),
        ),
      ),

      // Floating Action Button
      floatingActionButton: Container(
        height: 60,
        width: 60,
        child: FittedBox(
          child: FloatingActionButton(
            onPressed: _navigateToNewLot,
            backgroundColor: BioWayColors.ecoceGreen,
            foregroundColor: Colors.white,
            elevation: 8,
            shape: const CircleBorder(),
            child: const Icon(
              Icons.add,
              size: 32,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: color.withOpacity(0.3),
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
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoteCard(Map<String, dynamic> lote) {
    // Asignar color según el tipo de material
    Color materialColor = BioWayColors.ecoceGreen;
    switch (lote['material']) {
      case 'PET':
        materialColor = BioWayColors.petBlue;
        break;
      case 'HDPE':
        materialColor = BioWayColors.hdpeGreen;
        break;
      case 'PP':
        materialColor = BioWayColors.ppOrange;
        break;
      default:
        materialColor = BioWayColors.otherPurple;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Navegar a detalle del lote
            HapticFeedback.lightImpact();
          },
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Indicador de material
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: materialColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      lote['material'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: materialColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Información del lote
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Lote ${lote['id']}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: BioWayColors.darkGreen,
                            ),
                          ),
                          Text(
                            '${lote['peso']} kg',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: materialColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Origen: ${lote['origen']}',
                        style: TextStyle(
                          fontSize: 13,
                          color: BioWayColors.textGrey,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Fecha: ${lote['fecha']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: BioWayColors.textGrey.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),

                // Flecha
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey.shade400,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onBottomNavTapped(index),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
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