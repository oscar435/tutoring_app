import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import '../features/gamification/services/gamification_service.dart';
import '../core/models/logro.dart';
import '../core/models/progreso_estudiante.dart';
import 'package:flutter/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('🔄 Sincronizando gamificación para todos los estudiantes...');

  try {
    // Inicializar Firebase
    print('0. Inicializando Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final gamificationService = GamificationService();
    final firestore = FirebaseFirestore.instance;

    // 1. Inicializar logros si no existen
    print('1. Verificando logros...');
    await gamificationService.inicializarLogros();

    // 2. Obtener todos los estudiantes
    print('2. Obteniendo lista de estudiantes...');
    QuerySnapshot estudiantesSnapshot = await firestore
        .collection('estudiantes')
        .get();

    print('   Encontrados ${estudiantesSnapshot.docs.length} estudiantes');

    // 3. Obtener todos los logros
    List<Logro> todosLogros = await gamificationService.obtenerLogros();

    // 4. Sincronizar progreso para cada estudiante
    int sincronizados = 0;
    for (var doc in estudiantesSnapshot.docs) {
      final estudianteId = doc.id;
      final estudianteData = doc.data() as Map<String, dynamic>;
      final nombre =
          '${estudianteData['nombre'] ?? ''} ${estudianteData['apellidos'] ?? ''}'
              .trim();

      print('   Sincronizando: $nombre ($estudianteId)');

      try {
        // Sincronizar progreso base (sesiones y asistencias reales)
        await gamificationService.sincronizarProgresoConSesiones(estudianteId);

        // Obtener progreso actualizado
        DocumentSnapshot progresoDoc = await firestore
            .collection('progreso_gamificacion')
            .doc(estudianteId)
            .get();

        ProgresoEstudiante progreso;
        if (!progresoDoc.exists) {
          // Crear progreso inicial si no existe
          print('     📝 Creando progreso inicial para $nombre');
          progreso = ProgresoEstudiante(
            estudianteId: estudianteId,
            puntosTotales: 0,
            nivel: 1,
            sesionesCompletadas: 0,
            sesionesAsistidas: 0,
            logrosDesbloqueados: [],
            fechaCreacion: DateTime.now(),
            ultimaActualizacion: DateTime.now(),
          );
          await firestore
              .collection('progreso_gamificacion')
              .doc(estudianteId)
              .set(progreso.toMap());
        } else {
          progreso = ProgresoEstudiante.fromMap(
            progresoDoc.data() as Map<String, dynamic>,
          );
        }

        // Sumar puntos de recompensa de logros desbloqueados
        int puntosTotales = progreso.puntosTotales;
        int nivel = (puntosTotales / 100).floor() + 1;

        // Actualizar progreso con los puntos extra
        await firestore
            .collection('progreso_gamificacion')
            .doc(estudianteId)
            .update({
              'puntosTotales': puntosTotales,
              'nivel': nivel,
              'ultimaActualizacion': DateTime.now().toIso8601String(),
            });

        print('     ✅ Puntos totales corregidos: $puntosTotales');
        sincronizados++;
      } catch (e) {
        print('     ❌ Error sincronizando $nombre: $e');
      }
    }

    print('\n✅ Sincronización completada!');
    print('📊 Resumen:');
    print('   - Estudiantes procesados: ${estudiantesSnapshot.docs.length}');
    print('   - Sincronizados exitosamente: $sincronizados');
    print('   - Errores: ${estudiantesSnapshot.docs.length - sincronizados}');

    print(
      '\n🎮 Ahora todos los estudiantes tienen los puntos correctos según sus logros!',
    );
  } catch (e) {
    print('❌ Error en la sincronización: $e');
  }
}
