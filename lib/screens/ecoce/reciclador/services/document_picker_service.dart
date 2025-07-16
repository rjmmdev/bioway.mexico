import 'dart:io';
import 'package:file_picker/file_picker.dart';

/// Servicio para manejo de selección de documentos
/// Proporciona una interfaz unificada para seleccionar archivos
/// independientemente de la plataforma
class DocumentPickerService {
  static final DocumentPickerService _instance = DocumentPickerService._internal();
  
  factory DocumentPickerService() {
    return _instance;
  }
  
  DocumentPickerService._internal();

  /// Selecciona un documento del dispositivo
  /// Retorna el archivo seleccionado o null si se cancela
  Future<DocumentPickerResult?> pickDocument() async {
    try {
      FilePickerResult? result;
      
      // Configuración específica por plataforma
      if (Platform.isAndroid || Platform.isIOS) {
        // En móviles, usar configuración estándar
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'jpg', 'jpeg', 'png'],
          allowMultiple: false,
          allowCompression: true,
        );
      } else {
        // En desktop, usar configuración más amplia
        result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: false,
        );
      }
      
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        
        // Validar extensión
        final validExtensions = ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'jpg', 'jpeg', 'png'];
        final extension = fileName.split('.').last.toLowerCase();
        
        if (!validExtensions.contains(extension)) {
          throw Exception('Tipo de archivo no soportado. Por favor selecciona: PDF, DOC, DOCX, XLS, XLSX, JPG o PNG');
        }
        
        return DocumentPickerResult(
          file: file,
          fileName: fileName,
          fileSize: await _getFileSize(file),
        );
      }
      
      return null;
    } catch (e) {
      // Si hay un error de permisos o plataforma, intentar con configuración básica
      try {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: false,
        );
        
        if (result != null && result.files.single.path != null) {
          final file = File(result.files.single.path!);
          final fileName = result.files.single.name;
          
          return DocumentPickerResult(
            file: file,
            fileName: fileName,
            fileSize: await _getFileSize(file),
          );
        }
      } catch (_) {
        // Si falla completamente, propagar el error original
        rethrow;
      }
      
      return null;
    }
  }

  Future<String> _getFileSize(File file) async {
    final bytes = await file.length();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Resultado de la selección de documento
class DocumentPickerResult {
  final File file;
  final String fileName;
  final String fileSize;

  DocumentPickerResult({
    required this.file,
    required this.fileName,
    required this.fileSize,
  });
}