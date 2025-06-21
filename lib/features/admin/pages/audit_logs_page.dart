import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/audit_log.dart';

class AuditLogsPage extends StatefulWidget {
  const AuditLogsPage({super.key});

  @override
  State<AuditLogsPage> createState() => _AuditLogsPageState();
}

class _AuditLogsPageState extends State<AuditLogsPage> {
  final Stream<QuerySnapshot> _logsStream = FirebaseFirestore.instance
      .collection('audit_logs')
      .orderBy('timestamp', descending: true)
      .limit(200)
      .snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registros de Auditoría'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _logsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SelectableText('Error al cargar los registros: ${snapshot.error}'),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No se encontraron registros de auditoría.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final logs = snapshot.data!.docs
              .map((doc) => AuditLog.fromFirestore(doc))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return Card(
                elevation: 2.0,
                margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: ListTile(
                  leading: _getActionIcon(log.action),
                  title: Text(
                    log.description ?? 'Acción sin descripción.',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                      'Por: ${log.userName.isNotEmpty ? log.userName : 'Sistema'}'),
                  trailing: Text(
                    _formatTimestamp(log.timestamp),
                    style: const TextStyle(color: Colors.grey, fontSize: 12.0),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Icon _getActionIcon(AuditAction action) {
    Color color;
    IconData icon;

    switch (action) {
      case AuditAction.create:
        icon = Icons.add_circle;
        color = Colors.green;
        break;
      case AuditAction.update:
        icon = Icons.edit;
        color = Colors.blue;
        break;
      case AuditAction.delete:
        icon = Icons.delete;
        color = Colors.red;
        break;
      case AuditAction.login:
        icon = Icons.login;
        color = Colors.purple;
        break;
      case AuditAction.logout:
        icon = Icons.logout;
        color = Colors.orange;
        break;
      case AuditAction.roleChange:
        icon = Icons.security;
        color = Colors.indigo;
        break;
      case AuditAction.permissionChange:
        icon = Icons.admin_panel_settings;
        color = Colors.teal;
        break;
      case AuditAction.statusChange:
        icon = Icons.toggle_on;
        color = Colors.amber;
        break;
    }
    return Icon(icon, color: color);
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('dd/MM/yyyy').format(timestamp);
    }
  }
} 