import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../core/models/sesion_tutoria.dart';
import '../../../core/models/registro_post_sesion.dart';
import '../services/sesion_tutoria_service.dart';
import '../services/registro_post_sesion_service.dart';
import '../../../core/storage/preferencias_usuario.dart';
import 'registro_post_sesion_page.dart';
import 'resumen_post_sesion_page.dart';
import 'package:tutoring_app/features/tutorias/services/encuesta_satisfaccion_service.dart';
import 'package:tutoring_app/core/models/encuesta_satisfaccion.dart';

class HistorialSesionesPage extends StatefulWidget {
  @override
  _HistorialSesionesPageState createState() => _HistorialSesionesPageState();
}

class _HistorialSesionesPageState extends State<HistorialSesionesPage> {
  final SesionTutoriaService _sesionService = SesionTutoriaService();
  final RegistroPostSesionService _registroService =
      RegistroPostSesionService();
  String? _userId;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
  }

  Future<void> _cargarUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    final prefs = PreferenciasUsuario();
    String role = prefs.userRole;
    if (role == 'teacher') role = 'tutor';
    setState(() {
      _userId = user?.uid;
      _userRole = role;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null || _userRole == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Historial de Sesiones'),
          backgroundColor: Colors.deepPurple,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Historial de Sesiones'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<SesionTutoria>>(
        future: _sesionService.obtenerHistorialSesiones(_userId!, _userRole!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Error al cargar el historial',
                    style: TextStyle(fontSize: 18, color: Colors.red),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final sesiones = snapshot.data ?? [];

          if (sesiones.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No hay sesiones en el historial',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Las sesiones completadas aparecerán aquí',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: sesiones.length,
            itemBuilder: (context, index) {
              final sesion = sesiones[index];
              return _buildSesionCard(sesion);
            },
          );
        },
      ),
    );
  }

  Widget _buildSesionCard(SesionTutoria sesion) {
    final fechaSesion = sesion.fechaSesion ?? sesion.fechaReserva;

    String fechaFormateada;
    try {
      fechaFormateada = DateFormat(
        'EEEE d MMMM yyyy',
        'es',
      ).format(fechaSesion);
      fechaFormateada =
          fechaFormateada.substring(0, 1).toUpperCase() +
          fechaFormateada.substring(1);
    } catch (e) {
      fechaFormateada = DateFormat('dd/MM/yyyy').format(fechaSesion);
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sesion.curso ?? 'Sin curso asignado',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        fechaFormateada,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${sesion.horaInicio} - ${sesion.horaFin}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection(
                              _userRole == 'tutor' ? 'estudiantes' : 'tutores',
                            )
                            .doc(
                              _userRole == 'tutor'
                                  ? sesion.estudianteId
                                  : sesion.tutorId,
                            )
                            .get(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || !snapshot.data!.exists) {
                            return SizedBox.shrink();
                          }
                          final data =
                              snapshot.data!.data() as Map<String, dynamic>;
                          final nombre = data['nombre'] ?? '';
                          final apellidos = data['apellidos'] ?? '';
                          return Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text(
                              _userRole == 'tutor'
                                  ? 'Estudiante: $nombre $apellidos'
                                  : 'Tutor: $nombre $apellidos',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: sesion.estado == 'completada'
                        ? Colors.blue.withAlpha((0.15 * 255).toInt())
                        : Colors.red.withAlpha((0.15 * 255).toInt()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    sesion.estado == 'completada' ? 'COMPLETADA' : 'CANCELADA',
                    style: TextStyle(
                      color: sesion.estado == 'completada'
                          ? Colors.blue
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            if (_userRole == 'tutor' && sesion.estado == 'completada')
              if (sesion.estado == 'completada')
                FutureBuilder<bool>(
                  future: _registroService.sesionTieneRegistro(sesion.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      // Mostrar un espacio vacío del tamaño aproximado del botón para evitar saltos
                      return SizedBox(
                        width: double.infinity,
                        height: 36, // Altura estándar de botón
                      );
                    }
                    if (snapshot.hasData && snapshot.data == true) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.description),
                          label: const Text('Ver resumen post-sesión'),
                          onPressed: () {
                            _verResumenPostSesion(context, sesion.id);
                          },
                        ),
                      );
                    } else if (snapshot.hasData && snapshot.data == false) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.edit_note),
                          label: const Text('Registrar Post-Sesión'),
                          onPressed: () {
                            _registrarPostSesion(context, sesion.id, sesion);
                          },
                        ),
                      );
                    } else {
                      // Si hay error o no hay datos, no mostrar nada
                      return const SizedBox.shrink();
                    }
                  },
                ),
            if (!(_userRole == 'tutor' && sesion.estado == 'completada'))
              if (sesion.estado == 'completada')
                FutureBuilder<RegistroPostSesion?>(
                  future: _registroService.obtenerRegistroPorSesion(sesion.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Cargando detalles...',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      );
                    }

                    final registro = snapshot.data;

                    if (registro == null) {
                      return Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.orange,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Sin registro post-sesión',
                            style: TextStyle(color: Colors.orange),
                          ),
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (registro.temasTratados.isNotEmpty) ...[
                          Text(
                            'Temas cubiertos:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            registro.temasTratados.join(', '),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8),
                        ],
                        if (registro.recomendaciones.isNotEmpty) ...[
                          Text(
                            'Recomendaciones:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            registro.recomendaciones,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8),
                        ],
                        if (registro.observaciones.isNotEmpty) ...[
                          Text(
                            'Observaciones:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            registro.observaciones,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8),
                        ],
                        Row(
                          children: [
                            Icon(
                              registro.asistioEstudiante
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              size: 16,
                              color: registro.asistioEstudiante
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            SizedBox(width: 4),
                            Text(
                              registro.asistioEstudiante
                                  ? 'Asistió'
                                  : 'No asistió',
                              style: TextStyle(
                                fontSize: 12,
                                color: registro.asistioEstudiante
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
            if (_userRole != 'tutor')
              FutureBuilder<EncuestaSatisfaccion?>(
                future: EncuestaSatisfaccionService().obtenerEncuesta(
                  sesionId: sesion.id,
                  estudianteId: sesion.estudianteId,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SizedBox.shrink();
                  }
                  final encuesta = snapshot.data;
                  if (encuesta == null) return SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < encuesta.calificacion
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 20,
                            ),
                          ),
                        ),
                        if (encuesta.comentario.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0, left: 2.0),
                            child: Text(
                              encuesta.comentario,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _verResumenPostSesion(BuildContext context, String sesionId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResumenPostSesionPage(sesionId: sesionId),
      ),
    );
  }

  void _registrarPostSesion(
    BuildContext context,
    String sesionId,
    SesionTutoria sesion,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            RegistroPostSesionPage(sesionId: sesionId, sesion: sesion),
      ),
    );
  }
}
