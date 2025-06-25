import 'package:flutter/material.dart';

/// Constantes de la aplicación para centralizar valores comunes
class AppConstants {
  // Colores principales
  static const Color primaryColor = Colors.deepPurple;
  static const Color secondaryColor = Colors.orange;
  static const Color backgroundColor = Color(0xfff7f7f7);
  static const Color cardBackgroundColor = Colors.white;

  // Espaciado
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  // Tamaños de fuente
  static const double titleFontSize = 22.0;
  static const double subtitleFontSize = 16.0;
  static const double bodyFontSize = 14.0;
  static const double captionFontSize = 12.0;

  // Radios de borde
  static const double defaultBorderRadius = 12.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 16.0;

  // Duración de animaciones
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Días de la semana
  static const List<String> diasSemana = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  // Estados de solicitudes
  static const String estadoPendiente = 'pendiente';
  static const String estadoAceptada = 'aceptada';
  static const String estadoRechazada = 'rechazada';

  // Estados de sesiones
  static const String sesionAceptada = 'aceptada';
  static const String sesionFinalizada = 'finalizada';
  static const String sesionCancelada = 'cancelada';

  // Roles de usuario
  static const String roleStudent = 'student';
  static const String roleTeacher = 'teacher';
  static const String roleAdmin = 'admin';
  static const String roleSuperAdmin = 'superAdmin';

  // Mensajes de error comunes
  static const String errorConexion =
      'Error de conexión. Verifica tu internet e intenta nuevamente';
  static const String errorCargando = 'Error al cargar los datos';
  static const String errorGuardando = 'Error al guardar los cambios';
  static const String errorInesperado = 'Ocurrió un error inesperado';

  // Mensajes de éxito comunes
  static const String exitoGuardado = 'Datos guardados correctamente';
  static const String exitoActualizado = 'Datos actualizados correctamente';
  static const String exitoEliminado = 'Elemento eliminado correctamente';
}
