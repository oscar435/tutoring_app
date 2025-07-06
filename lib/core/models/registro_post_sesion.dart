import 'package:cloud_firestore/cloud_firestore.dart';

class RegistroPostSesion {
  final String id;
  final String sesionId;
  final String tutorId;
  final String estudianteId;
  final DateTime fechaRegistro;
  final List<String> temasTratados;
  final String recomendaciones;
  final String observaciones;
  final String comentariosAdicionales;
  final bool asistioEstudiante;

  RegistroPostSesion({
    required this.id,
    required this.sesionId,
    required this.tutorId,
    required this.estudianteId,
    required this.fechaRegistro,
    required this.temasTratados,
    required this.recomendaciones,
    required this.observaciones,
    required this.comentariosAdicionales,
    required this.asistioEstudiante,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'sesionId': sesionId,
    'tutorId': tutorId,
    'estudianteId': estudianteId,
    'fechaRegistro': Timestamp.fromDate(fechaRegistro),
    'temasTratados': temasTratados,
    'recomendaciones': recomendaciones,
    'observaciones': observaciones,
    'comentariosAdicionales': comentariosAdicionales,
    'asistioEstudiante': asistioEstudiante,
  };

  factory RegistroPostSesion.fromMap(Map<String, dynamic> map) {
    return RegistroPostSesion(
      id: map['id'],
      sesionId: map['sesionId'],
      tutorId: map['tutorId'],
      estudianteId: map['estudianteId'],
      fechaRegistro: (map['fechaRegistro'] as Timestamp).toDate(),
      temasTratados: List<String>.from(map['temasTratados']),
      recomendaciones: map['recomendaciones'],
      observaciones: map['observaciones'],
      comentariosAdicionales: map['comentariosAdicionales'],
      asistioEstudiante: map['asistioEstudiante'],
    );
  }

  factory RegistroPostSesion.empty({
    required String sesionId,
    required String tutorId,
    required String estudianteId,
  }) {
    return RegistroPostSesion(
      id: '',
      sesionId: sesionId,
      tutorId: tutorId,
      estudianteId: estudianteId,
      fechaRegistro: DateTime.now(),
      temasTratados: [],
      recomendaciones: '',
      observaciones: '',
      comentariosAdicionales: '',
      asistioEstudiante: true,
    );
  }
}
