import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/admin_user.dart';
import '../models/audit_log.dart';

class UserManagementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obtener todos los usuarios con filtros
  Future<List<AdminUser>> getUsers({
    UserRole? roleFilter,
    bool? isActiveFilter,
    String? searchQuery,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore.collection('users');

      // Aplicar filtros
      if (roleFilter != null) {
        query = query.where('role', isEqualTo: roleFilter.toString().split('.').last);
      }
      
      if (isActiveFilter != null) {
        query = query.where('isActive', isEqualTo: isActiveFilter);
      }

      // Ordenar por fecha de creación descendente
      query = query.orderBy('createdAt', descending: true).limit(limit);

      final querySnapshot = await query.get();
      List<AdminUser> users = [];

      for (var doc in querySnapshot.docs) {
        final user = AdminUser.fromFirestore(doc);
        
        // Aplicar filtro de búsqueda si existe
        if (searchQuery != null && searchQuery.isNotEmpty) {
          final query = searchQuery.toLowerCase();
          if (user.nombre.toLowerCase().contains(query) ||
              user.apellidos.toLowerCase().contains(query)) {
            users.add(user);
          }
        } else {
          users.add(user);
        }
      }

      return users;
    } catch (e) {
      print('Error obteniendo usuarios: $e');
      throw Exception('Error al obtener usuarios: $e');
    }
  }

  // Obtener usuario por ID
  Future<AdminUser?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return AdminUser.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error obteniendo usuario: $e');
      throw Exception('Error al obtener usuario: $e');
    }
  }

  // Crear nuevo usuario
  Future<String> createUser({
    required String email,
    required String password,
    required String nombre,
    required String apellidos,
    required UserRole role,
    required List<Permission> permissions,
    required String createdBy,
    Map<String, dynamic>? specificData,
  }) async {
    try {
      // Validar email único
      final existingUser = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      
      if (existingUser.docs.isNotEmpty) {
        throw Exception('El email ya está registrado');
      }

      // Crear cuenta de autenticación
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final String userId = userCredential.user!.uid;
      final WriteBatch batch = _firestore.batch();

      // Crear documento de usuario en 'users'
      final userDocRef = _firestore.collection('users').doc(userId);
      final user = AdminUser(
        id: userId,
        email: email,
        nombre: nombre,
        apellidos: apellidos,
        role: role,
        permissions: permissions,
        createdAt: DateTime.now(),
        isActive: true,
        createdBy: createdBy,
      );
      batch.set(userDocRef, user.toFirestore());

      // Crear documento en colección específica ('estudiantes' o 'tutores')
      final String? collectionName = _getCollectionForRole(role);
      if (collectionName != null && specificData != null) {
        final specificDocRef = _firestore.collection(collectionName).doc(userId);
        // Añadir campos por defecto que estaban en la UI
        specificData['createdAt'] = FieldValue.serverTimestamp();
        specificData['updatedAt'] = FieldValue.serverTimestamp();
        specificData['emailVerified'] = true;
        specificData['photoUrl'] = '';
        batch.set(specificDocRef, specificData);
      }
      
      await batch.commit();

      // Registrar en auditoría
      await _logAuditAction(
        userId: createdBy,
        action: AuditAction.create,
        resource: AuditResource.user,
        resourceId: userId,
        resourceName: user.fullName,
        description: 'Usuario creado: ${user.fullName} con rol ${user.roleDisplayName}',
      );

      return userId;
    } catch (e) {
      print('Error creando usuario: $e');
      throw Exception('Error al crear usuario: $e');
    }
  }

  // Actualizar usuario
  Future<void> updateUser({
    required String userId,
    String? nombre,
    String? apellidos,
    UserRole? role,
    List<Permission>? permissions,
    bool? isActive,
    required String modifiedBy,
    Map<String, dynamic>? specificData,
  }) async {
    try {
      final WriteBatch batch = _firestore.batch();
      final userDocRef = _firestore.collection('users').doc(userId);
      
      final userDoc = await userDocRef.get();
      if (!userDoc.exists) {
        throw Exception('Usuario no encontrado');
      }

      final oldUser = AdminUser.fromFirestore(userDoc);
      final Map<String, dynamic> updates = {};

      if (nombre != null) updates['nombre'] = nombre;
      if (apellidos != null) updates['apellidos'] = apellidos;
      if (role != null) updates['role'] = role.toString().split('.').last;
      if (permissions != null) {
        updates['permissions'] = permissions.map((p) => p.toString().split('.').last).toList();
      }
      if (isActive != null) updates['isActive'] = isActive;
      
      updates['lastModified'] = Timestamp.fromDate(DateTime.now());
      updates['modifiedBy'] = modifiedBy;

      // --- Inicio de Lógica de Auditoría Y MIGRACIÓN de Cambio de Rol ---
      if (role != null && role != oldUser.role) {
        await _logAuditAction(
          userId: modifiedBy,
          action: AuditAction.roleChange,
          resource: AuditResource.user,
          resourceId: userId,
          resourceName: oldUser.fullName,
          oldValues: {'role': oldUser.role.toString().split('.').last},
          newValues: {'role': role.toString().split('.').last},
          description: 'Rol de ${oldUser.fullName} cambiado de ${oldUser.roleDisplayName} a ${role.displayName}',
        );

        // 1. Borrar de la colección antigua
        final oldCollectionName = _getCollectionForRole(oldUser.role);
        if (oldCollectionName != null) {
          final oldSpecificDocRef = _firestore.collection(oldCollectionName).doc(userId);
          batch.delete(oldSpecificDocRef);
        }

        // 2. Crear en la nueva colección
        final newCollectionName = _getCollectionForRole(role);
        if (newCollectionName != null && specificData != null) {
          final newSpecificDocRef = _firestore.collection(newCollectionName).doc(userId);
          
          specificData['updatedAt'] = FieldValue.serverTimestamp();
          specificData['createdAt'] = oldUser.createdAt; 
          specificData['photoUrl'] = userDoc.data()!.containsKey('photoUrl') ? userDoc.get('photoUrl') : '';
          
          batch.set(newSpecificDocRef, specificData);
        }
      } else {
        // Si no hay cambio de rol, actualizar los datos específicos en la colección actual
        final currentRole = role ?? oldUser.role;
        final collectionName = _getCollectionForRole(currentRole);
        if (collectionName != null && specificData != null) {
          final specificDocRef = _firestore.collection(collectionName).doc(userId);
          
          // Añadir campos de auditoría
          specificData['updatedAt'] = FieldValue.serverTimestamp();
          
          // Actualizar el documento específico
          batch.update(specificDocRef, specificData);
        }
      }
      // --- Fin de Lógica de Auditoría y Migración ---

      if (updates.isNotEmpty) {
        batch.update(userDocRef, updates);
      }

      await batch.commit();

      // Log de actualización general
      await _logAuditAction(
        userId: modifiedBy,
        action: AuditAction.update,
        resource: AuditResource.user,
        resourceId: userId,
        resourceName: oldUser.fullName,
        oldValues: {
          'nombre': oldUser.nombre,
          'apellidos': oldUser.apellidos,
          'role': oldUser.role.toString().split('.').last,
        },
        newValues: {
          'nombre': nombre ?? oldUser.nombre,
          'apellidos': apellidos ?? oldUser.apellidos,
          'role': (role ?? oldUser.role).toString().split('.').last,
        },
        description: 'Usuario actualizado: ${oldUser.fullName}',
      );
    } catch (e) {
      print('Error actualizando usuario: $e');
      throw Exception('Error al actualizar usuario: $e');
    }
  }

  // Eliminar usuario (desactivar)
  Future<void> deleteUser({
    required String userId,
    required String deletedBy,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('Usuario no encontrado');
      }

      final user = AdminUser.fromFirestore(userDoc);

      // 1. Desactivar usuario en Firestore
      await _firestore.collection('users').doc(userId).update({
        'isActive': false,
        'lastModified': Timestamp.fromDate(DateTime.now()),
        'modifiedBy': deletedBy,
      });

      // 2. Agregar marca de desactivación en la colección específica
      try {
        final role = user.role;
        if (role == UserRole.student || role == UserRole.teacher) {
          final collectionName = role == UserRole.student ? 'estudiantes' : 'tutores';
          await _firestore.collection(collectionName).doc(userId).update({
            'isActive': false,
            'deactivatedAt': Timestamp.fromDate(DateTime.now()),
            'deactivatedBy': deletedBy,
          });
        }
      } catch (e) {
        print('Error actualizando colección específica: $e');
        // Continuar aunque falle, lo importante es la colección users
      }

      // Registrar en auditoría
      await _logAuditAction(
        userId: deletedBy,
        action: AuditAction.delete,
        resource: AuditResource.user,
        resourceId: userId,
        resourceName: user.fullName,
        description: 'Usuario desactivado: ${user.fullName}',
      );
    } catch (e) {
      print('Error eliminando usuario: $e');
      throw Exception('Error al eliminar usuario: $e');
    }
  }

  // Obtener estadísticas de usuarios
  Future<Map<String, int>> getUserStatistics() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      
      Map<String, int> stats = {
        'total': 0,
        'students': 0,
        'teachers': 0,
        'admins': 0,
        'active': 0,
        'inactive': 0,
      };

      for (var doc in usersSnapshot.docs) {
        final user = AdminUser.fromFirestore(doc);
        stats['total'] = (stats['total'] ?? 0) + 1;
        
        if (user.isActive) {
          stats['active'] = (stats['active'] ?? 0) + 1;
        } else {
          stats['inactive'] = (stats['inactive'] ?? 0) + 1;
        }

        switch (user.role) {
          case UserRole.student:
            stats['students'] = (stats['students'] ?? 0) + 1;
            break;
          case UserRole.teacher:
            stats['teachers'] = (stats['teachers'] ?? 0) + 1;
            break;
          case UserRole.admin:
          case UserRole.superAdmin:
            stats['admins'] = (stats['admins'] ?? 0) + 1;
            break;
        }
      }

      return stats;
    } catch (e) {
      print('Error obteniendo estadísticas: $e');
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  // Registrar acción de auditoría
  Future<void> _logAuditAction({
    required String userId,
    required AuditAction action,
    required AuditResource resource,
    required String resourceId,
    required String resourceName,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
    String? description,
  }) async {
    try {
      final currentUser = await getUserById(userId);
      
      final auditLog = AuditLog(
        id: '',
        userId: userId,
        userEmail: currentUser?.email ?? '',
        userName: currentUser?.fullName ?? '',
        action: action,
        resource: resource,
        resourceId: resourceId,
        resourceName: resourceName,
        oldValues: oldValues,
        newValues: newValues,
        description: description,
        timestamp: DateTime.now(),
      );

      await _firestore.collection('audit_logs').add(auditLog.toFirestore());
    } catch (e) {
      print('Error registrando auditoría: $e');
      // No lanzar excepción para no interrumpir la operación principal
      // TEMPORAL: Lanzamos el error para depurarlo en la UI
      throw Exception('Error al registrar en auditoría: $e');
    }
  }

  // Validar permisos de usuario
  bool validateUserPermissions(AdminUser user, List<Permission> requiredPermissions) {
    return requiredPermissions.every((permission) => user.hasPermission(permission));
  }

  // Verificar si el email ya existe
  Future<bool> isEmailExists(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error verificando email: $e');
      return false;
    }
  }

  String? _getCollectionForRole(UserRole role) {
    switch (role) {
      case UserRole.student:
        return 'estudiantes';
      case UserRole.teacher:
        return 'tutores';
      default:
        return null;
    }
  }

  // Reactivar usuario
  Future<void> reactivateUser({
    required String userId,
    required String reactivatedBy,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('Usuario no encontrado');
      }

      final user = AdminUser.fromFirestore(userDoc);

      // 1. Reactivar usuario en Firestore
      await _firestore.collection('users').doc(userId).update({
        'isActive': true,
        'lastModified': Timestamp.fromDate(DateTime.now()),
        'modifiedBy': reactivatedBy,
      });

      // 2. Remover marca de desactivación en la colección específica
      try {
        final role = user.role;
        if (role == UserRole.student || role == UserRole.teacher) {
          final collectionName = role == UserRole.student ? 'estudiantes' : 'tutores';
          await _firestore.collection(collectionName).doc(userId).update({
            'isActive': true,
            'reactivatedAt': Timestamp.fromDate(DateTime.now()),
            'reactivatedBy': reactivatedBy,
          });
        }
      } catch (e) {
        print('Error actualizando colección específica: $e');
        // Continuar aunque falle, lo importante es la colección users
      }

      // Registrar en auditoría
      await _logAuditAction(
        userId: reactivatedBy,
        action: AuditAction.update,
        resource: AuditResource.user,
        resourceId: userId,
        resourceName: user.fullName,
        description: 'Usuario reactivado: ${user.fullName}',
      );
    } catch (e) {
      print('Error reactivando usuario: $e');
      throw Exception('Error al reactivar usuario: $e');
    }
  }
} 