class Logro {
  final String id;
  final String nombre;
  final String descripcion;
  final String icono;
  final int puntosRecompensa;
  final String tipo; // 'sesion', 'asistencia', 'evaluacion', 'especial'
  final int meta; // Meta para desbloquear el logro
  final bool desbloqueado;
  final DateTime? fechaDesbloqueo;

  Logro({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.icono,
    required this.puntosRecompensa,
    required this.tipo,
    required this.meta,
    this.desbloqueado = false,
    this.fechaDesbloqueo,
  });

  factory Logro.fromMap(Map<String, dynamic> map) {
    return Logro(
      id: map['id'] ?? '',
      nombre: map['nombre'] ?? '',
      descripcion: map['descripcion'] ?? '',
      icono: map['icono'] ?? '',
      puntosRecompensa: map['puntosRecompensa']?.toInt() ?? 0,
      tipo: map['tipo'] ?? '',
      meta: map['meta']?.toInt() ?? 0,
      desbloqueado: map['desbloqueado'] ?? false,
      fechaDesbloqueo: map['fechaDesbloqueo'] != null
          ? DateTime.parse(map['fechaDesbloqueo'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'icono': icono,
      'puntosRecompensa': puntosRecompensa,
      'tipo': tipo,
      'meta': meta,
      'desbloqueado': desbloqueado,
      'fechaDesbloqueo': fechaDesbloqueo?.toIso8601String(),
    };
  }

  Logro copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    String? icono,
    int? puntosRecompensa,
    String? tipo,
    int? meta,
    bool? desbloqueado,
    DateTime? fechaDesbloqueo,
  }) {
    return Logro(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      icono: icono ?? this.icono,
      puntosRecompensa: puntosRecompensa ?? this.puntosRecompensa,
      tipo: tipo ?? this.tipo,
      meta: meta ?? this.meta,
      desbloqueado: desbloqueado ?? this.desbloqueado,
      fechaDesbloqueo: fechaDesbloqueo ?? this.fechaDesbloqueo,
    );
  }
}
