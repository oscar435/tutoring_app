import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tutoring_app/core/models/sesion_tutoria.dart';
import 'package:tutoring_app/features/tutorias/services/sesion_tutoria_service.dart';
import 'package:tutoring_app/core/utils/validators.dart';

class ProximasTutoriasPage extends StatefulWidget {
  final String userId;
  final String userRole; // 'tutor' o 'estudiante'

  const ProximasTutoriasPage({
    required this.userId,
    required this.userRole,
    super.key,
  });

  @override
  State<ProximasTutoriasPage> createState() => _ProximasTutoriasPageState();
}

class _ProximasTutoriasPageState extends State<ProximasTutoriasPage> {
  bool _localeInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeLocale();
  }

  Future<void> _initializeLocale() async {
    await initializeDateFormatting('es');
    if (mounted) {
      setState(() {
        _localeInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_localeInitialized) {
      return Scaffold(
        backgroundColor: Color(0xFFF8F7FC),
        appBar: AppBar(
          title: Text('Próximas Tutorías'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFF8F7FC),
      appBar: AppBar(
        title: Text('Próximas Tutorías'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<SesionTutoria>>(
        stream: SesionTutoriaService().streamSesionesFuturas(
          widget.userId,
          widget.userRole,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No tienes tutorías próximas',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: Future.wait(
              snapshot.data!.map((sesion) async {
                final estudianteDoc = await FirebaseFirestore.instance
                    .collection('estudiantes')
                    .doc(sesion.estudianteId)
                    .get();
                final estudianteData = estudianteDoc.data();

                final nombreEstudiante = estudianteData != null
                    ? '${estudianteData['nombre']} ${estudianteData['apellidos']}'
                    : 'Estudiante';

                final fotoUrl = estudianteData?['photoUrl'];

                // Verificar si el estudiante está asignado al tutor
                final tutorDoc = await FirebaseFirestore.instance
                    .collection('tutores')
                    .doc(widget.userId)
                    .get();

                final tutorData = tutorDoc.data();
                final estudiantesAsignados =
                    (tutorData?['estudiantes_asignados'] as List<dynamic>?)
                        ?.cast<String>() ??
                    [];
                final esAsignado = estudiantesAsignados.contains(
                  sesion.estudianteId,
                );

                return {
                  'sesion': sesion,
                  'nombreEstudiante': nombreEstudiante,
                  'fotoUrl': fotoUrl,
                  'estudianteData': estudianteData,
                  'esAsignado': esAsignado,
                };
              }),
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('No hay tutorías próximas'));
              }

              final sesiones = snapshot.data!;
              // Ordenar las sesiones por fecha más reciente
              sesiones.sort((a, b) {
                final fechaA =
                    (a['sesion'] as SesionTutoria).fechaSesion ??
                    (a['sesion'] as SesionTutoria).fechaReserva;
                final fechaB =
                    (b['sesion'] as SesionTutoria).fechaSesion ??
                    (b['sesion'] as SesionTutoria).fechaReserva;
                return fechaA.compareTo(
                  fechaB,
                ); // Orden ascendente (más cercano primero)
              });

              return ListView.separated(
                padding: EdgeInsets.all(16),
                itemCount: sesiones.length,
                separatorBuilder: (context, index) => SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final sesion = sesiones[index]['sesion'] as SesionTutoria;
                  final nombreEstudiante =
                      sesiones[index]['nombreEstudiante'] as String;
                  final fotoUrl = sesiones[index]['fotoUrl'] as String?;
                  final esAsignado = sesiones[index]['esAsignado'] as bool;

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('sesiones_tutoria')
                        .doc(sesion.id)
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
                        return _buildProximaTutoriaCard(
                          context,
                          sesion,
                          nombreEstudiante,
                          fotoUrl,
                          esAsignado,
                          sesion.estado,
                        );
                      }
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('solicitudes_tutoria')
                            .doc(solicitudId)
                            .get(),
                        builder: (context, solicitudSnapshot) {
                          String estadoVisual = sesion.estado;
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
                          return _buildProximaTutoriaCard(
                            context,
                            sesion,
                            nombreEstudiante,
                            fotoUrl,
                            esAsignado,
                            estadoVisual,
                          );
                        },
                      );
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

  Widget _buildProximaTutoriaCard(
    BuildContext context,
    SesionTutoria sesion,
    String nombreEstudiante,
    String? fotoUrl,
    bool esAsignado,
    String estadoVisual,
  ) {
    final fechaSesion = sesion.fechaSesion ?? sesion.fechaReserva;
    final ahora = DateTime.now();
    final esMismoDia =
        fechaSesion.year == ahora.year &&
        fechaSesion.month == ahora.month &&
        fechaSesion.day == ahora.day;

    String fechaFormateada;
    try {
      fechaFormateada = DateFormat('EEEE d MMMM', 'es').format(fechaSesion);
      // Capitalizar primera letra
      fechaFormateada =
          fechaFormateada.substring(0, 1).toUpperCase() +
          fechaFormateada.substring(1);
    } catch (e) {
      fechaFormateada = DateFormat('dd/MM/yyyy').format(fechaSesion);
    }

    return Card(
      elevation: 0,
      color: esAsignado ? Colors.green[50] : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: esAsignado
              ? Colors.green
              : (esMismoDia ? Colors.orange : Colors.grey.shade200),
          width: esAsignado ? 2 : (esMismoDia ? 2 : 1),
        ),
      ),
      child: InkWell(
        onTap: () {
          // Aquí podrías añadir navegación a detalles si es necesario
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: esAsignado
                      ? Border.all(color: Colors.green, width: 2)
                      : null,
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundImage: (fotoUrl != null && fotoUrl.isNotEmpty)
                      ? NetworkImage(fotoUrl)
                      : const AssetImage('assets/avatar.jpg') as ImageProvider,
                ),
              ),
              SizedBox(width: 12),
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
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
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
                                Icon(Icons.star, color: Colors.white, size: 10),
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
                      sesion.curso ?? 'Sin curso asignado',
                      style: TextStyle(
                        color: esAsignado
                            ? Colors.green[700]
                            : Colors.grey[600],
                        fontSize: 14,
                        fontWeight: esAsignado
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withAlpha((0.1 * 255).toInt()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 20,
                            color: Colors.deepPurple,
                          ),
                          SizedBox(width: 8),
                          Text(
                            fechaFormateada,
                            style: TextStyle(
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withAlpha((0.1 * 255).toInt()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 20,
                            color: Colors.deepPurple,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '${sesion.horaInicio} - ${sesion.horaFin}',
                            style: TextStyle(
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            margin: EdgeInsets.only(top: 6, bottom: 6),
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: estadoVisual == 'reprogramacion_pendiente'
                                  ? Colors.orange.withAlpha(
                                      (0.15 * 255).toInt(),
                                    )
                                  : estadoVisual == 'aceptada'
                                  ? Colors.green.withAlpha((0.15 * 255).toInt())
                                  : estadoVisual == 'pendiente'
                                  ? Colors.orange.withAlpha(
                                      (0.15 * 255).toInt(),
                                    )
                                  : Colors.red.withAlpha((0.15 * 255).toInt()),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              estadoVisual == 'reprogramacion_pendiente'
                                  ? 'REPROG. PENDIENTE'
                                  : estadoVisual.toUpperCase(),
                              style: TextStyle(
                                color:
                                    estadoVisual == 'reprogramacion_pendiente'
                                    ? Colors.orange
                                    : estadoVisual == 'aceptada'
                                    ? Colors.green
                                    : estadoVisual == 'pendiente'
                                    ? Colors.orange
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
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: esAsignado ? Colors.green : Colors.grey,
              ),
              if (widget.userRole == 'estudiante' &&
                  (estadoVisual == 'pendiente' || estadoVisual == 'aceptada'))
                IconButton(
                  icon: Icon(Icons.cancel, color: Colors.red),
                  tooltip: 'Cancelar tutoría',
                  onPressed: () async {
                    // Validar plazo de 24 horas
                    final fechaSesion =
                        sesion.fechaSesion ?? sesion.fechaReserva;
                    final mensajeError = Validators.getMensajeErrorCancelacion(
                      fechaSesion,
                    );

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
                      await SesionTutoriaService().cancelarSesion(sesion.id);
                      // Refresca la lista o muestra un mensaje
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Tutoría cancelada')),
                      );
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
