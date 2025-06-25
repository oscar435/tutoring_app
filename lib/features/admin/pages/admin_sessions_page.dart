import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminSessionsPage extends StatefulWidget {
  const AdminSessionsPage({super.key});

  @override
  State<AdminSessionsPage> createState() => _AdminSessionsPageState();
}

class _AdminSessionsPageState extends State<AdminSessionsPage> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final firestore = FirebaseFirestore.instance;
      final query = await firestore
          .collection('sesiones_tutoria')
          // .where('estado', isEqualTo: 'aceptada') // Mostrar todas las sesiones
          .get();
      final List<Map<String, dynamic>> sessions = [];
      for (final doc in query.docs) {
        final data = doc.data();
        // Buscar nombre de estudiante
        String estudianteNombre = data['estudianteId'] ?? '-';
        if (data['estudianteId'] != null) {
          final estDoc = await firestore
              .collection('estudiantes')
              .doc(data['estudianteId'])
              .get();
          if (estDoc.exists) {
            final est = estDoc.data();
            estudianteNombre =
                '${est?['nombre'] ?? ''} ${est?['apellidos'] ?? ''}'.trim();
            if (estudianteNombre.isEmpty)
              estudianteNombre = data['estudianteId'];
          }
        }
        // Buscar nombre de tutor
        String tutorNombre = data['tutorId'] ?? '-';
        if (data['tutorId'] != null) {
          final tutDoc = await firestore
              .collection('tutores')
              .doc(data['tutorId'])
              .get();
          if (tutDoc.exists) {
            final tut = tutDoc.data();
            tutorNombre = '${tut?['nombre'] ?? ''} ${tut?['apellidos'] ?? ''}'
                .trim();
            if (tutorNombre.isEmpty) tutorNombre = data['tutorId'];
          }
        }
        sessions.add({
          ...data,
          'estudianteNombre': estudianteNombre,
          'tutorNombre': tutorNombre,
        });
      }
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error al cargar sesiones: $e';
      });
    }
  }

  String _formatFecha(dynamic fecha) {
    if (fecha == null) return '-';
    try {
      if (fecha is Timestamp) {
        final dt = fecha.toDate();
        return DateFormat('dd/MM/yyyy').format(dt);
      } else if (fecha is DateTime) {
        return DateFormat('dd/MM/yyyy').format(fecha);
      } else if (fecha is String) {
        return fecha;
      }
    } catch (_) {}
    return fecha.toString();
  }

  String _formatHora(String? h) {
    if (h == null) return '-';
    // Si ya está en formato AM/PM, devolver tal cual
    if (h.contains('AM') || h.contains('PM')) return h;
    // Si es "09:00" o "9:00", formatear a AM/PM
    try {
      final parts = h.split(":");
      int hour = int.parse(parts[0]);
      int min = int.parse(parts[1].replaceAll(RegExp(r'[^0-9]'), ''));
      final dt = DateTime(2020, 1, 1, hour, min);
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return h;
    }
  }

  Color _estadoColor(String? estado) {
    switch (estado) {
      case 'aceptada':
        return Colors.green[600]!;
      case 'pendiente':
        return Colors.orange[700]!;
      case 'cancelada':
        return Colors.red[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  IconData _estadoIcon(String? estado) {
    switch (estado) {
      case 'aceptada':
        return Icons.check_circle;
      case 'pendiente':
        return Icons.hourglass_top;
      case 'cancelada':
        return Icons.cancel;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sesiones Agendadas (Admin)'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            )
          : _sessions.isEmpty
          ? const Center(child: Text('No hay sesiones registradas.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _sessions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final s = _sessions[index];
                final estado = s['estado'] ?? '-';
                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _estadoIcon(estado),
                              color: _estadoColor(estado),
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              s['curso'] ?? '-',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _estadoColor(
                                  estado,
                                ).withAlpha((0.1 * 255).toInt()),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                estado.toString().toUpperCase(),
                                style: TextStyle(
                                  color: _estadoColor(estado),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.person,
                              size: 18,
                              color: Colors.deepPurple,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Tooltip(
                                message: s['estudianteId'] ?? '-',
                                child: Text(
                                  'Estudiante: ${s['estudianteNombre'] ?? s['estudianteId'] ?? '-'}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Icon(
                              Icons.school,
                              size: 18,
                              color: Colors.teal,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Tooltip(
                                message: s['tutorId'] ?? '-',
                                child: Text(
                                  'Tutor: ${s['tutorNombre'] ?? s['tutorId'] ?? '-'}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: Colors.indigo,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatFecha(s['fechaSesion']),
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 16),
                            const Icon(
                              Icons.access_time,
                              size: 18,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_formatHora(s['horaInicio'])} - ${_formatHora(s['horaFin'])}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 16),
                            const Icon(
                              Icons.today,
                              size: 18,
                              color: Colors.blueGrey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              s['dia'] ?? '-',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        if ((s['mensaje'] ?? '').toString().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.message,
                                size: 18,
                                color: Colors.blueGrey,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  s['mensaje'],
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
