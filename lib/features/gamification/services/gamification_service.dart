import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/logro.dart';
import '../../../core/models/progreso_estudiante.dart';

class GamificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Colecciones
  static const String _logrosCollection = 'logros';
  static const String _progresoCollection = 'progreso_estudiantes';

  // Logros predefinidos
  static final List<Logro> _logrosPredefinidos = [
    Logro(
      id: 'primera_sesion',
      nombre: 'Primera Sesión',
      descripcion: 'Completa tu primera sesión de tutoría',
      icono: '🎯',
      puntosRecompensa: 50,
      tipo: 'sesion',
      meta: 1,
    ),
    Logro(
      id: '5_sesiones',
      nombre: 'Estudiante Dedicado',
      descripcion: 'Completa 5 sesiones de tutoría',
      icono: '📚',
      puntosRecompensa: 100,
      tipo: 'sesion',
      meta: 5,
    ),
    Logro(
      id: '10_sesiones',
      nombre: 'Estudiante Consistente',
      descripcion: 'Completa 10 sesiones de tutoría',
      icono: '🏆',
      puntosRecompensa: 200,
      tipo: 'sesion',
      meta: 10,
    ),
    Logro(
      id: '15_sesiones',
      nombre: 'Estudiante Experto',
      descripcion: 'Completa 15 sesiones de tutoría',
      icono: '👑',
      puntosRecompensa: 300,
      tipo: 'sesion',
      meta: 15,
    ),
    Logro(
      id: '20_sesiones',
      nombre: 'Maestro del Aprendizaje',
      descripcion: 'Completa 20 sesiones de tutoría',
      icono: '💎',
      puntosRecompensa: 500,
      tipo: 'sesion',
      meta: 20,
    ),
    Logro(
      id: 'asistencia_perfecta',
      nombre: 'Asistencia Perfecta',
      descripcion: 'Asiste a 5 sesiones consecutivas',
      icono: '⭐',
      puntosRecompensa: 150,
      tipo: 'asistencia',
      meta: 5,
    ),
    Logro(
      id: 'nivel_5',
      nombre: 'Nivel 5',
      descripcion: 'Alcanza el nivel 5',
      icono: '🚀',
      puntosRecompensa: 300,
      tipo: 'especial',
      meta: 5,
    ),
    Logro(
      id: 'nivel_10',
      nombre: 'Nivel 10',
      descripcion: 'Alcanza el nivel 10',
      icono: '🌟',
      puntosRecompensa: 600,
      tipo: 'especial',
      meta: 10,
    ),
  ];

  // Inicializar logros en Firestore
  Future<void> inicializarLogros() async {
    try {
      for (Logro logro in _logrosPredefinidos) {
        await _firestore
            .collection(_logrosCollection)
            .doc(logro.id)
            .set(logro.toMap());
      }
    } catch (e) {
      print('Error inicializando logros: $e');
    }
  }

  // Obtener todos los logros
  Future<List<Logro>> obtenerLogros() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_logrosCollection)
          .get();

      List<Logro> logros = snapshot.docs
          .map((doc) => Logro.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Si no hay logros, inicializar automáticamente
      if (logros.isEmpty) {
        print('No se encontraron logros, inicializando automáticamente...');
        await inicializarLogros();
        // Obtener logros nuevamente después de inicializar
        QuerySnapshot snapshot2 = await _firestore
            .collection(_logrosCollection)
            .get();
        logros = snapshot2.docs
            .map((doc) => Logro.fromMap(doc.data() as Map<String, dynamic>))
            .toList();
      }

      return logros;
    } catch (e) {
      print('Error obteniendo logros: $e');
      return [];
    }
  }

  // Obtener progreso del estudiante
  Future<ProgresoEstudiante?> obtenerProgresoEstudiante(
    String estudianteId,
  ) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_progresoCollection)
          .doc(estudianteId)
          .get();

      if (doc.exists) {
        return ProgresoEstudiante.fromMap(doc.data() as Map<String, dynamic>);
      } else {
        // Crear progreso inicial si no existe
        ProgresoEstudiante progresoInicial = ProgresoEstudiante(
          estudianteId: estudianteId,
          fechaCreacion: DateTime.now(),
          ultimaActualizacion: DateTime.now(),
        );
        await _firestore
            .collection(_progresoCollection)
            .doc(estudianteId)
            .set(progresoInicial.toMap());
        return progresoInicial;
      }
    } catch (e) {
      print('Error obteniendo progreso: $e');
      return null;
    }
  }

  // Actualizar progreso cuando se completa una sesión
  Future<void> completarSesion(String estudianteId, {String? sesionId}) async {
    try {
      ProgresoEstudiante? progreso = await obtenerProgresoEstudiante(
        estudianteId,
      );
      if (progreso == null) return;

      // Verificar si asistió realmente (si tenemos el sesionId)
      bool asistio = true; // Por defecto asumimos que asistió
      if (sesionId != null) {
        try {
          // Buscar el registro post-sesión para verificar asistencia
          QuerySnapshot registroSnapshot = await _firestore
              .collection('registros_post_sesion')
              .where('sesionId', isEqualTo: sesionId)
              .limit(1)
              .get();

          if (registroSnapshot.docs.isNotEmpty) {
            final registro =
                registroSnapshot.docs.first.data() as Map<String, dynamic>;
            asistio = registro['asistioEstudiante'] ?? true;
            print(
              '📊 Verificando asistencia para sesión $sesionId: ${asistio ? "Asistió" : "No asistió"}',
            );
          }
        } catch (e) {
          print('⚠️ Error verificando asistencia: $e');
        }
      }

      // Actualizar contadores
      int nuevasSesionesCompletadas = progreso.sesionesCompletadas + 1;
      int nuevasSesionesAsistidas =
          progreso.sesionesAsistidas + (asistio ? 1 : 0);
      int nuevosPuntos =
          progreso.puntosTotales +
          (asistio ? 25 : 10); // 25 puntos si asistió, 10 si no

      // Calcular nuevo nivel
      int nuevoNivel = (nuevosPuntos / 100).floor() + 1;

      // Verificar logros desbloqueados
      List<String> logrosAntes = List<String>.from(
        progreso.logrosDesbloqueados,
      );
      List<String> nuevosLogros = await _verificarLogrosDesbloqueados(
        estudianteId,
        nuevasSesionesCompletadas,
        nuevasSesionesAsistidas,
        nuevoNivel,
      );

      // Detectar logros recién desbloqueados
      List<String> logrosNuevos = nuevosLogros
          .where((id) => !logrosAntes.contains(id))
          .toList();

      // Recalcular nivel si sumó puntos extra
      nuevoNivel = (nuevosPuntos / 100).floor() + 1;

      // Actualizar progreso
      ProgresoEstudiante progresoActualizado = progreso.copyWith(
        sesionesCompletadas: nuevasSesionesCompletadas,
        sesionesAsistidas: nuevasSesionesAsistidas,
        puntosTotales: nuevosPuntos,
        nivel: nuevoNivel,
        logrosDesbloqueados: nuevosLogros,
        ultimaActualizacion: DateTime.now(),
      );

      await _firestore
          .collection(_progresoCollection)
          .doc(estudianteId)
          .update(progresoActualizado.toMap());

      print(
        '✅ Gamificación actualizada: ${asistio ? "Asistió" : "No asistió"} - Puntos: $nuevosPuntos, Nivel: $nuevoNivel',
      );
    } catch (e) {
      print('Error completando sesión: $e');
    }
  }

  // Verificar logros desbloqueados
  Future<List<String>> _verificarLogrosDesbloqueados(
    String estudianteId,
    int sesionesCompletadas,
    int sesionesAsistidas,
    int nivel,
  ) async {
    try {
      List<Logro> logros = await obtenerLogros();
      List<String> logrosDesbloqueados = [];

      for (Logro logro in logros) {
        bool desbloqueado = false;

        switch (logro.tipo) {
          case 'sesion':
            desbloqueado = sesionesCompletadas >= logro.meta;
            break;
          case 'asistencia':
            desbloqueado = sesionesAsistidas >= logro.meta;
            break;
          case 'especial':
            desbloqueado = nivel >= logro.meta;
            break;
        }

        if (desbloqueado) {
          logrosDesbloqueados.add(logro.id);
        }
      }

      return logrosDesbloqueados;
    } catch (e) {
      print('Error verificando logros: $e');
      return [];
    }
  }

  // Obtener ranking de estudiantes
  Future<List<ProgresoEstudiante>> obtenerRanking() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_progresoCollection)
          .orderBy('puntosTotales', descending: true)
          .limit(10)
          .get();

      return snapshot.docs
          .map(
            (doc) =>
                ProgresoEstudiante.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      print('Error obteniendo ranking: $e');
      return [];
    }
  }

  // Sincronizar progreso con sesiones existentes
  Future<void> sincronizarProgresoConSesiones(String estudianteId) async {
    try {
      // Obtener sesiones completadas del estudiante
      QuerySnapshot sesionesSnapshot = await _firestore
          .collection('sesiones_tutoria')
          .where('estudianteId', isEqualTo: estudianteId)
          .where('estado', isEqualTo: 'completada')
          .get();

      int sesionesCompletadas = sesionesSnapshot.docs.length;
      int sesionesAsistidas = 0;

      // Verificar asistencia real para cada sesión
      for (var sesionDoc in sesionesSnapshot.docs) {
        final sesionId = sesionDoc.id;

        // Buscar registro post-sesión para verificar asistencia
        QuerySnapshot registroSnapshot = await _firestore
            .collection('registros_post_sesion')
            .where('sesionId', isEqualTo: sesionId)
            .limit(1)
            .get();

        if (registroSnapshot.docs.isNotEmpty) {
          final registro =
              registroSnapshot.docs.first.data() as Map<String, dynamic>;
          bool asistio = registro['asistioEstudiante'] ?? true;
          if (asistio) {
            sesionesAsistidas++;
          }
        } else {
          // Si no hay registro post-sesión, asumimos que asistió
          sesionesAsistidas++;
        }
      }

      if (sesionesCompletadas > 0) {
        // Calcular puntos basados en sesiones existentes
        int puntosTotales =
            sesionesAsistidas * 25 +
            (sesionesCompletadas - sesionesAsistidas) * 10;
        int nivel = (puntosTotales / 100).floor() + 1;

        // Verificar logros desbloqueados
        List<String> logrosDesbloqueados = await _verificarLogrosDesbloqueados(
          estudianteId,
          sesionesCompletadas,
          sesionesAsistidas,
          nivel,
        );

        // Actualizar progreso
        ProgresoEstudiante progresoActualizado = ProgresoEstudiante(
          estudianteId: estudianteId,
          puntosTotales: puntosTotales,
          nivel: nivel,
          sesionesCompletadas: sesionesCompletadas,
          sesionesAsistidas: sesionesAsistidas,
          logrosDesbloqueados: logrosDesbloqueados,
          fechaCreacion: DateTime.now(),
          ultimaActualizacion: DateTime.now(),
        );

        await _firestore
            .collection(_progresoCollection)
            .doc(estudianteId)
            .set(progresoActualizado.toMap());

        print(
          '✅ Progreso sincronizado: $sesionesCompletadas sesiones completadas, $sesionesAsistidas asistidas, $puntosTotales puntos, Nivel $nivel',
        );
      }
    } catch (e) {
      print('❌ Error sincronizando progreso: $e');
    }
  }
}
