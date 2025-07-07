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
import 'package:tutoring_app/features/tutorias/pages/registro_post_sesion_page.dart';
import 'package:tutoring_app/features/tutorias/services/registro_post_sesion_service.dart';
import 'package:tutoring_app/features/tutorias/pages/historial_sesiones_page.dart';

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
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            tooltip: 'Ver historial de sesiones',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HistorialSesionesPage(),
                ),
              );
            },
          ),
        ],
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
                          null,
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
                            solicitudSnapshot.data?.data()
                                    is Map<String, dynamic>
                                ? solicitudSnapshot.data?.data()
                                      as Map<String, dynamic>?
                                : null,
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
    Map<String, dynamic>? solicitudData,
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
      elevation: 2,
      color: const Color(0xFFF5F6FA),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Etiquetas de estado
            if (estadoVisual == 'reprogramacion_pendiente')
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'REPROG. PENDIENTE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (estadoVisual == 'aceptada')
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule, color: Colors.white, size: 10),
                    SizedBox(width: 2),
                    Text(
                      'CONFIRMADA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            if (estadoVisual == 'completada')
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 10),
                    SizedBox(width: 2),
                    Text(
                      'COMPLETADA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            // Título del curso
            Text(
              sesion.curso ?? 'Sin curso asignado',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // Fecha relativa
            Text(
              fechaFormateada,
              style: TextStyle(
                color: Colors.grey[800],
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Hora
            Text(
              '${sesion.horaInicio} - ${sesion.horaFin}',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // Nombre del estudiante
            Text(
              nombreEstudiante,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 11,
                fontWeight: FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
