import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:io';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Inicializar Firebase
    await Firebase.initializeApp();
    
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final FirebaseAuth auth = FirebaseAuth.instance;
    
    print('Creando cuenta de tutor completa...');

    // Datos del tutor
    const String email = 'tutor.prueba@unfv.edu.pe';
    const String password = 'Tutor123!'; // Contraseña segura para pruebas

    // 1. Crear cuenta de autenticación
    final UserCredential userCredential = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final String tutorId = userCredential.user!.uid;
    print('✅ Cuenta de autenticación creada con ID: $tutorId');

    // 2. Datos del tutor para Firestore
    final Map<String, dynamic> tutorData = {
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      'emailVerified': true,
      'nombre': 'Juan',
      'apellidos': 'Pérez',
      'especialidad': 'Matemáticas',
      'universidad': 'UNFV',
    };

    // 3. Crear documento en la colección tutores
    await firestore.collection('tutores').doc(tutorId).set(tutorData);
    print('✅ Datos guardados en colección tutores');

    // 4. Crear referencia en users
    await firestore.collection('users').doc(tutorId).set({
      'email': email,
      'isTeacher': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    print('✅ Referencia creada en users');

    print('''
¡Tutor creado exitosamente!
Email: $email
Contraseña: $password
ID: $tutorId
''');
    exit(0);
  } catch (e) {
    print('Error al crear tutor: $e');
    exit(1);
  }
} 