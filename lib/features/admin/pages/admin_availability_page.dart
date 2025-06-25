import 'package:flutter/material.dart';
import 'package:tutoring_app/core/models/disponibilidad.dart';
import 'package:tutoring_app/features/disponibilidad/services/disponibilidad_service.dart';

class AdminAvailabilityPage extends StatefulWidget {
  final String tutorId;
  final String tutorName;
  
  const AdminAvailabilityPage({
    required this.tutorId,
    required this.tutorName,
    super.key,
  });

  @override
  State<AdminAvailabilityPage> createState() => _AdminAvailabilityPageState();
}

class _AdminAvailabilityPageState extends State<AdminAvailabilityPage> {
  final _formKey = GlobalKey<FormState>();
  List<Slot> _slots = [];
  List<String> _diasSeleccionados = [];
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFin;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  final _dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
  final DisponibilidadService _disponibilidadService = DisponibilidadService();

  @override
  void initState() {
    super.initState();
    _cargarDisponibilidad();
  }

  Future<void> _cargarDisponibilidad() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final disponibilidad = await _disponibilidadService.obtenerDisponibilidad(widget.tutorId);
      
      if (mounted) {
        setState(() {
          _slots = disponibilidad?.slots ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error al cargar la disponibilidad: $e';
        });
      }
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
        const SnackBar(
          content: Text('Por favor selecciona días y horarios'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validar que la hora de fin sea después de la hora de inicio
    if (_horaInicio!.hour > _horaFin!.hour || 
        (_horaInicio!.hour == _horaFin!.hour && _horaInicio!.minute >= _horaFin!.minute)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La hora de fin debe ser posterior a la hora de inicio'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    bool algunoAgregado = false;
    bool algunoSolapado = false;
    List<Slot> nuevosSlots = List.from(_slots);

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
          horaFinExistente
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
            return _dias.indexOf(a.dia).compareTo(_dias.indexOf(b.dia));
          }
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
          content: Text(algunoAgregado 
            ? 'Algunos horarios se solapaban y no fueron agregados'
            : 'Los horarios se solapan con slots existentes'
          ),
          backgroundColor: Colors.orange,
        ),
      );
    } else if (algunoAgregado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
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

  TimeOfDay _parseHora(String hora) {
    final partes = hora.split(':');
    return TimeOfDay(
      hour: int.parse(partes[0]), 
      minute: int.parse(partes[1])
    );
  }

  bool _haySolapamiento(
    TimeOfDay inicio1, 
    TimeOfDay fin1, 
    TimeOfDay inicio2, 
    TimeOfDay fin2
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

  void _toggleSlotStatus(int index) {
    setState(() {
      _slots[index] = Slot(
        dia: _slots[index].dia,
        horaInicio: _slots[index].horaInicio,
        horaFin: _slots[index].horaFin,
        activo: !_slots[index].activo,
      );
    });
  }

  Future<void> _guardarDisponibilidad() async {
    setState(() => _isSaving = true);

    try {
      await _disponibilidadService.guardarDisponibilidad(
        Disponibilidad(tutorId: widget.tutorId, slots: _slots),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Disponibilidad guardada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar la disponibilidad: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Map<String, List<Slot>> _agruparPorDia() {
    final Map<String, List<Slot>> agrupado = {};
    
    for (final slot in _slots) {
      if (!agrupado.containsKey(slot.dia)) {
        agrupado[slot.dia] = [];
      }
      agrupado[slot.dia]!.add(slot);
    }
    
    agrupado.forEach((dia, slots) {
      slots.sort((a, b) {
        final horaInicioA = _parseHora(a.horaInicio);
        final horaInicioB = _parseHora(b.horaInicio);
        final minutosA = horaInicioA.hour * 60 + horaInicioA.minute;
        final minutosB = horaInicioB.hour * 60 + horaInicioB.minute;
        return minutosA.compareTo(minutosB);
      });
    });
    
    final ordenado = Map.fromEntries(
      _dias.where((dia) => agrupado.containsKey(dia))
          .map((dia) => MapEntry(dia, agrupado[dia]!))
    );
    
    return ordenado;
  }

  @override
  Widget build(BuildContext context) {
    final horariosPorDia = _agruparPorDia();
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestionar Disponibilidad - ${widget.tutorName}'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading && !_isSaving)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _slots.isEmpty ? null : _guardarDisponibilidad,
              tooltip: 'Guardar Cambios',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _cargarDisponibilidad,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Información del tutor
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.person, color: Colors.blue[700]),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Tutor: ${widget.tutorName}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'ID: ${widget.tutorId}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Sección para agregar nuevos horarios
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Agregar Nuevos Horarios',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                // Selección de días
                                const Text('Selecciona los días:', style: TextStyle(fontWeight: FontWeight.w500)),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _dias.map((dia) => FilterChip(
                                    label: Text(dia),
                                    selected: _diasSeleccionados.contains(dia),
                                    selectedColor: Colors.deepPurple.withOpacity(0.2),
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
                                  )).toList(),
                                ),
                                const SizedBox(height: 16),
                                
                                // Selección de horarios
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        icon: const Icon(Icons.access_time),
                                        onPressed: _seleccionarHoraInicio,
                                        label: Text(_horaInicio == null ? 'Hora de inicio' : _horaInicio!.format(context)),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.deepPurple,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        icon: const Icon(Icons.access_time),
                                        onPressed: _seleccionarHoraFin,
                                        label: Text(_horaFin == null ? 'Hora de fin' : _horaFin!.format(context)),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.deepPurple,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.add),
                                  onPressed: _agregarSlots,
                                  label: const Text('Agregar horario'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurple,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(double.infinity, 45),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Lista de horarios existentes
                        Expanded(
                          child: _slots.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.calendar_today, size: 48, color: Colors.grey[400]),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No hay horarios configurados',
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
                                      margin: const EdgeInsets.only(bottom: 16),
                                      child: ExpansionTile(
                                        title: Row(
                                          children: [
                                            Icon(Icons.calendar_today, color: Colors.deepPurple),
                                            const SizedBox(width: 8),
                                            Text(
                                              dia,
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                '${slots.length} horario${slots.length != 1 ? 's' : ''}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        children: slots.asMap().entries.map((slotEntry) {
                                          final index = slotEntry.key;
                                          final slot = slotEntry.value;
                                          final globalIndex = _slots.indexOf(slot);
                                          
                                          return ListTile(
                                            leading: Icon(
                                              slot.activo ? Icons.check_circle : Icons.cancel,
                                              color: slot.activo ? Colors.green : Colors.red,
                                            ),
                                            title: Text('${slot.horaInicio} - ${slot.horaFin}'),
                                            subtitle: Text(
                                              slot.activo ? 'Activo' : 'Inactivo',
                                              style: TextStyle(
                                                color: slot.activo ? Colors.green[700] : Colors.red[700],
                                              ),
                                            ),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: Icon(
                                                    slot.activo ? Icons.block : Icons.check_circle_outline,
                                                    color: slot.activo ? Colors.orange : Colors.green,
                                                  ),
                                                  onPressed: () => _toggleSlotStatus(globalIndex),
                                                  tooltip: slot.activo ? 'Desactivar' : 'Activar',
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete, color: Colors.red),
                                                  onPressed: () => _eliminarSlot(globalIndex),
                                                  tooltip: 'Eliminar',
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ),
                        
                        // Botón de guardar
                        if (!_isLoading)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.only(top: 16),
                            child: ElevatedButton.icon(
                              icon: _isSaving 
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.save),
                              onPressed: _isSaving || _slots.isEmpty ? null : _guardarDisponibilidad,
                              label: Text(_isSaving ? 'Guardando...' : 'Guardar Disponibilidad'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 45),
                                disabledBackgroundColor: Colors.grey[300],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }
} 