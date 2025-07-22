import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de horario de recolección para BioWay
class Horario {
  final String id;
  final String dia;
  final int numDia; // 1 = Lunes, 7 = Domingo
  final String horario;
  final String matinfo; // Información del material
  final String qnr; // Qué no recibe
  final String cantidadMinima;
  final bool activo;

  Horario({
    required this.id,
    required this.dia,
    required this.numDia,
    required this.horario,
    required this.matinfo,
    required this.qnr,
    required this.cantidadMinima,
    this.activo = true,
  });

  /// Crea desde un documento de Firestore
  factory Horario.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Horario(
      id: doc.id,
      dia: data['dia'] ?? '',
      numDia: data['numDia'] ?? 1,
      horario: data['horario'] ?? '',
      matinfo: data['matinfo'] ?? '',
      qnr: data['qnr'] ?? '',
      cantidadMinima: data['cantidadMinima'] ?? '',
      activo: data['activo'] ?? true,
    );
  }

  /// Convierte a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'dia': dia,
      'numDia': numDia,
      'horario': horario,
      'matinfo': matinfo,
      'qnr': qnr,
      'cantidadMinima': cantidadMinima,
      'activo': activo,
    };
  }

  /// Crea una instancia de prueba (hardcoded)
  static List<Horario> getMockHorarios() {
    return [
      Horario(
        id: '1',
        dia: 'Lunes',
        numDia: 1,
        horario: '8:00 AM - 12:00 PM',
        matinfo: 'Plástico PET',
        qnr: 'Plástico sucio o con residuos',
        cantidadMinima: '1 kg mínimo',
      ),
      Horario(
        id: '2',
        dia: 'Martes',
        numDia: 2,
        horario: '8:00 AM - 12:00 PM',
        matinfo: 'Vidrio',
        qnr: 'Vidrio roto o focos',
        cantidadMinima: '2 kg mínimo',
      ),
      Horario(
        id: '3',
        dia: 'Miércoles',
        numDia: 3,
        horario: '8:00 AM - 12:00 PM',
        matinfo: 'Papel y Cartón',
        qnr: 'Papel mojado o con grasa',
        cantidadMinima: '1 kg mínimo',
      ),
      Horario(
        id: '4',
        dia: 'Jueves',
        numDia: 4,
        horario: '8:00 AM - 12:00 PM',
        matinfo: 'Metal (Aluminio)',
        qnr: 'Latas con residuos',
        cantidadMinima: '500 g mínimo',
      ),
      Horario(
        id: '5',
        dia: 'Viernes',
        numDia: 5,
        horario: '8:00 AM - 12:00 PM',
        matinfo: 'Plástico HDPE',
        qnr: 'Envases de químicos',
        cantidadMinima: '1 kg mínimo',
      ),
      Horario(
        id: '6',
        dia: 'Sábado',
        numDia: 6,
        horario: '9:00 AM - 1:00 PM',
        matinfo: 'Orgánico',
        qnr: 'Carne o lácteos',
        cantidadMinima: '2 kg mínimo',
      ),
      Horario(
        id: '7',
        dia: 'Domingo',
        numDia: 7,
        horario: 'Cerrado',
        matinfo: 'No hay recolección',
        qnr: 'N/A',
        cantidadMinima: 'N/A',
      ),
    ];
  }
}