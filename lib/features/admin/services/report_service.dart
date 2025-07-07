import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:convert';

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
        final data = doc.data();
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

        // Obtener datos específicos según el rol
        Map<String, dynamic> roleSpecificData = {};

        if (role == 'student') {
          // Buscar en la colección de estudiantes
          try {
            final studentDoc = await _firestore
                .collection('students')
                .doc(doc.id)
                .get();
            if (studentDoc.exists) {
              final studentData = studentDoc.data() as Map<String, dynamic>;
              roleSpecificData = {
                'codigo_estudiante': studentData['codigo_estudiante'] ?? '',
                'ciclo': studentData['ciclo'] ?? '',
                'edad': studentData['edad']?.toString() ?? '',
                'especialidad': studentData['especialidad'] ?? '',
                'universidad': studentData['universidad'] ?? '',
              };
            }
          } catch (e) {
            // Si no existe el documento, continuar
          }
        } else if (role == 'teacher') {
          // Buscar en la colección de tutores
          try {
            final teacherDoc = await _firestore
                .collection('tutors')
                .doc(doc.id)
                .get();
            if (teacherDoc.exists) {
              final teacherData = teacherDoc.data() as Map<String, dynamic>;
              roleSpecificData = {
                'escuela': teacherData['escuela'] ?? '',
                'especialidad': teacherData['especialidad'] ?? '',
                'cursos':
                    (teacherData['cursos'] as List<dynamic>?)?.join(', ') ?? '',
                'universidad': teacherData['universidad'] ?? '',
                'facultad': teacherData['facultad'] ?? '',
              };
            }
          } catch (e) {
            // Si no existe el documento, continuar
          }
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
          // Datos específicos del rol
          ...roleSpecificData,
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
      csvContent.writeln(
        'Generado el: ${DateFormat('dd/MM/yyyy HH:mm').format(generatedAt)}',
      );
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

      // Estadísticas específicas por carrera (estudiantes)
      csvContent.writeln('ESTADÍSTICAS POR CARRERA (ESTUDIANTES)');
      final Map<String, int> carreraCount = {};
      for (final user in userDetails) {
        if (user['rol'] == 'Estudiante' &&
            user['especialidad']?.isNotEmpty == true) {
          final carrera = user['especialidad'] as String;
          carreraCount[carrera] = (carreraCount[carrera] ?? 0) + 1;
        }
      }
      if (carreraCount.isNotEmpty) {
        carreraCount.forEach((carrera, count) {
          csvContent.writeln('$carrera,$count');
        });
      } else {
        csvContent.writeln('No hay datos de carreras disponibles');
      }
      csvContent.writeln('');

      // Estadísticas específicas por escuela (tutores)
      csvContent.writeln('ESTADÍSTICAS POR ESCUELA (TUTORES)');
      final Map<String, int> escuelaCount = {};
      for (final user in userDetails) {
        if (user['rol'] == 'Tutor' && user['escuela']?.isNotEmpty == true) {
          final escuela = user['escuela'] as String;
          escuelaCount[escuela] = (escuelaCount[escuela] ?? 0) + 1;
        }
      }
      if (escuelaCount.isNotEmpty) {
        escuelaCount.forEach((escuela, count) {
          csvContent.writeln('$escuela,$count');
        });
      } else {
        csvContent.writeln('No hay datos de escuelas disponibles');
      }
      csvContent.writeln('');

      // Detalles de usuarios
      csvContent.writeln('DETALLES DE USUARIOS');
      csvContent.writeln(
        'ID,Nombre,Apellidos,Email,Rol,Estado,Fecha Creación,Último Login,Creado Por,Código Estudiante,Ciclo,Edad,Especialidad Estudiante,Universidad Estudiante,Escuela Tutor,Especialidad Tutor,Cursos Tutor,Universidad Tutor,Facultad Tutor',
      );

      for (final user in userDetails) {
        csvContent.writeln(
          [
                user['id'],
                user['nombre'],
                user['apellidos'],
                user['email'],
                user['rol'],
                user['estado'],
                user['fecha_creacion'],
                user['ultimo_login'],
                user['creado_por'],
                user['codigo_estudiante'] ?? '',
                user['ciclo'] ?? '',
                user['edad'] ?? '',
                user['especialidad'] ?? '',
                user['universidad'] ?? '',
                user['escuela'] ?? '',
                user['especialidad_tutor'] ?? '',
                user['cursos'] ?? '',
                user['universidad_tutor'] ?? '',
                user['facultad'] ?? '',
              ]
              .map((field) => '"${field.toString().replaceAll('"', '""')}"')
              .join(','),
        );
      }

      final fileName =
          'reporte_usuarios_${DateFormat('yyyyMMdd_HHmmss').format(generatedAt)}.csv';

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

  // Generar reporte de tutorías y sesiones
  Future<Map<String, dynamic>> generateTutoringReport() async {
    try {
      // Obtener solicitudes de tutoría
      final solicitudesSnapshot = await _firestore
          .collection('solicitudes_tutoria')
          .get();

      // Obtener sesiones de tutoría
      final sesionesSnapshot = await _firestore
          .collection('sesiones_tutoria')
          .get();

      // Estadísticas de solicitudes
      final Map<String, int> solicitudStatus = {
        'pendiente': 0,
        'aceptada': 0,
        'rechazada': 0,
        'completada': 0,
      };

      // Estadísticas de sesiones
      final Map<String, int> sesionStatus = {
        'programada': 0,
        'en_curso': 0,
        'completada': 0,
        'cancelada': 0,
      };

      // Lista detallada de solicitudes
      final List<Map<String, dynamic>> solicitudDetails = [];
      for (var doc in solicitudesSnapshot.docs) {
        final data = doc.data();
        final status = data['estado'] as String? ?? 'pendiente';
        final createdAt = data['createdAt'] as Timestamp?;
        final fechaSolicitada = data['fecha_solicitada'] as Timestamp?;

        solicitudStatus[status] = (solicitudStatus[status] ?? 0) + 1;

        solicitudDetails.add({
          'id': doc.id,
          'estudiante_id': data['estudiante_id'] ?? '',
          'tutor_id': data['tutor_id'] ?? '',
          'materia': data['materia'] ?? '',
          'tema': data['tema'] ?? '',
          'estado': _getSolicitudStatusDisplayName(status),
          'fecha_solicitud': createdAt != null
              ? DateFormat('dd/MM/yyyy HH:mm').format(createdAt.toDate())
              : 'N/A',
          'fecha_solicitada': fechaSolicitada != null
              ? DateFormat('dd/MM/yyyy HH:mm').format(fechaSolicitada.toDate())
              : 'N/A',
          'duracion': data['duracion']?.toString() ?? '',
          'modalidad': data['modalidad'] ?? '',
        });
      }

      // Lista detallada de sesiones
      final List<Map<String, dynamic>> sesionDetails = [];
      for (var doc in sesionesSnapshot.docs) {
        final data = doc.data();
        final status = data['estado'] as String? ?? 'programada';
        final fechaInicio = data['fecha_inicio'] as Timestamp?;
        final fechaFin = data['fecha_fin'] as Timestamp?;

        sesionStatus[status] = (sesionStatus[status] ?? 0) + 1;

        sesionDetails.add({
          'id': doc.id,
          'solicitud_id': data['solicitud_id'] ?? '',
          'estudiante_id': data['estudiante_id'] ?? '',
          'tutor_id': data['tutor_id'] ?? '',
          'materia': data['materia'] ?? '',
          'tema': data['tema'] ?? '',
          'estado': _getSesionStatusDisplayName(status),
          'fecha_inicio': fechaInicio != null
              ? DateFormat('dd/MM/yyyy HH:mm').format(fechaInicio.toDate())
              : 'N/A',
          'fecha_fin': fechaFin != null
              ? DateFormat('dd/MM/yyyy HH:mm').format(fechaFin.toDate())
              : 'N/A',
          'duracion_real': data['duracion_real']?.toString() ?? '',
          'modalidad': data['modalidad'] ?? '',
          'notas': data['notas'] ?? '',
        });
      }

      return {
        'summary': {
          'total_solicitudes': solicitudesSnapshot.docs.length,
          'total_sesiones': sesionesSnapshot.docs.length,
          'solicitudes_por_estado': solicitudStatus,
          'sesiones_por_estado': sesionStatus,
        },
        'solicitud_details': solicitudDetails,
        'sesion_details': sesionDetails,
        'generated_at': DateTime.now(),
      };
    } catch (e) {
      throw Exception('Error generando reporte de tutorías: $e');
    }
  }

  // Exportar reporte de tutorías a CSV
  Future<String?> exportTutoringToCSV() async {
    try {
      final report = await generateTutoringReport();
      final summary = report['summary'] as Map<String, dynamic>;
      final solicitudDetails =
          report['solicitud_details'] as List<Map<String, dynamic>>;
      final sesionDetails =
          report['sesion_details'] as List<Map<String, dynamic>>;
      final generatedAt = report['generated_at'] as DateTime;

      // Crear contenido CSV
      final StringBuffer csvContent = StringBuffer();

      // Encabezado del reporte
      csvContent.writeln('REPORTE DE TUTORÍAS - SISTEMA DE TUTORÍAS UNFV');
      csvContent.writeln(
        'Generado el: ${DateFormat('dd/MM/yyyy HH:mm').format(generatedAt)}',
      );
      csvContent.writeln('');

      // Resumen estadístico
      csvContent.writeln('RESUMEN ESTADÍSTICO');
      csvContent.writeln(
        'Total de Solicitudes,${summary['total_solicitudes']}',
      );
      csvContent.writeln('Total de Sesiones,${summary['total_sesiones']}');
      csvContent.writeln('');

      // Distribución de solicitudes por estado
      csvContent.writeln('SOLICITUDES POR ESTADO');
      final solicitudStatus =
          summary['solicitudes_por_estado'] as Map<String, dynamic>;
      solicitudStatus.forEach((status, count) {
        csvContent.writeln('${_getSolicitudStatusDisplayName(status)},$count');
      });
      csvContent.writeln('');

      // Distribución de sesiones por estado
      csvContent.writeln('SESIONES POR ESTADO');
      final sesionStatus =
          summary['sesiones_por_estado'] as Map<String, dynamic>;
      sesionStatus.forEach((status, count) {
        csvContent.writeln('${_getSesionStatusDisplayName(status)},$count');
      });
      csvContent.writeln('');

      // Detalles de solicitudes
      csvContent.writeln('DETALLES DE SOLICITUDES');
      csvContent.writeln(
        'ID,Estudiante ID,Tutor ID,Materia,Tema,Estado,Fecha Solicitud,Fecha Solicitada,Duración,Modalidad',
      );

      for (final solicitud in solicitudDetails) {
        csvContent.writeln(
          [
                solicitud['id'],
                solicitud['estudiante_id'],
                solicitud['tutor_id'],
                solicitud['materia'],
                solicitud['tema'],
                solicitud['estado'],
                solicitud['fecha_solicitud'],
                solicitud['fecha_solicitada'],
                solicitud['duracion'],
                solicitud['modalidad'],
              ]
              .map((field) => '"${field.toString().replaceAll('"', '""')}"')
              .join(','),
        );
      }
      csvContent.writeln('');

      // Detalles de sesiones
      csvContent.writeln('DETALLES DE SESIONES');
      csvContent.writeln(
        'ID,Solicitud ID,Estudiante ID,Tutor ID,Materia,Tema,Estado,Fecha Inicio,Fecha Fin,Duración Real,Modalidad,Notas',
      );

      for (final sesion in sesionDetails) {
        csvContent.writeln(
          [
                sesion['id'],
                sesion['solicitud_id'],
                sesion['estudiante_id'],
                sesion['tutor_id'],
                sesion['materia'],
                sesion['tema'],
                sesion['estado'],
                sesion['fecha_inicio'],
                sesion['fecha_fin'],
                sesion['duracion_real'],
                sesion['modalidad'],
                sesion['notas'],
              ]
              .map((field) => '"${field.toString().replaceAll('"', '""')}"')
              .join(','),
        );
      }

      final fileName =
          'reporte_tutorias_${DateFormat('yyyyMMdd_HHmmss').format(generatedAt)}.csv';

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

        return null;
      } else {
        // Implementación para Mobile/Desktop
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsString(csvContent.toString());
        return file.path;
      }
    } catch (e) {
      throw Exception('Error exportando reporte de tutorías: $e');
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

  String _getSolicitudStatusDisplayName(String status) {
    switch (status) {
      case 'pendiente':
        return 'Pendiente';
      case 'aceptada':
        return 'Aceptada';
      case 'rechazada':
        return 'Rechazada';
      case 'completada':
        return 'Completada';
      default:
        return status;
    }
  }

  String _getSesionStatusDisplayName(String status) {
    switch (status) {
      case 'programada':
        return 'Programada';
      case 'en_curso':
        return 'En Curso';
      case 'completada':
        return 'Completada';
      case 'cancelada':
        return 'Cancelada';
      default:
        return status;
    }
  }
}
