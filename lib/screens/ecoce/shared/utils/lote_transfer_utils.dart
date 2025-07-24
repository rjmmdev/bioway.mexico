import 'package:flutter/material.dart';
import 'package:app/models/lotes/lote_unificado_model.dart';
import 'package:app/screens/ecoce/shared/widgets/transferir_lote_dialog.dart';
import 'package:app/utils/colors.dart';

/// Utilidades para facilitar la transferencia de lotes entre procesos
class LoteTransferUtils {
  
  /// Muestra el diálogo de transferencia de lote
  static Future<void> mostrarDialogoTransferencia({
    required BuildContext context,
    required LoteUnificadoModel lote,
    required String procesoDestino,
    Function(String)? onSuccess,
  }) async {
    // Mapeo de procesos a nombres legibles
    final nombresProcesos = {
      'transporte': 'Transportista',
      'reciclador': 'Reciclador', 
      'laboratorio': 'Laboratorio',
      'transformador': 'Transformador',
    };
    
    // Obtener color según el proceso actual
    final colorProceso = _getColorPorProceso(lote.datosGenerales.procesoActual);
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TransferirLoteDialog(
        lote: lote,
        procesoDestino: procesoDestino,
        nombreProcesoDestino: nombresProcesos[procesoDestino] ?? procesoDestino,
        primaryColor: colorProceso,
        onSuccess: onSuccess,
      ),
    );
  }
  
  /// Determina si un lote puede ser transferido a un proceso específico
  static bool puedeTransferirA(LoteUnificadoModel lote, String procesoDestino) {
    final procesoActual = lote.datosGenerales.procesoActual;
    
    // Reglas de negocio para transferencias válidas
    final transicionesValidas = {
      'origen': ['transporte', 'reciclador'],
      'transporte': ['reciclador', 'transformador', 'laboratorio'],
      'reciclador': ['transporte', 'transformador', 'laboratorio'],
      'laboratorio': ['transporte', 'reciclador', 'transformador'],
      'transformador': [], // Fin del proceso
    };
    
    return transicionesValidas[procesoActual]?.contains(procesoDestino) ?? false;
  }
  
  /// Obtiene los procesos disponibles para transferir desde el proceso actual
  static List<String> getProcesosPosibles(String procesoActual) {
    final transiciones = {
      'origen': ['transporte', 'reciclador'],
      'transporte': ['reciclador', 'transformador', 'laboratorio'],
      'reciclador': ['transporte', 'transformador', 'laboratorio'],
      'laboratorio': ['transporte', 'reciclador', 'transformador'],
      'transformador': <String>[],
    };
    
    return transiciones[procesoActual] ?? <String>[];
  }
  
  /// Obtiene el color asociado a un proceso
  static Color _getColorPorProceso(String proceso) {
    switch (proceso) {
      case 'origen':
        return const Color(0xFF2E7D32); // Verde oscuro
      case 'transporte':
        return const Color(0xFF1976D2); // Azul
      case 'reciclador':
        return const Color(0xFF388E3C); // Verde
      case 'laboratorio':
        return const Color(0xFF7B1FA2); // Púrpura
      case 'transformador':
        return const Color(0xFFD32F2F); // Rojo
      default:
        return BioWayColors.ecoceGreen;
    }
  }
  
  /// Genera un resumen de la trazabilidad del lote
  static String generarResumenTrazabilidad(LoteUnificadoModel lote) {
    final buffer = StringBuffer();
    
    // Información general
    buffer.writeln('=== TRAZABILIDAD DEL LOTE ===');
    buffer.writeln('ID: ${lote.id}');
    buffer.writeln('Material: ${lote.datosGenerales.tipoMaterial}');
    buffer.writeln('Peso inicial: ${lote.datosGenerales.pesoInicial} kg');
    buffer.writeln('Peso actual: ${lote.pesoActual} kg');
    buffer.writeln('Merma total: ${lote.mermaTotal} kg (${lote.porcentajeMerma.toStringAsFixed(1)}%)');
    buffer.writeln('');
    
    // Historial de procesos
    buffer.writeln('RECORRIDO:');
    for (int i = 0; i < lote.datosGenerales.historialProcesos.length; i++) {
      final proceso = lote.datosGenerales.historialProcesos[i];
      final esActual = proceso == lote.datosGenerales.procesoActual;
      
      buffer.write('${i + 1}. ${_getNombreProceso(proceso)}');
      if (esActual) {
        buffer.write(' (ACTUAL)');
      }
      buffer.writeln();
      
      // Detalles del proceso
      _agregarDetallesProceso(buffer, lote, proceso);
    }
    
    return buffer.toString();
  }
  
  static String _getNombreProceso(String proceso) {
    final nombres = {
      'origen': 'Origen',
      'transporte': 'Transporte',
      'reciclador': 'Reciclador',
      'laboratorio': 'Laboratorio', 
      'transformador': 'Transformador',
    };
    return nombres[proceso] ?? proceso;
  }
  
  static void _agregarDetallesProceso(StringBuffer buffer, LoteUnificadoModel lote, String proceso) {
    switch (proceso) {
      case 'origen':
        if (lote.origen != null) {
          buffer.writeln('   - Usuario: ${lote.origen!.usuarioFolio}');
          buffer.writeln('   - Fecha: ${_formatDate(lote.origen!.fechaEntrada)}');
          buffer.writeln('   - Peso: ${lote.origen!.pesoNace} kg');
        }
        break;
        
      case 'transporte':
        if (lote.transporte != null) {
          buffer.writeln('   - Usuario: ${lote.transporte!.usuarioFolio}');
          buffer.writeln('   - Fecha entrada: ${_formatDate(lote.transporte!.fechaEntrada)}');
          if (lote.transporte!.fechaSalida != null) {
            buffer.writeln('   - Fecha salida: ${_formatDate(lote.transporte!.fechaSalida!)}');
          }
          buffer.writeln('   - Peso recogido: ${lote.transporte!.pesoRecogido} kg');
          if (lote.transporte!.pesoEntregado != null) {
            buffer.writeln('   - Peso entregado: ${lote.transporte!.pesoEntregado} kg');
          }
        }
        break;
        
      case 'reciclador':
        if (lote.reciclador != null) {
          buffer.writeln('   - Usuario: ${lote.reciclador!.usuarioFolio}');
          buffer.writeln('   - Fecha entrada: ${_formatDate(lote.reciclador!.fechaEntrada)}');
          buffer.writeln('   - Peso entrada: ${lote.reciclador!.pesoEntrada} kg');
          if (lote.reciclador!.pesoProcesado != null) {
            buffer.writeln('   - Peso procesado: ${lote.reciclador!.pesoProcesado} kg');
          }
        }
        break;
        
      case 'laboratorio':
        if (lote.laboratorio != null) {
          buffer.writeln('   - Usuario: ${lote.laboratorio!.usuarioFolio}');
          buffer.writeln('   - Fecha: ${_formatDate(lote.laboratorio!.fechaEntrada)}');
          buffer.writeln('   - Peso muestra: ${lote.laboratorio!.pesoMuestra} kg');
        }
        break;
        
      case 'transformador':
        if (lote.transformador != null) {
          buffer.writeln('   - Usuario: ${lote.transformador!.usuarioFolio}');
          buffer.writeln('   - Fecha entrada: ${_formatDate(lote.transformador!.fechaEntrada)}');
          buffer.writeln('   - Peso entrada: ${lote.transformador!.pesoEntrada} kg');
          if (lote.transformador!.pesoSalida != null) {
            buffer.writeln('   - Peso salida: ${lote.transformador!.pesoSalida} kg');
          }
        }
        break;
    }
    buffer.writeln();
  }
  
  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}