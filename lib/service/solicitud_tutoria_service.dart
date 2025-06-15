import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/solicitud_tutoria.dart';
import '../models/notificacion.dart';
import 'notificacion_service.dart';
import 'package:uuid/uuid.dart';
import '../models/sesion_tutoria.dart';
import 'sesion_tutoria_service.dart';

class SolicitudTutoriaService {
  final CollectionReference _solicitudesRef =
      FirebaseFirestore.instance.collection('solicitudes_tutoria');
  final CollectionReference _estudiantesRef =
      FirebaseFirestore.instance.collection('estudiantes');

  // Crear una nueva solicitud de tutoría y notificar al tutor
  Future<void> crearSolicitud(SolicitudTutoria solicitud) async {
    await _solicitudesRef.doc(solicitud.id).set(solicitud.toMap());
    // Notificar al tutor
    final noti = Notificacion(
      id: const Uuid().v4(),
      usuarioId: solicitud.tutorId,
      tipo: 'solicitud',
      mensaje: 'Tienes una nueva solicitud de tutoría.',
      fecha: DateTime.now(),
    );
    await NotificacionService().crearNotificacion(noti);
  }

  // Obtener solicitudes por tutor
  Future<List<SolicitudTutoria>> obtenerSolicitudesPorTutor(String tutorId) async {
    final query = await _solicitudesRef.where('tutorId', isEqualTo: tutorId).get();
    return query.docs
        .map((doc) => SolicitudTutoria.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Actualizar el estado de una solicitud (aceptar/rechazar) y notificar al estudiante
  Future<void> actualizarEstado(String solicitudId, String nuevoEstado) async {
    final doc = await _solicitudesRef.doc(solicitudId).get();
    if (!doc.exists) return;
    final solicitud = SolicitudTutoria.fromMap(doc.data() as Map<String, dynamic>);
    await _solicitudesRef.doc(solicitudId).update({'estado': nuevoEstado});
    // Notificar al estudiante
    final mensaje = nuevoEstado == 'aceptada'
        ? 'Tu solicitud de tutoría fue aceptada.'
        : 'Tu solicitud de tutoría fue rechazada.';
    final noti = Notificacion(
      id: const Uuid().v4(),
      usuarioId: solicitud.estudianteId,
      tipo: 'respuesta',
      mensaje: mensaje,
      fecha: DateTime.now(),
    );
    await NotificacionService().crearNotificacion(noti);
    // Si se acepta, crear sesión
    if (nuevoEstado == 'aceptada') {
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
        fechaSesion: solicitud.fechaSesion,
      );
      await SesionTutoriaService().crearSesion(sesion);
    }
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
} 