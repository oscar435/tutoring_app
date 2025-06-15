import 'package:flutter/material.dart';
import '../models/solicitud_tutoria.dart';
import '../service/solicitud_tutoria_service.dart';
import 'package:intl/intl.dart';

class SolicitudesTutorPage extends StatefulWidget {
  final String tutorId;
  const SolicitudesTutorPage({required this.tutorId, super.key});

  @override
  State<SolicitudesTutorPage> createState() => _SolicitudesTutorPageState();
}

class _SolicitudesTutorPageState extends State<SolicitudesTutorPage> {
  late Future<List<Map<String, dynamic>>> _solicitudesFuture;

  @override
  void initState() {
    super.initState();
    _solicitudesFuture = SolicitudTutoriaService().obtenerSolicitudesConNombres(widget.tutorId);
  }

  Future<void> _actualizarEstado(String solicitudId, String nuevoEstado) async {
    await SolicitudTutoriaService().actualizarEstado(solicitudId, nuevoEstado);
    setState(() {
      _solicitudesFuture = SolicitudTutoriaService().obtenerSolicitudesConNombres(widget.tutorId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Solicitud ${nuevoEstado == 'aceptada' ? 'aceptada' : 'rechazada'}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Solicitudes de Tutoría')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _solicitudesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No hay solicitudes.'));
          }
          final solicitudes = snapshot.data!;
          return ListView.builder(
            itemCount: solicitudes.length,
            itemBuilder: (context, index) {
              final s = solicitudes[index];
              final solicitud = s['solicitud'] as SolicitudTutoria;
              final nombreEstudiante = s['nombreEstudiante'] as String;
              print('DEBUG: fechaSesion=${solicitud.fechaSesion} horaInicio=${solicitud.horaInicio} horaFin=${solicitud.horaFin}');
              return Card(
                color: const Color(0xFFF6F3FF),
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFD1C4E9),
                    child: Icon(Icons.person, color: Color(0xFF5E35B1)),
                  ),
                  title: Text('Estudiante: $nombreEstudiante', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Estado: ${solicitud.estado}', style: const TextStyle(color: Colors.black54)),
                      if (solicitud.curso != null) Text('Curso: ${solicitud.curso}'),
                      if (solicitud.mensaje != null && solicitud.mensaje!.isNotEmpty)
                        Text('Mensaje: ${solicitud.mensaje}'),
                      if (solicitud.fechaSesion != null && solicitud.horaInicio != null && solicitud.horaFin != null)
                        Text(
                          'Fecha: ${DateFormat('dd/MM/yyyy').format(solicitud.fechaSesion!)} ${solicitud.horaInicio} - ${solicitud.horaFin}',
                          style: const TextStyle(fontSize: 12, color: Colors.black45),
                        )
                      else if (solicitud.fechaSesion != null)
                        Text(
                          'Fecha: ${DateFormat('dd/MM/yyyy').format(solicitud.fechaSesion!)}',
                          style: const TextStyle(fontSize: 12, color: Colors.black45),
                        )
                      else
                        Text(
                          'Fecha: ' + DateFormat('dd/MM/yyyy HH:mm').format(solicitud.fechaHora),
                          style: const TextStyle(fontSize: 12, color: Colors.black45),
                        ),
                    ],
                  ),
                  trailing: solicitud.estado == 'pendiente'
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.check, color: Colors.green),
                              onPressed: () => _actualizarEstado(solicitud.id, 'aceptada'),
                              tooltip: 'Aceptar',
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.red),
                              onPressed: () => _actualizarEstado(solicitud.id, 'rechazada'),
                              tooltip: 'Rechazar',
                            ),
                          ],
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
} 