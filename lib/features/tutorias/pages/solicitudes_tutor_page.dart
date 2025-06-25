import 'package:flutter/material.dart';
import 'package:tutoring_app/core/models/solicitud_tutoria.dart';
import 'package:tutoring_app/features/tutorias/services/solicitud_tutoria_service.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    _solicitudesFuture = _obtenerSolicitudesConAsignacion();
  }

  Future<List<Map<String, dynamic>>> _obtenerSolicitudesConAsignacion() async {
    final solicitudes = await SolicitudTutoriaService()
        .obtenerSolicitudesConNombres(widget.tutorId);

    // Verificar cuáles estudiantes están asignados
    final solicitudesConAsignacion = await Future.wait(
      solicitudes.map((s) async {
        final solicitud = s['solicitud'] as SolicitudTutoria;
        final estudianteId = solicitud.estudianteId;
        final nombreEstudiante = s['nombreEstudiante'] as String;

        // Obtener datos del estudiante
        final estudianteDoc = await FirebaseFirestore.instance
            .collection('estudiantes')
            .doc(estudianteId)
            .get();

        final estudianteData = estudianteDoc.data();

        // Verificar si el estudiante está en la lista de estudiantes asignados del tutor
        final tutorDoc = await FirebaseFirestore.instance
            .collection('tutores')
            .doc(widget.tutorId)
            .get();

        final tutorData = tutorDoc.data();
        final estudiantesAsignados =
            (tutorData?['estudiantes_asignados'] as List<dynamic>?)
                ?.cast<String>() ??
            [];
        final esAsignado = estudiantesAsignados.contains(estudianteId);

        return {
          ...s,
          'esAsignado': esAsignado,
          'estudianteData': estudianteData,
        };
      }),
    );

    return solicitudesConAsignacion;
  }

  Future<void> _actualizarEstado(String solicitudId, String nuevoEstado) async {
    try {
      final resultado = await SolicitudTutoriaService().actualizarEstado(
        solicitudId,
        nuevoEstado,
      );

      if (resultado['success']) {
        setState(() {
          _solicitudesFuture = _obtenerSolicitudesConAsignacion();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado['message']),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar la solicitud: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
              final esAsignado = s['esAsignado'] as bool;
              final estudianteData =
                  s['estudianteData'] as Map<String, dynamic>?;

              return Card(
                color: esAsignado ? Colors.green[50] : const Color(0xFFF6F3FF),
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: esAsignado
                      ? BorderSide(color: Colors.green, width: 2)
                      : BorderSide.none,
                ),
                child: InkWell(
                  onTap: () {
                    // Aquí podrías añadir navegación a detalles si es necesario
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: esAsignado
                              ? Colors.green
                              : const Color(0xFFD1C4E9),
                          backgroundImage:
                              (estudianteData?['photoUrl'] as String? ?? '')
                                  .isNotEmpty
                              ? NetworkImage(estudianteData!['photoUrl'])
                              : null,
                          child:
                              (estudianteData?['photoUrl'] as String? ?? '')
                                  .isEmpty
                              ? Icon(
                                  Icons.person,
                                  color: esAsignado
                                      ? Colors.white
                                      : const Color(0xFF5E35B1),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      nombreEstudiante,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: esAsignado
                                            ? Colors.green[800]
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                  if (esAsignado)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.star,
                                            color: Colors.white,
                                            size: 10,
                                          ),
                                          SizedBox(width: 2),
                                          Text(
                                            'ASIGNADO',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                solicitud.curso ?? 'Sin curso especificado',
                                style: TextStyle(
                                  color: esAsignado
                                      ? Colors.green[700]
                                      : Colors.black54,
                                  fontSize: 14,
                                  fontWeight: esAsignado
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Estado: ${solicitud.estado}',
                                style: TextStyle(
                                  color: solicitud.estado == 'aceptada'
                                      ? Colors.green
                                      : solicitud.estado == 'pendiente'
                                      ? Colors.orange
                                      : Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (solicitud.fechaSesion != null &&
                                  solicitud.horaInicio != null &&
                                  solicitud.horaFin != null)
                                Text(
                                  '${DateFormat('dd/MM/yyyy').format(solicitud.fechaSesion!)} ${solicitud.horaInicio} - ${solicitud.horaFin}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (solicitud.estado == 'pendiente')
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.check,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    _actualizarEstado(solicitud.id, 'aceptada'),
                                tooltip: 'Aceptar',
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.close,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                onPressed: () => _actualizarEstado(
                                  solicitud.id,
                                  'rechazada',
                                ),
                                tooltip: 'Rechazar',
                              ),
                            ],
                          )
                        else
                          Icon(
                            Icons.chevron_right,
                            color: esAsignado ? Colors.green : Colors.grey,
                          ),
                      ],
                    ),
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
