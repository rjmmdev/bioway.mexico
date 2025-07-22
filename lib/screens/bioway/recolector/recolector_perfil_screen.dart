import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../utils/colors.dart';
import '../../../utils/bioway_levels.dart';
import '../../../models/bioway/bioway_user.dart';

class RecolectorPerfilScreen extends StatefulWidget {
  const RecolectorPerfilScreen({super.key});

  @override
  State<RecolectorPerfilScreen> createState() => _RecolectorPerfilScreenState();
}

class _RecolectorPerfilScreenState extends State<RecolectorPerfilScreen> {
  // Datos mock del usuario
  late BioWayUser mockUser;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  
  // Datos mock de recolecciones por material
  final Map<String, double> materialesRecolectados = {
    'plastico': 45.5,
    'vidrio': 28.3,
    'papel': 18.0,
    'metal': 15.2,
    'organico': 10.0,
    'electronico': 3.5,
  };

  @override
  void initState() {
    super.initState();
    _initializeMockData();
  }

  void _initializeMockData() {
    mockUser = BioWayUser(
      uid: 'recolector_123',
      nombre: 'Carlos Recolector',
      email: 'carlos@recolector.com',
      tipoUsuario: 'recolector',
      bioCoins: 2500,
      nivel: BioWayLevels.getLevelByCO2(250.8),
      fechaRegistro: DateTime.now().subtract(const Duration(days: 60)),
      direccion: 'Calle Principal 789',
      numeroExterior: '789',
      codigoPostal: '03100',
      estado: 'Ciudad de México',
      municipio: 'Benito Juárez',
      colonia: 'Del Valle',
      totalResiduosRecolectados: 45,
      totalKgReciclados: 120.5, // Suma de todos los materiales
      totalCO2Evitado: 250.8,
      vehiculo: 'Camioneta Nissan NP300',
      capacidadKg: 500.0,
      licenciaConducir: 'CDMX123456789',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BioWayColors.backgroundGrey,
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: BioWayColors.darkGreen,
        actions: [
          // Botón de cerrar sesión
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header con información del usuario
            _buildHeader(),
            
            // Sección de estadísticas principales
            _buildMainStats(),
            
            // Sección de información del vehículo
            _buildVehicleSection(),
            
            // Grid de materiales recolectados
            _buildMaterialsSection(),
            
            // Botón de eliminar cuenta
            _buildDeleteAccountButton(),
            
            SizedBox(height: MediaQuery.of(context).size.height * 0.04),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: BioWayColors.backgroundGradient,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Foto de perfil con opción de cambiar
          Stack(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _imageFile != null
                        ? Image.file(
                            _imageFile!,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
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
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: BioWayColors.primaryGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          
          // Nombre del usuario
          Text(
            mockUser.nombre,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.01),
          
          // Dirección
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_on,
                color: Colors.white70,
                size: 16,
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.01),
              Text(
                '${mockUser.colonia}, ${mockUser.municipio}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          
          // Nivel y BioCoins
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // BioCoins
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha:0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.015),
                    Text(
                      '${mockUser.bioCoins}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.04),
              // Nivel con botón de info
              GestureDetector(
                onTap: _showLevelInfo,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: BioWayLevels.getLevelColor(mockUser.nivel),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Text(
                        BioWayLevels.getDisplayName(mockUser.nivel),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(width: MediaQuery.of(context).size.width * 0.015),
                      const Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainStats() {
    return Padding(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estadísticas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.local_shipping,
                  title: 'Recolecciones\nRealizadas',
                  value: '${mockUser.totalResiduosRecolectados}',
                  color: BioWayColors.success,
                ),
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.03),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.eco,
                  title: 'CO2\nEvitado',
                  value: '${mockUser.totalCO2Evitado.toStringAsFixed(2)} kg',
                  color: BioWayColors.primaryGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información del Vehículo',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          Container(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildVehicleInfoRow(
                  icon: Icons.directions_car,
                  label: 'Vehículo',
                  value: mockUser.vehiculo ?? 'No especificado',
                  color: BioWayColors.primaryGreen,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                _buildVehicleInfoRow(
                  icon: Icons.scale,
                  label: 'Capacidad',
                  value: '${mockUser.capacidadKg ?? 0} kg',
                  color: BioWayColors.info,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                _buildVehicleInfoRow(
                  icon: Icons.assignment,
                  label: 'Licencia',
                  value: mockUser.licenciaConducir ?? 'No especificada',
                  color: BioWayColors.warning,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha:0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.0025),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMaterialsSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Materiales Recolectados',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: materialesRecolectados.length,
            itemBuilder: (context, index) {
              final entry = materialesRecolectados.entries.elementAt(index);
              return _buildMaterialCard(
                materialName: entry.key,
                cantidad: entry.value,
                unidad: 'kg',
                color: _getMaterialColor(entry.key),
                icon: _getIconForMaterial(entry.key),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialCard({
    required String materialName,
    required double cantidad,
    required String unidad,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha:0.8),
            color,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha:0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Icono de fondo
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(
              icon,
              size: 60,
              color: Colors.white.withValues(alpha:0.2),
            ),
          ),
          // Contenido
          Padding(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  materialName.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      cantidad.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.01),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        unidad,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
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
    );
  }

  Widget _buildDeleteAccountButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.05),
      child: OutlinedButton.icon(
        onPressed: _showDeleteAccountDialog,
        style: OutlinedButton.styleFrom(
          foregroundColor: BioWayColors.error,
          side: BorderSide(color: BioWayColors.error),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.delete_outline),
        label: const Text('Eliminar Cuenta'),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.03),
            decoration: BoxDecoration(
              color: color.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.015),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.005),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Métodos auxiliares
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      // TODO: Subir imagen a Firebase Storage
      _showSnackBar('Foto de perfil actualizada');
    }
  }


  Color _getMaterialColor(String material) {
    switch (material.toLowerCase()) {
      case 'plastico':
        return const Color(0xFF4CAF50);
      case 'vidrio':
        return const Color(0xFF2196F3);
      case 'papel':
        return const Color(0xFF795548);
      case 'metal':
        return const Color(0xFF9E9E9E);
      case 'organico':
        return const Color(0xFF8BC34A);
      case 'electronico':
        return const Color(0xFF607D8B);
      default:
        return Colors.grey;
    }
  }

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
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
              child: Column(
                children: [
                  const Text(
                    'Niveles BioWay',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.01),
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
                padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
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
        color: isCurrentLevel ? level.color.withValues(alpha:0.1) : Colors.grey.shade50,
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
                      level.color.withValues(alpha:0.8),
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
              SizedBox(width: MediaQuery.of(context).size.width * 0.04),
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
                    SizedBox(height: MediaQuery.of(context).size.height * 0.005),
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
          SizedBox(height: MediaQuery.of(context).size.height * 0.015),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.03),
            decoration: BoxDecoration(
              color: isCurrentLevel 
                  ? level.color.withValues(alpha:0.08)
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
                SizedBox(width: MediaQuery.of(context).size.width * 0.02),
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
                  SizedBox(width: MediaQuery.of(context).size.width * 0.03),
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
                  SizedBox(height: MediaQuery.of(context).size.height * 0.025),
                  const Text(
                    'Escribe "ELIMINAR" para confirmar:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.015),
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