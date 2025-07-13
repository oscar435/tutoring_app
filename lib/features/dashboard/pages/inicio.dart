import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tutoring_app/core/storage/preferencias_usuario.dart';
import 'package:tutoring_app/features/calendario/pages/CalendarioPage.dart';
import 'package:tutoring_app/features/perfil/pages/student_profile_page.dart';
import 'package:tutoring_app/features/materiales/pages/material_educativo_page.dart';
import 'package:tutoring_app/features/notificaciones/pages/notificaciones_page.dart';
import 'package:tutoring_app/features/tutorias/pages/TodasTutoriasPage.dart';
import 'package:tutoring_app/features/tutorias/pages/agendar_tutoria_page.dart';
import 'package:tutoring_app/core/models/solicitud_tutoria.dart';
import 'package:intl/intl.dart';
import 'package:tutoring_app/routes/app_routes.dart';
import 'package:tutoring_app/features/notificaciones/widgets/notification_badge.dart';
import 'package:tutoring_app/features/tutorias/services/sesion_tutoria_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:tutoring_app/features/tutorias/pages/historial_sesiones_page.dart';
import 'package:tutoring_app/core/models/sesion_tutoria.dart';
import 'package:tutoring_app/features/tutorias/widgets/encuesta_satisfaccion_modal.dart';
import 'package:tutoring_app/features/tutorias/services/encuesta_satisfaccion_service.dart';
import 'package:tutoring_app/core/models/encuesta_satisfaccion.dart';
import 'package:provider/provider.dart';
import '../../../main.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:tutoring_app/features/perfil/pages/mis_reportes_page.dart';

class HomePage2 extends StatelessWidget {
  static const routeName = '/home2';
  const HomePage2({super.key});

  Future<DocumentSnapshot?> _getAssignedTutor(String studentId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('tutores')
        .where('estudiantes_asignados', arrayContains: studentId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Error: No hay usuario')));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        // Verificar si el usuario está activo
        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final isActive = userData['isActive'] ?? true;

          if (!isActive) {
            // Usuario desactivado, cerrar sesión automáticamente
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await FirebaseAuth.instance.signOut();
              final prefs = PreferenciasUsuario();
              await prefs.clearUserSession();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.roleSelector,
                  (route) => false,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Tu cuenta ha sido desactivada. Contacta al administrador.',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            });
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.block, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      'Cuenta Desactivada',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tu cuenta ha sido desactivada por un administrador.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
        }

        return Scaffold(
          backgroundColor: Colors.white,
          drawer: _buildCustomDrawer(context, user.uid),
          body: SafeArea(
            child: Builder(
              builder: (context) => SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(context),
                    const SizedBox(height: 20),
                    _buildAssignedTutorCard(user.uid),
                    _buildSectionTitle(
                      'Tutorías agendadas',
                      trailing: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TodasTutoriasPage(),
                            ),
                          );
                        },
                        child: const Text('Ver todas'),
                      ),
                    ),
                    _buildSolicitudesEstudiante(user.uid),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Nuestros Servicios'),
                    Row(
                      children: [
                        Expanded(
                          child: _buildServiceCard(
                            context,
                            'TUTORÍAS',
                            Icons.school,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildServiceCard(
                            context,
                            'AYUDA PSICOPEDAGÓGICA',
                            Icons.psychology,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Noticias recientes'),
                    _buildNewsList(),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Eventos Unfv'),
                    _buildEventosList(),
                    const SizedBox(height: 20),
                    _buildSectionTitle(
                      'Herramientas para tu Éxito',
                      trailing: TextButton(
                        onPressed: () {
                          // Navegación a materiales educativos
                          Navigator.pushNamed(context, AppRoutes.materials);
                        },
                        child: const Text('Ver todos'),
                      ),
                    ),
                    _buildContenidoPsicopedagogicoList(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Drawer _buildCustomDrawer(BuildContext context, String userId) {
    return Drawer(
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('estudiantes')
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Drawer(
              child: Center(child: Text('Error al cargar datos')),
            );
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Drawer(
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final nombre = userData['nombre'] ?? '';
          final apellidos = userData['apellidos'] ?? '';
          final codigo = userData['codigo_estudiante'] ?? '';
          final photoUrl = userData['photoUrl'] ?? '';

          return Column(
            children: [
              UserAccountsDrawerHeader(
                accountName: Text('$nombre $apellidos'),
                accountEmail: Text(codigo),
                currentAccountPicture: CircleAvatar(
                  backgroundImage: photoUrl.isNotEmpty
                      ? NetworkImage(photoUrl)
                      : const AssetImage('assets/avatar.jpg') as ImageProvider,
                ),
              ),
              Expanded(
                child: Container(
                  color: const Color(0xff060628),
                  child: ListView(
                    children: [
                      _buildDrawerItem(
                        context,
                        Icons.home,
                        'Inicio',
                        () => Navigator.pop(context),
                      ),
                      _buildDrawerItem(context, Icons.person, 'Mi Perfil', () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StudentProfilePage(),
                          ),
                        );
                      }),
                      _buildDrawerItem(
                        context,
                        Icons.calendar_today,
                        'Calendario',
                        () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CalendarioPage(),
                            ),
                          );
                        },
                      ),
                      _buildDrawerItem(
                        context,
                        Icons.book_online,
                        'Tutorías agendadas',
                        () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HistorialSesionesPage(),
                            ),
                          );
                        },
                      ),
                      _buildDrawerItem(
                        context,
                        Icons.menu_book,
                        'Material Educativo',
                        () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const MaterialEducativoPage(),
                            ),
                          );
                        },
                      ),
                      _buildDrawerItem(
                        context,
                        Icons.emoji_events,
                        'Gamificación',
                        () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, AppRoutes.gamification);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.flag, color: Colors.white),
                        title: const Text(
                          'Mis reportes',
                          style: TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MisReportesPage(),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.white),
                        title: const Text(
                          'Cerrar sesión',
                          style: TextStyle(color: Colors.white),
                        ),
                        onTap: () async {
                          await FirebaseAuth.instance.signOut();
                          final prefs = PreferenciasUsuario();
                          await prefs.clearUserSession();
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            AppRoutes.roleSelector,
                            (route) => false,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  ListTile _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.contrast),
                tooltip: 'Modo alto contraste',
                onPressed: () {
                  Provider.of<ThemeProvider>(
                    context,
                    listen: false,
                  ).toggleContrast();
                },
              ),
              _buildNotificationIcon(context, ''),
              const SizedBox(width: 10),
              CircleAvatar(
                backgroundImage: AssetImage('assets/avatar.jpg'),
                radius: 18,
              ),
            ],
          ),
        ],
      );
    }
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('estudiantes')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        String photoUrl = '';
        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          photoUrl = userData['photoUrl'] ?? '';
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.contrast),
                  tooltip: 'Modo alto contraste',
                  onPressed: () {
                    Provider.of<ThemeProvider>(
                      context,
                      listen: false,
                    ).toggleContrast();
                  },
                ),
                _buildNotificationIcon(context, user.uid),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StudentProfilePage(),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    backgroundImage: photoUrl.isNotEmpty
                        ? NetworkImage(photoUrl)
                        : const AssetImage('assets/avatar.jpg')
                              as ImageProvider,
                    radius: 18,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationIcon(BuildContext context, String usuarioId) {
    if (usuarioId.isEmpty) {
      return IconButton(
        icon: const Icon(Icons.notifications, size: 28),
        onPressed: () {},
      );
    }

    return NotificationBadge(
      child: IconButton(
        icon: const Icon(Icons.notifications, size: 28),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NotificacionesPage()),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, {Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildSolicitudesEstudiante(String estudianteId) {
    return StreamBuilder<List<SesionTutoria>>(
      stream: _streamSesionesPorEstudiante(estudianteId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No tienes tutorías agendadas.'));
        }
        final sesiones = snapshot.data!;
        // Buscar la primera sesión completada sin encuesta respondida
        Future.microtask(() async {
          for (final sesion in sesiones) {
            if (sesion.estado == 'completada') {
              final encuesta = await EncuestaSatisfaccionService()
                  .obtenerEncuesta(
                    sesionId: sesion.id,
                    estudianteId: estudianteId,
                  );
              if (encuesta == null && context.mounted) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => EncuestaSatisfaccionModal(
                    onSubmit: (calificacion, comentario) async {
                      final nuevaEncuesta = EncuestaSatisfaccion(
                        id: '',
                        estudianteId: estudianteId,
                        calificacion: calificacion,
                        comentario: comentario,
                        fechaRespuesta: DateTime.now(),
                      );
                      await EncuestaSatisfaccionService().guardarEncuesta(
                        sesionId: sesion.id,
                        encuesta: nuevaEncuesta,
                      );
                    },
                    onCancel: () {
                      Navigator.of(context).pop();
                    },
                  ),
                );
                break;
              }
            }
          }
        });
        return SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: sesiones.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final sesion = sesiones[index];
              String fechaTexto = '';
              if (sesion.fechaSesion != null &&
                  (sesion.horaInicio ?? '').isNotEmpty) {
                fechaTexto =
                    '${sesion.dia ?? ''} ${DateFormat('dd/MM/yyyy').format(sesion.fechaSesion!)} - ${sesion.horaInicio}';
              } else {
                fechaTexto = '${sesion.dia ?? ''} - ${sesion.horaInicio ?? ''}';
              }
              Color estadoColor;
              switch (sesion.estado) {
                case 'aceptada':
                  estadoColor = Colors.green;
                  break;
                case 'completada':
                  estadoColor = Colors.blue;
                  break;
                case 'rechazada':
                  estadoColor = Colors.red;
                  break;
                default:
                  estadoColor = Colors.orange;
              }
              return GestureDetector(
                onTap: () => _mostrarDetalleSesion(context, sesion),
                child: Container(
                  width: 180,
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F6FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sesion.curso ?? 'Sin curso',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fechaTexto,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    sesion.estado == 'reprogramacion_pendiente'
                                    ? Colors.orange.withAlpha(
                                        (0.15 * 255).toInt(),
                                      )
                                    : estadoColor.withAlpha(
                                        (0.15 * 255).toInt(),
                                      ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                sesion.estado == 'reprogramacion_pendiente'
                                    ? 'REPROGRAMACIÓN PENDIENTE'
                                    : sesion.estado.toUpperCase(),
                                style: TextStyle(
                                  color:
                                      sesion.estado ==
                                          'reprogramacion_pendiente'
                                      ? Colors.orange
                                      : estadoColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Stream<List<SesionTutoria>> _streamSesionesPorEstudiante(
    String estudianteId,
  ) {
    return FirebaseFirestore.instance
        .collection('sesiones_tutoria')
        .where('estudianteId', isEqualTo: estudianteId)
        .orderBy('fechaReserva', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => SesionTutoria.fromMap(doc.data()))
              .toList();
        });
  }

  void _mostrarDetalleSesion(BuildContext context, SesionTutoria sesion) async {
    // Obtener nombre del tutor
    String nombreTutor = 'Tutor';
    if (sesion.tutorId.isNotEmpty) {
      final doc = await FirebaseFirestore.instance
          .collection('tutores')
          .doc(sesion.tutorId)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final nombre = data['nombre'] ?? '';
        final apellidos = data['apellidos'] ?? '';
        nombreTutor = ('$nombre $apellidos').trim().isEmpty
            ? 'Tutor'
            : '$nombre $apellidos';
      }
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.45,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.school, color: Colors.deepPurple, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      sesion.curso ?? 'Sin curso',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (sesion.estado == 'completada')
                    IconButton(
                      icon: const Icon(Icons.flag, color: Colors.redAccent),
                      tooltip: 'Reportar incidente',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            bool anonimo = false;
                            String tipo = 'Acoso';
                            String ubicacion = '';
                            String descripcion = '';
                            XFile? imagen;
                            final picker = ImagePicker();
                            return StatefulBuilder(
                              builder: (context, setState) => AlertDialog(
                                title: const Text('Reportar incidente'),
                                content: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Checkbox(
                                            value: anonimo,
                                            onChanged: (v) => setState(
                                              () => anonimo = v ?? false,
                                            ),
                                          ),
                                          const Text('Enviar como anónimo'),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      DropdownButtonFormField<String>(
                                        value: tipo,
                                        items: const [
                                          DropdownMenuItem(
                                            value: 'Acoso',
                                            child: Text('Acoso'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'Problema técnico',
                                            child: Text('Problema técnico'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'Otro',
                                            child: Text('Otro'),
                                          ),
                                        ],
                                        onChanged: (v) =>
                                            setState(() => tipo = v ?? 'Acoso'),
                                        decoration: const InputDecoration(
                                          labelText: 'Tipo de incidente',
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        decoration: const InputDecoration(
                                          labelText: 'Ubicación (opcional)',
                                        ),
                                        onChanged: (v) => ubicacion = v,
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        decoration: const InputDecoration(
                                          labelText: 'Descripción',
                                        ),
                                        maxLines: 3,
                                        onChanged: (v) => descripcion = v,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          ElevatedButton.icon(
                                            icon: const Icon(
                                              Icons.photo_camera,
                                            ),
                                            label: const Text('Adjuntar foto'),
                                            onPressed: () async {
                                              final picked = await picker
                                                  .pickImage(
                                                    source: ImageSource.gallery,
                                                  );
                                              if (picked != null)
                                                setState(() => imagen = picked);
                                            },
                                          ),
                                          if (imagen != null) ...[
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('Cancelar'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      final user =
                                          FirebaseAuth.instance.currentUser;
                                      String? imageUrl;
                                      if (imagen != null) {
                                        final storageRef = FirebaseStorage
                                            .instance
                                            .ref()
                                            .child(
                                              'reportes_incidentes/${DateTime.now().millisecondsSinceEpoch}_${imagen!.name}',
                                            );
                                        final uploadTask = await storageRef
                                            .putFile(File(imagen!.path));
                                        imageUrl = await storageRef
                                            .getDownloadURL();
                                      }
                                      await FirebaseFirestore.instance
                                          .collection('reportes_incidentes')
                                          .add({
                                            'sesionId': sesion.id,
                                            'usuarioId': anonimo
                                                ? null
                                                : user?.uid,
                                            'anonimo': anonimo,
                                            'tipo': tipo,
                                            'ubicacion': ubicacion,
                                            'descripcion': descripcion,
                                            'fecha': DateTime.now(),
                                            'imagen': imageUrl,
                                          });
                                      Navigator.of(context).pop();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Reporte enviado.'),
                                        ),
                                      );
                                    },
                                    child: const Text('Enviar'),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _detalleItem('Estado', sesion.estado.toUpperCase()),
              if (sesion.fechaSesion != null &&
                  (sesion.horaInicio ?? '').isNotEmpty &&
                  (sesion.horaFin ?? '').isNotEmpty)
                _detalleItem(
                  'Fecha y hora',
                  '${DateFormat('dd/MM/yyyy').format(sesion.fechaSesion!)} ${sesion.horaInicio} - ${sesion.horaFin}',
                ),
              if (sesion.mensaje != null && sesion.mensaje!.isNotEmpty)
                _detalleItem('Mensaje', sesion.mensaje!),
              _detalleItem('Tutor', nombreTutor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detalleItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalCards(List<Widget> cards) {
    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: cards
            .map(
              (card) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: card,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildCard(String text, IconData icon, Color color) {
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
  ) {
    return GestureDetector(
      onTap: title == 'TUTORÍAS'
          ? () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SeleccionarTutorPage(estudianteId: user.uid),
                ),
              );
            }
          : null,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsList() {
    return FutureBuilder<List<Noticia>>(
      future: fetchNoticias(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No hay noticias disponibles.'));
        }
        // Filtrar solo noticias
        final noticias = filtrarPorTipo(snapshot.data!, 'noticia')
          ..sort((a, b) => b.fecha.compareTo(a.fecha));

        if (noticias.isEmpty) {
          return const Center(child: Text('No hay noticias disponibles.'));
        }

        return SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: noticias.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final noticia = noticias[index];
              return SizedBox(
                width: 200,
                child: _NoticiaCard(noticia: noticia),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEventosList() {
    return FutureBuilder<List<Noticia>>(
      future: fetchNoticias(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No hay eventos disponibles.'));
        }
        // Filtrar solo eventos
        final eventos = filtrarPorTipo(snapshot.data!, 'eventoUNFV')
          ..sort((a, b) => b.fecha.compareTo(a.fecha));

        if (eventos.isEmpty) {
          return const Center(child: Text('No hay eventos disponibles.'));
        }

        return SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: eventos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final evento = eventos[index];
              return SizedBox(width: 200, child: _EventoCard(evento: evento));
            },
          ),
        );
      },
    );
  }

  Widget _buildContenidoPsicopedagogicoList() {
    return FutureBuilder<List<Noticia>>(
      future: fetchNoticias(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No hay contenido disponible.'));
        }
        // Filtrar solo contenido psicopedagógico
        final contenidos = filtrarPorTipo(
          snapshot.data!,
          'contenidoPsicopedagogico',
        )..sort((a, b) => b.fecha.compareTo(a.fecha));

        if (contenidos.isEmpty) {
          return const Center(child: Text('No hay contenido disponible.'));
        }

        return SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: contenidos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final contenido = contenidos[index];
              return SizedBox(
                width: 180,
                child: _ContenidoPsicopedagogicoCard(contenido: contenido),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAssignedTutorCard(String studentId) {
    return FutureBuilder<DocumentSnapshot?>(
      future: _getAssignedTutor(studentId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          // Si no hay tutor asignado o está cargando, no muestra nada.
          return const SizedBox.shrink();
        }

        final tutorData = snapshot.data!.data() as Map<String, dynamic>;
        final tutorId = snapshot.data!.id;
        final photoUrl = tutorData['photoUrl'] as String? ?? '';
        final nombre = tutorData['nombre'] as String? ?? 'Tutor';
        final apellidos = tutorData['apellidos'] as String? ?? '';
        final especialidad =
            tutorData['especialidad'] as String? ?? 'Especialista';

        return Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MI TUTOR ASIGNADO',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                    fontSize: 14,
                  ),
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: photoUrl.isNotEmpty
                          ? NetworkImage(photoUrl)
                          : const AssetImage('assets/teacher_avatar.jpg')
                                as ImageProvider,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$nombre $apellidos',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            especialidad,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.calendar_today,
                        color: Colors.deepPurple,
                        size: 28,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AgendarTutoriaPage(
                              tutorId: tutorId,
                              estudianteId: studentId,
                            ),
                          ),
                        );
                      },
                      tooltip: 'Agendar Tutoría',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class SeleccionarTutorPage extends StatefulWidget {
  final String estudianteId;
  const SeleccionarTutorPage({required this.estudianteId, super.key});

  @override
  State<SeleccionarTutorPage> createState() => _SeleccionarTutorPageState();
}

class _SeleccionarTutorPageState extends State<SeleccionarTutorPage> {
  String _busqueda = '';
  final TextEditingController _busquedaController = TextEditingController();
  late Future<List<QueryDocumentSnapshot>> _tutoresFuture;
  late Future<String?> _assignedTutorIdFuture;
  String? _escuelaSeleccionada;

  final List<String> _escuelas = [
    'Ingeniería Informática',
    'Ingeniería Electrónica',
    'Ingeniería de Telecomunicaciones',
    'Ingeniería Mecatrónica',
  ];

  @override
  void initState() {
    super.initState();
    _tutoresFuture = _obtenerTutores();
    _assignedTutorIdFuture = _getAssignedTutorId(widget.estudianteId);
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<List<QueryDocumentSnapshot>> _obtenerTutores() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('tutores')
        .get();
    return snapshot.docs;
  }

  Future<String?> _getAssignedTutorId(String studentId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('tutores')
        .where('estudiantes_asignados', arrayContains: studentId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.id;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Seleccionar Tutor')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _busquedaController,
                        decoration: InputDecoration(
                          hintText: 'Buscar tutor por nombre o apellido',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) => setState(() => _busqueda = value),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _busqueda = '';
                          _busquedaController.clear();
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _escuelaSeleccionada,
                  hint: const Text('Filtrar por Escuela Profesional'),
                  isExpanded: true,
                  items: _escuelas.map((String school) {
                    return DropdownMenuItem<String>(
                      value: school,
                      child: Text(school),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _escuelaSeleccionada = newValue;
                    });
                  },
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
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: Future.wait([_tutoresFuture, _assignedTutorIdFuture]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(
                    child: Text('No se encontraron tutores.'),
                  );
                }

                final tutores =
                    snapshot.data![0] as List<QueryDocumentSnapshot>;
                final assignedTutorId = snapshot.data![1] as String?;

                // Lógica de filtrado
                List<QueryDocumentSnapshot> filtrados = List.from(tutores);

                // 1. Filtrado por búsqueda de texto
                if (_busqueda.isNotEmpty) {
                  filtrados = filtrados.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final nombreCompleto =
                        '${data['nombre'] ?? ''} ${data['apellidos'] ?? ''}'
                            .toLowerCase();
                    return nombreCompleto.contains(_busqueda.toLowerCase());
                  }).toList();
                }

                // 2. Filtrado por escuela profesional
                if (_escuelaSeleccionada != null) {
                  filtrados = filtrados.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    // El campo se llama 'escuela' en Firestore
                    return data['escuela'] == _escuelaSeleccionada;
                  }).toList();
                }

                // Reordenar para poner al tutor asignado primero
                if (assignedTutorId != null) {
                  filtrados.sort((a, b) {
                    if (a.id == assignedTutorId) return -1;
                    if (b.id == assignedTutorId) return 1;
                    return 0;
                  });
                }

                return ListView.builder(
                  itemCount: filtrados.length,
                  itemBuilder: (context, index) {
                    final tutorDoc = filtrados[index];
                    final tutorData = tutorDoc.data() as Map<String, dynamic>;
                    final esAsignado = tutorDoc.id == assignedTutorId;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      color: esAsignado ? Colors.deepPurple[50] : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundImage:
                              (tutorData['photoUrl'] as String? ?? '')
                                  .isNotEmpty
                              ? NetworkImage(tutorData['photoUrl'])
                              : const AssetImage('assets/teacher_avatar.jpg')
                                    as ImageProvider,
                        ),
                        title: Text(
                          '${tutorData['nombre'] ?? ''} ${tutorData['apellidos'] ?? ''}',
                        ),
                        subtitle: Text(
                          tutorData['especialidad'] ?? 'Especialista',
                        ),
                        trailing: esAsignado
                            ? const Chip(
                                label: Text('Asignado'),
                                avatar: Icon(
                                  Icons.star,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                backgroundColor: Colors.deepPurple,
                                labelStyle: TextStyle(color: Colors.white),
                              )
                            : const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AgendarTutoriaPage(
                                tutorId: tutorDoc.id,
                                estudianteId: widget.estudianteId,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Modelo para Noticia
class Noticia {
  final int id;
  final String texto;
  final String imagenUrl;
  final String link;
  final DateTime fecha;
  final String tipo;

  Noticia({
    required this.id,
    required this.texto,
    required this.imagenUrl,
    required this.link,
    required this.fecha,
    required this.tipo,
  });

  factory Noticia.fromJson(Map<String, dynamic> json) {
    return Noticia(
      id: json['ID'] ?? 0,
      texto: json['TEXTO'] ?? '',
      imagenUrl: json['IMAGEN_URL'] ?? '',
      link: json['LINK'] ?? '',
      fecha: DateTime.tryParse(json['FECHA'] ?? '') ?? DateTime.now(),
      tipo: json['TIPO'] ?? 'noticia',
    );
  }
}

Future<List<Noticia>> fetchNoticias() async {
  const url =
      'https://script.google.com/macros/s/AKfycbxpFBL47pHkhm5EQckB_2MKURpr8cfI0LSlHcWQaObaElGQcAXiRzDPdwEHAaph_bi3/exec';
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => Noticia.fromJson(json)).toList();
  } else {
    throw Exception('Error al cargar noticias');
  }
}

// Función para filtrar por tipo
List<Noticia> filtrarPorTipo(List<Noticia> noticias, String tipo) {
  return noticias
      .where((noticia) => noticia.tipo.toLowerCase() == tipo.toLowerCase())
      .toList();
}

Future<void> _abrirLink(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

// Página para mostrar todas las noticias
class TodasLasNoticiasPage extends StatelessWidget {
  const TodasLasNoticiasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Todas las noticias')),
      body: FutureBuilder<List<Noticia>>(
        future: fetchNoticias(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay noticias disponibles.'));
          }
          final noticias = List<Noticia>.from(snapshot.data!)
            ..sort((a, b) => b.fecha.compareTo(a.fecha));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: noticias.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final noticia = noticias[index];
              return _NoticiaCard(noticia: noticia);
            },
          );
        },
      ),
    );
  }
}

class _NoticiaCard extends StatefulWidget {
  final Noticia noticia;
  const _NoticiaCard({required this.noticia});

  @override
  State<_NoticiaCard> createState() => _NoticiaCardState();
}

class _NoticiaCardState extends State<_NoticiaCard> {
  bool _highlighted = false;
  DateTime? _lastTap;

  void _onTap() {
    setState(() {
      _highlighted = !_highlighted;
    });
  }

  void _onDoubleTap() {
    _abrirLink(widget.noticia.link);
  }

  @override
  Widget build(BuildContext context) {
    final fechaStr = DateFormat('dd/MM/yyyy').format(widget.noticia.fecha);
    return GestureDetector(
      onTap: _onTap,
      onDoubleTap: _onDoubleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _highlighted
              ? Colors.deepPurple.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.deepPurple.withOpacity(0.2)),
        ),
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                // Fecha encima de la miniatura
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    fechaStr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                if (widget.noticia.imagenUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.noticia.imagenUrl,
                      height: 50,
                      width: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.noticia.texto,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget para eventos (sin miniatura)
class _EventoCard extends StatefulWidget {
  final Noticia evento;
  const _EventoCard({required this.evento});

  @override
  State<_EventoCard> createState() => _EventoCardState();
}

class _EventoCardState extends State<_EventoCard> {
  bool _highlighted = false;

  void _onTap() {
    setState(() {
      _highlighted = !_highlighted;
    });
  }

  void _onDoubleTap() {
    _abrirLink(widget.evento.link);
  }

  @override
  Widget build(BuildContext context) {
    final fechaStr = DateFormat('dd/MM/yyyy').format(widget.evento.fecha);
    return GestureDetector(
      onTap: _onTap,
      onDoubleTap: _onDoubleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _highlighted ? Colors.orange.withOpacity(0.1) : Colors.orange,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                fechaStr,
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.evento.texto,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// Widget para contenido psicopedagógico
class _ContenidoPsicopedagogicoCard extends StatefulWidget {
  final Noticia contenido;
  const _ContenidoPsicopedagogicoCard({required this.contenido});

  @override
  State<_ContenidoPsicopedagogicoCard> createState() =>
      _ContenidoPsicopedagogicoCardState();
}

class _ContenidoPsicopedagogicoCardState
    extends State<_ContenidoPsicopedagogicoCard> {
  bool _highlighted = false;

  void _onTap() {
    setState(() {
      _highlighted = !_highlighted;
    });
  }

  void _onDoubleTap() {
    _abrirLink(widget.contenido.link);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      onDoubleTap: _onDoubleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _highlighted ? Colors.green.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withOpacity(0.2)),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.contenido.imagenUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  widget.contenido.imagenUrl,
                  height: 80,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 8),
            Text(
              widget.contenido.texto,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
