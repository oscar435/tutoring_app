import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/gamification_service.dart';
import '../../../core/models/logro.dart';
import '../../../core/models/progreso_estudiante.dart';
import '../widgets/logro_card.dart';
import '../widgets/progress_card.dart';
import '../widgets/ranking_card.dart';

class StudentGamificationPage extends StatefulWidget {
  const StudentGamificationPage({Key? key}) : super(key: key);

  @override
  State<StudentGamificationPage> createState() =>
      _StudentGamificationPageState();
}

class _StudentGamificationPageState extends State<StudentGamificationPage>
    with SingleTickerProviderStateMixin {
  final GamificationService _gamificationService = GamificationService();
  late TabController _tabController;

  ProgresoEstudiante? _progreso;
  List<Logro> _logros = [];
  List<ProgresoEstudiante> _ranking = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _cargarDatos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Sincronizar progreso con sesiones existentes
        await _gamificationService.sincronizarProgresoConSesiones(user.uid);

        final progreso = await _gamificationService.obtenerProgresoEstudiante(
          user.uid,
        );
        final logros = await _gamificationService.obtenerLogros();
        final ranking = await _gamificationService.obtenerRanking();

        print('Logros cargados: ${logros.length}');
        print(
          'Progreso: ${progreso?.puntosTotales} puntos, Nivel ${progreso?.nivel}',
        );

        setState(() {
          _progreso = progreso;
          _logros = logros;
          _ranking = ranking;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error cargando datos: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎮 Gamificación'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _cargarDatos();
            },
            tooltip: 'Refrescar datos',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.emoji_events), text: 'Progreso'),
            Tab(icon: Icon(Icons.star), text: 'Logros'),
            Tab(icon: Icon(Icons.leaderboard), text: 'Ranking'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProgresoTab(),
                _buildLogrosTab(),
                _buildRankingTab(),
              ],
            ),
    );
  }

  Widget _buildProgresoTab() {
    if (_progreso == null) {
      return const Center(child: Text('No se pudo cargar el progreso'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ProgressCard(progreso: _progreso!),
          const SizedBox(height: 20),
          _buildEstadisticas(),
        ],
      ),
    );
  }

  Widget _buildLogrosTab() {
    print('Construyendo pestaña de logros con ${_logros.length} logros');

    if (_logros.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_border, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No hay logros disponibles',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Los logros se cargarán automáticamente',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: _logros.length,
      itemBuilder: (context, index) {
        final logro = _logros[index];
        final desbloqueado =
            _progreso?.logrosDesbloqueados.contains(logro.id) ?? false;
        print(
          'Renderizando logro: ${logro.nombre} - Desbloqueado: $desbloqueado',
        );
        return LogroCard(logro: logro, desbloqueado: desbloqueado);
      },
    );
  }

  Widget _buildRankingTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _ranking.length,
      itemBuilder: (context, index) {
        final progreso = _ranking[index];
        return RankingCard(
          progreso: progreso,
          posicion: index + 1,
          esUsuarioActual:
              progreso.estudianteId == FirebaseAuth.instance.currentUser?.uid,
        );
      },
    );
  }

  Widget _buildEstadisticas() {
    if (_progreso == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Estadísticas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildEstadisticaItem(
              'Sesiones Completadas',
              _progreso!.sesionesCompletadas.toString(),
            ),
            _buildEstadisticaItem(
              'Sesiones Asistidas',
              _progreso!.sesionesAsistidas.toString(),
            ),

            _buildEstadisticaItem(
              'Logros Desbloqueados',
              _progreso!.logrosDesbloqueados.length.toString(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadisticaItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}
