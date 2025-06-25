import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

// Lista de cursos agrupados por áreas coherentes (ejemplo)
const Map<String, List<String>> areasCursos = {
  'Matemáticas': [
    'Matemática Discreta',
    'Matemática Básica',
    'Cálculo Integral',
    'Fundamentos de Cálculo',
    'Matemática Aplicada',
    'Estadística',
    'Lógica Digital',
  ],
  'Programación': [
    'Lenguaje de Programación I',
    'Lenguaje de Programación II',
    'Programación en Dispositivos Móviles',
    'Sistemas Operativos',
    'Estructura de Datos',
    'Algoritmos',
    'Inteligencia Artificial',
  ],
  'Bases de Datos': [
    'Base de Datos I',
    'Base de Datos II',
    'Administración de Base de Datos',
    'Dinámica de Sistemas de Información',
  ],
  'Redes y Sistemas': [
    'Redes y Conectividad',
    'Teleinformática',
    'Gestión y Análisis de Datos e Información',
    'Seguridad y Auditoría Informática',
    'Tecnologías Emergentes',
  ],
  'Gestión y Negocios': [
    'Ingeniería de Sistemas de Información',
    'Gestión de Proyectos',
    'Gerencia y Consultoría Informática',
    'Prospectiva Empresarial',
    'Tecnologías de Business Intelligence',
  ],
};

Future<void> main() async {
  final firestore = FirebaseFirestore.instance;
  final tutores = await firestore.collection('tutores').get();
  final random = Random();

  for (final doc in tutores.docs) {
    // Elegir un área al azar
    final area = areasCursos.keys.elementAt(random.nextInt(areasCursos.length));
    final cursosArea = areasCursos[area]!;
    // Elegir 3 cursos distintos del área
    final cursos = <String>{};
    while (cursos.length < 3) {
      cursos.add(cursosArea[random.nextInt(cursosArea.length)]);
    }
    await firestore.collection('tutores').doc(doc.id).update({
      'cursos': cursos.toList(),
      'areaEspecialidad': area,
    });
  }
}
