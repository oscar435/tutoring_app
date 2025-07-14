import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:tutoring_app/core/models/disponibilidad.dart';
import 'package:tutoring_app/core/models/solicitud_tutoria.dart';
import 'package:tutoring_app/features/disponibilidad/services/disponibilidad_service.dart';
import 'package:tutoring_app/features/tutorias/services/solicitud_tutoria_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AgendarTutoriaPage extends StatefulWidget {
  final String tutorId;
  final String estudianteId;
  const AgendarTutoriaPage({
    required this.tutorId,
    required this.estudianteId,
    super.key,
  });

  @override
  State<AgendarTutoriaPage> createState() => _AgendarTutoriaPageState();
}

class _AgendarTutoriaPageState extends State<AgendarTutoriaPage> {
  Disponibilidad? _disponibilidad;
  Slot? _slotSeleccionado;
  bool _cargando = true;
  bool _guardando = false;
  DateTime? _fechaSeleccionada;
  List<String> _cursosTutor = [];
  String? _cursoSeleccionado;
  List<Slot> _horariosDisponibles = [];
  String? _errorMensaje;
  String? _diaSeleccionado;

  final List<String> _diasSemana = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  @override
  void initState() {
    super.initState();
    _cargarDisponibilidad();
    _cargarCursosTutor();
  }

  Future<void> _cargarDisponibilidad() async {
    try {
      setState(() {
        _cargando = true;
        _errorMensaje = null;
      });

      final servicio = DisponibilidadService();
      final disponibilidad = await servicio.obtenerDisponibilidad(
        widget.tutorId,
      );

      if (mounted) {
        setState(() {
          _disponibilidad = disponibilidad;
          _cargando = false;

          if (disponibilidad == null) {
            _errorMensaje = 'El docente no tiene disponibilidad registrada.';
          } else if (disponibilidad.slots.isEmpty) {
            _errorMensaje = 'El docente no tiene horarios configurados.';
          } else {
            final slotsActivos = disponibilidad.slots
                .where((slot) => slot.activo)
                .toList();
            if (slotsActivos.isEmpty) {
              _errorMensaje =
                  'El docente no tiene horarios activos configurados.';
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cargando = false;
          _errorMensaje = 'Error al cargar la disponibilidad: $e';
        });
      }
    }
  }

  Future<void> _cargarCursosTutor() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('tutores')
          .doc(widget.tutorId)
          .get();
      final data = doc.data();

      if (mounted) {
        setState(() {
          _cursosTutor = (data?['cursos'] as List?)?.cast<String>() ?? [];
          if (_cursosTutor.isNotEmpty) {
            _cursoSeleccionado = _cursosTutor.first;
          }
        });
      }
    } catch (e) {
      // print('Error al cargar cursos del tutor: $e');
    }
  }

  String _obtenerDiaSemana(DateTime fecha) {
    switch (fecha.weekday) {
      case 1:
        return 'Lunes';
      case 2:
        return 'Martes';
      case 3:
        return 'Miércoles';
      case 4:
        return 'Jueves';
      case 5:
        return 'Viernes';
      case 6:
        return 'Sábado';
      case 7:
        return 'Domingo';
      default:
        return 'Desconocido';
    }
  }

  int _obtenerNumeroDia(String dia) {
    switch (dia) {
      case 'Lunes':
        return 1;
      case 'Martes':
        return 2;
      case 3:
        return 3;
      case 'Jueves':
        return 4;
      case 'Viernes':
        return 5;
      case 'Sábado':
        return 6;
      case 'Domingo':
        return 7;
      default:
        return 1;
    }
  }

  DateTime _encontrarProximaFecha(String dia) {
    final ahora = DateTime.now();
    final numeroDia = _obtenerNumeroDia(dia);
    final diasHastaProximoDia = (numeroDia - ahora.weekday) % 7;

    // Si es el mismo día, buscar la próxima semana
    final diasAAdicionar = diasHastaProximoDia == 0 ? 7 : diasHastaProximoDia;

    return DateTime(ahora.year, ahora.month, ahora.day + diasAAdicionar);
  }

  Future<void> _seleccionarDia(String? dia) async {
    if (dia == null) return;

    setState(() {
      _diaSeleccionado = dia;
      _fechaSeleccionada = _encontrarProximaFecha(dia);
    });

    await _actualizarHorariosDisponibles();
  }

  Future<void> _actualizarHorariosDisponibles() async {
    if (_fechaSeleccionada == null) {
      setState(() {
        _horariosDisponibles = [];
        _slotSeleccionado = null;
      });
      return;
    }

    setState(() => _cargando = true);

    try {
      final servicio = DisponibilidadService();
      final horariosDisponibles = await servicio.obtenerHorariosDisponibles(
        tutorId: widget.tutorId,
        fecha: _fechaSeleccionada!,
      );

      if (mounted) {
        setState(() {
          _horariosDisponibles = horariosDisponibles;
          _slotSeleccionado = null; // Resetear selección
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar horarios disponibles: $e')),
        );
      }
    }
  }

  // Combinar fecha seleccionada y hora de inicio en un solo DateTime
  DateTime _combinarFechaYHora(DateTime fecha, String horaInicio) {
    // Normalizar el formato de hora
    String horaNormalizada = _normalizarFormatoHora(horaInicio);

    final partes = horaNormalizada.split(':');
    int hora = int.parse(partes[0]);
    int minuto = int.parse(partes[1]);

    return DateTime(fecha.year, fecha.month, fecha.day, hora, minuto);
  }

  // Normalizar formato de hora para manejar AM/PM y formato 24h
  String _normalizarFormatoHora(String hora) {
    // Si ya está en formato 24h (HH:MM), devolver tal como está
    if (hora.contains(':')) {
      final partes = hora.split(' ');
      if (partes.length == 1) {
        // Formato 24h (HH:MM)
        return hora;
      } else if (partes.length == 2) {
        // Formato 12h con AM/PM (HH:MM AM/PM)
        final horaMin = partes[0].split(':');
        int hora = int.parse(horaMin[0]);
        int minuto = int.parse(horaMin[1]);
        final ampm = partes[1].toUpperCase();

        if (ampm == 'PM' && hora != 12) hora += 12;
        if (ampm == 'AM' && hora == 12) hora = 0;

        return '${hora.toString().padLeft(2, '0')}:${minuto.toString().padLeft(2, '0')}';
      }
    }

    return hora; // Devolver tal como está si no se puede parsear
  }

  Future<void> _agendarTutoria() async {
    if (_slotSeleccionado == null ||
        _fechaSeleccionada == null ||
        _cursoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor, complete todos los campos requeridos'),
        ),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      // Validar conflicto de horario antes de crear la solicitud
      final servicio = DisponibilidadService();
      final hayConflicto = await servicio.hayConflictoHorario(
        tutorId: widget.tutorId,
        fechaSesion: _fechaSeleccionada!,
        horaInicio: _slotSeleccionado!.horaInicio,
        horaFin: _slotSeleccionado!.horaFin,
      );

      if (hayConflicto) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'El horario seleccionado ya no está disponible. Por favor, seleccione otro horario.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        // Recargar horarios disponibles
        await _actualizarHorariosDisponibles();
        setState(() => _guardando = false);
        return;
      }

      // Validar que el horario esté dentro de la disponibilidad del docente
      final esHorarioValido = await servicio.esHorarioValido(
        tutorId: widget.tutorId,
        dia: _slotSeleccionado!.dia,
        horaInicio: _slotSeleccionado!.horaInicio,
        horaFin: _slotSeleccionado!.horaFin,
      );

      if (!esHorarioValido) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'El horario seleccionado no está dentro de la disponibilidad del docente.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _guardando = false);
        return;
      }

      // Crear la solicitud
      final solicitudService = SolicitudTutoriaService();
      final fechaSesion = _combinarFechaYHora(
        _fechaSeleccionada!,
        _slotSeleccionado!.horaInicio,
      );
      final solicitud = SolicitudTutoria(
        id: const Uuid().v4(),
        tutorId: widget.tutorId,
        estudianteId: widget.estudianteId,
        fechaHora: DateTime.now(),
        estado: 'pendiente',
        curso: _cursoSeleccionado,
        dia: _slotSeleccionado!.dia,
        horaInicio: _slotSeleccionado!.horaInicio,
        horaFin: _slotSeleccionado!.horaFin,
        fechaSesion: fechaSesion,
      );

      await solicitudService.crearSolicitud(solicitud);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Solicitud enviada al docente exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar la solicitud: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  Widget _mostrarInformacionDisponibilidad() {
    if (_disponibilidad == null) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red),
        ),
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                _errorMensaje ??
                    'No se pudo cargar la disponibilidad del docente.',
                style: TextStyle(color: Colors.red[800]),
              ),
            ),
          ],
        ),
      );
    }

    final slotsActivos = _disponibilidad!.slots
        .where((slot) => slot.activo)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Disponibilidad del docente:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 10),
        if (slotsActivos.isEmpty)
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'El docente no tiene horarios activos configurados.',
                    style: TextStyle(color: Colors.orange[800]),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'Horarios configurados:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                ...slotsActivos.map(
                  (slot) => Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• ${slot.dia}: ${slot.horaInicio} - ${slot.horaFin}',
                      style: TextStyle(color: Colors.green[700]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Agendar Tutoría')),
      body: _cargando
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mostrar información de disponibilidad
                  _mostrarInformacionDisponibilidad(),

                  if (_cursosTutor.isNotEmpty) ...[
                    Text(
                      'Selecciona el curso:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    DropdownButton<String>(
                      value: _cursoSeleccionado,
                      isExpanded: true,
                      items: _cursosTutor
                          .map(
                            (curso) => DropdownMenuItem(
                              value: curso,
                              child: Text(curso),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _cursoSeleccionado = value),
                    ),
                    SizedBox(height: 20),
                  ],

                  // Filtro por día de la semana
                  Text(
                    'Selecciona el día de la semana:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _diaSeleccionado,
                    hint: const Text('Seleccionar día'),
                    isExpanded: true,
                    items: _diasSemana.map((String dia) {
                      return DropdownMenuItem<String>(
                        value: dia,
                        child: Text(dia),
                      );
                    }).toList(),
                    onChanged: _seleccionarDia,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Mostrar fecha seleccionada
                  if (_fechaSeleccionada != null) ...[
                    Text(
                      'Fecha seleccionada:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            '${_obtenerDiaSemana(_fechaSeleccionada!)} ${_fechaSeleccionada!.day}/${_fechaSeleccionada!.month}/${_fechaSeleccionada!.year}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                          Spacer(),
                          TextButton(
                            onPressed: () async {
                              final now = DateTime.now();
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _fechaSeleccionada!,
                                firstDate: now,
                                lastDate: now.add(Duration(days: 365)),
                              );
                              if (picked != null) {
                                setState(() {
                                  _fechaSeleccionada = picked;
                                  _diaSeleccionado = _obtenerDiaSemana(picked);
                                });
                                await _actualizarHorariosDisponibles();
                              }
                            },
                            child: Text('Cambiar fecha'),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                  if (_fechaSeleccionada != null) ...[
                    Text(
                      'Horarios disponibles para ${_obtenerDiaSemana(_fechaSeleccionada!)}:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    if (_horariosDisponibles.isEmpty)
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No hay horarios disponibles para esta fecha. El docente puede estar ocupado o no tener disponibilidad en este día.',
                                style: TextStyle(color: Colors.orange[800]),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._horariosDisponibles.map(
                        (slot) => RadioListTile<Slot>(
                          title: Text(
                            '${slot.dia}: ${slot.horaInicio} - ${slot.horaFin}',
                          ),
                          value: slot,
                          groupValue: _slotSeleccionado,
                          onChanged: (s) =>
                              setState(() => _slotSeleccionado = s),
                        ),
                      ),
                    SizedBox(height: 20),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed:
                          (_slotSeleccionado == null ||
                              _fechaSeleccionada == null ||
                              _cursoSeleccionado == null ||
                              _guardando)
                          ? null
                          : _agendarTutoria,
                      child: _guardando
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('Enviando solicitud...'),
                              ],
                            )
                          : Text('Agendar Tutoría'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
