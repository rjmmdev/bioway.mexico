import 'package:flutter/material.dart';
import '../../../services/firebase/ecoce_profile_service.dart';
import '../../../utils/colors.dart';
import '../shared/widgets/common_widgets.dart';

class MaestroUtilitiesScreen extends StatefulWidget {
  const MaestroUtilitiesScreen({super.key});

  @override
  State<MaestroUtilitiesScreen> createState() => _MaestroUtilitiesScreenState();
}

class _MaestroUtilitiesScreenState extends State<MaestroUtilitiesScreen> {
  final EcoceProfileService _profileService = EcoceProfileService();
  bool _isLoading = false;
  String _lastResult = '';
  // Método de análisis removido - ya no es necesario sin índices

  Future<void> _cleanupPendingDeletions() async {
    // Confirmar acción
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Limpieza'),
        content: const Text(
          'Esta acción eliminará todos los registros de usuarios pendientes de eliminación '
          'que tengan más de 30 días de antigüedad.\n\n'
          '¿Estás seguro de continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: BioWayColors.error,
            ),
            child: const Text('Limpiar Registros'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _lastResult = '';
    });

    try {
      await _profileService.cleanupPendingDeletions();
      setState(() {
        _lastResult = 'Limpieza completada exitosamente. Los registros antiguos han sido eliminados.';
      });
    } catch (e) {
      setState(() {
        _lastResult = 'Error al ejecutar limpieza: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Método de limpieza removido - ya no es necesario sin índices

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BioWayColors.backgroundGrey,
      appBar: AppBar(
        title: const Text('Mantenimiento del Sistema'),
        backgroundColor: BioWayColors.ecoceGreen,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            
            // Sección de Limpieza de Usuarios Pendientes
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person_remove, color: BioWayColors.error),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Limpiar Usuarios Pendientes de Eliminación',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Elimina los registros antiguos de la colección "users_pending_deletion" '
                      'que tienen más de 30 días de antigüedad.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _cleanupPendingDeletions,
                        icon: const Icon(Icons.cleaning_services),
                        label: const Text('Limpiar Registros Antiguos'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BioWayColors.error,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            
            // Mostrar resultados
            if (_lastResult.isNotEmpty) ...[
              const SizedBox(height: 20),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: _lastResult.contains('Error') 
                  ? BioWayColors.error.withValues(alpha:0.1)
                  : BioWayColors.success.withValues(alpha:0.1),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _lastResult.contains('Error') 
                              ? Icons.error 
                              : Icons.check_circle,
                            color: _lastResult.contains('Error') 
                              ? BioWayColors.error 
                              : BioWayColors.success,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _lastResult.contains('Error') 
                              ? 'Error' 
                              : 'Resultado',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _lastResult,
                        style: TextStyle(
                          color: _lastResult.contains('Error') 
                            ? BioWayColors.error 
                            : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            // Loading indicator
            if (_isLoading) ...[
              const SizedBox(height: 40),
              const Center(
                child: CircularProgressIndicator(),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Procesando...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatRow(String label, dynamic value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}