import 'package:cloud_firestore/cloud_firestore.dart';

class SolicitudTutoria {
  final String id;
  final String tutorId;
  final String estudianteId;
  final DateTime fechaHora;
  final String estado; // "pendiente", "aceptada", "rechazada"
  final String? curso;
  final String? mensaje;
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
    this.mensaje,
    this.dia,
    this.horaInicio,
    this.horaFin,
    this.fechaSesion,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'tutorId': tutorId,
    'estudianteId': estudianteId,
    'fechaHora': fechaHora.toIso8601String(),
    'estado': estado,
    'curso': curso,
    'mensaje': mensaje,
    'dia': dia,
    'horaInicio': horaInicio,
    'horaFin': horaFin,
    'fechaSesion': fechaSesion?.toIso8601String(),
  };

  factory SolicitudTutoria.fromMap(Map<String, dynamic> map) => SolicitudTutoria(
    id: map['id'],
    tutorId: map['tutorId'],
    estudianteId: map['estudianteId'],
    fechaHora: DateTime.parse(map['fechaHora']),
    estado: map['estado'],
    curso: map['curso'],
    mensaje: map['mensaje'],
    dia: map['dia'],
    horaInicio: map['horaInicio'],
    horaFin: map['horaFin'],
    fechaSesion: _parseFechaSesion(map['fechaSesion']),
  );

  static DateTime? _parseFechaSesion(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is String) {
      try {
        return DateTime.parse(raw);
      } catch (_) {
        return null;
      }
    }
    if (raw is Timestamp) return raw.toDate();
    return null;
  }
} 