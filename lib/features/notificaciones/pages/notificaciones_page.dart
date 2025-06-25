import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/notificacion_service.dart';
import '../../../core/models/notificacion.dart';

class NotificacionesPage extends StatefulWidget {
  const NotificacionesPage({super.key});

  @override
  State<NotificacionesPage> createState() => _NotificacionesPageState();
}

class _NotificacionesPageState extends State<NotificacionesPage> {
  final NotificacionService _notificacionService = NotificacionService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await _notificacionService.initialize();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Notificaciones',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _initializeNotifications();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildNotificationsList(),
    );
  }

  Widget _buildNotificationsList() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Center(child: Text('Usuario no autenticado'));
    }

    return StreamBuilder<List<Notificacion>>(
      stream: _notificacionService.getNotificacionesStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar notificaciones',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final notificaciones = snapshot.data!;

        if (notificaciones.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 80,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'No tienes notificaciones',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Las notificaciones aparecerán aquí',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notificaciones.length,
          itemBuilder: (context, index) {
            final notificacion = notificaciones[index];
            return _buildNotificationCard(notificacion);
          },
        );
      },
    );
  }

  Widget _buildNotificationCard(Notificacion notificacion) {
    return Dismissible(
      key: Key(notificacion.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade700,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (direction) {
        // Eliminar notificación - funcionalidad deshabilitada temporalmente
        // _notificacionService.eliminarNotificacion(notificacion.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Funcionalidad de eliminación en desarrollo'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: notificacion.leida ? Colors.white : const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.05 * 255).toInt()),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              if (!notificacion.leida) {
                _notificacionService.marcarComoLeida(notificacion.id);
              }
              _handleNotificationTap(notificacion);
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNotificationIcon(notificacion.tipo),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notificacion.titulo,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: notificacion.leida
                                      ? FontWeight.w500
                                      : FontWeight.w600,
                                  color: notificacion.leida
                                      ? Colors.grey[700]
                                      : Colors.black87,
                                ),
                              ),
                            ),
                            if (!notificacion.leida)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notificacion.mensaje,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              notificacion.tiempoTranscurrido,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getTypeColor(
                                  notificacion.tipo,
                                ).withAlpha((0.1 * 255).toInt()),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                notificacion.tipoString,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: _getTypeColor(notificacion.tipo),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(TipoNotificacion tipo) {
    IconData iconData;
    Color iconColor;

    switch (tipo) {
      case TipoNotificacion.solicitudTutoria:
        iconData = Icons.school;
        iconColor = Colors.blue;
        break;
      case TipoNotificacion.respuestaSolicitud:
        iconData = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case TipoNotificacion.recordatorioSesion:
        iconData = Icons.alarm;
        iconColor = Colors.orange;
        break;
      case TipoNotificacion.cancelacionSesion:
        iconData = Icons.cancel;
        iconColor = Colors.red;
        break;
      case TipoNotificacion.asignacionTutor:
        iconData = Icons.person_add;
        iconColor = Colors.purple;
        break;
      case TipoNotificacion.notificacionAdmin:
        iconData = Icons.admin_panel_settings;
        iconColor = Colors.indigo;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.grey;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconColor.withAlpha((0.1 * 255).toInt()),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(iconData, color: iconColor, size: 20),
    );
  }

  Color _getTypeColor(TipoNotificacion tipo) {
    switch (tipo) {
      case TipoNotificacion.solicitudTutoria:
        return Colors.blue;
      case TipoNotificacion.respuestaSolicitud:
        return Colors.green;
      case TipoNotificacion.recordatorioSesion:
        return Colors.orange;
      case TipoNotificacion.cancelacionSesion:
        return Colors.red;
      case TipoNotificacion.asignacionTutor:
        return Colors.purple;
      case TipoNotificacion.notificacionAdmin:
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  void _handleNotificationTap(Notificacion notificacion) {
    // Aquí puedes implementar la navegación basada en el tipo de notificación
    switch (notificacion.tipo) {
      case TipoNotificacion.solicitudTutoria:
        // Navegar a solicitudes de tutoría
        Navigator.pushNamed(context, '/solicitudes-tutor');
        break;
      case TipoNotificacion.respuestaSolicitud:
        // Navegar a mis tutorías
        Navigator.pushNamed(context, '/mis-tutorias');
        break;
      case TipoNotificacion.recordatorioSesion:
        // Navegar a próximas tutorías
        Navigator.pushNamed(context, '/proximas-tutorias');
        break;
      case TipoNotificacion.cancelacionSesion:
        // Navegar a todas las tutorías
        Navigator.pushNamed(context, '/todas-tutorias');
        break;
      case TipoNotificacion.asignacionTutor:
        // Navegar a perfil
        Navigator.pushNamed(context, '/perfil');
        break;
      case TipoNotificacion.notificacionAdmin:
        // Navegar a dashboard
        Navigator.pushNamed(context, '/dashboard');
        break;
      default:
        // No hacer nada
        break;
    }
  }
}
