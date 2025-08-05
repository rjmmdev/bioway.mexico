import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/ecoce/ecoce_profile_model.dart';
import '../../../services/user_session_service.dart';
import '../../../utils/colors.dart';
import '../../../utils/ui_constants.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import '../shared/screens/receptor_recepcion_pasos_screen.dart';
import '../shared/utils/user_type_helper.dart';
import '../shared/utils/dialog_utils.dart';
import 'transformador_inicio_screen.dart';
import 'transformador_produccion_screen.dart';
import '../shared/ecoce_ayuda_screen.dart';
import '../shared/ecoce_perfil_screen.dart';

/// Pantalla principal del transformador que mantiene todas las pantallas en memoria
/// para mejorar el rendimiento de navegación
class TransformadorMainScreen extends StatefulWidget {
  final int initialIndex;
  
  const TransformadorMainScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<TransformadorMainScreen> createState() => _TransformadorMainScreenState();
}

class _TransformadorMainScreenState extends State<TransformadorMainScreen> {
  late int _selectedIndex;
  late PageController _pageController;
  final UserSessionService _sessionService = UserSessionService();
  EcoceProfileModel? _userProfile;
  
  // Mantener referencias a las pantallas para preservar su estado
  late final List<Widget> _screens;
  bool _screensInitialized = false;
  
  // Controlar qué páginas se han inicializado
  final Set<int> _initializedPages = {};

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _selectedIndex);
    _loadUserProfile();
    _initializeScreens();
  }

  void _initializeScreens() {
    _screens = [
      const TransformadorInicioScreen(),
      const TransformadorProduccionScreen(),
      const EcoceAyudaScreen(showBottomNavigation: false),
      const EcocePerfilScreen(showBottomNavigation: false),
    ];
    _screensInitialized = true;
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _sessionService.getCurrentUserProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
        });
      }
    } catch (e) {
      debugPrint('Error cargando perfil: $e');
    }
  }

  void _onBottomNavTapped(int index) {
    if (index == _selectedIndex) return;
    
    HapticFeedback.lightImpact();
    setState(() {
      _selectedIndex = index;
    });
    
    // Pequeño delay para permitir que la animación del bottom navigation se complete
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        _pageController.jumpToPage(index);
      }
    });
  }

  void _onAddPressed() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ReceptorRecepcionPasosScreen(
          userType: 'transformador',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        // Si no estamos en inicio, navegar a inicio
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
          _pageController.jumpToPage(0);
        } else {
          // Si estamos en inicio, preguntar si quiere salir
          final shouldExit = await DialogUtils.showConfirmDialog(
            context: context,
            title: '¿Cerrar sesión?',
            message: '¿Estás seguro de que deseas salir?',
          );
          
          if (shouldExit && context.mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/ecoce_login',
              (route) => false,
            );
          }
        }
      },
      child: Scaffold(
        body: _screensInitialized ? PageView.builder(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(), // Desactivar swipe
          itemCount: _screens.length,
          itemBuilder: (context, index) {
            // Marcar página como inicializada
            _initializedPages.add(index);
            
            // Pre-cargar páginas adyacentes para mejor rendimiento
            if (index > 0 && !_initializedPages.contains(index - 1)) {
              _initializedPages.add(index - 1);
            }
            if (index < _screens.length - 1 && !_initializedPages.contains(index + 1)) {
              _initializedPages.add(index + 1);
            }
            
            return _screens[index];
          },
        ) : Center(
          child: CircularProgressIndicator(
            color: Colors.orange,
          ),
        ),
        bottomNavigationBar: EcoceBottomNavigation(
          selectedIndex: _selectedIndex,
          onItemTapped: _onBottomNavTapped,
          primaryColor: Colors.orange,
          items: EcoceNavigationConfigs.transformadorItems,
          fabConfig: FabConfig(
            icon: Icons.add,
            onPressed: _onAddPressed,
          ),
        ),
        floatingActionButton: EcoceFloatingActionButton(
          onPressed: _onAddPressed,
          icon: Icons.add,
          backgroundColor: Colors.orange,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }
}