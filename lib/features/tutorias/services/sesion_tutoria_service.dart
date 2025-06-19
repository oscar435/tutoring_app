import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutoring_app/core/models/sesion_tutoria.dart';

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
        .orderBy('fechaSesion', descending: false)
        .orderBy('fechaReserva', descending: false)
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
        .orderBy('fechaSesion', descending: false)
        .orderBy('fechaReserva', descending: false)
        .get();
    
    final sesiones = query.docs
        .map((doc) => SesionTutoria.fromMap(doc.data() as Map<String, dynamic>))
        .where((sesion) => (sesion.fechaSesion ?? sesion.fechaReserva).isAfter(ahora))
        .toList();
    
    // Ordenar por fecha (más próximas primero)
    sesiones.sort((a, b) {
      final fechaA = a.fechaSesion ?? a.fechaReserva;
      final fechaB = b.fechaSesion ?? b.fechaReserva;
      return fechaA.compareTo(fechaB);
    });
    
    return sesiones;
  }

  Stream<List<SesionTutoria>> streamSesionesFuturasPorTutor(String tutorId) {
    final ahora = DateTime.now();
    return _sesionesRef
        .where('tutorId', isEqualTo: tutorId)
        .where('estado', isEqualTo: 'aceptada')
        .orderBy('fechaSesion', descending: false)
        .orderBy('fechaReserva', descending: false)
        .snapshots()
        .map((snapshot) {
          final sesiones = snapshot.docs
              .map((doc) => SesionTutoria.fromMap(doc.data() as Map<String, dynamic>))
              .where((sesion) => (sesion.fechaSesion ?? sesion.fechaReserva).isAfter(ahora))
              .toList();
          
          // Ordenar por fecha (más próximas primero)
          sesiones.sort((a, b) {
            final fechaA = a.fechaSesion ?? a.fechaReserva;
            final fechaB = b.fechaSesion ?? b.fechaReserva;
            return fechaA.compareTo(fechaB);
          });
          
          return sesiones;
        });
  }

  Future<List<SesionTutoria>> obtenerSesionesPorEstudiante(String estudianteId) async {
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

  Stream<List<SesionTutoria>> streamSesionesFuturasPorEstudiante(String estudianteId) {
    final ahora = DateTime.now();
    return _sesionesRef
        .where('estudianteId', isEqualTo: estudianteId)
        .where('estado', isEqualTo: 'aceptada')
        .orderBy('fechaSesion', descending: false)
        .orderBy('fechaReserva', descending: false)
        .snapshots()
        .map((snapshot) {
          final sesiones = snapshot.docs
              .map((doc) => SesionTutoria.fromMap(doc.data() as Map<String, dynamic>))
              .where((sesion) => (sesion.fechaSesion ?? sesion.fechaReserva).isAfter(ahora))
              .toList();
          
          // Ordenar por fecha (más próximas primero)
          sesiones.sort((a, b) {
            final fechaA = a.fechaSesion ?? a.fechaReserva;
            final fechaB = b.fechaSesion ?? b.fechaReserva;
            return fechaA.compareTo(fechaB);
          });
          
          return sesiones;
        });
  }
} 