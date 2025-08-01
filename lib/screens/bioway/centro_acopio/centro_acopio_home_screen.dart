import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../utils/colors.dart';
import '../../../services/user_session_service.dart';
import '../../../models/bioway/centro_acopio_model.dart';
import 'recepcion_material_screen.dart';
import 'inventario_screen.dart';
import 'reportes_screen.dart';
import 'prepago_screen.dart';

class CentroAcopioHomeScreen extends StatefulWidget {
  const CentroAcopioHomeScreen({super.key});

  @override
  State<CentroAcopioHomeScreen> createState() => _CentroAcopioHomeScreenState();
}

class _CentroAcopioHomeScreenState extends State<CentroAcopioHomeScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  CentroAcopioModel? _centroAcopio;
  bool _isLoading = true;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _loadCentroAcopioData();
    _updateActivity();
  }

  Future<void> _updateActivity() async {
    // Activity tracking removed - not implemented yet
  }

  Future<void> _loadCentroAcopioData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('bioway_centros_acopio')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          setState(() {
            _centroAcopio = CentroAcopioModel.fromJson({
              'id': doc.id,
              ...doc.data()!,
            });
            _isLoading = false;
          });
        } else {
          // Crear centro de acopio por defecto si no existe
          setState(() {
            _centroAcopio = CentroAcopioModel(
              id: user.uid,
              nombre: 'Centro de Acopio',
              direccion: 'Sin dirección',
              estado: 'Estado',
              municipio: 'Municipio',
              codigoPostal: '00000',
              latitud: 0.0,
              longitud: 0.0,
              telefono: '0000000000',
              responsable: user.email ?? 'Sin responsable',
              saldoPrepago: 0.0,
              comisionBioWay: 0.10,
              reputacion: 5.0,
              totalRecepcionesMes: 0,
              inventarioActual: {},
              fechaRegistro: DateTime.now(),
              activo: true,
            );
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error cargando datos del centro: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showQRScanner() {
    setState(() => _isScanning = true);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Escanear QR del Recolector',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: MobileScanner(
                controller: _scannerController,
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty) {
                    final String? code = barcodes.first.rawValue;
                    if (code != null) {
                      Navigator.pop(context);
                      _processQRCode(code);
                    }
                  }
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      setState(() => _isScanning = false);
    });
  }

  void _processQRCode(String code) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecepcionMaterialScreen(
          qrCode: code,
          centroAcopioId: _centroAcopio?.id ?? '',
        ),
      ),
    ).then((_) => _loadCentroAcopioData());
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 30),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: BioWayColors.primaryGreen,
        title: const Text(
          'Centro de Acopio',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              UserSessionService().clearSession();
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadCentroAcopioData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información del centro
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        BioWayColors.primaryGreen,
                        BioWayColors.primaryGreen.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _centroAcopio?.nombre ?? 'Centro de Acopio',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${_centroAcopio?.municipio}, ${_centroAcopio?.estado}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Saldo Prepago',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '\$${_centroAcopio?.saldoPrepago.toStringAsFixed(2) ?? '0.00'}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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
                                const Icon(
                                  Icons.star,
                                  color: Colors.yellow,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _centroAcopio?.reputacion.toStringAsFixed(1) ?? '5.0',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
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
                const SizedBox(height: 24),

                // Estadísticas
                const Text(
                  'Estadísticas del Mes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    _buildStatCard(
                      'Recepciones',
                      '${_centroAcopio?.totalRecepcionesMes ?? 0}',
                      Icons.inbox,
                      BioWayColors.primaryGreen,
                    ),
                    _buildStatCard(
                      'Inventario Total',
                      '${_calculateTotalInventory()} kg',
                      Icons.inventory,
                      Colors.blue,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Acciones principales
                const Text(
                  'Acciones Rápidas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1,
                  children: [
                    _buildActionButton(
                      title: 'Recibir Material',
                      icon: Icons.qr_code_scanner,
                      color: BioWayColors.primaryGreen,
                      onTap: _showQRScanner,
                    ),
                    _buildActionButton(
                      title: 'Inventario',
                      icon: Icons.inventory_2,
                      color: Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => InventarioScreen(
                              centroAcopioId: _centroAcopio?.id ?? '',
                            ),
                          ),
                        );
                      },
                    ),
                    _buildActionButton(
                      title: 'Reportes',
                      icon: Icons.assessment,
                      color: Colors.orange,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReportesScreen(
                              centroAcopioId: _centroAcopio?.id ?? '',
                            ),
                          ),
                        );
                      },
                    ),
                    _buildActionButton(
                      title: 'Recargar Saldo',
                      icon: Icons.account_balance_wallet,
                      color: Colors.purple,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PrepagoScreen(
                              centroAcopioId: _centroAcopio?.id ?? '',
                              saldoActual: _centroAcopio?.saldoPrepago ?? 0.0,
                            ),
                          ),
                        ).then((_) => _loadCentroAcopioData());
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _calculateTotalInventory() {
    if (_centroAcopio == null) return 0.0;
    return _centroAcopio!.inventarioActual.values.fold(0.0, (sum, value) => sum + value);
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }
}