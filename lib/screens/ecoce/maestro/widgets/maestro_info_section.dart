import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../utils/colors.dart';

/// Modelo para representar un item de información
class InfoItem {
  final String label;
  final String value;
  final IconData? icon;
  final bool copyable;

  InfoItem({
    required this.label,
    required this.value,
    this.icon,
    this.copyable = false,
  });
}

/// Sección de información reutilizable para las pantallas del maestro
class MaestroInfoSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<InfoItem> items;
  final EdgeInsets? margin;
  final bool expandable;

  const MaestroInfoSection({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
    this.margin,
    this.expandable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: expandable ? _buildExpandable() : _buildStatic(),
    );
  }

  Widget _buildExpandable() {
    return Theme(
      data: ThemeData().copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: _buildHeader(),
        children: [
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: BioWayColors.lightGrey, width: 1),
              ),
            ),
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatic() {
    return Column(
      children: [
        _buildHeader(),
        Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: BioWayColors.lightGrey, width: 1),
            ),
          ),
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (expandable) ...[
            const Spacer(),
            Icon(
              Icons.expand_more,
              color: color,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: items.map((item) => _buildInfoRow(item)).toList(),
      ),
    );
  }

  Widget _buildInfoRow(InfoItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.icon != null) ...[
            Icon(
              item.icon,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.label}:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: BioWayColors.darkGreen,
                    ),
                  ),
                ),
                if (item.copyable) ...[
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => _copyToClipboard(item.value),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.copy,
                        size: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    // En producción, mostrar un SnackBar
  }

  /// Constructor factory para crear una sección de información fiscal
  factory MaestroInfoSection.fiscal({
    required String nombre,
    required String rfc,
    required String? nombreContacto,
    required String? correo,
    required String? telefono,
    EdgeInsets? margin,
  }) {
    return MaestroInfoSection(
      title: 'Información Fiscal',
      icon: Icons.account_balance,
      color: BioWayColors.darkGreen,
      margin: margin,
      items: [
        InfoItem(
          label: 'Nombre',
          value: nombre,
          icon: Icons.business,
        ),
        InfoItem(
          label: 'RFC',
          value: rfc,
          icon: Icons.badge,
          copyable: true,
        ),
        if (nombreContacto != null)
          InfoItem(
            label: 'Contacto',
            value: nombreContacto,
            icon: Icons.person,
          ),
        if (correo != null)
          InfoItem(
            label: 'Correo',
            value: correo,
            icon: Icons.email,
            copyable: true,
          ),
        if (telefono != null)
          InfoItem(
            label: 'Teléfono',
            value: telefono,
            icon: Icons.phone,
            copyable: true,
          ),
      ],
    );
  }

  /// Constructor factory para crear una sección de ubicación
  factory MaestroInfoSection.ubicacion({
    required String direccion,
    required String? colonia,
    required String? municipio,
    required String? estado,
    required String? cp,
    EdgeInsets? margin,
  }) {
    return MaestroInfoSection(
      title: 'Ubicación',
      icon: Icons.location_on,
      color: BioWayColors.petBlue,
      margin: margin,
      items: [
        InfoItem(
          label: 'Dirección',
          value: direccion,
          icon: Icons.home,
        ),
        if (colonia != null)
          InfoItem(
            label: 'Colonia',
            value: colonia,
          ),
        if (municipio != null)
          InfoItem(
            label: 'Municipio',
            value: municipio,
          ),
        if (estado != null)
          InfoItem(
            label: 'Estado',
            value: estado,
          ),
        if (cp != null)
          InfoItem(
            label: 'C.P.',
            value: cp,
            copyable: true,
          ),
      ],
    );
  }
}