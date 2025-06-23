import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notificacion_service.dart';

class NotificacionesConfigPage extends StatefulWidget {
  const NotificacionesConfigPage({Key? key}) : super(key: key);

  @override
  State<NotificacionesConfigPage> createState() => _NotificacionesConfigPageState();
}

class _NotificacionesConfigPageState extends State<NotificacionesConfigPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificacionService _notificacionService = NotificacionService();
  
  bool _solicitudesTutoria = true;
  bool _respuestasSolicitud = true;
  bool _recordatoriosSesion = true;
  bool _cancelacionesSesion = true;
  bool _asignacionesTutor = true;
  bool _notificacionesAdmin = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarConfiguracion();
  }

  Future<void> _cargarConfiguracion() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final doc = await _firestore
            .collection('usuarios')
            .doc(user.uid)
            .collection('configuracion')
            .doc('notificaciones')
            .get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            _solicitudesTutoria = data['solicitudesTutoria'] ?? true;
            _respuestasSolicitud = data['respuestasSolicitud'] ?? true;
            _recordatoriosSesion = data['recordatoriosSesion'] ?? true;
            _cancelacionesSesion = data['cancelacionesSesion'] ?? true;
            _asignacionesTutor = data['asignacionesTutor'] ?? true;
            _notificacionesAdmin = data['notificacionesAdmin'] ?? true;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Error cargando configuración: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _guardarConfiguracion() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore
            .collection('usuarios')
            .doc(user.uid)
            .collection('configuracion')
            .doc('notificaciones')
            .set({
          'solicitudesTutoria': _solicitudesTutoria,
          'respuestasSolicitud': _respuestasSolicitud,
          'recordatoriosSesion': _recordatoriosSesion,
          'cancelacionesSesion': _cancelacionesSesion,
          'asignacionesTutor': _asignacionesTutor,
          'notificacionesAdmin': _notificacionesAdmin,
          'ultimaActualizacion': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuración guardada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar configuración: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _probarNotificacion() async {
    try {
      await _notificacionService.enviarNotificacionRecordatorioSesion(
        usuarioId: _auth.currentUser?.uid ?? '',
        materia: 'Prueba',
        fecha: DateTime.now().add(const Duration(minutes: 30)),
        nombreTutor: 'Sistema',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notificación de prueba enviada'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar notificación de prueba: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Configuración de Notificaciones',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: _guardarConfiguracion,
            tooltip: 'Guardar configuración',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información general
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue[600],
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Configuración de Notificaciones',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Personaliza qué tipos de notificaciones quieres recibir. Los cambios se aplicarán inmediatamente.',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tipos de notificaciones
                  Text(
                    'Tipos de Notificaciones',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildNotificationSwitch(
                    title: 'Solicitudes de Tutoría',
                    subtitle: 'Recibe notificaciones cuando un estudiante solicite una tutoría',
                    icon: Icons.school,
                    iconColor: Colors.blue,
                    value: _solicitudesTutoria,
                    onChanged: (value) => setState(() => _solicitudesTutoria = value),
                  ),

                  _buildNotificationSwitch(
                    title: 'Respuestas de Solicitudes',
                    subtitle: 'Recibe notificaciones cuando se acepte o rechace tu solicitud',
                    icon: Icons.check_circle,
                    iconColor: Colors.green,
                    value: _respuestasSolicitud,
                    onChanged: (value) => setState(() => _respuestasSolicitud = value),
                  ),

                  _buildNotificationSwitch(
                    title: 'Recordatorios de Sesión',
                    subtitle: 'Recibe recordatorios 30 minutos antes de tus sesiones',
                    icon: Icons.alarm,
                    iconColor: Colors.orange,
                    value: _recordatoriosSesion,
                    onChanged: (value) => setState(() => _recordatoriosSesion = value),
                  ),

                  _buildNotificationSwitch(
                    title: 'Cancelaciones de Sesión',
                    subtitle: 'Recibe notificaciones cuando se cancele una sesión',
                    icon: Icons.cancel,
                    iconColor: Colors.red,
                    value: _cancelacionesSesion,
                    onChanged: (value) => setState(() => _cancelacionesSesion = value),
                  ),

                  _buildNotificationSwitch(
                    title: 'Asignaciones de Tutor',
                    subtitle: 'Recibe notificaciones cuando se te asigne un tutor',
                    icon: Icons.person_add,
                    iconColor: Colors.purple,
                    value: _asignacionesTutor,
                    onChanged: (value) => setState(() => _asignacionesTutor = value),
                  ),

                  _buildNotificationSwitch(
                    title: 'Notificaciones Administrativas',
                    subtitle: 'Recibe notificaciones importantes del sistema',
                    icon: Icons.admin_panel_settings,
                    iconColor: Colors.indigo,
                    value: _notificacionesAdmin,
                    onChanged: (value) => setState(() => _notificacionesAdmin = value),
                  ),

                  const SizedBox(height: 30),

                  // Botón de prueba
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _probarNotificacion,
                      icon: const Icon(Icons.notifications),
                      label: Text(
                        'Probar Notificación',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Información adicional
                  Card(
                    elevation: 1,
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                color: Colors.blue[600],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Consejos',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• Las notificaciones push funcionan mejor en dispositivos físicos\n'
                            '• Asegúrate de tener una conexión estable a internet\n'
                            '• Los recordatorios se envían automáticamente 30 minutos antes de cada sesión',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildNotificationSwitch({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: SwitchListTile(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(left: 44),
          child: Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: Colors.blue,
      ),
    );
  }
} 