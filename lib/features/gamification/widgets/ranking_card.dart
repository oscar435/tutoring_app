import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/progreso_estudiante.dart';

Future<String> obtenerNombreEstudiante(String estudianteId) async {
  final doc = await FirebaseFirestore.instance
      .collection('estudiantes')
      .doc(estudianteId)
      .get();
  if (doc.exists) {
    final data = doc.data()!;
    return '${data['nombre'] ?? ''} ${data['apellidos'] ?? ''}'.trim();
  }
  return 'Estudiante';
}

class RankingCard extends StatelessWidget {
  final ProgresoEstudiante progreso;
  final int posicion;
  final bool esUsuarioActual;

  const RankingCard({
    Key? key,
    required this.progreso,
    required this.posicion,
    required this.esUsuarioActual,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: esUsuarioActual ? 4 : 2,
      color: esUsuarioActual ? Colors.blue[50] : Colors.white,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getColorForPosition(posicion),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              '$posicion',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        title: FutureBuilder<String>(
          future: obtenerNombreEstudiante(progreso.estudianteId),
          builder: (context, snapshot) {
            final nombre = snapshot.data ?? 'Estudiante';
            return Row(
              children: [
                Text(
                  nombre,
                  style: TextStyle(
                    fontWeight: esUsuarioActual
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: esUsuarioActual ? Colors.blue : Colors.black,
                  ),
                ),
                if (esUsuarioActual) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'TÚ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        subtitle: Text(
          'Nivel ${progreso.nivel} • ${progreso.puntosTotales} puntos',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${progreso.puntosTotales}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.blue,
              ),
            ),
            Text(
              'pts',
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForPosition(int posicion) {
    switch (posicion) {
      case 1:
        return Colors.amber; // Oro
      case 2:
        return Colors.grey[400]!; // Plata
      case 3:
        return Colors.orange[700]!; // Bronce
      default:
        return Colors.blue;
    }
  }
}
