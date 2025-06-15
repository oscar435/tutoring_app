import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/disponibilidad.dart';
import '../models/solicitud_tutoria.dart';
import '../service/disponibilidad_service.dart';
import '../service/solicitud_tutoria_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AgendarTutoriaPage extends StatefulWidget {
  final String tutorId;
  final String estudianteId;
  const AgendarTutoriaPage({required this.tutorId, required this.estudianteId, super.key});

  @override
  State<AgendarTutoriaPage> createState() => _AgendarTutoriaPageState();
}

class _AgendarTutoriaPageState extends State<AgendarTutoriaPage> {
  Disponibilidad? _disponibilidad;
  Slot? _slotSeleccionado;
  bool _cargando = true;
  final _mensajeController = TextEditingController();
  DateTime? _fechaSeleccionada;
  List<String> _cursosTutor = [];
  String? _cursoSeleccionado;

  @override
  void initState() {
    super.initState();
    _cargarDisponibilidad();
    _cargarCursosTutor();
  }

  Future<void> _cargarDisponibilidad() async {
    final servicio = DisponibilidadService();
    final disponibilidad = await servicio.obtenerDisponibilidad(widget.tutorId);
    setState(() {
      _disponibilidad = disponibilidad;
      _cargando = false;
    });
  }

  Future<void> _cargarCursosTutor() async {
    final doc = await FirebaseFirestore.instance.collection('tutores').doc(widget.tutorId).get();
    final data = doc.data() as Map<String, dynamic>?;
    setState(() {
      _cursosTutor = (data?['cursos'] as List?)?.cast<String>() ?? [];
      if (_cursosTutor.isNotEmpty) {
        _cursoSeleccionado = _cursosTutor.first;
      }
    });
  }

  Future<void> _agendarTutoria() async {
    if (_slotSeleccionado == null || _fechaSeleccionada == null || _cursoSeleccionado == null) return;
    final servicio = SolicitudTutoriaService();
    final solicitud = SolicitudTutoria(
      id: const Uuid().v4(),
      tutorId: widget.tutorId,
      estudianteId: widget.estudianteId,
      fechaHora: DateTime.now(),
      estado: 'pendiente',
      curso: _cursoSeleccionado,
      mensaje: _mensajeController.text,
      dia: _slotSeleccionado!.dia,
      horaInicio: _slotSeleccionado!.horaInicio,
      horaFin: _slotSeleccionado!.horaFin,
      fechaSesion: _fechaSeleccionada,
    );
    await servicio.crearSolicitud(solicitud);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Solicitud enviada al tutor')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Agendar Tutoría')),
      body: _cargando
          ? Center(child: CircularProgressIndicator())
          : _disponibilidad == null
              ? Center(child: Text('El tutor no tiene disponibilidad registrada.'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_cursosTutor.isNotEmpty) ...[
                        Text('Selecciona el curso:', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 10),
                        DropdownButton<String>(
                          value: _cursoSeleccionado,
                          isExpanded: true,
                          items: _cursosTutor.map((curso) => DropdownMenuItem(
                            value: curso,
                            child: Text(curso),
                          )).toList(),
                          onChanged: (value) => setState(() => _cursoSeleccionado = value),
                        ),
                        SizedBox(height: 20),
                      ],
                      Text('Selecciona un horario disponible:', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      ..._disponibilidad!.slots.map((slot) => RadioListTile<Slot>(
                            title: Text('${slot.dia}: ${slot.horaInicio} - ${slot.horaFin}'),
                            value: slot,
                            groupValue: _slotSeleccionado,
                            onChanged: (s) => setState(() => _slotSeleccionado = s),
                          )),
                      SizedBox(height: 20),
                      Text('Selecciona la fecha:', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: now,
                            firstDate: now,
                            lastDate: now.add(Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() {
                              _fechaSeleccionada = picked;
                            });
                          }
                        },
                        child: Text(_fechaSeleccionada == null
                            ? 'Seleccionar fecha'
                            : '${_fechaSeleccionada!.day}/${_fechaSeleccionada!.month}/${_fechaSeleccionada!.year}'),
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: _mensajeController,
                        decoration: InputDecoration(labelText: 'Mensaje para el tutor (opcional)'),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _slotSeleccionado == null || _fechaSeleccionada == null || _cursoSeleccionado == null ? null : _agendarTutoria,
                        child: Text('Agendar Tutoría'),
                      ),
                    ],
                  ),
                ),
    );
  }
} 