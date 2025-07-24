class MaterialReciclableModel {
  final String id;
  final String nombre;
  final String categoria;
  final String icono;
  final String color;
  final bool disponibleParaTodos;
  final List<String> empresasPermitidas;
  final List<String> usuariosPermitidos;
  final bool activo;

  MaterialReciclableModel({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.icono,
    required this.color,
    required this.disponibleParaTodos,
    required this.empresasPermitidas,
    required this.usuariosPermitidos,
    required this.activo,
  });

  factory MaterialReciclableModel.fromJson(Map<String, dynamic> json) {
    return MaterialReciclableModel(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      categoria: json['categoria'] ?? '',
      icono: json['icono'] ?? '',
      color: json['color'] ?? '',
      disponibleParaTodos: json['disponibleParaTodos'] ?? true,
      empresasPermitidas: List<String>.from(json['empresasPermitidas'] ?? []),
      usuariosPermitidos: List<String>.from(json['usuariosPermitidos'] ?? []),
      activo: json['activo'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'categoria': categoria,
      'icono': icono,
      'color': color,
      'disponibleParaTodos': disponibleParaTodos,
      'empresasPermitidas': empresasPermitidas,
      'usuariosPermitidos': usuariosPermitidos,
      'activo': activo,
    };
  }
}