import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/notificaciones/services/notificacion_service.dart';
import '../core/models/notificacion.dart';

class TestNotificaciones {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final NotificacionService _notificacionService = NotificacionService();

  static Future<void> testNotificaciones() async {
    print('🧪 Iniciando pruebas de notificaciones...');

    try {
      // Inicializar el servicio
      await _notificacionService.initialize();
      print('✅ Servicio de notificaciones inicializado');

      // Obtener usuario actual
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No hay usuario autenticado');
        return;
      }

      print('👤 Usuario: ${user.email}');

      // Crear notificaciones de prueba
      await _crearNotificacionesPrueba(user.uid);

      // Verificar notificaciones creadas
      await _verificarNotificaciones(user.uid);

      print('✅ Pruebas completadas exitosamente');

    } catch (e) {
      print('❌ Error en las pruebas: $e');
    }
  }

  static Future<void> _crearNotificacionesPrueba(String usuarioId) async {
    print('📝 Creando notificaciones de prueba...');

    // Notificación de solicitud de tutoría
    await _notificacionService.enviarNotificacionSolicitudTutoria(
      estudianteId: 'estudiante_test',
      estudianteNombre: 'Juan Pérez',
      tutorId: usuarioId,
      materia: 'Matemáticas',
      fecha: DateTime.now().add(const Duration(days: 1)),
    );

    // Notificación de respuesta de solicitud
    await _notificacionService.enviarNotificacionRespuestaSolicitud(
      estudianteId: usuarioId,
      tutorId: 'tutor_test',
      tutorNombre: 'María García',
      aceptada: true,
      materia: 'Física',
      fecha: DateTime.now().add(const Duration(days: 2)),
    );

    // Notificación de recordatorio de sesión
    await _notificacionService.enviarNotificacionRecordatorioSesion(
      usuarioId: usuarioId,
      materia: 'Química',
      fecha: DateTime.now().add(const Duration(hours: 1)),
      nombreTutor: 'Carlos López',
    );

    print('✅ Notificaciones de prueba creadas');
  }

  static Future<void> _verificarNotificaciones(String usuarioId) async {
    print('🔍 Verificando notificaciones...');

    final notificaciones = await _notificacionService
        .getNotificacionesUsuario(usuarioId)
        .first;

    print('📊 Total de notificaciones: ${notificaciones.length}');

    for (int i = 0; i < notificaciones.length; i++) {
      final notificacion = notificaciones[i];
      print('📋 Notificación ${i + 1}:');
      print('   Título: ${notificacion.titulo}');
      print('   Mensaje: ${notificacion.mensaje}');
      print('   Tipo: ${notificacion.tipoString}');
      print('   Leída: ${notificacion.leida}');
      print('   Tiempo: ${notificacion.tiempoTranscurrido}');
      print('   ---');
    }

    // Verificar notificaciones no leídas
    final noLeidas = await _notificacionService.getNotificacionesNoLeidas(usuarioId);
    print('🔴 Notificaciones no leídas: $noLeidas');
  }

  static Future<void> limpiarNotificacionesPrueba(String usuarioId) async {
    print('🧹 Limpiando notificaciones de prueba...');

    final notificaciones = await _firestore
        .collection('notificaciones')
        .where('usuarioId', isEqualTo: usuarioId)
        .get();

    for (final doc in notificaciones.docs) {
      await doc.reference.delete();
    }

    print('✅ Notificaciones de prueba eliminadas');
  }
} 