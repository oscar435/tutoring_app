import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sesion_tutoria.dart';

class SesionTutoriaService {
  final CollectionReference _sesionesRef =
      FirebaseFirestore.instance.collection('sesiones_tutoria');

  Future<void> crearSesion(SesionTutoria sesion) async {
    await _sesionesRef.doc(sesion.id).set(sesion.toMap());
  }

  Future<List<SesionTutoria>> obtenerSesionesPorTutor(String tutorId) async {
    final query = await _sesionesRef
        .where('tutorId', isEqualTo: tutorId)
        .where('estado', isEqualTo: 'aceptada')
        .get();
    return query.docs
        .map((doc) => SesionTutoria.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<SesionTutoria>> obtenerSesionesFuturasPorTutor(String tutorId) async {
    final ahora = DateTime.now();
    final query = await _sesionesRef
        .where('tutorId', isEqualTo: tutorId)
        .where('estado', isEqualTo: 'aceptada')
        .get();
    return query.docs
        .map((doc) => SesionTutoria.fromMap(doc.data() as Map<String, dynamic>))
        .where((sesion) => (sesion.fechaSesion ?? sesion.fechaReserva).isAfter(ahora))
        .toList();
  }

  Stream<List<SesionTutoria>> streamSesionesFuturasPorTutor(String tutorId) {
    final ahora = DateTime.now();
    return _sesionesRef
        .where('tutorId', isEqualTo: tutorId)
        .where('estado', isEqualTo: 'aceptada')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SesionTutoria.fromMap(doc.data() as Map<String, dynamic>))
            .where((sesion) => (sesion.fechaSesion ?? sesion.fechaReserva).isAfter(ahora))
            .toList());
  }

  Future<List<SesionTutoria>> obtenerSesionesPorEstudiante(String estudianteId) async {
    final query = await _sesionesRef
        .where('estudianteId', isEqualTo: estudianteId)
        .where('estado', isEqualTo: 'aceptada')
        .get();
    return query.docs
        .map((doc) => SesionTutoria.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Stream<List<SesionTutoria>> streamSesionesFuturasPorEstudiante(String estudianteId) {
    final ahora = DateTime.now();
    return _sesionesRef
        .where('estudianteId', isEqualTo: estudianteId)
        .where('estado', isEqualTo: 'aceptada')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SesionTutoria.fromMap(doc.data() as Map<String, dynamic>))
            .where((sesion) => (sesion.fechaSesion ?? sesion.fechaReserva).isAfter(ahora))
            .toList());
  }
} 