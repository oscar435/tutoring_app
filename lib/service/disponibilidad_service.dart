import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/disponibilidad.dart';

class DisponibilidadService {
  final CollectionReference _disponibilidadRef =
      FirebaseFirestore.instance.collection('disponibilidades');

  // Guardar o actualizar la disponibilidad de un tutor
  Future<void> guardarDisponibilidad(Disponibilidad disponibilidad) async {
    await _disponibilidadRef.doc(disponibilidad.tutorId).set(disponibilidad.toMap());
  }

  // Obtener la disponibilidad de un tutor por su ID
  Future<Disponibilidad?> obtenerDisponibilidad(String tutorId) async {
    final doc = await _disponibilidadRef.doc(tutorId).get();
    if (doc.exists) {
      return Disponibilidad.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }
} 