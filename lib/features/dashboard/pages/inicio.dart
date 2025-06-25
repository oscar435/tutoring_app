import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tutoring_app/core/storage/preferencias_usuario.dart';
import 'package:tutoring_app/features/calendario/pages/CalendarioPage.dart';
import 'package:tutoring_app/features/perfil/pages/student_profile_page.dart';
import 'package:tutoring_app/features/materiales/pages/material_educativo_page.dart';
import 'package:tutoring_app/features/notificaciones/pages/notificaciones_page.dart';
import 'package:tutoring_app/features/tutorias/pages/TodasTutoriasPage.dart';
import 'package:tutoring_app/features/tutorias/pages/agendar_tutoria_page.dart';
import 'package:tutoring_app/core/models/solicitud_tutoria.dart';
import 'package:intl/intl.dart';
import 'package:tutoring_app/routes/app_routes.dart';
import 'package:tutoring_app/features/notificaciones/widgets/notification_badge.dart';

class HomePage2 extends StatelessWidget {
  static const routeName = '/home2';
  const HomePage2({super.key});

  Future<DocumentSnapshot?> _getAssignedTutor(String studentId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('tutores')
        .where('estudiantes_asignados', arrayContains: studentId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Error: No hay usuario')));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
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
                  (route) => false,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Tu cuenta ha sido desactivada. Contacta al administrador.',
                    ),
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
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
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
          drawer: _buildCustomDrawer(context, user.uid),
          body: SafeArea(
            child: Builder(
              builder: (context) => SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(context),
                    const SizedBox(height: 20),
                    _buildAssignedTutorCard(user.uid),
                    _buildSectionTitle(
                      'Tutorías agendadas',
                      trailing: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TodasTutoriasPage(),
                            ),
                          );
                        },
                        child: const Text('Ver todas'),
                      ),
                    ),
                    _buildSolicitudesEstudiante(user.uid),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Nuestros Servicios'),
                    Row(
                      children: [
                        Expanded(
                          child: _buildServiceCard(
                            context,
                            'TUTORÍAS',
                            Icons.school,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildServiceCard(
                            context,
                            'AYUDA PSICOPEDAGÓGICA',
                            Icons.psychology,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSectionTitle(
                      'Noticias recientes',
                      trailing: TextButton(
                        onPressed: () {
                          // Navegación a noticias - implementación básica
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Funcionalidad de noticias en desarrollo',
                              ),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: const Text('Todas las noticias'),
                      ),
                    ),
                    _buildNewsList(),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Eventos'),
                    _buildEventCard('21 Mayo', 'Encuesta estudiantil'),
                    const SizedBox(height: 20),
                    _buildSectionTitle(
                      'Materiales disponibles',
                      trailing: TextButton(
                        onPressed: () {
                          // Navegación a materiales educativos
                          Navigator.pushNamed(context, AppRoutes.materials);
                        },
                        child: const Text('Ver todos'),
                      ),
                    ),
                    _buildMaterialsRow(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Drawer _buildCustomDrawer(BuildContext context, String userId) {
    return Drawer(
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('estudiantes')
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Drawer(
              child: Center(child: Text('Error al cargar datos')),
            );
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Drawer(
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final nombre = userData['nombre'] ?? '';
          final apellidos = userData['apellidos'] ?? '';
          final codigo = userData['codigo_estudiante'] ?? '';
          final photoUrl = userData['photoUrl'] ?? '';

          return Column(
            children: [
              UserAccountsDrawerHeader(
                accountName: Text('$nombre $apellidos'),
                accountEmail: Text(codigo),
                currentAccountPicture: CircleAvatar(
                  backgroundImage: photoUrl.isNotEmpty
                      ? NetworkImage(photoUrl)
                      : const AssetImage('assets/avatar.jpg') as ImageProvider,
                ),
              ),
              Expanded(
                child: Container(
                  color: const Color(0xff060628),
                  child: ListView(
                    children: [
                      _buildDrawerItem(
                        context,
                        Icons.home,
                        'Inicio',
                        () => Navigator.pop(context),
                      ),
                      _buildDrawerItem(context, Icons.person, 'Mi Perfil', () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StudentProfilePage(),
                          ),
                        );
                      }),
                      _buildDrawerItem(
                        context,
                        Icons.calendar_today,
                        'Calendario',
                        () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CalendarioPage(),
                            ),
                          );
                        },
                      ),
                      _buildDrawerItem(
                        context,
                        Icons.book_online,
                        'Tutorías agendadas',
                        () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TodasTutoriasPage(),
                            ),
                          );
                        },
                      ),
                      _buildDrawerItem(
                        context,
                        Icons.menu_book,
                        'Material Educativo',
                        () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const MaterialEducativoPage(),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.white),
                        title: const Text(
                          'Cerrar sesión',
                          style: TextStyle(color: Colors.white),
                        ),
                        onTap: () async {
                          await FirebaseAuth.instance.signOut();
                          final prefs = PreferenciasUsuario();
                          await prefs.clearUserSession();
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            AppRoutes.roleSelector,
                            (route) => false,
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

  ListTile _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
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
              _buildNotificationIcon(context, ''),
              const SizedBox(width: 10),
              CircleAvatar(
                backgroundImage: AssetImage('assets/avatar.jpg'),
                radius: 18,
              ),
            ],
          ),
        ],
      );
    }
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('estudiantes')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        String photoUrl = '';
        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          photoUrl = userData['photoUrl'] ?? '';
        }
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
                _buildNotificationIcon(context, user.uid),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StudentProfilePage(),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    backgroundImage: photoUrl.isNotEmpty
                        ? NetworkImage(photoUrl)
                        : const AssetImage('assets/avatar.jpg')
                              as ImageProvider,
                    radius: 18,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationIcon(BuildContext context, String usuarioId) {
    if (usuarioId.isEmpty) {
      return IconButton(
        icon: const Icon(Icons.notifications, size: 28),
        onPressed: () {},
      );
    }

    return NotificationBadge(
      child: IconButton(
        icon: const Icon(Icons.notifications, size: 28),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NotificacionesPage()),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, {Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildSolicitudesEstudiante(String estudianteId) {
    return StreamBuilder<List<SolicitudTutoria>>(
      stream: _streamSolicitudesPorEstudiante(estudianteId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No tienes tutorías agendadas.'));
        }
        final solicitudes = snapshot.data!;
        return SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: solicitudes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final solicitud = solicitudes[index];
              String fechaTexto = '';
              if (solicitud.fechaSesion != null &&
                  (solicitud.horaInicio ?? '').isNotEmpty) {
                fechaTexto =
                    '${solicitud.dia ?? ''} ${DateFormat('dd/MM/yyyy').format(solicitud.fechaSesion!)} - ${solicitud.horaInicio}';
              } else {
                fechaTexto =
                    '${solicitud.dia ?? ''} - ${solicitud.horaInicio ?? ''}';
              }
              Color estadoColor;
              switch (solicitud.estado) {
                case 'aceptada':
                  estadoColor = Colors.green;
                  break;
                case 'rechazada':
                  estadoColor = Colors.red;
                  break;
                default:
                  estadoColor = Colors.orange;
              }
              return GestureDetector(
                onTap: () => _mostrarDetalleSolicitud(context, solicitud),
                child: Container(
                  width: 180,
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        solicitud.curso ?? 'Sin curso',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fechaTexto,
                        style: const TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: estadoColor.withAlpha(
                                (0.15 * 255).toInt(),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              solicitud.estado.toUpperCase(),
                              style: TextStyle(
                                color: estadoColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Stream<List<SolicitudTutoria>> _streamSolicitudesPorEstudiante(
    String estudianteId,
  ) {
    return FirebaseFirestore.instance
        .collection('solicitudes_tutoria')
        .where('estudianteId', isEqualTo: estudianteId)
        .orderBy('fechaHora', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => SolicitudTutoria.fromMap(doc.data()))
              .toList();
        });
  }

  void _mostrarDetalleSolicitud(
    BuildContext context,
    SolicitudTutoria solicitud,
  ) async {
    // Obtener nombre del tutor
    String nombreTutor = 'Tutor';
    if (solicitud.tutorId.isNotEmpty) {
      final doc = await FirebaseFirestore.instance
          .collection('tutores')
          .doc(solicitud.tutorId)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final nombre = data['nombre'] ?? '';
        final apellidos = data['apellidos'] ?? '';
        nombreTutor = ('$nombre $apellidos').trim().isEmpty
            ? 'Tutor'
            : '$nombre $apellidos';
      }
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.45,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.school, color: Colors.deepPurple, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      solicitud.curso ?? 'Sin curso',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _detalleItem('Estado', solicitud.estado.toUpperCase()),
              if (solicitud.fechaSesion != null &&
                  (solicitud.horaInicio ?? '').isNotEmpty &&
                  (solicitud.horaFin ?? '').isNotEmpty)
                _detalleItem(
                  'Fecha y hora',
                  '${DateFormat('dd/MM/yyyy').format(solicitud.fechaSesion!)} ${solicitud.horaInicio} - ${solicitud.horaFin}',
                ),
              if (solicitud.mensaje != null && solicitud.mensaje!.isNotEmpty)
                _detalleItem('Mensaje', solicitud.mensaje!),
              _detalleItem('Tutor', nombreTutor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detalleItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalCards(List<Widget> cards) {
    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: cards
            .map(
              (card) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: card,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildCard(String text, IconData icon, Color color) {
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
  ) {
    return GestureDetector(
      onTap: title == 'TUTORÍAS'
          ? () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SeleccionarTutorPage(estudianteId: user.uid),
                ),
              );
            }
          : null,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsList() {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Image.asset('assets/news.png'),
              const Text(
                'FIEI da la bienvenida a sus ingresantes 2025',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            children: [
              Image.asset('assets/news2.png'),
              const Text(
                'Villarrealinos presentan muestra escultórica',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(String date, String description) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            date,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsRow() {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Image.asset('assets/info_curso.jpg'),
              const Text(
                'Introducción a la Ingeniería Informática',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            children: [
              Image.asset('assets/oratoria_curso.jpg'),
              const Text(
                'Dominar la oratoria y el discurso',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAssignedTutorCard(String studentId) {
    return FutureBuilder<DocumentSnapshot?>(
      future: _getAssignedTutor(studentId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          // Si no hay tutor asignado o está cargando, no muestra nada.
          return const SizedBox.shrink();
        }

        final tutorData = snapshot.data!.data() as Map<String, dynamic>;
        final tutorId = snapshot.data!.id;
        final photoUrl = tutorData['photoUrl'] as String? ?? '';
        final nombre = tutorData['nombre'] as String? ?? 'Tutor';
        final apellidos = tutorData['apellidos'] as String? ?? '';
        final especialidad =
            tutorData['especialidad'] as String? ?? 'Especialista';

        return Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MI TUTOR ASIGNADO',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                    fontSize: 14,
                  ),
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: photoUrl.isNotEmpty
                          ? NetworkImage(photoUrl)
                          : const AssetImage('assets/teacher_avatar.jpg')
                                as ImageProvider,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$nombre $apellidos',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            especialidad,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.calendar_today,
                        color: Colors.deepPurple,
                        size: 28,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AgendarTutoriaPage(
                              tutorId: tutorId,
                              estudianteId: studentId,
                            ),
                          ),
                        );
                      },
                      tooltip: 'Agendar Tutoría',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class SeleccionarTutorPage extends StatefulWidget {
  final String estudianteId;
  const SeleccionarTutorPage({required this.estudianteId, super.key});

  @override
  State<SeleccionarTutorPage> createState() => _SeleccionarTutorPageState();
}

class _SeleccionarTutorPageState extends State<SeleccionarTutorPage> {
  String _busqueda = '';
  final TextEditingController _busquedaController = TextEditingController();
  late Future<List<QueryDocumentSnapshot>> _tutoresFuture;
  late Future<String?> _assignedTutorIdFuture;
  String? _escuelaSeleccionada;

  final List<String> _escuelas = [
    'Ingeniería Informática',
    'Ingeniería Electrónica',
    'Ingeniería de Telecomunicaciones',
    'Ingeniería Mecatrónica',
  ];

  @override
  void initState() {
    super.initState();
    _tutoresFuture = _obtenerTutores();
    _assignedTutorIdFuture = _getAssignedTutorId(widget.estudianteId);
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<List<QueryDocumentSnapshot>> _obtenerTutores() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('tutores')
        .get();
    return snapshot.docs;
  }

  Future<String?> _getAssignedTutorId(String studentId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('tutores')
        .where('estudiantes_asignados', arrayContains: studentId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.id;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Seleccionar Tutor')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _busquedaController,
                        decoration: InputDecoration(
                          hintText: 'Buscar tutor por nombre o apellido',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) => setState(() => _busqueda = value),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _busqueda = '';
                          _busquedaController.clear();
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _escuelaSeleccionada,
                  hint: const Text('Filtrar por Escuela Profesional'),
                  isExpanded: true,
                  items: _escuelas.map((String school) {
                    return DropdownMenuItem<String>(
                      value: school,
                      child: Text(school),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _escuelaSeleccionada = newValue;
                    });
                  },
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: Future.wait([_tutoresFuture, _assignedTutorIdFuture]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(
                    child: Text('No se encontraron tutores.'),
                  );
                }

                final tutores =
                    snapshot.data![0] as List<QueryDocumentSnapshot>;
                final assignedTutorId = snapshot.data![1] as String?;

                // Lógica de filtrado
                List<QueryDocumentSnapshot> filtrados = List.from(tutores);

                // 1. Filtrado por búsqueda de texto
                if (_busqueda.isNotEmpty) {
                  filtrados = filtrados.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final nombreCompleto =
                        '${data['nombre'] ?? ''} ${data['apellidos'] ?? ''}'
                            .toLowerCase();
                    return nombreCompleto.contains(_busqueda.toLowerCase());
                  }).toList();
                }

                // 2. Filtrado por escuela profesional
                if (_escuelaSeleccionada != null) {
                  filtrados = filtrados.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    // El campo se llama 'escuela' en Firestore
                    return data['escuela'] == _escuelaSeleccionada;
                  }).toList();
                }

                // Reordenar para poner al tutor asignado primero
                if (assignedTutorId != null) {
                  filtrados.sort((a, b) {
                    if (a.id == assignedTutorId) return -1;
                    if (b.id == assignedTutorId) return 1;
                    return 0;
                  });
                }

                return ListView.builder(
                  itemCount: filtrados.length,
                  itemBuilder: (context, index) {
                    final tutorDoc = filtrados[index];
                    final tutorData = tutorDoc.data() as Map<String, dynamic>;
                    final esAsignado = tutorDoc.id == assignedTutorId;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      color: esAsignado ? Colors.deepPurple[50] : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundImage:
                              (tutorData['photoUrl'] as String? ?? '')
                                  .isNotEmpty
                              ? NetworkImage(tutorData['photoUrl'])
                              : const AssetImage('assets/teacher_avatar.jpg')
                                    as ImageProvider,
                        ),
                        title: Text(
                          '${tutorData['nombre'] ?? ''} ${tutorData['apellidos'] ?? ''}',
                        ),
                        subtitle: Text(
                          tutorData['especialidad'] ?? 'Especialista',
                        ),
                        trailing: esAsignado
                            ? const Chip(
                                label: Text('Asignado'),
                                avatar: Icon(
                                  Icons.star,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                backgroundColor: Colors.deepPurple,
                                labelStyle: TextStyle(color: Colors.white),
                              )
                            : const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AgendarTutoriaPage(
                                tutorId: tutorDoc.id,
                                estudianteId: widget.estudianteId,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
