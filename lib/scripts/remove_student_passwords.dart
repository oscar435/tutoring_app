import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:tutoring_app/core/services/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final firestore = FirebaseFirestore.instance;
  final studentsRef = firestore.collection('estudiantes');
  int updatedCount = 0;

  final snapshot = await studentsRef.get();
  final batch = firestore.batch();

  for (final doc in snapshot.docs) {
    final data = doc.data();

    // Comprobar si el campo 'password' existe en el documento
    if ((data).containsKey('password')) {
      batch.update(doc.reference, {'password': FieldValue.delete()});
      updatedCount++;
    }
  }

  if (updatedCount > 0) {
    await batch.commit();
  }
}
