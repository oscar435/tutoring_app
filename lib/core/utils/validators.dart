import 'package:flutter/services.dart';

/// Utilidades para validaciones comunes en la aplicación
class Validators {
  /// Valida si un email es válido
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  /// Valida si un email es institucional de UNFV
  static bool isValidInstitutionalEmail(String email) {
    final emailRegex = RegExp(r'^(\d{10})@unfv\.edu\.pe$');
    return emailRegex.hasMatch(email);
  }

  /// Extrae el código de estudiante de un email institucional
  static String? extractStudentCode(String email) {
    final regex = RegExp(r'^(\d{10})@unfv\.edu\.pe$');
    final match = regex.firstMatch(email);
    return match?.group(1);
  }

  /// Valida si una contraseña cumple con los requisitos mínimos
  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  /// Valida si un nombre es válido (no vacío y solo letras)
  static bool isValidName(String name) {
    final nameRegex = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$');
    return name.isNotEmpty && nameRegex.hasMatch(name);
  }

  /// Valida si un código de estudiante es válido (10 dígitos)
  static bool isValidStudentCode(String code) {
    final codeRegex = RegExp(r'^\d{10}$');
    return codeRegex.hasMatch(code);
  }

  /// Valida si una edad es válida (entre 15 y 100 años)
  static bool isValidAge(int age) {
    return age >= 15 && age <= 100;
  }

  /// Valida si un ciclo académico es válido (entre 1 y 20)
  static bool isValidAcademicCycle(int cycle) {
    return cycle >= 1 && cycle <= 20;
  }

  /// Formatea un número de teléfono
  static String formatPhoneNumber(String phone) {
    // Eliminar todos los caracteres no numéricos
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');

    // Si tiene 9 dígitos, formatear como celular peruano
    if (digits.length == 9) {
      return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
    }

    // Si tiene 7 dígitos, formatear como teléfono fijo
    if (digits.length == 7) {
      return '${digits.substring(0, 3)} ${digits.substring(3, 5)} ${digits.substring(5)}';
    }

    return phone;
  }

  /// Valida si una hora es válida (formato HH:mm)
  static bool isValidTime(String time) {
    final timeRegex = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');
    return timeRegex.hasMatch(time);
  }

  /// Convierte una hora en formato string a minutos desde medianoche
  static int timeToMinutes(String time) {
    final parts = time.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    return hours * 60 + minutes;
  }

  /// Convierte minutos desde medianoche a formato string HH:mm
  static String minutesToTime(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
  }

  /// Valida si hay solapamiento entre dos rangos de tiempo
  static bool hasTimeOverlap(
    String start1,
    String end1,
    String start2,
    String end2,
  ) {
    final start1Min = timeToMinutes(start1);
    final end1Min = timeToMinutes(end1);
    final start2Min = timeToMinutes(start2);
    final end2Min = timeToMinutes(end2);

    return start1Min < end2Min && end1Min > start2Min;
  }

  /// Filtros de texto para campos específicos
  static List<TextInputFormatter> getEmailFormatters() {
    return [
      FilteringTextInputFormatter.deny(RegExp(r'\s')), // No espacios
      FilteringTextInputFormatter.deny(
        RegExp(r'[<>]'),
      ), // No caracteres especiales
    ];
  }

  static List<TextInputFormatter> getNameFormatters() {
    return [
      FilteringTextInputFormatter.allow(
        RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]'),
      ), // Solo letras y espacios
    ];
  }

  static List<TextInputFormatter> getStudentCodeFormatters() {
    return [
      FilteringTextInputFormatter.digitsOnly, // Solo dígitos
      LengthLimitingTextInputFormatter(10), // Máximo 10 dígitos
    ];
  }

  static List<TextInputFormatter> getPhoneFormatters() {
    return [
      FilteringTextInputFormatter.digitsOnly, // Solo dígitos
      LengthLimitingTextInputFormatter(9), // Máximo 9 dígitos
    ];
  }

  /// Valida si se puede cancelar una tutoría basado en el plazo de 24 horas
  static bool puedeCancelarTutoria(DateTime fechaSesion) {
    final ahora = DateTime.now();
    final diferencia = fechaSesion.difference(ahora);

    // Solo permitir cancelar si faltan más de 24 horas
    return diferencia.inHours >= 24;
  }

  /// Obtiene el mensaje de error para cancelación fuera de plazo
  static String getMensajeErrorCancelacion(DateTime fechaSesion) {
    final ahora = DateTime.now();
    final diferencia = fechaSesion.difference(ahora);

    if (diferencia.isNegative) {
      return 'No se puede cancelar una tutoría que ya pasó';
    }

    final horasRestantes = diferencia.inHours;
    final minutosRestantes = diferencia.inMinutes % 60;

    if (horasRestantes < 24) {
      return 'Solo se puede cancelar hasta 24 horas antes. Faltan $horasRestantes horas y $minutosRestantes minutos';
    }

    return '';
  }
}
