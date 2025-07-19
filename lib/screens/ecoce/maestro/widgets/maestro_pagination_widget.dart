import 'package:flutter/material.dart';
import '../../../../utils/colors.dart';

/// Widget de paginación reutilizable para las pantallas del maestro
class MaestroPaginationWidget extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final int maxVisiblePages;
  final Color activeColor;
  final Color inactiveColor;

  const MaestroPaginationWidget({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    this.maxVisiblePages = 5,
    this.activeColor = BioWayColors.ecoceGreen,
    this.inactiveColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Botón anterior
          IconButton(
            icon: Icon(
              Icons.chevron_left,
              color: currentPage > 1 ? activeColor : inactiveColor.withValues(alpha: 0.5),
            ),
            onPressed: currentPage > 1
                ? () => onPageChanged(currentPage - 1)
                : null,
          ),
          const SizedBox(width: 8),
          // Botones de página
          ..._buildPaginationButtons(),
          const SizedBox(width: 8),
          // Botón siguiente
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color: currentPage < totalPages ? activeColor : inactiveColor.withValues(alpha: 0.5),
            ),
            onPressed: currentPage < totalPages
                ? () => onPageChanged(currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPaginationButtons() {
    List<Widget> buttons = [];
    
    int startPage = 1;
    int endPage = totalPages;
    
    // Calcular rango de páginas visibles
    if (totalPages > maxVisiblePages) {
      if (currentPage <= 3) {
        endPage = maxVisiblePages;
      } else if (currentPage >= totalPages - 2) {
        startPage = totalPages - maxVisiblePages + 1;
      } else {
        startPage = currentPage - 2;
        endPage = currentPage + 2;
      }
    }
    
    // Agregar primera página y elipsis si es necesario
    if (startPage > 1) {
      buttons.add(_buildPageButton(1));
      if (startPage > 2) {
        buttons.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '...',
              style: TextStyle(color: inactiveColor),
            ),
          ),
        );
      }
    }
    
    // Agregar páginas del rango
    for (int i = startPage; i <= endPage; i++) {
      buttons.add(_buildPageButton(i));
    }
    
    // Agregar elipsis y última página si es necesario
    if (endPage < totalPages) {
      if (endPage < totalPages - 1) {
        buttons.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '...',
              style: TextStyle(color: inactiveColor),
            ),
          ),
        );
      }
      buttons.add(_buildPageButton(totalPages));
    }
    
    return buttons;
  }

  Widget _buildPageButton(int page) {
    final isActive = page == currentPage;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: isActive ? activeColor : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: !isActive ? () => onPageChanged(page) : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(minWidth: 36),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: !isActive
                  ? Border.all(color: inactiveColor.withValues(alpha: 0.5))
                  : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                page.toString(),
                style: TextStyle(
                  color: isActive ? Colors.white : inactiveColor,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}