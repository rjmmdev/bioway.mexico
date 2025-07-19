import 'package:flutter/material.dart';

/// Modelo para representar un documento de usuario
/// Usado en las pantallas de administración y aprobación del maestro
class DocumentoUsuario {
  final String nombre;
  final String tipo; // pdf, jpg, png, etc
  final String path;
  final IconData icon;

  DocumentoUsuario({
    required this.nombre,
    required this.tipo,
    required this.path,
    required this.icon,
  });

  /// Crea una instancia desde un Map (útil para Firebase)
  factory DocumentoUsuario.fromMap(Map<String, dynamic> map) {
    return DocumentoUsuario(
      nombre: map['nombre'] ?? '',
      tipo: map['tipo'] ?? 'pdf',
      path: map['path'] ?? '',
      icon: _getIconForType(map['tipo'] ?? 'pdf'),
    );
  }

  /// Convierte la instancia a Map
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'tipo': tipo,
      'path': path,
    };
  }

  /// Obtiene el icono apropiado según el tipo de documento
  static IconData _getIconForType(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'doc':
      case 'docx':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  /// Verifica si el documento es una imagen
  bool get isImage => ['jpg', 'jpeg', 'png', 'gif'].contains(tipo.toLowerCase());

  /// Verifica si el documento es un PDF
  bool get isPDF => tipo.toLowerCase() == 'pdf';
}