import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/colors.dart';

class RecepcionMaterialScreen extends StatefulWidget {
  final String qrCode;
  final String centroAcopioId;

  const RecepcionMaterialScreen({
    Key? key,
    required this.qrCode,
    required this.centroAcopioId,
  }) : super(key: key);

  @override
  State<RecepcionMaterialScreen> createState() => _RecepcionMaterialScreenState();
}

class _RecepcionMaterialScreenState extends State<RecepcionMaterialScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _cantidadControllers = {};
  
  bool _isLoading = true;
  Map<String, dynamic>? _recolectorData;
  Map<String, dynamic>? _solicitudData;
  List<Map<String, dynamic>> _materialesDisponibles = [];
  double _comisionTotal = 0.0;

  @override
  void initState() {
    super.initState();
    _loadDataFromQR();
  }

  Future<void> _loadDataFromQR() async {
    try {
      // Decodificar QR (formato: solicitudId:recolectorId)
      final parts = widget.qrCode.split(':');
      if (parts.length != 2) {
        throw Exception('Código QR inválido');
      }

      final solicitudId = parts[0];
      final recolectorId = parts[1];

      // Cargar datos del recolector
      final recolectorDoc = await FirebaseFirestore.instance
          .collection('bioway_recolectores')
          .doc(recolectorId)
          .get();

      if (!recolectorDoc.exists) {
        throw Exception('Recolector no encontrado');
      }

      // Cargar datos de la solicitud
      final solicitudDoc = await FirebaseFirestore.instance
          .collection('bioway_solicitudes')
          .doc(solicitudId)
          .get();

      if (!solicitudDoc.exists) {
        throw Exception('Solicitud no encontrada');
      }

      // Cargar materiales disponibles
      final materialesSnapshot = await FirebaseFirestore.instance
          .collection('bioway_materiales')
          .where('activo', isEqualTo: true)
          .get();

      setState(() {
        _recolectorData = recolectorDoc.data();
        _solicitudData = solicitudDoc.data();
        _materialesDisponibles = materialesSnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
        
        // Inicializar controladores
        for (var material in _materialesDisponibles) {
          _cantidadControllers[material['id']] = TextEditingController();
        }
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context);
    }
  }

  void _calcularComision() {
    double total = 0.0;
    _cantidadControllers.forEach((materialId, controller) {
      final cantidad = double.tryParse(controller.text) ?? 0.0;
      final material = _materialesDisponibles.firstWhere(
        (m) => m['id'] == materialId,
        orElse: () => {'precioKg': 0.0},
      );
      total += cantidad * (material['precioKg'] ?? 0.0) * 0.10; // 10% comisión
    });
    
    setState(() {
      _comisionTotal = total;
    });
  }

  Future<void> _procesarRecepcion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final batch = FirebaseFirestore.instance.batch();
      final timestamp = FieldValue.serverTimestamp();
      final recepcionId = FirebaseFirestore.instance
          .collection('bioway_recepciones')
          .doc()
          .id;

      // Crear registro de recepción
      final recepcionData = {
        'id': recepcionId,
        'centroAcopioId': widget.centroAcopioId,
        'recolectorId': _recolectorData!['id'],
        'solicitudId': _solicitudData!['id'],
        'fecha': timestamp,
        'materiales': {},
        'pesoTotal': 0.0,
        'comisionBioWay': _comisionTotal,
        'estado': 'completado',
      };

      // Agregar materiales y calcular peso total
      double pesoTotal = 0.0;
      _cantidadControllers.forEach((materialId, controller) {
        final cantidad = double.tryParse(controller.text) ?? 0.0;
        if (cantidad > 0) {
          recepcionData['materiales'][materialId] = cantidad;
          pesoTotal += cantidad;
        }
      });
      recepcionData['pesoTotal'] = pesoTotal;

      // Guardar recepción
      batch.set(
        FirebaseFirestore.instance
            .collection('bioway_recepciones')
            .doc(recepcionId),
        recepcionData,
      );

      // Actualizar inventario del centro
      batch.update(
        FirebaseFirestore.instance
            .collection('bioway_centros_acopio')
            .doc(widget.centroAcopioId),
        {
          'inventarioActual': FieldValue.increment(pesoTotal),
          'totalRecepcionesMes': FieldValue.increment(1),
          'saldoPrepago': FieldValue.increment(-_comisionTotal),
          'ultimaActividad': timestamp,
        },
      );

      // Actualizar estadísticas del recolector
      batch.update(
        FirebaseFirestore.instance
            .collection('bioway_recolectores')
            .doc(_recolectorData!['id']),
        {
          'totalKgRecolectados': FieldValue.increment(pesoTotal),
          'totalResiduosRecolectados': FieldValue.increment(1),
          'bioCoins': FieldValue.increment((pesoTotal * 10).round()),
          'ultimaActividad': timestamp,
        },
      );

      // Marcar solicitud como completada
      batch.update(
        FirebaseFirestore.instance
            .collection('bioway_solicitudes')
            .doc(_solicitudData!['id']),
        {
          'estado': 'completado',
          'fechaCompletado': timestamp,
        },
      );

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recepción registrada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: BioWayColors.primaryGreen,
          title: const Text('Recepción de Material'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: BioWayColors.primaryGreen,
        title: const Text(
          'Recepción de Material',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información del recolector
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recolector',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.person, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            _recolectorData?['nombre'] ?? 'Sin nombre',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      if (_recolectorData?['empresa'] != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.business, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              _recolectorData!['empresa'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Materiales a recibir
                const Text(
                  'Materiales Recibidos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                ..._materialesDisponibles.map((material) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.recycling,
                          color: Color(int.parse(
                            material['color'].replaceAll('#', '0xFF'),
                          )),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                material['nombre'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '\$${material['precioKg']?.toStringAsFixed(2) ?? '0.00'}/kg',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: TextFormField(
                            controller: _cantidadControllers[material['id']],
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              hintText: '0.0',
                              suffixText: 'kg',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => _calcularComision(),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return null;
                              }
                              final cantidad = double.tryParse(value);
                              if (cantidad == null || cantidad < 0) {
                                return 'Inválido';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),

                const SizedBox(height: 20),

                // Resumen
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: BioWayColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: BioWayColors.primaryGreen.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Comisión BioWay (10%):',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '\$${_comisionTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: BioWayColors.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Botón procesar
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _procesarRecepcion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BioWayColors.primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'Procesar Recepción',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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

  @override
  void dispose() {
    _cantidadControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }
}