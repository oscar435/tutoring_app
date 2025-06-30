import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tutoring_app/features/perfil/pages/edit_student_profile_page.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  File? _imageFile;
  bool _isUploading = false;

  Future<void> _pickAndUploadImage(String uid) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (pickedFile != null) {
      setState(() => _isUploading = true);
      _imageFile = File(pickedFile.path);
      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_photos')
            .child('$uid.jpg');
        await ref.putFile(_imageFile!);
        final photoUrl = await ref.getDownloadURL();
        await FirebaseFirestore.instance
            .collection('estudiantes')
            .doc(uid)
            .update({'photoUrl': photoUrl});
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al subir la foto: $e')));
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No hay usuario logueado')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil de Estudiante')),
      backgroundColor: const Color(0xfff7f7f7),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('estudiantes')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar datos'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final photoUrl = data['photoUrl'] ?? '';
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.orange),
                    tooltip: 'Cambiar foto de perfil',
                    onPressed: _isUploading
                        ? null
                        : () => _pickAndUploadImage(user.uid),
                  ),
                ),
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : (photoUrl.isNotEmpty
                                  ? NetworkImage(photoUrl)
                                  : const AssetImage('assets/avatar.jpg')
                                        as ImageProvider),
                      ),
                      if (_isUploading) const CircularProgressIndicator(),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '${data['nombre'] ?? ''} ${data['apellidos'] ?? ''}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  data['email'] ?? '',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                _buildProfileItem(
                  'Código de estudiante',
                  data['codigo_estudiante'],
                ),
                _buildProfileItem('Especialidad', data['especialidad']),
                _buildProfileItem('Ciclo académico', data['ciclo']),
                _buildProfileItem('Universidad', data['universidad']),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileItem(String label, String? value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.08 * 255).toInt()),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value ?? '-', style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
