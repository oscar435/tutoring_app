import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:tutoring_app/core/services/firebase_options.dart';

Future<void> main() async {
  // --- BOILERPLATE FOR FIREBASE INITIALIZATION ---
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final firestore = FirebaseFirestore.instance;
  final tutorsRef = firestore.collection('tutores');
  int updatedCount = 0;

  try {
    final snapshot = await tutorsRef.get();
    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch = firestore.batch();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final Map<String, dynamic> dataToUpdate = {};
      bool needsUpdate = false;

      // --- CHECK FOR EACH FIELD AND ADD IF MISSING ---

      if (data['sobre_mi'] == null) {
        dataToUpdate['sobre_mi'] = '';
        needsUpdate = true;
      }

      if (data['emailVerified'] == null) {
        dataToUpdate['emailVerified'] = true;
        needsUpdate = true;
      }

      dataToUpdate['updatedAt'] = FieldValue.serverTimestamp();

      if (data['createdAt'] == null) {
        dataToUpdate['createdAt'] = FieldValue.serverTimestamp();
        needsUpdate = true;
      }

      if (data['facultad'] == null) {
        dataToUpdate['facultad'] =
            'Facultad de Ingeniería Electrónica e Informática';
        needsUpdate = true;
      }

      if (data['universidad'] == null) {
        dataToUpdate['universidad'] =
            'Universidad Nacional Federico Villarreal';
        needsUpdate = true;
      }

      if (data['photoUrl'] == null) {
        dataToUpdate['photoUrl'] = '';
        needsUpdate = true;
      }

      if (needsUpdate) {
        batch.update(doc.reference, dataToUpdate);
        updatedCount++;
      }
    }

    if (updatedCount > 0) {
      await batch.commit();
    }
  } catch (e) {
    print('--- ERROR DURANTE LA MIGRACIÓN ---');
    print(e);
    print('La migración falló. No se realizaron cambios en la base de datos.');
  }

  print('--- Proceso de migración finalizado ---');
}
