import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tutoring_app/core/models/notificacion.dart'; // Asegúrate de que este import sea correcto.

class NotificacionService {
  static final NotificacionService _instance = NotificacionService._internal();
  factory NotificacionService() => _instance;
  NotificacionService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _fcmToken;
  bool _isInitialized = false;

  Stream<RemoteMessage> get onMessageReceived => FirebaseMessaging.onMessage;
  Stream<RemoteMessage> get onMessageOpenedApp => FirebaseMessaging.onMessageOpenedApp;
  Stream<RemoteMessage?> get onInitialMessage =>
      FirebaseMessaging.instance.getInitialMessage().asStream();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _requestPermissions();
      await _configureFCM();
      await _configureLocalNotifications();
      await _getFCMToken();
      _setupMessageHandlers();
      _isInitialized = true;
      debugPrint('✅ Servicio de notificaciones inicializado correctamente');
    } catch (e) {
      debugPrint('❌ Error al inicializar servicio de notificaciones: $e');
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      await _firebaseMessaging.requestPermission(
        alert: true, badge: true, sound: true, provisional: false,
      );
    } else if (Platform.isAndroid) {
      await Permission.notification.request();
    }
  }

  Future<void> _configureFCM() async {
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true, badge: true, sound: true,
    );
  }

  Future<void> _configureLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $_fcmToken');
      if (_fcmToken != null && _auth.currentUser != null) {
        await _saveFCMToken(_fcmToken!);
      }
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        if (_auth.currentUser != null) {
          _saveFCMToken(newToken);
        }
      });
    } catch (e) {
      debugPrint('Error al obtener FCM token: $e');
    }
  }

  Future<void> _saveFCMToken(String token) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'ultimaActualizacion': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error al guardar FCM token: $e');
    }
  }

  // Método público para actualizar el FCM token después del login
  Future<void> updateFCMTokenAfterLogin() async {
    try {
      debugPrint('🔄 Actualizando FCM token después del login...');
      
      // Obtener un token FRESCO cada vez (no reutilizar el almacenado)
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        _fcmToken = token;
        debugPrint('📱 FCM Token obtenido: $token');
        
        // Guardar en Firestore
        await _saveFCMToken(token);
        debugPrint('✅ FCM Token guardado en Firestore');
      } else {
        debugPrint('❌ No se pudo obtener FCM token');
      }
    } catch (e) {
      debugPrint('❌ Error actualizando FCM token después del login: $e');
    }
  }

  // Método público para obtener el token actual
  String? getCurrentFCMToken() {
    return _fcmToken;
  }

  // Método público para limpiar el FCM token al hacer logout
  Future<void> clearFCMTokenOnLogout() async {
    try {
      debugPrint('🧹 Limpiando FCM token al hacer logout...');
      
      final user = _auth.currentUser;
      if (user != null) {
        // Eliminar el token de Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': FieldValue.delete(),
          'ultimaActualizacion': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ FCM Token eliminado de Firestore');
      }
      
      // Limpiar el token en memoria
      _fcmToken = null;
    } catch (e) {
      debugPrint('❌ Error limpiando FCM token: $e');
    }
  }

  void _setupMessageHandlers() {
    // 1. Mensaje recibido mientras la app está en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Mensaje recibido en primer plano: ${message.notification?.title}');
      // Solo mostramos la notificación visualmente.
      // El backend es ahora el único responsable de crear el documento en Firestore.
      _showLocalNotification(message);
    });

    // 2. Usuario toca la notificación y abre la app (desde segundo plano)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notificación tocada para abrir la app: ${message.notification?.title}');
      _handleNotificationTap(message);
    });
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'tutoring_app_channel',
      'Tutoring App Notifications',
      channelDescription: 'Canal para notificaciones de la app de tutorías',
      importance: Importance.max,
      priority: Priority.high,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(presentSound: true, presentBadge: true, presentAlert: true);
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      message.notification?.title,
      message.notification?.body,
      platformDetails,
      payload: json.encode(message.data),
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = json.decode(response.payload!);
        // Creamos un RemoteMessage "falso" para reutilizar el handler
        _handleNotificationTap(RemoteMessage(data: Map<String, dynamic>.from(data)));
      } catch (e) {
        debugPrint('Error decodificando payload de notificación: $e');
      }
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    // Lógica para navegar a diferentes pantallas según la notificación.
    // Esta lógica debe ser implementada según las rutas de tu app.
    final String? tipo = message.data['tipo'];
    debugPrint('Manejando tap de notificación tipo: $tipo');

    // Ejemplo de cómo podrías manejar la navegación:
    // final navigatorKey = GlobalKey<NavigatorState>(); // Necesitarías un GlobalKey en tu app
    // if (navigatorKey.currentState != null) {
    //   switch (tipo) {
    //     case 'solicitudTutoria':
    //       navigatorKey.currentState!.pushNamed('/solicitudes_tutor');
    //       break;
    //     case 'sesionConfirmada':
    //       navigatorKey.currentState!.pushNamed('/proximas_tutorias');
    //       break;
    //     // etc...
    //   }
    // }
  }

  // LA FUNCIÓN _saveNotificationToFirestore HA SIDO ELIMINADA.
  // La creación de documentos de notificación es ahora responsabilidad
  // exclusiva de las Cloud Functions para garantizar una única fuente de verdad.

  // Esta función puede ser útil si necesitas convertir el string del tipo
  // a un enum en otras partes de la app.
  TipoNotificacion getTipoFromString(String tipo) {
    switch (tipo) {
      case 'solicitudTutoria':
        return TipoNotificacion.solicitudTutoria;
      case 'respuestaSolicitud':
        return TipoNotificacion.respuestaSolicitud;
      case 'sesionConfirmada':
        return TipoNotificacion.sesionConfirmada;
      case 'recordatorioSesion':
        return TipoNotificacion.recordatorioSesion;
      // Añade otros casos según sea necesario
      default:
        return TipoNotificacion.mensajeGeneral;
    }
  }

  Future<void> marcarComoLeida(String notificacionId) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('notificaciones')
            .doc(notificacionId)
            .update({'leida': true});
      }
    } catch (e) {
      debugPrint('Error al marcar notificación como leída: $e');
    }
  }

  Stream<List<Notificacion>> getNotificacionesStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }
    return _firestore
        .collection('notificaciones')
        .where('usuarioId', isEqualTo: user.uid)
        .orderBy('fechaCreacion', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Notificacion.fromFirestore(doc.data()))
            .toList());
  }

  Stream<int> getUnreadNotificationsCount() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(0);
    }
    return _firestore
        .collection('notificaciones')
        .where('usuarioId', isEqualTo: user.uid)
        .where('leida', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
} 