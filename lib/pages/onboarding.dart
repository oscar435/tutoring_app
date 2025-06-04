import 'package:flutter/material.dart';
import 'package:tutoring_app/routes/app_routes.dart';

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
      "image": "assets/conecta_tutores.png",
      "title": "Conecta con Tutores",
      "description": "Agenda tutorías según tu curso y horario.",
    },
    {
      "image": "assets/psico.png",
      "title": "Sesión Psicopedagógica",
      "description": "Atención personalizada con profesionales del área.",
    },
    {
      "image": "assets/resources.png",
      "title": "Materiales y Recursos",
      "description": "Guías, videos y tips sobre estudio y bienestar.",
    },
    {
      "image": "assets/talleres.png",
      "title": "Talleres, Charlas y Campañas",
      "description":
          "Infórmate de talleres, charlas y eventos que apoyan tu desarrollo académico.",
    },
  ];

  void _nextPage() {
    if (_currentIndex < onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
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
                      Image.asset(item['image']!, height: 300),
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
