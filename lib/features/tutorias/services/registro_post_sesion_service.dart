import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:tutoring_app/core/models/registro_post_sesion.dart';
import 'package:tutoring_app/core/models/sesion_tutoria.dart';
import 'package:tutoring_app/features/gamification/services/gamification_service.dart';

class RegistroPostSesionService {
  final CollectionReference _registrosRef = FirebaseFirestore.instance
      .collection('registros_post_sesion');
  final CollectionReference _sesionesRef = FirebaseFirestore.instance
      .collection('sesiones_tutoria');

  // Crear un nuevo registro post-sesión
  Future<void> crearRegistro(RegistroPostSesion registro) async {
    final registroId = const Uuid().v4();
    final registroConId = RegistroPostSesion(
      id: registroId,
      sesionId: registro.sesionId,
      tutorId: registro.tutorId,
      estudianteId: registro.estudianteId,
      fechaRegistro: registro.fechaRegistro,
      temasTratados: registro.temasTratados,
      recomendaciones: registro.recomendaciones,
      observaciones: registro.observaciones,
      comentariosAdicionales: registro.comentariosAdicionales,
      asistioEstudiante: registro.asistioEstudiante,
    );

    await _registrosRef.doc(registroId).set(registroConId.toMap());

    // Actualizar el estado de la sesión
    await _sesionesRef.doc(registro.sesionId).update({
      'estado': 'completada',
      'registroPostSesionId': registroId,
    });

    // Actualizar gamificación del estudiante
    try {
      final gamificationService = GamificationService();
      await gamificationService.completarSesion(
        registro.estudianteId,
        sesionId: registro.sesionId,
      );
      print(
        '✅ Gamificación actualizada para estudiante: ${registro.estudianteId}',
      );
    } catch (e) {
      print('❌ Error actualizando gamificación: $e');
    }
  }

  // Obtener registro post-sesión por ID
  Future<RegistroPostSesion?> obtenerRegistro(String registroId) async {
    final doc = await _registrosRef.doc(registroId).get();
    if (doc.exists) {
      return RegistroPostSesion.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  // Obtener registro post-sesión por sesión ID
  Future<RegistroPostSesion?> obtenerRegistroPorSesion(String sesionId) async {
    final query = await _registrosRef
        .where('sesionId', isEqualTo: sesionId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return RegistroPostSesion.fromMap(
        query.docs.first.data() as Map<String, dynamic>,
      );
    }
    return null;
  }

  // Obtener todos los registros de un tutor
  Future<List<RegistroPostSesion>> obtenerRegistrosPorTutor(
    String tutorId,
  ) async {
    final query = await _registrosRef
        .where('tutorId', isEqualTo: tutorId)
        .orderBy('fechaRegistro', descending: true)
        .get();

    return query.docs
        .map(
          (doc) =>
              RegistroPostSesion.fromMap(doc.data() as Map<String, dynamic>),
        )
        .toList();
  }

  // Obtener todos los registros de un estudiante
  Future<List<RegistroPostSesion>> obtenerRegistrosPorEstudiante(
    String estudianteId,
  ) async {
    final query = await _registrosRef
        .where('estudianteId', isEqualTo: estudianteId)
        .orderBy('fechaRegistro', descending: true)
        .get();

    return query.docs
        .map(
          (doc) =>
              RegistroPostSesion.fromMap(doc.data() as Map<String, dynamic>),
        )
        .toList();
  }

  // Verificar si una sesión ya tiene registro post-sesión
  Future<bool> sesionTieneRegistro(String sesionId) async {
    final query = await _registrosRef
        .where('sesionId', isEqualTo: sesionId)
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  // Obtener historial de un estudiante
  Future<List<RegistroPostSesion>> obtenerHistorialEstudiante(
    String estudianteId,
  ) async {
    final registros = await obtenerRegistrosPorEstudiante(estudianteId);

    // Ordenar por fecha más reciente
    registros.sort((a, b) => b.fechaRegistro.compareTo(a.fechaRegistro));

    return registros;
  }

  // Actualizar un registro existente
  Future<void> actualizarRegistro(RegistroPostSesion registro) async {
    await _registrosRef.doc(registro.id).update(registro.toMap());
  }

  // Eliminar un registro
  Future<void> eliminarRegistro(String registroId) async {
    await _registrosRef.doc(registroId).delete();
  }
}
