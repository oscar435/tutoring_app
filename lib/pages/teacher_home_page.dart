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
                _buildSectionTitle(title: 'Solicitudes Pendientes'),
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
                    builder: (context) => SolicitudesTutorPage(tutorId: user?.uid ?? ''),
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
                      _buildDrawerItem(Icons.home, 'Inicio', context, null),
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
                            LoginTeacherPage.routeName,
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

  Widget _buildSectionTitle({required String title, String? trailing}) {
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
            Text(
              trailing,
              style: const TextStyle(
                color: Colors.deepPurple,
                fontWeight: FontWeight.w500,
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
            final nombreEstudiante = await SolicitudTutoriaService().obtenerNombreEstudiante(sesion.estudianteId);
            return {
              'sesion': sesion,
              'nombreEstudiante': nombreEstudiante,
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
                return _buildTutoriaCard(
                  sesion.curso ?? 'Sin curso',
                  '${sesion.dia} - ${sesion.horaInicio}',
                  nombreEstudiante,
                  Colors.deepPurple,
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
            String fechaHoraTexto;
            if (solicitud.fechaSesion != null && solicitud.horaInicio != null && solicitud.horaFin != null) {
              final fecha = solicitud.fechaSesion!;
              final fechaFormateada = DateFormat('dd/MM/yyyy').format(fecha);
              fechaHoraTexto = '$fechaFormateada ${solicitud.horaInicio} - ${solicitud.horaFin}';
            } else {
              final fecha = solicitud.fechaHora;
              fechaHoraTexto = DateFormat('dd/MM/yyyy HH:mm').format(fecha);
            }
            return _buildRequestCard(
              nombreEstudiante,
              solicitud.curso ?? 'Sin curso especificado',
              fechaHoraTexto,
              solicitud.id,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildRequestCard(String student, String subject, String time, String solicitudId) {
    final DateTime fecha = DateTime.tryParse(time) ?? DateTime.now();
    final String fechaFormateada = DateFormat('dd/MM/yyyy HH:mm').format(fecha);
    return Card(
      color: const Color(0xFFF6F3FF),
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFD1C4E9),
          child: Icon(Icons.person, color: Color(0xFF5E35B1)),
        ),
        title: Text(student, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subject, style: const TextStyle(color: Colors.black54)),
            Text(fechaFormateada, style: const TextStyle(fontSize: 12, color: Colors.black45)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () => _actualizarEstado(solicitudId, 'aceptada'),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => _actualizarEstado(solicitudId, 'rechazada'),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
} 