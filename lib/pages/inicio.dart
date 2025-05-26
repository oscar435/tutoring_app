import 'package:flutter/material.dart';

class HomePage2 extends StatelessWidget {
  static const routeName = '/home2';

  const HomePage2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f7f7),
      appBar: AppBar(title: const Text("Página de Inicio")),
      body: const Center(
        child: Text("¡Bienvenido a la app!", style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
