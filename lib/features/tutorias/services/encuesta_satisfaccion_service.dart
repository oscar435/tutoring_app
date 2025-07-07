import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutoring_app/core/models/encuesta_satisfaccion.dart';

class EncuestaSatisfaccionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> guardarEncuesta({
    required String sesionId,
    required EncuestaSatisfaccion encuesta,
  }) async {
    await _db
        .collection('sesiones_tutoria')
        .doc(sesionId)
        .collection('encuestas_satisfaccion')
        .doc(encuesta.estudianteId)
        .set(encuesta.toMap());
  }

  Future<EncuestaSatisfaccion?> obtenerEncuesta({
    required String sesionId,
    required String estudianteId,
  }) async {
    final doc = await _db
        .collection('sesiones_tutoria')
        .doc(sesionId)
        .collection('encuestas_satisfaccion')
        .doc(estudianteId)
        .get();
    if (!doc.exists) return null;
    return EncuestaSatisfaccion.fromMap(doc.data()!);
  }

  Stream<EncuestaSatisfaccion?> streamEncuesta({
    required String sesionId,
    required String estudianteId,
  }) {
    return _db
        .collection('sesiones_tutoria')
        .doc(sesionId)
        .collection('encuestas_satisfaccion')
        .doc(estudianteId)
        .snapshots()
        .map(
          (doc) =>
              doc.exists ? EncuestaSatisfaccion.fromMap(doc.data()!) : null,
        );
  }
}
