import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/gamification/services/gamification_service.dart';
import '../core/models/logro.dart';

Future<void> main() async {
  print('🚀 Forzando inicialización de gamificación...');

  try {
    final gamificationService = GamificationService();

    print('1. Inicializando logros...');
    await gamificationService.inicializarLogros();

    print('2. Verificando logros...');
    List<Logro> logros = await gamificationService.obtenerLogros();

    print('✅ Logros inicializados correctamente');
    print('📋 Logros creados: ${logros.length}');

    for (Logro logro in logros) {
      print('   - ${logro.nombre} (${logro.puntosRecompensa} pts)');
    }

    print('\n🎮 Sistema de gamificación listo!');
    print(
      '💡 Ahora puedes abrir la app y ver los logros en la pestaña "Logros"',
    );
  } catch (e) {
    print('❌ Error inicializando gamificación: $e');
  }
}
