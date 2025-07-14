import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:open_file/open_file.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class MaterialEducativoPage extends StatefulWidget {
  const MaterialEducativoPage({super.key});

  @override
  State<MaterialEducativoPage> createState() => _MaterialEducativoPageState();
}

class _MaterialEducativoPageState extends State<MaterialEducativoPage> {
  final storageRef = FirebaseStorage.instance.ref('material_educativo');
  bool _loading = true;
  Map<String, List<Reference>> _materiales = {
    'Programación': [],
    'Matemáticas': [],
    'Otros': [],
  };

  @override
  void initState() {
    super.initState();
    _fetchMateriales();
  }

  Future<void> _fetchMateriales() async {
    final allFiles = await storageRef.listAll();
    final Map<String, List<Reference>> temp = {
      'Programación': [],
      'Matemáticas': [],
      'Otros': [],
    };
    for (final ref in allFiles.items) {
      final name = ref.name.toLowerCase();
      if (name.contains('java') || name.contains('programar')) {
        temp['Programación']!.add(ref);
      } else if (name.contains('calculo') || name.contains('mate')) {
        temp['Matemáticas']!.add(ref);
      } else {
        temp['Otros']!.add(ref);
      }
    }
    setState(() {
      _materiales = temp;
      _loading = false;
    });
  }

  Future<bool> _checkStoragePermission() async {
    final status = await Permission.storage.request();
    if (status.isGranted) {
      return true;
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Permiso de almacenamiento denegado. No se puede continuar.',
            ),
          ),
        );
      }
      return false;
    }
  }

  Future<void> _verPDF(Reference ref) async {
    if (!await _checkStoragePermission()) return;
    try {
      final url = await ref.getDownloadURL();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${ref.name}');
      if (!await file.exists()) {
        await Dio().download(url, file.path);
      }
      final result = await OpenFile.open(file.path);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No se pudo abrir el PDF. ¿Tienes un visor de PDF instalado?',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al abrir el PDF: $e')));
      }
    }
  }

  Future<void> _descargarPDF(Reference ref) async {
    if (!await _checkStoragePermission()) return;
    try {
      final url = await ref.getDownloadURL();
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${ref.name}');
      await Dio().download(url, file.path);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Descargado en: ${file.path}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al descargar el PDF: $e')),
        );
      }
    }
  }

  Widget _buildMaterialList(String categoria, List<Reference> archivos) {
    if (archivos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          'No hay material disponible en este tema.',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }
    return Column(
      children: archivos.map((ref) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Image.asset(
              'assets/pdf_icon.png',
              width: 36,
              height: 36,
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.picture_as_pdf, color: Colors.red, size: 36),
            ),
            title: Text(
              ref.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility, color: Colors.purple),
                  onPressed: () => _verPDF(ref),
                  tooltip: 'Ver',
                ),
                IconButton(
                  icon: const Icon(Icons.download_rounded, color: Colors.green),
                  onPressed: () => _descargarPDF(ref),
                  tooltip: 'Descargar',
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Material Educativo')),
      backgroundColor: const Color(0xfff7f7f7),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Text(
                      'Programación',
                      style: TextStyle(
                        color: Colors.purple[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  _buildMaterialList(
                    'Programación',
                    _materiales['Programación']!,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Text(
                      'Matemáticas',
                      style: TextStyle(
                        color: Colors.purple[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  _buildMaterialList(
                    'Matemáticas',
                    _materiales['Matemáticas']!,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Text(
                      'Otros',
                      style: TextStyle(
                        color: Colors.purple[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  _buildMaterialList('Otros', _materiales['Otros']!),
                  const SizedBox(height: 24),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '¡Más material educativo próximamente!',
                        style: TextStyle(
                          color: Colors.purple,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
