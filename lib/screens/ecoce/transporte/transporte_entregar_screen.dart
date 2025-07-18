import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import '../shared/utils/navigation_utils.dart';
import '../shared/utils/material_utils.dart';
import '../../../utils/colors.dart';
import 'transporte_escaneo.dart';
import 'transporte_ayuda_screen.dart';
import 'transporte_perfil_screen.dart';
import 'transporte_qr_entrega_screen.dart';

class TransporteEntregarScreen extends StatefulWidget {
  const TransporteEntregarScreen({super.key});

  @override
  State<TransporteEntregarScreen> createState() => _TransporteEntregarScreenState();
}

class _TransporteEntregarScreenState extends State<TransporteEntregarScreen> with TickerProviderStateMixin {
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
  
  // Animaciones
  late AnimationController _headerController;
  late AnimationController _listController;
  late Animation<double> _headerAnimation;
  late Animation<double> _listAnimation;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _cargarLotesEnTransito();
  }
  
  void _setupAnimations() {
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _listController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _headerAnimation = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutBack,
    );
    
    _listAnimation = CurvedAnimation(
      parent: _listController,
      curve: Curves.easeOutCubic,
    );
    
    _headerController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _listController.forward();
    });
  }
  
  @override
  void dispose() {
    _headerController.dispose();
    _listController.dispose();
    super.dispose();
  }
  
  void _cargarLotesEnTransito() {
    // TODO: Implementar GET /lotes?status=in-transit&transportista=folio
    // Por ahora usamos datos mock con los materiales correctos
    List<Map<String, dynamic>> lotesMock = [
      {
        'id': 'L001',
        'firebaseId': 'Firebase_ID_1x7h9k3',
        'material': 'PET',
        'peso': 45.5,
        'presentacion': 'Pacas',
        'origen': 'Centro de Acopio Norte',
        'fecha': MaterialUtils.formatDate(DateTime.now().subtract(const Duration(days: 2))),
      },
      {
        'id': 'L002',
        'firebaseId': 'Firebase_ID_2y8j0m4',
        'material': 'HDPE',
        'peso': 32.0,
        'presentacion': 'Sacos',
        'origen': 'Centro de Acopio Norte',
        'fecha': MaterialUtils.formatDate(DateTime.now().subtract(const Duration(days: 1))),
      },
      {
        'id': 'L003',
        'firebaseId': 'Firebase_ID_3z9k1n5',
        'material': 'PP',
        'peso': 28.7,
        'presentacion': 'Pacas',
        'origen': 'Centro de Acopio Sur',
        'fecha': MaterialUtils.formatDate(DateTime.now().subtract(const Duration(days: 3))),
      },
      {
        'id': 'L004',
        'firebaseId': 'Firebase_ID_4a0l2o6',
        'material': 'PEBD',
        'peso': 51.2,
        'presentacion': 'Sacos',
        'origen': 'Centro de Acopio Sur',
        'fecha': MaterialUtils.formatDate(DateTime.now()),
      },
      {
        'id': 'L005',
        'firebaseId': 'Firebase_ID_5b1m3p7',
        'material': 'Multilaminado',
        'peso': 22.5,
        'presentacion': 'Pacas',
        'origen': 'Centro de Acopio Este',
        'fecha': MaterialUtils.formatDate(DateTime.now().subtract(const Duration(days: 1))),
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
    if (index == _selectedIndex) return;
    
    switch (index) {
      case 0:
        NavigationUtils.navigateWithFade(
          context,
          const TransporteEscaneoScreen(),
          replacement: true,
        );
        break;
      case 1:
        // Ya estamos en entregar
        break;
      case 2:
        NavigationUtils.navigateWithFade(
          context,
          const TransporteAyudaScreen(),
          replacement: true,
        );
        break;
      case 3:
        NavigationUtils.navigateWithFade(
          context,
          const TransportePerfilScreen(),
          replacement: true,
        );
        break;
    }
  }
  
  void _toggleLote(String loteId) {
    HapticFeedback.lightImpact();
    setState(() {
      lotesSeleccionados[loteId] = !lotesSeleccionados[loteId]!;
      
      // Verificar si todos los lotes del grupo están seleccionados
      _actualizarEstadoGrupos();
    });
  }
  
  void _toggleGrupo(String origen) {
    HapticFeedback.lightImpact();
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
        SnackBar(
          content: const Text('Selecciona al menos un lote'),
          backgroundColor: BioWayColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    
    HapticFeedback.mediumImpact();
    
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

  Color _getMaterialColor(String material) {
    switch (material) {
      case 'PET':
        return BioWayColors.deepBlue;
      case 'HDPE':
        return BioWayColors.success;
      case 'LDPE':
        return BioWayColors.limeGreen;
      case 'PP':
        return BioWayColors.ppPurple; // Morado correcto
      case 'PS':
        return BioWayColors.warning;
      case 'PVC':
        return BioWayColors.error;
      case 'PEBD':
        return BioWayColors.pebdPink; // Rosa correcto
      case 'Multilaminado':
        return BioWayColors.multilaminadoBrown; // Café/Gris correcto
      default:
        return BioWayColors.darkGrey;
    }
  }

  IconData _getMaterialIcon(String material) {
    switch (material) {
      case 'PET':
        return Icons.local_drink;
      case 'HDPE':
        return Icons.cleaning_services;
      case 'LDPE':
        return Icons.shopping_bag;
      case 'PP':
        return Icons.kitchen;
      case 'PS':
        return Icons.coffee;
      case 'PVC':
        return Icons.plumbing;
      case 'PEBD':
        return Icons.shopping_bag;
      case 'Multilaminado':
        return Icons.layers;
      default:
        return Icons.recycling;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: BioWayColors.backgroundGrey,
      body: SafeArea(
        child: Column(
          children: [
            // Header moderno con animación
            ScaleTransition(
              scale: _headerAnimation,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      BioWayColors.deepBlue,
                      BioWayColors.deepBlue.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: BioWayColors.deepBlue.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Entregar Lotes',
                              style: TextStyle(
                                fontSize: screenWidth * 0.06,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.005),
                            Text(
                              'Selecciona los lotes a entregar',
                              style: TextStyle(
                                fontSize: screenWidth * 0.035,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.03,
                            vertical: screenHeight * 0.008,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person,
                                color: Colors.white,
                                size: screenWidth * 0.04,
                              ),
                              SizedBox(width: screenWidth * 0.02),
                              Text(
                                folioOperador,
                                style: TextStyle(
                                  fontSize: screenWidth * 0.035,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    
                    // Estadísticas rápidas
                    Row(
                      children: [
                        _buildStatChip(
                          icon: Icons.inventory_2,
                          value: lotesSeleccionados.length.toString(),
                          label: 'Total',
                          color: Colors.white,
                          screenWidth: screenWidth,
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        _buildStatChip(
                          icon: Icons.check_circle,
                          value: totalLotesSeleccionados.toString(),
                          label: 'Seleccionados',
                          color: BioWayColors.limeGreen,
                          screenWidth: screenWidth,
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        _buildStatChip(
                          icon: Icons.scale,
                          value: '${pesoTotalSeleccionado.toStringAsFixed(1)} kg',
                          label: 'Peso',
                          color: BioWayColors.warning,
                          screenWidth: screenWidth,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Lista de lotes agrupados con diseño mejorado
            Expanded(
              child: FadeTransition(
                opacity: _listAnimation,
                child: ListView.builder(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  itemCount: lotesAgrupados.length,
                  itemBuilder: (context, index) {
                    String origen = lotesAgrupados.keys.elementAt(index);
                    List<Map<String, dynamic>> lotes = lotesAgrupados[origen]!;
                    
                    return AnimatedContainer(
                      duration: Duration(milliseconds: 300 + (index * 100)),
                      margin: EdgeInsets.only(bottom: screenHeight * 0.02),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Column(
                          children: [
                            // Header del grupo con gradiente
                            Container(
                              padding: EdgeInsets.all(screenWidth * 0.04),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    BioWayColors.deepBlue.withOpacity(0.1),
                                    BioWayColors.deepBlue.withOpacity(0.05),
                                  ],
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(screenWidth * 0.025),
                                    decoration: BoxDecoration(
                                      color: BioWayColors.deepBlue.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.location_on,
                                      color: BioWayColors.deepBlue,
                                      size: screenWidth * 0.05,
                                    ),
                                  ),
                                  SizedBox(width: screenWidth * 0.03),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          origen,
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.045,
                                            fontWeight: FontWeight.bold,
                                            color: BioWayColors.darkGreen,
                                          ),
                                        ),
                                        Text(
                                          '${lotes.length} lotes',
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.035,
                                            color: BioWayColors.textGrey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _toggleGrupo(origen),
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: screenWidth * 0.04,
                                          vertical: screenHeight * 0.01,
                                        ),
                                        decoration: BoxDecoration(
                                          color: gruposSeleccionados[origen]! 
                                              ? BioWayColors.deepBlue
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: BioWayColors.deepBlue,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Text(
                                          gruposSeleccionados[origen]! 
                                              ? 'Deseleccionar' 
                                              : 'Seleccionar todo',
                                          style: TextStyle(
                                            color: gruposSeleccionados[origen]!
                                                ? Colors.white
                                                : BioWayColors.deepBlue,
                                            fontSize: screenWidth * 0.035,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Lista de lotes del grupo
                            ...lotes.asMap().entries.map((entry) {
                              final index = entry.key;
                              final lote = entry.value;
                              final isLast = index == lotes.length - 1;
                              final materialColor = _getMaterialColor(lote['material']);
                              
                              return Container(
                                decoration: BoxDecoration(
                                  border: isLast ? null : Border(
                                    bottom: BorderSide(
                                      color: Colors.grey.shade200,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _toggleLote(lote['id']),
                                    child: Padding(
                                      padding: EdgeInsets.all(screenWidth * 0.04),
                                      child: Row(
                                        children: [
                                          // Checkbox animado
                                          AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            width: screenWidth * 0.06,
                                            height: screenWidth * 0.06,
                                            decoration: BoxDecoration(
                                              color: lotesSeleccionados[lote['id']]!
                                                  ? BioWayColors.deepBlue
                                                  : Colors.transparent,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: lotesSeleccionados[lote['id']]!
                                                    ? BioWayColors.deepBlue
                                                    : Colors.grey.shade400,
                                                width: 2,
                                              ),
                                            ),
                                            child: lotesSeleccionados[lote['id']]!
                                                ? const Icon(
                                                    Icons.check,
                                                    color: Colors.white,
                                                    size: 16,
                                                  )
                                                : null,
                                          ),
                                          
                                          SizedBox(width: screenWidth * 0.04),
                                          
                                          // Ícono del material
                                          Container(
                                            width: screenWidth * 0.12,
                                            height: screenWidth * 0.12,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  materialColor.withOpacity(0.2),
                                                  materialColor.withOpacity(0.1),
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              _getMaterialIcon(lote['material']),
                                              color: materialColor,
                                              size: screenWidth * 0.06,
                                            ),
                                          ),
                                          
                                          SizedBox(width: screenWidth * 0.04),
                                          
                                          // Información del lote
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Primera línea: Material y ID
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: EdgeInsets.symmetric(
                                                        horizontal: screenWidth * 0.025,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: materialColor,
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        lote['material'],
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(width: screenWidth * 0.02),
                                                    Flexible(
                                                      child: Text(
                                                        'ID: ${lote['id']}',
                                                        style: TextStyle(
                                                          fontSize: screenWidth * 0.03,
                                                          color: BioWayColors.textGrey,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                
                                                SizedBox(height: screenHeight * 0.01),
                                                
                                                // Firebase ID
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: screenWidth * 0.025,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: BioWayColors.warning.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(
                                                      color: BioWayColors.warning.withOpacity(0.3),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.qr_code,
                                                        size: screenWidth * 0.035,
                                                        color: BioWayColors.warning,
                                                      ),
                                                      SizedBox(width: screenWidth * 0.015),
                                                      Flexible(
                                                        child: Text(
                                                          lote['firebaseId'],
                                                          style: TextStyle(
                                                            fontSize: screenWidth * 0.03,
                                                            fontWeight: FontWeight.w600,
                                                            color: BioWayColors.darkGreen,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                
                                                SizedBox(height: screenHeight * 0.01),
                                                
                                                // Detalles del lote
                                                Wrap(
                                                  spacing: screenWidth * 0.03,
                                                  runSpacing: 4,
                                                  children: [
                                                    _buildDetailChip(
                                                      icon: Icons.scale,
                                                      text: '${lote['peso']} kg',
                                                      color: Colors.blue,
                                                      screenWidth: screenWidth,
                                                    ),
                                                    _buildDetailChip(
                                                      icon: lote['presentacion'] == 'Pacas' 
                                                          ? Icons.inventory 
                                                          : Icons.shopping_bag,
                                                      text: lote['presentacion'],
                                                      color: Colors.green,
                                                      screenWidth: screenWidth,
                                                    ),
                                                    _buildDetailChip(
                                                      icon: Icons.calendar_today,
                                                      text: lote['fecha'],
                                                      color: Colors.orange,
                                                      screenWidth: screenWidth,
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
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // Banda fija inferior mejorada
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: totalLotesSeleccionados > 0 ? null : 0,
              child: Container(
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Indicador de selección
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      
                      // Resumen de selección
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildSummaryItem(
                            icon: Icons.inventory_2,
                            value: totalLotesSeleccionados.toString(),
                            label: 'Lotes',
                            color: BioWayColors.deepBlue,
                            screenWidth: screenWidth,
                          ),
                          Container(
                            height: 40,
                            width: 1,
                            color: Colors.grey.shade300,
                          ),
                          _buildSummaryItem(
                            icon: Icons.scale,
                            value: '${pesoTotalSeleccionado.toStringAsFixed(1)} kg',
                            label: 'Peso Total',
                            color: BioWayColors.warning,
                            screenWidth: screenWidth,
                          ),
                          Container(
                            height: 40,
                            width: 1,
                            color: Colors.grey.shade300,
                          ),
                          _buildSummaryItem(
                            icon: Icons.location_on,
                            value: origenesSeleccionados.length.toString(),
                            label: 'Orígenes',
                            color: BioWayColors.success,
                            screenWidth: screenWidth,
                          ),
                        ],
                      ),
                      
                      SizedBox(height: screenHeight * 0.02),
                      
                      // Botón de generar QR mejorado
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          key: const Key('btn_generate_qr'),
                          onPressed: _generarQREntrega,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BioWayColors.deepBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            elevation: 3,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.qr_code, size: 24),
                              const SizedBox(width: 12),
                              Text(
                                'Generar QR de Entrega',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.045,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: EcoceBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        primaryColor: BioWayColors.deepBlue,
        items: EcoceNavigationConfigs.transporteItems,
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required double screenWidth,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.03,
        vertical: screenWidth * 0.02,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: screenWidth * 0.04,
          ),
          SizedBox(width: screenWidth * 0.02),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: screenWidth * 0.025,
                  color: color.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String text,
    required Color color,
    required double screenWidth,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required double screenWidth,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: screenWidth * 0.06,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.bold,
            color: BioWayColors.darkGreen,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: screenWidth * 0.03,
            color: BioWayColors.textGrey,
          ),
        ),
      ],
    );
  }
}