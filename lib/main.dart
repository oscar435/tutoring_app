import 'package:tutoring_app/firebase_options.dart';
import 'package:tutoring_app/preferences/pref_usuarios.dart';
import 'package:tutoring_app/routes/app_routes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PreferenciasUsuario.init(); //importante para inicialiar la app
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final prefs = PreferenciasUsuario();

  @override
  Widget build(BuildContext context) {
    // Siempre iniciar en SplashPage
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
    );
  }
}
