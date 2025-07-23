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
  Map<String, dynamic>? _analysisResults;

  Future<void> _runAnalysis() async {
    setState(() {
      _isLoading = true;
      _lastResult = '';
      _analysisResults = null;
    });

    try {
      final results = await _profileService.analyzeProfileStructure();
      setState(() {
        _analysisResults = results;
        _lastResult = 'Análisis completado exitosamente';
      });
    } catch (e) {
      setState(() {
        _lastResult = 'Error al ejecutar análisis: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

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

  Future<void> _runCleanup() async {
    // Confirmar acción
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Limpieza'),
        content: const Text(
          'Esta acción limpiará todos los perfiles duplicados y reorganizará los índices.\n\n'
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
            child: const Text('Ejecutar Limpieza'),
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
      final results = await _profileService.cleanupDuplicateProfiles();
      setState(() {
        _lastResult = '''
Limpieza completada:
- Usuarios válidos: ${results['usuarios_validos']}
- Índices mantenidos: ${results['indices_mantenidos']}
- Documentos eliminados: ${results['documentos_eliminados']}
- Errores: ${results['errores']}
''';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BioWayColors.backgroundGrey,
      appBar: AppBar(
        title: const Text('Utilidades del Sistema'),
        backgroundColor: BioWayColors.ecoceGreen,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sección de Análisis
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
                        Icon(Icons.analytics, color: BioWayColors.primaryGreen),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Análisis de Estructura',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Analiza la estructura actual de perfiles en Firebase para detectar duplicados, '
                      'índices con datos extra y documentos huérfanos.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _runAnalysis,
                        icon: const Icon(Icons.search),
                        label: const Text('Ejecutar Análisis'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BioWayColors.primaryGreen,
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
            
            const SizedBox(height: 20),
            
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
            
            const SizedBox(height: 20),
            
            // Sección de Limpieza
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
                        Icon(Icons.cleaning_services, color: BioWayColors.warning),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Limpieza de Duplicados',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Elimina perfiles duplicados y reorganiza los índices para mantener '
                      'solo la estructura correcta.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _runCleanup,
                        icon: const Icon(Icons.delete_sweep),
                        label: const Text('Ejecutar Limpieza'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BioWayColors.warning,
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
            
            // Mostrar resultados del análisis
            if (_analysisResults != null) ...[
              const SizedBox(height: 20),
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
                      const Text(
                        'Resultados del Análisis',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStatRow('Usuarios en subcolecciones', 
                        _analysisResults!['usuarios_en_subcollecciones'], 
                        Colors.blue),
                      _buildStatRow('Índices limpios', 
                        _analysisResults!['indices_limpios'], 
                        BioWayColors.success),
                      _buildStatRow('Índices con datos extra', 
                        _analysisResults!['indices_con_datos_extra'], 
                        BioWayColors.warning),
                      _buildStatRow('Perfiles completos duplicados', 
                        _analysisResults!['perfiles_completos_en_principal'], 
                        BioWayColors.error),
                      _buildStatRow('Documentos huérfanos', 
                        _analysisResults!['documentos_huerfanos'], 
                        Colors.grey),
                    ],
                  ),
                ),
              ),
            ],
            
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