import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutoring_app/core/models/sesion_tutoria.dart';

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
        .where('estado', isEqualTo: 'aceptada')
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
        .where('estado', isEqualTo: 'aceptada')
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
        .where('estado', isEqualTo: 'aceptada')
        .where('fechaSesion', isGreaterThan: ahora) // Filtrado en el servidor
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
              .toList();
          return sesiones;
        });
  }

  Future<List<SesionTutoria>> obtenerSesionesPorEstudiante(
    String estudianteId,
  ) async {
    final query = await _sesionesRef
        .where('estudianteId', isEqualTo: estudianteId)
        .where('estado', isEqualTo: 'aceptada')
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
}
