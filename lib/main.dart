import 'package:tutoring_app/firebase_options.dart';
import 'package:tutoring_app/preferences/pref_usuarios.dart';
import 'package:tutoring_app/routes/app_routes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    // Verificar si hay usuario logueado
    final user = FirebaseAuth.instance.currentUser;
    String initialRoute;
    
    if (user != null) {
      // Si hay usuario logueado, ir directo al home
      initialRoute = AppRoutes.home;
    } else {
      // Si no hay usuario, ir al login
      initialRoute = AppRoutes.login;
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      routes: AppRoutes.routes,
    );
  }
}
