import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:tutoring_app/core/models/registro_post_sesion.dart';
import 'package:tutoring_app/core/models/sesion_tutoria.dart';
import 'package:tutoring_app/features/tutorias/services/registro_post_sesion_service.dart';
import 'package:tutoring_app/core/utils/validators.dart';

class RegistroPostSesionPage extends StatefulWidget {
  final String sesionId;
  final SesionTutoria sesion;

  const RegistroPostSesionPage({
    required this.sesionId,
    required this.sesion,
    super.key,
  });

  @override
  State<RegistroPostSesionPage> createState() => _RegistroPostSesionPageState();
}

class _RegistroPostSesionPageState extends State<RegistroPostSesionPage> {
  final _formKey = GlobalKey<FormState>();
  final _registroService = RegistroPostSesionService();

  // Controllers
  final _temasController = TextEditingController();
  final _recomendacionesController = TextEditingController();
  final _observacionesController = TextEditingController();
  final _comentariosController = TextEditingController();
  final _duracionController = TextEditingController();
  final _recursosController = TextEditingController();

  // Variables de estado
  List<String> _temasTratados = [];
  List<String> _recursosUtilizados = [];
  bool _asistioEstudiante = true;
  String _estadoSesion = 'completada';
  int _duracionRealMinutos = 0;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  Map<String, dynamic>? _estudianteData;

  @override
  void initState() {
    super.initState();
    _cargarDatosEstudiante();
    _cargarRegistroExistente();
  }

  @override
  void dispose() {
    _temasController.dispose();
    _recomendacionesController.dispose();
    _observacionesController.dispose();
    _comentariosController.dispose();
    _duracionController.dispose();
    _recursosController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosEstudiante() async {
    try {
      final estudianteDoc = await FirebaseFirestore.instance
          .collection('estudiantes')
          .doc(widget.sesion.estudianteId)
          .get();

      if (mounted) {
        setState(() {
          _estudianteData = estudianteDoc.data();
        });
      }
    } catch (e) {
      print('Error al cargar datos del estudiante: $e');
    }
  }

  Future<void> _cargarRegistroExistente() async {
    try {
      setState(() => _isLoading = true);

      final registroExistente = await _registroService.obtenerRegistroPorSesion(
        widget.sesionId,
      );

      if (mounted && registroExistente != null) {
        setState(() {
          _temasTratados = registroExistente.temasTratados;
          _asistioEstudiante = registroExistente.asistioEstudiante;
          _recomendacionesController.text = registroExistente.recomendaciones;
          _observacionesController.text = registroExistente.observaciones;
          _comentariosController.text =
              registroExistente.comentariosAdicionales;
          _errorMessage = 'Esta sesión ya tiene un registro. Puedes editarlo.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al cargar registro existente: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _agregarTema() {
    if (_temasController.text.trim().isNotEmpty) {
      setState(() {
        _temasTratados.add(_temasController.text.trim());
        _temasController.clear();
      });
    }
  }

  void _eliminarTema(int index) {
    setState(() {
      _temasTratados.removeAt(index);
    });
  }

  void _agregarRecurso() {
    if (_recursosController.text.trim().isNotEmpty) {
      setState(() {
        _recursosUtilizados.add(_recursosController.text.trim());
        _recursosController.clear();
      });
    }
  }

  void _eliminarRecurso(int index) {
    setState(() {
      _recursosUtilizados.removeAt(index);
    });
  }

  Future<void> _guardarRegistro() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final registro = RegistroPostSesion(
        id: '',
        sesionId: widget.sesionId,
        tutorId: widget.sesion.tutorId,
        estudianteId: widget.sesion.estudianteId,
        fechaRegistro: DateTime.now(),
        temasTratados: _temasTratados,
        recomendaciones: _recomendacionesController.text.trim(),
        observaciones: _observacionesController.text.trim(),
        comentariosAdicionales: _comentariosController.text.trim(),
        asistioEstudiante: _asistioEstudiante,
      );

      await _registroService.crearRegistro(registro);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registro guardado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar el registro: $e'),
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

  @override
  Widget build(BuildContext context) {
    final tieneRegistroExistente =
        _errorMessage == 'Esta sesión ya tiene un registro. Puedes editarlo.';
    if (tieneRegistroExistente) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Registro Post-Sesión'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
              SizedBox(height: 16),
              Text(
                'Esta sesión ya tiene un registro post-sesión. No es posible editarlo.',
                style: TextStyle(color: Colors.orange, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro Post-Sesión'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading && !_isSaving)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _guardarRegistro,
              tooltip: 'Guardar Registro',
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
                  Icon(Icons.warning, size: 64, color: Colors.orange[300]),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.orange[700]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSesionInfo(),
                    const SizedBox(height: 24),
                    _buildAsistencia(),
                    if (_asistioEstudiante) ...[
                      const SizedBox(height: 24),
                      _buildTemasTratados(),
                      const SizedBox(height: 24),
                      _buildRecomendaciones(),
                      const SizedBox(height: 24),
                      _buildObservaciones(),
                      const SizedBox(height: 24),
                      _buildComentariosAdicionales(),
                    ],
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save),
                        onPressed: _isSaving ? null : _guardarRegistro,
                        label: Text(
                          _isSaving ? 'Guardando...' : 'Guardar Registro',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSesionInfo() {
    final nombreEstudiante = _estudianteData != null
        ? '${_estudianteData!['nombre'] ?? ''} ${_estudianteData!['apellidos'] ?? ''}'
              .trim()
        : 'Estudiante';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text(
                  'Información de la Sesión',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Estudiante', nombreEstudiante),
            _buildInfoRow('Curso', widget.sesion.curso ?? 'No especificado'),
            _buildInfoRow(
              'Fecha',
              DateFormat(
                'dd/MM/yyyy',
              ).format(widget.sesion.fechaSesion ?? widget.sesion.fechaReserva),
            ),
            _buildInfoRow(
              'Hora',
              '${widget.sesion.horaInicio} - ${widget.sesion.horaFin}',
            ),
            _buildInfoRow('Estado', widget.sesion.estado.toUpperCase()),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildTemasTratados() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.topic, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Temas Tratados *',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _temasController,
                    decoration: const InputDecoration(
                      hintText: 'Agregar tema tratado',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _agregarTema,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            if (_temasTratados.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _temasTratados.asMap().entries.map((entry) {
                  final index = entry.key;
                  final tema = entry.value;
                  return Chip(
                    label: Text(tema),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => _eliminarTema(index),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecomendaciones() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Recomendaciones *',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _recomendacionesController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Escribe las recomendaciones para el estudiante...',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Las recomendaciones son obligatorias';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildObservaciones() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notes, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Observaciones *',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _observacionesController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Escribe las observaciones de la sesión...',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Las observaciones son obligatorias';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAsistencia() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Asistencia del Estudiante',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Asistió'),
                    value: true,
                    groupValue: _asistioEstudiante,
                    onChanged: (value) {
                      setState(() {
                        _asistioEstudiante = value!;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('No asistió'),
                    value: false,
                    groupValue: _asistioEstudiante,
                    onChanged: (value) {
                      setState(() {
                        _asistioEstudiante = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComentariosAdicionales() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.comment, color: Colors.indigo),
                const SizedBox(width: 8),
                Text(
                  'Comentarios Adicionales',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _comentariosController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Comentarios adicionales (opcional)...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
