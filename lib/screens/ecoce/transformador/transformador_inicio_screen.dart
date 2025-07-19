import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import '../shared/widgets/statistic_card.dart';
import 'transformador_lote_detalle_screen.dart';

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
  
  // Lista de lotes en proceso (datos de ejemplo mejorados)
  final List<Map<String, dynamic>> _lotesEnProceso = [
    {
      'id': 'Firebase_ID_1x7h9k3',
      'origen': 'RECICLADOR PLASTICOS DEL NORTE',
      'material': 'PET',
      'fecha': '14/07/2025',
      'fechaISO': '2025-07-14T10:30:00',
      'peso': 120.0,
      'estado': 'RECIBIDO',
      'estadoColor': Colors.blue,
      'producto': 'Envases PET',
      'tiposAnalisis': ['Inyección', 'Extrusión'],
      'composicion': 'PET reciclado 70%, PET virgen 30%, estabilizadores UV 0.5%',
      'comentarios': 'Material de alta calidad, cumple con normas ISO 9001',
      'procesosAplicados': ['Lavado', 'Secado', 'Extrusión'],
    },
    {
      'id': 'Firebase_ID_2a9m5p1',
      'origen': 'CENTRO DE ACOPIO SUSTENTABLE',
      'material': 'LDPE',
      'fecha': '14/07/2025',
      'fechaISO': '2025-07-14T08:15:00',
      'peso': 85.5,
      'estado': 'RECIBIDO',
      'estadoColor': Colors.blue,
      'producto': 'Láminas LDPE',
      'tiposAnalisis': ['Soplado', 'Laminado', 'Termoformado'],
      'composicion': 'LDPE reciclado 80%, aditivos antioxidantes 2%, pigmentos 1%',
      'comentarios': 'Procesamiento especial requerido para cliente premium',
      'procesosAplicados': ['Trituración', 'Lavado', 'Laminado'],
    },
  ];

  void _navigateToRecibirLotes() {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, '/transformador_recibir_lote');
  }

  void _navigateToDocumentacion() {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, '/transformador_documentacion');
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
        Navigator.pushReplacementNamed(context, '/transformador_produccion');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/transformador_ayuda');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/transformador_perfil');
        break;
    }
  }

  void _onAddPressed() {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, '/transformador_recibir_lote');
  }

  void _navigateToLoteDetalle(Map<String, dynamic> lote) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransformadorLoteDetalleScreen(
          firebaseId: lote['id'],
          peso: lote['peso'].toDouble(),
          tiposAnalisis: lote['tiposAnalisis'] ?? ['Extrusión', 'Inyección'],
          productoFabricado: lote['producto'] ?? 'Producto no especificado',
          composicionMaterial: lote['composicion'] ?? 'Material reciclado procesado según estándares de calidad',
          fechaCreacion: DateTime.parse(lote['fechaISO'] ?? DateTime.now().toIso8601String()),
          procesosAplicados: lote['procesosAplicados'] ?? [],
          comentarios: lote['comentarios'],
        ),
      ),
    );
  }

  Widget _buildLoteCard(Map<String, dynamic> lote) {
    final productoColor = _getProductoColor(lote['producto'] ?? '');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToLoteDetalle(lote),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Icono del producto
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              productoColor.withValues(alpha: 0.2),
                              productoColor.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getProductoIcon(lote['producto'] ?? ''),
                          color: productoColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Información del lote
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Primera línea: Producto y ID
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    'Lote ${lote['id'] ?? ''}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Segunda línea: Tipo de material
                            Row(
                              children: [
                                Icon(
                                  Icons.category_outlined,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Material: ${lote['material'] ?? 'No especificado'}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Tercera línea: Peso, Producto y Composición
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    _buildCompactChip(
                                      Icons.scale_outlined,
                                      '${lote['peso']} kg',
                                      Colors.blue,
                                    ),
                                    const SizedBox(width: 8),
                                    _buildCompactChip(
                                      Icons.calendar_today_outlined,
                                      lote['fecha'] ?? '',
                                      Colors.orange,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // Producto fabricado
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: productoColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.inventory_2_outlined,
                                        size: 12,
                                        color: productoColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          lote['producto'] ?? '',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: productoColor,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Composición
                                Text(
                                  lote['composicion'] ?? '',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Flecha de navegación
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: () => _navigateToLoteDetalle(lote),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.grey.shade400,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Botón de acción inferior
                InkWell(
                  onTap: () => _actualizarDocumentacion(lote['id']),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: BioWayColors.ecoceGreen.withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.update,
                          color: BioWayColors.ecoceGreen,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Actualizar Documentación',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: BioWayColors.ecoceGreen,
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
    );
  }

  Widget _buildCompactChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
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
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Color _getProductoColor(String producto) {
    // Asignar colores basados en el tipo de producto
    if (producto.toLowerCase().contains('pet') || producto.toLowerCase().contains('envase')) {
      return Colors.indigo;
    } else if (producto.toLowerCase().contains('ldpe') || producto.toLowerCase().contains('lámina')) {
      return Colors.teal;
    } else if (producto.toLowerCase().contains('hdpe') || producto.toLowerCase().contains('botella')) {
      return Colors.blue;
    } else if (producto.toLowerCase().contains('pp') || producto.toLowerCase().contains('polipropileno')) {
      return Colors.purple;
    } else if (producto.toLowerCase().contains('ps') || producto.toLowerCase().contains('poliestireno')) {
      return Colors.orange;
    } else {
      return BioWayColors.ecoceGreen;
    }
  }

  IconData _getProductoIcon(String producto) {
    // Asignar iconos basados en el tipo de producto
    if (producto.toLowerCase().contains('envase') || producto.toLowerCase().contains('botella')) {
      return Icons.local_drink;
    } else if (producto.toLowerCase().contains('lámina') || producto.toLowerCase().contains('hoja')) {
      return Icons.layers;
    } else if (producto.toLowerCase().contains('tubo') || producto.toLowerCase().contains('tubería')) {
      return Icons.view_column;
    } else if (producto.toLowerCase().contains('contenedor') || producto.toLowerCase().contains('caja')) {
      return Icons.inventory_2;
    } else if (producto.toLowerCase().contains('película') || producto.toLowerCase().contains('film')) {
      return Icons.wrap_text;
    } else {
      return Icons.recycling;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        // Detectar swipe hacia la izquierda (ir a producción)
        if (details.primaryVelocity! < -100) {
          Navigator.pushReplacementNamed(context, '/transformador_produccion');
        }
        // No hay pantalla a la derecha desde inicio
      },
      child: Scaffold(
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
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
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
                              borderRadius: BorderRadius.circular(16),
                            ),
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
      ),
    );
  }
}