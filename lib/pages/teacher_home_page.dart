import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tutoring_app/pages/CalendarioPage.dart';
import 'package:tutoring_app/pages/login_teacher_page.dart';

class TeacherHomePage extends StatelessWidget {
  static const routeName = '/teacher-home';
  const TeacherHomePage({Key? key}) : super(key: key);

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
          children: const [
            Icon(Icons.notifications, size: 28),
            SizedBox(width: 10),
            CircleAvatar(
              backgroundImage: AssetImage('assets/teacher_avatar.jpg'),
              radius: 18,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTeacherDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.deepPurple,
            child: Column(
              children: const [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: AssetImage('assets/teacher_avatar.jpg'),
                ),
                SizedBox(height: 10),
                Text(
                  'Prof. Juan Pérez',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Ingeniería de Software',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
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
                    Icons.people,
                    'Mis estudiantes',
                    context,
                    null,
                  ),
                  _buildDrawerItem(
                    Icons.assessment,
                    'Reportes',
                    context,
                    null,
                  ),
                  _buildDrawerItem(
                    Icons.settings,
                    'Configuración',
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
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: [
        _buildTutoriaCard(
          'Programación I',
          'Hoy - 3:00 PM',
          '4 estudiantes',
          Colors.blue,
        ),
        _buildTutoriaCard(
          'Base de Datos',
          'Mañana - 2:00 PM',
          '3 estudiantes',
          Colors.green,
        ),
        _buildTutoriaCard(
          'Algoritmos',
          'Vie - 4:00 PM',
          '5 estudiantes',
          Colors.orange,
        ),
        _buildTutoriaCard(
          'Estructuras',
          'Sáb - 10:00 AM',
          '2 estudiantes',
          Colors.purple,
        ),
      ],
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
            ),
            const Spacer(),
            Text(
              time,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              students,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
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
    return Column(
      children: [
        _buildRequestCard(
          'María García',
          'Programación I',
          'Mañana - 3:00 PM',
        ),
        _buildRequestCard(
          'Carlos López',
          'Base de Datos',
          'Jueves - 2:00 PM',
        ),
        _buildRequestCard(
          'Ana Martínez',
          'Algoritmos',
          'Viernes - 4:00 PM',
        ),
      ],
    );
  }

  Widget _buildRequestCard(String student, String subject, String time) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.person),
        ),
        title: Text(student),
        subtitle: Text('$subject\n$time'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () {},
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
} 