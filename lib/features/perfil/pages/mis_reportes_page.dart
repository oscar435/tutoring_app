import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MisReportesPage extends StatelessWidget {
  const MisReportesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('No autenticado.')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Mis reportes')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reportes_incidentes')
            .where('usuarioId', isEqualTo: user.uid)
            .orderBy('fecha', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No has enviado reportes.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  leading: Icon(Icons.flag, color: Colors.redAccent),
                  title: Text(data['tipo'] ?? 'Incidente'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fecha: ${data['fecha'] != null ? (data['fecha'] as Timestamp).toDate().toString().substring(0, 16) : '-'}',
                      ),
                      if ((data['ubicacion'] ?? '').isNotEmpty)
                        Text('Ubicación: ${data['ubicacion']}'),
                      if ((data['descripcion'] ?? '').isNotEmpty)
                        Text('Descripción: ${data['descripcion']}'),
                      if ((data['imagen'] ?? '').isNotEmpty) ...[
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () {
                            if (data['imagen'] != null) {
                              showDialog(
                                context: context,
                                builder: (context) => Dialog(
                                  child: Image.network(data['imagen']),
                                ),
                              );
                            }
                          },
                          child: Text(
                            'Ver imagen adjunta',
                            style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      if ((data['respuesta'] ?? '').isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Respuesta del admin: ${data['respuesta']}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        const Text(
                          'Sin respuesta del admin',
                          style: TextStyle(color: Colors.grey),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
