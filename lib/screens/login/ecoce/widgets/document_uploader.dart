// Archivo: widgets/document_uploader.dart
import 'package:flutter/material.dart';
import '../../../../utils/colors.dart';

class DocumentUploader extends StatelessWidget {
  final Map<String, String?> selectedFiles;
  final Function(String) onFileToggle;

  const DocumentUploader({
    super.key,
    required this.selectedFiles,
    required this.onFileToggle,
  });

  static const List<Map<String, dynamic>> _documents = [
    {
      'key': 'const_sit_fis',
      'title': 'Constancia de Situación Fiscal',
      'icon': Icons.description,
    },
    {
      'key': 'comp_domicilio',
      'title': 'Comprobante de Domicilio',
      'icon': Icons.home_work,
    },
    {
      'key': 'banco_caratula',
      'title': 'Carátula de Estado de Cuenta',
      'icon': Icons.account_balance,
    },
    {
      'key': 'ine',
      'title': 'INE/Identificación Oficial',
      'icon': Icons.badge,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BioWayColors.lightGrey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BioWayColors.lightGrey, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder_open, color: BioWayColors.petBlue, size: 24),
              const SizedBox(width: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Documentos Fiscales',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: BioWayColors.darkGreen,
                    ),
                  ),
                  Text(
                    'Opcional - Puedes subirlos después',
                    style: TextStyle(fontSize: 12, color: BioWayColors.textGrey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Lista de documentos
          ..._documents.map((doc) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DocumentUploadItem(
              title: doc['title'],
              documentKey: doc['key'],
              icon: doc['icon'],
              hasFile: selectedFiles[doc['key']] != null,
              fileName: selectedFiles[doc['key']],
              onTap: () => onFileToggle(doc['key']),
            ),
          )).toList(),
        ],
      ),
    );
  }
}

class DocumentUploadItem extends StatelessWidget {
  final String title;
  final String documentKey;
  final IconData icon;
  final bool hasFile;
  final String? fileName;
  final VoidCallback onTap;

  const DocumentUploadItem({
    super.key,
    required this.title,
    required this.documentKey,
    required this.icon,
    required this.hasFile,
    this.fileName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: hasFile ? BioWayColors.success.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasFile ? BioWayColors.success : BioWayColors.lightGrey,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: hasFile ? BioWayColors.success : BioWayColors.textGrey,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: hasFile ? FontWeight.bold : FontWeight.normal,
                      color: hasFile ? BioWayColors.success : BioWayColors.darkGreen,
                    ),
                  ),
                  Text(
                    hasFile
                        ? fileName ?? '$title.pdf'
                        : 'Toca para seleccionar archivo PDF',
                    style: const TextStyle(
                      fontSize: 12,
                      color: BioWayColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              hasFile ? Icons.check_circle : Icons.upload_file,
              color: hasFile ? BioWayColors.success : BioWayColors.textGrey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}