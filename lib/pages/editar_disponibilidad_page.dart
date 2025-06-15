import 'package:flutter/material.dart';
import '../models/disponibilidad.dart';
import '../service/disponibilidad_service.dart';

class EditarDisponibilidadPage extends StatefulWidget {
  final String tutorId;
  const EditarDisponibilidadPage({required this.tutorId, super.key});

  @override
  State<EditarDisponibilidadPage> createState() => _EditarDisponibilidadPageState();
}

class _EditarDisponibilidadPageState extends State<EditarDisponibilidadPage> {
  final _formKey = GlobalKey<FormState>();
  final List<Slot> _slots = [];
  List<String> _diasSeleccionados = [];
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFin;

  final _dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

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
        _slots.clear();
        _slots.addAll(disponibilidad.slots);
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
    if (_diasSeleccionados.isNotEmpty && _horaInicio != null && _horaFin != null) {
      bool algunoDuplicado = false;
      for (final dia in _diasSeleccionados) {
        final nuevoSlot = Slot(
          dia: dia,
          horaInicio: _horaInicio!.format(context),
          horaFin: _horaFin!.format(context),
        );
        bool existe = _slots.any((s) => s.dia == nuevoSlot.dia && s.horaInicio == nuevoSlot.horaInicio && s.horaFin == nuevoSlot.horaFin);
        if (!existe) {
          setState(() {
            _slots.add(nuevoSlot);
          });
        } else {
          algunoDuplicado = true;
        }
      }
      if (algunoDuplicado) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Algunos horarios ya estaban agregados.')),
        );
      }
      setState(() {
        _diasSeleccionados = [];
        _horaInicio = null;
        _horaFin = null;
      });
    }
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Disponibilidad guardada')),
    );
  }

  Map<String, List<Slot>> _agruparPorDia() {
    final Map<String, List<Slot>> agrupado = {};
    for (final slot in _slots) {
      agrupado.putIfAbsent(slot.dia, () => []).add(slot);
    }
    return agrupado;
  }

  @override
  Widget build(BuildContext context) {
    final horariosPorDia = _agruparPorDia();
    return Scaffold(
      appBar: AppBar(title: Text('Editar Disponibilidad')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Selecciona los días:', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Wrap(
                spacing: 8,
                children: _dias.map((dia) => FilterChip(
                  label: Text(dia),
                  selected: _diasSeleccionados.contains(dia),
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
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _seleccionarHoraInicio,
                      child: Text(_horaInicio == null ? 'Hora de inicio' : _horaInicio!.format(context)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _seleccionarHoraFin,
                      child: Text(_horaFin == null ? 'Hora de fin' : _horaFin!.format(context)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _agregarSlots,
                child: Text('Agregar horario'),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _slots.isEmpty
                    ? Center(child: Text('No has agregado horarios de disponibilidad.'))
                    : ListView(
                        children: horariosPorDia.entries.map((entry) {
                          final dia = entry.key;
                          final slots = entry.value;
                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 4),
                            child: ExpansionTile(
                              title: Text(dia, style: TextStyle(fontWeight: FontWeight.bold)),
                              children: slots.asMap().entries.map((e) {
                                final idx = _slots.indexOf(e.value);
                                return ListTile(
                                  leading: Icon(Icons.access_time, color: Colors.deepPurple),
                                  title: Text('${e.value.horaInicio} - ${e.value.horaFin}'),
                                  trailing: IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _eliminarSlot(idx),
                                    tooltip: 'Eliminar',
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        }).toList(),
                      ),
              ),
              ElevatedButton(
                onPressed: _slots.isEmpty ? null : _guardarDisponibilidad,
                child: Text('Guardar Disponibilidad'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 