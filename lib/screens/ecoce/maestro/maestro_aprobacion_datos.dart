import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../../../utils/colors.dart';
import '../shared/utils/dialog_utils.dart';
import 'maestro_aprobacion.dart';

/// Modelo para documentos
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
}

class MaestroAprobacionDatosScreen extends StatefulWidget {
  final UsuarioPendiente usuario;
  final VoidCallback onPerfilAprobado;
  final VoidCallback onPerfilDenegado;

  const MaestroAprobacionDatosScreen({
    super.key,
    required this.usuario,
    required this.onPerfilAprobado,
    required this.onPerfilDenegado,
  });

  @override
  State<MaestroAprobacionDatosScreen> createState() => _MaestroAprobacionDatosScreenState();
}

class _MaestroAprobacionDatosScreenState extends State<MaestroAprobacionDatosScreen> {
  // Datos de prueba organizados por pasos del formulario
  final Map<String, List<Map<String, String>>> _datosFormulario = {
    'Información General': [
      {'label': 'Razón Social', 'value': 'Centro de Acopio La Esperanza SA de CV'},
      {'label': 'RFC', 'value': 'XAXX010101000'},
      {'label': 'Tipo de Proveedor', 'value': 'Acopiador'},
      {'label': 'Fecha de Solicitud', 'value': '15/01/2024'},
    ],
    'Datos de Contacto': [
      {'label': 'Nombre del Responsable', 'value': 'Juan Pérez González'},
      {'label': 'Teléfono Personal', 'value': '+52 555 123 4567'},
      {'label': 'Teléfono Empresa', 'value': '+52 555 987 6543'},
      {'label': 'Correo Electrónico', 'value': 'contacto@laesperanza.mx'},
    ],
    'Dirección': [
      {'label': 'Calle', 'value': 'Av. Insurgentes Sur'},
      {'label': 'Número Exterior', 'value': '1234'},
      {'label': 'Número Interior', 'value': 'Local 5-A'},
      {'label': 'Colonia', 'value': 'Del Valle Centro'},
      {'label': 'Código Postal', 'value': '03100'},
      {'label': 'Ciudad', 'value': 'Ciudad de México'},
      {'label': 'Estado', 'value': 'CDMX'},
    ],
    'Información Operativa': [
      {'label': 'Materiales que Maneja', 'value': 'PET, HDPE, PP, LDPE, PS, PVC'},
      {'label': 'Capacidad de Almacenamiento', 'value': '500 toneladas'},
      {'label': 'Transporte Propio', 'value': 'Sí'},
      {'label': 'Número de Empleados', 'value': '25'},
    ],
  };

  // Documentos de prueba
  final List<DocumentoUsuario> _documentos = [
    DocumentoUsuario(
      nombre: 'Constancia_Situacion_Fiscal.pdf',
      tipo: 'pdf',
      path: 'assets/documents/sample.pdf',
      icon: Icons.picture_as_pdf,
    ),
    DocumentoUsuario(
      nombre: 'Comprobante_Domicilio.jpg',
      tipo: 'jpg',
      path: 'assets/images/sample.jpg',
      icon: Icons.image,
    ),
    DocumentoUsuario(
      nombre: 'INE_Responsable.png',
      tipo: 'png',
      path: 'assets/images/sample.png',
      icon: Icons.badge,
    ),
    DocumentoUsuario(
      nombre: 'Acta_Constitutiva.pdf',
      tipo: 'pdf',
      path: 'assets/documents/sample.pdf',
      icon: Icons.description,
    ),
    DocumentoUsuario(
      nombre: 'Permiso_Operacion.pdf',
      tipo: 'pdf',
      path: 'assets/documents/sample.pdf',
      icon: Icons.verified_user,
    ),
    DocumentoUsuario(
      nombre: 'Fotos_Instalaciones.jpg',
      tipo: 'jpg',
      path: 'assets/images/sample.jpg',
      icon: Icons.photo_library,
    ),
  ];

  void _mostrarDocumento(DocumentoUsuario documento) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.usuario.color,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        documento.icon,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          documento.nombre,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                
                // Contenido
                Expanded(
                  child: Container(
                    color: Colors.grey[100],
                    child: Center(
                      child: documento.tipo == 'pdf'
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.picture_as_pdf,
                                  size: 100,
                                  color: Colors.red[700],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Vista previa PDF',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  documento.nombre,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            )
                          : Container(
                              padding: const EdgeInsets.all(16),
                              child: Image.asset(
                                'assets/images/ecoce_logo.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image,
                                        size: 100,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Vista previa de imagen',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                    ),
                  ),
                ),
                
                // Botón cerrar
                Container(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.usuario.color,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cerrar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _aprobarPerfil() async {
    final confirm = await DialogUtils.showConfirmDialog(
      context: context,
      title: 'Aprobar Perfil',
      message: '¿Está seguro de aprobar el perfil de ${widget.usuario.nombre}?\n\nEsto permitirá al usuario crear sus credenciales de acceso.',
      confirmText: 'Aprobar',
      cancelText: 'Cancelar',
      confirmColor: Colors.green,
    );

    if (confirm) {
      await DialogUtils.showSuccessDialog(
        context: context,
        title: 'Perfil Aprobado',
        message: 'El perfil ha sido aprobado exitosamente. El usuario recibirá una notificación para crear sus credenciales.',
        onPressed: () {
          widget.onPerfilAprobado();
          Navigator.pop(context);
        },
      );
    }
  }

  void _denegarPerfil() async {
    final confirm = await DialogUtils.showConfirmDialog(
      context: context,
      title: 'Denegar Perfil',
      message: '¿Está seguro de denegar el perfil de ${widget.usuario.nombre}?\n\nEsta acción eliminará permanentemente la solicitud.',
      confirmText: 'Denegar',
      cancelText: 'Cancelar',
      confirmColor: Colors.red,
    );

    if (confirm) {
      await DialogUtils.showErrorDialog(
        context: context,
        title: 'Perfil Denegado',
        message: 'El perfil ha sido denegado y la solicitud ha sido eliminada.',
      );
      widget.onPerfilDenegado();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: widget.usuario.color,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Supervisión y Aprobación',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.usuario.folioTemporal,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          children: [
            // Información del usuario
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(screenWidth * 0.04),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: widget.usuario.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.usuario.icon,
                      color: widget.usuario.color,
                      size: 32,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.04),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.usuario.nombre,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: widget.usuario.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: widget.usuario.color.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            widget.usuario.tipoUsuario,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: widget.usuario.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: screenHeight * 0.02),

            // Tarjetas de información
            ..._datosFormulario.entries.map((entry) {
              return Container(
                margin: EdgeInsets.only(bottom: screenHeight * 0.015),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header de la tarjeta
                    Container(
                      padding: EdgeInsets.all(screenWidth * 0.04),
                      decoration: BoxDecoration(
                        color: widget.usuario.color.withOpacity(0.05),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getIconForSection(entry.key),
                            color: widget.usuario.color,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: widget.usuario.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Contenido
                    Padding(
                      padding: EdgeInsets.all(screenWidth * 0.04),
                      child: Column(
                        children: entry.value.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '${item['label']}:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    item['value']!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            // Tarjeta de documentos
            Container(
              margin: EdgeInsets.only(bottom: screenHeight * 0.02),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    decoration: BoxDecoration(
                      color: widget.usuario.color.withOpacity(0.05),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.folder_open,
                          color: widget.usuario.color,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Documentos Adjuntos',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: widget.usuario.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Grid de documentos
                  Padding(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: _documentos.length,
                      itemBuilder: (context, index) {
                        final documento = _documentos[index];
                        return InkWell(
                          onTap: () => _mostrarDocumento(documento),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey[300]!,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  documento.icon,
                                  size: 40,
                                  color: documento.tipo == 'pdf' 
                                      ? Colors.red[700] 
                                      : Colors.blue[700],
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Text(
                                    documento.nombre,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Botones de acción
            SizedBox(height: screenHeight * 0.02),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _aprobarPerfil,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Aprobar Perfil'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.02,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.04),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _denegarPerfil,
                    icon: const Icon(Icons.cancel),
                    label: const Text('Denegar Perfil'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.02,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: screenHeight * 0.04),
          ],
        ),
      ),
    );
  }

  IconData _getIconForSection(String section) {
    switch (section) {
      case 'Información General':
        return Icons.info_outline;
      case 'Datos de Contacto':
        return Icons.contact_phone;
      case 'Dirección':
        return Icons.location_on;
      case 'Información Operativa':
        return Icons.engineering;
      default:
        return Icons.folder;
    }
  }
}