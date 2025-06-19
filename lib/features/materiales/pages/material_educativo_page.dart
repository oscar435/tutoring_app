import 'package:flutter/material.dart';

class MaterialEducativoPage extends StatelessWidget {
  const MaterialEducativoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final materiales = [
      {
        'titulo': 'Cálculo Diferencial - Apuntes PDF',
        'tipo': 'PDF',
      },
      {
        'titulo': 'Introducción a la Programación - Video',
        'tipo': 'Video',
      },
      {
        'titulo': 'Guía de Física Básica',
        'tipo': 'PDF',
      },
      {
        'titulo': 'Taller de Álgebra - Presentación',
        'tipo': 'PPT',
      },
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Material Educativo')),
      backgroundColor: const Color(0xfff7f7f7),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: materiales.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final mat = materiales[index];
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Icon(
                mat['tipo'] == 'PDF'
                    ? Icons.picture_as_pdf
                    : mat['tipo'] == 'Video'
                        ? Icons.play_circle_fill
                        : Icons.insert_drive_file,
                color: Colors.orange,
                size: 32,
              ),
              title: Text(mat['titulo'] ?? ''),
              subtitle: Text(mat['tipo'] ?? ''),
              trailing: IconButton(
                icon: const Icon(Icons.visibility, color: Colors.blue),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Función de visualizar aún no implementada')),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
} 