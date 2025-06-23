# 📱 Sistema de Notificaciones Push - Tutoring App

## 🎯 Descripción General

Este sistema implementa notificaciones push completas para la aplicación de tutorías, incluyendo Firebase Cloud Messaging (FCM) y notificaciones locales. El sistema es completamente automático y se integra con todos los flujos de la aplicación.

## 🏗️ Arquitectura del Sistema

### Componentes Principales

1. **Modelo de Notificación** (`lib/core/models/notificacion.dart`)
   - Soporte para FCM tokens
   - Tipos de notificación predefinidos
   - Datos adicionales en formato JSON
   - Métodos de formateo de tiempo

2. **Servicio de Notificaciones** (`lib/features/notificaciones/services/notificacion_service.dart`)
   - Gestión de FCM tokens
   - Notificaciones locales
   - Métodos específicos por tipo
   - Manejo de permisos

3. **Interfaz de Usuario** (`lib/features/notificaciones/pages/notificaciones_page.dart`)
   - Diseño moderno y responsive
   - Gestos de deslizar para eliminar
   - Formateo inteligente de fechas
   - Iconos y colores por tipo

4. **Widget de Badge** (`lib/features/notificaciones/widgets/notification_badge.dart`)
   - Contador de notificaciones no leídas
   - Integración en AppBars
   - Actualización automática

5. **Cloud Functions** (`functions/src/index.ts`)
   - Triggers automáticos en Firestore
   - Envío de notificaciones push
   - Recordatorios programados

## 📋 Tipos de Notificaciones

### 1. Solicitud de Tutoría
- **Trigger**: Creación de solicitud en Firestore
- **Destinatario**: Tutor
- **Mensaje**: "Juan Pérez solicita una tutoría de Matemáticas"

### 2. Respuesta de Solicitud
- **Trigger**: Actualización de estado de solicitud
- **Destinatario**: Estudiante
- **Mensaje**: "María García aceptó tu solicitud de tutoría de Física"

### 3. Recordatorio de Sesión
- **Trigger**: Programado cada hora
- **Destinatario**: Estudiante/Tutor
- **Mensaje**: "Tienes una sesión de Química con Carlos López en 30 minutos"

### 4. Cancelación de Sesión
- **Trigger**: Actualización de estado de sesión
- **Destinatario**: Estudiante/Tutor
- **Mensaje**: "La sesión de Matemáticas ha sido cancelada"

### 5. Asignación de Tutor
- **Trigger**: Asignación manual por admin
- **Destinatario**: Estudiante
- **Mensaje**: "Se te ha asignado el tutor María García"

### 6. Notificación Administrativa
- **Trigger**: Manual desde panel admin
- **Destinatario**: Usuarios específicos
- **Mensaje**: Personalizable

## 🚀 Configuración e Instalación

### 1. Dependencias Flutter

```yaml
dependencies:
  firebase_messaging: ^15.1.3
  flutter_local_notifications: ^18.0.1
  permission_handler: ^11.3.1
```

### 2. Configuración Android

**AndroidManifest.xml**:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

<service
    android:name="io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingService"
    android:exported="false">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT"/>
    </intent-filter>
</service>
```

### 3. Configuración Firebase

1. **Habilitar Cloud Messaging** en Firebase Console
2. **Descargar google-services.json** y colocarlo en `android/app/`
3. **Configurar Cloud Functions**:
   ```bash
   cd functions
   npm install
   firebase deploy --only functions
   ```

## 🔧 Uso del Sistema

### Inicialización Automática

El sistema se inicializa automáticamente en `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Inicializar el servicio de notificaciones
  if (!kIsWeb) {
    await NotificacionService().initialize();
  }
  
  runApp(MyApp());
}
```

### Integración en Páginas

```dart
// Widget de badge en AppBar
NotificationBadge(
  child: IconButton(
    icon: const Icon(Icons.notifications),
    onPressed: () => Navigator.pushNamed(context, '/notificaciones'),
  ),
)
```

### Envío Manual de Notificaciones

```dart
// Desde el servicio
await NotificacionService().enviarNotificacionSolicitudTutoria(
  estudianteId: 'user123',
  estudianteNombre: 'Juan Pérez',
  tutorId: 'tutor456',
  materia: 'Matemáticas',
  fecha: DateTime.now().add(Duration(days: 1)),
);
```

## 🧪 Pruebas

### Script de Pruebas

```dart
// Ejecutar pruebas
dart run lib/scripts/run_test_notificaciones.dart
```

### Pruebas Manuales

1. **Notificación de prueba** desde la página de configuración
2. **Crear solicitud de tutoría** para probar notificación automática
3. **Aceptar/rechazar solicitud** para probar respuesta
4. **Verificar badge** en AppBar

## 📊 Monitoreo y Logs

### Logs del Servicio

```dart
// Logs automáticos
print('✅ Servicio de notificaciones inicializado correctamente');
print('FCM Token: $token');
print('✅ Notificación creada: ${notificacion.titulo}');
```

### Logs de Cloud Functions

```typescript
console.log(`Notificación enviada exitosamente: ${response}`);
console.log(`Recordatorios enviados para ${sesionesSnapshot.docs.length} sesiones`);
```

## 🔒 Seguridad

### Permisos

- **Android**: Permisos automáticos en runtime
- **iOS**: Solicitud de permisos en primera ejecución
- **Cloud Functions**: Verificación de roles de usuario

### Validaciones

- Verificación de FCM tokens válidos
- Validación de datos de entrada
- Manejo de errores robusto

## 🎨 Personalización

### Colores por Tipo

```dart
Color _getTypeColor(TipoNotificacion tipo) {
  switch (tipo) {
    case TipoNotificacion.solicitudTutoria: return Colors.blue;
    case TipoNotificacion.respuestaSolicitud: return Colors.green;
    case TipoNotificacion.recordatorioSesion: return Colors.orange;
    case TipoNotificacion.cancelacionSesion: return Colors.red;
    case TipoNotificacion.asignacionTutor: return Colors.purple;
    case TipoNotificacion.notificacionAdmin: return Colors.indigo;
    default: return Colors.grey;
  }
}
```

### Mensajes Personalizables

Los mensajes se pueden personalizar en:
- `NotificacionService` - Métodos de envío
- `Cloud Functions` - Triggers automáticos
- `NotificacionesConfigPage` - Configuración de usuario

## 🚨 Solución de Problemas

### Problemas Comunes

1. **Notificaciones no llegan**
   - Verificar FCM token en Firestore
   - Comprobar permisos de notificación
   - Revisar logs de Cloud Functions

2. **Badge no se actualiza**
   - Verificar stream de notificaciones
   - Comprobar método `getNotificacionesNoLeidas`
   - Revisar estado del widget

3. **Error de inicialización**
   - Verificar dependencias en pubspec.yaml
   - Comprobar configuración de Firebase
   - Revisar AndroidManifest.xml

### Debugging

```dart
// Habilitar logs detallados
NotificacionService().initialize().then((_) {
  print('✅ Inicialización completada');
}).catchError((error) {
  print('❌ Error: $error');
});
```

## 📈 Métricas y Analytics

### Métricas Automáticas

- Número de notificaciones enviadas
- Tasa de entrega exitosa
- Tiempo de respuesta de usuarios
- Tipos de notificación más populares

### Dashboard de Monitoreo

```typescript
// En Cloud Functions
console.log(`Métrica: ${tipo} enviada a ${userId}`);
```

## 🔄 Mantenimiento

### Actualizaciones

1. **Dependencias**: Mantener actualizadas las dependencias de FCM
2. **Cloud Functions**: Desplegar cambios automáticamente
3. **Configuración**: Revisar configuración de Firebase periódicamente

### Backup y Recuperación

- Los FCM tokens se almacenan en Firestore
- Configuración de usuario persistente
- Logs de actividad disponibles

## 📞 Soporte

Para soporte técnico o preguntas sobre el sistema de notificaciones:

1. Revisar logs de la aplicación
2. Verificar configuración de Firebase
3. Probar con el script de pruebas
4. Consultar esta documentación

---

**Versión**: 1.0.0  
**Última actualización**: Diciembre 2024  
**Compatibilidad**: Flutter 3.8+, Firebase 11.0+ 