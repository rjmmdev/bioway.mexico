import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../utils/colors.dart';
import '../../../../models/bioway/empresa_model.dart';

class EmpresaFormScreen extends StatefulWidget {
  final EmpresaModel? empresa;

  const EmpresaFormScreen({
    Key? key,
    this.empresa,
  }) : super(key: key);

  @override
  State<EmpresaFormScreen> createState() => _EmpresaFormScreenState();
}

class _EmpresaFormScreenState extends State<EmpresaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _rangoKmController = TextEditingController();
  
  bool _isLoading = false;
  bool _rangoRestringido = false;
  List<String> _materialesSeleccionados = [];
  List<String> _estadosSeleccionados = [];
  List<String> _municipiosSeleccionados = [];
  
  // Listas de opciones
  final List<Map<String, dynamic>> _materialesDisponibles = [
    {'id': 'plastico_pet_1', 'nombre': 'Plástico PET Tipo 1'},
    {'id': 'aceite', 'nombre': 'Aceite Usado'},
    {'id': 'raspa', 'nombre': 'Raspa de Cuero'},
    {'id': 'papel', 'nombre': 'Papel y Cartón'},
    {'id': 'vidrio', 'nombre': 'Vidrio'},
    {'id': 'metal', 'nombre': 'Metal'},
    {'id': 'electronico', 'nombre': 'Residuos Electrónicos'},
  ];
  
  final List<String> _estadosDisponibles = [
    'Aguascalientes', 'Baja California', 'Baja California Sur', 'Campeche',
    'Chiapas', 'Chihuahua', 'Ciudad de México', 'Coahuila', 'Colima',
    'Durango', 'Estado de México', 'Guanajuato', 'Guerrero', 'Hidalgo',
    'Jalisco', 'Michoacán', 'Morelos', 'Nayarit', 'Nuevo León', 'Oaxaca',
    'Puebla', 'Querétaro', 'Quintana Roo', 'San Luis Potosí', 'Sinaloa',
    'Sonora', 'Tabasco', 'Tamaulipas', 'Tlaxcala', 'Veracruz', 'Yucatán',
    'Zacatecas'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.empresa != null) {
      _loadEmpresaData();
    }
  }

  void _loadEmpresaData() {
    final empresa = widget.empresa!;
    _nombreController.text = empresa.nombre;
    _descripcionController.text = empresa.descripcion;
    _materialesSeleccionados = List.from(empresa.materialesRecolectan);
    _estadosSeleccionados = List.from(empresa.estadosDisponibles);
    _municipiosSeleccionados = List.from(empresa.municipiosDisponibles);
    _rangoRestringido = empresa.rangoRestringido;
    if (empresa.rangoMaximoKm != null) {
      _rangoKmController.text = empresa.rangoMaximoKm.toString();
    }
  }

  Future<void> _saveEmpresa() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_materialesSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos un material'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_estadosSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos un estado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final empresaData = {
        'nombre': _nombreController.text.trim(),
        'descripcion': _descripcionController.text.trim(),
        'materialesRecolectan': _materialesSeleccionados,
        'estadosDisponibles': _estadosSeleccionados,
        'municipiosDisponibles': _municipiosSeleccionados,
        'rangoRestringido': _rangoRestringido,
        'rangoMaximoKm': _rangoRestringido 
            ? double.tryParse(_rangoKmController.text) 
            : null,
        'activa': true,
        'fechaCreacion': widget.empresa?.fechaCreacion.toIso8601String() ?? 
            DateTime.now().toIso8601String(),
        'fechaActualizacion': DateTime.now().toIso8601String(),
      };

      if (widget.empresa != null) {
        // Actualizar empresa existente
        await FirebaseFirestore.instance
            .collection('bioway_empresas')
            .doc(widget.empresa!.id)
            .update(empresaData);
      } else {
        // Crear nueva empresa
        await FirebaseFirestore.instance
            .collection('bioway_empresas')
            .add(empresaData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.empresa != null 
                  ? 'Empresa actualizada correctamente'
                  : 'Empresa creada correctamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: BioWayColors.primaryGreen,
        title: Text(
          widget.empresa != null ? 'Editar Empresa' : 'Nueva Empresa',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Información básica
                      _buildSectionTitle('Información Básica'),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de la Empresa',
                          hintText: 'Ej: Sicit',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El nombre es requerido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descripcionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                          hintText: 'Describe brevemente la empresa...',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'La descripción es requerida';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Materiales
                      _buildSectionTitle('Materiales que Recolectan'),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: _materialesDisponibles.map((material) {
                            return CheckboxListTile(
                              title: Text(material['nombre']),
                              value: _materialesSeleccionados
                                  .contains(material['id']),
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    _materialesSeleccionados.add(material['id']);
                                  } else {
                                    _materialesSeleccionados
                                        .remove(material['id']);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Cobertura geográfica
                      _buildSectionTitle('Cobertura Geográfica'),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Estados Disponibles',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _estadosDisponibles.map((estado) {
                                final isSelected = _estadosSeleccionados
                                    .contains(estado);
                                return FilterChip(
                                  label: Text(estado),
                                  selected: isSelected,
                                  onSelected: (bool selected) {
                                    setState(() {
                                      if (selected) {
                                        _estadosSeleccionados.add(estado);
                                      } else {
                                        _estadosSeleccionados.remove(estado);
                                      }
                                    });
                                  },
                                  selectedColor: BioWayColors.primaryGreen
                                      .withOpacity(0.3),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Restricción de rango
                      SwitchListTile(
                        title: const Text('Restringir por rango de distancia'),
                        subtitle: const Text(
                          'Los recolectores solo verán materiales dentro del rango',
                        ),
                        value: _rangoRestringido,
                        onChanged: (bool value) {
                          setState(() {
                            _rangoRestringido = value;
                          });
                        },
                      ),
                      if (_rangoRestringido) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _rangoKmController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Rango máximo (km)',
                            hintText: 'Ej: 50',
                            border: OutlineInputBorder(),
                            suffixText: 'km',
                          ),
                          validator: (value) {
                            if (_rangoRestringido && 
                                (value == null || value.isEmpty)) {
                              return 'El rango es requerido';
                            }
                            if (value != null && value.isNotEmpty) {
                              final rango = double.tryParse(value);
                              if (rango == null || rango <= 0) {
                                return 'Ingresa un valor válido';
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 32),

                      // Botón guardar
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _saveEmpresa,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BioWayColors.primaryGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text(
                            widget.empresa != null ? 'Actualizar' : 'Crear Empresa',
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
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _rangoKmController.dispose();
    super.dispose();
  }
}