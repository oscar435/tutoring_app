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

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
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
    await Future.delayed(const Duration(milliseconds: 3000)); // Splash de 3 segundos
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
