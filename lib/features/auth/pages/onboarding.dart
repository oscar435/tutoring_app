import 'package:flutter/material.dart';
import 'package:tutoring_app/routes/app_routes.dart';
import 'package:tutoring_app/core/storage/preferencias_usuario.dart';

class OnboardingPage extends StatefulWidget {
  static const String routeName = AppRoutes.onboarding;
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<Map<String, String>> onboardingData = [
    {
      "image": "https://firebasestorage.googleapis.com/v0/b/tutoring-app-96acc.firebasestorage.app/o/Onboarding_pics%2Fconecta_tutores.png?alt=media&token=c979220c-f56e-4ffc-a2fb-5f0066aebcb6",
      "title": "Conecta con Tutores",
      "description": "Agenda tutorías según tu curso y horario.",
    },
    {
      "image": "https://firebasestorage.googleapis.com/v0/b/tutoring-app-96acc.firebasestorage.app/o/Onboarding_pics%2Fpsico.png?alt=media&token=c3cb82a3-e478-47bf-81eb-8bedd8021972",
      "title": "Sesión Psicopedagógica",
      "description": "Atención personalizada con profesionales del área.",
    },
    {
      "image": "https://firebasestorage.googleapis.com/v0/b/tutoring-app-96acc.firebasestorage.app/o/Onboarding_pics%2Fresources.png?alt=media&token=d9ba21cd-41fe-4c10-914c-9a17c24f892b",
      "title": "Materiales y Recursos",
      "description": "Guías, videos y tips sobre estudio y bienestar.",
    },
    {
      "image": "https://firebasestorage.googleapis.com/v0/b/tutoring-app-96acc.firebasestorage.app/o/Onboarding_pics%2Ftalleres.png?alt=media&token=4afb54a8-97e1-4ffa-8a98-b3337404844b",
      "title": "Talleres, Charlas y Campañas",
      "description": "Infórmate de talleres, charlas y eventos que apoyan tu desarrollo académico.",
    },
  ];

  void _nextPage() {
    if (_currentIndex < onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      final prefs = PreferenciasUsuario();
      prefs.onboardingCompletado = true;
      Navigator.pushReplacementNamed(context, AppRoutes.roleSelector);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f7f7),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemCount: onboardingData.length,
              itemBuilder: (_, index) {
                final item = onboardingData[index];
                return Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.network(
                        item['image']!,
                        height: 300,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const CircularProgressIndicator();
                        },
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 100),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        item['title']!,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        item['description']!,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  _currentIndex == onboardingData.length - 1
                      ? 'Comenzar'
                      : 'Siguiente',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
