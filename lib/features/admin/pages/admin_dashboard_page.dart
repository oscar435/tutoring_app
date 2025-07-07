import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/admin_user.dart';
import '../widgets/recent_activity_widget.dart';
import '../widgets/role_distribution_chart.dart';
import '../services/report_service.dart';
import 'user_management_page.dart';
import 'audit_logs_page.dart';
import 'package:tutoring_app/features/admin/pages/admin_sessions_page.dart';
import 'package:tutoring_app/features/admin/pages/admin_requests_page.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../main.dart';
import 'incident_reports_page.dart';

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

  // NUEVO: Streams y datos para métricas
  Stream<QuerySnapshot>? _sesionesStream;
  Stream<QuerySnapshot>? _registrosPostSesionStream;
  int _totalSesiones = 0;
  int _aceptadas = 0;
  int _canceladas = 0;
  int _asistencias = 0;
  int _registrosPostSesion = 0;
  Stream<QuerySnapshot>? _solicitudesRechazadasStream;
  int _rechazadas = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _sesionesStream = _firestore.collection('sesiones_tutoria').snapshots();
    _registrosPostSesionStream = _firestore
        .collection('registros_post_sesion')
        .snapshots();
    _solicitudesRechazadasStream = _firestore
        .collection('solicitudes_tutoria')
        .where('estado', isEqualTo: 'rechazada')
        .snapshots();
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
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error cargando usuario: $e')));
    }
    return null;
  }

  Future<Map<String, dynamic>?> _fetchRoleReport() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      final Map<String, int> roleCount = {
        'student': 0,
        'teacher': 0,
        'admin': 0,
        'superAdmin': 0,
      };

      for (var doc in usersSnapshot.docs) {
        final role = (doc.data())['role'] as String? ?? 'student';
        roleCount[role] = (roleCount[role] ?? 0) + 1;
      }
      return {'byRole': roleCount, 'total': usersSnapshot.docs.length};
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando estadísticas: $e')),
        );
      return null;
    }
  }

  Future<void> _handleLogout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cerrar sesión: $e')));
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
            icon: const Icon(Icons.contrast),
            tooltip: 'Modo alto contraste',
            onPressed: () {
              Provider.of<ThemeProvider>(
                context,
                listen: false,
              ).toggleContrast();
            },
          ),
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
              decoration: BoxDecoration(color: Colors.blue[700]),
              child: _currentUser == null
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
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
                          _currentUser!.nombre.isNotEmpty
                              ? _currentUser!.fullName
                              : _currentUser!.email,
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
                            color: Colors.white.withAlpha((0.8 * 255).toInt()),
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
            ListTile(
              leading: const Icon(Icons.flag),
              title: const Text('Reportes de Incidentes'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const IncidentReportsPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: _sesionesStream,
              builder: (context, sesionesSnapshot) {
                if (sesionesSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final sesiones = sesionesSnapshot.data?.docs ?? [];
                _totalSesiones = sesiones.length;
                _aceptadas = sesiones
                    .where(
                      (doc) =>
                          doc['estado'] == 'aceptada' ||
                          doc['estado'] == 'completada',
                    )
                    .length;
                _canceladas = sesiones
                    .where((doc) => doc['estado'] == 'cancelada')
                    .length;

                return StreamBuilder<QuerySnapshot>(
                  stream: _registrosPostSesionStream,
                  builder: (context, registrosSnapshot) {
                    if (registrosSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final registros = registrosSnapshot.data?.docs ?? [];
                    _registrosPostSesion = registros.length;
                    _asistencias = registros
                        .where((doc) => doc['asistioEstudiante'] == true)
                        .length;

                    return StreamBuilder<QuerySnapshot>(
                      stream: _solicitudesRechazadasStream,
                      builder: (context, solicitudesSnapshot) {
                        if (solicitudesSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final solicitudes =
                            solicitudesSnapshot.data?.docs ?? [];
                        _rechazadas = solicitudes.length;

                        double pctAceptadas = _totalSesiones > 0
                            ? (_aceptadas / _totalSesiones) * 100
                            : 0;
                        double pctCanceladas =
                            (_totalSesiones + _rechazadas) > 0
                            ? (_rechazadas / (_totalSesiones + _rechazadas)) *
                                  100
                            : 0;
                        double pctAsistencia = _registrosPostSesion > 0
                            ? (_asistencias / _registrosPostSesion) * 100
                            : 0;

                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                        onPressed: _isLoading
                                            ? null
                                            : _exportReport,
                                        icon: const Icon(Icons.download),
                                        label: const Text('Reporte Usuarios'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green[700],
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: _isLoading
                                            ? null
                                            : _exportTutoringReport,
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
                                              builder: (context) =>
                                                  const UserManagementPage(),
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
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const AdminSessionsPage(),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.event_available),
                                        label: const Text('Sesiones Agendadas'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green[700],
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const AdminRequestsPage(),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.history),
                                        label: const Text(
                                          'Historial de Solicitudes',
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.purple[700],
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              // Tarjetas de métricas de usuarios
                              Row(
                                children: [
                                  Expanded(
                                    child: Card(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                              // Tarjetas de métricas de sesiones
                              Row(
                                children: [
                                  Expanded(
                                    child: Card(
                                      color: Colors.blue[50],
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Total de Sesiones',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '$_totalSesiones',
                                              style: TextStyle(
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
                                      color: Colors.green[50],
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              '% Sesiones Aceptadas',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '${(_totalSesiones > 0 ? (_aceptadas / _totalSesiones) * 100 : 0).toStringAsFixed(1)}%',
                                              style: TextStyle(
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
                                      color: Colors.red[50],
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              '% Solicitudes Rechazadas',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '${(_rechazadas + _aceptadas > 0 ? (_rechazadas / (_rechazadas + _aceptadas)) * 100 : 0).toStringAsFixed(1)}%',
                                              style: TextStyle(
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
                                      color: Colors.purple[50],
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              '% Asistencia',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '${pctAsistencia.toStringAsFixed(1)}%',
                                              style: TextStyle(
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
                              // Fila de gráficos y actividad reciente en 2 columnas
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      children: [
                                        Card(
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Distribución de Asistencias',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                Center(
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      SizedBox(
                                                        height: 180,
                                                        width: 180,
                                                        child: PieChart(
                                                          PieChartData(
                                                            sections: [
                                                              PieChartSectionData(
                                                                value: _asistencias
                                                                    .toDouble(),
                                                                color:
                                                                    Colors.blue,
                                                                title:
                                                                    _asistencias >
                                                                        0
                                                                    ? _asistencias
                                                                          .toString()
                                                                    : '',
                                                                titleStyle: const TextStyle(
                                                                  fontSize: 18,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                                radius: 60,
                                                              ),
                                                              PieChartSectionData(
                                                                value:
                                                                    (_registrosPostSesion -
                                                                            _asistencias)
                                                                        .toDouble(),
                                                                color: Colors
                                                                    .redAccent,
                                                                title:
                                                                    (_registrosPostSesion -
                                                                            _asistencias) >
                                                                        0
                                                                    ? (_registrosPostSesion -
                                                                              _asistencias)
                                                                          .toString()
                                                                    : '',
                                                                titleStyle: const TextStyle(
                                                                  fontSize: 18,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                                radius: 60,
                                                              ),
                                                            ],
                                                            sectionsSpace: 2,
                                                            centerSpaceRadius:
                                                                40,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 16),
                                                      // Leyenda
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Container(
                                                                width: 16,
                                                                height: 16,
                                                                color:
                                                                    Colors.blue,
                                                              ),
                                                              const SizedBox(
                                                                width: 8,
                                                              ),
                                                              const Text(
                                                                'Asistió',
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                            height: 8,
                                                          ),
                                                          Row(
                                                            children: [
                                                              Container(
                                                                width: 16,
                                                                height: 16,
                                                                color: Colors
                                                                    .redAccent,
                                                              ),
                                                              const SizedBox(
                                                                width: 8,
                                                              ),
                                                              const Text(
                                                                'No asistió',
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        Card(
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: RoleDistributionChart(
                                              data: _roleReport['byRole'] ?? {},
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 3,
                                    child: Card(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: RecentActivityWidget(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
