import 'package:flutter/material.dart';
import '../../../../utils/colors.dart';

class HorariosScreen extends StatelessWidget {
  const HorariosScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: BioWayColors.primaryGreen,
        title: const Text(
          'Horarios de Recolección',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(
        child: Text(
          'Configuración de Horarios\n(En desarrollo)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}