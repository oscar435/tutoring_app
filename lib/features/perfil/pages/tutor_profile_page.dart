import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutoring_app/features/perfil/pages/edit_tutor_profile_page.dart';

class TutorProfilePage extends StatelessWidget {
  const TutorProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Perfil de Tutor')),
        body: const Center(child: Text('No autenticado')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil de Tutor')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('tutores').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar datos'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final nombre = data['nombre'] ?? '';
          final apellidos = data['apellidos'] ?? '';
          final especialidad = data['especialidad'] ?? '';
          final escuela = data['escuela'] ?? especialidad;
          final email = data['email'] ?? '';
          final emailVerified = data['emailVerified'] ?? false;
          final photoUrl = data['photoUrl'] ?? '';
          final universidad = data['universidad'] ?? '';
          final facultad = data['facultad'] ?? '';
          final cursos = (data['cursos'] as List?)?.cast<String>() ?? [];
          final sobreMi = data['sobre_mi'] as String?;
          final createdAt = data['createdAt'];
          String fechaCreacion = '';
          if (createdAt != null) {
            if (createdAt is String) {
              fechaCreacion = createdAt;
            } else if (createdAt is Timestamp) {
              final dt = createdAt.toDate();
              fechaCreacion = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
            }
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundImage: photoUrl.isNotEmpty
                      ? NetworkImage(photoUrl)
                      : const AssetImage('assets/teacher_avatar.jpg') as ImageProvider,
                ),
                const SizedBox(height: 18),
                Text(
                  '$nombre $apellidos',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                if (sobreMi != null && sobreMi.isNotEmpty) ...[
                  Text(
                    sobreMi,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.grey[700], fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 10),
                ],
                _infoRow(Icons.email, 'Correo', email),
                _infoRow(Icons.school, 'Escuela', escuela),
                _infoRow(Icons.star, 'Especialidad', especialidad),
                if (facultad.isNotEmpty)
                  _infoRow(Icons.account_balance, 'Facultad', facultad),
                if (universidad.isNotEmpty)
                  _infoRow(Icons.account_balance_outlined, 'Universidad', universidad),
                if (cursos.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: cursos.map((c) => Chip(label: Text(c), backgroundColor: Colors.deepPurple[50])).toList(),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
       floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EditTutorProfilePage()),
          );
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.edit, color: Colors.white),
        tooltip: 'Editar Perfil',
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple, size: 22),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
} 