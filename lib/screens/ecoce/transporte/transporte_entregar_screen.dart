import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'widgets/transporte_bottom_navigation.dart';
import 'transporte_inicio_screen.dart';
import 'transporte_ayuda_screen.dart';
import 'transporte_perfil_screen.dart';
import 'transporte_qr_entrega_screen.dart';

class TransporteEntregarScreen extends StatefulWidget {
  const TransporteEntregarScreen({super.key});

  @override
  State<TransporteEntregarScreen> createState() => _TransporteEntregarScreenState();
}

class _TransporteEntregarScreenState extends State<TransporteEntregarScreen> {
  final int _selectedIndex = 1;
  
  // Mapa para agrupar lotes por origen
  Map<String, List<Map<String, dynamic>>> lotesAgrupados = {};
  
  // Estado de selección por lote
  Map<String, bool> lotesSeleccionados = {};
  
  // Estado de selección por grupo
  Map<String, bool> gruposSeleccionados = {};
  
  // Variables de usuario (TODO: Obtener del auth)
  final String nombreOperador = 'Juan Pérez';
  final String folioOperador = 'V0000001';
  
  @override
  void initState() {
    super.initState();
    _cargarLotesEnTransito();
  }
  
  void _cargarLotesEnTransito() {
    // TODO: Implementar GET /lotes?status=in-transit&transportista=folio
    // Por ahora usamos datos mock
    List<Map<String, dynamic>> lotesMock = [
      {
        'id': 'L001',
        'firebaseId': 'Firebase_ID_1x7h9k3',
        'material': 'PET',
        'peso': 45.5,
        'presentacion': 'Pacas',
        'origen': 'Centro de Acopio Norte',
      },
      {
        'id': 'L002',
        'firebaseId': 'Firebase_ID_2y8j0m4',
        'material': 'HDPE',
        'peso': 32.0,
        'presentacion': 'Sacos',
        'origen': 'Centro de Acopio Norte',
      },
      {
        'id': 'L003',
        'firebaseId': 'Firebase_ID_3z9k1n5',
        'material': 'PP',
        'peso': 28.7,
        'presentacion': 'Pacas',
        'origen': 'Centro de Acopio Sur',
      },
      {
        'id': 'L004',
        'firebaseId': 'Firebase_ID_4a0l2o6',
        'material': 'PET',
        'peso': 51.2,
        'presentacion': 'Sacos',
        'origen': 'Centro de Acopio Sur',
      },
      {
        'id': 'L005',
        'firebaseId': 'Firebase_ID_5b1m3p7',
        'material': 'LDPE',
        'peso': 22.5,
        'presentacion': 'Pacas',
        'origen': 'Centro de Acopio Este',
      },
    ];
    
    // Agrupar por origen
    for (var lote in lotesMock) {
      String origen = lote['origen'];
      if (!lotesAgrupados.containsKey(origen)) {
        lotesAgrupados[origen] = [];
      }
      lotesAgrupados[origen]!.add(lote);
      
      // Inicializar estado de selección
      lotesSeleccionados[lote['id']] = false;
    }
    
    // Inicializar estado de grupos
    for (var origen in lotesAgrupados.keys) {
      gruposSeleccionados[origen] = false;
    }
    
    setState(() {});
  }
  
  void _onItemTapped(int index) {
    HapticFeedback.lightImpact();
    
    if (index == _selectedIndex) return;
    
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const TransporteInicioScreen(),
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
      case 1:
        // Ya estamos en entregar
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const TransporteAyudaScreen(),
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
                const TransportePerfilScreen(),
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
  
  void _toggleLote(String loteId) {
    setState(() {
      lotesSeleccionados[loteId] = !lotesSeleccionados[loteId]!;
      
      // Verificar si todos los lotes del grupo están seleccionados
      _actualizarEstadoGrupos();
    });
  }
  
  void _toggleGrupo(String origen) {
    setState(() {
      bool nuevoEstado = !gruposSeleccionados[origen]!;
      gruposSeleccionados[origen] = nuevoEstado;
      
      // Actualizar todos los lotes del grupo
      for (var lote in lotesAgrupados[origen]!) {
        lotesSeleccionados[lote['id']] = nuevoEstado;
      }
    });
  }
  
  void _actualizarEstadoGrupos() {
    for (var origen in lotesAgrupados.keys) {
      bool todosSeleccionados = lotesAgrupados[origen]!
          .every((lote) => lotesSeleccionados[lote['id']]!);
      gruposSeleccionados[origen] = todosSeleccionados;
    }
  }
  
  int get totalLotesSeleccionados {
    return lotesSeleccionados.values.where((selected) => selected).length;
  }
  
  double get pesoTotalSeleccionado {
    double total = 0.0;
    lotesSeleccionados.forEach((loteId, seleccionado) {
      if (seleccionado) {
        // Buscar el lote en los grupos
        for (var lotes in lotesAgrupados.values) {
          var lote = lotes.firstWhere(
            (l) => l['id'] == loteId,
            orElse: () => {'peso': 0.0},
          );
          total += lote['peso'] as double;
        }
      }
    });
    return total;
  }
  
  List<String> get origenesSeleccionados {
    Set<String> origenes = {};
    lotesSeleccionados.forEach((loteId, seleccionado) {
      if (seleccionado) {
        for (var entry in lotesAgrupados.entries) {
          if (entry.value.any((lote) => lote['id'] == loteId)) {
            origenes.add(entry.key);
            break;
          }
        }
      }
    });
    return origenes.toList();
  }
  
  void _generarQREntrega() {
    if (totalLotesSeleccionados == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos un lote'),
          backgroundColor: Color(0xFFE74C3C),
        ),
      );
      return;
    }
    
    // Recopilar IDs de lotes seleccionados
    List<String> lotesParaEntrega = [];
    lotesSeleccionados.forEach((loteId, seleccionado) {
      if (seleccionado) {
        lotesParaEntrega.add(loteId);
      }
    });
    
    // Navegar a la pantalla de generación de QR
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransporteQREntregaScreen(
          lotesEntrega: lotesParaEntrega,
          pesoTotal: pesoTotalSeleccionado,
          origenes: origenesSeleccionados,
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header con gradiente azul
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.02,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1490EE),
                    Color(0xFF70B7F9),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Entregar',
                    style: TextStyle(
                      fontSize: screenWidth * 0.06,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        nombreOperador,
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.03,
                          vertical: screenHeight * 0.005,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        ),
                        child: Text(
                          folioOperador,
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Panel de resumen
            Container(
              margin: EdgeInsets.all(screenWidth * 0.04),
              padding: EdgeInsets.all(screenWidth * 0.04),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Materiales en Tránsito',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Total Lotes',
                              style: TextStyle(
                                fontSize: screenWidth * 0.035,
                                color: const Color(0xFF606060),
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.005),
                            Text(
                              lotesSeleccionados.length.toString(),
                              style: TextStyle(
                                fontSize: screenWidth * 0.07,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: screenHeight * 0.06,
                        width: 1,
                        color: Colors.grey[300],
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Kg Total',
                              style: TextStyle(
                                fontSize: screenWidth * 0.035,
                                color: const Color(0xFF606060),
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.005),
                            Text(
                              lotesAgrupados.values
                                  .expand((lotes) => lotes)
                                  .fold(0.0, (sum, lote) => sum + (lote['peso'] as double))
                                  .toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: screenWidth * 0.07,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Lista de lotes agrupados
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                itemCount: lotesAgrupados.length,
                itemBuilder: (context, index) {
                  String origen = lotesAgrupados.keys.elementAt(index);
                  List<Map<String, dynamic>> lotes = lotesAgrupados[origen]!;
                  
                  return Container(
                    margin: EdgeInsets.only(bottom: screenHeight * 0.02),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Header del grupo
                        Container(
                          padding: EdgeInsets.all(screenWidth * 0.04),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  origen,
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.04,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              TextButton(
                                key: Key('btn_select_group_$index'),
                                onPressed: () => _toggleGrupo(origen),
                                child: Text(
                                  gruposSeleccionados[origen]! 
                                      ? 'Deseleccionar Todos' 
                                      : 'Seleccionar Todos',
                                  style: TextStyle(
                                    color: const Color(0xFF1490EE),
                                    fontSize: screenWidth * 0.035,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Lista de lotes del grupo
                        ...lotes.map((lote) {
                          return Container(
                            padding: EdgeInsets.all(screenWidth * 0.04),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey[200]!,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Checkbox
                                Checkbox(
                                  value: lotesSeleccionados[lote['id']]!,
                                  onChanged: (_) => _toggleLote(lote['id']),
                                  activeColor: const Color(0xFF1490EE),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                
                                SizedBox(width: screenWidth * 0.03),
                                
                                // Información del lote
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Chip con Firebase ID
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: screenWidth * 0.03,
                                          vertical: screenHeight * 0.005,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF9C4),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                            color: const Color(0xFFF9A825),
                                          ),
                                        ),
                                        child: Text(
                                          lote['firebaseId'],
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.03,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF6F4E37),
                                          ),
                                        ),
                                      ),
                                      
                                      SizedBox(height: screenHeight * 0.01),
                                      
                                      // Detalles del lote
                                      Row(
                                        children: [
                                          Text(
                                            lote['material'],
                                            style: TextStyle(
                                              fontSize: screenWidth * 0.035,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF1490EE),
                                            ),
                                          ),
                                          SizedBox(width: screenWidth * 0.04),
                                          Icon(
                                            Icons.scale,
                                            size: screenWidth * 0.04,
                                            color: const Color(0xFF606060),
                                          ),
                                          SizedBox(width: screenWidth * 0.01),
                                          Text(
                                            '${lote['peso']} kg',
                                            style: TextStyle(
                                              fontSize: screenWidth * 0.035,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          SizedBox(width: screenWidth * 0.04),
                                          Text(
                                            lote['presentacion'],
                                            style: TextStyle(
                                              fontSize: screenWidth * 0.035,
                                              color: const Color(0xFF606060),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Banda fija inferior
            if (totalLotesSeleccionados > 0)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      '$totalLotesSeleccionados ${totalLotesSeleccionados == 1 ? 'lote seleccionado' : 'lotes seleccionados'}',
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0D47A1),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        key: const Key('btn_generate_qr'),
                        onPressed: _generarQREntrega,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1490EE),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Generar QR de Entrega',
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
          ],
        ),
      ),
      bottomNavigationBar: TransporteBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}