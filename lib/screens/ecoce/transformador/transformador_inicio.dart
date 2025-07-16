import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';

class TransformadorInicioScreen extends StatefulWidget {
  const TransformadorInicioScreen({super.key});

  @override
  State<TransformadorInicioScreen> createState() => _TransformadorInicioScreenState();
}

class _TransformadorInicioScreenState extends State<TransformadorInicioScreen>
    with TickerProviderStateMixin {
  
  // Controladores de animación
  late AnimationController _headerController;
  late AnimationController _cardsController;
  late AnimationController _fabController;
  
  // Animaciones
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _cardsFadeAnimation;
  late Animation<double> _fabScaleAnimation;

  // Datos simulados basados en la imagen
  final String _folio = 'T0000001';
  final int _lotesRecibidos = 47;
  final int _productosCreados = 28;
  final double _materialProcesado = 4.5; // toneladas
  final double _capacidadUtilizada = 85.0; // porcentaje
  final double _materialProcesadoHoy = 1.2; // toneladas

  // Lista de lotes en proceso
  final List<Map<String, dynamic>> _lotesEnProceso = [
    {
      'id': 'Firebase_ID_1x7h9k3',
      'material': 'PELLETS',
      'peso': 120,
      'estado': 'RECIBIDO',
      'origen': 'Recicladora El Futuro',
      'fechaRecibido': '11 Jul 2025',
    },
    {
      'id': 'Firebase_ID_2x8i0l4',
      'material': 'PET',
      'peso': 120,
      'estado': 'EN PROCESO',
      'origen': 'Recicladora El Futuro',
      'fechaIniciado': '11 Jul 2025 - 9:30',
      'procesos': ['Inyección', 'Soplado', 'Extrucción', 'Laminado', 'Termoformado', 'Pulstrucción', 'Plástico Corrugado', 'Rotomoldeo'],
    },
  ];

  // Lista de transformaciones finalizadas
  final List<Map<String, dynamic>> _transformacionesFinalizadas = [
    {
      'id': 'Firebase_ID_3x9j2n6',
      'material': 'PET',
      'peso': 180,
      'pesoProducido': 59,
      'fechaFinalizado': '12 Jul 2025',
      'procesos': ['Inyección', 'Soplado', 'Rotomoldeo', 'Extrucción', 'Laminado', 'Termoformado', 'Pulstrucción', 'Plástico Corrugado'],
      'producto': 'Botellas PET 500 ml',
      'materialReciclado': 33,
      'compuestoAl': 'Resina virgen PET',
    },
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    // Header animation
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _headerFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOut,
    ));

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutCubic,
    ));

    // Cards animation
    _cardsController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _cardsFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardsController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    // FAB animation
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fabScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabController,
      curve: Curves.easeOutBack,
    ));
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _headerController.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    _cardsController.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    _fabController.forward();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _cardsController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  void _navigateBack() {
    HapticFeedback.lightImpact();
    Navigator.pop(context);
  }

  void _escanearLote() {
    HapticFeedback.mediumImpact();
    // TODO: Implementar funcionalidad de escaneo
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Función de escaneo en desarrollo'),
        backgroundColor: BioWayColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _verDocumentacion() {
    HapticFeedback.lightImpact();
    // TODO: Implementar navegación a documentación
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Funcionalidad en desarrollo'),
        backgroundColor: BioWayColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _actualizarDocumentacion(String loteId) {
    HapticFeedback.lightImpact();
    // TODO: Implementar actualización de documentación
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Actualizar documentación para $loteId'),
        backgroundColor: BioWayColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            AnimatedBuilder(
              animation: _headerController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _headerFadeAnimation,
                  child: SlideTransition(
                    position: _headerSlideAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            BioWayColors.ppOrange,
                            BioWayColors.ppOrange.withOpacity(0.8),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Barra superior con notificación
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '9:41',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Stack(
                                  children: [
                                    const Icon(
                                      Icons.notifications_outlined,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: BioWayColors.error,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Información de la empresa
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.factory,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'La Venta S.A. de C.V.',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        const Text(
                                          'Transformador',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            _folio,
                                            style: TextStyle(
                                              color: BioWayColors.ppOrange,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Estadísticas principales
                          Row(
                            children: [
                              _buildStatCard(
                                title: 'Lotes\nRecibidos',
                                value: _lotesRecibidos.toString(),
                                color: Colors.white.withOpacity(0.9),
                              ),
                              const SizedBox(width: 12),
                              _buildStatCard(
                                title: 'Productos\nCreados',
                                value: _productosCreados.toString(),
                                color: Colors.white.withOpacity(0.9),
                              ),
                              const SizedBox(width: 12),
                              _buildStatCard(
                                title: 'Material\nProcesado',
                                value: '${_materialProcesado} tons',
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Contenido principal
            Expanded(
              child: AnimatedBuilder(
                animation: _cardsController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _cardsFadeAnimation,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Acciones Rápidas
                          _buildSectionTitle('Acciones Rápidas'),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionCard(
                                  icon: Icons.qr_code_scanner,
                                  title: 'Recibir Lotes',
                                  subtitle: 'Escanear lote entrante',
                                  onTap: _escanearLote,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildActionCard(
                                  icon: Icons.description,
                                  title: 'Documentación',
                                  subtitle: 'Fichas técnicas',
                                  onTap: _verDocumentacion,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Capacidad de Producción - Hoy
                          _buildCapacitySection(),

                          const SizedBox(height: 24),

                          // Lotes en Proceso
                          _buildSectionTitle('Lotes en Proceso'),
                          const SizedBox(height: 12),
                          ..._lotesEnProceso.map((lote) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildLoteCard(lote, isCompleted: false),
                          )),

                          const SizedBox(height: 24),

                          // Transformaciones Finalizadas
                          _buildSectionTitle('🏆 Transformaciones Finalizadas'),
                          const SizedBox(height: 12),
                          ..._transformacionesFinalizadas.map((transformacion) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildLoteCard(transformacion, isCompleted: true),
                          )),

                          const SizedBox(height: 80), // Espacio para el FAB
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // FAB animado
      floatingActionButton: AnimatedBuilder(
        animation: _fabController,
        builder: (context, child) {
          return Transform.scale(
            scale: _fabScaleAnimation.value,
            child: FloatingActionButton(
              onPressed: _escanearLote,
              backgroundColor: BioWayColors.ppOrange,
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 28,
              ),
            ),
          );
        },
      ),

      // Bottom Navigation
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBottomNavItem(
                  icon: Icons.home,
                  label: 'Inicio',
                  isSelected: true,
                  onTap: () {},
                ),
                _buildBottomNavItem(
                  icon: Icons.bar_chart,
                  label: 'Producción',
                  isSelected: false,
                  onTap: () {},
                ),
                _buildBottomNavItem(
                  icon: Icons.help_outline,
                  label: 'Ayuda',
                  isSelected: false,
                  onTap: () {},
                ),
                _buildBottomNavItem(
                  icon: Icons.person,
                  label: 'Perfil',
                  isSelected: false,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: BioWayColors.ppOrange,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: BioWayColors.textGrey,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: BioWayColors.darkGreen,
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: BioWayColors.ppOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: BioWayColors.ppOrange,
                    size: 20,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey.shade400,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: BioWayColors.darkGreen,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: BioWayColors.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapacitySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BioWayColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: BioWayColors.info.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bar_chart,
                color: BioWayColors.info,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Capacidad de Producción - Hoy',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: BioWayColors.darkGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_capacidadUtilizada.toInt()}%',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: BioWayColors.info,
                      ),
                    ),
                    const Text(
                      'Capacidad Utilizada',
                      style: TextStyle(
                        fontSize: 14,
                        color: BioWayColors.textGrey,
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
                      '$_materialProcesadoHoy t',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: BioWayColors.info,
                      ),
                    ),
                    const Text(
                      'Material Procesado',
                      style: TextStyle(
                        fontSize: 14,
                        color: BioWayColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Barra de progreso
          LinearProgressIndicator(
            value: _capacidadUtilizada / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(BioWayColors.info),
            minHeight: 8,
          ),
          const SizedBox(height: 8),
          Text(
            'Máxima eficiencia: ${100 - _capacidadUtilizada.toInt()}% restante disponible',
            style: TextStyle(
              fontSize: 12,
              color: BioWayColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoteCard(Map<String, dynamic> lote, {required bool isCompleted}) {
    final Color statusColor = isCompleted 
        ? BioWayColors.success 
        : (lote['estado'] == 'RECIBIDO' ? BioWayColors.info : BioWayColors.warning);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del lote
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.yellow.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              lote['id'],
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: BioWayColors.darkGreen,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Información principal
          Row(
            children: [
              Expanded(
                child: _buildLoteInfoItem(
                  icon: Icons.recycling,
                  label: 'MATERIAL',
                  value: lote['material'],
                  color: BioWayColors.success,
                ),
              ),
              Expanded(
                child: _buildLoteInfoItem(
                  icon: Icons.scale,
                  label: 'PESO',
                  value: '${lote['peso']} kg',
                  color: BioWayColors.warning,
                ),
              ),
              if (isCompleted)
                Expanded(
                  child: _buildLoteInfoItem(
                    icon: Icons.inventory,
                    label: 'PRODUCIDO',
                    value: '${lote['pesoProducido']} kg',
                    color: BioWayColors.ppOrange,
                  ),
                ),
              if (!isCompleted)
                Expanded(
                  child: _buildLoteInfoItem(
                    icon: Icons.flag,
                    label: 'Estado',
                    value: lote['estado'],
                    color: statusColor,
                    isStatus: true,
                  ),
                ),
            ],
          ),

          // Información adicional
          if (lote['origen'] != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.business, size: 16, color: BioWayColors.textGrey),
                const SizedBox(width: 4),
                Text(
                  'Origen: ${lote['origen']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: BioWayColors.textGrey,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.calendar_today, size: 16, color: BioWayColors.textGrey),
                const SizedBox(width: 4),
                Text(
                  isCompleted 
                      ? 'Finalizado: ${lote['fechaFinalizado']}'
                      : lote['fechaIniciado'] != null 
                          ? 'Iniciado: ${lote['fechaIniciado']}'
                          : 'Recibido: ${lote['fechaRecibido']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: BioWayColors.textGrey,
                  ),
                ),
              ],
            ),
          ],

          // Procesos aplicados
          if (lote['procesos'] != null) ...[
            const SizedBox(height: 12),
            const Text(
              'Proceso aplicado',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: BioWayColors.darkGreen,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: lote['procesos'].map<Widget>((proceso) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: BioWayColors.textGrey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    proceso,
                    style: TextStyle(
                      fontSize: 10,
                      color: BioWayColors.textGrey,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          // Información del producto (solo para completados)
          if (isCompleted && lote['producto'] != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: BioWayColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Producto Fabricado',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: BioWayColors.darkGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Producto:',
                        style: TextStyle(fontSize: 11, color: BioWayColors.textGrey),
                      ),
                      Text(
                        lote['producto'],
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: BioWayColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '% Material reciclado:',
                        style: TextStyle(fontSize: 11, color: BioWayColors.textGrey),
                      ),
                      Text(
                        '${lote['materialReciclado']}%',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: BioWayColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Compuesto al 67%:',
                        style: TextStyle(fontSize: 11, color: BioWayColors.textGrey),
                      ),
                      Text(
                        lote['compuestoAl'],
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: BioWayColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Botón de acción
          if (!isCompleted) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _actualizarDocumentacion(lote['id']),
                icon: const Icon(Icons.edit_document, size: 18),
                label: const Text('Actualizar Documentación'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BioWayColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoteInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isStatus = false,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        if (isStatus)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          )
        else
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: BioWayColors.textGrey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? BioWayColors.ppOrange : BioWayColors.textGrey,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? BioWayColors.ppOrange : BioWayColors.textGrey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}