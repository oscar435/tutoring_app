import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/gamification/services/gamification_service.dart';
import '../core/models/progreso_estudiante.dart';
import '../core/models/logro.dart';

Future<void> main() async {
  print('🧪 Probando sistema de gamificación...');

  try {
    final gamificationService = GamificationService();

    // ID de prueba para un estudiante
    const String testStudentId = 'test_student_123';

    print('1. Inicializando logros...');
    await gamificationService.inicializarLogros();

    print('2. Obteniendo progreso inicial...');
    ProgresoEstudiante? progreso = await gamificationService
        .obtenerProgresoEstudiante(testStudentId);
    print(
      '   Progreso inicial: ${progreso?.puntosTotales} puntos, Nivel ${progreso?.nivel}',
    );

    print('3. Simulando completar una sesión...');
    await gamificationService.completarSesion(testStudentId);

    print('4. Obteniendo progreso después de la sesión...');
    progreso = await gamificationService.obtenerProgresoEstudiante(
      testStudentId,
    );
    print(
      '   Progreso después de sesión: ${progreso?.puntosTotales} puntos, Nivel ${progreso?.nivel}',
    );
    print('   Sesiones completadas: ${progreso?.sesionesCompletadas}');
    print('   Logros desbloqueados: ${progreso?.logrosDesbloqueados.length}');

    print('5. Simulando completar otra sesión...');
    await gamificationService.completarSesion(testStudentId);

    print('6. Obteniendo progreso final...');
    progreso = await gamificationService.obtenerProgresoEstudiante(
      testStudentId,
    );
    print(
      '   Progreso final: ${progreso?.puntosTotales} puntos, Nivel ${progreso?.nivel}',
    );
    print('   Sesiones completadas: ${progreso?.sesionesCompletadas}');

    print('7. Obteniendo ranking...');
    List<ProgresoEstudiante> ranking = await gamificationService
        .obtenerRanking();
    print('   Ranking obtenido: ${ranking.length} estudiantes');

    print('8. Obteniendo logros...');
    List<Logro> logros = await gamificationService.obtenerLogros();
    print('   Logros disponibles: ${logros.length}');

    print('\n✅ Pruebas completadas exitosamente!');
    print('📊 Resumen:');
    print('   - Puntos totales: ${progreso?.puntosTotales}');
    print('   - Nivel actual: ${progreso?.nivel}');
    print('   - Sesiones: ${progreso?.sesionesCompletadas}');
    print('   - Logros: ${progreso?.logrosDesbloqueados.length}');
  } catch (e) {
    print('❌ Error en las pruebas: $e');
  }
}
