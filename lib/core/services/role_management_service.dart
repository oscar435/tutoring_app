import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin_user.dart';
import '../models/audit_log.dart';

class RoleManagementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Definir estructura jerárquica de roles y permisos
  static const Map<UserRole, List<Permission>> rolePermissions = {
    UserRole.student: [
      Permission.viewUsers, // Solo puede ver otros estudiantes
    ],
    UserRole.teacher: [
      Permission.viewUsers,
      Permission.editUsers, // Puede editar información de estudiantes
    ],
    UserRole.admin: [
      Permission.viewUsers,
      Permission.createUsers,
      Permission.editUsers,
      Permission.assignRoles,
      Permission.viewAuditLogs,
    ],
    UserRole.superAdmin: [
      Permission.viewUsers,
      Permission.createUsers,
      Permission.editUsers,
      Permission.deleteUsers,
      Permission.assignRoles,
      Permission.viewAuditLogs,
      Permission.manageSystem,
    ],
  };

  // Obtener permisos por rol
  List<Permission> getPermissionsForRole(UserRole role) {
    return rolePermissions[role] ?? [];
  }

  // Verificar si un rol puede asignar otro rol
  bool canAssignRole(UserRole assignerRole, UserRole targetRole) {
    switch (assignerRole) {
      case UserRole.superAdmin:
        return true; // Puede asignar cualquier rol
      case UserRole.admin:
        return targetRole == UserRole.student || targetRole == UserRole.teacher;
      case UserRole.teacher:
      case UserRole.student:
        return false; // No pueden asignar roles
    }
  }

  // Asignar rol a usuario
  Future<void> assignRoleToUser({
    required String userId,
    required UserRole newRole,
    required String assignedBy,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('Usuario no encontrado');
      }

      final oldUser = AdminUser.fromFirestore(userDoc);

      // Verificar permisos del asignador
      final assignerDoc = await _firestore
          .collection('users')
          .doc(assignedBy)
          .get();
      if (!assignerDoc.exists) {
        throw Exception('Usuario asignador no encontrado');
      }

      final assigner = AdminUser.fromFirestore(assignerDoc);
      if (!canAssignRole(assigner.role, newRole)) {
        throw Exception('No tienes permisos para asignar este rol');
      }

      // Obtener permisos del nuevo rol
      final newPermissions = getPermissionsForRole(newRole);

      // Actualizar usuario
      await _firestore.collection('users').doc(userId).update({
        'role': newRole.toString().split('.').last,
        'permissions': newPermissions
            .map((p) => p.toString().split('.').last)
            .toList(),
        'lastModified': Timestamp.fromDate(DateTime.now()),
        'modifiedBy': assignedBy,
      });

      // Registrar en auditoría
      await _logRoleChange(
        userId: assignedBy,
        targetUserId: userId,
        oldRole: oldUser.role,
        newRole: newRole,
        targetUserName: oldUser.fullName,
      );
    } catch (e) {
      throw Exception('Error al asignar rol: $e');
    }
  }

  // Obtener usuarios por rol
  Future<List<AdminUser>> getUsersByRole(UserRole role) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: role.toString().split('.').last)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => AdminUser.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener usuarios por rol: $e');
    }
  }

  // Obtener reporte de usuarios por rol
  Future<Map<String, dynamic>> getUsersByRoleReport() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();

      Map<String, dynamic> report = {
        'total': 0,
        'byRole': {},
        'byStatus': {'active': 0, 'inactive': 0},
        'recentActivity': [],
      };

      for (var doc in usersSnapshot.docs) {
        final user = AdminUser.fromFirestore(doc);
        report['total'] = (report['total'] as int) + 1;

        // Contar por rol
        final roleName = user.roleDisplayName;
        if (report['byRole'][roleName] == null) {
          report['byRole'][roleName] = {
            'count': 0,
            'active': 0,
            'inactive': 0,
            'users': [],
          };
        }

        report['byRole'][roleName]['count'] =
            (report['byRole'][roleName]['count'] as int) + 1;
        report['byRole'][roleName]['users'].add({
          'id': user.id,
          'name': user.fullName,
          'email': user.email,
          'isActive': user.isActive,
          'createdAt': user.createdAt.toIso8601String(),
        });

        if (user.isActive) {
          report['byStatus']['active'] =
              (report['byStatus']['active'] as int) + 1;
          report['byRole'][roleName]['active'] =
              (report['byRole'][roleName]['active'] as int) + 1;
        } else {
          report['byStatus']['inactive'] =
              (report['byStatus']['inactive'] as int) + 1;
          report['byRole'][roleName]['inactive'] =
              (report['byRole'][roleName]['inactive'] as int) + 1;
        }

        // Agregar a actividad reciente (últimos 30 días)
        final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
        if (user.createdAt.isAfter(thirtyDaysAgo)) {
          report['recentActivity'].add({
            'user': user.fullName,
            'role': user.roleDisplayName,
            'action': 'Registro',
            'date': user.createdAt.toIso8601String(),
          });
        }
      }

      // Ordenar actividad reciente por fecha
      report['recentActivity'].sort(
        (a, b) =>
            DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])),
      );

      return report;
    } catch (e) {
      throw Exception('Error al generar reporte: $e');
    }
  }

  // Obtener auditoría de cambios de roles
  Future<List<AuditLog>> getRoleChangeAudit({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection('audit_logs')
          .where(
            'action',
            isEqualTo: AuditAction.roleChange.toString().split('.').last,
          )
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      if (startDate != null) {
        query = query.where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }

      if (endDate != null) {
        query = query.where(
          'timestamp',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        );
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => AuditLog.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener auditoría de roles: $e');
    }
  }

  // Validar jerarquía de roles
  bool validateRoleHierarchy(UserRole currentRole, UserRole newRole) {
    // Un usuario no puede asignarse un rol superior al suyo
    final roleHierarchy = {
      UserRole.student: 1,
      UserRole.teacher: 2,
      UserRole.admin: 3,
      UserRole.superAdmin: 4,
    };

    return roleHierarchy[currentRole]! >= roleHierarchy[newRole]!;
  }

  // Obtener roles disponibles para asignar
  List<UserRole> getAvailableRolesForAssignment(UserRole assignerRole) {
    switch (assignerRole) {
      case UserRole.superAdmin:
        return UserRole.values;
      case UserRole.admin:
        return [UserRole.student, UserRole.teacher];
      case UserRole.teacher:
      case UserRole.student:
        return [];
    }
  }

  // Registrar cambio de rol en auditoría
  Future<void> _logRoleChange({
    required String userId,
    required String targetUserId,
    required UserRole oldRole,
    required UserRole newRole,
    required String targetUserName,
  }) async {
    try {
      final currentUser = await _getUserById(userId);

      final auditLog = AuditLog(
        id: '',
        userId: userId,
        userEmail: currentUser?.email ?? '',
        userName: currentUser?.fullName ?? '',
        action: AuditAction.roleChange,
        resource: AuditResource.user,
        resourceId: targetUserId,
        resourceName: targetUserName,
        oldValues: {'role': oldRole.toString().split('.').last},
        newValues: {'role': newRole.toString().split('.').last},
        description:
            'Rol cambiado de ${_getRoleDisplayName(oldRole)} a ${_getRoleDisplayName(newRole)} para $targetUserName',
        timestamp: DateTime.now(),
      );

      await _firestore.collection('audit_logs').add(auditLog.toFirestore());
    } catch (e) {
      throw Exception('Error registrando cambio de rol: $e');
    }
  }

  // Helper para obtener usuario por ID
  Future<AdminUser?> _getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return AdminUser.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Helper para obtener nombre de rol
  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.student:
        return 'Estudiante';
      case UserRole.teacher:
        return 'Tutor';
      case UserRole.admin:
        return 'Administrador';
      case UserRole.superAdmin:
        return 'Super Administrador';
    }
  }
}
