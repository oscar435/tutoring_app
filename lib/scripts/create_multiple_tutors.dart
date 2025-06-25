import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:flutter/widgets.dart';

// Datos específicos de la FIEI-UNFV
const carreras = [
  'Ingeniería Informática',
  'Ingeniería Electrónica',
  'Ingeniería Mecatrónica',
  'Ingeniería de Telecomunicaciones'
];

// Lista de tutores a crear
final List<Map<String, String>> tutores = [
  {
    'nombre': 'Pedro',
    'apellidos': 'Salas Rivera',
    'especialidad': 'Física',
    'email': 'pedro.salas@unfv.edu.pe',
  },
  {
    'nombre': 'Carmen',
    'apellidos': 'Rodríguez Pinto',
    'especialidad': 'Sistemas Digitales',
    'email': 'carmen.rodriguez@unfv.edu.pe',
  },
  {
    'nombre': 'Luis',
    'apellidos': 'García Torres',
    'especialidad': 'Electrónica de Potencia',
    'email': 'luis.garcia@unfv.edu.pe',
  },
  {
    'nombre': 'Ana',
    'apellidos': 'Pérez Díaz',
    'especialidad': 'Microcontroladores',
    'email': 'ana.perez@unfv.edu.pe',
  },
  {
    'nombre': 'Jorge',
    'apellidos': 'Mendoza Ruiz',
    'especialidad': 'Telecomunicaciones',
    'email': 'jorge.mendoza@unfv.edu.pe',
  },
  {
    'nombre': 'Patricia',
    'apellidos': 'Sánchez Luna',
    'especialidad': 'Instrumentación',
    'email': 'patricia.sanchez@unfv.edu.pe',
  },
  {
    'nombre': 'Roberto',
    'apellidos': 'Cruz Mendoza',
    'especialidad': 'Electrónica Médica',
    'email': 'roberto.cruz@unfv.edu.pe',
  },
  {
    'nombre': 'Diana',
    'apellidos': 'Flores Quispe',
    'especialidad': 'Robótica',
    'email': 'diana.flores@unfv.edu.pe',
  },
  {
    'nombre': 'Miguel',
    'apellidos': 'Torres Huamán',
    'especialidad': 'Sistemas Embebidos',
    'email': 'miguel.torres@unfv.edu.pe',
  },
  {
    'nombre': 'María',
    'apellidos': 'López Castro',
    'especialidad': 'Automatización',
    'email': 'maria.lopez@unfv.edu.pe',
  },
];

Future<void> main() async {
  // Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase sin Flutter
  await Firebase.initializeApp();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  print('Creando 10 tutores de Ingeniería Electrónica...\n');

  for (var i = 0; i < tutores.length; i++) {
    final tutor = tutores[i];
    final password = 'Unfv${tutor['nombre']!.substring(0, 3).toUpperCase()}2024!';
    try {
      // 1. Crear cuenta de autenticación
      final UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: tutor['email']!,
        password: password,
      );
      final String tutorId = userCredential.user!.uid;
      // 2. Datos del tutor para Firestore
      final Map<String, dynamic> tutorData = {
        'email': tutor['email'],
        'createdAt': Timestamp.fromDate(DateTime(2025, 6, 15, 2, 3, 21)),
        'emailVerified': true,
        'nombre': tutor['nombre'],
        'apellidos': tutor['apellidos'],
        'especialidad': tutor['especialidad'],
        'escuela': 'Ingeniería Electrónica',
        'universidad': 'Universidad Nacional Federico Villarreal',
        'facultad': 'Facultad de Ingeniería Electrónica e Informática',
      };
      // 3. Crear documento en la colección tutores
      await firestore.collection('tutores').doc(tutorId).set(tutorData);
      // 4. Crear referencia en users
      await firestore.collection('users').doc(tutorId).set({
        'email': tutor['email'],
        'isTeacher': true,
        'createdAt': Timestamp.fromDate(DateTime(2025, 6, 15, 2, 3, 21)),
      });
      print('''\n✅ Tutor creado exitosamente:\n   Nombre: ${tutor['nombre']} ${tutor['apellidos']}\n   Email: ${tutor['email']}\n   Contraseña: $password\n   ID: $tutorId\n''');
    } catch (e) {
      print('❌ Error al crear tutor ${tutor['nombre']}: $e');
    }
  }
  print('Proceso completado.');
  exit(0);
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
} 