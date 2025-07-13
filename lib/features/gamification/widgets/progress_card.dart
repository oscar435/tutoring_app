import 'package:flutter/material.dart';
import '../../../core/models/progreso_estudiante.dart';

class ProgressCard extends StatelessWidget {
  final ProgresoEstudiante progreso;

  const ProgressCard({Key? key, required this.progreso}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nivel ${progreso.nivel}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${progreso.puntosTotales} puntos',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    '${progreso.nivel}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Progreso al siguiente nivel',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    Text(
                      '${progreso.puntosTotales % 100}/100',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progreso.progresoNivel,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                  minHeight: 8,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Sesiones',
                  progreso.sesionesCompletadas.toString(),
                ),
                _buildStatItem(
                  'Asistencias',
                  progreso.sesionesAsistidas.toString(),
                ),
                _buildStatItem(
                  'Logros',
                  progreso.logrosDesbloqueados.length.toString(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
