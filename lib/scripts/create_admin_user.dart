import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../core/services/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const AdminCreatorApp());
}

class AdminCreatorApp extends StatelessWidget {
  const AdminCreatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: AdminCreatorPage(),
    );
  }
}

class AdminCreatorPage extends StatefulWidget {
  const AdminCreatorPage({super.key});

  @override
  State<AdminCreatorPage> createState() => _AdminCreatorPageState();
}

class _AdminCreatorPageState extends State<AdminCreatorPage> {
  bool _isCreating = true;
  String _status = 'Creando usuario administrador...';

  @override
  void initState() {
    super.initState();
    _createAdminUser();
  }

  Future<void> _createAdminUser() async {
    try {
      // Crear el usuario en Firebase Auth
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: 'admin@unfv.edu.pe',
        password: 'AdminUnfv2024!',
      );

      setState(() => _status = 'Usuario creado en Auth, creando en Firestore...');

      // Crear el documento del usuario en Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'email': 'admin@unfv.edu.pe',
        'role': 'superAdmin',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'nombre': 'Super Administrador',
        'apellido': 'UNFV',
      });

      setState(() {
        _isCreating = false;
        _status = '''
Usuario administrador creado exitosamente

Email: admin@unfv.edu.pe
Password: AdminUnfv2024!

Puedes cerrar esta ventana y acceder al panel de administración.''';
      });
    } catch (e) {
      setState(() {
        _isCreating = false;
        _status = 'Error al crear usuario administrador: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isCreating) const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 