import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/audit_log.dart';

class RecentActivityWidget extends StatelessWidget {
  const RecentActivityWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actividad Reciente',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('audit_logs')
                  .orderBy('timestamp', descending: true)
                  .limit(10)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No hay actividad reciente'),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final log = AuditLog.fromFirestore(snapshot.data!.docs[index]);
                    return ListTile(
                      leading: _getActionIcon(log.action),
                      title: Text(log.userName),
                      subtitle: Text(log.description ?? ''),
                      trailing: Text(
                        _formatTimestamp(log.timestamp),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Icon _getActionIcon(AuditAction action) {
    switch (action) {
      case AuditAction.create:
        return const Icon(Icons.add_circle, color: Colors.green);
      case AuditAction.update:
        return const Icon(Icons.edit, color: Colors.blue);
      case AuditAction.delete:
        return const Icon(Icons.delete, color: Colors.red);
      case AuditAction.login:
        return const Icon(Icons.login, color: Colors.purple);
      case AuditAction.logout:
        return const Icon(Icons.logout, color: Colors.orange);
      case AuditAction.roleChange:
        return const Icon(Icons.security, color: Colors.indigo);
      case AuditAction.permissionChange:
        return const Icon(Icons.admin_panel_settings, color: Colors.teal);
      case AuditAction.statusChange:
        return const Icon(Icons.toggle_on, color: Colors.amber);
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inHours < 1) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Hace ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} d';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
} 