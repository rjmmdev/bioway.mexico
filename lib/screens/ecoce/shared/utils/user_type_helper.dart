import 'package:flutter/material.dart';
import '../../../../utils/colors.dart';
import '../../../../models/ecoce/ecoce_profile_model.dart';
import '../widgets/ecoce_bottom_navigation.dart';

/// Helper class for user type related operations
class UserTypeHelper {
  /// Get primary color based on user profile
  static Color getPrimaryColor(EcoceProfileModel? profile) {
    if (profile == null) return BioWayColors.ecoceGreen;
    
    // Para origen, verificar subtipo
    if (profile.ecoceTipoActor == 'O') {
      if (profile.ecoceSubtipo == 'A') {
        return BioWayColors.darkGreen; // Centro de Acopio
      } else if (profile.ecoceSubtipo == 'P') {
        return BioWayColors.ppPurple; // Planta de Separación
      }
      return BioWayColors.ecoceGreen; // Default origen
    }
    
    // Para otros tipos de usuario
    switch (profile.ecoceTipoActor) {
      case 'R':
        return BioWayColors.ecoceGreen; // Reciclador
      case 'V':
        return BioWayColors.petBlue; // Transporte
      case 'T':
        return BioWayColors.ecoceGreen; // Transformador
      case 'L':
        return BioWayColors.otherPurple; // Laboratorio
      case 'M':
        return BioWayColors.warning; // Maestro
      case 'P':
        return const Color(0xFF8B4513); // Repositorio (brown)
      default:
        return BioWayColors.ecoceGreen;
    }
  }

  /// Get navigation items based on user type
  static List<NavigationItem> getNavigationItems(String? tipoActor) {
    if (tipoActor == null) return [];
    
    switch (tipoActor) {
      case 'O':
        return EcoceNavigationConfigs.origenItems;
      case 'R':
        return EcoceNavigationConfigs.recicladorItems;
      case 'V':
        return EcoceNavigationConfigs.transporteItems;
      case 'T':
        return EcoceNavigationConfigs.transformadorItems;
      case 'L':
        return EcoceNavigationConfigs.laboratorioItems;
      case 'P':
        return EcoceNavigationConfigs.plantaSeparacionItems;
      case 'M':
        return EcoceNavigationConfigs.maestroItems;
      default:
        return [];
    }
  }

  /// Get FAB configuration based on user type
  static FabConfig? getFabConfig(String? tipoActor, BuildContext context) {
    if (tipoActor == null) return null;
    
    switch (tipoActor) {
      case 'O':
        return FabConfig(
          icon: Icons.add,
          onPressed: () => Navigator.pushNamed(context, '/origen_crear_lote'),
          tooltip: 'Nuevo Lote',
        );
      case 'R':
        return FabConfig(
          icon: Icons.add,
          onPressed: () => Navigator.pushNamed(context, '/reciclador_escaneo'),
          tooltip: 'Escanear Lote',
        );
      case 'V':
        return null; // Transportista no tiene FAB
      case 'T':
        return FabConfig(
          icon: Icons.add,
          onPressed: () => Navigator.pushNamed(context, '/transformador_recibir_lote'),
          tooltip: 'Recibir Lote',
        );
      case 'L':
        return FabConfig(
          icon: Icons.add,
          onPressed: () => Navigator.pushNamed(context, '/laboratorio_gestion_muestras'),
          tooltip: 'Nueva Muestra',
        );
      case 'M':
        return FabConfig(
          icon: Icons.add,
          onPressed: () => Navigator.pushNamed(context, '/maestro_solicitudes'),
          tooltip: 'Ver Solicitudes',
        );
      default:
        return null;
    }
  }

  /// Get base navigation path for user type
  static String getBasePath(String? tipoActor) {
    if (tipoActor == null) return '';
    
    switch (tipoActor) {
      case 'O':
        return '/origen';
      case 'R':
        return '/reciclador';
      case 'V':
        return '/transporte';
      case 'T':
        return '/transformador';
      case 'L':
        return '/laboratorio';
      case 'P':
        return '/planta_separacion';
      case 'M':
        return '/maestro';
      default:
        return '';
    }
  }

  /// Get icon code string for user type
  static String getIconCodeString(String? tipoActor, String? subtipo) {
    if (tipoActor == null) return 'person';
    
    if (tipoActor == 'O') {
      if (subtipo == 'A') {
        return 'warehouse';
      } else if (subtipo == 'P') {
        return 'sort';
      }
      return 'store';
    }
    
    switch (tipoActor) {
      case 'R':
        return 'recycling';
      case 'V':
        return 'local_shipping';
      case 'T':
        return 'factory';
      case 'L':
        return 'science';
      case 'M':
        return 'admin_panel_settings';
      default:
        return 'person';
    }
  }
  
  /// Get icon data for user type
  static IconData getIconData(String? tipoActor, String? subtipo) {
    if (tipoActor == null) return Icons.business;
    
    if (tipoActor == 'O') {
      if (subtipo == 'A') {
        return Icons.warehouse;
      } else if (subtipo == 'P') {
        return Icons.sort;
      }
      return Icons.store;
    }
    
    switch (tipoActor) {
      case 'R':
        return Icons.recycling;
      case 'V':
        return Icons.local_shipping;
      case 'T':
        return Icons.auto_fix_high;
      case 'L':
        return Icons.science;
      case 'M':
        return Icons.admin_panel_settings;
      default:
        return Icons.business;
    }
  }

  /// Build navigation route based on index and user type
  static String? buildNavigationRoute(String? tipoActor, int index) {
    final basePath = getBasePath(tipoActor);
    if (basePath.isEmpty) return null;
    
    switch (index) {
      case 0:
        // Transportista usa inicio como su pantalla principal
        if (tipoActor == 'V') {
          return '${basePath}_inicio';
        }
        return '${basePath}_inicio';
      case 1:
        // Para maestro es diferente
        if (tipoActor == 'M') {
          return '${basePath}_solicitudes';
        }
        // Transportista tiene entregar en índice 1
        if (tipoActor == 'V') {
          return '${basePath}_entregar';
        }
        // Laboratorio tiene muestras en índice 1
        if (tipoActor == 'L') {
          return '${basePath}_muestras';
        }
        return '${basePath}_lotes';
      case 2:
        // Todos usan la misma pantalla de ayuda
        return '${basePath}_ayuda';
      case 3:
        // Todos usan la misma pantalla de perfil
        return '${basePath}_perfil';
      default:
        return null;
    }
  }

  /// Handle navigation based on index
  static void handleNavigation(BuildContext context, String? tipoActor, int index, int currentIndex) {
    if (index == currentIndex) return;
    
    final route = buildNavigationRoute(tipoActor, index);
    if (route != null) {
      Navigator.pushReplacementNamed(context, route);
    }
  }
}