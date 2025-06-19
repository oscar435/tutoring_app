class Notificacion {
  final String id;
  final String usuarioId;
  final String tipo;
  final String mensaje;
  final bool leida;
  final DateTime fecha;

  Notificacion({
    required this.id,
    required this.usuarioId,
    required this.tipo,
    required this.mensaje,
    this.leida = false,
    required this.fecha,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'usuarioId': usuarioId,
    'tipo': tipo,
    'mensaje': mensaje,
    'leida': leida,
    'fecha': fecha.toIso8601String(),
  };

  factory Notificacion.fromMap(Map<String, dynamic> map) => Notificacion(
    id: map['id'],
    usuarioId: map['usuarioId'],
    tipo: map['tipo'],
    mensaje: map['mensaje'],
    leida: map['leida'] ?? false,
    fecha: DateTime.parse(map['fecha']),
  );
} 