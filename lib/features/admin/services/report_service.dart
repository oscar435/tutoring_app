import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:convert';
import '../../../core/models/admin_user.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generar reporte detallado de usuarios por rol
  Future<Map<String, dynamic>> generateUserReport() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      
      // Estadísticas por rol
      final Map<String, int> roleCount = {
        'student': 0,
        'teacher': 0,
        'admin': 0,
        'superAdmin': 0,
      };

      // Usuarios activos vs inactivos
      int activeUsers = 0;
      int inactiveUsers = 0;

      // Lista detallada de usuarios
      final List<Map<String, dynamic>> userDetails = [];

      for (var doc in usersSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final role = data['role'] as String? ?? 'student';
        final isActive = data['isActive'] as bool? ?? true;
        final createdAt = data['createdAt'] as Timestamp?;
        final lastLogin = data['lastLogin'] as Timestamp?;

        // Contar por rol
        roleCount[role] = (roleCount[role] ?? 0) + 1;

        // Contar activos/inactivos
        if (isActive) {
          activeUsers++;
        } else {
          inactiveUsers++;
        }

        // Agregar detalles del usuario
        userDetails.add({
          'id': doc.id,
          'nombre': data['nombre'] ?? '',
          'apellidos': data['apellidos'] ?? '',
          'email': data['email'] ?? '',
          'rol': _getRoleDisplayName(role),
          'estado': isActive ? 'Activo' : 'Inactivo',
          'fecha_creacion': createdAt != null 
              ? DateFormat('dd/MM/yyyy HH:mm').format(createdAt.toDate())
              : 'N/A',
          'ultimo_login': lastLogin != null 
              ? DateFormat('dd/MM/yyyy HH:mm').format(lastLogin.toDate())
              : 'Nunca',
          'creado_por': data['createdBy'] ?? 'Sistema',
        });
      }

      return {
        'summary': {
          'total_usuarios': usersSnapshot.docs.length,
          'usuarios_activos': activeUsers,
          'usuarios_inactivos': inactiveUsers,
          'por_rol': roleCount,
        },
        'user_details': userDetails,
        'generated_at': DateTime.now(),
      };
    } catch (e) {
      throw Exception('Error generando reporte: $e');
    }
  }

  // Exportar reporte a CSV
  Future<String?> exportToCSV() async {
    try {
      final report = await generateUserReport();
      final summary = report['summary'] as Map<String, dynamic>;
      final userDetails = report['user_details'] as List<Map<String, dynamic>>;
      final generatedAt = report['generated_at'] as DateTime;

      // Crear contenido CSV
      final StringBuffer csvContent = StringBuffer();

      // Encabezado del reporte
      csvContent.writeln('REPORTE DE USUARIOS - SISTEMA DE TUTORÍAS UNFV');
      csvContent.writeln('Generado el: ${DateFormat('dd/MM/yyyy HH:mm').format(generatedAt)}');
      csvContent.writeln('');

      // Resumen estadístico
      csvContent.writeln('RESUMEN ESTADÍSTICO');
      csvContent.writeln('Total de Usuarios,${summary['total_usuarios']}');
      csvContent.writeln('Usuarios Activos,${summary['usuarios_activos']}');
      csvContent.writeln('Usuarios Inactivos,${summary['usuarios_inactivos']}');
      csvContent.writeln('');

      // Distribución por rol
      csvContent.writeln('DISTRIBUCIÓN POR ROL');
      final roleCount = summary['por_rol'] as Map<String, dynamic>;
      roleCount.forEach((role, count) {
        csvContent.writeln('${_getRoleDisplayName(role)},$count');
      });
      csvContent.writeln('');

      // Detalles de usuarios
      csvContent.writeln('DETALLES DE USUARIOS');
      csvContent.writeln('ID,Nombre,Apellidos,Email,Rol,Estado,Fecha Creación,Último Login,Creado Por');
      
      for (final user in userDetails) {
        csvContent.writeln([
          user['id'],
          user['nombre'],
          user['apellidos'],
          user['email'],
          user['rol'],
          user['estado'],
          user['fecha_creacion'],
          user['ultimo_login'],
          user['creado_por'],
        ].map((field) => '"${field.toString().replaceAll('"', '""')}"').join(','));
      }

      final fileName = 'reporte_usuarios_${DateFormat('yyyyMMdd_HHmmss').format(generatedAt)}.csv';

      if (kIsWeb) {
        // Implementación para Web
        final bytes = utf8.encode(csvContent.toString());
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.document.createElement('a') as html.AnchorElement
          ..href = url
          ..style.display = 'none'
          ..download = fileName;
        
        html.document.body!.children.add(anchor);
        anchor.click();
        html.document.body!.children.remove(anchor);
        html.Url.revokeObjectUrl(url);

        return null; // En web, no retornamos una ruta, solo disparamos la descarga.
      } else {
        // Implementación para Mobile/Desktop
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsString(csvContent.toString());
        return file.path;
      }
    } catch (e) {
      throw Exception('Error exportando reporte: $e');
    }
  }

  // Generar reporte de auditoría
  Future<Map<String, dynamic>> generateAuditReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection('audit_logs')
          .orderBy('timestamp', descending: true);

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final logsSnapshot = await query.get();

      // Estadísticas por acción
      final Map<String, int> actionCount = {};
      final List<Map<String, dynamic>> logDetails = [];

      for (var doc in logsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final action = data['action'] as String? ?? 'unknown';
        final timestamp = data['timestamp'] as Timestamp?;

        // Contar acciones
        actionCount[action] = (actionCount[action] ?? 0) + 1;

        // Agregar detalles del log
        logDetails.add({
          'id': doc.id,
          'usuario': data['userName'] ?? '',
          'email': data['userEmail'] ?? '',
          'accion': _getActionDisplayName(action),
          'recurso': data['resourceName'] ?? '',
          'descripcion': data['description'] ?? '',
          'fecha': timestamp != null 
              ? DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate())
              : 'N/A',
        });
      }

      return {
        'summary': {
          'total_logs': logsSnapshot.docs.length,
          'por_accion': actionCount,
          'periodo': {
            'inicio': startDate?.toIso8601String(),
            'fin': endDate?.toIso8601String(),
          },
        },
        'log_details': logDetails,
        'generated_at': DateTime.now(),
      };
    } catch (e) {
      throw Exception('Error generando reporte de auditoría: $e');
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'student':
        return 'Estudiante';
      case 'teacher':
        return 'Tutor';
      case 'admin':
        return 'Administrador';
      case 'superAdmin':
        return 'Super Admin';
      default:
        return role;
    }
  }

  String _getActionDisplayName(String action) {
    switch (action) {
      case 'create':
        return 'Crear';
      case 'update':
        return 'Actualizar';
      case 'delete':
        return 'Eliminar';
      case 'login':
        return 'Iniciar Sesión';
      case 'logout':
        return 'Cerrar Sesión';
      case 'roleChange':
        return 'Cambio de Rol';
      case 'permissionChange':
        return 'Cambio de Permisos';
      case 'statusChange':
        return 'Cambio de Estado';
      default:
        return action;
    }
  }
} 