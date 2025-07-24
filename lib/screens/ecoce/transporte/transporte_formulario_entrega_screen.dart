import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import '../../../utils/colors.dart';
import '../../../services/user_session_service.dart';
import '../../../services/firebase/firebase_manager.dart';
import '../../../services/firebase/auth_service.dart';
import '../../../services/lote_service.dart';
import '../../../services/firebase/firebase_storage_service.dart';
import '../../../services/image_service.dart';
import '../shared/widgets/signature_dialog.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import '../shared/widgets/form_widgets.dart';
import '../shared/widgets/photo_evidence_widget.dart';

class TransporteFormularioEntregaScreen extends StatefulWidget {
  final List<Map<String, dynamic>> lotes;
  final String qrData;
  final String nuevoLoteId;
  
  const TransporteFormularioEntregaScreen({
    super.key,
    required this.lotes,
    required this.qrData,
    required this.nuevoLoteId,
  });

  @override
  State<TransporteFormularioEntregaScreen> createState() => _TransporteFormularioEntregaScreenState();
}

class _TransporteFormularioEntregaScreenState extends State<TransporteFormularioEntregaScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserSessionService _userSession = UserSessionService();
  final FirebaseManager _firebaseManager = FirebaseManager();
  final AuthService _authService = AuthService();
  final LoteService _loteService = LoteService();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  
  // Controladores
  final TextEditingController _idDestinoController = TextEditingController();
  final TextEditingController _pesoEntregadoController = TextEditingController();
  final TextEditingController _comentariosController = TextEditingController();
  
  // Estados
  bool _isLoading = false;
  bool _isSearchingUser = false;
  Map<String, dynamic>? _destinatarioInfo;
  File? _evidenciaFoto;
  List<File> _photoFiles = [];
  List<Offset?> _firmaRecibe = [];
  List<Map<String, dynamic>> _suggestedUsers = [];
  bool _showSuggestions = false;
  
  @override
  void initState() {
    super.initState();
    _initializeForm();
    _idDestinoController.addListener(_onFolioChanged);
  }
  
  void _initializeForm() {
    // Calcular peso total
    double pesoTotal = widget.lotes.fold(0.0, (total, lote) => total + (lote['peso'] as double));
    _pesoEntregadoController.text = pesoTotal.toStringAsFixed(1);
  }
  
  @override
  void dispose() {
    _idDestinoController.removeListener(_onFolioChanged);
    _idDestinoController.dispose();
    _pesoEntregadoController.dispose();
    _comentariosController.dispose();
    super.dispose();
  }
  
  void _onFolioChanged() async {
    final query = _idDestinoController.text.trim().toUpperCase();
    
    // Si el campo está vacío o tiene menos de 2 caracteres, ocultar sugerencias
    if (query.length < 2) {
      setState(() {
        _showSuggestions = false;
        _suggestedUsers = [];
      });
      return;
    }
    
    // Buscar usuarios que coincidan con el patrón
    try {
      final app = _firebaseManager.currentApp;
      if (app == null) return;
      
      final firestore = FirebaseFirestore.instanceFor(app: app);
      
      // Buscar en el índice de perfiles
      final querySnapshot = await firestore
          .collection('ecoce_profiles')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: query)
          .where(FieldPath.documentId, isLessThan: query + '\uf8ff')
          .limit(10)
          .get();
      
      final suggestions = <Map<String, dynamic>>[];
      
      for (final doc in querySnapshot.docs) {
        final profileData = doc.data();
        final profilePath = profileData['path'] as String?;
        
        if (profilePath != null) {
          // Obtener datos completos del usuario
          final userDoc = await firestore.doc(profilePath).get();
          
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            String tipoUsuario = 'Desconocido';
            String tipoLabel = 'Desconocido';
            
            if (profilePath.contains('reciclador')) {
              tipoUsuario = 'R';
              tipoLabel = 'Reciclador';
            } else if (profilePath.contains('laboratorio')) {
              tipoUsuario = 'L';
              tipoLabel = 'Laboratorio';
            } else if (profilePath.contains('transformador')) {
              tipoUsuario = 'T';
              tipoLabel = 'Transformador';
            }
            
            suggestions.add({
              'folio': doc.id,
              'nombre': userData['nombre'] ?? userData['ecoce_nombre'] ?? 'Sin nombre',
              'tipo': tipoUsuario,
              'tipo_label': tipoLabel,
              'direccion': _buildDireccion(userData),
            });
          }
        }
      }
      
      setState(() {
        _suggestedUsers = suggestions;
        _showSuggestions = suggestions.isNotEmpty;
      });
    } catch (e) {
      print('Error buscando usuarios: $e');
    }
  }
  
  void _selectUser(Map<String, dynamic> user) {
    setState(() {
      _idDestinoController.text = user['folio'];
      _destinatarioInfo = user;
      _showSuggestions = false;
      _suggestedUsers = [];
    });
  }
  
  Future<void> _buscarUsuario() async {
    final folio = _idDestinoController.text.trim();
    
    if (folio.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingrese un folio'),
          backgroundColor: BioWayColors.error,
        ),
      );
      return;
    }
    
    setState(() {
      _isSearchingUser = true;
      _destinatarioInfo = null;
    });
    
    try {
      // Obtener Firestore de la instancia correcta
      final app = _firebaseManager.currentApp;
      if (app == null) {
        throw Exception('Firebase no inicializado');
      }
      final firestore = FirebaseFirestore.instanceFor(app: app);
      
      // Buscar en ecoce_profiles
      final profileDoc = await firestore
          .collection('ecoce_profiles')
          .doc(folio)
          .get();
      
      if (!profileDoc.exists) {
        throw Exception('Usuario no encontrado');
      }
      
      final profileData = profileDoc.data()!;
      final profilePath = profileData['path'] as String;
      
      // Obtener datos completos del usuario
      final userDoc = await firestore.doc(profilePath).get();
      
      if (!userDoc.exists) {
        throw Exception('Datos del usuario no encontrados');
      }
      
      // Determinar el tipo de usuario basado en el path
      String tipoUsuario = 'Desconocido';
      if (profilePath.contains('reciclador')) {
        tipoUsuario = 'R';
      } else if (profilePath.contains('laboratorio')) {
        tipoUsuario = 'L';
      } else if (profilePath.contains('transformador')) {
        tipoUsuario = 'T';
      }
      
      setState(() {
        _destinatarioInfo = {
          'folio': folio,
          'nombre': userDoc.data()?['nombre'] ?? userDoc.data()?['ecoce_nombre'] ?? 'Sin nombre',
          'tipo': tipoUsuario,
          'tipo_label': _getTipoLabel(tipoUsuario),
          'direccion': _buildDireccion(userDoc.data() ?? {}),
        };
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al buscar usuario: ${e.toString()}'),
            backgroundColor: BioWayColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isSearchingUser = false;
      });
    }
  }
  
  String _buildDireccion(Map<String, dynamic> data) {
    final parts = [
      data['calle'] ?? data['ecoce_calle'],
      data['num_ext'] ?? data['ecoce_num_ext'],
      data['colonia'] ?? data['ecoce_colonia'],
      data['municipio'] ?? data['ecoce_municipio'],
      data['estado'] ?? data['ecoce_estado'],
      (data['cp'] ?? data['ecoce_cp']) != null ? 'C.P. ${data['cp'] ?? data['ecoce_cp']}' : null,
    ].where((part) => part != null && part.toString().isNotEmpty).toList();
    
    return parts.isEmpty ? 'Sin dirección registrada' : parts.join(', ');
  }
  
  String _getTipoLabel(String tipo) {
    switch (tipo) {
      case 'R':
        return 'Reciclador';
      case 'L':
        return 'Laboratorio';
      case 'T':
        return 'Transformador';
      default:
        return 'Desconocido';
    }
  }
  
  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      
      if (photo != null) {
        final compressedImage = await ImageService.optimizeImageForDatabase(File(photo.path));
        
        setState(() {
          _evidenciaFoto = compressedImage;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al capturar imagen: $e'),
            backgroundColor: BioWayColors.error,
          ),
        );
      }
    }
  }
  
  void _showSignatureDialog() {
    SignatureDialog.show(
      context: context,
      title: 'Firma del Receptor',
      initialSignature: _firmaRecibe,
      onSignatureSaved: (signature) {
        setState(() {
          _firmaRecibe = signature;
        });
      },
      primaryColor: const Color(0xFF1490EE),
    );
  }
  
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_destinatarioInfo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor busque y seleccione un destinatario'),
          backgroundColor: BioWayColors.error,
        ),
      );
      return;
    }
    
    if (_evidenciaFoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor capture la evidencia fotográfica'),
          backgroundColor: BioWayColors.error,
        ),
      );
      return;
    }
    
    if (_firmaRecibe.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor capture la firma del receptor'),
          backgroundColor: BioWayColors.error,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Subir firma a Storage
      String? firmaUrl;
      if (_firmaRecibe.isNotEmpty) {
        final signatureImage = await _captureSignature();
        if (signatureImage != null) {
          firmaUrl = await _storageService.uploadImage(
            signatureImage,
            'lotes/transportista/firmas_entrega',
          );
        }
      }
      
      // Subir fotos a Storage
      List<String> photoUrls = [];
      for (int i = 0; i < _photoFiles.length; i++) {
        final url = await _storageService.uploadImage(
          _photoFiles[i],
          'lotes/transportista/evidencias_entrega',
        );
        if (url != null) {
          photoUrls.add(url);
        }
      }
      
      // Actualizar el lote de transportista con los datos de entrega
      await _loteService.actualizarLoteTransportista(
        widget.nuevoLoteId,
        {
          'ecoce_transportista_direccion_destino': _destinatarioInfo!['direccion'],
          'ecoce_transportista_destinatario': _destinatarioInfo!['folio'],
          'ecoce_transportista_fecha_entrega': Timestamp.fromDate(DateTime.now()),
          'ecoce_transportista_peso_entregado': double.parse(_pesoEntregadoController.text),
          'ecoce_transportista_firma_recibe': firmaUrl,
          'ecoce_transportista_evi_foto_entrega': photoUrls,
          'ecoce_transportista_comentarios_entrega': _comentariosController.text.trim(),
          'estado': 'entregado',
        },
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lote ${widget.nuevoLoteId} entregado exitosamente'),
            backgroundColor: BioWayColors.success,
          ),
        );
        
        // Volver a la pantalla de recoger
        Navigator.pushReplacementNamed(
          context,
          '/transporte_inicio',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al completar entrega: $e'),
          backgroundColor: BioWayColors.error,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _onBottomNavTapped(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/transporte_inicio');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/transporte_entregar');
        break;
      case 2:
        Navigator.pushNamed(context, '/transporte_ayuda');
        break;
      case 3:
        Navigator.pushNamed(context, '/transporte_perfil');
        break;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1490EE),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Formulario de Entrega',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Resumen de lotes
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF90CAF9)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Lotes a entregar:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1565C0),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1490EE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Peso total: ${_pesoEntregadoController.text} kg',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.lotes.map((lote) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF9C4),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFFFD54F)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    lote['id'],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF827717),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '(${lote['peso']} kg)',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF827717),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Identificar Destinatario
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              '🔍',
                              style: TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Identificar Destinatario',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: BioWayColors.darkGreen,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '*',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: BioWayColors.error,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: StandardTextField(
                                controller: _idDestinoController,
                                label: 'Folio del Destinatario',
                                hint: 'Ej: R0000001',
                                icon: Icons.badge,
                                required: true,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                                  TextInputFormatter.withFunction((oldValue, newValue) => 
                                    TextEditingValue(
                                      text: newValue.text.toUpperCase(),
                                      selection: newValue.selection,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1490EE),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF1490EE).withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                key: const Key('btn_buscar_usuario'),
                                onPressed: _isSearchingUser ? null : _buscarUsuario,
                                icon: _isSearchingUser 
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.search, color: Colors.white),
                                padding: const EdgeInsets.all(12),
                                constraints: const BoxConstraints(
                                  minWidth: 48,
                                  minHeight: 48,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        // Mostrar sugerencias de usuarios
                        if (_showSuggestions && _suggestedUsers.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 200),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF1490EE).withValues(alpha: 0.3)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: _suggestedUsers.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final user = _suggestedUsers[index];
                                return InkWell(
                                  onTap: () => _selectUser(user),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: Row(
                                      children: [
                                        // Icono del tipo de usuario
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: _getColorForUserType(user['tipo']).withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              user['tipo'],
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: _getColorForUserType(user['tipo']),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Información del usuario
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    user['folio'],
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                      color: BioWayColors.darkGreen,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: _getColorForUserType(user['tipo']).withValues(alpha: 0.1),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      user['tipo_label'],
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: _getColorForUserType(user['tipo']),
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                user['nombre'],
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: BioWayColors.darkGreen,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.arrow_forward_ios,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                        
                        if (_destinatarioInfo != null) ...[
                          const SizedBox(height: 16),
                          const ValidationMessage(
                            message: 'Usuario encontrado exitosamente',
                            type: MessageType.success,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: BioWayColors.backgroundGrey,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF1490EE).withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoRow('Nombre:', _destinatarioInfo!['nombre']),
                                _buildInfoRow('Tipo:', _destinatarioInfo!['tipo_label']),
                                _buildInfoRow('Dirección:', _destinatarioInfo!['direccion']),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Evidencia Fotográfica
                  PhotoEvidenceFormField(
                    title: 'Evidencia Fotográfica',
                    maxPhotos: 3,
                    minPhotos: 1,
                    isRequired: true,
                    onPhotosChanged: (List<File> photos) {
                      setState(() {
                        _photoFiles = photos;
                        _evidenciaFoto = photos.isNotEmpty ? photos.first : null;
                      });
                    },
                    primaryColor: const Color(0xFF1490EE),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Firma del Receptor
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              '✍️',
                              style: TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Firma del Receptor',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: BioWayColors.darkGreen,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '*',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: BioWayColors.error,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: _firmaRecibe.isEmpty ? _showSignatureDialog : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: _firmaRecibe.isNotEmpty ? 150 : 100,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: _firmaRecibe.isNotEmpty 
                                  ? const Color(0xFF1490EE).withValues(alpha: 0.05)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _firmaRecibe.isNotEmpty 
                                    ? const Color(0xFF1490EE) 
                                    : Colors.grey[300]!,
                                width: _firmaRecibe.isNotEmpty ? 2 : 1,
                              ),
                            ),
                            child: _firmaRecibe.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.draw,
                                          size: 32,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Toca para firmar',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Stack(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        child: Center(
                                          child: AspectRatio(
                                            aspectRatio: 2.0,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Colors.grey[200]!,
                                                  width: 1,
                                                ),
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(7),
                                                child: FittedBox(
                                                  fit: BoxFit.contain,
                                                  child: SizedBox(
                                                    width: 300,
                                                    height: 300,
                                                    child: CustomPaint(
                                                      painter: SignaturePainter(_firmaRecibe),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: 0.1),
                                                    blurRadius: 4,
                                                  ),
                                                ],
                                              ),
                                              child: IconButton(
                                                onPressed: _showSignatureDialog,
                                                icon: const Icon(
                                                  Icons.edit,
                                                  color: Color(0xFF1490EE),
                                                  size: 20,
                                                ),
                                                constraints: const BoxConstraints(
                                                  minWidth: 32,
                                                  minHeight: 32,
                                                ),
                                                padding: EdgeInsets.zero,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: 0.1),
                                                    blurRadius: 4,
                                                  ),
                                                ],
                                              ),
                                              child: IconButton(
                                                onPressed: () {
                                                  setState(() {
                                                    _firmaRecibe = [];
                                                  });
                                                },
                                                icon: const Icon(
                                                  Icons.clear,
                                                  color: Colors.red,
                                                  size: 20,
                                                ),
                                                constraints: const BoxConstraints(
                                                  minWidth: 32,
                                                  minHeight: 32,
                                                ),
                                                padding: EdgeInsets.zero,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Comentarios
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              '💬',
                              style: TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Comentarios',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: BioWayColors.darkGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        StandardTextField(
                          controller: _comentariosController,
                          label: 'Comentarios adicionales',
                          hint: 'Información adicional sobre la entrega',
                          icon: Icons.notes,
                          maxLines: 4,
                          required: false,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      
      // Botón completar fijo
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1490EE),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Completar Entrega',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              key: const Key('btn_completar_entrega'),
            ),
          ),
        ),
      ),
      
      bottomNavigationBar: EcoceBottomNavigation(
        selectedIndex: 1,
        onItemTapped: _onBottomNavTapped,
        primaryColor: const Color(0xFF1490EE),
        items: const [
          NavigationItem(
            icon: Icons.qr_code_scanner_rounded,
            label: 'Recoger',
            testKey: 'transporte_nav_recoger',
          ),
          NavigationItem(
            icon: Icons.local_shipping_rounded,
            label: 'Entregar',
            testKey: 'transporte_nav_entregar',
          ),
          NavigationItem(
            icon: Icons.help_outline_rounded,
            label: 'Ayuda',
            testKey: 'transporte_nav_ayuda',
          ),
          NavigationItem(
            icon: Icons.person_outline_rounded,
            label: 'Perfil',
            testKey: 'transporte_nav_perfil',
          ),
        ],
        fabConfig: null,
      ),
    );
  }
  
  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: BioWayColors.darkGreen,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: BioWayColors.darkGreen,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<File?> _captureSignature() async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, 300, 200));
      
      // Fondo blanco
      canvas.drawRect(
        Rect.fromLTWH(0, 0, 300, 200),
        Paint()..color = Colors.white,
      );

      // Dibujar la firma
      final paint = Paint()
        ..color = Colors.black
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < _firmaRecibe.length - 1; i++) {
        if (_firmaRecibe[i] != null && _firmaRecibe[i + 1] != null) {
          canvas.drawLine(_firmaRecibe[i]!, _firmaRecibe[i + 1]!, paint);
        }
      }

      final picture = recorder.endRecording();
      final img = await picture.toImage(300, 200);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        final buffer = byteData.buffer.asUint8List();
        
        // Guardar temporalmente
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png');
        await file.writeAsBytes(buffer);
        
        return file;
      }
      
      return null;
    } catch (e) {
      print('Error al capturar firma: $e');
      return null;
    }
  }
  
  Color _getColorForUserType(String tipo) {
    switch (tipo) {
      case 'R':
        return const Color(0xFF4CAF50); // Verde para Reciclador
      case 'L':
        return const Color(0xFF2196F3); // Azul para Laboratorio
      case 'T':
        return const Color(0xFF9C27B0); // Púrpura para Transformador
      default:
        return const Color(0xFF757575); // Gris para otros
    }
  }
}