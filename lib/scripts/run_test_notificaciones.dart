import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/services/firebase_options.dart';
import 'test_notificaciones.dart';

void main() async {
  // Inicializar Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  print('🚀 Iniciando pruebas de notificaciones...');
  print('=====================================');
  
  // Verificar si hay usuario autenticado
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    print('❌ No hay usuario autenticado. Por favor, inicia sesión primero.');
    return;
  }
  
  print('✅ Usuario autenticado: ${user.email}');
  print('');
  
  // Ejecutar pruebas
  await TestNotificaciones.testNotificaciones();
  
  print('');
  print('🎯 Pruebas completadas. Revisa la app para ver las notificaciones.');
  print('');
  print('💡 Para limpiar las notificaciones de prueba, ejecuta:');
  print('   TestNotificaciones.limpiarNotificacionesPrueba("${user.uid}");');
} 