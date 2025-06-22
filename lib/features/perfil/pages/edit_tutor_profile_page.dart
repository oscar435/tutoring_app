import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tutoring_app/core/utils/snackbar.dart';

class EditTutorProfilePage extends StatefulWidget {
  const EditTutorProfilePage({super.key});

  @override
  State<EditTutorProfilePage> createState() => _EditTutorProfilePageState();
}

class _EditTutorProfilePageState extends State<EditTutorProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _sobreMiController = TextEditingController();
  
  File? _imageFile;
  String? _networkImageUrl;
  bool _isLoading = false;
  
  final _picker = ImagePicker();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    _loadTutorData();
  }

  @override
  void dispose() {
    _sobreMiController.dispose();
    super.dispose();
  }

  Future<void> _loadTutorData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection('tutores').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      _sobreMiController.text = data['sobre_mi'] ?? '';
      setState(() {
        _networkImageUrl = data['photoUrl'];
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    
    final user = _auth.currentUser;
    if (user == null) {
       setState(() => _isLoading = false);
       return;
    }

    try {
      String? newPhotoUrl = _networkImageUrl;

      // 1. Upload new image if selected
      if (_imageFile != null) {
        final ref = _storage.ref().child('profile_pictures').child('${user.uid}.jpg');
        await ref.putFile(_imageFile!);
        newPhotoUrl = await ref.getDownloadURL();
      }

      // 2. Prepare data to update
      final Map<String, dynamic> dataToUpdate = {
        'sobre_mi': _sobreMiController.text,
        'photoUrl': newPhotoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // 3. Update Firestore
      await _firestore.collection('tutores').doc(user.uid).set(dataToUpdate, SetOptions(merge: true));

      if (mounted) {
        showSuccessSnackBar(context, 'Perfil actualizado exitosamente');
        Navigator.pop(context);
      }

    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'Error al actualizar el perfil: $e');
      }
    } finally {
      if(mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil de Tutor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveProfile,
            tooltip: 'Guardar Cambios',
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // --- Image Selector ---
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!)
                                : (_networkImageUrl != null && _networkImageUrl!.isNotEmpty
                                    ? NetworkImage(_networkImageUrl!)
                                    : const AssetImage('assets/teacher_avatar.jpg')) as ImageProvider,
                            backgroundColor: Colors.grey[200],
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.deepPurple,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    // --- "Sobre mí" field ---
                    TextFormField(
                      controller: _sobreMiController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Sobre Mí / Biografía',
                        hintText: 'Cuéntales a los estudiantes sobre ti, tu experiencia y tu método de enseñanza...',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        if (value != null && value.length > 500) {
                          return 'La biografía no puede exceder los 500 caracteres.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                     ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      child: const Text('Guardar Cambios', style: TextStyle(color: Colors.white)),
                    )
                  ],
                ),
              ),
            ),
    );
  }
} 