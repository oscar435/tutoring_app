import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutoring_app/core/utils/snackbar.dart';
import 'package:tutoring_app/routes/app_routes.dart';

class AdminDashboardPage extends StatefulWidget {
  static const String routeName = '/admin-dashboard';
  
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final user = FirebaseAuth.instance.currentUser;
  bool _isLoading = true;
  Map<String, dynamic>? _adminData;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    if (user == null) return;
    
    try {
      final doc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user!.uid)
          .get();
      
      if (doc.exists) {
        setState(() {
          _adminData = doc.data() as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        // Si no es admin, redirigir
        Navigator.pushReplacementNamed(context, AppRoutes.roleSelector);
      }
    } catch (e) {
      showSnackBar(context, "Error al cargar datos de administrador");
      Navigator.pushReplacementNamed(context, AppRoutes.roleSelector);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xfff7f7f7),
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, AppRoutes.roleSelector);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con información del admin
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.admin_panel_settings,
                    size: 48,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Bienvenido, ${_adminData?['nombre'] ?? 'Administrador'}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Panel de Control del Sistema',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Estadísticas rápidas
            const Text(
              'Estadísticas del Sistema',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('estudiantes').snapshots(),
              builder: (context, estudiantesSnapshot) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('tutores').snapshots(),
                  builder: (context, tutoresSnapshot) {
                    final totalEstudiantes = estudiantesSnapshot.data?.docs.length ?? 0;
                    final totalTutores = tutoresSnapshot.data?.docs.length ?? 0;
                    
                    return Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Estudiantes',
                            totalEstudiantes.toString(),
                            Icons.people,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Tutores',
                            totalTutores.toString(),
                            Icons.school,
                            Colors.green,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            
            const SizedBox(height: 32),
            
            // Funcionalidades administrativas
            const Text(
              'Funcionalidades Administrativas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildAdminCard(
                    'Gestión de Usuarios',
                    Icons.people_alt,
                    Colors.blue,
                    () => Navigator.pushNamed(context, '/admin-users'),
                  ),
                  _buildAdminCard(
                    'Gestión de Roles',
                    Icons.security,
                    Colors.orange,
                    () => Navigator.pushNamed(context, '/admin-roles'),
                  ),
                  _buildAdminCard(
                    'Reportes',
                    Icons.analytics,
                    Colors.green,
                    () => Navigator.pushNamed(context, '/admin-reports'),
                  ),
                  _buildAdminCard(
                    'Auditoría',
                    Icons.history,
                    Colors.purple,
                    () => Navigator.pushNamed(context, '/admin-audit'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 48),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 