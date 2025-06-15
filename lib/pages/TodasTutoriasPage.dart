import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tutoring_app/models/solicitud_tutoria.dart';
import 'package:tutoring_app/service/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TodasTutoriasPage extends StatelessWidget {
  const TodasTutoriasPage({super.key});

  @override
  Widget build(BuildContext context) {
    initializeDateFormatting('es_ES', null);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No hay usuario logueado')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Todas mis tutorías'),
      ),
      body: StreamBuilder<List<SolicitudTutoria>>(
        stream: _obtenerTodasTutorias(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final tutorias = snapshot.data ?? [];
          if (tutorias.isEmpty) {
            return const Center(
              child: Text('No tienes tutorías agendadas'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tutorias.length,
            itemBuilder: (context, index) {
              final tutoria = tutorias[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: Text(tutoria.curso ?? 'Sin curso'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fecha: '
                        '${tutoria.fechaSesion != null ? DateFormat('EEEE d MMMM', 'es_ES').format(tutoria.fechaSesion!) : 'Sin fecha'}',
                      ),
                      Text(
                        'Hora: '
                        '${tutoria.fechaSesion != null ? DateFormat('HH:mm').format(tutoria.fechaSesion!) : 'Sin hora'}',
                      ),
                      Text(
                        'Estado: ${tutoria.estado}',
                        style: TextStyle(
                          color: tutoria.estado == 'aceptada'
                              ? Colors.green
                              : tutoria.estado == 'pendiente'
                                  ? Colors.orange
                                  : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  onTap: () => _mostrarDetalleTutoria(context, tutoria),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Stream<List<SolicitudTutoria>> _obtenerTodasTutorias(String userId) {
    return FirebaseFirestore.instance
        .collection('solicitudes_tutoria')
        .where('estudianteId', isEqualTo: userId)
        .orderBy('fechaHora', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SolicitudTutoria.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    });
  }

  void _mostrarDetalleTutoria(BuildContext context, SolicitudTutoria tutoria) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Icon(
                    Icons.drag_handle,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  tutoria.curso ?? 'Sin curso',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildInfoRow(
                  'Fecha',
                  tutoria.fechaSesion != null
                      ? DateFormat('EEEE d MMMM', 'es_ES').format(tutoria.fechaSesion!)
                      : 'Sin fecha',
                ),
                _buildInfoRow(
                  'Hora',
                  tutoria.fechaSesion != null
                      ? DateFormat('HH:mm').format(tutoria.fechaSesion!)
                      : 'Sin hora',
                ),
                _buildInfoRow('Estado', tutoria.estado),
                if (tutoria.mensaje != null && tutoria.mensaje!.isNotEmpty)
                  _buildInfoRow('Mensaje', tutoria.mensaje!),
                const SizedBox(height: 20),
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('tutores')
                      .doc(tutoria.tutorId)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final tutorData = snapshot.data!.data() as Map<String, dynamic>;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tutor',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text('${tutorData['nombre']} ${tutorData['apellidos']}'),
                          Text(tutorData['escuela'] ?? ''),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
} 