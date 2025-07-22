import 'package:flutter/material.dart';

class ProductoDescuento {
  final String id;
  final String comercioId;
  final String nombre;
  final String descripcion;
  final int bioCoinsCosto;
  final double descuentoPorcentaje;
  final bool destacado;
  final IconData icono;
  final String categoria;
  final bool activo;
  final DateTime? fechaExpiracion;

  ProductoDescuento({
    required this.id,
    required this.comercioId,
    required this.nombre,
    required this.descripcion,
    required this.bioCoinsCosto,
    required this.descuentoPorcentaje,
    required this.destacado,
    required this.icono,
    required this.categoria,
    required this.activo,
    this.fechaExpiracion,
  });

  // Constructor desde Map (Firebase)
  factory ProductoDescuento.fromMap(Map<String, dynamic> map, String id) {
    return ProductoDescuento(
      id: id,
      comercioId: map['comercioId'] ?? '',
      nombre: map['nombre'] ?? '',
      descripcion: map['descripcion'] ?? '',
      bioCoinsCosto: map['bioCoinsCosto'] ?? 0,
      descuentoPorcentaje: map['descuentoPorcentaje']?.toDouble() ?? 0.0,
      destacado: map['destacado'] ?? false,
      icono: _getIconFromString(map['icono'] ?? 'local_offer'),
      categoria: map['categoria'] ?? '',
      activo: map['activo'] ?? true,
      fechaExpiracion: map['fechaExpiracion'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['fechaExpiracion'])
          : null,
    );
  }

  // Convertir a Map para Firebase
  Map<String, dynamic> toMap() {
    return {
      'comercioId': comercioId,
      'nombre': nombre,
      'descripcion': descripcion,
      'bioCoinsCosto': bioCoinsCosto,
      'descuentoPorcentaje': descuentoPorcentaje,
      'destacado': destacado,
      'icono': _getStringFromIcon(icono),
      'categoria': categoria,
      'activo': activo,
      'fechaExpiracion': fechaExpiracion?.millisecondsSinceEpoch,
    };
  }

  static IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'coffee':
        return Icons.coffee;
      case 'restaurant':
        return Icons.restaurant;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'directions_bike':
        return Icons.directions_bike;
      case 'medical_services':
        return Icons.medical_services;
      case 'local_pizza':
        return Icons.local_pizza;
      case 'cake':
        return Icons.cake;
      case 'local_drink':
        return Icons.local_drink;
      default:
        return Icons.local_offer;
    }
  }

  static String _getStringFromIcon(IconData icon) {
    if (icon == Icons.coffee) return 'coffee';
    if (icon == Icons.restaurant) return 'restaurant';
    if (icon == Icons.shopping_cart) return 'shopping_cart';
    if (icon == Icons.directions_bike) return 'directions_bike';
    if (icon == Icons.medical_services) return 'medical_services';
    if (icon == Icons.local_pizza) return 'local_pizza';
    if (icon == Icons.cake) return 'cake';
    if (icon == Icons.local_drink) return 'local_drink';
    return 'local_offer';
  }

  // Datos mock para testing
  static List<ProductoDescuento> getMockProductos() {
    return [
      // Productos destacados
      ProductoDescuento(
        id: 'prod_001',
        comercioId: 'com_001',
        nombre: 'Café Americano',
        descripcion: '20% de descuento en tu café americano favorito',
        bioCoinsCosto: 50,
        descuentoPorcentaje: 20,
        destacado: true,
        icono: Icons.coffee,
        categoria: 'Bebidas',
        activo: true,
      ),
      ProductoDescuento(
        id: 'prod_004',
        comercioId: 'com_002',
        nombre: 'Canasta Orgánica',
        descripcion: '15% de descuento en productos orgánicos seleccionados',
        bioCoinsCosto: 150,
        descuentoPorcentaje: 15,
        destacado: true,
        icono: Icons.shopping_cart,
        categoria: 'Alimentos',
        activo: true,
      ),
      ProductoDescuento(
        id: 'prod_007',
        comercioId: 'com_003',
        nombre: 'Servicio de Bicicleta',
        descripcion: '30% de descuento en servicio completo de mantenimiento',
        bioCoinsCosto: 200,
        descuentoPorcentaje: 30,
        destacado: true,
        icono: Icons.directions_bike,
        categoria: 'Servicios',
        activo: true,
      ),
      // Productos normales
      ProductoDescuento(
        id: 'prod_002',
        comercioId: 'com_001',
        nombre: 'Capuchino',
        descripcion: '15% de descuento en capuchino grande',
        bioCoinsCosto: 75,
        descuentoPorcentaje: 15,
        destacado: false,
        icono: Icons.coffee,
        categoria: 'Bebidas',
        activo: true,
      ),
      ProductoDescuento(
        id: 'prod_003',
        comercioId: 'com_001',
        nombre: 'Pastel del día',
        descripcion: '25% de descuento en rebanada de pastel',
        bioCoinsCosto: 100,
        descuentoPorcentaje: 25,
        destacado: false,
        icono: Icons.cake,
        categoria: 'Postres',
        activo: true,
      ),
      ProductoDescuento(
        id: 'prod_005',
        comercioId: 'com_002',
        nombre: 'Frutas de temporada',
        descripcion: '10% de descuento en frutas y verduras de temporada',
        bioCoinsCosto: 80,
        descuentoPorcentaje: 10,
        destacado: false,
        icono: Icons.shopping_cart,
        categoria: 'Alimentos',
        activo: true,
      ),
      ProductoDescuento(
        id: 'prod_006',
        comercioId: 'com_002',
        nombre: 'Productos de limpieza eco',
        descripcion: '20% de descuento en línea ecológica',
        bioCoinsCosto: 120,
        descuentoPorcentaje: 20,
        destacado: false,
        icono: Icons.shopping_cart,
        categoria: 'Hogar',
        activo: true,
      ),
      ProductoDescuento(
        id: 'prod_008',
        comercioId: 'com_003',
        nombre: 'Accesorios para bici',
        descripcion: '15% de descuento en accesorios seleccionados',
        bioCoinsCosto: 90,
        descuentoPorcentaje: 15,
        destacado: false,
        icono: Icons.directions_bike,
        categoria: 'Accesorios',
        activo: true,
      ),
      ProductoDescuento(
        id: 'prod_009',
        comercioId: 'com_004',
        nombre: 'Vitaminas naturales',
        descripcion: '20% de descuento en suplementos naturales',
        bioCoinsCosto: 180,
        descuentoPorcentaje: 20,
        destacado: false,
        icono: Icons.medical_services,
        categoria: 'Salud',
        activo: true,
      ),
      ProductoDescuento(
        id: 'prod_010',
        comercioId: 'com_004',
        nombre: 'Consulta nutricional',
        descripcion: '30% de descuento en primera consulta',
        bioCoinsCosto: 250,
        descuentoPorcentaje: 30,
        destacado: false,
        icono: Icons.medical_services,
        categoria: 'Servicios',
        activo: true,
      ),
      ProductoDescuento(
        id: 'prod_011',
        comercioId: 'com_005',
        nombre: 'Menú del día',
        descripcion: '15% de descuento en menú completo orgánico',
        bioCoinsCosto: 140,
        descuentoPorcentaje: 15,
        destacado: false,
        icono: Icons.restaurant,
        categoria: 'Alimentos',
        activo: true,
      ),
      ProductoDescuento(
        id: 'prod_012',
        comercioId: 'com_005',
        nombre: 'Pizza vegetariana',
        descripcion: '20% de descuento en pizza vegetariana grande',
        bioCoinsCosto: 160,
        descuentoPorcentaje: 20,
        destacado: false,
        icono: Icons.local_pizza,
        categoria: 'Alimentos',
        activo: true,
      ),
    ];
  }
}