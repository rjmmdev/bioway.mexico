// Versión de desarrollo del login ECOCE con bypass para pruebas
// IMPORTANTE: NO usar en producción

import 'package:flutter/material.dart';
import '../../../services/firebase/auth_service.dart';
import '../../../services/firebase/firebase_manager.dart';
import '../../ecoce/maestro/maestro_unified_screen.dart';

class ECOCELoginDevScreen extends StatefulWidget {
  const ECOCELoginDevScreen({super.key});

  @override
  State<ECOCELoginDevScreen> createState() => _ECOCELoginDevScreenState();
}

class _ECOCELoginDevScreenState extends State<ECOCELoginDevScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      await _authService.initializeForPlatform(FirebasePlatform.ecoce);
    } catch (e) {
      print('Error inicializando Firebase: $e');
    }
  }

  Future<void> _loginAsMaestro() async {
    setState(() => _isLoading = true);
    
    try {
      // Intentar login con credenciales de maestro
      // Cambia estas credenciales según tu configuración
      await _authService.signInWithEmailAndPassword(
        email: 'maestro@test.com',
        password: 'master123',
      );
      
      // Navegar directamente sin verificar perfil
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MaestroUnifiedScreen(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ECOCE Login Dev'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.warning,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            const Text(
              'Modo Desarrollo',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Esta pantalla es solo para pruebas',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _loginAsMaestro,
              icon: _isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.admin_panel_settings),
              label: const Text('Entrar como Maestro'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }
}