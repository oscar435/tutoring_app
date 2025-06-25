import 'package:flutter/material.dart';
import 'package:tutoring_app/routes/app_routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tutoring_app/core/storage/preferencias_usuario.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SplashPage extends StatefulWidget {
  static const String routeName = '/';

  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  final prefs = PreferenciasUsuario();
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    _checkNavigation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkNavigation() async {
    await Future.delayed(
      const Duration(milliseconds: 3000),
    ); // Splash de 3 segundos
    final isOnboardingDone = prefs.onboardingCompletado;
    final user = FirebaseAuth.instance.currentUser;

    if (!isOnboardingDone) {
      if (mounted)
        Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
      return;
    }

    if (user == null) {
      if (mounted)
        Navigator.pushReplacementNamed(context, AppRoutes.roleSelector);
      return;
    }

    // La fuente de la verdad para el rol es la colección 'users'
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return; // Comprobar si el widget sigue montado

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final role = userData['role'] as String?;
        final isActive =
            userData['isActive'] ?? true; // Verificar si está activo

        // Verificar si el usuario está activo
        if (!isActive) {
          // Usuario desactivado, cerrar sesión y redirigir
          await FirebaseAuth.instance.signOut();
          await prefs.clearUserSession();
          if (mounted) {
            Navigator.pushReplacementNamed(context, AppRoutes.roleSelector);
          }
          return;
        }

        // Guardar el rol actual en las preferencias locales
        await prefs.setUserRole(role ?? '');

        switch (role) {
          case 'teacher':
            Navigator.pushReplacementNamed(context, AppRoutes.teacherHome);
            break;
          case 'student':
            Navigator.pushReplacementNamed(context, AppRoutes.home);
            break;
          default:
            // Para admin, superAdmin o roles desconocidos, cerrar sesión en móvil y redirigir
            await FirebaseAuth.instance.signOut();
            await prefs.clearUserSession(); // Limpiar datos de sesión
            Navigator.pushReplacementNamed(context, AppRoutes.roleSelector);
            break;
        }
      } else {
        // Si el usuario existe en Auth pero no en la BBDD, es un estado inconsistente.
        await FirebaseAuth.instance.signOut();
        await prefs.clearUserSession();
        Navigator.pushReplacementNamed(context, AppRoutes.roleSelector);
      }
    } catch (e) {
      print('Error verificando usuario en SplashPage: $e');
      // En caso de error, cerrar sesión para evitar un estado inconsistente
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        await prefs.clearUserSession();
        Navigator.pushReplacementNamed(context, AppRoutes.roleSelector);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f7f7),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Image.asset(
                      'assets/logo_transparente.png',
                      height: 180,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Asesoría y apoyo cuando más lo necesitas.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              strokeWidth: 3,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
