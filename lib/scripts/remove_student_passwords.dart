import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:tutoring_app/core/services/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;
  final studentsRef = firestore.collection('estudiantes');
  int updatedCount = 0;

  print('--- Iniciando limpieza de contraseñas de estudiantes ---');

  try {
    final snapshot = await studentsRef.get();
    if (snapshot.docs.isEmpty) {
      print('No se encontraron estudiantes.');
      return;
    }

    print('Se encontraron ${snapshot.docs.length} estudiantes.');
    final batch = firestore.batch();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      
      // Comprobar si el campo 'password' existe en el documento
      if ((data).containsKey('password')) {
        print('Se encontró contraseña en el estudiante con ID: ${doc.id}. Programando eliminación.');
        // Usar FieldValue.delete() para eliminar el campo
        batch.update(doc.reference, {'password': FieldValue.delete()});
        updatedCount++;
      }
    }

    if (updatedCount > 0) {
      print('\nConfirmando la eliminación de $updatedCount campos de contraseña...');
      await batch.commit();
      print('¡Éxito! $updatedCount documentos de estudiantes han sido limpiados.');
    } else {
      print('\nNo se encontraron contraseñas para eliminar. Todos los documentos ya son seguros.');
    }

  } catch (e) {
    print('\n--- ERROR DURANTE LA LIMPIEZA ---');
    print(e);
    print('La limpieza falló. No se realizaron cambios en la base de datos.');
  }

  print('--- Proceso de limpieza finalizado ---');
} 