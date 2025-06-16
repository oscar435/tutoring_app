import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tutoring_app/pages/CalendarioPage.dart';
import 'package:tutoring_app/pages/login_pages.dart';
import 'package:tutoring_app/pages/student_profile_page.dart';
import 'package:tutoring_app/pages/material_educativo_page.dart';
import 'package:tutoring_app/pages/notificaciones_page.dart';
import 'package:tutoring_app/pages/TodasTutoriasPage.dart';
import 'agendar_tutoria_page.dart';
import '../service/solicitud_tutoria_service.dart';
import '../models/solicitud_tutoria.dart';
import 'package:intl/intl.dart';
import 'package:tutoring_app/routes/app_routes.dart';

class HomePage2 extends StatelessWidget {
  static const routeName = '/home2';
  const HomePage2({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Error: No hay usuario')));

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
                _buildSectionTitle(
                  'Tutorías agendadas',
                  trailing: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TodasTutoriasPage()),
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
                      // TODO: Implementar navegación a noticias
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
                      // TODO: Implementar navegación a cursos
                    },
                    child: const Text('All Courses'),
                  ),
                ),
                _buildMaterialsRow(),
              ],
            ),
          ),
        ),
      ),
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
                        : const AssetImage('assets/avatar.jpg') as ImageProvider,
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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notificaciones')
          .where('usuarioId', isEqualTo: usuarioId)
          .where('leida', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        int count = 0;
        if (snapshot.hasData) {
          count = snapshot.data!.docs.length;
        }
        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications, size: 28),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificacionesPage(usuarioId: usuarioId),
                  ),
                );
              },
            ),
            if (count > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCustomDrawer(BuildContext context, String userId) {
    return Drawer(
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('estudiantes')
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar datos'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final nombre = userData['nombre'] ?? '';
          final apellidos = userData['apellidos'] ?? '';
          final codigo = userData['codigo_estudiante'] ?? '';
          final photoUrl = userData['photoUrl'] ?? '';

          return Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: photoUrl.isNotEmpty
                          ? NetworkImage(photoUrl)
                          : const AssetImage('assets/avatar.jpg') as ImageProvider,
                      radius: 30,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$nombre $apellidos',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(codigo, style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 5),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  color: const Color(0xFF0B1120),
                  child: ListView(
                    children: [
                      _buildDrawerItem(Icons.home, 'Inicio', context, null),
                      _buildDrawerItem(
                        Icons.book_online,
                        'Tutorías agendadas',
                        context,
                        null,
                      ),
                      _buildDrawerItem(
                        Icons.calendar_month,
                        'Calendario académico',
                        context,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CalendarioPage(),
                            ),
                          );
                        },
                      ),
                      _buildDrawerItem(
                        Icons.menu_book,
                        'Material Educativo',
                        context,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MaterialEducativoPage(),
                            ),
                          );
                        },
                      ),
                      _buildDrawerItem(Icons.person, 'Perfil', context, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StudentProfilePage(),
                          ),
                        );
                      }),
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
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap:
          onTap ??
          () {
            Navigator.pop(
              context,
            ); // Cierra el Drawer si no hay acción específica
          },
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
              if (solicitud.fechaSesion != null && (solicitud.horaInicio ?? '').isNotEmpty) {
                fechaTexto = '${solicitud.dia ?? ''} ${DateFormat('dd/MM/yyyy').format(solicitud.fechaSesion!)} - ${solicitud.horaInicio}';
              } else {
                fechaTexto = '${solicitud.dia ?? ''} - ${solicitud.horaInicio ?? ''}';
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
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fechaTexto,
                        style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.w500, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: estadoColor.withOpacity(0.15),
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

  Stream<List<SolicitudTutoria>> _streamSolicitudesPorEstudiante(String estudianteId) {
    return FirebaseFirestore.instance
        .collection('solicitudes_tutoria')
        .where('estudianteId', isEqualTo: estudianteId)
        .orderBy('fechaHora', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SolicitudTutoria.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  void _mostrarDetalleSolicitud(BuildContext context, SolicitudTutoria solicitud) async {
    // Obtener nombre del tutor
    String nombreTutor = 'Tutor';
    if (solicitud.tutorId.isNotEmpty) {
      final doc = await FirebaseFirestore.instance.collection('tutores').doc(solicitud.tutorId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final nombre = data['nombre'] ?? '';
        final apellidos = data['apellidos'] ?? '';
        nombreTutor = ('$nombre $apellidos').trim().isEmpty ? 'Tutor' : '$nombre $apellidos';
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
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _detalleItem('Estado', solicitud.estado.toUpperCase()),
              if (solicitud.fechaSesion != null && (solicitud.horaInicio ?? '').isNotEmpty && (solicitud.horaFin ?? '').isNotEmpty)
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
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
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
            child: Text(text, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, String title, IconData icon, Color color) {
    return GestureDetector(
      onTap: title == 'TUTORÍAS'
          ? () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SeleccionarTutorPage(estudianteId: user.uid),
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
              child: Text(title, style: const TextStyle(color: Colors.white)),
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
              const Text('FIEI da la bienvenida a sus ingresantes 2025'),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            children: [
              Image.asset('assets/news2.png'),
              const Text('Villarrealinos presentan muestra escultórica'),
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
          Text(description, style: const TextStyle(color: Colors.white)),
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
              const Text('Introducción a la Ingeniería Informática'),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            children: [
              Image.asset('assets/oratoria_curso.jpg'),
              const Text('Dominar la oratoria y el discurso'),
            ],
          ),
        ),
      ],
    );
  }
}

class SeleccionarTutorPage extends StatefulWidget {
  final String estudianteId;
  const SeleccionarTutorPage({required this.estudianteId, Key? key}) : super(key: key);

  @override
  State<SeleccionarTutorPage> createState() => _SeleccionarTutorPageState();
}

class _SeleccionarTutorPageState extends State<SeleccionarTutorPage> {
  String _busqueda = '';
  String _escuelaSeleccionada = 'Todas';
  final TextEditingController _busquedaController = TextEditingController();
  List<String> _escuelasDisponibles = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Seleccionar Tutor')),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('tutores').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          final docs = (snapshot.data as QuerySnapshot).docs;
          if (docs.isEmpty) return Center(child: Text('No hay tutores disponibles.'));

          // Obtener escuelas disponibles entre los tutores
          final escuelasSet = <String>{};
          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final escuela = (data['escuela'] ?? '').toString();
            if (escuela.isNotEmpty) escuelasSet.add(escuela);
          }
          _escuelasDisponibles = ['Todas', ...escuelasSet.toList()..sort()];

          // Filtrar tutores
          final tutoresFiltrados = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final nombre = (data['nombre'] ?? '').toString().toLowerCase();
            final apellidos = (data['apellidos'] ?? '').toString().toLowerCase();
            final escuela = (data['escuela'] ?? '').toString();
            final coincideBusqueda = nombre.contains(_busqueda.toLowerCase()) || apellidos.contains(_busqueda.toLowerCase());
            final coincideEscuela = _escuelaSeleccionada == 'Todas' || escuela == _escuelaSeleccionada;
            return coincideBusqueda && coincideEscuela;
          }).toList();

          return Column(
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
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                              _escuelaSeleccionada = 'Todas';
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _escuelasDisponibles.map((escuela) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ChoiceChip(
                            label: Text(escuela),
                            selected: _escuelaSeleccionada == escuela,
                            onSelected: (selected) => setState(() => _escuelaSeleccionada = escuela),
                          ),
                        )).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: tutoresFiltrados.isEmpty
                    ? Center(child: Text('No se encontraron tutores.'))
                    : ListView.builder(
                        itemCount: tutoresFiltrados.length,
                        itemBuilder: (context, index) {
                          final data = tutoresFiltrados[index].data() as Map<String, dynamic>;
                          final tutorId = tutoresFiltrados[index].id;
                          final nombre = data['nombre'] ?? '';
                          final apellidos = data['apellidos'] ?? '';
                          final especialidad = data['especialidad'] ?? '';
                          final universidad = data['universidad'] ?? '';
                          final photoUrl = data['photoUrl'] ?? '';
                          final cursos = (data['cursos'] as List?)?.cast<String>() ?? [];
                          final ciclo = data['ciclo'] ?? '';
                          return Card(
                            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            elevation: 3,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () => _mostrarDetalleTutor(context, data, tutorId),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 32,
                                      backgroundImage: photoUrl.isNotEmpty
                                          ? NetworkImage(photoUrl)
                                          : null,
                                      child: photoUrl.isEmpty ? Icon(Icons.person, size: 32) : null,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('$nombre $apellidos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                          Text(especialidad, style: TextStyle(fontWeight: FontWeight.w500, color: Colors.deepPurple)),
                                          Text(universidad, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                                          if (ciclo != null && ciclo.toString().isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 2.0),
                                              child: Text('Ciclo: $ciclo', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                            ),
                                          if (cursos.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 8.0),
                                              child: Wrap(
                                                spacing: 8,
                                                children: cursos.map((c) => Chip(label: Text(c), backgroundColor: Colors.deepPurple[50])).toList(),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.deepPurple,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: Text('Agendar'),
                                      onPressed: () => _mostrarDetalleTutor(context, data, tutorId, agendar: true),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _mostrarDetalleTutor(BuildContext context, Map<String, dynamic> data, String tutorId, {bool agendar = false}) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (context) {
        final cursos = (data['cursos'] as List?)?.cast<String>() ?? [];
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundImage: (data['photoUrl'] ?? '').toString().isNotEmpty
                        ? NetworkImage(data['photoUrl'])
                        : null,
                    child: (data['photoUrl'] ?? '').toString().isEmpty ? Icon(Icons.person, size: 36) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${data['nombre']} ${data['apellidos']}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                        Text(data['especialidad'] ?? '', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.deepPurple)),
                        Text(data['universidad'] ?? '', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                        if ((data['ciclo'] ?? '').toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text('Ciclo: ${data['ciclo']}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (cursos.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: cursos.map((c) => Chip(label: Text(c), backgroundColor: Colors.deepPurple[50])).toList(),
                ),
              if ((data['bio'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Sobre el tutor:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(data['bio'], style: TextStyle(fontSize: 15)),
              ],
              if ((data['experiencia'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Experiencia:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(data['experiencia'], style: TextStyle(fontSize: 15)),
              ],
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Agendar Tutoría'),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AgendarTutoriaPage(
                          tutorId: tutorId,
                          estudianteId: widget.estudianteId,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
