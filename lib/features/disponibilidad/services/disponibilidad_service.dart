import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutoring_app/core/models/disponibilidad.dart';
import 'package:tutoring_app/core/models/sesion_tutoria.dart';

class DisponibilidadService {
  final CollectionReference _disponibilidadRef =
      FirebaseFirestore.instance.collection('disponibilidades');
  final CollectionReference _sesionesRef =
      FirebaseFirestore.instance.collection('sesiones_tutoria');

  // Guardar o actualizar la disponibilidad de un tutor
  Future<void> guardarDisponibilidad(Disponibilidad disponibilidad) async {
    await _disponibilidadRef.doc(disponibilidad.tutorId).set(disponibilidad.toMap());
  }

  // Obtener la disponibilidad de un tutor por su ID
  Future<Disponibilidad?> obtenerDisponibilidad(String tutorId) async {
    final doc = await _disponibilidadRef.doc(tutorId).get();
    if (doc.exists) {
      return Disponibilidad.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  // Validar si hay conflicto de horario para una fecha y hora específica
  Future<bool> hayConflictoHorario({
    required String tutorId,
    required DateTime fechaSesion,
    required String horaInicio,
    required String horaFin,
    String? sesionIdExcluir, // Para excluir la sesión actual en caso de edición
  }) async {
    try {
      // Obtener todas las sesiones confirmadas del tutor para la fecha específica
      final query = await _sesionesRef
          .where('tutorId', isEqualTo: tutorId)
          .where('estado', isEqualTo: 'aceptada')
          .get();

      final sesiones = query.docs
          .map((doc) => SesionTutoria.fromMap(doc.data() as Map<String, dynamic>))
          .where((sesion) {
            // Excluir la sesión actual si estamos editando
            if (sesionIdExcluir != null && sesion.id == sesionIdExcluir) {
              return false;
            }
            
            // Verificar si la sesión es para la misma fecha
            final sesionFecha = sesion.fechaSesion;
            if (sesionFecha == null) return false;
            
            return sesionFecha.year == fechaSesion.year &&
                   sesionFecha.month == fechaSesion.month &&
                   sesionFecha.day == fechaSesion.day;
          })
          .toList();

      // Convertir horas a minutos para facilitar la comparación
      final horaInicioMinutos = _convertirHoraAMinutos(horaInicio);
      final horaFinMinutos = _convertirHoraAMinutos(horaFin);

      // Verificar conflictos con cada sesión existente
      for (final sesion in sesiones) {
        final sesionHoraInicio = _convertirHoraAMinutos(sesion.horaInicio);
        final sesionHoraFin = _convertirHoraAMinutos(sesion.horaFin);

        // Verificar si hay solapamiento
        if (_haySolapamiento(
          horaInicioMinutos, horaFinMinutos,
          sesionHoraInicio, sesionHoraFin,
        )) {
          return true; // Hay conflicto
        }
      }

      return false; // No hay conflicto
    } catch (e) {
      print('Error al validar conflicto de horario: $e');
      return true; // En caso de error, asumir que hay conflicto por seguridad
    }
  }

  // Obtener horarios disponibles para una fecha específica
  Future<List<Slot>> obtenerHorariosDisponibles({
    required String tutorId,
    required DateTime fecha,
  }) async {
    try {
      // Obtener la disponibilidad del tutor
      final disponibilidad = await obtenerDisponibilidad(tutorId);
      if (disponibilidad == null) return [];

      // Obtener el día de la semana de la fecha
      final diaSemana = _obtenerDiaSemana(fecha.weekday);

      // Obtener las sesiones confirmadas para esa fecha
      final query = await _sesionesRef
          .where('tutorId', isEqualTo: tutorId)
          .where('estado', isEqualTo: 'aceptada')
          .get();

      final sesionesOcupadas = query.docs
          .map((doc) => SesionTutoria.fromMap(doc.data() as Map<String, dynamic>))
          .where((sesion) {
            final sesionFecha = sesion.fechaSesion;
            if (sesionFecha == null) return false;
            
            return sesionFecha.year == fecha.year &&
                   sesionFecha.month == fecha.month &&
                   sesionFecha.day == fecha.day;
          })
          .toList();

      // Filtrar slots disponibles
      final slotsDisponibles = <Slot>[];
      
      for (final slot in disponibilidad.slots) {
        // Solo considerar slots del día de la semana correspondiente
        if (slot.dia != diaSemana) continue;
        
        if (!slot.activo) continue; // Saltar slots inactivos

        // Verificar si el slot está ocupado
        bool estaOcupado = false;
        final slotHoraInicio = _convertirHoraAMinutos(slot.horaInicio);
        final slotHoraFin = _convertirHoraAMinutos(slot.horaFin);

        for (final sesion in sesionesOcupadas) {
          final sesionHoraInicio = _convertirHoraAMinutos(sesion.horaInicio);
          final sesionHoraFin = _convertirHoraAMinutos(sesion.horaFin);

          if (_haySolapamiento(
            slotHoraInicio, slotHoraFin,
            sesionHoraInicio, sesionHoraFin,
          )) {
            estaOcupado = true;
            break;
          }
        }

        if (!estaOcupado) {
          slotsDisponibles.add(slot);
        }
      }

      return slotsDisponibles;
    } catch (e) {
      print('Error al obtener horarios disponibles: $e');
      return [];
    }
  }

  // Verificar si dos rangos de tiempo se solapan
  bool _haySolapamiento(
    int inicio1, int fin1,
    int inicio2, int fin2,
  ) {
    return inicio1 < fin2 && inicio2 < fin1;
  }

  // Convertir hora en formato "HH:MM" a minutos
  int _convertirHoraAMinutos(String hora) {
    final partes = hora.split(':');
    if (partes.length != 2) return 0;
    
    final horas = int.tryParse(partes[0]) ?? 0;
    final minutos = int.tryParse(partes[1]) ?? 0;
    
    return horas * 60 + minutos;
  }

  // Validar que un horario esté dentro de la disponibilidad del tutor
  Future<bool> esHorarioValido({
    required String tutorId,
    required String dia,
    required String horaInicio,
    required String horaFin,
  }) async {
    try {
      final disponibilidad = await obtenerDisponibilidad(tutorId);
      if (disponibilidad == null) return false;

      // Buscar un slot que coincida con el día y horario
      for (final slot in disponibilidad.slots) {
        if (slot.dia == dia && slot.activo) {
          final slotHoraInicio = _convertirHoraAMinutos(slot.horaInicio);
          final slotHoraFin = _convertirHoraAMinutos(slot.horaFin);
          final horaInicioMinutos = _convertirHoraAMinutos(horaInicio);
          final horaFinMinutos = _convertirHoraAMinutos(horaFin);

          // Verificar que el horario solicitado esté completamente dentro del slot disponible
          if (horaInicioMinutos >= slotHoraInicio && 
              horaFinMinutos <= slotHoraFin &&
              horaInicioMinutos < horaFinMinutos) {
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      print('Error al validar horario: $e');
      return false;
    }
  }

  // Convertir número de día de la semana a nombre
  String _obtenerDiaSemana(int weekday) {
    switch (weekday) {
      case 1: return 'Lunes';
      case 2: return 'Martes';
      case 3: return 'Miércoles';
      case 4: return 'Jueves';
      case 5: return 'Viernes';
      case 6: return 'Sábado';
      case 7: return 'Domingo';
      default: return 'Desconocido';
    }
  }
} 