// Script de prueba para validar la funcionalidad de conflictos de horario
// Este script solo valida la lógica de negocio sin depender de Flutter o Firebase

import 'package:tutoring_app/core/models/disponibilidad.dart';
import 'package:tutoring_app/features/disponibilidad/services/disponibilidad_service.dart';

class TestValidacionConflictos {
  static void main() {
    print('=== PRUEBAS DE VALIDACIÓN DE CONFLICTOS ===\n');

    _probarNormalizacionHora();
    _probarValidacionHorarios();
    _probarConflictosMismoDia();

    print('\n=== PRUEBAS COMPLETADAS ===');
  }

  // Probar la normalización de formatos de hora
  static void _probarNormalizacionHora() {
    print('--- Probando normalización de formatos de hora ---');

    final testCases = [
      {'input': '14:30', 'expected': '14:30'},
      {'input': '2:30 PM', 'expected': '14:30'},
      {'input': '2:30 AM', 'expected': '02:30'},
      {'input': '12:00 PM', 'expected': '12:00'},
      {'input': '12:00 AM', 'expected': '00:00'},
      {'input': '9:45 AM', 'expected': '09:45'},
      {'input': '11:15 PM', 'expected': '23:15'},
    ];

    for (final testCase in testCases) {
      final result = _normalizarFormatoHora(testCase['input']!);
      final passed = result == testCase['expected'];

      print(
        '${passed ? '✅' : '❌'} "${testCase['input']}" -> "$result" (esperado: "${testCase['expected']}")',
      );
    }
  }

  // Método de normalización de hora (copiado del servicio)
  static String _normalizarFormatoHora(String hora) {
    if (hora.contains(':')) {
      final partes = hora.split(' ');
      if (partes.length == 1) {
        return hora;
      } else if (partes.length == 2) {
        final horaMin = partes[0].split(':');
        int hora = int.parse(horaMin[0]);
        int minuto = int.parse(horaMin[1]);
        final ampm = partes[1].toUpperCase();

        if (ampm == 'PM' && hora != 12) hora += 12;
        if (ampm == 'AM' && hora == 12) hora = 0;

        return '${hora.toString().padLeft(2, '0')}:${minuto.toString().padLeft(2, '0')}';
      }
    }
    return hora;
  }

  static int _convertirHoraAMinutos(String hora) {
    String horaNormalizada = _normalizarFormatoHora(hora);

    final partes = horaNormalizada.split(':');
    if (partes.length != 2) return 0;

    final horas = int.tryParse(partes[0]) ?? 0;
    final minutos = int.tryParse(partes[1]) ?? 0;

    return horas * 60 + minutos;
  }

  static bool _haySolapamiento(int inicio1, int fin1, int inicio2, int fin2) {
    return inicio1 < fin2 && inicio2 < fin1;
  }

  static void _probarValidacionHorarios() {
    print('\n--- Probando validación de horarios ---');

    // Simular disponibilidad de un tutor
    final disponibilidadSlots = [
      {
        'dia': 'Sábado',
        'horaInicio': '2:30 PM',
        'horaFin': '4:30 PM',
        'activo': true,
      },
      {
        'dia': 'Lunes',
        'horaInicio': '14:00',
        'horaFin': '16:00',
        'activo': true,
      },
    ];

    // Casos de prueba para el bug específico
    final casosPrueba = [
      {
        'descripcion': 'Solicitud para sábado dentro del horario disponible',
        'dia': 'Sábado',
        'horaInicio': '2:30 PM',
        'horaFin': '3:30 PM',
        'esperado': true,
      },
      {
        'descripcion': 'Solicitud para sábado fuera del horario',
        'dia': 'Sábado',
        'horaInicio': '5:00 PM',
        'horaFin': '6:00 PM',
        'esperado': false,
      },
      {
        'descripcion': 'Solicitud para lunes con formato 24h',
        'dia': 'Lunes',
        'horaInicio': '14:30',
        'horaFin': '15:30',
        'esperado': true,
      },
    ];

    for (final caso in casosPrueba) {
      bool resultado = false;

      // Buscar slot correspondiente
      for (final slot in disponibilidadSlots) {
        if (slot['dia'] == caso['dia'] && slot['activo'] == true) {
          final slotHoraInicio = _convertirHoraAMinutos(
            slot['horaInicio'] as String,
          );
          final slotHoraFin = _convertirHoraAMinutos(slot['horaFin'] as String);
          final horaInicioMinutos = _convertirHoraAMinutos(
            caso['horaInicio'] as String,
          );
          final horaFinMinutos = _convertirHoraAMinutos(
            caso['horaFin'] as String,
          );

          // Verificar que el horario solicitado esté completamente dentro del slot disponible
          if (horaInicioMinutos >= slotHoraInicio &&
              horaFinMinutos <= slotHoraFin &&
              horaInicioMinutos < horaFinMinutos) {
            resultado = true;
            break;
          }
        }
      }

      final passed = resultado == caso['esperado'];
      print(
        '${passed ? '✅' : '❌'} ${caso['descripcion']}: ${resultado} (esperado: ${caso['esperado']})',
      );
    }
  }

  static void _probarConflictosMismoDia() {
    print('\n--- Probando conflictos en el mismo día ---');

    // Simular sesiones existentes
    final sesionesExistentes = [
      {
        'fechaSesion': DateTime(2024, 1, 6), // Sábado
        'horaInicio': '3:00 PM',
        'horaFin': '4:00 PM',
      },
    ];

    // Casos de prueba para conflictos
    final casosPrueba = [
      {
        'descripcion': 'Nueva sesión que se solapa',
        'fechaSesion': DateTime(2024, 1, 6),
        'horaInicio': '3:30 PM',
        'horaFin': '4:30 PM',
        'esperado': true, // Debería haber conflicto
      },
      {
        'descripcion': 'Nueva sesión que no se solapa',
        'fechaSesion': DateTime(2024, 1, 6),
        'horaInicio': '4:30 PM',
        'horaFin': '5:30 PM',
        'esperado': false, // No debería haber conflicto
      },
    ];

    for (final caso in casosPrueba) {
      bool hayConflicto = false;

      for (final sesion in sesionesExistentes) {
        // Verificar si es el mismo día
        final sesionFecha = sesion['fechaSesion'] as DateTime;
        final casoFecha = caso['fechaSesion'] as DateTime;

        if (sesionFecha.year == casoFecha.year &&
            sesionFecha.month == casoFecha.month &&
            sesionFecha.day == casoFecha.day) {
          final sesionHoraInicio = _convertirHoraAMinutos(
            sesion['horaInicio'] as String,
          );
          final sesionHoraFin = _convertirHoraAMinutos(
            sesion['horaFin'] as String,
          );
          final nuevaHoraInicio = _convertirHoraAMinutos(
            caso['horaInicio'] as String,
          );
          final nuevaHoraFin = _convertirHoraAMinutos(
            caso['horaFin'] as String,
          );

          if (_haySolapamiento(
            nuevaHoraInicio,
            nuevaHoraFin,
            sesionHoraInicio,
            sesionHoraFin,
          )) {
            hayConflicto = true;
            break;
          }
        }
      }

      final passed = hayConflicto == caso['esperado'];
      print(
        '${passed ? '✅' : '❌'} ${caso['descripcion']}: ${hayConflicto} (esperado: ${caso['esperado']})',
      );
    }
  }
}

// Función para ejecutar las pruebas
void main() {
  TestValidacionConflictos.main();
}
