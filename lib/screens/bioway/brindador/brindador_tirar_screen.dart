import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';

class BrindadorTirarScreen extends StatefulWidget {
  final Map<String, double> selectedMaterials;
  
  const BrindadorTirarScreen({
    super.key,
    required this.selectedMaterials,
  });

  @override
  State<BrindadorTirarScreen> createState() => _BrindadorTirarScreenState();
}

class _BrindadorTirarScreenState extends State<BrindadorTirarScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isProcessing = false;

  final List<TutorialStep> _tutorialSteps = [
    TutorialStep(
      title: '¡Excelente trabajo!',
      description: 'Has separado tus residuos correctamente. Ahora vamos a registrarlos en el sistema.',
      icon: Icons.check_circle,
      color: BioWayColors.success,
    ),
    TutorialStep(
      title: 'Coloca tus residuos',
      description: 'Deposita tus residuos separados en los contenedores designados o prepáralos para la recolección.',
      icon: Icons.inventory_2,
      color: BioWayColors.primaryGreen,
    ),
    TutorialStep(
      title: 'Espera la recolección',
      description: 'Un recolector certificado pasará a recoger tus residuos según el horario establecido.',
      icon: Icons.local_shipping,
      color: BioWayColors.info,
    ),
    TutorialStep(
      title: 'Gana BioCoins',
      description: 'Recibirás 20 BioCoins como recompensa por tu contribución al medio ambiente.',
      icon: Icons.monetization_on,
      color: BioWayColors.warning,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _tutorialSteps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _processRegistration();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _processRegistration() async {
    setState(() {
      _isProcessing = true;
    });

    // Simular proceso de registro
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      // Mostrar diálogo de éxito
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: BioWayColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 60,
                  color: BioWayColors.success,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '¡Tarea Completada!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Has ganado 20 BioCoins',
                style: TextStyle(
                  fontSize: 18,
                  color: BioWayColors.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tus residuos han sido registrados exitosamente.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Volver al dashboard
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [BioWayColors.primaryGreen, BioWayColors.mediumGreen],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'Continuar',
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BioWayColors.backgroundGrey,
      appBar: AppBar(
        title: const Text('Registro de Residuos'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: BioWayColors.darkGreen,
      ),
      body: Column(
        children: [
          // Indicador de progreso
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: List.generate(
                _tutorialSteps.length,
                (index) => Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                      right: index < _tutorialSteps.length - 1 ? 8 : 0,
                    ),
                    height: 4,
                    decoration: BoxDecoration(
                      color: index <= _currentPage
                          ? BioWayColors.primaryGreen
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Contenido del tutorial
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _tutorialSteps.length,
              itemBuilder: (context, index) {
                final step = _tutorialSteps[index];
                return _buildTutorialPage(step);
              },
            ),
          ),
          
          // Botones de navegación
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                if (_currentPage > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousPage,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: BioWayColors.primaryGreen),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Anterior',
                        style: TextStyle(
                          color: BioWayColors.primaryGreen,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (_currentPage > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _nextPage,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: BioWayColors.primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _currentPage < _tutorialSteps.length - 1
                                ? 'Siguiente'
                                : 'Completar',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialPage(TutorialStep step) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ícono animado
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: step.color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    step.icon,
                    size: 80,
                    color: step.color,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 40),
          
          // Título
          Text(
            step.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          
          // Descripción
          Text(
            step.description,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          // Mostrar materiales seleccionados en la primera página
          if (_currentPage == 0) ...[
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Materiales seleccionados:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: BioWayColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...widget.selectedMaterials.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: BioWayColors.success,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${entry.key}: ${entry.value} kg',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class TutorialStep {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  TutorialStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}