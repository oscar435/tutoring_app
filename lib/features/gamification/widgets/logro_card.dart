import 'package:flutter/material.dart';
import '../../../core/models/logro.dart';

class LogroCard extends StatelessWidget {
  final Logro logro;
  final bool desbloqueado;

  const LogroCard({Key? key, required this.logro, required this.desbloqueado})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: desbloqueado ? 4 : 2,
      color: desbloqueado ? Colors.white : Colors.grey[100],
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: desbloqueado
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue, Colors.purple],
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono del logro
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: desbloqueado ? Colors.white : Colors.grey[300],
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    logro.icono,
                    style: TextStyle(
                      fontSize: 30,
                      color: desbloqueado ? Colors.blue : Colors.grey[600],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Nombre del logro
              Flexible(
                child: Text(
                  logro.nombre,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: desbloqueado ? Colors.white : Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),

              // Descripción
              Flexible(
                child: Text(
                  logro.descripcion,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: desbloqueado ? Colors.white70 : Colors.grey[600],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),

              // Puntos de recompensa

              // Estado del logro
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: desbloqueado ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  desbloqueado ? 'Desbloqueado' : 'Bloqueado',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
