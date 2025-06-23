import 'package:cloud_firestore/cloud_firestore.dart';

enum TipoNotificacion {
  solicitudTutoria,
  respuestaSolicitud,
  sesionConfirmada,
  recordatorioSesion,
  cancelacionSesion,
  mensajeGeneral,
  asignacionTutor,
  notificacionAdmin,
}

class Notificacion {
  final String id;
  final String titulo;
  final String mensaje;
  final String usuarioId;
  final String? remitenteId;
  final String? remitenteNombre;
  final TipoNotificacion tipo;
  final DateTime fechaCreacion;
  final bool leida;
  final Map<String, dynamic>? datosAdicionales;
  final String? fcmToken;

  Notificacion({
    required this.id,
    required this.titulo,
    required this.mensaje,
    required this.usuarioId,
    this.remitenteId,
    this.remitenteNombre,
    required this.tipo,
    required this.fechaCreacion,
    this.leida = false,
    this.datosAdicionales,
    this.fcmToken,
  });

  factory Notificacion.fromFirestore(Map<String, dynamic> data, {String? docId}) {
    return Notificacion(
      id: docId ?? data['id'] ?? '',
      titulo: data['titulo'] ?? '',
      mensaje: data['mensaje'] ?? '',
      usuarioId: data['usuarioId'] ?? '',
      remitenteId: data['remitenteId'],
      remitenteNombre: data['remitenteNombre'],
      tipo: TipoNotificacion.values.firstWhere(
        (e) => e.toString().endsWith('.${data['tipo']}'),
        orElse: () => TipoNotificacion.mensajeGeneral,
      ),
      fechaCreacion: (data['fechaCreacion'] as Timestamp).toDate(),
      leida: data['leida'] ?? false,
      datosAdicionales: data['datosAdicionales'] != null ? Map<String, dynamic>.from(data['datosAdicionales']) : null,
      fcmToken: data['fcmToken'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'titulo': titulo,
      'mensaje': mensaje,
      'usuarioId': usuarioId,
      'remitenteId': remitenteId,
      'remitenteNombre': remitenteNombre,
      'tipo': tipo.toString().split('.').last,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'leida': leida,
      'datosAdicionales': datosAdicionales,
      'fcmToken': fcmToken,
    };
  }

  Notificacion copyWith({
    String? id,
    String? titulo,
    String? mensaje,
    String? usuarioId,
    String? remitenteId,
    String? remitenteNombre,
    TipoNotificacion? tipo,
    DateTime? fechaCreacion,
    bool? leida,
    Map<String, dynamic>? datosAdicionales,
    String? fcmToken,
  }) {
    return Notificacion(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      mensaje: mensaje ?? this.mensaje,
      usuarioId: usuarioId ?? this.usuarioId,
      remitenteId: remitenteId ?? this.remitenteId,
      remitenteNombre: remitenteNombre ?? this.remitenteNombre,
      tipo: tipo ?? this.tipo,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      leida: leida ?? this.leida,
      datosAdicionales: datosAdicionales ?? this.datosAdicionales,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  String get tipoString {
    switch (tipo) {
      case TipoNotificacion.solicitudTutoria:
        return 'Solicitud de Tutoría';
      case TipoNotificacion.respuestaSolicitud:
        return 'Respuesta de Solicitud';
      case TipoNotificacion.sesionConfirmada:
        return 'Sesión Confirmada';
      case TipoNotificacion.recordatorioSesion:
        return 'Recordatorio de Sesión';
      case TipoNotificacion.cancelacionSesion:
        return 'Cancelación de Sesión';
      case TipoNotificacion.mensajeGeneral:
        return 'Mensaje General';
      case TipoNotificacion.asignacionTutor:
        return 'Asignación de Tutor';
      case TipoNotificacion.notificacionAdmin:
        return 'Notificación Administrativa';
    }
  }

  String get tiempoTranscurrido {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fechaCreacion);

    if (diferencia.inDays > 0) {
      return '${diferencia.inDays} día${diferencia.inDays > 1 ? 's' : ''}';
    } else if (diferencia.inHours > 0) {
      return '${diferencia.inHours} hora${diferencia.inHours > 1 ? 's' : ''}';
    } else if (diferencia.inMinutes > 0) {
      return '${diferencia.inMinutes} minuto${diferencia.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'Ahora mismo';
    }
  }
} 