import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/gamification/services/gamification_service.dart';

Future<void> main() async {
  print('🚀 Inicializando sistema de gamificación...');

  try {
    final gamificationService = GamificationService();

    // Inicializar logros predefinidos
    await gamificationService.inicializarLogros();

    print('✅ Logros inicializados correctamente');
    print('📋 Logros creados:');
    print('   - Primera Sesión (50 pts)');
    print('   - Estudiante Dedicado (100 pts)');
    print('   - Estudiante Consistente (200 pts)');
    print('   - Asistencia Perfecta (150 pts)');
    print('   - Primera Evaluación (75 pts)');
    print('   - Nivel 5 (300 pts)');

    print('\n🎮 Sistema de gamificación listo para usar!');
  } catch (e) {
    print('❌ Error inicializando gamificación: $e');
  }
}
