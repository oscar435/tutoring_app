import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutoring_app/core/models/sesion_tutoria.dart';
import 'package:intl/intl.dart';

class SesionTutoriaService {
  final CollectionReference _sesionesRef = FirebaseFirestore.instance
      .collection('sesiones_tutoria');

  Future<void> crearSesion(SesionTutoria sesion, String solicitudId) async {
    await _sesionesRef.doc(sesion.id).set({
      ...sesion.toMap(),
      'solicitudId': solicitudId,
    });
  }

  Future<List<SesionTutoria>> obtenerSesionesPorTutor(String tutorId) async {
    final query = await _sesionesRef
        .where('tutorId', isEqualTo: tutorId)
        .where('estado', whereIn: ['aceptada', 'completada'])
        .orderBy('fechaSesion', descending: false)
        .orderBy('fechaReserva', descending: false)
        .get();
    return query.docs
        .map((doc) => SesionTutoria.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<SesionTutoria>> obtenerSesionesFuturasPorTutor(
    String tutorId,
  ) async {
    final ahora = DateTime.now();
    final query = await _sesionesRef
        .where('tutorId', isEqualTo: tutorId)
        .where('estado', whereIn: ['aceptada', 'completada'])
        .orderBy('fechaSesion', descending: false)
        .orderBy('fechaReserva', descending: false)
        .get();

    final sesiones = query.docs
        .map((doc) => SesionTutoria.fromMap(doc.data() as Map<String, dynamic>))
        .where(
          (sesion) =>
              (sesion.fechaSesion ?? sesion.fechaReserva).isAfter(ahora),
        )
        .toList();

    // Ordenar por fecha (más próximas primero)
    sesiones.sort((a, b) {
      final fechaA = a.fechaSesion ?? a.fechaReserva;
      final fechaB = b.fechaSesion ?? b.fechaReserva;
      return fechaA.compareTo(fechaB);
    });

    return sesiones;
  }

  Stream<List<SesionTutoria>> streamSesionesFuturas(
    String userId,
    String userRole,
  ) {
    final ahora = DateTime.now();

    // Validar rol de usuario
    if (userRole != 'tutor' && userRole != 'estudiante') {
      throw ArgumentError(
        'El rol del usuario debe ser "tutor" o "estudiante".',
      );
    }

    final userField = userRole == 'tutor' ? 'tutorId' : 'estudianteId';

    return _sesionesRef
        .where(userField, isEqualTo: userId)
        .where('estado', whereIn: ['aceptada', 'completada'])
        .orderBy('fechaSesion', descending: false)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            return []; // Devuelve una lista vacía si no hay documentos
          }
          final sesiones = snapshot.docs
              .map(
                (doc) =>
                    SesionTutoria.fromMap(doc.data() as Map<String, dynamic>),
              )
              .where((sesion) {
                final ahora = DateTime.now();
                final fechaSesion = sesion.fechaSesion ?? sesion.fechaReserva;
                // Para sesiones aceptadas, mostrar si la fecha es futura o es hoy
                if (sesion.estado == 'aceptada') {
                  final esHoy =
                      fechaSesion.year == ahora.year &&
                      fechaSesion.month == ahora.month &&
                      fechaSesion.day == ahora.day;
                  return (fechaSesion.isAfter(ahora) || esHoy);
                }
                // Para sesiones completadas, mostrar si la fecha es futura o es hoy
                final esHoy =
                    fechaSesion.year == ahora.year &&
                    fechaSesion.month == ahora.month &&
                    fechaSesion.day == ahora.day;
                return (fechaSesion.isAfter(ahora) || esHoy);
              })
              .toList();
          return sesiones;
        });
  }

  Future<List<SesionTutoria>> obtenerSesionesPorEstudiante(
    String estudianteId,
  ) async {
    final query = await _sesionesRef
        .where('estudianteId', isEqualTo: estudianteId)
        .where('estado', whereIn: ['aceptada', 'completada'])
        .orderBy('fechaSesion', descending: false)
        .orderBy('fechaReserva', descending: false)
        .get();

    final sesiones = query.docs
        .map((doc) => SesionTutoria.fromMap(doc.data() as Map<String, dynamic>))
        .toList();

    // Ordenar por fecha (más próximas primero)
    sesiones.sort((a, b) {
      final fechaA = a.fechaSesion ?? a.fechaReserva;
      final fechaB = b.fechaSesion ?? b.fechaReserva;
      return fechaA.compareTo(fechaB);
    });

    return sesiones;
  }

  Future<void> cancelarSesion(String sesionId) async {
    final firestore = FirebaseFirestore.instance;
    // 1. Cancelar la sesión
    await firestore.collection('sesiones_tutoria').doc(sesionId).update({
      'estado': 'cancelada',
      'canceladaEn': FieldValue.serverTimestamp(),
    });

    // 2. Obtener el campo solicitudId de la sesión
    final sesionDoc = await firestore
        .collection('sesiones_tutoria')
        .doc(sesionId)
        .get();
    final solicitudId = sesionDoc.data()?['solicitudId'];
    if (solicitudId != null) {
      await firestore.collection('solicitudes_tutoria').doc(solicitudId).update(
        {'estado': 'cancelada'},
      );
    }
  }

  Future<void> reprogramarSesionYSolicitud({
    required String sesionId,
    required DateTime nuevaFechaSesion,
    required String nuevaHoraInicio,
    required String nuevaHoraFin,
  }) async {
    final firestore = FirebaseFirestore.instance;
    // 1. Actualizar la sesión
    await firestore.collection('sesiones_tutoria').doc(sesionId).update({
      'fechaSesion': Timestamp.fromDate(nuevaFechaSesion),
      'horaInicio': nuevaHoraInicio,
      'horaFin': nuevaHoraFin,
      'estado': 'aceptada',
    });
    // 2. Obtener el campo solicitudId de la sesión
    final sesionDoc = await firestore
        .collection('sesiones_tutoria')
        .doc(sesionId)
        .get();
    final solicitudId = sesionDoc.data()?['solicitudId'];
    if (solicitudId != null) {
      await firestore
          .collection('solicitudes_tutoria')
          .doc(solicitudId)
          .update({
            'fechaSesion': Timestamp.fromDate(nuevaFechaSesion),
            'horaInicio': nuevaHoraInicio,
            'horaFin': nuevaHoraFin,
            'estado': 'pendiente',
          });
    }
  }

  Future<void> solicitarReprogramacion({
    required String solicitudId,
    required DateTime nuevaFechaSesion,
    required String nuevaHoraInicio,
    required String nuevaHoraFin,
  }) async {
    final firestore = FirebaseFirestore.instance;
    // Calcular el día en español
    String nuevoDia = DateFormat('EEEE', 'es').format(nuevaFechaSesion);
    nuevoDia = nuevoDia.substring(0, 1).toUpperCase() + nuevoDia.substring(1);
    await firestore.collection('solicitudes_tutoria').doc(solicitudId).update({
      'reprogramacionPendiente': {
        'fechaSesion': Timestamp.fromDate(nuevaFechaSesion),
        'horaInicio': nuevaHoraInicio,
        'horaFin': nuevaHoraFin,
        'dia': nuevoDia,
      },
      'estado': 'reprogramacion_pendiente',
    });
  }

  Future<void> aceptarReprogramacion({required String solicitudId}) async {
    final firestore = FirebaseFirestore.instance;
    final solicitudDoc = await firestore
        .collection('solicitudes_tutoria')
        .doc(solicitudId)
        .get();
    final data = solicitudDoc.data();
    if (data == null || data['reprogramacionPendiente'] == null) return;
    final repro = data['reprogramacionPendiente'];
    final nuevaFechaSesion = (repro['fechaSesion'] as Timestamp).toDate();
    final nuevaHoraInicio = repro['horaInicio'] as String;
    final nuevaHoraFin = repro['horaFin'] as String;
    final nuevoDia = repro['dia'] as String? ?? '';
    // Actualizar solicitud
    await firestore.collection('solicitudes_tutoria').doc(solicitudId).update({
      'fechaSesion': Timestamp.fromDate(nuevaFechaSesion),
      'horaInicio': nuevaHoraInicio,
      'horaFin': nuevaHoraFin,
      'dia': nuevoDia,
      'estado': 'aceptada',
      'reprogramacionPendiente': FieldValue.delete(),
    });
    // Buscar la sesión asociada
    final sesiones = await firestore
        .collection('sesiones_tutoria')
        .where('solicitudId', isEqualTo: solicitudId)
        .get();
    if (sesiones.docs.isNotEmpty) {
      final sesionId = sesiones.docs.first.id;
      await firestore.collection('sesiones_tutoria').doc(sesionId).update({
        'fechaSesion': Timestamp.fromDate(nuevaFechaSesion),
        'horaInicio': nuevaHoraInicio,
        'horaFin': nuevaHoraFin,
        'dia': nuevoDia,
        'estado': 'aceptada',
      });
    }
  }

  Future<void> rechazarReprogramacion({required String solicitudId}) async {
    final firestore = FirebaseFirestore.instance;
    // Limpiar reprogramacionPendiente y cambiar estado a cancelada
    await firestore.collection('solicitudes_tutoria').doc(solicitudId).update({
      'reprogramacionPendiente': FieldValue.delete(),
      'estado': 'cancelada',
    });
    // Buscar la sesión asociada y cancelarla
    final sesiones = await firestore
        .collection('sesiones_tutoria')
        .where('solicitudId', isEqualTo: solicitudId)
        .get();
    if (sesiones.docs.isNotEmpty) {
      final sesionId = sesiones.docs.first.id;
      await firestore.collection('sesiones_tutoria').doc(sesionId).update({
        'estado': 'cancelada',
      });
    }
  }

  // Obtener sesiones completadas por tutor
  Future<List<SesionTutoria>> obtenerSesionesCompletadasPorTutor(
    String tutorId,
  ) async {
    final query = await _sesionesRef
        .where('tutorId', isEqualTo: tutorId)
        .where('estado', isEqualTo: 'completada')
        .orderBy('fechaSesion', descending: true)
        .get();
    return query.docs
        .map((doc) => SesionTutoria.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Obtener sesiones completadas por estudiante
  Future<List<SesionTutoria>> obtenerSesionesCompletadasPorEstudiante(
    String estudianteId,
  ) async {
    final query = await _sesionesRef
        .where('estudianteId', isEqualTo: estudianteId)
        .where('estado', isEqualTo: 'completada')
        .orderBy('fechaSesion', descending: true)
        .get();
    return query.docs
        .map((doc) => SesionTutoria.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Obtener historial de sesiones (completadas y pasadas)
  Future<List<SesionTutoria>> obtenerHistorialSesiones(
    String userId,
    String userRole,
  ) async {
    final ahora = DateTime.now();
    final userField = userRole == 'tutor' ? 'tutorId' : 'estudianteId';

    final query = await _sesionesRef
        .where(userField, isEqualTo: userId)
        .where('estado', whereIn: ['completada'])
        .orderBy('fechaSesion', descending: true)
        .get();

    // DEBUG: Mostrar todas las sesiones encontradas antes del filtro
    print('Sesiones encontradas para $userRole ($userId):');
    for (var doc in query.docs) {
      print(doc.data());
    }

    final sesiones = query.docs
        .map((doc) => SesionTutoria.fromMap(doc.data() as Map<String, dynamic>))
        .toList();

    return sesiones;
  }
}
