import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tutoring_app/pages/CalendarioPage.dart';
import 'package:tutoring_app/pages/login_pages.dart';
import 'package:tutoring_app/pages/student_profile_page.dart';
import 'package:tutoring_app/pages/material_educativo_page.dart';
import 'package:tutoring_app/pages/notificaciones_page.dart';
import 'agendar_tutoria_page.dart';

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
                _buildSectionTitle('Tutorías agendadas', trailing: 'Todas'),
                _buildHorizontalCards([
                  _buildCard(
                    'Mayo 30 - 7:00 pm',
                    Icons.calendar_today,
                    Colors.pinkAccent,
                  ),
                  _buildCard(
                    'Junio 05 - 5:00 pm',
                    Icons.calendar_today,
                    Colors.lightBlue,
                  ),
                ]),
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
                  trailing: 'Todas las noticias',
                ),
                _buildNewsList(),
                const SizedBox(height: 20),
                _buildSectionTitle('Eventos'),
                _buildEventCard('21 Mayo', 'Encuesta estudiantil'),
                const SizedBox(height: 20),
                _buildSectionTitle(
                  'Materiales disponibles',
                  trailing: 'All Courses',
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
                            LoginPage.routeName,
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

  Widget _buildSectionTitle(String title, {String? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (trailing != null)
          Text(
            trailing,
            style: const TextStyle(color: Colors.orange, fontSize: 14),
          ),
      ],
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

class SeleccionarTutorPage extends StatelessWidget {
  final String estudianteId;
  const SeleccionarTutorPage({required this.estudianteId, Key? key}) : super(key: key);

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
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final tutorId = docs[index].id;
              final nombre = data['nombre'] ?? '';
              final apellidos = data['apellidos'] ?? '';
              final especialidad = data['especialidad'] ?? '';
              final universidad = data['universidad'] ?? '';
              final photoUrl = data['photoUrl'] ?? '';
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: photoUrl.isNotEmpty
                        ? NetworkImage(photoUrl)
                        : const AssetImage('assets/avatar.jpg') as ImageProvider,
                  ),
                  title: Text('$nombre $apellidos'),
                  subtitle: Text('$especialidad\n$universidad'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AgendarTutoriaPage(
                          tutorId: tutorId,
                          estudianteId: estudianteId,
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
    );
  }
}
