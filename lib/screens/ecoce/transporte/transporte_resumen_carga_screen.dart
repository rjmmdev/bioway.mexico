import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import '../shared/utils/navigation_utils.dart';
import '../../../utils/colors.dart';
import 'transporte_inicio_screen.dart';
import 'transporte_recoger_screen.dart';
import 'transporte_entregar_screen.dart';
import 'transporte_ayuda_screen.dart';
import 'transporte_perfil_screen.dart';

class TransporteResumenCargaScreen extends StatefulWidget {
  final Map<String, dynamic> loteInicial;
  
  const TransporteResumenCargaScreen({
    super.key,
    required this.loteInicial,
  });

  @override
  State<TransporteResumenCargaScreen> createState() => _TransporteResumenCargaScreenState();
}

class _TransporteResumenCargaScreenState extends State<TransporteResumenCargaScreen> {
  final int _selectedIndex = 0;
  List<Map<String, dynamic>> lotesTemp = [];
  bool _showSuccessBanner = true;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    // Agregar el lote inicial
    lotesTemp.add(widget.loteInicial);
    
    // Configurar el timer para ocultar el banner
    _bannerTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSuccessBanner = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    super.dispose();
  }

  double get pesoTotal => lotesTemp.fold(0.0, (sum, lote) => sum + (lote['peso'] as double));

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        // Ya estamos en inicio/recoger
        break;
      case 1:
        NavigationUtils.navigateWithFade(
          context,
          const TransporteEntregarScreen(),
          replacement: true,
        );
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

  void _removerLote(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      lotesTemp.removeAt(index);
    });
    
    if (lotesTemp.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const TransporteInicioScreen(),
        ),
      );
    }
  }

  void _escanearOtroLote() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const TransporteInicioScreen(),
      ),
    );
  }

  void _continuarAlFormulario() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransporteRecogerScreen(
          lotesSeleccionados: lotesTemp,
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
            // Header con gradiente verde
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.02,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF3AA45B),
                    Color(0xFF68C76A),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumen de Carga',
                    style: TextStyle(
                      fontSize: screenWidth * 0.06,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.005),
                  Text(
                    'Lotes listos para transportar',
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            // Contenido principal
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: Column(
                    children: [
                      // Banner de confirmación
                      AnimatedOpacity(
                        opacity: _showSuccessBanner ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 500),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          height: _showSuccessBanner ? null : 0,
                          margin: EdgeInsets.only(bottom: screenHeight * 0.02),
                          padding: EdgeInsets.all(screenWidth * 0.04),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF4CAF50).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFF4CAF50),
                                size: 24,
                              ),
                              SizedBox(width: screenWidth * 0.03),
                              const Expanded(
                                child: Text(
                                  'Lote escaneado correctamente',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Tarjeta de resumen
                      Container(
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
                        child: Row(
                          children: [
                            // Columna de Lotes
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    'Lotes',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.035,
                                      color: const Color(0xFF606060),
                                    ),
                                  ),
                                  SizedBox(height: screenHeight * 0.01),
                                  Text(
                                    lotesTemp.length.toString(),
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.08,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Divisor
                            Container(
                              height: screenHeight * 0.06,
                              width: 1,
                              color: Colors.grey[300],
                            ),
                            
                            // Columna de Kg Total
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
                                  SizedBox(height: screenHeight * 0.01),
                                  Text(
                                    pesoTotal.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.08,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.03),

                      // Sección de Lotes Escaneados
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Lotes Escaneados',
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.02),

                      // Lista de lotes
                      ...lotesTemp.asMap().entries.map((entry) {
                        final index = entry.key;
                        final lote = entry.value;
                        
                        return Container(
                          margin: EdgeInsets.only(bottom: screenHeight * 0.015),
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
                            children: [
                              // Header del lote con chip y botón X
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    key: Key('chip_lote_$index'),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.03,
                                      vertical: screenHeight * 0.005,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF9C4),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: const Color(0xFFF9A825),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      lote['firebaseId'] ?? lote['id'],
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.03,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF6F4E37),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    key: Key('btn_remove_lote_$index'),
                                    onPressed: () => _removerLote(index),
                                    icon: const Icon(
                                      Icons.close,
                                      color: Color(0xFFE74C3C),
                                      size: 20,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),

                              SizedBox(height: screenHeight * 0.015),

                              // Información del lote
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildLoteInfo('Material', lote['material']),
                                  _buildLoteInfo('Peso', '${lote['peso']} kg'),
                                  _buildLoteInfo('Presentación', lote['presentacion']),
                                ],
                              ),

                              SizedBox(height: screenHeight * 0.015),

                              // Sub-panel de origen
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(screenWidth * 0.03),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Origen',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.03,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF606060),
                                      ),
                                    ),
                                    SizedBox(height: screenHeight * 0.005),
                                    Text(
                                      lote['origen'],
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.035,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),

                      SizedBox(height: screenHeight * 0.03),

                      // Botones de acción
                      Row(
                        children: [
                          // Botón "Escanear Otro Lote"
                          Expanded(
                            child: OutlinedButton.icon(
                              key: const Key('btn_scan_another'),
                              onPressed: _escanearOtroLote,
                              icon: const Icon(Icons.qr_code_scanner),
                              label: const Text('Escanear Otro Lote'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF3AA45B),
                                side: const BorderSide(
                                  color: Color(0xFF3AA45B),
                                  width: 2,
                                ),
                                padding: EdgeInsets.symmetric(
                                  vertical: screenHeight * 0.02,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: screenHeight * 0.015),

                      // Botón "Continuar al Formulario"
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          key: const Key('btn_continue_form'),
                          onPressed: _continuarAlFormulario,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3AA45B),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'Continuar al Formulario',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.1), // Espacio para el bottom nav
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

  Widget _buildLoteInfo(String label, String value) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: screenWidth * 0.03,
            color: const Color(0xFF606060),
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: screenWidth * 0.035,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}