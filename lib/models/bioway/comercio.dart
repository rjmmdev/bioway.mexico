class Comercio {
  final String id;
  final String nombre;
  final String categoria;
  final String direccion;
  final String estado;
  final String municipio;
  final double latitud;
  final double longitud;
  final String horario;
  final bool activo;
  final List<String> productosIds;
  final DateTime fechaRegistro;

  Comercio({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.direccion,
    required this.estado,
    required this.municipio,
    required this.latitud,
    required this.longitud,
    required this.horario,
    required this.activo,
    required this.productosIds,
    required this.fechaRegistro,
  });

  // Constructor desde Map (Firebase)
  factory Comercio.fromMap(Map<String, dynamic> map, String id) {
    return Comercio(
      id: id,
      nombre: map['nombre'] ?? '',
      categoria: map['categoria'] ?? '',
      direccion: map['direccion'] ?? '',
      estado: map['estado'] ?? '',
      municipio: map['municipio'] ?? '',
      latitud: map['latitud']?.toDouble() ?? 0.0,
      longitud: map['longitud']?.toDouble() ?? 0.0,
      horario: map['horario'] ?? '',
      activo: map['activo'] ?? true,
      productosIds: List<String>.from(map['productosIds'] ?? []),
      fechaRegistro: map['fechaRegistro'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['fechaRegistro'])
          : DateTime.now(),
    );
  }

  // Convertir a Map para Firebase
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'categoria': categoria,
      'direccion': direccion,
      'estado': estado,
      'municipio': municipio,
      'latitud': latitud,
      'longitud': longitud,
      'horario': horario,
      'activo': activo,
      'productosIds': productosIds,
      'fechaRegistro': fechaRegistro.millisecondsSinceEpoch,
    };
  }

  // Datos mock para testing
  static List<Comercio> getMockComercios() {
    return [
      Comercio(
        id: 'com_001',
        nombre: 'Café Verde',
        categoria: 'Cafetería',
        direccion: 'Av. Insurgentes 234',
        estado: 'Ciudad de México',
        municipio: 'Benito Juárez',
        latitud: 19.3834,
        longitud: -99.1755,
        horario: '8:00 - 20:00',
        activo: true,
        productosIds: ['prod_001', 'prod_002', 'prod_003'],
        fechaRegistro: DateTime.now().subtract(const Duration(days: 30)),
      ),
      Comercio(
        id: 'com_002',
        nombre: 'Eco Market',
        categoria: 'Supermercado',
        direccion: 'Calle Puebla 567',
        estado: 'Ciudad de México',
        municipio: 'Roma Norte',
        latitud: 19.3900,
        longitud: -99.1700,
        horario: '7:00 - 22:00',
        activo: true,
        productosIds: ['prod_004', 'prod_005', 'prod_006'],
        fechaRegistro: DateTime.now().subtract(const Duration(days: 45)),
      ),
      Comercio(
        id: 'com_003',
        nombre: 'Bicicletas Sustentables',
        categoria: 'Deportes',
        direccion: 'Av. Álvaro Obregón 890',
        estado: 'Ciudad de México',
        municipio: 'Roma Sur',
        latitud: 19.3950,
        longitud: -99.1650,
        horario: '10:00 - 19:00',
        activo: true,
        productosIds: ['prod_007', 'prod_008'],
        fechaRegistro: DateTime.now().subtract(const Duration(days: 20)),
      ),
      Comercio(
        id: 'com_004',
        nombre: 'Farmacia Natural',
        categoria: 'Salud',
        direccion: 'Miguel Ángel de Quevedo 123',
        estado: 'Ciudad de México',
        municipio: 'Coyoacán',
        latitud: 19.3500,
        longitud: -99.1600,
        horario: '9:00 - 21:00',
        activo: true,
        productosIds: ['prod_009', 'prod_010'],
        fechaRegistro: DateTime.now().subtract(const Duration(days: 60)),
      ),
      Comercio(
        id: 'com_005',
        nombre: 'Restaurante Orgánico',
        categoria: 'Restaurante',
        direccion: 'Mazatlán 456',
        estado: 'Ciudad de México',
        municipio: 'Condesa',
        latitud: 19.4100,
        longitud: -99.1750,
        horario: '13:00 - 23:00',
        activo: true,
        productosIds: ['prod_011', 'prod_012'],
        fechaRegistro: DateTime.now().subtract(const Duration(days: 15)),
      ),
    ];
  }
}