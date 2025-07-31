import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/colors.dart';
import '../../../services/firebase/firebase_manager.dart';
import '../../../services/firebase/auth_service.dart';

class MaestroRegisterScreen extends StatefulWidget {
  const MaestroRegisterScreen({super.key});

  @override
  State<MaestroRegisterScreen> createState() => _MaestroRegisterScreenState();
}

class _MaestroRegisterScreenState extends State<MaestroRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final FirebaseManager _firebaseManager = FirebaseManager();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _successMessage;
  
  FirebaseFirestore get _firestore {
    final app = _firebaseManager.currentApp;
    if (app == null) {
      throw Exception('Firebase no inicializado para ECOCE');
    }
    return FirebaseFirestore.instanceFor(app: app);
  }
  
  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }
  
  Future<void> _initializeFirebase() async {
    try {
      await _authService.initializeForPlatform(FirebasePlatform.ecoce);
      print('Firebase inicializado correctamente para ECOCE');
    } catch (e) {
      print('Error al inicializar Firebase: $e');
      setState(() {
        _errorMessage = 'Error al inicializar Firebase. Por favor, recargue la página.';
      });
    }
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  Future<void> _createMaestroAccount() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    
    try {
      // Paso 1: Crear usuario en Firebase Auth
      final userCredential = await _authService.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      if (userCredential.user != null) {
        final userId = userCredential.user!.uid;
        
        // Esperar un momento para que Firebase propague los permisos
        await Future.delayed(const Duration(seconds: 2));
        
        // Forzar recarga del token
        await userCredential.user!.reload();
        await userCredential.user!.getIdToken(true);
        
        // Paso 2: Crear documento en colección de maestros
        try {
          print('Intentando crear documento maestro para UID: $userId');
          print('Usuario autenticado actual: ${_authService.currentUser?.uid}');
          
          await _firestore
              .collection('maestros')
              .doc(userId)
              .set({
            'email': _emailController.text.trim(),
            'uid': userId,
            'created_at': FieldValue.serverTimestamp(),
            'nombre': 'Administrador ECOCE',
            'activo': true,
          });
          
          print('Documento maestro creado exitosamente');
        } catch (firestoreError) {
          // Si falla, intentar con un enfoque diferente
          print('Error al crear documento maestro: $firestoreError');
          print('UID del usuario: $userId');
          print('Estado de autenticación: ${_authService.currentUser?.uid}');
          
          // Mostrar mensaje de éxito parcial
          setState(() {
            _isLoading = false;
            _successMessage = '✅ Usuario creado en Auth!\n\n'
                'UID: $userId\n'
                'Email: ${_emailController.text}\n\n'
                '⚠️ El perfil maestro no se pudo crear automáticamente.\n'
                'Use "Ya tengo cuenta" para completar el registro.\n\n'
                'Error técnico: ${firestoreError.toString()}';
          });
          
          await _authService.signOut();
          return;
        }
        
        setState(() {
          _isLoading = false;
          _successMessage = '✅ Cuenta maestro creada con éxito!\n\nUID: $userId\nEmail: ${_emailController.text}';
        });
        
        // Cerrar sesión para que puedan hacer login normal
        await _authService.signOut();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
  }
  
  Future<void> _setupExistingUser() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    
    try {
      // Intentar hacer login
      final userCredential = await _authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      if (userCredential.user != null) {
        final userId = userCredential.user!.uid;
        
        // Crear documento en colección de maestros
        await _firestore
            .collection('maestros')
            .doc(userId)
            .set({
          'email': _emailController.text.trim(),
          'uid': userId,
          'created_at': FieldValue.serverTimestamp(),
          'nombre': 'Administrador ECOCE',
          'activo': true,
        }, SetOptions(merge: true));
        
        setState(() {
          _isLoading = false;
          _successMessage = '✅ Perfil maestro creado para usuario existente!\n\nUID: $userId';
        });
        
        await _authService.signOut();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Registro Maestro ECOCE'),
        backgroundColor: BioWayColors.ecoceGreen,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mensajes
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red[700], fontSize: 14),
                  ),
                ),
              
              if (_successMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Text(
                    _successMessage!,
                    style: TextStyle(color: Colors.green[700], fontSize: 14),
                  ),
                ),
              
              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa un email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa una contraseña';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Botón crear nueva cuenta
              ElevatedButton(
                onPressed: _isLoading ? null : _createMaestroAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: BioWayColors.ecoceGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Crear Nueva Cuenta Maestro',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
              const SizedBox(height: 12),
              
              // Botón para usuario existente
              OutlinedButton(
                onPressed: _isLoading ? null : _setupExistingUser,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Ya tengo cuenta, solo crear perfil',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 24),
              
              // Instrucciones
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instrucciones:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. Si es la primera vez, usa "Crear Nueva Cuenta"\n'
                      '2. Si ya creaste la cuenta pero falta el perfil, usa "Ya tengo cuenta"\n'
                      '3. Después de crear, inicia sesión normalmente\n'
                      '4. La cuenta de maestro tiene acceso completo al sistema\n'
                      '5. La cuenta se guarda en la colección "maestros"',
                      style: TextStyle(color: Colors.blue[700], fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Información adicional
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.green[700], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Estructura de Datos',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Los usuarios maestro tienen su propia colección.\n'
                      'No utilizan el modelo de proveedores (EcoceProfileModel).\n'
                      'Estructura simplificada solo para administradores.\n'
                      'Acceso completo a todas las funciones del sistema.',
                      style: TextStyle(color: Colors.green[700], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}