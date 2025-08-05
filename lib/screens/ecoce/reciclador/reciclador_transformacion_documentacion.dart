import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../utils/colors.dart';
import '../../../utils/ui_constants.dart';
import '../../../services/transformacion_service.dart';
import '../../../services/firebase/firebase_storage_service.dart';
import '../../../services/firebase/firebase_manager.dart';
import '../../../models/lotes/transformacion_model.dart';
import '../shared/widgets/document_upload_per_requirement_widget.dart';
import '../shared/widgets/dialog_utils.dart';

class RecicladorTransformacionDocumentacion extends StatefulWidget {
  final String transformacionId;
  
  const RecicladorTransformacionDocumentacion({
    super.key,
    required this.transformacionId,
  });
  
  @override
  State<RecicladorTransformacionDocumentacion> createState() => _RecicladorTransformacionDocumentacionState();
}

class _RecicladorTransformacionDocumentacionState extends State<RecicladorTransformacionDocumentacion> {
  final TransformacionService _transformacionService = TransformacionService();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  final FirebaseManager _firebaseManager = FirebaseManager();
  
  // Obtener Firestore de la instancia correcta
  FirebaseFirestore get _firestore {
    final app = _firebaseManager.currentApp;
    if (app != null) {
      return FirebaseFirestore.instanceFor(app: app);
    }
    return FirebaseFirestore.instance;
  }
  
  TransformacionModel? _transformacion;
  bool _isLoading = true;
  bool _hasDocuments = false;
  
  @override
  void initState() {
    super.initState();
    _loadTransformacionData();
  }
  
  Future<void> _loadTransformacionData() async {
    try {
      final transformacion = await _transformacionService.obtenerTransformacion(widget.transformacionId);
      
      if (transformacion != null) {
        // Verificar si ya tiene documentos
        _hasDocuments = transformacion.documentosAsociados.isNotEmpty;
      }
      
      if (mounted) {
        setState(() {
          _transformacion = transformacion;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        DialogUtils.showErrorDialog(
          context,
          title: 'Error',
          message: 'Error al cargar la transformación: $e',
        );
      }
    }
  }

  Widget _buildDocumentUploadContent() {
    if (_hasDocuments) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: UIConstants.iconSizeDialog,
              color: BioWayColors.success,
            ),
            SizedBox(height: UIConstants.spacing16),
            const Text(
              'Documentación ya enviada',
              style: TextStyle(
                fontSize: UIConstants.fontSizeLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: UIConstants.spacing8),
            Text(
              'Los documentos de este megalote ya fueron cargados',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: UIConstants.spacing24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Regresar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: BioWayColors.ecoceGreen,
              ),
            ),
          ],
        ),
      );
    }
    
    // Usar el widget sin su propio AppBar/Scaffold
    return DocumentUploadPerRequirementWidget(
      title: 'Documentación del Megalote',
      subtitle: 'Carga la documentación técnica del proceso',
      lotId: widget.transformacionId, // Usar el ID de la transformación
      requiredDocuments: const {
        'f_tecnica_pellet': 'Ficha Técnica del Pellet',
        'rep_result_reci': 'Reporte de Resultado del Reciclador',
      },
      onDocumentsSubmitted: _onDocumentsSubmitted,
      primaryColor: BioWayColors.ecoceGreen,
      userType: 'reciclador_transformacion',
      showAppBar: false,
    );
  }

  void _onDocumentsSubmitted(Map<String, DocumentInfo> documents) async {
    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // Subir documentos a Firebase Storage
      Map<String, String> documentUrls = {};
      for (var entry in documents.entries) {
        if (entry.value.file != null) {
          final url = await _storageService.uploadFile(
            entry.value.file!,
            'transformaciones/${widget.transformacionId}/documentos',
          );
          if (url != null) {
            documentUrls[entry.key] = url;
          }
        }
      }
      
      // Verificar que tenemos la transformación y el usuario es el dueño
      print('[DocumentacionTransformacion] Actualizando transformación ${widget.transformacionId}');
      
      if (_transformacion == null) {
        throw Exception('No se pudo cargar la información de la transformación');
      }
      
      // Obtener el usuario actual
      final firebaseManager = FirebaseManager();
      final app = firebaseManager.currentApp;
      final firebaseAuth = app != null 
        ? FirebaseAuth.instanceFor(app: app) 
        : FirebaseAuth.instance;
      final currentUser = firebaseAuth.currentUser;
      
      print('[DocumentacionTransformacion] Usuario actual: ${currentUser?.uid}');
      print('[DocumentacionTransformacion] Dueño de la transformación: ${_transformacion!.usuarioId}');
      
      // Verificar que el usuario sea el dueño
      if (currentUser?.uid != _transformacion!.usuarioId) {
        throw Exception('No tienes permisos para actualizar esta transformación');
      }
      
      // Actualizar la transformación con los documentos
      await _firestore.collection('transformaciones').doc(widget.transformacionId).update({
        'documentos_asociados': documentUrls,
        'fecha_documentacion': FieldValue.serverTimestamp(),
        'documentacion_completada': true,
      });
      
      if (!mounted) return;
      
      // Cerrar loading
      Navigator.pop(context);
      
      // Mostrar éxito
      DialogUtils.showSuccessDialog(
        context,
        title: 'Documentación Cargada',
        message: 'Los documentos se han guardado correctamente',
        onAccept: () {
          Navigator.pop(context); // Regresar a la pantalla anterior
        },
      );
      
    } catch (e) {
      if (!mounted) return;
      
      // Cerrar loading si está abierto
      Navigator.pop(context);
      
      DialogUtils.showErrorDialog(
        context,
        title: 'Error',
        message: 'Error al cargar documentación: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: BioWayColors.ecoceGreen,
        title: const Text(
          'Documentación del Megalote',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _transformacion == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: UIConstants.iconSizeXLarge,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: UIConstants.spacing16),
                      const Text(
                        'Transformación no encontrada',
                        style: TextStyle(fontSize: UIConstants.fontSizeBody),
                      ),
                    ],
                  ),
                )
              : _buildDocumentUploadContent(),
    );
  }
}