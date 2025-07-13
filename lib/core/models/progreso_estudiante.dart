class ProgresoEstudiante {
  final String estudianteId;
  final int puntosTotales;
  final int nivel;
  final int sesionesCompletadas;
  final int sesionesAsistidas;
  final List<String> logrosDesbloqueados;
  final DateTime fechaCreacion;
  final DateTime ultimaActualizacion;

  ProgresoEstudiante({
    required this.estudianteId,
    this.puntosTotales = 0,
    this.nivel = 1,
    this.sesionesCompletadas = 0,
    this.sesionesAsistidas = 0,
    this.logrosDesbloqueados = const [],
    required this.fechaCreacion,
    required this.ultimaActualizacion,
  });

  factory ProgresoEstudiante.fromMap(Map<String, dynamic> map) {
    return ProgresoEstudiante(
      estudianteId: map['estudianteId'] ?? '',
      puntosTotales: map['puntosTotales']?.toInt() ?? 0,
      nivel: map['nivel']?.toInt() ?? 1,
      sesionesCompletadas: map['sesionesCompletadas']?.toInt() ?? 0,
      sesionesAsistidas: map['sesionesAsistidas']?.toInt() ?? 0,
      logrosDesbloqueados: List<String>.from(map['logrosDesbloqueados'] ?? []),
      fechaCreacion: DateTime.parse(map['fechaCreacion']),
      ultimaActualizacion: DateTime.parse(map['ultimaActualizacion']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'estudianteId': estudianteId,
      'puntosTotales': puntosTotales,
      'nivel': nivel,
      'sesionesCompletadas': sesionesCompletadas,
      'sesionesAsistidas': sesionesAsistidas,
      'logrosDesbloqueados': logrosDesbloqueados,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'ultimaActualizacion': ultimaActualizacion.toIso8601String(),
    };
  }

  ProgresoEstudiante copyWith({
    String? estudianteId,
    int? puntosTotales,
    int? nivel,
    int? sesionesCompletadas,
    int? sesionesAsistidas,
    List<String>? logrosDesbloqueados,
    DateTime? fechaCreacion,
    DateTime? ultimaActualizacion,
  }) {
    return ProgresoEstudiante(
      estudianteId: estudianteId ?? this.estudianteId,
      puntosTotales: puntosTotales ?? this.puntosTotales,
      nivel: nivel ?? this.nivel,
      sesionesCompletadas: sesionesCompletadas ?? this.sesionesCompletadas,
      sesionesAsistidas: sesionesAsistidas ?? this.sesionesAsistidas,
      logrosDesbloqueados: logrosDesbloqueados ?? this.logrosDesbloqueados,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      ultimaActualizacion: ultimaActualizacion ?? this.ultimaActualizacion,
    );
  }

  // Calcular puntos necesarios para el siguiente nivel
  int get puntosParaSiguienteNivel {
    return nivel * 100; // 100 puntos por nivel
  }

  // Calcular progreso hacia el siguiente nivel
  double get progresoNivel {
    int puntosNivelActual = (nivel - 1) * 100;
    int puntosEnNivelActual = puntosTotales - puntosNivelActual;
    return (puntosEnNivelActual / 100.0).clamp(0.0, 1.0);
  }
}
