import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../utils/colors.dart';
import 'origen_lote_detalle_screen.dart';

class OrigenCrearLoteScreen extends StatefulWidget {
  const OrigenCrearLoteScreen({super.key});

  @override
  State<OrigenCrearLoteScreen> createState() => _OrigenCrearLoteScreenState();
}

class _OrigenCrearLoteScreenState extends State<OrigenCrearLoteScreen> {
  // Controladores para los campos de texto
  final TextEditingController _nombreContactoController = TextEditingController();
  final TextEditingController _pesoController = TextEditingController();
  final TextEditingController _condicionesController = TextEditingController();

  // Variables para los selectores
  String? _tipoPolimeroSeleccionado;
  String _presentacionSeleccionada = 'Pacas';

  // Lista de tipos de polímeros disponibles
  final List<String> _tiposPolimeros = [
    'PEBD',
    'PP',
    'Multi'
  ];

  // Flag para validación del formulario (no se usa aún pero se puede implementar después)

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nombreContactoController.dispose();
    _pesoController.dispose();
    _condicionesController.dispose();
    super.dispose();
  }

  void _generarLote() {
    // Validar el formulario
    if (_nombreContactoController.text.isEmpty || 
        _tipoPolimeroSeleccionado == null || 
        _pesoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor complete todos los campos obligatorios'),
          backgroundColor: BioWayColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    // Generar un ID de Firebase simulado
    final String firebaseId = 'FID_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    
    // Navegar a la pantalla de detalle con mensaje de éxito
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrigenLoteDetalleScreen(
          firebaseId: firebaseId,
          material: _tipoPolimeroSeleccionado!,
          peso: double.tryParse(_pesoController.text) ?? 0,
          presentacion: _presentacionSeleccionada,
          fuente: _nombreContactoController.text,
          fechaCreacion: DateTime.now(),
          mostrarMensajeExito: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Crear Nuevo Lote',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Banner informativo verde
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: BioWayColors.lightGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: BioWayColors.ecoceGreen.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Registro de Material Entrante',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: BioWayColors.darkGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete la información del material que está ingresando al centro de acopio',
                    style: TextStyle(
                      fontSize: 14,
                      color: BioWayColors.darkGreen.withOpacity(0.8),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // Formulario
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre del Contacto
                  _buildLabel('Nombre del Contacto', true),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nombreContactoController,
                    decoration: InputDecoration(
                      hintText: 'Ej: Programa Escolar Norte',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: BioWayColors.ecoceGreen, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    onTap: () {
                      if (_nombreContactoController.text == 'Ej: Programa Escolar Norte') {
                        _nombreContactoController.clear();
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  // Tipo de Polímero
                  _buildLabel('Tipo de Polímero', true),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _tipoPolimeroSeleccionado,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      hint: const Text('Seleccionar tipo'),
                      icon: const Icon(Icons.keyboard_arrow_down),
                      items: _tiposPolimeros.map((String tipo) {
                        return DropdownMenuItem<String>(
                          value: tipo,
                          child: Text(tipo),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _tipoPolimeroSeleccionado = newValue;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Presentación del Material
                  _buildLabel('Presentación del Material', true),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPresentacionOption(
                          svgPath: 'assets/images/icons/pacas.svg',
                          label: 'Pacas',
                          isSelected: _presentacionSeleccionada == 'Pacas',
                          onTap: () {
                            setState(() {
                              _presentacionSeleccionada = 'Pacas';
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildPresentacionOption(
                          svgPath: 'assets/images/icons/sacos.svg',
                          label: 'Sacos',
                          isSelected: _presentacionSeleccionada == 'Sacos',
                          onTap: () {
                            setState(() {
                              _presentacionSeleccionada = 'Sacos';
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Línea divisora con título
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: Colors.grey.shade300,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'DETALLES DEL MATERIAL',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: Colors.grey.shade300,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Peso
                  _buildLabel('Peso', true),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _pesoController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          decoration: InputDecoration(
                            hintText: '0.00',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: BioWayColors.ecoceGreen, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: const Text(
                          'kg',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Condiciones del Material
                  _buildLabel('Condiciones del Material', false),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _condicionesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Describe el estado del material: limpieza, compactación, contaminación, etc.',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: BioWayColors.ecoceGreen, width: 2),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Botón Generar Lote
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _generarLote,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BioWayColors.ecoceGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Generar Lote y Código QR',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, bool isRequired) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        if (isRequired)
          Text(
            ' *',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: BioWayColors.error,
            ),
          ),
      ],
    );
  }

  Widget _buildPresentacionOption({
    required String svgPath,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? BioWayColors.ecoceGreen.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? BioWayColors.ecoceGreen : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            SvgPicture.asset(
              svgPath,
              width: 40,
              height: 40,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? BioWayColors.ecoceGreen : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}