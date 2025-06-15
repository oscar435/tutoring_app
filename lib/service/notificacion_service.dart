import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notificacion.dart';

class NotificacionService {
  final CollectionReference _notificacionesRef =
      FirebaseFirestore.instance.collection('notificaciones');

  // Crear una nueva notificación
  Future<void> crearNotificacion(Notificacion notificacion) async {
    await _notificacionesRef.doc(notificacion.id).set(notificacion.toMap());
  }

  // Obtener notificaciones para un usuario
  Future<List<Notificacion>> obtenerNotificacionesPorUsuario(String usuarioId) async {
    final query = await _notificacionesRef
        .where('usuarioId', isEqualTo: usuarioId)
        .orderBy('fecha', descending: true)
        .get();
    return query.docs
        .map((doc) => Notificacion.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Marcar una notificación como leída
  Future<void> marcarComoLeida(String notificacionId) async {
    await _notificacionesRef.doc(notificacionId).update({'leida': true});
  }

  // Borrar una notificación por su ID
  Future<void> borrarNotificacion(String notificacionId) async {
    await _notificacionesRef.doc(notificacionId).delete();
  }
} 