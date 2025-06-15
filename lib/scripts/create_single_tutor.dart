import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:io';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final FirebaseAuth auth = FirebaseAuth.instance;

    // Cambia estos datos para el nuevo tutor
    const String nombre = 'Sofía';
    const String apellidos = 'Gómez Torres';
    const String especialidad = 'Cálculo y Álgebra';
    const String carrera = 'Ingeniería Informática';
    const String email = 'sofia.gomez@unfv.edu.pe';
    const String password = 'UnfvSofia2024!';

    print('Creando cuenta de tutor...');

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
      'nombre': nombre,
      'apellidos': apellidos,
      'especialidad': especialidad,
      'carrera': carrera,
      'universidad': 'Universidad Nacional Federico Villarreal',
      'facultad': 'Facultad de Ingeniería Electrónica e Informática',
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

    print('''\n¡Tutor creado exitosamente!\nEmail: $email\nContraseña: $password\nID: $tutorId\n''');
    exit(0);
  } catch (e) {
    print('Error al crear tutor: $e');
    exit(1);
  }
}