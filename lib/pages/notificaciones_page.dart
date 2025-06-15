import 'package:flutter/material.dart';
import '../models/notificacion.dart';
import '../service/notificacion_service.dart';
import 'package:intl/intl.dart';

class NotificacionesPage extends StatefulWidget {
  final String usuarioId;
  const NotificacionesPage({required this.usuarioId, super.key});

  @override
  State<NotificacionesPage> createState() => _NotificacionesPageState();
}

class _NotificacionesPageState extends State<NotificacionesPage> {
  late Future<List<Notificacion>> _notificacionesFuture;

  @override
  void initState() {
    super.initState();
    _notificacionesFuture = NotificacionService().obtenerNotificacionesPorUsuario(widget.usuarioId);
  }

  Future<void> _marcarComoLeida(String notificacionId) async {
    await NotificacionService().marcarComoLeida(notificacionId);
    setState(() {
      _notificacionesFuture = NotificacionService().obtenerNotificacionesPorUsuario(widget.usuarioId);
    });
  }

  Future<void> _borrarNotificacion(String notificacionId) async {
    await NotificacionService().borrarNotificacion(notificacionId);
    setState(() {
      _notificacionesFuture = NotificacionService().obtenerNotificacionesPorUsuario(widget.usuarioId);
    });
  }

  String _formatearFecha(DateTime fecha) {
    final ahora = DateTime.now();
    if (fecha.year == ahora.year && fecha.month == ahora.month && fecha.day == ahora.day) {
      return 'Hoy, ' + DateFormat('HH:mm').format(fecha);
    }
    return DateFormat('dd/MM/yyyy HH:mm').format(fecha);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notificaciones')),
      body: FutureBuilder<List<Notificacion>>(
        future: _notificacionesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No tienes notificaciones.'));
          }
          // Copia local de la lista para manipulación visual
          List<Notificacion> notificaciones = List.from(snapshot.data!);
          return StatefulBuilder(
            builder: (context, setStateLocal) {
              return ListView.builder(
                itemCount: notificaciones.length,
                itemBuilder: (context, index) {
                  final noti = notificaciones[index];
                  return Dismissible(
                    key: Key(noti.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) {
                      setStateLocal(() {
                        notificaciones.removeAt(index);
                      });
                    },
                    child: Card(
                      color: noti.leida ? Colors.white : Colors.blue[50],
                      child: ListTile(
                        leading: Icon(
                          noti.tipo == 'solicitud' ? Icons.mail : Icons.check_circle,
                          color: noti.leida ? Colors.grey : Colors.blue,
                        ),
                        title: Text(noti.mensaje,
                            style: TextStyle(
                              fontWeight: noti.leida ? FontWeight.normal : FontWeight.bold,
                            )),
                        subtitle: Text(_formatearFecha(noti.fecha)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!noti.leida)
                              IconButton(
                                icon: Icon(Icons.check, color: Colors.green),
                                onPressed: () => _marcarComoLeida(noti.id),
                                tooltip: 'Marcar como leída',
                              ),
                            if (noti.leida)
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setStateLocal(() {
                                    notificaciones.removeAt(index);
                                  });
                                },
                                tooltip: 'Borrar notificación',
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
} 