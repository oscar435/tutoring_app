import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'dart:io';

final List<String> escuelasReparto = [
  'Ingeniería Electrónica',
  'Ingeniería Electrónica',
  'Ingeniería Mecatrónica',
  'Ingeniería Mecatrónica',
  'Ingeniería Informática',
  'Ingeniería Informática',
  'Ingeniería Informática',
  'Ingeniería de Telecomunicaciones',
  'Ingeniería de Telecomunicaciones',
  'Ingeniería de Telecomunicaciones',
];

Future<Map<String, List<String>>> obtenerCursosPorEscuela() async {
  final firestore = FirebaseFirestore.instance;
  final escuelasSnap = await firestore.collection('escuelas').get();
  final Map<String, List<String>> cursosPorEscuela = {};
  for (var doc in escuelasSnap.docs) {
    final data = doc.data();
    final nombreEscuela = data.values.first.toString();
    final cursos = <String>[];
    final ciclosSnap = await firestore
        .collection('escuelas')
        .doc(doc.id)
        .collection('ciclos')
        .get();
    for (var cicloDoc in ciclosSnap.docs) {
      final cursosSnap = await firestore
          .collection('escuelas')
          .doc(doc.id)
          .collection('ciclos')
          .doc(cicloDoc.id)
          .collection('cursos')
          .get();
      for (var cursoDoc in cursosSnap.docs) {
        final cursoData = cursoDoc.data();
        final nombreCurso = cursoData['nombre'] ?? cursoDoc.id;
        cursos.add(nombreCurso);
      }
    }
    cursosPorEscuela[nombreEscuela] = cursos;
  }
  return cursosPorEscuela;
}

Future<void> asignarEscuelasATutores(
  List<QueryDocumentSnapshot> tutoresDocs,
) async {
  for (int i = 0; i < tutoresDocs.length && i < escuelasReparto.length; i++) {
    final doc = tutoresDocs[i];
    final nuevaEscuela = escuelasReparto[i];
    await doc.reference.update({'escuela': nuevaEscuela});
    final data = doc.data() as Map<String, dynamic>;
  }
}

Future<void> asignarCursosATutores() async {
  final firestore = FirebaseFirestore.instance;
  final tutoresSnap = await firestore.collection('tutores').get();

  // Repartir escuelas antes de asignar cursos
  await asignarEscuelasATutores(tutoresSnap.docs);

  // Obtener todos los cursos por escuela
  final cursosPorEscuela = await obtenerCursosPorEscuela();
  final random = Random();

  for (var doc in tutoresSnap.docs) {
    final data = doc.data();
    final escuela = data['escuela'] ?? '';
    if (escuela.isEmpty) continue;
    final cursos = cursosPorEscuela[escuela] ?? [];
    if (cursos.length < 3) {
      continue;
    }
    // Seleccionar 3 cursos aleatorios y distintos
    final cursosCopia = List<String>.from(cursos);
    cursosCopia.shuffle(random);
    final cursosAsignados = cursosCopia.take(3).toList();
    final especialidad = cursosAsignados.first;
    await doc.reference.update({
      'cursos': cursosAsignados,
      'especialidad': especialidad,
    });
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await asignarCursosATutores();
  exit(0);
}
