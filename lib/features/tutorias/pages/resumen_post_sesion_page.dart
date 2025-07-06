import 'package:flutter/material.dart';
import 'package:tutoring_app/core/models/registro_post_sesion.dart';
import 'package:tutoring_app/features/tutorias/services/registro_post_sesion_service.dart';

class ResumenPostSesionPage extends StatelessWidget {
  final String sesionId;
  const ResumenPostSesionPage({Key? key, required this.sesionId})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen Post-Sesión'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<RegistroPostSesion?>(
        future: RegistroPostSesionService().obtenerRegistroPorSesion(sesionId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final registro = snapshot.data;
          if (registro == null) {
            return const Center(
              child: Text('No se encontró el registro post-sesión.'),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              ListTile(
                leading: const Icon(Icons.topic, color: Colors.blue),
                title: const Text('Temas Tratados'),
                subtitle: Text(registro.temasTratados.join(', ')),
              ),
              ListTile(
                leading: const Icon(Icons.lightbulb, color: Colors.amber),
                title: const Text('Recomendaciones'),
                subtitle: Text(registro.recomendaciones),
              ),
              ListTile(
                leading: const Icon(Icons.notes, color: Colors.green),
                title: const Text('Observaciones'),
                subtitle: Text(registro.observaciones),
              ),
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Asistencia'),
                subtitle: Text(
                  registro.asistioEstudiante ? 'Asistió' : 'No asistió',
                ),
              ),
              if (registro.comentariosAdicionales.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.comment, color: Colors.indigo),
                  title: const Text('Comentarios Adicionales'),
                  subtitle: Text(registro.comentariosAdicionales),
                ),
            ],
          );
        },
      ),
    );
  }
}
