import 'package:flutter/material.dart';
import 'package:tutoring_app/features/calendario/pages/CalendarioPage.dart';
import 'package:tutoring_app/features/notificaciones/pages/notificaciones_page.dart';
import 'package:tutoring_app/core/utils/snackbar.dart';
import 'package:tutoring_app/features/disponibilidad/pages/editar_disponibilidad_page.dart';
import 'package:tutoring_app/features/tutorias/pages/solicitudes_tutor_page.dart';
import 'package:tutoring_app/features/tutorias/pages/proximas_tutorias_page.dart';
import 'package:tutoring_app/core/storage/preferencias_usuario.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutoring_app/core/models/solicitud_tutoria.dart';
import 'package:tutoring_app/core/models/sesion_tutoria.dart';
import 'package:tutoring_app/features/dashboard/pages/mis_estudiantes_page.dart';
import 'package:tutoring_app/features/perfil/pages/tutor_profile_page.dart';
import 'package:tutoring_app/routes/app_routes.dart';
import 'package:tutoring_app/features/tutorias/services/solicitud_tutoria_service.dart';
import 'package:tutoring_app/features/tutorias/services/sesion_tutoria_service.dart';
import 'package:intl/intl.dart';

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

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _actualizarEstado(String solicitudId, String nuevoEstado) async {
    if (!mounted) return;

    final resultado = await SolicitudTutoriaService().actualizarEstado(solicitudId, nuevoEstado);
    final exito = resultado['success'] as bool;
    final mensaje = resultado['message'] as String;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: exito ? Colors.green : Colors.red,
        ),
      );
    }
    
    // Si la operación fue exitosa, refrescar la lista de solicitudes
    if (exito) {
      setState(() {
        if (user != null) {
          _solicitudesFuture = SolicitudTutoriaService().obtenerSolicitudesConNombres(user!.uid);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Error: No hay usuario')));

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        // Verificar si el usuario está activo
        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final isActive = userData['isActive'] ?? true;
          
          if (!isActive) {
            // Usuario desactivado, cerrar sesión automáticamente
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await FirebaseAuth.instance.signOut();
              final prefs = PreferenciasUsuario();
              await prefs.clearUserSession();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.roleSelector, 
                  (route) => false
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tu cuenta ha sido desactivada. Contacta al administrador.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            });
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.block, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      'Cuenta Desactivada',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tu cuenta ha sido desactivada por un administrador.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
        }

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
                    _buildSectionTitle(
                      title: 'Próximas Tutorías',
                      trailing: 'Ver todas',
                      onTrailingTap: () {
                        if (user != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProximasTutoriasPage(
                                userId: user.uid, 
                                userRole: 'tutor'
                              ),
                            ),
                          );
                        }
                      },
                    ),
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
      },
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
                    builder: (context) => const TutorProfilePage(),
                  ),
                );
              },
              child: StreamBuilder<DocumentSnapshot>(
                stream: user != null ? FirebaseFirestore.instance.collection('tutores').doc(user.uid).snapshots() : null,
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    final photoUrl = data['photoUrl'] as String?;
                    if (photoUrl != null && photoUrl.isNotEmpty) {
                      return CircleAvatar(
                        backgroundImage: NetworkImage(photoUrl),
                        radius: 18,
                      );
                    }
                  }
                  return const CircleAvatar(
                    backgroundImage: AssetImage('assets/teacher_avatar.jpg'),
                    radius: 18,
                  );
                },
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
                      _buildDrawerItem(Icons.home, 'Inicio', context, () => Navigator.pop(context)),
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
      stream: SesionTutoriaService().streamSesionesFuturas(user!.uid, 'tutor'),
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
            final estudianteDoc = await FirebaseFirestore.instance
                .collection('estudiantes')
                .doc(sesion.estudianteId)
                .get();
            
            final estudianteData = estudianteDoc.data() as Map<String, dynamic>?;
            final nombreEstudiante = estudianteData != null
                ? '${estudianteData['nombre']} ${estudianteData['apellidos']}'
                : 'Estudiante';
            
            final fechaSesion = sesion.fechaSesion ?? sesion.fechaReserva;
            final fechaCompleta = DateFormat('dd/MM/yyyy').format(fechaSesion);
            final fechaRelativa = _getRelativeTime(fechaSesion);
            
            // Verificar si el estudiante está asignado al tutor
            final tutorDoc = await FirebaseFirestore.instance
                .collection('tutores')
                .doc(user!.uid)
                .get();
            
            final tutorData = tutorDoc.data() as Map<String, dynamic>?;
            final estudiantesAsignados = (tutorData?['estudiantes_asignados'] as List<dynamic>?)?.cast<String>() ?? [];
            final esAsignado = estudiantesAsignados.contains(sesion.estudianteId);
            
            final fotoUrl = estudianteData?['photoUrl'] as String?;
            return {
              'sesion': sesion,
              'nombreEstudiante': nombreEstudiante,
              'fechaCompleta': fechaCompleta,
              'fechaRelativa': fechaRelativa,
              'fechaSesion': fechaSesion,
              'fotoUrl': fotoUrl,
              'estudianteData': estudianteData,
              'esAsignado': esAsignado,
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
            
            // Ordenar por fecha (ya viene ordenado del servicio, pero por si acaso)
            sesionesConNombres.sort((a, b) {
              final fechaA = a['fechaSesion'] as DateTime;
              final fechaB = b['fechaSesion'] as DateTime;
              return fechaA.compareTo(fechaB);
            });
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Text(
                    'Próximas Tutorías (${sesionesConNombres.length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 1.35,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  children: sesionesConNombres.asMap().entries.map((entry) {
                    final index = entry.key;
                    final s = entry.value;
                    final sesion = s['sesion'] as SesionTutoria;
                    final nombreEstudiante = s['nombreEstudiante'] as String;
                    final fechaCompleta = s['fechaCompleta'] as String;
                    final fechaRelativa = s['fechaRelativa'] as String;
                    final fotoUrl = s['fotoUrl'] as String?;
                    final estudianteData = s['estudianteData'] as Map<String, dynamic>?;
                    final esAsignado = s['esAsignado'] as bool;
                    
                    // Color especial para la próxima tutoría
                    final isNext = index == 0;
                    
                    return GestureDetector(
                      onTap: () => _mostrarDetallesTutoria(sesion, nombreEstudiante, fotoUrl, estudianteData),
                      child: _buildTutoriaCard(
                        sesion.curso ?? 'Sin curso',
                        fechaCompleta,
                        fechaRelativa,
                        nombreEstudiante,
                        isNext ? Colors.orange : (esAsignado ? Colors.green : Colors.deepPurple),
                        isNext: isNext,
                        esAsignado: esAsignado,
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTutoriaCard(
    String subject,
    String time,
    String relativeTime,
    String students,
    Color color, {
    bool isNext = false,
    bool esAsignado = false,
  }) {
    return Card(
      elevation: isNext ? 4 : 2,
      color: esAsignado ? Colors.green[50] : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isNext 
            ? BorderSide(color: Colors.orange, width: 2) 
            : (esAsignado ? BorderSide(color: Colors.green, width: 2) : BorderSide.none),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isNext)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'PRÓXIMA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (esAsignado && !isNext)
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
                    Icon(Icons.star, color: Colors.white, size: 10),
                    SizedBox(width: 2),
                    Text(
                      'ASIGNADO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              subject,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: esAsignado ? Colors.green[800] : Colors.black,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              relativeTime,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              time,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              students,
              style: TextStyle(
                color: esAsignado ? Colors.green[700] : Color(0xFFAAAAAA),
                fontSize: 11,
                fontWeight: esAsignado ? FontWeight.w600 : FontWeight.normal,
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
            return FutureBuilder<Map<String, dynamic>>(
              future: Future.wait([
                FirebaseFirestore.instance.collection('estudiantes').doc(estudianteId).get(),
                FirebaseFirestore.instance.collection('tutores').doc(user!.uid).get(),
              ]).then((results) async {
                final estudianteDoc = results[0];
                final tutorDoc = results[1];
                
                String? fotoUrl;
                if (estudianteDoc.exists) {
                  final data = estudianteDoc.data() as Map<String, dynamic>?;
                  fotoUrl = data?['photoUrl'] as String?;
                }
                
                // Verificar si el estudiante está asignado
                bool esAsignado = false;
                if (tutorDoc.exists) {
                  final tutorData = tutorDoc.data() as Map<String, dynamic>?;
                  final estudiantesAsignados = (tutorData?['estudiantes_asignados'] as List<dynamic>?)?.cast<String>() ?? [];
                  esAsignado = estudiantesAsignados.contains(estudianteId);
                }
                
                return {
                  'fotoUrl': fotoUrl,
                  'esAsignado': esAsignado,
                };
              }),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Card(
                    color: const Color(0xFFF6F3FF),
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(
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
                                  nombreEstudiante,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  curso,
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
                  );
                }
                
                final fotoUrl = snapshot.data?['fotoUrl'] as String?;
                final esAsignado = snapshot.data?['esAsignado'] as bool? ?? false;
                
                return _buildRequestCard(
                  nombreEstudiante,
                  curso,
                  '', // ya no mostramos la fecha aquí
                  solicitud.id,
                  fotoUrl,
                  esAsignado,
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildRequestCard(String student, String subject, String time, String solicitudId, String? fotoUrl, bool esAsignado) {
    return Card(
      color: esAsignado ? Colors.green[50] : const Color(0xFFF6F3FF),
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: esAsignado ? BorderSide(color: Colors.green, width: 2) : BorderSide.none,
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
                      backgroundColor: esAsignado ? Colors.green : const Color(0xFFD1C4E9),
                      backgroundImage: NetworkImage(fotoUrl),
                      onBackgroundImageError: (_, __) {},
                    )
                  : CircleAvatar(
                      radius: 20,
                      backgroundColor: esAsignado ? Colors.green : const Color(0xFFD1C4E9),
                      child: Icon(Icons.person, color: esAsignado ? Colors.white : const Color(0xFF5E35B1)),
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
                            student,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: esAsignado ? Colors.green[800] : Colors.black,
                            ),
                          ),
                        ),
                        if (esAsignado)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                    const SizedBox(height: 4),
                    Text(
                      subject,
                      style: TextStyle(
                        color: esAsignado ? Colors.green[700] : Colors.black54,
                        fontSize: 14,
                        fontWeight: esAsignado ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: esAsignado ? Colors.green : Colors.grey),
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

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final difference = sessionDate.difference(today);

    if (difference.inDays == 0) {
      return 'Hoy';
    } else if (difference.inDays == 1) {
      return 'Mañana';
    } else if (difference.inDays > 1 && difference.inDays < 7) {
      return 'En ${difference.inDays} días';
    } else {
      return DateFormat('dd MMM').format(dateTime);
    }
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diferencia = now.difference(dateTime);

    if (diferencia.inDays > 365) {
      return 'En ${(diferencia.inDays / 365).round()} años';
    } else if (diferencia.inDays > 30) {
      return 'En ${(diferencia.inDays / 30).round()} meses';
    } else if (diferencia.inDays > 0) {
      return 'En ${diferencia.inDays} días';
    } else if (diferencia.inHours > 0) {
      return 'En ${diferencia.inHours} horas';
    } else if (diferencia.inMinutes > 0) {
      return 'En ${diferencia.inMinutes} minutos';
    } else {
      return 'Ahora';
    }
  }
}