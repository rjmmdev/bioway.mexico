import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:qr_flutter/qr_flutter.dart';
import 'transporte_formulario_entrega_screen.dart';

class TransporteQREntregaScreen extends StatefulWidget {
  final List<String> lotesEntrega;
  final double pesoTotal;
  final List<String> origenes;
  
  const TransporteQREntregaScreen({
    super.key,
    required this.lotesEntrega,
    required this.pesoTotal,
    required this.origenes,
  });

  @override
  State<TransporteQREntregaScreen> createState() => _TransporteQREntregaScreenState();
}

class _TransporteQREntregaScreenState extends State<TransporteQREntregaScreen> {
  Timer? _timer;
  int _tiempoRestante = 900; // 15 minutos en segundos
  bool _qrExpirado = false;
  
  @override
  void initState() {
    super.initState();
    _iniciarTemporizador();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  
  void _iniciarTemporizador() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_tiempoRestante > 0) {
            _tiempoRestante--;
          } else {
            _qrExpirado = true;
            timer.cancel();
          }
        });
      }
    });
  }
  
  String _formatearTiempo(int segundos) {
    final minutos = segundos ~/ 60;
    final segs = segundos % 60;
    return '${minutos.toString().padLeft(2, '0')}:${segs.toString().padLeft(2, '0')}';
  }
  
  void _generarNuevoCodigo() {
    setState(() {
      _tiempoRestante = 900;
      _qrExpirado = false;
    });
    _iniciarTemporizador();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nuevo código QR generado'),
        backgroundColor: Color(0xFF4CAF50),
      ),
    );
  }
  
  void _continuarAlFormulario() {
    if (_qrExpirado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El código QR ha expirado. Genera uno nuevo'),
          backgroundColor: Color(0xFFE74C3C),
        ),
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransporteFormularioEntregaScreen(
          lotesEntrega: widget.lotesEntrega,
          pesoTotal: widget.pesoTotal,
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Datos para el QR
    final qrData = {
      'lotes_salida': widget.lotesEntrega,
      'peso_total': widget.pesoTotal,
      'origen': widget.origenes.join(', '),
      'timestamp': DateTime.now().toIso8601String(),
    };
    final qrString = qrData.toString();
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.02,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1490EE), Color(0xFF70B7F9)],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        padding: EdgeInsets.zero,
                      ),
                      SizedBox(width: screenWidth * 0.03),
                      Text(
                        'QR de Entrega',
                        style: TextStyle(
                          fontSize: screenWidth * 0.06,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: screenHeight * 0.04),
                
                // QR Code Container
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.08),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // QR Code
                      QrImageView(
                        data: qrString,
                        version: QrVersions.auto,
                        size: 250.0,
                        backgroundColor: Colors.white,
                        errorStateBuilder: (context, error) {
                          return Container(
                            width: 250,
                            height: 250,
                            alignment: Alignment.center,
                            child: const Text(
                              'Error al generar QR',
                              style: TextStyle(color: Colors.red),
                            ),
                          );
                        },
                      ),
                      
                      SizedBox(height: screenHeight * 0.03),
                      
                      // Temporizador
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.06,
                          vertical: screenHeight * 0.015,
                        ),
                        decoration: BoxDecoration(
                          color: _qrExpirado 
                              ? const Color(0xFFFFEBEE)
                              : (_tiempoRestante < 60 
                                  ? const Color(0xFFFFF3E0) 
                                  : const Color(0xFFE3F2FD)),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: _qrExpirado
                                ? const Color(0xFFE74C3C).withValues(alpha: 0.3)
                                : (_tiempoRestante < 60
                                    ? const Color(0xFFF57C00).withValues(alpha: 0.3)
                                    : const Color(0xFF2196F3).withValues(alpha: 0.3)),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer,
                              size: screenWidth * 0.05,
                              color: _qrExpirado
                                  ? const Color(0xFFE74C3C)
                                  : (_tiempoRestante < 60
                                      ? const Color(0xFFF57C00)
                                      : const Color(0xFF2196F3)),
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            Text(
                              _qrExpirado 
                                  ? 'Código expirado'
                                  : 'Válido por ${_formatearTiempo(_tiempoRestante)}',
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.w600,
                                color: _qrExpirado
                                    ? const Color(0xFFE74C3C)
                                    : (_tiempoRestante < 60
                                        ? const Color(0xFFF57C00)
                                        : const Color(0xFF2196F3)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: screenHeight * 0.03),
                
                // Resumen de entrega
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF2196F3).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total de lotes:',
                            style: TextStyle(
                              fontSize: screenWidth * 0.035,
                              color: const Color(0xFF606060),
                            ),
                          ),
                          Text(
                            widget.lotesEntrega.length.toString(),
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0D47A1),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Peso total:',
                            style: TextStyle(
                              fontSize: screenWidth * 0.035,
                              color: const Color(0xFF606060),
                            ),
                          ),
                          Text(
                            '${widget.pesoTotal.toStringAsFixed(1)} kg',
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0D47A1),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Origen(es):',
                            style: TextStyle(
                              fontSize: screenWidth * 0.035,
                              color: const Color(0xFF606060),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              widget.origenes.join('\n'),
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0D47A1),
                              ),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: screenHeight * 0.03),
                
                // Instrucciones
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFF57C00).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: const Color(0xFFF57C00),
                            size: screenWidth * 0.05,
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          Text(
                            'Instrucciones',
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFE65100),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      _buildInstruccion('1. El receptor debe escanear este código QR'),
                      SizedBox(height: screenHeight * 0.01),
                      _buildInstruccion('2. Se verificará la información de los lotes'),
                      SizedBox(height: screenHeight * 0.01),
                      _buildInstruccion('3. Procede con el formulario de entrega'),
                      SizedBox(height: screenHeight * 0.01),
                      _buildInstruccion('4. El código expira en 15 minutos'),
                    ],
                  ),
                ),
                
                SizedBox(height: screenHeight * 0.04),
                
                // Botones
                if (_qrExpirado) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _generarNuevoCodigo,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Generar nuevo código'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2196F3),
                        side: const BorderSide(
                          color: Color(0xFF2196F3),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    key: const Key('btn_to_form_entrega'),
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _continuarAlFormulario,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Continuar al Formulario de Entrega',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
                
                SizedBox(height: screenHeight * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildInstruccion(String texto) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle_outline,
          size: screenWidth * 0.04,
          color: const Color(0xFFE65100),
        ),
        SizedBox(width: screenWidth * 0.02),
        Expanded(
          child: Text(
            texto,
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              color: const Color(0xFF795548),
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}