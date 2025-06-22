import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/admin_user.dart';
import '../widgets/recent_activity_widget.dart';
import '../widgets/role_distribution_chart.dart';
import '../services/report_service.dart';
import 'user_management_page.dart';
import 'audit_logs_page.dart';
import 'package:tutoring_app/features/admin/pages/audit_logs_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ReportService _reportService = ReportService();
  Map<String, dynamic> _roleReport = {};
  AdminUser? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    // Cargar datos en paralelo
    final results = await Future.wait([
      _fetchCurrentUser(),
      _fetchRoleReport(),
    ]);

    final user = results[0] as AdminUser?;
    final report = results[1] as Map<String, dynamic>?;

    if (mounted) {
      setState(() {
        _currentUser = user;
        if (report != null) {
          _roleReport = report;
        }
        _isLoading = false;
      });
    }
  }

  Future<AdminUser?> _fetchCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return AdminUser.fromFirestore(doc);
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error cargando usuario: $e')));
    }
    return null;
  }

  Future<Map<String, dynamic>?> _fetchRoleReport() async {
     try {
      final usersSnapshot = await _firestore.collection('users').get();
      final Map<String, int> roleCount = {
        'student': 0, 'teacher': 0, 'admin': 0, 'superAdmin': 0,
      };

      for (var doc in usersSnapshot.docs) {
        final role = (doc.data() as Map<String, dynamic>)['role'] as String? ?? 'student';
        roleCount[role] = (roleCount[role] ?? 0) + 1;
      }
      return {'byRole': roleCount, 'total': usersSnapshot.docs.length};
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error cargando estadísticas: $e')));
      return null;
    }
  }

  Future<void> _handleLogout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión: $e')),
      );
    }
  }

  Future<void> _exportReport() async {
    try {
      setState(() => _isLoading = true);
      
      final filePath = await _reportService.exportToCSV();
      
      if (mounted) {
        setState(() => _isLoading = false);

        String message;
        if (filePath != null) {
          // Para Mobile/Desktop
          message = 'Reporte de usuarios exportado exitosamente a: $filePath';
        } else {
          // Para Web
          message = 'La descarga del reporte de usuarios ha comenzado.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar reporte: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportTutoringReport() async {
    try {
      setState(() => _isLoading = true);
      
      final filePath = await _reportService.exportTutoringToCSV();
      
      if (mounted) {
        setState(() => _isLoading = false);

        String message;
        if (filePath != null) {
          // Para Mobile/Desktop
          message = 'Reporte de tutorías exportado exitosamente a: $filePath';
        } else {
          // Para Web
          message = 'La descarga del reporte de tutorías ha comenzado.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar reporte de tutorías: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showReportDetails(String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reporte Exportado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('El reporte se ha exportado exitosamente.'),
            const SizedBox(height: 8),
            Text('Ubicación: $filePath'),
            const SizedBox(height: 16),
            const Text(
              'El archivo contiene:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('• Resumen estadístico'),
            const Text('• Distribución por rol'),
            const Text('• Detalles de todos los usuarios'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue[700],
              ),
              child: _currentUser == null
                  ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 30,
                          child: Icon(
                            Icons.person_outline,
                            size: 35,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _currentUser!.nombre.isNotEmpty ? _currentUser!.fullName : _currentUser!.email,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentUser!.roleDisplayName,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              selected: true,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Gestión de Usuarios'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserManagementPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Registros de Auditoría'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AuditLogsPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Resumen del Sistema',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _exportReport,
                            icon: const Icon(Icons.download),
                            label: const Text('Reporte Usuarios'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _exportTutoringReport,
                            icon: const Icon(Icons.school),
                            label: const Text('Reporte Tutorías'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[700],
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const UserManagementPage(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.people),
                            label: const Text('Gestionar Usuarios'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[700],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total de Usuarios',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${_roleReport['total'] ?? 0}',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tutores Activos',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${(_roleReport['byRole'] ?? {})['teacher'] ?? 0}',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Estudiantes Registrados',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${(_roleReport['byRole'] ?? {})['student'] ?? 0}',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: RoleDistributionChart(
                          data: _roleReport['byRole'] ?? {},
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        flex: 3,
                        child: RecentActivityWidget(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
} 