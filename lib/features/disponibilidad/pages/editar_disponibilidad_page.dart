import 'package:flutter/material.dart';
import 'package:tutoring_app/core/models/disponibilidad.dart';
import 'package:tutoring_app/features/disponibilidad/services/disponibilidad_service.dart';

class EditarDisponibilidadPage extends StatefulWidget {
  final String tutorId;
  const EditarDisponibilidadPage({required this.tutorId, super.key});

  @override
  State<EditarDisponibilidadPage> createState() =>
      _EditarDisponibilidadPageState();
}

class _EditarDisponibilidadPageState extends State<EditarDisponibilidadPage> {
  final _formKey = GlobalKey<FormState>();
  List<Slot> _slots = [];
  List<String> _diasSeleccionados = [];
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFin;

  final _dias = [
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
  }

  Future<void> _cargarDisponibilidad() async {
    final servicio = DisponibilidadService();
    final disponibilidad = await servicio.obtenerDisponibilidad(widget.tutorId);
    if (disponibilidad != null) {
      setState(() {
        _slots = disponibilidad.slots;
      });
    }
  }

  Future<void> _seleccionarHoraInicio() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _horaInicio ?? TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null) setState(() => _horaInicio = picked);
  }

  Future<void> _seleccionarHoraFin() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _horaFin ?? TimeOfDay(hour: 10, minute: 0),
    );
    if (picked != null) setState(() => _horaFin = picked);
  }

  void _agregarSlots() {
    if (_diasSeleccionados.isEmpty || _horaInicio == null || _horaFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor selecciona días y horarios')),
      );
      return;
    }

    // Validar que la hora de fin sea después de la hora de inicio
    if (_horaInicio!.hour > _horaFin!.hour ||
        (_horaInicio!.hour == _horaFin!.hour &&
            _horaInicio!.minute >= _horaFin!.minute)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'La hora de fin debe ser posterior a la hora de inicio',
          ),
        ),
      );
      return;
    }

    bool algunoAgregado = false;
    bool algunoSolapado = false;
    List<Slot> nuevosSlots = List.from(_slots); // Crear una nueva lista

    for (final dia in _diasSeleccionados) {
      final nuevoSlot = Slot(
        dia: dia,
        horaInicio: _horaInicio!.format(context),
        horaFin: _horaFin!.format(context),
      );

      // Obtener todos los slots existentes para este día
      final slotsDelDia = nuevosSlots.where((s) => s.dia == dia).toList();

      // Verificar si hay solapamiento con algún slot existente
      bool haySolapamiento = false;
      for (final slotExistente in slotsDelDia) {
        final horaInicioExistente = _parseHora(slotExistente.horaInicio);
        final horaFinExistente = _parseHora(slotExistente.horaFin);

        if (_haySolapamiento(
          _horaInicio!,
          _horaFin!,
          horaInicioExistente,
          horaFinExistente,
        )) {
          haySolapamiento = true;
          algunoSolapado = true;
          break;
        }
      }

      if (!haySolapamiento) {
        nuevosSlots.add(nuevoSlot);
        algunoAgregado = true;
      }
    }

    // Actualizar el estado con la nueva lista completa
    if (algunoAgregado) {
      setState(() {
        // Ordenar los slots por día y hora antes de actualizar
        nuevosSlots.sort((a, b) {
          if (a.dia != b.dia) {
            // Primero ordenar por día según el orden en _dias
            return _dias.indexOf(a.dia).compareTo(_dias.indexOf(b.dia));
          }
          // Si es el mismo día, ordenar por hora
          final horaInicioA = _parseHora(a.horaInicio);
          final horaInicioB = _parseHora(b.horaInicio);
          final minutosA = horaInicioA.hour * 60 + horaInicioA.minute;
          final minutosB = horaInicioB.hour * 60 + horaInicioB.minute;
          return minutosA.compareTo(minutosB);
        });
        _slots = nuevosSlots;
      });
    }

    if (algunoSolapado) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            algunoAgregado
                ? 'Algunos horarios se solapaban y no fueron agregados'
                : 'Los horarios se solapan con slots existentes',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    } else if (algunoAgregado) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Horarios agregados correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    }

    // Limpiar selección
    setState(() {
      _diasSeleccionados = [];
      _horaInicio = null;
      _horaFin = null;
    });
  }

  // Convierte una hora en formato string "HH:mm" a TimeOfDay
  TimeOfDay _parseHora(String hora) {
    final partes = hora.split(':');
    return TimeOfDay(hour: int.parse(partes[0]), minute: int.parse(partes[1]));
  }

  // Verifica si hay solapamiento entre dos rangos de hora
  bool _haySolapamiento(
    TimeOfDay inicio1,
    TimeOfDay fin1,
    TimeOfDay inicio2,
    TimeOfDay fin2,
  ) {
    final inicio1Minutos = inicio1.hour * 60 + inicio1.minute;
    final fin1Minutos = fin1.hour * 60 + fin1.minute;
    final inicio2Minutos = inicio2.hour * 60 + inicio2.minute;
    final fin2Minutos = fin2.hour * 60 + fin2.minute;

    return inicio1Minutos < fin2Minutos && fin1Minutos > inicio2Minutos;
  }

  void _eliminarSlot(int index) {
    setState(() {
      _slots.removeAt(index);
    });
  }

  Future<void> _guardarDisponibilidad() async {
    final servicio = DisponibilidadService();
    await servicio.guardarDisponibilidad(
      Disponibilidad(tutorId: widget.tutorId, slots: _slots),
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Disponibilidad guardada')));
  }

  Map<String, List<Slot>> _agruparPorDia() {
    final Map<String, List<Slot>> agrupado = {};

    // Primero, agrupar los slots por día
    for (final slot in _slots) {
      if (!agrupado.containsKey(slot.dia)) {
        agrupado[slot.dia] = [];
      }
      agrupado[slot.dia]!.add(slot);
    }

    // Ordenar los slots dentro de cada día por hora
    agrupado.forEach((dia, slots) {
      slots.sort((a, b) {
        final horaInicioA = _parseHora(a.horaInicio);
        final horaInicioB = _parseHora(b.horaInicio);
        final minutosA = horaInicioA.hour * 60 + horaInicioA.minute;
        final minutosB = horaInicioB.hour * 60 + horaInicioB.minute;
        return minutosA.compareTo(minutosB);
      });
    });

    // Crear un nuevo mapa ordenado según el orden de los días en _dias
    final ordenado = Map.fromEntries(
      _dias
          .where((dia) => agrupado.containsKey(dia))
          .map((dia) => MapEntry(dia, agrupado[dia]!)),
    );

    return ordenado;
  }

  @override
  Widget build(BuildContext context) {
    final horariosPorDia = _agruparPorDia();
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Disponibilidad'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Selecciona los días:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _dias
                    .map(
                      (dia) => FilterChip(
                        label: Text(dia),
                        selected: _diasSeleccionados.contains(dia),
                        selectedColor: Colors.deepPurple.withAlpha(
                          (0.2 * 255).toInt(),
                        ),
                        checkmarkColor: Colors.deepPurple,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _diasSeleccionados.add(dia);
                            } else {
                              _diasSeleccionados.remove(dia);
                            }
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.access_time),
                      onPressed: _seleccionarHoraInicio,
                      label: Text(
                        _horaInicio == null
                            ? 'Hora de inicio'
                            : _horaInicio!.format(context),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.deepPurple,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.access_time),
                      onPressed: _seleccionarHoraFin,
                      label: Text(
                        _horaFin == null
                            ? 'Hora de fin'
                            : _horaFin!.format(context),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.deepPurple,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: Icon(Icons.add),
                onPressed: _agregarSlots,
                label: Text('Agregar horario'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 45),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: _slots.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No has agregado horarios de disponibilidad.',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        children: horariosPorDia.entries.map((entry) {
                          final dia = entry.key;
                          final slots = entry.value;
                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ExpansionTile(
                              title: Text(
                                dia,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              iconColor: Colors.deepPurple,
                              collapsedIconColor: Colors.deepPurple,
                              children: slots.asMap().entries.map((e) {
                                final idx = _slots.indexOf(e.value);
                                return ListTile(
                                  leading: Icon(
                                    Icons.access_time,
                                    color: Colors.deepPurple,
                                  ),
                                  title: Text(
                                    '${e.value.horaInicio} - ${e.value.horaFin}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(Icons.delete_outline),
                                    onPressed: () => _eliminarSlot(idx),
                                    color: Colors.red,
                                    tooltip: 'Eliminar',
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: Icon(Icons.save),
                onPressed: _slots.isEmpty ? null : _guardarDisponibilidad,
                label: Text('Guardar Disponibilidad'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 45),
                  disabledBackgroundColor: Colors.grey[300],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
