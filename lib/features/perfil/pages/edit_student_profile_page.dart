import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditStudentProfilePage extends StatefulWidget {
  const EditStudentProfilePage({Key? key}) : super(key: key);

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
    final doc = await FirebaseFirestore.instance.collection('estudiantes').doc(user!.uid).get();
    if (doc.exists) {
      setState(() {
        _userData = doc.data();
      });
    }
  }

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
      if (user == null) return null;
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child('${user!.uid}.jpg');
      await ref.putFile(image);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error al subir imagen: $e');
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
    await FirebaseFirestore.instance.collection('estudiantes').doc(user!.uid).set({
      ..._userData!,
      'photoUrl': photoUrl,
    }, SetOptions(merge: true));
    setState(() => _isLoading = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_userData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Perfil')),
      backgroundColor: const Color(0xfff7f7f7),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!)
                      : (_userData!['photoUrl'] != null && _userData!['photoUrl'].isNotEmpty)
                          ? NetworkImage(_userData!['photoUrl'])
                          : const AssetImage('assets/avatar.jpg') as ImageProvider,
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.edit, size: 20, color: Colors.purple),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildTextField('Nombre', 'nombre', _userData!['nombre']),
              _buildTextField('Apellidos', 'apellidos', _userData!['apellidos']),
              _buildTextField('Edad', 'edad', _userData!['edad']?.toString(), isNumber: true),
              _buildTextField('Código de estudiante', 'codigo_estudiante', _userData!['codigo_estudiante']),
              _buildTextField('Especialidad', 'especialidad', _userData!['especialidad']),
              _buildTextField('Ciclo académico', 'ciclo', _userData!['ciclo']),
              _buildTextField('Universidad', 'universidad', _userData!['universidad']),
              const SizedBox(height: 30),
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text('Guardar Cambios'),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String key, String? initialValue, {bool isNumber = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        initialValue: initialValue ?? '',
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (value) => (value == null || value.isEmpty) ? 'Campo requerido' : null,
        onSaved: (value) => _userData![key] = isNumber ? int.tryParse(value ?? '') ?? 0 : value,
      ),
    );
  }
} 