import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../utils/colors.dart';

/// Modelo para los datos del formulario común
class CommonFormData {
  // Datos básicos
  String tipoActor;
  String nombre = '';
  String rfc = '';
  String nombreContacto = '';
  String telContacto = '';
  String telEmpresa = '';
  String correoContacto = '';

  // Ubicación
  String calle = '';
  String numExt = '';
  String cp = '';
  String refUbi = '';
  String poligonoLoc = '';

  // Operativos
  List<String> listaMateriales = [];
  bool transporte = false;
  String linkRedSocial = '';

  // Documentos
  String? constSitFis;
  String? compDomicilio;
  String? bancoCaratula;
  String? ine;

  // Credenciales
  String username = '';
  String password = '';

  CommonFormData({required this.tipoActor});
}

/// Widget de formulario con campos comunes para todos los proveedores
class CommonFieldsForm extends StatefulWidget {
  final CommonFormData formData;
  final bool showTransportField;
  final Function(CommonFormData) onDataChanged;
  final GlobalKey<FormState> formKey;

  const CommonFieldsForm({
    super.key,
    required this.formData,
    required this.onDataChanged,
    required this.formKey,
    this.showTransportField = true,
  });

  @override
  State<CommonFieldsForm> createState() => _CommonFieldsFormState();
}

class _CommonFieldsFormState extends State<CommonFieldsForm> {
  // Controladores
  late TextEditingController _nombreController;
  late TextEditingController _rfcController;
  late TextEditingController _nombreContactoController;
  late TextEditingController _telContactoController;
  late TextEditingController _telEmpresaController;
  late TextEditingController _correoController;
  late TextEditingController _calleController;
  late TextEditingController _numExtController;
  late TextEditingController _cpController;
  late TextEditingController _refUbiController;
  late TextEditingController _poligonoController;
  late TextEditingController _linkController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  // Estados
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;

  // Lista de materiales disponibles
  final List<String> _availableMaterials = [
    'PET',
    'HDPE',
    'PP',
    'LDPE',
    'PS',
    'PVC',
    'Otros plásticos',
    'Cartón',
    'Papel',
    'Vidrio',
    'Metal',
    'Aluminio',
  ];

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _nombreController = TextEditingController(text: widget.formData.nombre);
    _rfcController = TextEditingController(text: widget.formData.rfc);
    _nombreContactoController = TextEditingController(text: widget.formData.nombreContacto);
    _telContactoController = TextEditingController(text: widget.formData.telContacto);
    _telEmpresaController = TextEditingController(text: widget.formData.telEmpresa);
    _correoController = TextEditingController(text: widget.formData.correoContacto);
    _calleController = TextEditingController(text: widget.formData.calle);
    _numExtController = TextEditingController(text: widget.formData.numExt);
    _cpController = TextEditingController(text: widget.formData.cp);
    _refUbiController = TextEditingController(text: widget.formData.refUbi);
    _poligonoController = TextEditingController(text: widget.formData.poligonoLoc);
    _linkController = TextEditingController(text: widget.formData.linkRedSocial);
    _usernameController = TextEditingController(text: widget.formData.username);
    _passwordController = TextEditingController(text: widget.formData.password);
    _confirmPasswordController = TextEditingController();

    // Listeners para actualizar formData
    _nombreController.addListener(() => _updateFormData());
    _rfcController.addListener(() => _updateFormData());
    _nombreContactoController.addListener(() => _updateFormData());
    _telContactoController.addListener(() => _updateFormData());
    _telEmpresaController.addListener(() => _updateFormData());
    _correoController.addListener(() => _updateFormData());
    _calleController.addListener(() => _updateFormData());
    _numExtController.addListener(() => _updateFormData());
    _cpController.addListener(() => _updateFormData());
    _refUbiController.addListener(() => _updateFormData());
    _poligonoController.addListener(() => _updateFormData());
    _linkController.addListener(() => _updateFormData());
    _usernameController.addListener(() => _updateFormData());
    _passwordController.addListener(() => _updateFormData());
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _rfcController.dispose();
    _nombreContactoController.dispose();
    _telContactoController.dispose();
    _telEmpresaController.dispose();
    _correoController.dispose();
    _calleController.dispose();
    _numExtController.dispose();
    _cpController.dispose();
    _refUbiController.dispose();
    _poligonoController.dispose();
    _linkController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updateFormData() {
    widget.formData.nombre = _nombreController.text;
    widget.formData.rfc = _rfcController.text;
    widget.formData.nombreContacto = _nombreContactoController.text;
    widget.formData.telContacto = _telContactoController.text;
    widget.formData.telEmpresa = _telEmpresaController.text;
    widget.formData.correoContacto = _correoController.text;
    widget.formData.calle = _calleController.text;
    widget.formData.numExt = _numExtController.text;
    widget.formData.cp = _cpController.text;
    widget.formData.refUbi = _refUbiController.text;
    widget.formData.poligonoLoc = _poligonoController.text;
    widget.formData.linkRedSocial = _linkController.text;
    widget.formData.username = _usernameController.text;
    widget.formData.password = _passwordController.text;
    widget.onDataChanged(widget.formData);
  }

  void _searchCP() {
    // Simulación de búsqueda de CP
    if (_cpController.text.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Buscando CP ${_cpController.text}...'),
          backgroundColor: BioWayColors.info,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _uploadDocument(String documentType) {
    // Simulación de upload
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Seleccionar archivo para $documentType'),
        backgroundColor: BioWayColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SECCIÓN 1: DATOS BÁSICOS
          _buildSectionTitle('Datos Básicos del Proveedor', Icons.business),
          const SizedBox(height: 16),

          // Tipo de actor (solo lectura)
          _buildReadOnlyField(
            label: 'Tipo de actor',
            value: widget.formData.tipoActor,
            icon: Icons.category,
          ),
          const SizedBox(height: 16),

          // Nombre del proveedor
          _buildTextField(
            controller: _nombreController,
            label: 'Nombre del proveedor *',
            hint: 'Centro de Acopio La Esperanza SA de CV',
            icon: Icons.business_center,
            maxLength: 50,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Este campo es obligatorio';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // RFC (opcional)
          _buildTextField(
            controller: _rfcController,
            label: 'RFC',
            hint: 'XAXX010101000',
            icon: Icons.credit_card,
            maxLength: 13,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
              TextInputFormatter.withFunction((oldValue, newValue) {
                return newValue.copyWith(text: newValue.text.toUpperCase());
              }),
            ],
            helperText: 'Opcional. Tendrás 30 días para proporcionar esta información.',
          ),
          const SizedBox(height: 16),

          // Nombre de contacto
          _buildTextField(
            controller: _nombreContactoController,
            label: 'Nombre de contacto *',
            hint: 'Nombre completo de la persona responsable',
            icon: Icons.person,
            maxLength: 50,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Este campo es obligatorio';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Teléfonos
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _telContactoController,
                  label: 'Tel. contacto *',
                  hint: '+52 1234567890',
                  icon: Icons.phone,
                  maxLength: 15,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Campo obligatorio';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _telEmpresaController,
                  label: 'Tel. empresa *',
                  hint: '+52 1234567890',
                  icon: Icons.phone_in_talk,
                  maxLength: 15,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Campo obligatorio';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Correo electrónico
          _buildTextField(
            controller: _correoController,
            label: 'Correo electrónico *',
            hint: 'correo@ejemplo.com',
            icon: Icons.email,
            maxLength: 50,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Este campo es obligatorio';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return 'Ingresa un correo válido';
              }
              return null;
            },
          ),

          const SizedBox(height: 32),

          // SECCIÓN 2: INFORMACIÓN DE UBICACIÓN
          _buildSectionTitle('Información de Ubicación', Icons.location_on),
          const SizedBox(height: 16),

          // Calle y número
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildTextField(
                  controller: _calleController,
                  label: 'Nombre de calle *',
                  hint: 'Av. Revolución',
                  icon: Icons.route,
                  maxLength: 50,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Campo obligatorio';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _numExtController,
                  label: 'Núm. ext *',
                  hint: '123',
                  icon: Icons.numbers,
                  maxLength: 10,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Obligatorio';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Código postal con búsqueda
          _buildCPField(),
          const SizedBox(height: 16),

          // Referencias
          _buildTextField(
            controller: _refUbiController,
            label: 'Referencias (ubicación) *',
            hint: 'Frente a la iglesia, entrada lateral',
            icon: Icons.location_searching,
            maxLength: 150,
            maxLines: 2,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Este campo es obligatorio';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Polígono asignado
          _buildTextField(
            controller: _poligonoController,
            label: 'Polígono asignado *',
            hint: 'Zona Norte CDMX',
            icon: Icons.map,
            maxLength: 50,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Este campo es obligatorio';
              }
              return null;
            },
          ),

          const SizedBox(height: 32),

          // SECCIÓN 3: INFORMACIÓN OPERATIVA
          _buildSectionTitle('Información Operativa', Icons.settings),
          const SizedBox(height: 16),

          // Materiales que manejan
          _buildMaterialsSelector(),
          const SizedBox(height: 16),

          // Transporte propio (no se muestra para transportistas)
          if (widget.showTransportField) ...[
            _buildSwitchField(
              label: '¿Cuentas con transporte propio?',
              value: widget.formData.transporte,
              onChanged: (value) {
                setState(() {
                  widget.formData.transporte = value;
                  _updateFormData();
                });
              },
            ),
            const SizedBox(height: 16),
          ],

          // Link de red social
          _buildTextField(
            controller: _linkController,
            label: 'Link de red social o página web',
            hint: 'https://www.ejemplo.com',
            icon: Icons.link,
            maxLength: 150,
            keyboardType: TextInputType.url,
          ),

          const SizedBox(height: 32),

          // SECCIÓN 4: DOCUMENTOS FISCALES
          _buildSectionTitle('Documentos Fiscales (Opcionales)', Icons.folder),
          const SizedBox(height: 16),

          _buildDocumentUploadGrid(),

          const SizedBox(height: 32),

          // SECCIÓN 5: CREDENCIALES DE ACCESO
          _buildSectionTitle('Credenciales de Acceso', Icons.security),
          const SizedBox(height: 16),

          // Username
          _buildTextField(
            controller: _usernameController,
            label: 'Nombre de usuario *',
            hint: 'usuario123',
            icon: Icons.person_outline,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Este campo es obligatorio';
              }
              if (value.length < 4) {
                return 'Mínimo 4 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Password
          _buildTextField(
            controller: _passwordController,
            label: 'Contraseña *',
            hint: '••••••••',
            icon: Icons.lock_outline,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: BioWayColors.ecoceGreen,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Este campo es obligatorio';
              }
              if (value.length < 6) {
                return 'Mínimo 6 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Confirm password
          _buildTextField(
            controller: _confirmPasswordController,
            label: 'Confirmar contraseña *',
            hint: '••••••••',
            icon: Icons.lock_outline,
            obscureText: _obscureConfirmPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                color: BioWayColors.ecoceGreen,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Este campo es obligatorio';
              }
              if (value != _passwordController.text) {
                return 'Las contraseñas no coinciden';
              }
              return null;
            },
          ),

          const SizedBox(height: 24),

          // Términos y condiciones
          _buildTermsCheckbox(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: BioWayColors.ecoceGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: BioWayColors.ecoceGreen, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: BioWayColors.darkGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    int? maxLength,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    String? helperText,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLength: maxLength,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        helperStyle: TextStyle(
          color: BioWayColors.info,
          fontSize: 12,
        ),
        prefixIcon: Icon(icon, color: BioWayColors.ecoceGreen, size: 20),
        suffixIcon: suffixIcon,
        counterText: '',
        filled: true,
        fillColor: Colors.white,
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BioWayColors.error, width: 2),
        ),
        labelStyle: TextStyle(color: BioWayColors.textGrey, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, color: BioWayColors.ecoceGreen, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: BioWayColors.textGrey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: BioWayColors.darkGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCPField() {
    return Row(
      children: [
        Expanded(
          child: _buildTextField(
            controller: _cpController,
            label: 'Código Postal *',
            hint: '12345',
            icon: Icons.location_on,
            maxLength: 5,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Este campo es obligatorio';
              }
              if (value.length != 5) {
                return 'El CP debe tener 5 dígitos';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 12),
        Container(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _searchCP,
            icon: const Icon(Icons.search, size: 18),
            label: const Text('Buscar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: BioWayColors.ecoceGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMaterialsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.category, color: BioWayColors.ecoceGreen, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Listado de materiales que manejan *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: BioWayColors.darkGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableMaterials.map((material) {
            final isSelected = widget.formData.listaMateriales.contains(material);
            return FilterChip(
              label: Text(material),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    widget.formData.listaMateriales.add(material);
                  } else {
                    widget.formData.listaMateriales.remove(material);
                  }
                  _updateFormData();
                });
              },
              selectedColor: BioWayColors.ecoceGreen.withOpacity(0.2),
              checkmarkColor: BioWayColors.ecoceGreen,
              labelStyle: TextStyle(
                color: isSelected ? BioWayColors.ecoceGreen : BioWayColors.textGrey,
                fontSize: 13,
              ),
            );
          }).toList(),
        ),
        if (widget.formData.listaMateriales.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Selecciona al menos un material',
              style: TextStyle(
                color: BioWayColors.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSwitchField({
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.local_shipping, color: BioWayColors.ecoceGreen, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: BioWayColors.darkGreen,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: BioWayColors.ecoceGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentUploadGrid() {
    final documents = [
      {'title': 'Constancia de Situación Fiscal', 'field': 'constSitFis'},
      {'title': 'Comprobante de Domicilio', 'field': 'compDomicilio'},
      {'title': 'Carátula de Banco', 'field': 'bancoCaratula'},
      {'title': 'INE', 'field': 'ine'},
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: documents.map((doc) {
        return _buildDocumentUploadCard(
          title: doc['title']!,
          onTap: () => _uploadDocument(doc['title']!),
        );
      }).toList(),
    );
  }

  Widget _buildDocumentUploadCard({
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.upload_file,
              color: BioWayColors.ecoceGreen,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: BioWayColors.darkGreen,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BioWayColors.info.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: BioWayColors.info.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: _acceptedTerms,
            onChanged: (value) {
              setState(() {
                _acceptedTerms = value ?? false;
              });
            },
            activeColor: BioWayColors.ecoceGreen,
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _acceptedTerms = !_acceptedTerms;
                });
              },
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 13,
                    color: BioWayColors.darkGreen,
                    height: 1.4,
                  ),
                  children: [
                    const TextSpan(text: 'He leído y acepto los '),
                    TextSpan(
                      text: 'términos y condiciones',
                      style: TextStyle(
                        color: BioWayColors.ecoceGreen,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const TextSpan(text: ' del sistema ECOCE.'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool get isFormValid => _acceptedTerms && widget.formData.listaMateriales.isNotEmpty;
}