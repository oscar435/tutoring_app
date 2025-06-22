import 'package:cloud_firestore/cloud_firestore.dart';

class SesionTutoria {
  final String id;
  final String tutorId;
  final String estudianteId;
  final String dia;
  final String horaInicio;
  final String horaFin;
  final DateTime fechaReserva;
  final String? curso;
  final String estado; // aceptada, finalizada, cancelada
  final String? mensaje;
  final DateTime? fechaSesion;

  SesionTutoria({
    required this.id,
    required this.tutorId,
    required this.estudianteId,
    required this.dia,
    required this.horaInicio,
    required this.horaFin,
    required this.fechaReserva,
    this.curso,
    required this.estado,
    this.mensaje,
    this.fechaSesion,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'tutorId': tutorId,
    'estudianteId': estudianteId,
    'dia': dia,
    'horaInicio': horaInicio,
    'horaFin': horaFin,
    'fechaReserva': Timestamp.fromDate(fechaReserva),
    'curso': curso,
    'estado': estado,
    'mensaje': mensaje,
    'fechaSesion': fechaSesion != null ? Timestamp.fromDate(fechaSesion!) : null,
  };

  factory SesionTutoria.fromMap(Map<String, dynamic> map) {
    return SesionTutoria(
      id: map['id'],
      tutorId: map['tutorId'],
      estudianteId: map['estudianteId'],
      dia: map['dia'],
      horaInicio: map['horaInicio'],
      horaFin: map['horaFin'],
      fechaReserva: (map['fechaReserva'] as Timestamp).toDate(),
      curso: map['curso'],
      estado: map['estado'],
      mensaje: map['mensaje'],
      fechaSesion: map['fechaSesion'] != null ? (map['fechaSesion'] as Timestamp).toDate() : null,
    );
  }
} 