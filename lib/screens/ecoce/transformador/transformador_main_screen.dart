import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import 'transformador_inicio.dart';
import 'transformador_produccion_screen.dart';
import 'widgets/transformador_bottom_navigation.dart';

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
  late PageController _pageController;
  late int _currentIndex;
  
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(
      initialPage: _currentIndex,
    );
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
  
  void _onBottomNavTapped(int index) {
    HapticFeedback.lightImpact();
    
    if (index == _currentIndex) return;
    
    if (index < 2) {
      // Animar a la página correspondiente
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    } else {
      // Para Ayuda y Perfil, mostrar mensaje temporal
      String message = index == 2 
          ? 'Pantalla de Ayuda en desarrollo' 
          : 'Pantalla de Perfil en desarrollo';
          
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: BioWayColors.info,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
  
  void _onFabPressed() {
    HapticFeedback.lightImpact();
    // TODO: Implementar acción del FAB según la pantalla actual
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Función de agregar en desarrollo'),
        backgroundColor: BioWayColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const BouncingScrollPhysics(),
        children: const [
          TransformadorInicioScreen(),
          TransformadorProduccionScreen(),
        ],
      ),
      bottomNavigationBar: TransformadorBottomNavigation(
        selectedIndex: _currentIndex,
        onItemTapped: _onBottomNavTapped,
        onFabPressed: _onFabPressed,
      ),
      floatingActionButton: TransformadorFloatingActionButton(
        onPressed: _onFabPressed,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}