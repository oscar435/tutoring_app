import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tutoring_app/pages/CalendarioPage.dart';
import 'package:tutoring_app/pages/login_teacher_page.dart';
import 'package:tutoring_app/pages/notificaciones_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutoring_app/pages/editar_disponibilidad_page.dart';
import 'package:tutoring_app/pages/solicitudes_tutor_page.dart';
import '../models/solicitud_tutoria.dart';
import '../service/solicitud_tutoria_service.dart';
import 'package:intl/intl.dart';
import '../models/sesion_tutoria.dart';
import '../service/sesion_tutoria_service.dart';
import 'package:tutoring_app/pages/mis_estudiantes_page.dart';
import 'package:tutoring_app/pages/tutor_profile_page.dart';
import 'package:tutoring_app/routes/app_routes.dart';

class TeacherHomePage extends StatefulWidget {
  static const routeName = '/teacher-home';
  const TeacherHomePage({Key? key}) : super(key: key);

  @override
  State<TeacherHomePage> createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  late Future<List<Map<String, dynamic>>> _solicitudesFuture;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      _solicitudesFuture = SolicitudTutoriaService().obtenerSolicitudesConNombres(user!.uid);
    }
  }

  Future<void> _actualizarEstado(String solicitudId, String nuevoEstado) async {
    await SolicitudTutoriaService().actualizarEstado(solicitudId, nuevoEstado);
    setState(() {
      if (user != null) {
        _solicitudesFuture = SolicitudTutoriaService().obtenerSolicitudesConNombres(user!.uid);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Solicitud ${nuevoEstado == 'aceptada' ? 'aceptada' : 'rechazada'}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: _buildTeacherDrawer(context),
      body: SafeArea(
        child: Builder(
          builder: (context) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(context),
                const SizedBox(height: 20),
                _buildSectionTitle(title: 'Próximas Tutorías', trailing: 'Ver todas'),
                _buildTutoriasGrid(),
                const SizedBox(height: 20),
                _buildSectionTitle(title: 'Estadísticas'),
                _buildStatsCards(),
                const SizedBox(height: 20),
                _buildSectionTitle(
                  title: 'Solicitudes Pendientes',
                  trailing: 'Ver todas',
                  onTrailingTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SolicitudesTutorPage(tutorId: user?.uid ?? ''),
                      ),
                    );
                  },
                ),
                _buildPendingRequestsList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications, size: 28),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificacionesPage(usuarioId: user?.uid ?? ''),
                  ),
                );
              },
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TutorProfilePage(),
                  ),
                );
              },
              child: const CircleAvatar(
                backgroundImage: AssetImage('assets/teacher_avatar.jpg'),
                radius: 18,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTeacherDrawer(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Drawer();
    return Drawer(
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('tutores').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar datos'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final nombre = data['nombre'] ?? '';
          final apellidos = data['apellidos'] ?? '';
          final escuela = data['escuela'] ?? '';
          final photoUrl = data['photoUrl'] ?? '';
          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF512DA8), Color(0xFF9575CD)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundImage: photoUrl.isNotEmpty
                          ? NetworkImage(photoUrl)
                          : const AssetImage('assets/teacher_avatar.jpg') as ImageProvider,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '$nombre $apellidos',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      escuela,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  color: const Color(0xFF0B1120),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      _buildDrawerItem(Icons.home, 'Inicio', context, () {
                        Navigator.pop(context);
                      }),
                      _buildDrawerItem(
                        Icons.calendar_today,
                        'Calendario de tutorías',
                        context,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CalendarioPage(),
                          ),
                        ),
                      ),
                      _buildDrawerItem(
                        Icons.access_time,
                        'Disponibilidad',
                        context,
                        user != null
                            ? () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditarDisponibilidadPage(tutorId: user.uid),
                                  ),
                                )
                            : null,
                      ),
                      _buildDrawerItem(
                        Icons.people,
                        'Mis estudiantes',
                        context,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MisEstudiantesPage(tutorId: user.uid),
                          ),
                        ),
                      ),
                      _buildDrawerItem(
                        Icons.person,
                        'Perfil',
                        context,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TutorProfilePage(),
                          ),
                        ),
                      ),
                      _buildDrawerItem(
                        Icons.assessment,
                        'Reportes',
                        context,
                        null,
                      ),
                      _buildDrawerItem(
                        Icons.logout,
                        'Cerrar sesión',
                        context,
                        () async {
                          await FirebaseAuth.instance.signOut();
                          Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.roleSelector,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDrawerItem(
    IconData icon,
    String title,
    BuildContext context,
    VoidCallback? onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white70),
      ),
      onTap: onTap,
    );
  }

  Widget _buildSectionTitle({required String title, String? trailing, VoidCallback? onTrailingTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (trailing != null)
            GestureDetector(
              onTap: onTrailingTap,
              child: Text(
                trailing,
                style: const TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTutoriasGrid() {
    if (user == null) return SizedBox.shrink();
    return StreamBuilder<List<SesionTutoria>>(
      stream: SesionTutoriaService().streamSesionesFuturasPorTutor(user!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No hay próximas tutorías.'));
        }
        final sesiones = snapshot.data!;
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: Future.wait(sesiones.map((sesion) async {
            final estudianteDoc = await FirebaseFirestore.instance.collection('estudiantes').doc(sesion.estudianteId).get();
            final estudianteData = estudianteDoc.data() as Map<String, dynamic>?;
            final nombreEstudiante = estudianteData?['nombre'] != null && estudianteData?['apellidos'] != null
                ? '${estudianteData!['nombre']} ${estudianteData['apellidos']}'
                : 'Estudiante';
            // Construir la fecha completa
            String fechaCompleta = '';
            if (sesion.fechaSesion != null) {
              fechaCompleta = '${sesion.dia} ${DateFormat('dd/MM/yyyy').format(sesion.fechaSesion!)} - ${sesion.horaInicio}';
            } else {
              fechaCompleta = '${sesion.dia} - ${sesion.horaInicio}';
            }
            final fotoUrl = estudianteData?['photoUrl'] as String?;
            return {
              'sesion': sesion,
              'nombreEstudiante': nombreEstudiante,
              'fechaCompleta': fechaCompleta,
              'fotoUrl': fotoUrl,
              'estudianteData': estudianteData,
            };
          })),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (!snap.hasData || snap.data!.isEmpty) {
              return Center(child: Text('No hay próximas tutorías.'));
            }
            final sesionesConNombres = snap.data!;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: sesionesConNombres.map((s) {
                final sesion = s['sesion'] as SesionTutoria;
                final nombreEstudiante = s['nombreEstudiante'] as String;
                final fechaCompleta = s['fechaCompleta'] as String;
                final fotoUrl = s['fotoUrl'] as String?;
                final estudianteData = s['estudianteData'] as Map<String, dynamic>?;
                return GestureDetector(
                  onTap: () => _mostrarDetallesTutoria(sesion, nombreEstudiante, fotoUrl, estudianteData),
                  child: _buildTutoriaCard(
                    sesion.curso ?? 'Sin curso',
                    fechaCompleta,
                    nombreEstudiante,
                    Colors.deepPurple,
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  Widget _buildTutoriaCard(
    String subject,
    String time,
    String students,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subject,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text(
              students,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Tutorías',
            '45',
            Icons.school,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            'Estudiantes',
            '120',
            Icons.people,
            Colors.green,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            'Horas',
            '89',
            Icons.timer,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingRequestsList() {
    if (user == null) return SizedBox.shrink();
    
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _solicitudesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No hay solicitudes pendientes.'));
        }
        
        final solicitudes = snapshot.data!.where((s) => 
          (s['solicitud'] as SolicitudTutoria).estado == 'pendiente'
        ).toList();
        
        if (solicitudes.isEmpty) {
          return Center(child: Text('No hay solicitudes pendientes.'));
        }

        return Column(
          children: solicitudes.map((s) {
            final solicitud = s['solicitud'] as SolicitudTutoria;
            final nombreEstudiante = s['nombreEstudiante'] as String;
            final estudianteId = solicitud.estudianteId;
            final curso = solicitud.curso ?? 'Sin curso especificado';
            // Obtener la foto de perfil del estudiante
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('estudiantes').doc(estudianteId).get(),
              builder: (context, snapshotEst) {
                String? fotoUrl;
                if (snapshotEst.hasData && snapshotEst.data != null) {
                  final data = snapshotEst.data!.data() as Map<String, dynamic>?;
                  fotoUrl = data?['photoUrl'] as String?;
                }
                return _buildRequestCard(
                  nombreEstudiante,
                  curso,
                  '', // ya no mostramos la fecha aquí
                  solicitud.id,
                  fotoUrl,
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildRequestCard(String student, String subject, String time, String solicitudId, String? fotoUrl) {
    return Card(
      color: const Color(0xFFF6F3FF),
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _mostrarDetallesSolicitud(solicitudId),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              fotoUrl != null && fotoUrl.isNotEmpty
                  ? CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFD1C4E9),
                      backgroundImage: NetworkImage(fotoUrl),
                      onBackgroundImageError: (_, __) {},
                    )
                  : CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFD1C4E9),
                      child: const Icon(Icons.person, color: Color(0xFF5E35B1)),
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subject,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDetallesTutoria(SesionTutoria sesion, String nombreEstudiante, String? fotoUrl, Map<String, dynamic>? estudianteData) async {
    if (!mounted) return;

    String fechaHoraTexto;
    if (sesion.fechaSesion != null && (sesion.horaInicio ?? '').isNotEmpty && (sesion.horaFin ?? '').isNotEmpty) {
      final fecha = sesion.fechaSesion!;
      final fechaFormateada = DateFormat('dd/MM/yyyy').format(fecha);
      fechaHoraTexto = '$fechaFormateada ${sesion.horaInicio} - ${sesion.horaFin}';
    } else {
      fechaHoraTexto = '${sesion.dia} ${sesion.horaInicio} - ${sesion.horaFin}';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF6F3FF),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  fotoUrl != null && fotoUrl.isNotEmpty
                      ? CircleAvatar(
                          radius: 25,
                          backgroundColor: const Color(0xFFD1C4E9),
                          backgroundImage: NetworkImage(fotoUrl),
                          onBackgroundImageError: (_, __) {},
                        )
                      : CircleAvatar(
                          radius: 25,
                          backgroundColor: const Color(0xFFD1C4E9),
                          child: const Icon(Icons.person, color: Color(0xFF5E35B1)),
                        ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombreEstudiante,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          sesion.curso ?? 'Sin curso especificado',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetalleItem(
                      Icons.event,
                      'Fecha y hora de la tutoría',
                      fechaHoraTexto,
                    ),
                    if (sesion.mensaje != null && sesion.mensaje!.isNotEmpty)
                      _buildDetalleItem(Icons.message, 'Mensaje', sesion.mensaje!),
                    _buildDetalleItem(Icons.access_time, 'Estado', sesion.estado.toUpperCase()),
                    _buildDetalleItem(
                      Icons.send,
                      'Reservada el',
                      DateFormat('dd/MM/yyyy HH:mm').format(sesion.fechaReserva),
                    ),
                    if (estudianteData != null && estudianteData['email'] != null)
                      _buildDetalleItem(Icons.email, 'Email estudiante', estudianteData['email']),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetalleItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.deepPurple, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDetallesSolicitud(String solicitudId) async {
    final solicitudDoc = await FirebaseFirestore.instance
        .collection('solicitudes_tutoria')
        .doc(solicitudId)
        .get();
    
    if (!solicitudDoc.exists) return;
    
    final solicitud = SolicitudTutoria.fromMap(solicitudDoc.data() as Map<String, dynamic>);
    
    // Obtener datos del estudiante
    final estudianteDoc = await FirebaseFirestore.instance
        .collection('estudiantes')
        .doc(solicitud.estudianteId)
        .get();
    
    final estudianteData = estudianteDoc.data() as Map<String, dynamic>?;
    final nombreEstudiante = estudianteData?['nombre'] != null && estudianteData?['apellidos'] != null
        ? '${estudianteData!['nombre']} ${estudianteData['apellidos']}'
        : 'Estudiante';
    final fotoUrl = estudianteData?['photoUrl'] as String?;
    
    String fechaHoraTexto;
    if (solicitud.fechaSesion != null && (solicitud.horaInicio ?? '').isNotEmpty && (solicitud.horaFin ?? '').isNotEmpty) {
      final fecha = solicitud.fechaSesion!;
      final fechaFormateada = DateFormat('dd/MM/yyyy').format(fecha);
      fechaHoraTexto = '$fechaFormateada ${solicitud.horaInicio} - ${solicitud.horaFin}';
    } else {
      fechaHoraTexto = DateFormat('dd/MM/yyyy HH:mm').format(solicitud.fechaHora);
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF6F3FF),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  fotoUrl != null && fotoUrl.isNotEmpty
                      ? CircleAvatar(
                          radius: 25,
                          backgroundColor: const Color(0xFFD1C4E9),
                          backgroundImage: NetworkImage(fotoUrl),
                          onBackgroundImageError: (_, __) {},
                        )
                      : CircleAvatar(
                          radius: 25,
                          backgroundColor: const Color(0xFFD1C4E9),
                          child: const Icon(Icons.person, color: Color(0xFF5E35B1)),
                        ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombreEstudiante,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          solicitud.curso ?? 'Sin curso especificado',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetalleItem(
                      Icons.event,
                      'Fecha y hora de la tutoría',
                      fechaHoraTexto,
                    ),
                    if (solicitud.mensaje != null && solicitud.mensaje!.isNotEmpty)
                      _buildDetalleItem(Icons.message, 'Mensaje', solicitud.mensaje!),
                    _buildDetalleItem(Icons.access_time, 'Estado', solicitud.estado.toUpperCase()),
                    _buildDetalleItem(
                      Icons.send,
                      'Solicitud enviada el',
                      DateFormat('dd/MM/yyyy HH:mm').format(solicitud.fechaHora),
                    ),
                  ],
                ),
              ),
            ),
            if (solicitud.estado == 'pendiente')
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _actualizarEstado(solicitudId, 'rechazada');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Rechazar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _actualizarEstado(solicitudId, 'aceptada');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Aceptar'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
} 