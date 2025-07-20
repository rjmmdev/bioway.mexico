import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../utils/colors.dart';

/// Diálogo de confirmación para eliminar un usuario
/// Requiere que el usuario escriba el folio para confirmar la eliminación
class DeleteUserDialog extends StatefulWidget {
  final String userName;
  final String userFolio;
  final String userId;
  
  const DeleteUserDialog({
    super.key,
    required this.userName,
    required this.userFolio,
    required this.userId,
  });

  @override
  State<DeleteUserDialog> createState() => _DeleteUserDialogState();
}

class _DeleteUserDialogState extends State<DeleteUserDialog> {
  final TextEditingController _folioController = TextEditingController();
  final FocusNode _folioFocusNode = FocusNode();
  bool _isDeleteEnabled = false;
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    _folioController.addListener(_validateFolio);
    // Auto-focus the text field after a brief delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: 300), () {
        if (mounted) {
          _folioFocusNode.requestFocus();
        }
      });
    });
  }

  @override
  void dispose() {
    _folioController.dispose();
    _folioFocusNode.dispose();
    super.dispose();
  }

  void _validateFolio() {
    setState(() {
      _isDeleteEnabled = _folioController.text.trim() == widget.userFolio;
      if (_folioController.text.isNotEmpty && !_isDeleteEnabled) {
        _showError = true;
      } else {
        _showError = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: screenWidth * 0.9,
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: screenHeight - keyboardHeight - 100,
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: keyboardHeight > 0 ? 16 : 0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: BioWayColors.error.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: BioWayColors.error,
                          size: 32,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Eliminar Usuario',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: BioWayColors.darkGreen,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                widget.userName,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: BioWayColors.textGrey,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Advertencia
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: BioWayColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: BioWayColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.delete_forever,
                                  color: BioWayColors.error,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Esta acción no se puede deshacer',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: BioWayColors.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Se eliminarán permanentemente:',
                              style: TextStyle(
                                fontSize: 13,
                                color: BioWayColors.error.withValues(alpha: 0.8),
                              ),
                            ),
                            SizedBox(height: 8),
                            _buildBulletPoint('Datos del perfil y cuenta'),
                            _buildBulletPoint('Todos los documentos subidos'),
                            _buildBulletPoint('Historial completo de actividad'),
                            _buildBulletPoint('Acceso al sistema'),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 24),
                      
                      // Instrucciones
                      Text(
                        'Para confirmar la eliminación, escribe el folio del usuario:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: BioWayColors.darkGreen,
                        ),
                      ),
                      SizedBox(height: 12),
                      
                      // Folio a escribir
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: BioWayColors.lightGrey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: BioWayColors.lightGrey,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.badge,
                              size: 20,
                              color: BioWayColors.textGrey,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.userFolio,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: BioWayColors.darkGreen,
                                  fontFamily: 'monospace',
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.content_copy,
                                size: 18,
                                color: BioWayColors.textGrey,
                              ),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: widget.userFolio));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Folio copiado'),
                                    duration: Duration(seconds: 1),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              tooltip: 'Copiar folio',
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 20),
                      
                      // Campo de texto
                      TextField(
                        controller: _folioController,
                        focusNode: _folioFocusNode,
                        onChanged: (_) => _validateFolio(),
                        textCapitalization: TextCapitalization.characters,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          letterSpacing: 1,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Confirmar folio',
                          hintText: 'Escribe el folio aquí',
                          hintStyle: TextStyle(
                            color: BioWayColors.textGrey.withValues(alpha: 0.5),
                            fontWeight: FontWeight.normal,
                            fontFamily: 'sans-serif',
                            letterSpacing: 0,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: Icon(
                            Icons.edit,
                            color: _showError ? BioWayColors.error : BioWayColors.textGrey,
                          ),
                          suffixIcon: _folioController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    _isDeleteEnabled ? Icons.check_circle : Icons.cancel,
                                    color: _isDeleteEnabled ? BioWayColors.success : BioWayColors.error,
                                  ),
                                  onPressed: () {
                                    _folioController.clear();
                                    _validateFolio();
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _showError ? BioWayColors.error : BioWayColors.lightGrey,
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _showError ? BioWayColors.error : BioWayColors.lightGrey,
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _showError ? BioWayColors.error : BioWayColors.primaryGreen,
                              width: 2,
                            ),
                          ),
                          errorText: _showError ? 'El folio no coincide' : null,
                          errorStyle: TextStyle(
                            color: BioWayColors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Actions
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(
                            color: BioWayColors.textGrey,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isDeleteEnabled ? () => Navigator.of(context).pop(true) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BioWayColors.error,
                          disabledBackgroundColor: BioWayColors.lightGrey.withValues(alpha: 0.5),
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: _isDeleteEnabled ? 2 : 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.delete_forever,
                              size: 18,
                              color: _isDeleteEnabled ? Colors.white : BioWayColors.textGrey,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Eliminar',
                              style: TextStyle(
                                color: _isDeleteEnabled ? Colors.white : BioWayColors.textGrey,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
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
  
  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              color: BioWayColors.error.withValues(alpha: 0.6),
              fontSize: 12,
              height: 1.3,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: BioWayColors.error.withValues(alpha: 0.8),
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}