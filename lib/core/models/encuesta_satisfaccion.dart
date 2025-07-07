// Modelo para la encuesta de satisfacción del estudiante
class EncuestaSatisfaccion {
  final String id;
  final String estudianteId;
  final int calificacion; // 1-5
  final String comentario;
  final DateTime fechaRespuesta;

  EncuestaSatisfaccion({
    required this.id,
    required this.estudianteId,
    required this.calificacion,
    required this.comentario,
    required this.fechaRespuesta,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'estudianteId': estudianteId,
    'calificacion': calificacion,
    'comentario': comentario,
    'fechaRespuesta': fechaRespuesta.toIso8601String(),
  };

  factory EncuestaSatisfaccion.fromMap(Map<String, dynamic> map) {
    return EncuestaSatisfaccion(
      id: map['id'] ?? '',
      estudianteId: map['estudianteId'] ?? '',
      calificacion: map['calificacion'] ?? 0,
      comentario: map['comentario'] ?? '',
      fechaRespuesta:
          DateTime.tryParse(map['fechaRespuesta'] ?? '') ?? DateTime.now(),
    );
  }
}
