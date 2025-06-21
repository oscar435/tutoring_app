import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/audit_log.dart';

class AuditLogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<AuditLog>> getAuditLogs({int limit = 100}) async {
    try {
      final querySnapshot = await _firestore
          .collection('audit_logs')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => AuditLog.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error obteniendo logs de auditoría: $e');
      throw Exception('Error al obtener logs de auditoría: $e');
    }
  }
} 