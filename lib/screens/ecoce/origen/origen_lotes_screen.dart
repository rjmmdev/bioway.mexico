import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import 'origen_codigo_qr.dart';
import 'origen_crear_lote_screen.dart';
import 'origen_ayuda.dart';
import 'origen_perfil.dart';
import 'widgets/lote_card.dart';

class OrigenLotesScreen extends StatefulWidget {
  const OrigenLotesScreen({super.key});

  @override
  State<OrigenLotesScreen> createState() => _OrigenLotesScreenState();
}

class _OrigenLotesScreenState extends State<OrigenLotesScreen> {
  // Índice para la navegación del bottom bar
  int _selectedIndex = 1; // Lotes está seleccionado

  // Filtros
  String _filtroMaterial = 'Todos';
  String _filtroPeriodo = 'Esta semana';
  String _filtroTipo = 'Todos los tipos';

  // Lista de lotes (datos de ejemplo)
  final List<Map<String, dynamic>> _lotes = [
    {
      'firebaseId': 'FID_1x7h9k3',
      'material': 'PEBD',
      'peso': 125,
      'fecha': '15/07/2025',
      'presentacion': 'Pacas',
      'fuente': 'Programa Escolar Norte',
    },
    {
      'firebaseId': 'FID_2y8j0l4',
      'material': 'PP',
      'peso': 175,
      'fecha': '14/07/2025',
      'presentacion': 'Sacos',
      'fuente': 'Programa Escolar Norte',
    },
    {
      'firebaseId': 'FID_3z9k1m5',
      'material': 'Multi',
      'peso': 150,
      'fecha': '14/07/2025',
      'presentacion': 'Pacas',
      'fuente': 'Programa Escolar Centro',
    },
    {
      'firebaseId': 'FID_4a0b2n6',
      'material': 'PEBD',
      'peso': 200,
      'fecha': '13/07/2025',
      'presentacion': 'Sacos',
      'fuente': 'Recolección Municipal',
    },
    {
      'firebaseId': 'FID_5c1d3p7',
      'material': 'PP',
      'peso': 180,
      'fecha': '13/07/2025',
      'presentacion': 'Pacas',
      'fuente': 'Centro Comunitario Sur',
    },
  ];

  // Estadísticas
  int get totalLotes => _lotes.length;
  double get pesoTotal => _lotes.fold(0, (sum, lote) => sum + lote['peso']);
  String get materialPredominante {
    Map<String, int> conteo = {};
    for (var lote in _lotes) {
      conteo[lote['material']] = (conteo[lote['material']] ?? 0) + 1;
    }
    var sorted = conteo.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    if (sorted.isEmpty) return 'N/A';
    int total = sorted.fold(0, (sum, entry) => sum + entry.value);
    double porcentaje = (sorted.first.value / total) * 100;
    return '${porcentaje.toStringAsFixed(0)}% ${sorted.first.key}';
  }

  void _verCodigoQR(Map<String, dynamic> lote) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrigenCodigoQRScreen(
          firebaseId: lote['firebaseId'],
          material: lote['material'],
          peso: lote['peso'].toDouble(),
          presentacion: lote['presentacion'],
          fuente: lote['fuente'],
          fechaCreacion: DateTime.now(), // En producción vendría de la base de datos
        ),
      ),
    );
  }

  void _onBottomNavTapped(int index) {
    HapticFeedback.lightImpact();
    
    if (index == _selectedIndex) return;
    
    switch (index) {
      case 0:
        Navigator.pop(context);
        break;
      case 1:
        // Ya estamos en lotes
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
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const OrigenPerfilScreen(),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Lotes',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Filtros de material
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildMaterialFilter('Todos', _filtroMaterial == 'Todos'),
                      const SizedBox(width: 8),
                      _buildMaterialFilter('PEBD', _filtroMaterial == 'PEBD'),
                      const SizedBox(width: 8),
                      _buildMaterialFilter('PP', _filtroMaterial == 'PP'),
                      const SizedBox(width: 8),
                      _buildMaterialFilter('Multi', _filtroMaterial == 'Multi'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                
                // Dropdowns de filtros
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdownFilter(
                        value: _filtroPeriodo,
                        items: ['Esta semana', 'Este mes', 'Últimos 3 meses', 'Todo el año'],
                        onChanged: (value) {
                          setState(() {
                            _filtroPeriodo = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdownFilter(
                        value: _filtroTipo,
                        items: ['Todos los tipos', 'Pacas', 'Sacos'],
                        onChanged: (value) {
                          setState(() {
                            _filtroTipo = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Estadísticas
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: BioWayColors.lightGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: BioWayColors.ecoceGreen.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatistic(totalLotes.toString(), 'Lotes totales'),
                _buildStatistic('${(pesoTotal / 1000).toStringAsFixed(1)} t', 'Peso total'),
                _buildStatistic(materialPredominante, 'PET'),
              ],
            ),
          ),

          // Lista de lotes
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _lotes.length,
              itemBuilder: (context, index) {
                return LoteCard(
                  lote: _lotes[index],
                  onQRTap: () => _verCodigoQR(_lotes[index]),
                );
              },
            ),
          ),
        ],
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

  Widget _buildMaterialFilter(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _filtroMaterial = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? BioWayColors.ecoceGreen : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        icon: const Icon(Icons.keyboard_arrow_down),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: const TextStyle(fontSize: 14),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildStatistic(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: BioWayColors.darkGreen,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: BioWayColors.darkGreen.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildLoteCard(Map<String, dynamic> lote) {
    final materialColor = _getMaterialColor(lote['material']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _verCodigoQR(lote),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header del lote
                Row(
                  children: [
                    // Icono del material
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: materialColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        _getMaterialIcon(lote['material']),
                        color: materialColor,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Información principal
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: materialColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  lote['material'],
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: materialColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  lote['firebaseId'],
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.amber,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            lote['fuente'],
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    // Botón de acción rápida
                    Container(
                      decoration: BoxDecoration(
                        color: BioWayColors.ecoceGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () => _verCodigoQR(lote),
                        icon: Icon(
                          Icons.qr_code_2,
                          color: BioWayColors.ecoceGreen,
                        ),
                        tooltip: 'Ver QR',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Detalles del lote
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildLoteDetail(
                        icon: Icons.scale,
                        label: 'Peso',
                        value: '${lote['peso']} kg',
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey.withOpacity(0.3),
                      ),
                      _buildLoteDetail(
                        icon: Icons.inventory_2,
                        label: 'Presentación',
                        value: lote['presentacion'],
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey.withOpacity(0.3),
                      ),
                      _buildLoteDetail(
                        icon: Icons.calendar_today,
                        label: 'Fecha',
                        value: lote['fecha'],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoteDetail({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey[600],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Color _getMaterialColor(String material) {
    switch (material) {
      case 'PET':
        return Colors.blue;
      case 'HDPE':
        return Colors.orange;
      case 'PP':
        return Colors.purple;
      case 'PVC':
        return Colors.red;
      case 'LDPE':
        return Colors.teal;
      case 'PS':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  IconData _getMaterialIcon(String material) {
    switch (material) {
      case 'PET':
        return Icons.local_drink;
      case 'HDPE':
        return Icons.cleaning_services;
      case 'PP':
        return Icons.kitchen;
      case 'PVC':
        return Icons.plumbing;
      case 'LDPE':
        return Icons.shopping_bag;
      case 'PS':
        return Icons.fastfood;
      default:
        return Icons.recycling;
    }
  }


  Widget _buildBottomNavItem(IconData icon, IconData activeIcon, String label, int index) {
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