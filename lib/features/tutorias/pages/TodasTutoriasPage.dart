import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tutoring_app/core/models/sesion_tutoria.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tutoring_app/features/tutorias/services/sesion_tutoria_service.dart';
import 'package:tutoring_app/core/utils/validators.dart';
import 'package:tutoring_app/features/disponibilidad/services/disponibilidad_service.dart';
import 'package:tutoring_app/core/models/disponibilidad.dart';

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
      appBar: AppBar(title: const Text('Todas mis tutorías')),
      body: StreamBuilder<List<SesionTutoria>>(
        stream: SesionTutoriaService().streamSesionesFuturas(
          user.uid,
          'estudiante',
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final tutorias = snapshot.data ?? [];
          if (tutorias.isEmpty) {
            return const Center(child: Text('No tienes tutorías agendadas'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tutorias.length,
            itemBuilder: (context, index) {
              final tutoria = tutorias[index];
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('sesiones_tutoria')
                    .doc(tutoria.id)
                    .get(),
                builder: (context, sesionSnapshot) {
                  String? solicitudId;
                  if (sesionSnapshot.hasData &&
                      sesionSnapshot.data != null &&
                      sesionSnapshot.data!.exists) {
                    final data =
                        sesionSnapshot.data!.data() as Map<String, dynamic>;
                    solicitudId = data['solicitudId'];
                  }
                  if (solicitudId == null) {
                    // Si no hay solicitud asociada, mostrar el estado normal de la sesión
                    return _buildTutoriaCard(context, tutoria, tutoria.estado);
                  }
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('solicitudes_tutoria')
                        .doc(solicitudId)
                        .get(),
                    builder: (context, solicitudSnapshot) {
                      String estadoVisual = tutoria.estado;
                      if (solicitudSnapshot.hasData &&
                          solicitudSnapshot.data != null &&
                          solicitudSnapshot.data!.exists) {
                        final data =
                            solicitudSnapshot.data!.data()
                                as Map<String, dynamic>;
                        if (data['estado'] == 'reprogramacion_pendiente') {
                          estadoVisual = 'reprogramacion_pendiente';
                        }
                      }
                      return _buildTutoriaCard(context, tutoria, estadoVisual);
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _mostrarDetalleTutoria(BuildContext context, SesionTutoria tutoria) {
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
                  child: Icon(Icons.drag_handle, color: Colors.grey),
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
                      ? DateFormat(
                          'EEEE d MMMM',
                          'es_ES',
                        ).format(tutoria.fechaSesion!)
                      : 'Sin fecha',
                ),
                _buildInfoRow(
                  'Hora',
                  tutoria.horaInicio.isNotEmpty && tutoria.horaFin.isNotEmpty
                      ? "${tutoria.horaInicio} - ${tutoria.horaFin}"
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
                      final tutorData =
                          snapshot.data!.data() as Map<String, dynamic>;
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
                          Text(
                            '${tutorData['nombre']} ${tutorData['apellidos']}',
                          ),
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
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> mostrarDialogoReprogramar(
    BuildContext context,
    SesionTutoria tutoria,
  ) async {
    // Helpers
    String _diaNombre(int weekday) {
      switch (weekday) {
        case 1:
          return 'Lunes';
        case 2:
          return 'Martes';
        case 3:
          return 'Miércoles';
        case 4:
          return 'Jueves';
        case 5:
          return 'Viernes';
        case 6:
          return 'Sábado';
        case 7:
          return 'Domingo';
        default:
          return '';
      }
    }

    bool _esMismoDia(DateTime a, DateTime b) {
      return a.year == b.year && a.month == b.month && a.day == b.day;
    }

    DateTime? nuevaFecha = tutoria.fechaSesion ?? DateTime.now();
    Slot? nuevoSlot;
    List<DateTime> diasDisponibles = [];
    List<Slot> horariosDisponibles = [];
    bool cargando = true;
    String? error;

    final result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> cargarDisponibilidad(DateTime? fecha) async {
              setState(() {
                cargando = true;
                error = null;
              });
              try {
                final servicio = DisponibilidadService();
                final disponibilidad = await servicio.obtenerDisponibilidad(
                  tutoria.tutorId,
                );
                if (disponibilidad == null) {
                  setState(() {
                    error = 'El tutor no tiene disponibilidad.';
                    cargando = false;
                  });
                  return;
                }
                // Obtener próximos 14 días con disponibilidad
                diasDisponibles = [];
                for (int i = 0; i < 14; i++) {
                  final dia = DateTime.now().add(Duration(days: i));
                  final diaSemana = disponibilidad.slots
                      .where(
                        (s) => s.dia == _diaNombre(dia.weekday) && s.activo,
                      )
                      .toList();
                  if (diaSemana.isNotEmpty) diasDisponibles.add(dia);
                }
                // Si la fecha actual no es válida, seleccionar la primera disponible
                if (nuevaFecha == null ||
                    !diasDisponibles.any((d) => _esMismoDia(d, nuevaFecha!))) {
                  nuevaFecha = diasDisponibles.isNotEmpty
                      ? diasDisponibles.first
                      : null;
                } else {
                  // Usar el objeto exacto de la lista
                  nuevaFecha = diasDisponibles.firstWhere(
                    (d) => _esMismoDia(d, nuevaFecha!),
                  );
                }
                // Cargar horarios disponibles para ese día
                if (nuevaFecha != null) {
                  horariosDisponibles = await servicio
                      .obtenerHorariosDisponibles(
                        tutorId: tutoria.tutorId,
                        fecha: nuevaFecha!,
                      );
                  // Si el slot actual ya no está disponible, deseleccionarlo
                  if (nuevoSlot != null &&
                      !horariosDisponibles.contains(nuevoSlot)) {
                    nuevoSlot = null;
                  }
                } else {
                  horariosDisponibles = [];
                  nuevoSlot = null;
                }
                setState(() {
                  cargando = false;
                });
              } catch (e) {
                setState(() {
                  error = 'Error al cargar disponibilidad.';
                  cargando = false;
                });
              }
            }

            // Cargar disponibilidad al abrir
            if (cargando && diasDisponibles.isEmpty) {
              cargarDisponibilidad(nuevaFecha);
            }

            return AlertDialog(
              title: Text('Reprogramar tutoría'),
              content: cargando
                  ? SizedBox(
                      height: 80,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : error != null
                  ? Text(error!)
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<DateTime>(
                          value: nuevaFecha,
                          hint: Text('Selecciona día'),
                          items: diasDisponibles
                              .map(
                                (d) => DropdownMenuItem(
                                  value: d,
                                  child: Text(
                                    DateFormat(
                                      'EEEE d MMMM',
                                      'es_ES',
                                    ).format(d),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (d) async {
                            setState(() {
                              nuevaFecha = d;
                              cargando = true;
                            });
                            await cargarDisponibilidad(d);
                          },
                        ),
                        SizedBox(height: 12),
                        DropdownButtonFormField<Slot>(
                          value: nuevoSlot,
                          hint: Text('Selecciona horario'),
                          items: horariosDisponibles
                              .map(
                                (slot) => DropdownMenuItem(
                                  value: slot,
                                  child: Text(
                                    '${slot.horaInicio} - ${slot.horaFin}',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (s) => setState(() => nuevoSlot = s),
                        ),
                      ],
                    ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    if (nuevaFecha != null && nuevoSlot != null) {
                      Navigator.pop(context, {
                        'fecha': nuevaFecha,
                        'horaInicio': nuevoSlot!.horaInicio,
                        'horaFin': nuevoSlot!.horaFin,
                      });
                    }
                  },
                  child: Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );
    return result;
  }

  // Helper para combinar fecha y hora en formato AM/PM
  DateTime combinarFechaYHora(DateTime fecha, String horaInicio) {
    final partes = horaInicio.split(' ');
    final horaMin = partes[0].split(':');
    int hora = int.parse(horaMin[0]);
    int minuto = int.parse(horaMin[1]);
    String ampm = partes[1].toUpperCase();
    if (ampm == 'PM' && hora != 12) hora += 12;
    if (ampm == 'AM' && hora == 12) hora = 0;
    return DateTime(fecha.year, fecha.month, fecha.day, hora, minuto);
  }

  Widget _buildTutoriaCard(
    BuildContext context,
    SesionTutoria tutoria,
    String estadoVisual,
  ) {
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
              '${tutoria.horaInicio.isNotEmpty && tutoria.horaFin.isNotEmpty ? "${tutoria.horaInicio} - ${tutoria.horaFin}" : 'Sin hora'}',
            ),
            Row(
              children: [
                Flexible(
                  child: Container(
                    margin: EdgeInsets.only(top: 6, bottom: 6),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: estadoVisual == 'reprogramacion_pendiente'
                          ? Colors.orange.withAlpha((0.15 * 255).toInt())
                          : estadoVisual == 'aceptada'
                          ? Colors.green.withAlpha((0.15 * 255).toInt())
                          : estadoVisual == 'pendiente'
                          ? Colors.orange.withAlpha((0.15 * 255).toInt())
                          : estadoVisual == 'completada'
                          ? Colors.green.withAlpha((0.15 * 255).toInt())
                          : Colors.red.withAlpha((0.15 * 255).toInt()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      estadoVisual == 'reprogramacion_pendiente'
                          ? 'REPROGRAMACIÓN PENDIENTE'
                          : estadoVisual.toUpperCase(),
                      style: TextStyle(
                        color: estadoVisual == 'reprogramacion_pendiente'
                            ? Colors.orange
                            : estadoVisual == 'aceptada'
                            ? Colors.green
                            : estadoVisual == 'pendiente'
                            ? Colors.orange
                            : estadoVisual == 'completada'
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            if (tutoria.estado == 'pendiente' || tutoria.estado == 'aceptada')
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(Icons.cancel, color: Colors.red),
                    tooltip: 'Cancelar tutoría',
                    onPressed: () async {
                      // Validar plazo de 24 horas
                      final fechaSesion =
                          tutoria.fechaSesion ?? tutoria.fechaReserva;
                      final mensajeError =
                          Validators.getMensajeErrorCancelacion(fechaSesion);

                      if (mensajeError.isNotEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(mensajeError),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 4),
                          ),
                        );
                        return;
                      }

                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Cancelar tutoría'),
                          content: Text(
                            '¿Estás seguro de que deseas cancelar esta tutoría?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text('No'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text('Sí, cancelar'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await SesionTutoriaService().cancelarSesion(tutoria.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Tutoría cancelada')),
                        );
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.edit_calendar, color: Colors.orange),
                    tooltip: 'Reprogramar tutoría',
                    onPressed: () async {
                      final result = await mostrarDialogoReprogramar(
                        context,
                        tutoria,
                      );
                      if (result == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Debes seleccionar fecha y horario para reprogramar.',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      final fecha = result['fecha'] as DateTime;
                      final horaInicio = result['horaInicio'] as String;
                      final horaFin = result['horaFin'] as String;
                      final nuevaFechaSesion = combinarFechaYHora(
                        fecha,
                        horaInicio,
                      );
                      try {
                        final sesionDoc = await FirebaseFirestore.instance
                            .collection('sesiones_tutoria')
                            .doc(tutoria.id)
                            .get();
                        final solicitudId = sesionDoc.data()?['solicitudId'];
                        if (solicitudId != null) {
                          await SesionTutoriaService().solicitarReprogramacion(
                            solicitudId: solicitudId,
                            nuevaFechaSesion: nuevaFechaSesion,
                            nuevaHoraInicio: horaInicio,
                            nuevaHoraFin: horaFin,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Solicitud de reprogramación enviada para ${DateFormat('dd/MM/yyyy').format(fecha)} de $horaInicio a $horaFin',
                              ),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'No se pudo encontrar la solicitud asociada.',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Error al solicitar reprogramación: $e',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
          ],
        ),
        onTap: () => _mostrarDetalleTutoria(context, tutoria),
      ),
    );
  }
}
