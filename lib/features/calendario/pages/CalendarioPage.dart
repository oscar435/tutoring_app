import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutoring_app/routes/app_routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:tutoring_app/core/models/sesion_tutoria.dart';
import 'package:tutoring_app/features/tutorias/services/sesion_tutoria_service.dart';

class CalendarioPage extends StatefulWidget {
  static const String routeName = AppRoutes.calendario;
  const CalendarioPage({Key? key}) : super(key: key);

  @override
  State<CalendarioPage> createState() => _CalendarioPageState();
}

class _CalendarioPageState extends State<CalendarioPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, String>>> _events = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _listenEventos();
  }

  void _listenEventos() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _detectarRolYEscuchar(user.uid);
  }

  void _detectarRolYEscuchar(String uid) async {
    final tutorDoc = await FirebaseFirestore.instance.collection('tutores').doc(uid).get();
    final estudianteDoc = await FirebaseFirestore.instance.collection('estudiantes').doc(uid).get();
    
    String? userRole;
    if (tutorDoc.exists) {
      userRole = 'tutor';
    } else if (estudianteDoc.exists) {
      userRole = 'estudiante';
    }

    if (userRole != null) {
      SesionTutoriaService().streamSesionesFuturas(uid, userRole).listen((sesiones) async {
        final Map<DateTime, List<Map<String, String>>> eventos = {};
        for (final sesion in sesiones) {
          final fecha = sesion.fechaSesion;
          if (fecha != null) {
            final key = DateTime.utc(fecha.year, fecha.month, fecha.day);
            
            if (userRole == 'tutor') {
              final estudianteNombre = await _obtenerNombreEstudiante(sesion.estudianteId);
              eventos.putIfAbsent(key, () => []).add({
                'curso': sesion.curso ?? 'Tutoría',
                'estudiante': estudianteNombre,
                'hora': '${sesion.horaInicio} - ${sesion.horaFin}',
              });
            } else { // Es estudiante
              final tutorNombre = await _obtenerNombreTutor(sesion.tutorId);
              eventos.putIfAbsent(key, () => []).add({
                'curso': sesion.curso ?? 'Tutoría',
                'tutor': tutorNombre,
                'hora': '${sesion.horaInicio} - ${sesion.horaFin}',
              });
            }
          }
        }
        if (mounted) {
          setState(() {
            _events = eventos;
            _loading = false;
          });
        }
      });
    } else {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<String> _obtenerNombreEstudiante(String estudianteId) async {
    final doc = await FirebaseFirestore.instance.collection('estudiantes').doc(estudianteId).get();
    if (!doc.exists) return 'Estudiante';
    final data = doc.data() as Map<String, dynamic>;
    final nombre = data['nombre'] ?? '';
    final apellidos = data['apellidos'] ?? '';
    return '$nombre $apellidos'.trim().isEmpty ? 'Estudiante' : '$nombre $apellidos';
  }

  Future<String> _obtenerNombreTutor(String tutorId) async {
    final doc = await FirebaseFirestore.instance.collection('tutores').doc(tutorId).get();
    if (!doc.exists) return 'Tutor';
    final data = doc.data() as Map<String, dynamic>;
    final nombre = data['nombre'] ?? '';
    final apellidos = data['apellidos'] ?? '';
    return '$nombre $apellidos'.trim().isEmpty ? 'Tutor' : '$nombre $apellidos';
  }

  DateTime? _parsearFechaDesdeDia(String dia, DateTime base) {
    // Intenta encontrar la próxima fecha para el día de la semana dado
    if (dia.isEmpty) return null;
    final dias = {
      'Lunes': DateTime.monday,
      'Martes': DateTime.tuesday,
      'Miércoles': DateTime.wednesday,
      'Jueves': DateTime.thursday,
      'Viernes': DateTime.friday,
      'Sábado': DateTime.saturday,
      'Domingo': DateTime.sunday,
    };
    final diaSemana = dias[dia];
    if (diaSemana == null) return null;
    DateTime fecha = base;
    while (fecha.weekday != diaSemana) {
      fecha = fecha.add(Duration(days: 1));
    }
    return fecha;
  }

  List<Map<String, String>> _getEventsForDay(DateTime day) {
    return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: Text(
          'Calendario Académico',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.deepPurple[50],
                  child: TableCalendar<Map<String, String>>(
                    firstDay: DateTime.utc(2024, 1, 1),
                    lastDay: DateTime.utc(2026, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    calendarStyle: const CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Colors.deepPurple,
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: BoxDecoration(
                        color: Colors.pink,
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: TextStyle(color: Colors.white),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.deepPurple,
                      ),
                      leftChevronIcon: const Icon(
                        Icons.chevron_left,
                        color: Colors.deepPurple,
                      ),
                      rightChevronIcon: const Icon(
                        Icons.chevron_right,
                        color: Colors.deepPurple,
                      ),
                    ),
                    eventLoader: _getEventsForDay,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _selectedDay == null
                      ? Center(
                          child: Text(
                            "Selecciona una fecha",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        )
                      : ListView(
                          children: _getEventsForDay(_selectedDay!).map((event) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              child: Card(
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                color: Colors.deepPurple[100],
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.event_note,
                                    color: Colors.deepPurple,
                                  ),
                                  title: Text(
                                    event['curso'] ?? '',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.deepPurple[900],
                                    ),
                                  ),
                                  subtitle: Text(
                                    event['tutor'] != null
                                        ? 'Tutor: ${event['tutor'] ?? ''}\nHora: ${event['hora'] ?? ''}'
                                        : 'Estudiante: ${event['estudiante'] ?? ''}\nHora: ${event['hora'] ?? ''}',
                                    style: GoogleFonts.poppins(fontSize: 14),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ],
            ),
    );
  }
}
