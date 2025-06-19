import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MisEstudiantesPage extends StatelessWidget {
  final String tutorId;
  const MisEstudiantesPage({required this.tutorId, Key? key}) : super(key: key);

  Future<List<Map<String, dynamic>>> _obtenerEstudiantes() async {
    final sesionesSnap = await FirebaseFirestore.instance
        .collection('sesiones_tutoria')
        .where('tutorId', isEqualTo: tutorId)
        .where('estado', isEqualTo: 'aceptada')
        .get();
    final sesiones = sesionesSnap.docs.map((doc) => doc.data()).toList();
    final ids = sesiones.map((s) => s['estudianteId'] as String).toSet().toList();
    if (ids.isEmpty) return [];
    final estudiantesSnap = await FirebaseFirestore.instance
        .collection('estudiantes')
        .where(FieldPath.documentId, whereIn: ids)
        .get();
    return estudiantesSnap.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  void _mostrarPerfilEstudiante(BuildContext context, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundImage: (data['photoUrl'] ?? '').toString().isNotEmpty
                    ? NetworkImage(data['photoUrl'])
                    : const AssetImage('assets/avatar.jpg') as ImageProvider,
              ),
              const SizedBox(height: 18),
              Text(
                '${data['nombre'] ?? ''} ${data['apellidos'] ?? ''}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              if (data['codigo_estudiante'] != null)
                _infoRow(Icons.badge, 'Código', data['codigo_estudiante']),
              if (data['especialidad'] != null)
                _infoRow(Icons.school, 'Escuela', data['especialidad']),
              if (data['ciclo'] != null)
                _infoRow(Icons.timeline, 'Ciclo académico', data['ciclo']),
              if (data['email'] != null)
                _infoRow(Icons.email, 'Correo', data['email']),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Estudiantes')),
      backgroundColor: const Color(0xfff7f7f7),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _obtenerEstudiantes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No tienes estudiantes aún.'));
          }
          final estudiantes = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: estudiantes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final est = estudiantes[index];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: (est['photoUrl'] ?? '').toString().isNotEmpty
                        ? NetworkImage(est['photoUrl'])
                        : const AssetImage('assets/avatar.jpg') as ImageProvider,
                  ),
                  title: Text('${est['nombre'] ?? ''} ${est['apellidos'] ?? ''}'),
                  subtitle: Text(est['correo'] ?? ''),
                  onTap: () => _mostrarPerfilEstudiante(context, est),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 