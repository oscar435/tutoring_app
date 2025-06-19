class Slot {
  final String dia;
  final String horaInicio;
  final String horaFin;
  final bool activo;

  Slot({required this.dia, required this.horaInicio, required this.horaFin, this.activo = true});

  Map<String, dynamic> toMap() => {
    'dia': dia,
    'horaInicio': horaInicio,
    'horaFin': horaFin,
    'activo': activo,
  };

  factory Slot.fromMap(Map<String, dynamic> map) => Slot(
    dia: map['dia'],
    horaInicio: map['horaInicio'],
    horaFin: map['horaFin'],
    activo: map['activo'] ?? true,
  );
}

class Disponibilidad {
  final String tutorId;
  final List<Slot> slots;

  Disponibilidad({required this.tutorId, required this.slots});

  Map<String, dynamic> toMap() => {
    'tutorId': tutorId,
    'slots': slots.map((s) => s.toMap()).toList(),
  };

  factory Disponibilidad.fromMap(Map<String, dynamic> map) => Disponibilidad(
    tutorId: map['tutorId'],
    slots: List<Slot>.from((map['slots'] as List).map((s) => Slot.fromMap(s))),
  );
} 