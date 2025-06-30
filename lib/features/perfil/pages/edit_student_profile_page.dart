import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditStudentProfilePage extends StatefulWidget {
  const EditStudentProfilePage({super.key});

  @override
  State<EditStudentProfilePage> createState() => _EditStudentProfilePageState();
}

class _EditStudentProfilePageState extends State<EditStudentProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? _userData;
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('estudiantes')
        .doc(user!.uid)
        .get();
    if (doc.exists) {
      setState(() {
        _userData = doc.data();
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      if (user == null) return null;
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child('${user!.uid}.jpg');
      await ref.putFile(image);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    _formKey.currentState!.save();
    String? photoUrl = _userData?['photoUrl'] ?? '';
    if (_imageFile != null) {
      final uploadedUrl = await _uploadImage(_imageFile!);
      if (uploadedUrl != null) photoUrl = uploadedUrl;
    }
    await FirebaseFirestore.instance
        .collection('estudiantes')
        .doc(user!.uid)
        .set({..._userData!, 'photoUrl': photoUrl}, SetOptions(merge: true));
    setState(() => _isLoading = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_userData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Perfil de Estudiante')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 70,
                backgroundColor: Colors.purple[100],
                backgroundImage: _imageFile != null
                    ? FileImage(_imageFile!)
                    : (_userData?['photoUrl'] ?? '').toString().isNotEmpty
                    ? NetworkImage(_userData!['photoUrl'])
                    : const AssetImage('assets/avatar.jpg') as ImageProvider,
                child:
                    _imageFile == null &&
                        (_userData?['photoUrl'] ?? '').toString().isEmpty
                    ? const Icon(
                        Icons.camera_alt,
                        size: 50,
                        color: Colors.purple,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Haz clic en la foto para cambiarla',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),
            _infoRow(Icons.person, 'Nombre', _userData?['nombre'] ?? ''),
            _infoRow(
              Icons.person_outline,
              'Apellidos',
              _userData?['apellidos'] ?? '',
            ),
            _infoRow(
              Icons.badge,
              'Código de estudiante',
              _userData?['codigo_estudiante'] ?? '',
            ),
            _infoRow(
              Icons.school,
              'Especialidad',
              _userData?['especialidad'] ?? '',
            ),
            _infoRow(
              Icons.looks_one,
              'Ciclo académico',
              _userData?['ciclo'] ?? '',
            ),
            _infoRow(
              Icons.location_city,
              'Universidad',
              _userData?['universidad'] ?? '',
            ),
            _infoRow(Icons.email, 'Correo', _userData?['email'] ?? ''),
            const SizedBox(height: 40),
            _isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text('Guardar foto de perfil'),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
