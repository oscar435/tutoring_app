import 'package:flutter/material.dart';
import 'package:tutoring_app/core/models/solicitud_tutoria.dart';
import 'package:tutoring_app/features/tutorias/services/solicitud_tutoria_service.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutoring_app/features/tutorias/services/sesion_tutoria_service.dart';

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

              // Mostrar tag y detalles si hay reprogramación pendiente
              final tieneRepro =
                  solicitud.estado == 'reprogramacion_pendiente' &&
                  (s['solicitud'] as dynamic).reprogramacionPendiente != null;
              final repro = tieneRepro
                  ? (s['solicitud'] as dynamic).reprogramacionPendiente
                  : null;

              return Card(
                color: tieneRepro
                    ? Colors.orange[50]
                    : (esAsignado ? Colors.green[50] : const Color(0xFFF6F3FF)),
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: tieneRepro
                      ? BorderSide(color: Colors.orange, width: 2)
                      : (esAsignado
                            ? BorderSide(color: Colors.green, width: 2)
                            : BorderSide.none),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: esAsignado
                                ? Colors.green
                                : (tieneRepro
                                      ? Colors.orange
                                      : const Color(0xFFD1C4E9)),
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
                                        : (tieneRepro
                                              ? Colors.orange
                                              : const Color(0xFF5E35B1)),
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
                                          color: tieneRepro
                                              ? Colors.orange[800]
                                              : (esAsignado
                                                    ? Colors.green[800]
                                                    : Colors.black),
                                        ),
                                      ),
                                    ),
                                    if (tieneRepro)
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.refresh,
                                              color: Colors.white,
                                              size: 12,
                                            ),
                                            SizedBox(width: 2),
                                            Text(
                                              'REPROG.',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (esAsignado && !tieneRepro)
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
                                SizedBox(height: 4),
                                Text(
                                  solicitud.curso ?? 'Sin curso',
                                  style: TextStyle(
                                    color: tieneRepro
                                        ? Colors.orange[700]
                                        : (esAsignado
                                              ? Colors.green[700]
                                              : Colors.grey[600]),
                                    fontSize: 14,
                                    fontWeight: tieneRepro || esAsignado
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                                  ),
                                ),
                                SizedBox(height: 8),
                                if (tieneRepro) ...[
                                  Text(
                                    'Reprogramación solicitada:',
                                    style: TextStyle(
                                      color: Colors.orange[900],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Nueva fecha: ' +
                                        DateFormat(
                                          'EEEE d MMMM',
                                          'es_ES',
                                        ).format(
                                          (repro['fechaSesion'] as Timestamp)
                                              .toDate(),
                                        ),
                                  ),
                                  Text(
                                    'Nuevo horario: ${repro['horaInicio']} - ${repro['horaFin']}',
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      ElevatedButton.icon(
                                        icon: Icon(Icons.check),
                                        label: Text('Aceptar'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                        ),
                                        onPressed: () async {
                                          await SesionTutoriaService()
                                              .aceptarReprogramacion(
                                                solicitudId: solicitud.id,
                                              );
                                          setState(() {
                                            _solicitudesFuture =
                                                _obtenerSolicitudesConAsignacion();
                                          });
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Reprogramación aceptada',
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        },
                                      ),
                                      SizedBox(width: 12),
                                      ElevatedButton.icon(
                                        icon: Icon(Icons.close),
                                        label: Text('Rechazar'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        onPressed: () async {
                                          await SesionTutoriaService()
                                              .rechazarReprogramacion(
                                                solicitudId: solicitud.id,
                                              );
                                          setState(() {
                                            _solicitudesFuture =
                                                _obtenerSolicitudesConAsignacion();
                                          });
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Reprogramación rechazada',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        solicitud.curso ?? 'Sin curso especificado',
                        style: TextStyle(
                          color: tieneRepro
                              ? Colors.orange[700]
                              : (esAsignado
                                    ? Colors.green[700]
                                    : Colors.grey[600]),
                          fontSize: 14,
                          fontWeight: tieneRepro || esAsignado
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
              );
            },
          );
        },
      ),
    );
  }
}
