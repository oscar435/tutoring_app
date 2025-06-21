import 'package:cloud_firestore/cloud_firestore.dart';

enum AuditAction {
  create,
  update,
  delete,
  login,
  logout,
  roleChange,
  permissionChange,
  statusChange,
}

enum AuditResource {
  user,
  role,
  permission,
  system,
}

class AuditLog {
  final String id;
  final String userId;
  final String userEmail;
  final String userName;
  final AuditAction action;
  final AuditResource resource;
  final String resourceId;
  final String resourceName;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final String? description;
  final DateTime timestamp;
  final String? ipAddress;
  final String? userAgent;

  AuditLog({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.action,
    required this.resource,
    required this.resourceId,
    required this.resourceName,
    this.oldValues,
    this.newValues,
    this.description,
    required this.timestamp,
    this.ipAddress,
    this.userAgent,
  });

  factory AuditLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return AuditLog(
      id: doc.id,
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userName: data['userName'] ?? '',
      action: AuditAction.values.firstWhere(
        (e) => e.toString().split('.').last == data['action'],
        orElse: () => AuditAction.update,
      ),
      resource: AuditResource.values.firstWhere(
        (e) => e.toString().split('.').last == data['resource'],
        orElse: () => AuditResource.user,
      ),
      resourceId: data['resourceId'] ?? '',
      resourceName: data['resourceName'] ?? '',
      oldValues: data['oldValues'],
      newValues: data['newValues'],
      description: data['description'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      ipAddress: data['ipAddress'],
      userAgent: data['userAgent'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'action': action.toString().split('.').last,
      'resource': resource.toString().split('.').last,
      'resourceId': resourceId,
      'resourceName': resourceName,
      'oldValues': oldValues,
      'newValues': newValues,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'ipAddress': ipAddress,
      'userAgent': userAgent,
    };
  }

  String get actionDisplayName {
    switch (action) {
      case AuditAction.create:
        return 'Crear';
      case AuditAction.update:
        return 'Actualizar';
      case AuditAction.delete:
        return 'Eliminar';
      case AuditAction.login:
        return 'Iniciar Sesión';
      case AuditAction.logout:
        return 'Cerrar Sesión';
      case AuditAction.roleChange:
        return 'Cambio de Rol';
      case AuditAction.permissionChange:
        return 'Cambio de Permisos';
      case AuditAction.statusChange:
        return 'Cambio de Estado';
    }
  }

  String get resourceDisplayName {
    switch (resource) {
      case AuditResource.user:
        return 'Usuario';
      case AuditResource.role:
        return 'Rol';
      case AuditResource.permission:
        return 'Permiso';
      case AuditResource.system:
        return 'Sistema';
    }
  }

  String get formattedTimestamp {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
} 