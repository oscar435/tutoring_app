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
    'fechaReserva': fechaReserva.toIso8601String(),
    'curso': curso,
    'estado': estado,
    'mensaje': mensaje,
    'fechaSesion': fechaSesion?.toIso8601String(),
  };

  factory SesionTutoria.fromMap(Map<String, dynamic> map) => SesionTutoria(
    id: map['id'],
    tutorId: map['tutorId'],
    estudianteId: map['estudianteId'],
    dia: map['dia'],
    horaInicio: map['horaInicio'],
    horaFin: map['horaFin'],
    fechaReserva: DateTime.parse(map['fechaReserva']),
    curso: map['curso'],
    estado: map['estado'],
    mensaje: map['mensaje'],
    fechaSesion: map['fechaSesion'] != null ? DateTime.parse(map['fechaSesion']) : null,
  );
} 