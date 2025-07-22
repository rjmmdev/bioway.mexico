import 'package:flutter/material.dart';

/// Modelo de material reciclable para BioWay
class MaterialReciclable {
  final String id;
  final String nombre;
  final String descripcion;
  final String iconoUrl;
  final Color color;
  final double puntosPerKg;
  final double co2PorKg;
  final List<String> ejemplos;
  final String instrucciones;
  final bool activo;
  
  const MaterialReciclable({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.iconoUrl,
    required this.color,
    required this.puntosPerKg,
    required this.co2PorKg,
    required this.ejemplos,
    required this.instrucciones,
    this.activo = true,
  });
  
  /// Lista predefinida de materiales reciclables
  static List<MaterialReciclable> get materiales => [
    MaterialReciclable(
      id: 'plastico',
      nombre: 'Plástico',
      descripcion: 'Envases y botellas de plástico',
      iconoUrl: 'assets/icons/plastic.svg',
      color: const Color(0xFF4CAF50),
      puntosPerKg: 50,
      co2PorKg: 2.5,
      ejemplos: ['Botellas PET', 'Envases de shampoo', 'Tuppers'],
      instrucciones: 'Lava y seca los envases antes de reciclar',
    ),
    MaterialReciclable(
      id: 'vidrio',
      nombre: 'Vidrio',
      descripcion: 'Botellas y frascos de vidrio',
      iconoUrl: 'assets/icons/glass.svg',
      color: const Color(0xFF2196F3),
      puntosPerKg: 30,
      co2PorKg: 1.8,
      ejemplos: ['Botellas de vino', 'Frascos de mermelada', 'Envases de cerveza'],
      instrucciones: 'Retira tapas y etiquetas. No incluyas vidrio roto',
    ),
    MaterialReciclable(
      id: 'papel',
      nombre: 'Papel y Cartón',
      descripcion: 'Papel, periódicos, cajas de cartón',
      iconoUrl: 'assets/icons/paper.svg',
      color: const Color(0xFF795548),
      puntosPerKg: 20,
      co2PorKg: 1.2,
      ejemplos: ['Periódicos', 'Cajas de cereal', 'Hojas de papel'],
      instrucciones: 'Mantén el papel seco y sin grasa',
    ),
    MaterialReciclable(
      id: 'metal',
      nombre: 'Metal',
      descripcion: 'Latas de aluminio y hojalata',
      iconoUrl: 'assets/icons/metal.svg',
      color: const Color(0xFF9E9E9E),
      puntosPerKg: 60,
      co2PorKg: 3.2,
      ejemplos: ['Latas de refresco', 'Latas de atún', 'Papel aluminio'],
      instrucciones: 'Aplasta las latas para ahorrar espacio',
    ),
    MaterialReciclable(
      id: 'organico',
      nombre: 'Orgánico',
      descripcion: 'Residuos orgánicos compostables',
      iconoUrl: 'assets/icons/organic.svg',
      color: const Color(0xFF8BC34A),
      puntosPerKg: 10,
      co2PorKg: 0.5,
      ejemplos: ['Cáscaras de fruta', 'Restos de comida', 'Hojas secas'],
      instrucciones: 'Separa en bolsa biodegradable',
    ),
    MaterialReciclable(
      id: 'electronico',
      nombre: 'Electrónico',
      descripcion: 'Aparatos electrónicos y baterías',
      iconoUrl: 'assets/icons/electronic.svg',
      color: const Color(0xFF607D8B),
      puntosPerKg: 100,
      co2PorKg: 5.0,
      ejemplos: ['Celulares viejos', 'Baterías', 'Cables'],
      instrucciones: 'No mezcles con otros residuos. Manejo especial',
    ),
  ];
  
  /// Busca un material por su ID
  static MaterialReciclable? findById(String id) {
    try {
      return materiales.firstWhere((material) => material.id == id);
    } catch (e) {
      return null;
    }
  }
  
  /// Convierte a Map para Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'iconoUrl': iconoUrl,
      'color': color.toARGB32(),
      'puntosPerKg': puntosPerKg,
      'co2PorKg': co2PorKg,
      'ejemplos': ejemplos,
      'instrucciones': instrucciones,
      'activo': activo,
    };
  }
  
  /// Crea desde Map de Firebase
  factory MaterialReciclable.fromMap(Map<String, dynamic> map) {
    return MaterialReciclable(
      id: map['id'],
      nombre: map['nombre'],
      descripcion: map['descripcion'],
      iconoUrl: map['iconoUrl'],
      color: Color(map['color']),
      puntosPerKg: (map['puntosPerKg'] ?? 0).toDouble(),
      co2PorKg: (map['co2PorKg'] ?? 0).toDouble(),
      ejemplos: List<String>.from(map['ejemplos'] ?? []),
      instrucciones: map['instrucciones'] ?? '',
      activo: map['activo'] ?? true,
    );
  }
}