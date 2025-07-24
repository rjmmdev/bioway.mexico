import 'package:flutter/material.dart';
import '../../../services/lote_unificado_service.dart';
import '../../../utils/colors.dart';

/// Pantalla de debug para verificar los lotes en Firestore
class RepositorioDebugScreen extends StatelessWidget {
  const RepositorioDebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loteService = LoteUnificadoService();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug: Lotes en Firestore'),
        backgroundColor: BioWayColors.primaryGreen,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: loteService.obtenerTodosLotesSimple(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }
          
          final lotes = snapshot.data ?? [];
          
          if (lotes.isEmpty) {
            return const Center(
              child: Text('No se encontraron lotes'),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lotes.length,
            itemBuilder: (context, index) {
              final lote = lotes[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ID: ${lote['id']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Datos: ${lote.toString()}'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}