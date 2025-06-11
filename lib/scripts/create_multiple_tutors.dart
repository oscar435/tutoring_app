import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:io';

// Datos específicos de la FIEI-UNFV
const carreras = [
  'Ingeniería Informática',
  'Ingeniería Electrónica',
  'Ingeniería Mecatrónica',
  'Ingeniería de Telecomunicaciones'
];

// Lista de tutores a crear
final tutores = [
  {
    'nombre': 'Carlos',
    'apellidos': 'Mendoza Ramírez',
    'especialidad': 'Desarrollo de Software',
    'carrera': 'Ingeniería Informática',
  },
  {
    'nombre': 'Ana María',
    'apellidos': 'Pacheco Torres',
    'especialidad': 'Inteligencia Artificial',
    'carrera': 'Ingeniería Informática',
  },
  {
    'nombre': 'Luis',
    'apellidos': 'García Vásquez',
    'especialidad': 'Redes y Seguridad',
    'carrera': 'Ingeniería Informática',
  },
  {
    'nombre': 'Miguel',
    'apellidos': 'Torres Huamán',
    'especialidad': 'Sistemas Embebidos',
    'carrera': 'Ingeniería Electrónica',
  },
  {
    'nombre': 'Patricia',
    'apellidos': 'Sánchez Luna',
    'especialidad': 'Automatización Industrial',
    'carrera': 'Ingeniería Electrónica',
  },
  {
    'nombre': 'Roberto',
    'apellidos': 'Cruz Mendoza',
    'especialidad': 'Microelectrónica',
    'carrera': 'Ingeniería Electrónica',
  },
  {
    'nombre': 'Diana',
    'apellidos': 'Flores Quispe',
    'especialidad': 'Robótica Industrial',
    'carrera': 'Ingeniería Mecatrónica',
  },
  {
    'nombre': 'Jorge',
    'apellidos': 'Ramos Silva',
    'especialidad': 'Sistemas de Control',
    'carrera': 'Ingeniería Mecatrónica',
  },
  {
    'nombre': 'María',
    'apellidos': 'López Castro',
    'especialidad': 'Automatización y PLC',
    'carrera': 'Ingeniería Mecatrónica',
  },
  {
    'nombre': 'Fernando',
    'apellidos': 'Vargas Ruiz',
    'especialidad': 'Redes 5G',
    'carrera': 'Ingeniería de Telecomunicaciones',
  },
  {
    'nombre': 'Claudia',
    'apellidos': 'Morales Díaz',
    'especialidad': 'Comunicaciones Satelitales',
    'carrera': 'Ingeniería de Telecomunicaciones',
  },
  {
    'nombre': 'Ricardo',
    'apellidos': 'Pérez Wong',
    'especialidad': 'Sistemas de Comunicación',
    'carrera': 'Ingeniería de Telecomunicaciones',
  },
  {
    'nombre': 'Andrea',
    'apellidos': 'Castro Medina',
    'especialidad': 'Base de Datos',
    'carrera': 'Ingeniería Informática',
  },
  {
    'nombre': 'José',
    'apellidos': 'Martínez Chávez',
    'especialidad': 'IoT y Redes de Sensores',
    'carrera': 'Ingeniería Electrónica',
  },
  {
    'nombre': 'Carmen',
    'apellidos': 'Rodríguez Pinto',
    'especialidad': 'Sistemas Digitales',
    'carrera': 'Ingeniería Electrónica',
  }
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Inicializar Firebase
    await Firebase.initializeApp();
    
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final FirebaseAuth auth = FirebaseAuth.instance;
    
    print('Creando 15 tutores de la FIEI-UNFV...\n');

    for (var tutor in tutores) {
      // Generar email basado en el nombre y apellido
      final nombreEmail = tutor['nombre']!.toLowerCase().replaceAll(' ', '');
      final apellidoEmail = tutor['apellidos']!.split(' ')[0].toLowerCase();
      final email = '$nombreEmail.$apellidoEmail@unfv.edu.pe';
      
      // Contraseña segura basada en el nombre
      final password = 'Unfv${nombreEmail.capitalize()}2024!';

      try {
        // 1. Crear cuenta de autenticación
        final UserCredential userCredential = await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        final String tutorId = userCredential.user!.uid;

        // 2. Datos del tutor para Firestore
        final Map<String, dynamic> tutorData = {
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'emailVerified': true,
          'nombre': tutor['nombre'],
          'apellidos': tutor['apellidos'],
          'especialidad': tutor['especialidad'],
          'carrera': tutor['carrera'],
          'universidad': 'Universidad Nacional Federico Villarreal',
          'facultad': 'Facultad de Ingeniería Electrónica e Informática',
        };

        // 3. Crear documento en la colección tutores
        await firestore.collection('tutores').doc(tutorId).set(tutorData);

        // 4. Crear referencia en users
        await firestore.collection('users').doc(tutorId).set({
          'email': email,
          'isTeacher': true,
          'createdAt': FieldValue.serverTimestamp(),
        });

        print('''
✅ Tutor creado exitosamente:
   Nombre: ${tutor['nombre']} ${tutor['apellidos']}
   Carrera: ${tutor['carrera']}
   Email: $email
   Contraseña: $password
   ID: $tutorId
''');
      } catch (e) {
        print('❌ Error al crear tutor ${tutor['nombre']}: $e');
      }
    }

    print('Proceso completado.');
    exit(0);
  } catch (e) {
    print('Error general: $e');
    exit(1);
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
} 