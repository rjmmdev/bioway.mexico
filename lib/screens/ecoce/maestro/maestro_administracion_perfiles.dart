import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import '../shared/widgets/ecoce_bottom_navigation.dart';
import '../shared/utils/navigation_utils.dart';
import 'maestro_aprobacion.dart';
import 'maestro_administracion_datos.dart';

/// Modelo para representar un usuario aprobado
class UsuarioAprobado {
  final String id;
  final String nombre;
  final String tipoUsuario;
  final String codigoTipo;
  final String folioOficial;
  final DateTime fechaAprobacion;
  final IconData icon;
  final Color color;
  final bool activo;

  UsuarioAprobado({
    required this.id,
    required this.nombre,
    required this.tipoUsuario,
    required this.codigoTipo,
    required this.folioOficial,
    required this.fechaAprobacion,
    required this.icon,
    required this.color,
    this.activo = true,
  });
}

class MaestroAdministracionPerfilesScreen extends StatefulWidget {
  const MaestroAdministracionPerfilesScreen({super.key});

  @override
  State<MaestroAdministracionPerfilesScreen> createState() => _MaestroAdministracionPerfilesScreenState();
}

class _MaestroAdministracionPerfilesScreenState extends State<MaestroAdministracionPerfilesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filtrosTipoUsuario = [];
  int _paginaActual = 1;
  final int _itemsPorPagina = 10;
  
  // Datos de prueba de usuarios aprobados
  final List<UsuarioAprobado> _usuariosAprobados = [
    UsuarioAprobado(
      id: '1',
      nombre: 'Acopio Central México SA de CV',
      tipoUsuario: 'Acopiador',
      codigoTipo: 'A',
      folioOficial: 'A-CDMX-2024-001',
      fechaAprobacion: DateTime.now().subtract(const Duration(days: 30)),
      icon: Icons.warehouse,
      color: BioWayColors.darkGreen,
    ),
    UsuarioAprobado(
      id: '2',
      nombre: 'Recicladora Industrial del Pacífico',
      tipoUsuario: 'Reciclador',
      codigoTipo: 'R',
      folioOficial: 'R-JAL-2024-015',
      fechaAprobacion: DateTime.now().subtract(const Duration(days: 25)),
      icon: Icons.recycling,
      color: BioWayColors.recycleOrange,
    ),
    UsuarioAprobado(
      id: '3',
      nombre: 'Logística Verde México',
      tipoUsuario: 'Transportista',
      codigoTipo: 'TR',
      folioOficial: 'TR-NL-2024-008',
      fechaAprobacion: DateTime.now().subtract(const Duration(days: 20)),
      icon: Icons.local_shipping,
      color: BioWayColors.deepBlue,
    ),
    UsuarioAprobado(
      id: '4',
      nombre: 'Lab Quality Certification',
      tipoUsuario: 'Laboratorio',
      codigoTipo: 'L',
      folioOficial: 'L-QRO-2024-003',
      fechaAprobacion: DateTime.now().subtract(const Duration(days: 15)),
      icon: Icons.science,
      color: BioWayColors.otherPurple,
    ),
    UsuarioAprobado(
      id: '5',
      nombre: 'Separación Avanzada del Golfo',
      tipoUsuario: 'Planta de Separación',
      codigoTipo: 'PS',
      folioOficial: 'PS-VER-2024-012',
      fechaAprobacion: DateTime.now().subtract(const Duration(days: 10)),
      icon: Icons.factory,
      color: BioWayColors.ecoceGreen,
    ),
    UsuarioAprobado(
      id: '6',
      nombre: 'Transformadores Ecológicos SA',
      tipoUsuario: 'Transformador',
      codigoTipo: 'T',
      folioOficial: 'T-MEX-2024-007',
      fechaAprobacion: DateTime.now().subtract(const Duration(days: 5)),
      icon: Icons.auto_fix_high,
      color: BioWayColors.petBlue,
    ),
    // Agregar más usuarios de prueba
    ...List.generate(25, (index) => UsuarioAprobado(
      id: '${index + 7}',
      nombre: 'Empresa Certificada ${index + 1}',
      tipoUsuario: ['Acopiador', 'Reciclador', 'Transportista', 'Laboratorio', 'Planta de Separación', 'Transformador'][index % 6],
      codigoTipo: ['A', 'R', 'TR', 'L', 'PS', 'T'][index % 6],
      folioOficial: '${['A', 'R', 'TR', 'L', 'PS', 'T'][index % 6]}-EST-2024-${(index + 20).toString().padLeft(3, '0')}',
      fechaAprobacion: DateTime.now().subtract(Duration(days: 60 + index)),
      icon: [Icons.warehouse, Icons.recycling, Icons.local_shipping, Icons.science, Icons.factory, Icons.auto_fix_high][index % 6],
      color: [BioWayColors.darkGreen, BioWayColors.recycleOrange, BioWayColors.deepBlue, BioWayColors.otherPurple, BioWayColors.ecoceGreen, BioWayColors.petBlue][index % 6],
      activo: index % 5 != 0, // Algunos inactivos para demostrar
    )),
  ];

  List<UsuarioAprobado> get _usuariosFiltrados {
    var filtrados = _usuariosAprobados.where((usuario) {
      // Filtro por búsqueda
      if (_searchController.text.isNotEmpty) {
        final searchLower = _searchController.text.toLowerCase();
        if (!usuario.folioOficial.toLowerCase().contains(searchLower) &&
            !usuario.nombre.toLowerCase().contains(searchLower)) {
          return false;
        }
      }
      
      // Filtro por tipo de usuario
      if (_filtrosTipoUsuario.isNotEmpty) {
        if (!_filtrosTipoUsuario.contains(usuario.tipoUsuario)) {
          return false;
        }
      }
      
      return true;
    }).toList();
    
    return filtrados;
  }

  int get _totalPaginas => (_usuariosFiltrados.length / _itemsPorPagina).ceil();

  List<UsuarioAprobado> get _usuariosPaginados {
    final inicio = (_paginaActual - 1) * _itemsPorPagina;
    final fin = inicio + _itemsPorPagina;
    
    if (inicio >= _usuariosFiltrados.length) {
      return [];
    }
    
    return _usuariosFiltrados.sublist(
      inicio,
      fin > _usuariosFiltrados.length ? _usuariosFiltrados.length : fin,
    );
  }

  void _mostrarFiltroTipoUsuario() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Filtrar por Tipo de Usuario',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCheckboxTile('Acopiador', 'A', Icons.warehouse, BioWayColors.darkGreen, setDialogState),
                    _buildCheckboxTile('Planta de Separación', 'PS', Icons.factory, BioWayColors.ecoceGreen, setDialogState),
                    _buildCheckboxTile('Reciclador', 'R', Icons.recycling, BioWayColors.recycleOrange, setDialogState),
                    _buildCheckboxTile('Transformador', 'T', Icons.auto_fix_high, BioWayColors.petBlue, setDialogState),
                    _buildCheckboxTile('Transportista', 'TR', Icons.local_shipping, BioWayColors.deepBlue, setDialogState),
                    _buildCheckboxTile('Laboratorio', 'L', Icons.science, BioWayColors.otherPurple, setDialogState),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      _filtrosTipoUsuario.clear();
                    });
                  },
                  child: Text(
                    'Limpiar',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _paginaActual = 1;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BioWayColors.ecoceGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Aplicar',
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

  Widget _buildCheckboxTile(String titulo, String codigo, IconData icon, Color color, StateSetter setDialogState) {
    final isSelected = _filtrosTipoUsuario.contains(titulo);
    
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        titulo,
        style: TextStyle(
          color: isSelected ? color : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: Checkbox(
        value: isSelected,
        onChanged: (bool? value) {
          setDialogState(() {
            if (value == true) {
              _filtrosTipoUsuario.add(titulo);
            } else {
              _filtrosTipoUsuario.remove(titulo);
            }
          });
        },
        activeColor: color,
        side: BorderSide(color: color, width: 2),
      ),
      onTap: () {
        setDialogState(() {
          if (isSelected) {
            _filtrosTipoUsuario.remove(titulo);
          } else {
            _filtrosTipoUsuario.add(titulo);
          }
        });
      },
    );
  }

  void _navegarADetalles(UsuarioAprobado usuario) {
    NavigationUtils.navigateWithSlide(
      context,
      MaestroAdministracionDatosScreen(usuario: usuario),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(screenWidth * 0.04),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    BioWayColors.ecoceGreen,
                    BioWayColors.ecoceGreen.withValues(alpha: 0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Usuario Maestro ECOCE',
                    style: TextStyle(
                      fontSize: screenWidth * 0.06,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.005),
                  Text(
                    'Administración de Perfiles',
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),

            // Filtros
            Container(
              padding: EdgeInsets.all(screenWidth * 0.04),
              color: Colors.white,
              child: Column(
                children: [
                  // Buscador
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar por folio oficial o nombre...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: BioWayColors.ecoceGreen, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _paginaActual = 1;
                      });
                    },
                  ),
                  
                  SizedBox(height: screenHeight * 0.015),
                  
                  // Filtro tipo usuario
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _mostrarFiltroTipoUsuario,
                      icon: const Icon(Icons.filter_list),
                      label: Text(
                        _filtrosTipoUsuario.isEmpty
                            ? 'Filtrar por Tipo de Usuario'
                            : 'Tipos: ${_filtrosTipoUsuario.length} seleccionados',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: BioWayColors.ecoceGreen,
                        side: BorderSide(color: BioWayColors.ecoceGreen),
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                          vertical: screenHeight * 0.015,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Lista de usuarios
            Expanded(
              child: _usuariosPaginados.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.verified_user,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No se encontraron usuarios aprobados',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(screenWidth * 0.04),
                      itemCount: _usuariosPaginados.length,
                      itemBuilder: (context, index) {
                        final usuario = _usuariosPaginados[index];
                        return _buildUsuarioCard(usuario, screenWidth, screenHeight);
                      },
                    ),
            ),

            // Paginación
            if (_totalPaginas > 1)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenHeight * 0.02,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Botón anterior
                    IconButton(
                      onPressed: _paginaActual > 1
                          ? () {
                              setState(() {
                                _paginaActual--;
                              });
                            }
                          : null,
                      icon: const Icon(Icons.chevron_left),
                      color: BioWayColors.ecoceGreen,
                    ),
                    
                    // Páginas
                    ..._buildPaginationButtons(),
                    
                    // Botón siguiente
                    IconButton(
                      onPressed: _paginaActual < _totalPaginas
                          ? () {
                              setState(() {
                                _paginaActual++;
                              });
                            }
                          : null,
                      icon: const Icon(Icons.chevron_right),
                      color: BioWayColors.ecoceGreen,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: EcoceBottomNavigation(
        selectedIndex: 1,
        onItemTapped: (index) {
          if (index == 0) {
            NavigationUtils.navigateWithFade(
              context,
              const MaestroAprobacionScreen(),
              replacement: true,
            );
          }
        },
        primaryColor: BioWayColors.ecoceGreen,
        items: const [
          NavigationItem(
            icon: Icons.how_to_reg,
            label: 'Aprobación',
          ),
          NavigationItem(
            icon: Icons.admin_panel_settings,
            label: 'Administración',
          ),
        ],
      ),
    );
  }

  Widget _buildUsuarioCard(UsuarioAprobado usuario, double screenWidth, double screenHeight) {
    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.015),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _navegarADetalles(usuario),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Row(
              children: [
                // Icono
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: usuario.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    usuario.icon,
                    color: usuario.color,
                    size: 28,
                  ),
                ),
                
                SizedBox(width: screenWidth * 0.04),
                
                // Información
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              usuario.nombre,
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!usuario.activo)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'INACTIVO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[700],
                                ),
                              ),
                            ),
                        ],
                      ),
                      
                      SizedBox(height: screenHeight * 0.01),
                      
                      // Tipo de usuario y folio
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          // Tipo de usuario
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.025,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: usuario.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: usuario.color.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              usuario.tipoUsuario,
                              style: TextStyle(
                                fontSize: screenWidth * 0.03,
                                fontWeight: FontWeight.w600,
                                color: usuario.color,
                              ),
                            ),
                          ),
                          
                          // Folio oficial
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.025,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: usuario.color.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: usuario.color.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Text(
                              usuario.folioOficial,
                              style: TextStyle(
                                fontSize: screenWidth * 0.025,
                                fontWeight: FontWeight.w500,
                                color: usuario.color.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: screenHeight * 0.005),
                      
                      // Fecha de aprobación
                      Text(
                        'Aprobado: ${_formatDate(usuario.fechaAprobacion)}',
                        style: TextStyle(
                          fontSize: screenWidth * 0.025,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Botón de documento
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.green,
                        Colors.green[700]!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.description,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPaginationButtons() {
    List<Widget> buttons = [];
    const maxVisiblePages = 5;
    
    int startPage = 1;
    int endPage = _totalPaginas;
    
    if (_totalPaginas > maxVisiblePages) {
      if (_paginaActual <= 3) {
        endPage = maxVisiblePages;
      } else if (_paginaActual >= _totalPaginas - 2) {
        startPage = _totalPaginas - maxVisiblePages + 1;
      } else {
        startPage = _paginaActual - 2;
        endPage = _paginaActual + 2;
      }
    }
    
    if (startPage > 1) {
      buttons.add(_buildPageButton(1));
      if (startPage > 2) {
        buttons.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('...', style: TextStyle(color: Colors.grey[600])),
          ),
        );
      }
    }
    
    for (int i = startPage; i <= endPage; i++) {
      buttons.add(_buildPageButton(i));
    }
    
    if (endPage < _totalPaginas) {
      if (endPage < _totalPaginas - 1) {
        buttons.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('...', style: TextStyle(color: Colors.grey[600])),
          ),
        );
      }
      buttons.add(_buildPageButton(_totalPaginas));
    }
    
    return buttons;
  }

  Widget _buildPageButton(int page) {
    final isSelected = page == _paginaActual;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: TextButton(
        onPressed: () {
          setState(() {
            _paginaActual = page;
          });
        },
        style: TextButton.styleFrom(
          backgroundColor: isSelected ? BioWayColors.ecoceGreen : Colors.transparent,
          foregroundColor: isSelected ? Colors.white : BioWayColors.ecoceGreen,
          minimumSize: const Size(40, 40),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          page.toString(),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}