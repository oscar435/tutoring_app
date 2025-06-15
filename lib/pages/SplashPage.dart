import 'package:flutter/material.dart';
import 'package:tutoring_app/routes/app_routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tutoring_app/preferences/pref_usuarios.dart';

class SplashPage extends StatefulWidget {
  static const String routeName = AppRoutes.splash;

  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final prefs = PreferenciasUsuario();

  @override
  void initState() {
    super.initState();
    _checkNavigation();
  }

  Future<void> _checkNavigation() async {
    await Future.delayed(const Duration(milliseconds: 1200)); // Breve splash
    final isOnboardingDone = prefs.onboardingCompletado;
    final user = FirebaseAuth.instance.currentUser;
    if (!isOnboardingDone) {
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
    } else if (user == null) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
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
            const Spacer(),
            Image.asset('assets/logo_transparente.png', height: 250),
            const SizedBox(height: 20),
            const Text(
              'Asesoría y apoyo cuando más lo necesitas.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
