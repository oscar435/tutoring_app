import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterProfilePhotoPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const RegisterProfilePhotoPage({super.key, required this.userData});

  @override
  State<RegisterProfilePhotoPage> createState() => _RegisterProfilePhotoPageState();
}

class _RegisterProfilePhotoPageState extends State<RegisterProfilePhotoPage> {
  File? _imageFile;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child('${user.uid}.jpg');

      await ref.putFile(image);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error al subir imagen: $e');
      return null;
    }
  }

  Future<void> _finishRegistration({bool skipPhoto = false}) async {
    setState(() => _isLoading = true);

    String? photoUrl;
    if (!skipPhoto && _imageFile != null) {
      photoUrl = await _uploadImage(_imageFile!);
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('estudiantes').doc(user.uid).set({
        ...widget.userData,
        'photoUrl': photoUrl ?? '', // Guarda la URL o vacío si no hay foto
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    setState(() => _isLoading = false);

    // Aquí navega a la pantalla de felicitaciones o Home
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CongratsPage(), // Reemplaza con tu pantalla de felicitaciones
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f7f7),
      appBar: AppBar(title: const Text('Subir foto')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 70,
                backgroundColor: Colors.purple[100],
                backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                child: _imageFile == null
                    ? const Icon(Icons.camera_alt, size: 50, color: Colors.purple)
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Haga clic en Círculo para Cargar su foto',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            if (_isLoading)
              const CircularProgressIndicator()
            else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _finishRegistration(skipPhoto: true),
                      child: const Text('Saltar para más tarde'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _imageFile != null ? () => _finishRegistration() : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text('Continuar'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Pantalla de felicitaciones
class CongratsPage extends StatelessWidget {
  const CongratsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 100),
            const SizedBox(height: 20),
            const Text('¡Felicidades!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text('Se ha inscrito correctamente.'),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Navega al HomePage
                Navigator.of(context).pushReplacementNamed('/home2');
              },
              child: const Text('Ir a Inicio'),
            ),
          ],
        ),
      ),
    );
  }
} 