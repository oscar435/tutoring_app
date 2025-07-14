import 'package:cloud_firestore/cloud_firestore.dart';

class SolicitudTutoria {
  final String id;
  final String tutorId;
  final String estudianteId;
  final DateTime fechaHora;
  final String estado; // "pendiente", "aceptada", "rechazada"
  final String? curso;
  final String? dia;
  final String? horaInicio;
  final String? horaFin;
  final DateTime? fechaSesion;

  SolicitudTutoria({
    required this.id,
    required this.tutorId,
    required this.estudianteId,
    required this.fechaHora,
    required this.estado,
    this.curso,
    this.dia,
    this.horaInicio,
    this.horaFin,
    this.fechaSesion,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'tutorId': tutorId,
    'estudianteId': estudianteId,
    'fechaHora': Timestamp.fromDate(fechaHora),
    'estado': estado,
    'curso': curso,
    'dia': dia,
    'horaInicio': horaInicio,
    'horaFin': horaFin,
    'fechaSesion': fechaSesion != null
        ? Timestamp.fromDate(fechaSesion!)
        : null,
  };

  factory SolicitudTutoria.fromMap(Map<String, dynamic> map) =>
      SolicitudTutoria(
        id: map['id'],
        tutorId: map['tutorId'],
        estudianteId: map['estudianteId'],
        fechaHora: _parseFechaSesion(map['fechaHora'])!,
        estado: map['estado'],
        curso: map['curso'],
        dia: map['dia'],
        horaInicio: map['horaInicio'],
        horaFin: map['horaFin'],
        fechaSesion: _parseFechaSesion(map['fechaSesion']),
      );

  static DateTime? _parseFechaSesion(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) {
      try {
        return DateTime.parse(raw);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
