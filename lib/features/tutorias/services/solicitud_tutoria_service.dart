import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutoring_app/core/models/solicitud_tutoria.dart';
import 'package:tutoring_app/core/models/notificacion.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tutoring_app/core/models/sesion_tutoria.dart';
import 'package:tutoring_app/features/notificaciones/services/notificacion_service.dart';
import 'package:tutoring_app/features/disponibilidad/services/disponibilidad_service.dart';
import 'package:uuid/uuid.dart';
import 'package:tutoring_app/features/tutorias/services/sesion_tutoria_service.dart';

class SolicitudTutoriaService {
  final CollectionReference _solicitudesRef =
      FirebaseFirestore.instance.collection('solicitudes_tutoria');
  final CollectionReference _estudiantesRef =
      FirebaseFirestore.instance.collection('estudiantes');
  final CollectionReference _tutoresRef =
      FirebaseFirestore.instance.collection('tutores');

  // Crear una nueva solicitud de tutoría y notificar al tutor
  Future<void> crearSolicitud(SolicitudTutoria solicitud) async {
    await _solicitudesRef.doc(solicitud.id).set(solicitud.toMap());
    
    // LA LÓGICA DE NOTIFICACIÓN SE HA ELIMINADO DE AQUÍ.
    // AHORA LA GESTIONA COMPLETAMENTE LA CLOUD FUNCTION onSolicitudTutoriaCreated
  }

  // Obtener solicitudes por tutor
  Future<List<SolicitudTutoria>> obtenerSolicitudesPorTutor(String tutorId) async {
    final query = await _solicitudesRef
        .where('tutorId', isEqualTo: tutorId)
        .orderBy('fechaHora', descending: true)
        .get();
    return query.docs
        .map((doc) => SolicitudTutoria.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Actualizar el estado de una solicitud (aceptar/rechazar) y notificar al estudiante
  Future<Map<String, dynamic>> actualizarEstado(String solicitudId, String nuevoEstado) async {
    final doc = await _solicitudesRef.doc(solicitudId).get();
    if (!doc.exists) {
      return {'success': false, 'message': 'Solicitud no encontrada'};
    }
    
    final solicitud = SolicitudTutoria.fromMap(doc.data() as Map<String, dynamic>);
    
    // Si se va a aceptar, validar conflictos de horario
    if (nuevoEstado == 'aceptada') {
      final disponibilidadService = DisponibilidadService();
      
      // Verificar si hay conflicto de horario
      final hayConflicto = await disponibilidadService.hayConflictoHorario(
        tutorId: solicitud.tutorId,
        fechaSesion: solicitud.fechaSesion!,
        horaInicio: solicitud.horaInicio!,
        horaFin: solicitud.horaFin!,
      );

      if (hayConflicto) {
        return {
          'success': false, 
          'message': 'No se puede aceptar la solicitud. El horario ya está ocupado por otra sesión.'
        };
      }

      // Verificar que el horario esté dentro de la disponibilidad del tutor
      final esHorarioValido = await disponibilidadService.esHorarioValido(
        tutorId: solicitud.tutorId,
        dia: solicitud.dia!,
        horaInicio: solicitud.horaInicio!,
        horaFin: solicitud.horaFin!,
      );

      if (!esHorarioValido) {
        return {
          'success': false, 
          'message': 'No se puede aceptar la solicitud. El horario no está dentro de la disponibilidad del tutor.'
        };
      }
    }

    // Actualizar el estado de la solicitud
    await _solicitudesRef.doc(solicitudId).update({'estado': nuevoEstado});
    
    // LA LÓGICA DE NOTIFICACIÓN SE HA ELIMINADO DE AQUÍ.
    // AHORA LA GESTIONA COMPLETAMENTE LA CLOUD FUNCTION onSolicitudTutoriaUpdated
    
    // Si se acepta, crear sesión
    if (nuevoEstado == 'aceptada') {
      final fechaSesion = solicitud.fechaSesion ?? _calcularFechaSesion(solicitud.dia!, solicitud.horaInicio!);
      final sesion = SesionTutoria(
        id: const Uuid().v4(),
        tutorId: solicitud.tutorId,
        estudianteId: solicitud.estudianteId,
        dia: solicitud.dia ?? '',
        horaInicio: solicitud.horaInicio ?? '',
        horaFin: solicitud.horaFin ?? '',
        fechaReserva: DateTime.now(),
        curso: solicitud.curso,
        estado: 'aceptada',
        mensaje: solicitud.mensaje,
        fechaSesion: fechaSesion,
      );
      await SesionTutoriaService().crearSesion(sesion);
    }

    return {'success': true, 'message': 'Solicitud actualizada correctamente'};
  }

  DateTime _calcularFechaSesion(String dia, String horaInicio) {
    final ahora = DateTime.now();
    final diasSemana = {
      'Lunes': 1, 'Martes': 2, 'Miércoles': 3, 'Jueves': 4, 'Viernes': 5, 'Sábado': 6, 'Domingo': 7
    };
    final diaSolicitado = diasSemana[dia]!;
    
    var fechaBase = DateTime(ahora.year, ahora.month, ahora.day);
    while (fechaBase.weekday != diaSolicitado) {
      fechaBase = fechaBase.add(const Duration(days: 1));
    }

    final partesHora = horaInicio.split(':');
    var fechaFinal = DateTime(
      fechaBase.year,
      fechaBase.month,
      fechaBase.day,
      int.parse(partesHora[0]),
      int.parse(partesHora[1]),
    );

    // Si la fecha/hora calculada ya pasó, calcular para la siguiente semana
    if (fechaFinal.isBefore(ahora)) {
      fechaFinal = fechaFinal.add(const Duration(days: 7));
    }
    
    return fechaFinal;
  }

  // Obtener nombre del estudiante
  Future<String> obtenerNombreEstudiante(String estudianteId) async {
    final doc = await _estudiantesRef.doc(estudianteId).get();
    if (!doc.exists) return 'Estudiante';
    final data = doc.data() as Map<String, dynamic>;
    final nombre = data['nombre'] ?? '';
    final apellidos = data['apellidos'] ?? '';
    return '$nombre $apellidos'.trim().isEmpty ? 'Estudiante' : '$nombre $apellidos';
  }

  // Obtener nombre del tutor
  Future<String> obtenerNombreTutor(String tutorId) async {
    final doc = await _tutoresRef.doc(tutorId).get();
    if (!doc.exists) return 'Tutor';
    final data = doc.data() as Map<String, dynamic>;
    final nombre = data['nombre'] ?? '';
    final apellidos = data['apellidos'] ?? '';
    return '$nombre $apellidos'.trim().isEmpty ? 'Tutor' : '$nombre $apellidos';
  }

  // Obtener solicitudes por tutor con nombres de estudiantes
  Future<List<Map<String, dynamic>>> obtenerSolicitudesConNombres(String tutorId) async {
    final solicitudes = await obtenerSolicitudesPorTutor(tutorId);
    final solicitudesConNombres = await Future.wait(
      solicitudes.map((s) async {
        final nombreEstudiante = await obtenerNombreEstudiante(s.estudianteId);
        return {
          'solicitud': s,
          'nombreEstudiante': nombreEstudiante,
        };
      }),
    );
    return solicitudesConNombres;
  }

  // Obtener stream de solicitudes por tutor
  Stream<List<SolicitudTutoria>> getSolicitudesPorTutorStream(String tutorId) {
    return _solicitudesRef
        .where('tutorId', isEqualTo: tutorId)
        .orderBy('fechaHora', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SolicitudTutoria.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // Obtener stream de solicitudes por tutor con detalles del estudiante
  Stream<List<Map<String, dynamic>>> getSolicitudesConDetallesStream(String tutorId) {
    return _solicitudesRef
        .where('tutorId', isEqualTo: tutorId)
        .orderBy('fechaHora', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final solicitudesConDetalles = <Map<String, dynamic>>[];
      for (var doc in snapshot.docs) {
        final solicitud = SolicitudTutoria.fromMap(doc.data() as Map<String, dynamic>);
        
        // Obtener detalles del estudiante
        final estudianteDoc = await _estudiantesRef.doc(solicitud.estudianteId).get();
        String nombreEstudiante = 'Estudiante';
        String? photoUrl;

        if (estudianteDoc.exists) {
          final data = estudianteDoc.data() as Map<String, dynamic>;
          final nombre = data['nombre'] ?? '';
          final apellidos = data['apellidos'] ?? '';
          nombreEstudiante = '$nombre $apellidos'.trim().isEmpty ? 'Estudiante' : '$nombre $apellidos';
          photoUrl = data['photoUrl'];
        }

        solicitudesConDetalles.add({
          'solicitud': solicitud,
          'nombreEstudiante': nombreEstudiante,
          'photoUrl': photoUrl,
        });
      }
      return solicitudesConDetalles;
    });
  }
} 