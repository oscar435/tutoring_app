import 'package:flutter/material.dart';
import 'package:tutoring_app/routes/app_routes.dart';

class RoleSelectorPage extends StatelessWidget {
  static const String routeName = AppRoutes.roleSelector;
  const RoleSelectorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f7f7),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 64.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo_transparente.png', height: 250),
            const SizedBox(height: 40),

            // Botón Estudiante
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.registerCredentials);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white, // color del texto
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size.fromHeight(60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Ingresar como Estudiante',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),

            // Botón Profesor
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.loginTeacher);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size.fromHeight(60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Ingresar como Profesor',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 40),

            // Enlace a iniciar sesión
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.login);
              },
              child: const Text(
                '¿Ya tienes una cuenta? Inicia sesión',
                style: TextStyle(
                  color: Colors.blueAccent,
                  decoration: TextDecoration.underline,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
