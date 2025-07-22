import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../utils/colors.dart';
import '../../../utils/bioway_levels.dart';
import '../../../models/bioway/bioway_user.dart';
import '../../../models/bioway/material_reciclable.dart';

class BrindadorPerfilScreen extends StatefulWidget {
  const BrindadorPerfilScreen({super.key});

  @override
  State<BrindadorPerfilScreen> createState() => _BrindadorPerfilScreenState();
}

class _BrindadorPerfilScreenState extends State<BrindadorPerfilScreen> {
  // Datos mock del usuario
  late BioWayUser mockUser;
  
  // Datos mock de materiales reciclados
  final Map<String, double> materialesReciclados = {
    'plastico': 25.5,
    'vidrio': 15.3,
    'papel': 10.0,
    'metal': 8.2,
    'organico': 30.0,
    'electronico': 2.5,
  };

  @override
  void initState() {
    super.initState();
    _initializeMockData();
  }

  void _initializeMockData() {
    mockUser = BioWayUser(
      uid: 'mock_123',
      nombre: 'Juan Pérez',
      email: 'juan@example.com',
      tipoUsuario: 'brindador',
      bioCoins: 1250,
      nivel: 'BioWay', // Guardián Verde based on 183.0 kg CO2
      fechaRegistro: DateTime.now().subtract(const Duration(days: 30)),
      direccion: 'Av. Insurgentes Sur 123',
      numeroExterior: '456',
      codigoPostal: '03810',
      estado: 'Ciudad de México',
      municipio: 'Benito Juárez',
      colonia: 'Del Valle',
      totalResiduosBrindados: 15,
      totalKgReciclados: 91.5, // Suma de todos los materiales
      totalCO2Evitado: 183.0, // Calculado con factores CO2
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BioWayColors.backgroundGrey,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header con información del usuario
            _buildHeader(),
            
            SizedBox(height: MediaQuery.of(context).size.height * 0.025),
            
            // Sección de estadísticas principales
            _buildMainStats(),
            
            SizedBox(height: MediaQuery.of(context).size.height * 0.045),
            
            // Grid de materiales reciclados
            _buildMaterialsSection(),
            
            // Botón de cerrar sesión
            _buildLogoutButton(),
            
            // Botón de eliminar cuenta
            _buildDeleteAccountButton(),
            
            SizedBox(height: MediaQuery.of(context).size.height * 0.025),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: BioWayColors.backgroundGradient,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            top: 15,
            left: 20,
            right: 20,
            bottom: 10,
          ),
          child: Row(
        children: [
          // Foto de perfil sin botón de cámara
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: Container(
                padding: const EdgeInsets.all(10),
                child: SvgPicture.asset(
                  'assets/logos/bioway_logo.svg',
                  colorFilter: ColorFilter.mode(
                    BioWayColors.primaryGreen,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Información del usuario en columna
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre del usuario (aumentado el tamaño)
                Text(
                  mockUser.nombre,
                  style: TextStyle(
                    fontSize: 22,
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
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                
                // Dirección con texto más grande
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: BioWayColors.darkGreen.withOpacity(0.8),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${mockUser.colonia}, ${mockUser.municipio}',
                        style: TextStyle(
                          fontSize: 13,
                          color: BioWayColors.darkGreen.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Nivel y BioCoins con texto más grande
                Row(
                  children: [
                    // BioCoins con texto más grande
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.monetization_on,
                            color: BioWayColors.darkGreen,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${mockUser.bioCoins}',
                            style: TextStyle(
                              color: BioWayColors.darkGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Nivel con texto más grande
                    GestureDetector(
                      onTap: _showLevelInfo,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: BioWayLevels.getLevelColor(mockUser.nivel),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              BioWayLevels.getDisplayName(mockUser.nivel),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.info_outline,
                              color: Colors.white,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainStats() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la sección mejorado
          Container(
            margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.015),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        BioWayColors.primaryGreen,
                        BioWayColors.lightGreen,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tu Impacto Ambiental',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: BioWayColors.textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Resumen de tu contribución',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Tarjeta ultra compacta de estadísticas
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Total Reciclado
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.recycling,
                        color: BioWayColors.primaryGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mockUser.totalKgReciclados.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: BioWayColors.darkGreen,
                                height: 1,
                              ),
                            ),
                            Text(
                              'kg reciclados',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Separador
                Container(
                  width: 1,
                  height: 35,
                  color: Colors.grey.shade200,
                ),
                // CO2 Ahorrado
                Expanded(
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Icon(
                        Icons.eco,
                        color: BioWayColors.success,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mockUser.totalCO2Evitado.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: BioWayColors.darkGreen,
                                height: 1,
                              ),
                            ),
                            Text(
                              'kg CO₂ evitado',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildMaterialsSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la sección mejorado
          Container(
            margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.001),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        BioWayColors.primaryGreen,
                        BioWayColors.lightGreen,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Desglose por Material',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: BioWayColors.textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Tu contribución detallada por tipo',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Grid de materiales mejorado y responsive
          LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final crossAxisCount = screenWidth > 600 ? 3 : 2;
              final childAspectRatio = screenWidth > 600 ? 1.2 : 1.1;
              
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: childAspectRatio,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: materialesReciclados.length,
                itemBuilder: (context, index) {
                  final entry = materialesReciclados.entries.elementAt(index);
                  final material = MaterialReciclable.findById(entry.key);
                  return _buildModernMaterialCard(
                    materialName: material?.nombre ?? entry.key,
                    cantidad: entry.value,
                    color: material?.color ?? Colors.grey,
                    icon: _getIconForMaterial(entry.key),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModernMaterialCard({
    required String materialName,
    required double cantidad,
    required Color color,
    required IconData icon,
  }) {
    // Calcular el total de kg para el porcentaje
    final totalKg = materialesReciclados.values.reduce((a, b) => a + b);
    final percentage = (cantidad / totalKg * 100).toStringAsFixed(1);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decoración con ícono grande
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(
              icon,
              size: 60,
              color: color.withOpacity(0.08),
            ),
          ),
          // Contenido
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Ícono y nombre del material
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        materialName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: BioWayColors.textDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Cantidad con mejor formato
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        cantidad.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'kg',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: color.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                // Porcentaje del total
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$percentage%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                          Text(
                            'del total',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      LinearProgressIndicator(
                        value: cantidad / totalKg,
                        backgroundColor: color.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _handleLogout,
          style: ElevatedButton.styleFrom(
            backgroundColor: BioWayColors.darkGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          icon: const Icon(Icons.logout, size: 20),
          label: const Text(
            'Cerrar Sesión',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteAccountButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _showDeleteAccountDialog,
          style: OutlinedButton.styleFrom(
            foregroundColor: BioWayColors.error,
            side: BorderSide(color: BioWayColors.error),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.delete_outline, size: 20),
          label: const Text(
            'Eliminar Cuenta',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // Métodos auxiliares


  IconData _getIconForMaterial(String materialId) {
    switch (materialId) {
      case 'plastico':
        return Icons.local_drink;
      case 'vidrio':
        return Icons.wine_bar;
      case 'papel':
        return Icons.description;
      case 'metal':
        return Icons.recycling;
      case 'organico':
        return Icons.compost;
      case 'electronico':
        return Icons.devices;
      default:
        return Icons.recycling;
    }
  }

  void _showLevelInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Título con tu impacto actual
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Niveles BioWay',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    BioWayLevels.getImpactInfo(mockUser.totalCO2Evitado),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Lista de niveles
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: BioWayLevels.levels.length,
                itemBuilder: (context, index) {
                  final level = BioWayLevels.levels[index];
                  return _buildLevelItemCO2(level);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelItemCO2(LevelInfo level) {
    // Determinar si es el nivel actual basado en CO2
    final currentLevelName = BioWayLevels.getLevelByCO2(mockUser.totalCO2Evitado);
    final isCurrentLevel = currentLevelName == level.name;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentLevel ? level.color.withOpacity(0.1) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentLevel ? level.color : Colors.grey.shade200,
          width: isCurrentLevel ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      level.color,
                      level.color.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  BioWayLevels.getLevelIcon(level.name),
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isCurrentLevel ? level.color : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      level.maxCO2 != null 
                          ? '${level.minCO2} - ${level.maxCO2} kg CO₂'
                          : '${level.minCO2}+ kg CO₂',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCurrentLevel)
                Icon(
                  Icons.check_circle,
                  color: level.color,
                  size: 28,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCurrentLevel 
                  ? level.color.withOpacity(0.08)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.eco,
                  size: 20,
                  color: isCurrentLevel ? level.color : Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    level.impactDescription,
                    style: TextStyle(
                      fontSize: 13,
                      color: isCurrentLevel ? level.color : Colors.grey.shade600,
                      fontWeight: isCurrentLevel ? FontWeight.w500 : FontWeight.normal,
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

  void _showDeleteAccountDialog() {
    final TextEditingController confirmController = TextEditingController();
    bool isButtonEnabled = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: BioWayColors.error,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text('Eliminar Cuenta'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Esta acción es permanente y no se puede deshacer. Se eliminarán todos tus datos.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Escribe "ELIMINAR" para confirmar:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmController,
                    onChanged: (value) {
                      setState(() {
                        isButtonEnabled = value == 'ELIMINAR';
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'ELIMINAR',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: BioWayColors.error,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isButtonEnabled
                      ? () {
                          Navigator.of(dialogContext).pop();
                          _deleteAccount();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BioWayColors.error,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Eliminar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteAccount() {
    // TODO: Implementar eliminación real con Firebase
    _showSnackBar('Cuenta eliminada exitosamente');
    // Navegar al login
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  void _handleLogout() {
    // TODO: Implementar logout real con Firebase
    _showSnackBar('Sesión cerrada');
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}