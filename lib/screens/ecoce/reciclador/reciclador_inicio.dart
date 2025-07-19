import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import 'reciclador_escaneo.dart';
import 'reciclador_administracion_lotes.dart';
import 'reciclador_formulario_salida.dart';
import 'reciclador_documentacion.dart';
import 'reciclador_lote_qr_screen.dart';
import 'reciclador_ayuda.dart';
import 'reciclador_perfil.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import '../shared/utils/navigation_utils.dart';
import 'widgets/reciclador_lote_card.dart';
import '../shared/widgets/statistic_card.dart';
import '../shared/widgets/gradient_header.dart';
import '../shared/widgets/quick_action_button.dart';
import '../shared/utils/material_utils.dart';

class RecicladorHomeScreen extends StatefulWidget {
  const RecicladorHomeScreen({super.key});

  @override
  State<RecicladorHomeScreen> createState() => _RecicladorHomeScreenState();
}

class _RecicladorHomeScreenState extends State<RecicladorHomeScreen> {
  // Índice para la navegación del bottom bar
  final int _selectedIndex = 0;

  // Datos de ejemplo para el reciclador (en producción vendrían de la base de datos)
  final String _nombreReciclador = "Juan Pérez García";
  final String _folioReciclador = "R0001234";
  final int _lotesRecibidos = 45;
  final int _lotesCreados = 38;
  final double _pesoProcesado = 1250.5; // en kg

  // Lista de lotes con diferentes estados (datos de ejemplo)
  final List<Map<String, dynamic>> _lotesRecientes = [
    {
      'id': 'L001',
      'fecha': '14/07/2025',
      'peso': 125.5,
      'material': 'PEBD',
      'origen': 'Acopiador Norte',
      'presentacion': 'Pacas',
      'estado': 'salida', // Requiere formulario de salida
    },
    {
      'id': 'L002',
      'fecha': '14/07/2025',
      'peso': 89.3,
      'material': 'PP',
      'origen': 'Planta Separación Sur',
      'presentacion': 'Sacos',
      'estado': 'documentacion', // Requiere documentación
    },
    {
      'id': 'L003',
      'fecha': '13/07/2025',
      'peso': 200.8,
      'material': 'Multilaminado',
      'origen': 'Acopiador Centro',
      'presentacion': 'Pacas',
      'estado': 'finalizado', // Completado
    },
    {
      'id': 'L004',
      'fecha': '13/07/2025',
      'peso': 156.2,
      'material': 'PEBD',
      'origen': 'Planta Separación Este',
      'presentacion': 'Sacos',
      'estado': 'salida', // Requiere formulario de salida
    },
  ];

  void _navigateToNewLot() {
    HapticFeedback.lightImpact();
    NavigationUtils.navigateWithSlide(
      context,
      const QRScannerScreen(),
    );
  }

  void _navigateToLotControl() {
    HapticFeedback.lightImpact();
    NavigationUtils.navigateWithSlide(
      context,
      const RecicladorAdministracionLotes(),
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
        NavigationUtils.navigateWithFade(
          context,
          const RecicladorAdministracionLotes(),
        );
        break;
      case 2:
        NavigationUtils.navigateWithFade(
          context,
          const RecicladorAyudaScreen(),
        );
        break;
      case 3:
        NavigationUtils.navigateWithFade(
          context,
          const RecicladorPerfilScreen(),
        );
        break;
    }
  }

  // Obtener texto del botón según el estado
  String _getActionButtonText(String estado) {
    switch (estado) {
      case 'salida':
        return 'Formulario de Salida';
      case 'documentacion':
        return 'Ingresar Documentación';
      case 'finalizado':
        return 'Ver Código QR';
      default:
        return '';
    }
  }

  // Obtener color del botón según el estado
  Color _getActionButtonColor(String estado) {
    switch (estado) {
      case 'salida':
        return BioWayColors.error; // Rojo
      case 'documentacion':
        return BioWayColors.warning; // Naranja
      case 'finalizado':
        return BioWayColors.success; // Verde
      default:
        return BioWayColors.ecoceGreen;
    }
  }

  // Manejar tap en lote según su estado
  void _handleLoteTap(Map<String, dynamic> lote) {
    HapticFeedback.lightImpact();
    
    switch (lote['estado']) {
      case 'salida':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecicladorFormularioSalida(
              loteId: lote['id'],
              pesoOriginal: lote['peso'].toDouble(),
            ),
          ),
        );
        break;
      case 'documentacion':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecicladorDocumentacion(
              lotId: lote['id'],
            ),
          ),
        );
        break;
      case 'finalizado':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecicladorLoteQRScreen(
              loteId: lote['id'],
              material: lote['material'],
              pesoOriginal: lote['peso'].toDouble(),
              pesoFinal: lote['peso'].toDouble(), // En producción vendría de la base de datos
              presentacion: lote['presentacion'],
              origen: lote['origen'],
              fechaEntrada: DateTime.now().subtract(const Duration(days: 5)), // En producción vendría de la BD
              fechaSalida: DateTime.now(),
              documentosCargados: ['Ficha Técnica', 'Reporte de Reciclaje'], // En producción vendría de la BD
            ),
          ),
        );
        break;
    }
  }

  Widget _buildQRButton(Map<String, dynamic> lote) {
    return Container(
      decoration: BoxDecoration(
        color: BioWayColors.ecoceGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          _handleLoteTap(lote);
        },
        icon: Icon(
          Icons.qr_code_2,
          color: BioWayColors.ecoceGreen,
          size: 22,
        ),
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 36,
        ),
        tooltip: 'Ver QR',
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
            // Header moderno con gradiente
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
                          // Nombre del reciclador
                          Text(
                            _nombreReciclador,
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
                                      Icons.recycling,
                                      size: 16,
                                      color: BioWayColors.ecoceGreen,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Reciclador',
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
                                  _folioReciclador,
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
                              // Card de Lotes Creados
                              Expanded(
                                child: StatisticCard(
                                  title: 'Lotes creados',
                                  value: _lotesCreados.toString(),
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
                              // Card de Peso Procesado centrada
                              Container(
                                width: MediaQuery.of(context).size.width * 0.45,
                                child: StatisticCard(
                                  title: 'Material procesado',
                                  value: '${(_pesoProcesado / 1000).toStringAsFixed(1)}',
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
                      // Acción rápida única centrada más compacta
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
                            onTap: _navigateToNewLot,
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
                                          'Escanear Nuevo Lote',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          'Registra entrada de material',
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
                      
                      const SizedBox(height: 20),
                      
                      // Sección de lotes recientes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Lotes Recientes',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          TextButton(
                            onPressed: _navigateToLotControl,
                            child: Row(
                              children: [
                                Text(
                                  'Ver todos',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: BioWayColors.ecoceGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward,
                                  size: 16,
                                  color: BioWayColors.ecoceGreen,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Lista de lotes con nuevo diseño y botones según estado
                      ..._lotesRecientes.map((lote) {
                        // Para lotes finalizados, usar el estilo con botón QR lateral
                        if (lote['estado'] == 'finalizado') {
                          return RecicladorLoteCard(
                            lote: lote,
                            onTap: () => _handleLoteTap(lote),
                            showActionButton: false,
                            showActions: false,
                            trailing: _buildQRButton(lote),
                          );
                        }
                        
                        // Para otros estados, mostrar botón debajo
                        return RecicladorLoteCard(
                          lote: lote,
                          onTap: () => _handleLoteTap(lote),
                          showActionButton: true,
                          actionButtonText: _getActionButtonText(lote['estado']),
                          actionButtonColor: _getActionButtonColor(lote['estado']),
                          onActionPressed: () => _handleLoteTap(lote),
                          showActions: true, // Mostrar flecha lateral
                        );
                      }),
                      
                      const SizedBox(height: 100), // Espacio para el FAB
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      
      // Bottom Navigation Bar con FAB
      bottomNavigationBar: EcoceBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onBottomNavTapped,
        primaryColor: BioWayColors.ecoceGreen,
        items: EcoceNavigationConfigs.recicladorItems,
        fabConfig: FabConfig(
          icon: Icons.add,
          onPressed: _navigateToNewLot,
        ),
      ),
      
      // Floating Action Button
      floatingActionButton: EcoceFloatingActionButton(
        onPressed: _navigateToNewLot,
        icon: Icons.add,
        backgroundColor: BioWayColors.ecoceGreen,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}