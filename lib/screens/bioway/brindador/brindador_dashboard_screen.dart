import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../utils/colors.dart';
import '../../../models/bioway/horario.dart';
import '../../../models/bioway/user_state.dart';
import 'brindador_residuos_grid_screen.dart';

class BrindadorDashboardScreen extends StatefulWidget {
  const BrindadorDashboardScreen({super.key});

  @override
  State<BrindadorDashboardScreen> createState() => _BrindadorDashboardScreenState();
}

class _BrindadorDashboardScreenState extends State<BrindadorDashboardScreen> 
    with SingleTickerProviderStateMixin {
  late List<Horario> _horarios;
  late UserState _userState;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  int _bioCoins = 1250;
  int _userStatus = 0;
  int _selectedIndex = 1; // HOY por defecto
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.3, initialPage: _selectedIndex);
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.repeat(reverse: true);
    _initializeMockData();
  }

  void _initializeMockData() {
    _horarios = Horario.getMockHorarios();
    _userState = UserState.getMockUserState();
    _userStatus = 0;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = _getAyerHoyManana(_horarios);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildRecycleNowCard(days[_selectedIndex]),
                    const SizedBox(height: 24),
                    _buildScheduleSection(days),
                    const SizedBox(height: 24),
                    _buildTipsSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      padding: EdgeInsets.fromLTRB(
        screenWidth * 0.04, 
        16, 
        screenWidth * 0.04, 
        0
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Buenos días,",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _userState.nombre,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: BioWayColors.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.monetization_on,
                  color: BioWayColors.primaryGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '$_bioCoins',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: BioWayColors.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecycleNowCard(Horario? horario) {
    final canRecycle = _userState.puedeBrindar && horario != null;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: canRecycle
              ? [BioWayColors.primaryGreen, BioWayColors.primaryGreen.withOpacity(0.8)]
              : [Colors.grey[400]!, Colors.grey[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: canRecycle
                ? BioWayColors.primaryGreen.withOpacity(0.3)
                : Colors.black.withOpacity(0.1),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: canRecycle ? () => _navigateToResiduos(horario) : null,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.06,
              vertical: 32,
            ),
            child: Column(
              children: [
                if (horario != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          'HOY - ${horario.dia}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    horario.matinfo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.schedule,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        horario.horario,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Icon(
                        Icons.scale,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Mín: ${horario.cantidadMinima}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                ],
                AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: canRecycle ? _scaleAnimation.value : 1.0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(35),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.recycling,
                              color: canRecycle
                                  ? BioWayColors.primaryGreen
                                  : Colors.grey,
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              canRecycle
                                  ? 'Reciclar ahora'
                                  : horario == null
                                      ? 'Sin recolección hoy'
                                      : 'No disponible',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: canRecycle
                                    ? BioWayColors.primaryGreen
                                    : Colors.grey,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                if (!canRecycle && horario == null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Revisa el calendario para próximas recolecciones',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildScheduleSection(List<Horario?> days) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Text(
                "Calendario de Reciclaje",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: BioWayColors.textDark,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                "Selecciona un día para ver qué materiales se recogen",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 100,
            child: PageView.builder(
              controller: _pageController,
              itemCount: 3,
              onPageChanged: _onCardSelected,
              itemBuilder: (context, index) {
                return _buildDayCard(days[index], index, _getLabel(index));
              },
            ),
          ),
          if (days[_selectedIndex] != null) ...[
            const SizedBox(height: 20),
            _buildScheduleDetails(days[_selectedIndex]!),
          ],
        ],
      ),
    );
  }

  Widget _buildDayCard(Horario? horario, int index, String label) {
    final isSelected = index == _selectedIndex;
    return GestureDetector(
      onTap: () => _onCardSelected(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: EdgeInsets.symmetric(
          horizontal: isSelected ? 6 : 12,
          vertical: isSelected ? 0 : 8,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    BioWayColors.primaryGreen,
                    BioWayColors.darkGreen,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? BioWayColors.primaryGreen.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isSelected ? 16 : 14,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : BioWayColors.textDark,
                ),
              ),
              const SizedBox(height: 5),
              if (horario != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.2)
                        : BioWayColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    horario.dia.substring(0, 3).toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : BioWayColors.primaryGreen,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleDetails(Horario horario) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: BioWayColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.recycling,
                  color: BioWayColors.primaryGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      horario.matinfo,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_getLabel(_selectedIndex)} - ${horario.dia}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDetailRow(Icons.schedule, 'Horario', horario.horario),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.scale, 'Cantidad mínima', horario.cantidadMinima),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.not_interested, 'No se recibe', horario.qnr),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openMoreInfo,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: BioWayColors.primaryGreen),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(
                Icons.info_outline,
                color: BioWayColors.primaryGreen,
              ),
              label: Text(
                'Más información',
                style: TextStyle(
                  color: BioWayColors.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipsSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.amber[700],
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Tips de Reciclaje',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTipCard(
            icon: Icons.clean_hands,
            title: 'Limpia tus residuos',
            description: 'Asegúrate de que estén limpios y secos',
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildTipCard(
            icon: Icons.compress,
            title: 'Compacta el material',
            description: 'Aplasta botellas y latas para ahorrar espacio',
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildTipCard(
            icon: Icons.category,
            title: 'Separa correctamente',
            description: 'Clasifica por tipo de material',
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToResiduos(Horario horario) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BrindadorResiduosGridScreen(
          selectedCantMin: horario.cantidadMinima,
        ),
      ),
    );
  }

  void _onCardSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index, 
      duration: const Duration(milliseconds: 200), 
      curve: Curves.easeInOut,
    );
  }

  Horario? _findHorarioOrNull(List<Horario> all, int day) {
    for (final h in all) {
      if (h.numDia == day) return h;
    }
    return null;
  }

  List<Horario?> _getAyerHoyManana(List<Horario> all) {
    final now = DateTime.now();
    final hoyNum = now.weekday;
    final ayerNum = (hoyNum == 1) ? 7 : hoyNum - 1;
    final mananaNum = (hoyNum == 7) ? 1 : hoyNum + 1;

    return [
      _findHorarioOrNull(all, ayerNum),
      _findHorarioOrNull(all, hoyNum),
      _findHorarioOrNull(all, mananaNum),
    ];
  }

  String _getLabel(int index) {
    if (index == 0) return "AYER";
    if (index == 1) return "HOY";
    if (index == 2) return "MAÑANA";
    return "";
  }

  Future<void> _openMoreInfo() async {
    final Uri url = Uri.parse("https://bioway.com.mx/biowayapp.html#guia-reciclaje");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se pudo abrir el enlace")),
        );
      }
    }
  }
}