class BioCompetidor {
  final String userId;
  final String nombre;
  final String avatar;
  final int puntos;
  final int posicion;
  final double progreso;
  final int racha;
  final List<String> insignias;

  BioCompetidor({
    required this.userId,
    required this.nombre,
    required this.avatar,
    required this.puntos,
    required this.posicion,
    this.progreso = 0.0,
    this.racha = 0,
    this.insignias = const [],
  });

  factory BioCompetidor.fromMap(Map<String, dynamic> map) {
    return BioCompetidor(
      userId: map['userId'] ?? '',
      nombre: map['nombre'] ?? '',
      avatar: map['avatar'] ?? '',
      puntos: map['puntos'] ?? 0,
      posicion: map['posicion'] ?? 0,
      progreso: (map['progreso'] ?? 0.0).toDouble(),
      racha: map['racha'] ?? 0,
      insignias: List<String>.from(map['insignias'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'nombre': nombre,
      'avatar': avatar,
      'puntos': puntos,
      'posicion': posicion,
      'progreso': progreso,
      'racha': racha,
      'insignias': insignias,
    };
  }
}