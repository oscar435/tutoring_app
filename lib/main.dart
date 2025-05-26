import 'package:tutoring_app/firebase_options.dart';
import 'package:tutoring_app/pages/login_pages.dart';
//import 'package:app3/pages/home1_pages.dart';
//import 'package:app3/pages/onboarding.dart';
//import 'package:app3/pages/home_pages.dart';
//import 'package:app3/pages/login_pages.dart';
//import 'package:app3/pages/registro_pages.dart';
//import 'package:app3/pages/screens/age_screen.dart';
//import 'package:app3/pages/screens/alias_screen.dart';
//import 'package:app3/pages/screens/eleccion_categoria.dart';
//import 'package:app3/pages/screens/welcome_screen.dart';
import 'package:tutoring_app/preferences/pref_usuarios.dart';
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: prefs.ultimaPagina, //prefs.ultimaPagina,
      routes: {LoginPage.routename: (context) => const LoginPage()},
    );
  }
}
