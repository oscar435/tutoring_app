import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  student,
  teacher,
  admin,
  superAdmin;

  String get displayName {
    switch (this) {
      case UserRole.student:
        return 'Estudiante';
      case UserRole.teacher:
        return 'Tutor';
      case UserRole.admin:
        return 'Administrador';
      case UserRole.superAdmin:
        return 'Super Admin';
    }
  }
}

enum Permission {
  viewUsers,
  createUsers,
  editUsers,
  deleteUsers,
  assignRoles,
  viewAuditLogs,
  manageSystem,
}

class AdminUser {
  final String id;
  final String email;
  final String nombre;
  final String apellidos;
  final UserRole role;
  final List<Permission> permissions;
  final DateTime createdAt;
  final bool isActive;
  final String? createdBy;
  final DateTime? lastModified;
  final String? modifiedBy;

  AdminUser({
    required this.id,
    required this.email,
    required this.nombre,
    required this.apellidos,
    required this.role,
    required this.permissions,
    required this.createdAt,
    required this.isActive,
    this.createdBy,
    this.lastModified,
    this.modifiedBy,
  });

  factory AdminUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AdminUser(
      id: doc.id,
      email: data['email'] ?? '',
      nombre: data['nombre'] ?? '',
      apellidos: data['apellidos'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == data['role'],
        orElse: () => UserRole.student,
      ),
      permissions:
          (data['permissions'] as List<dynamic>?)
              ?.map(
                (p) => Permission.values.firstWhere(
                  (e) => e.toString().split('.').last == p,
                  orElse: () => Permission.viewUsers,
                ),
              )
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      createdBy: data['createdBy'],
      lastModified: data['lastModified'] != null
          ? (data['lastModified'] as Timestamp).toDate()
          : null,
      modifiedBy: data['modifiedBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    final data = {
      'email': email,
      'nombre': nombre,
      'apellidos': apellidos,
      'role': role.toString().split('.').last,
      'permissions': permissions
          .map((p) => p.toString().split('.').last)
          .toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'createdBy': createdBy,
    };
    if (lastModified != null) {
      data['lastModified'] = Timestamp.fromDate(lastModified!);
    }
    if (modifiedBy != null) {
      data['modifiedBy'] = modifiedBy;
    }
    return data;
  }

  AdminUser copyWith({
    String? id,
    String? email,
    String? nombre,
    String? apellidos,
    UserRole? role,
    List<Permission>? permissions,
    DateTime? createdAt,
    bool? isActive,
    String? createdBy,
    DateTime? lastModified,
    String? modifiedBy,
  }) {
    return AdminUser(
      id: id ?? this.id,
      email: email ?? this.email,
      nombre: nombre ?? this.nombre,
      apellidos: apellidos ?? this.apellidos,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      lastModified: lastModified ?? this.lastModified,
      modifiedBy: modifiedBy ?? this.modifiedBy,
    );
  }

  bool hasPermission(Permission permission) {
    return permissions.contains(permission);
  }

  String get fullName => '$nombre $apellidos';
  String get roleDisplayName => role.displayName;
}
