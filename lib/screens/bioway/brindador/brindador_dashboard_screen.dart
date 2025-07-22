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

class _BrindadorDashboardScreenState extends State<BrindadorDashboardScreen> {
  // Datos hardcoded para testing
  late List<Horario> _horarios;
  late UserState _userState;
  
  // Mock de datos del usuario
  int _bioCoins = 1250; // BioCoins del usuario
  int _userStatus = 0; // 0 = puede brindar, 1 = ya brindó
  
  int _selectedIndex = 1; // HOY por defecto
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.3, initialPage: _selectedIndex);
    _initializeMockData();
  }

  void _initializeMockData() {
    // Datos hardcoded para testing
    _horarios = Horario.getMockHorarios();
    _userState = UserState.getMockUserState();
    
    // Simular estado del usuario
    // 0 = puede brindar residuo (botón activo)
    // 1 = ya brindó residuo (botón inactivo)
    _userStatus = 0;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Header con diseño mejorado
  Widget _buildHeader() {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: BioWayColors.backgroundGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Espacio adicional después del SafeArea
            SizedBox(height: MediaQuery.of(context).size.height * 0.006),
            // Sección superior con información del usuario
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).size.height * 0.006,
                left: MediaQuery.of(context).size.width * 0.06,
                right: MediaQuery.of(context).size.width * 0.06,
                bottom: MediaQuery.of(context).size.height * 0.03,
              ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Buenos días,",
                          style: TextStyle(
                            fontSize: 16,
                            color: BioWayColors.darkGreen.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                        Text(
                          _userState.nombre,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: BioWayColors.darkGreen,
                            shadows: [
                              Shadow(
                                offset: const Offset(0, 1),
                                blurRadius: 3,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: BioWayColors.darkGreen.withOpacity(0.2),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/logos/bioway_logo.svg',
                          width: 35,
                          height: 35,
                          colorFilter: ColorFilter.mode(
                            BioWayColors.darkGreen,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
            // Decoración curva inferior
            Container(
              height: 30,
              decoration: BoxDecoration(
                color: BioWayColors.backgroundGrey,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Day Card con diseño mejorado
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
              SizedBox(height: MediaQuery.of(context).size.height * 0.005),
              if (horario != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.02, vertical: MediaQuery.of(context).size.height * 0.0025),
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

  /// Panel de detalles con información del horario
  Widget _buildDetailPanel(Horario? horario) {
    if (horario == null) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.06),
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.1),
        child: Column(
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Colors.grey.shade300,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            Text(
              "No hay recolección programada",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.06),
      child: Column(
        children: [
          // Tarjeta principal de material
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.06),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  BioWayColors.primaryGreen.withOpacity(0.1),
                  BioWayColors.lightGreen.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: BioWayColors.primaryGreen.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
                  decoration: BoxDecoration(
                    color: BioWayColors.primaryGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.recycling,
                    size: 48,
                    color: BioWayColors.primaryGreen,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                Text(
                  horario.matinfo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: BioWayColors.textDark,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.04, vertical: MediaQuery.of(context).size.height * 0.0075),
                  decoration: BoxDecoration(
                    color: BioWayColors.primaryGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${_getLabel(_selectedIndex)} - ${horario.dia}",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.025),
          
          // Información detallada
          Container(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
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
              children: [
                _buildModernInfoRow(
                  Icons.schedule,
                  "Horario de recolección",
                  horario.horario,
                  BioWayColors.info,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                _buildModernInfoRow(
                  Icons.scale,
                  "Cantidad mínima",
                  horario.cantidadMinima,
                  BioWayColors.warning,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                _buildModernInfoRow(
                  Icons.not_interested,
                  "No se recibe",
                  horario.qnr,
                  BioWayColors.error,
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.03),
          
          // Botones de acción
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label: "Más info",
                  icon: Icons.info_outline,
                  onTap: _openMoreInfo,
                  isPrimary: false,
                ),
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.03),
              Expanded(
                child: _buildActionButton(
                  label: _userState.puedeBrindar 
                      ? "Reciclar ahora" 
                      : "No disponible",
                  icon: Icons.eco,
                  onTap: _userState.puedeBrindar 
                      ? () => _navigateToResiduos(horario) 
                      : null,
                  isPrimary: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.025),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        SizedBox(width: MediaQuery.of(context).size.width * 0.04),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.0025),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: BioWayColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
    required bool isPrimary,
  }) {
    final isEnabled = onTap != null;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.02),
        decoration: BoxDecoration(
          gradient: isPrimary && isEnabled
              ? LinearGradient(
                  colors: [
                    BioWayColors.primaryGreen,
                    BioWayColors.darkGreen,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: !isPrimary || !isEnabled
              ? isEnabled
                  ? Colors.grey.shade100
                  : Colors.grey.shade200
              : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isPrimary && isEnabled
              ? [
                  BoxShadow(
                    color: BioWayColors.primaryGreen.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isPrimary && isEnabled
                  ? Colors.white
                  : isEnabled
                      ? BioWayColors.primaryGreen
                      : Colors.grey.shade400,
              size: 20,
            ),
            SizedBox(width: MediaQuery.of(context).size.width * 0.02),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isPrimary && isEnabled
                    ? Colors.white
                    : isEnabled
                        ? BioWayColors.textDark
                        : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
  

  Widget _buildGradientButton(String text, IconData icon, VoidCallback? onPressed) {
    final isEnabled = onPressed != null;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isEnabled 
              ? [BioWayColors.primaryGreen, BioWayColors.mediumGreen]
              : [Colors.grey.shade400, Colors.grey.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: BioWayColors.primaryGreen.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.015, horizontal: MediaQuery.of(context).size.width * 0.04),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                Flexible(
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToResiduos(Horario horario) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BrindadorResiduosGridScreen(
          selectedCantMin: horario.cantidadMinima,
        ),
      ),
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
  
  Widget _buildTipsSection() {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.025, left: MediaQuery.of(context).size.width * 0.06, right: MediaQuery.of(context).size.width * 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: BioWayColors.warning,
                size: 24,
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.02),
              Text(
                "Tips de Reciclaje",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: BioWayColors.textDark,
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          _buildTipCard(
            icon: Icons.clean_hands,
            title: "Limpia tus residuos",
            description: "Asegúrate de que estén limpios y secos antes de reciclar",
            color: BioWayColors.info,
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.015),
          _buildTipCard(
            icon: Icons.compress,
            title: "Compacta el material",
            description: "Aplasta botellas y latas para ahorrar espacio",
            color: BioWayColors.success,
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.015),
          _buildTipCard(
            icon: Icons.category,
            title: "Separa correctamente",
            description: "Clasifica por tipo de material para facilitar el reciclaje",
            color: BioWayColors.primaryGreen,
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
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.03),
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
          SizedBox(width: MediaQuery.of(context).size.width * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: BioWayColors.textDark,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final days = _getAyerHoyManana(_horarios);
    
    return Scaffold(
      backgroundColor: BioWayColors.backgroundGrey,
      extendBodyBehindAppBar: true,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Título con estilo moderno
                  Container(
                    margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.006, bottom: MediaQuery.of(context).size.height * 0.019),
                    child: Column(
                      children: [
                        Text(
                          "Calendario de Reciclaje",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: BioWayColors.textDark,
                          ),
                        ),
                        SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                        Text(
                          "Selecciona un día para ver qué materiales se recogen",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Selector de días mejorado
                  Container(
                    height: 100,
                    margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.019),
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: 3,
                      onPageChanged: _onCardSelected,
                      itemBuilder: (context, index) {
                        return _buildDayCard(days[index], index, _getLabel(index));
                      },
                    ),
                  ),
                  
                  // Panel de detalles
                  _buildDetailPanel(days[_selectedIndex]),
                  
                  // Sección de tips
                  _buildTipsSection(),
                  
                  SizedBox(height: MediaQuery.of(context).size.height * 0.025),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}