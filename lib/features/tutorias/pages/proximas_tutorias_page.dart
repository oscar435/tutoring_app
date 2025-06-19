import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tutoring_app/core/models/sesion_tutoria.dart';
import 'package:tutoring_app/features/tutorias/services/sesion_tutoria_service.dart';

class ProximasTutoriasPage extends StatefulWidget {
  final String tutorId;

  const ProximasTutoriasPage({
    required this.tutorId,
    Key? key,
  }) : super(key: key);

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
        body: Center(
          child: CircularProgressIndicator(),
        ),
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
        stream: SesionTutoriaService().streamSesionesFuturasPorTutor(widget.tutorId),
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
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
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
                final estudianteData = estudianteDoc.data() as Map<String, dynamic>?;
                
                final nombreEstudiante = estudianteData != null
                    ? '${estudianteData['nombre']} ${estudianteData['apellidos']}'
                    : 'Estudiante';
                
                final fotoUrl = estudianteData?['photoUrl'];
                
                return {
                  'sesion': sesion,
                  'nombreEstudiante': nombreEstudiante,
                  'fotoUrl': fotoUrl,
                  'estudianteData': estudianteData,
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
                final fechaA = (a['sesion'] as SesionTutoria).fechaSesion ?? (a['sesion'] as SesionTutoria).fechaReserva;
                final fechaB = (b['sesion'] as SesionTutoria).fechaSesion ?? (b['sesion'] as SesionTutoria).fechaReserva;
                return fechaA.compareTo(fechaB); // Orden ascendente (más cercano primero)
              });

              return ListView.separated(
                padding: EdgeInsets.all(16),
                itemCount: sesiones.length,
                separatorBuilder: (context, index) => SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final sesion = sesiones[index]['sesion'] as SesionTutoria;
                  final nombreEstudiante = sesiones[index]['nombreEstudiante'] as String;
                  final fotoUrl = sesiones[index]['fotoUrl'] as String?;
                  
                  final fechaSesion = sesion.fechaSesion ?? sesion.fechaReserva;
                  final ahora = DateTime.now();
                  final esMismoDia = fechaSesion.year == ahora.year &&
                      fechaSesion.month == ahora.month &&
                      fechaSesion.day == ahora.day;

                  String fechaFormateada;
                  try {
                    fechaFormateada = DateFormat('EEEE d MMMM', 'es').format(fechaSesion);
                    // Capitalizar primera letra
                    fechaFormateada = fechaFormateada.substring(0, 1).toUpperCase() + fechaFormateada.substring(1);
                  } catch (e) {
                    fechaFormateada = DateFormat('dd/MM/yyyy').format(fechaSesion);
                  }

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: esMismoDia ? Colors.orange : Colors.grey.shade200,
                        width: esMismoDia ? 2 : 1,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.deepPurple.withOpacity(0.1),
                                backgroundImage: fotoUrl != null ? NetworkImage(fotoUrl) : null,
                                child: fotoUrl == null
                                    ? Icon(Icons.person, color: Colors.deepPurple)
                                    : null,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nombreEstudiante,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      sesion.curso ?? 'Sin curso asignado',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.withOpacity(0.1),
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
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.withOpacity(0.1),
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
                        ],
                      ),
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