import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class IncidentReportsPage extends StatelessWidget {
  const IncidentReportsPage({super.key});

  Future<Map<String, dynamic>?> _fetchSesion(String sesionId) async {
    final doc = await FirebaseFirestore.instance
        .collection('sesiones_tutoria')
        .doc(sesionId)
        .get();
    if (doc.exists) return doc.data();
    return null;
  }

  Future<String> _fetchNombreUsuario(String uid) async {
    if (uid.isEmpty) return '-';
    // Buscar en tutores y estudiantes
    final docTutor = await FirebaseFirestore.instance
        .collection('tutores')
        .doc(uid)
        .get();
    if (docTutor.exists) {
      final data = docTutor.data();
      return ((data?['nombre'] ?? '') + ' ' + (data?['apellidos'] ?? ''))
          .trim();
    }
    final docEst = await FirebaseFirestore.instance
        .collection('estudiantes')
        .doc(uid)
        .get();
    if (docEst.exists) {
      final data = docEst.data();
      return ((data?['nombre'] ?? '') + ' ' + (data?['apellidos'] ?? ''))
          .trim();
    }
    return uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reportes de Incidentes')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reportes_incidentes')
            .orderBy('fecha', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No hay reportes de incidentes.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return FutureBuilder<Map<String, dynamic>?>(
                future: _fetchSesion(data['sesionId'] ?? ''),
                builder: (context, sesionSnap) {
                  final sesion = sesionSnap.data;
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.flag,
                        color: data['anonimo'] == true
                            ? Colors.grey
                            : Colors.redAccent,
                      ),
                      title: Text(data['tipo'] ?? 'Incidente'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fecha: ${data['fecha'] != null ? (data['fecha'] as Timestamp).toDate().toString().substring(0, 16) : '-'}',
                          ),
                          Text(
                            'Usuario: ${data['anonimo'] == true ? 'Anónimo' : (data['usuarioId'] ?? '-')}',
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
                          if (sesion != null) ...[
                            const Divider(),
                            Text('Sesión: ${sesion['curso'] ?? '-'}'),
                            if (sesion['fechaSesion'] != null)
                              Text(
                                'Fecha: ${(sesion['fechaSesion'] as Timestamp).toDate().toString().substring(0, 16)}',
                              ),
                            FutureBuilder<String>(
                              future: _fetchNombreUsuario(
                                sesion['tutorId'] ?? '',
                              ),
                              builder: (context, snap) =>
                                  Text('Tutor: ${snap.data ?? '-'}'),
                            ),
                            FutureBuilder<String>(
                              future: _fetchNombreUsuario(
                                sesion['estudianteId'] ?? '',
                              ),
                              builder: (context, snap) =>
                                  Text('Estudiante: ${snap.data ?? '-'}'),
                            ),
                          ],
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.reply),
                        tooltip: 'Responder',
                        onPressed: () async {
                          final TextEditingController controller =
                              TextEditingController();
                          await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Responder al reporte'),
                              content: TextField(
                                controller: controller,
                                decoration: const InputDecoration(
                                  labelText: 'Respuesta (opcional)',
                                ),
                                maxLines: 3,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cancelar'),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    await docs[i].reference.update({
                                      'respuesta': controller.text,
                                    });
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Enviar'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      onTap: () {},
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
