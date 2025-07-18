import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import '../shared/utils/material_utils.dart';
import 'laboratorio_escaneo.dart';
import 'laboratorio_gestion_muestras.dart';
import 'widgets/laboratorio_muestra_card.dart';

// Modelo temporal para representar una muestra
class ScannedMuestra {
  final String id;
  final String material;
  final double weight;
  final String format; // 'Muestra'
  final DateTime dateScanned;

  ScannedMuestra({
    required this.id,
    required this.material,
    required this.weight,
    required this.format,
    required this.dateScanned,
  });
}

class LaboratorioRegistroMuestrasScreen extends StatefulWidget {
  final String? initialMuestraId;

  const LaboratorioRegistroMuestrasScreen({
    super.key,
    this.initialMuestraId,
  });

  @override
  State<LaboratorioRegistroMuestrasScreen> createState() => _LaboratorioRegistroMuestrasScreenState();
}

class _LaboratorioRegistroMuestrasScreenState extends State<LaboratorioRegistroMuestrasScreen> {
  // Lista de muestras escaneadas
  List<ScannedMuestra> _scannedMuestras = [];

  @override
  void initState() {
    super.initState();
    // Si viene con un ID inicial, agregarlo a la lista
    if (widget.initialMuestraId != null) {
      _addMuestraFromId(widget.initialMuestraId!);
    }
  }

  void _addMuestraFromId(String muestraId) {
    // TODO: Aquí se consultaría la base de datos con el ID
    // Por ahora simulamos datos
    final newMuestra = ScannedMuestra(
      id: muestraId,
      material: _getMaterialForDemo(muestraId),
      weight: _getWeightForDemo(),
      format: 'Muestra',
      dateScanned: DateTime.now(),
    );

    setState(() {
      _scannedMuestras.add(newMuestra);
    });
  }

  // Métodos temporales para simular datos
  String _getMaterialForDemo(String id) {
    final materials = ['PEBD', 'PP', 'Multilaminado'];
    return materials[id.length % materials.length];
  }

  double _getWeightForDemo() {
    // Para muestras, pesos más pequeños (1-5 kg)
    return 1 + (DateTime.now().millisecondsSinceEpoch % 40) / 10;
  }

  void _removeMuestra(int index) {
    HapticFeedback.lightImpact();

    setState(() {
      _scannedMuestras.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Muestra eliminada'),
        backgroundColor: BioWayColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Deshacer',
          textColor: Colors.white,
          onPressed: () {
            // TODO: Implementar deshacer eliminación
          },
        ),
      ),
    );
  }

  void _addMoreMuestras() async {
    HapticFeedback.lightImpact();

    // Navegar al escáner indicando que estamos agregando más muestras
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const LaboratorioEscaneoScreen(isAddingMore: true),
      ),
    );

    // Si regresa con un ID, agregarlo
    if (result != null && result.isNotEmpty) {
      _addMuestraFromId(result);
    }
  }

  void _continueWithMuestras() {
    if (_scannedMuestras.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Debe escanear al menos una muestra'),
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

    // Navegar directamente a la Gestión de Muestras en la pestaña de Formulario
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LaboratorioGestionMuestras(
          initialTab: 0, // Pestaña de Formulario
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BioWayColors.backgroundGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: BioWayColors.darkGreen),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Muestras Escaneadas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: BioWayColors.darkGreen,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
        ),
      ),
      body: Column(
        children: [
          // Mensaje de confirmación
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            color: Colors.white,
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: BioWayColors.success,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Código QR escaneado correctamente',
                    style: TextStyle(
                      fontSize: 14,
                      color: BioWayColors.darkGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Resumen de carga
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  BioWayColors.ecoceGreen,
                  BioWayColors.ecoceGreen.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: BioWayColors.ecoceGreen.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Resumen de Muestras',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _scannedMuestras.length.toString(),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Muestras',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // Header de la lista
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Muestras Escaneadas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: BioWayColors.darkGreen,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addMoreMuestras,
                  icon: Icon(
                    Icons.add,
                    color: BioWayColors.ecoceGreen,
                    size: 20,
                  ),
                  label: Text(
                    'Agregar',
                    style: TextStyle(
                      color: BioWayColors.ecoceGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    backgroundColor: BioWayColors.ecoceGreen.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lista de muestras
          Expanded(
            child: _scannedMuestras.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.science_outlined,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay muestras escaneadas',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _addMoreMuestras,
                    child: Text(
                      'Escanear primera muestra',
                      style: TextStyle(
                        color: BioWayColors.ecoceGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: _scannedMuestras.length,
              itemBuilder: (context, index) {
                final muestra = _scannedMuestras[index];
                final muestraMap = {
                  'id': muestra.id,
                  'material': muestra.material,
                  'peso': muestra.weight,
                  'presentacion': muestra.format,
                  'origen': 'Reciclador',
                  'fecha': MaterialUtils.formatDate(muestra.dateScanned),
                  'estado': 'registro', // Estado temporal para registro
                };
                
                return LaboratorioMuestraCard(
                  muestra: muestraMap,
                  onTap: () {
                    // No hacemos nada en el tap principal
                  },
                  trailing: IconButton(
                    onPressed: () => _removeMuestra(index),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: BioWayColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.close,
                        color: BioWayColors.error,
                        size: 20,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Botón continuar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _scannedMuestras.isNotEmpty ? _continueWithMuestras : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BioWayColors.ecoceGreen,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: _scannedMuestras.isNotEmpty ? 3 : 0,
                  ),
                  child: Text(
                    _scannedMuestras.isEmpty
                        ? 'Escanea al menos una muestra'
                        : 'Continuar con ${_scannedMuestras.length} muestra${_scannedMuestras.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}