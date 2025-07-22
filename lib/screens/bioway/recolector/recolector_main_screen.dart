import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import '../shared/widgets/custom_bottom_navigation_bar.dart';
import 'recolector_dashboard_screen.dart';
import 'recolector_perfil_screen.dart';
import 'recolector_historial_screen.dart';

class RecolectorMainScreen extends StatefulWidget {
  const RecolectorMainScreen({super.key});

  @override
  State<RecolectorMainScreen> createState() => _RecolectorMainScreenState();
}

class _RecolectorMainScreenState extends State<RecolectorMainScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavItemTapped(int index) {
    if (index == _currentIndex) return;
    
    HapticFeedback.lightImpact();
    
    setState(() {
      _currentIndex = index;
    });
    
    // Animación suave entre páginas
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        physics: const NeverScrollableScrollPhysics(), // Deshabilitamos el swipe manual
        children: const [
          RecolectorDashboardScreen(),
          RecolectorPerfilScreen(),
          RecolectorHistorialScreen(),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavItemTapped,
      ),
    );
  }
}