import 'package:tutoring_app/firebase_options.dart';
import 'package:tutoring_app/pages/RoleSelectorPage.dart';
import 'package:tutoring_app/pages/SplashPage.dart';
import 'package:tutoring_app/pages/inicio.dart';
import 'package:tutoring_app/pages/login_pages.dart';
import 'package:tutoring_app/pages/onboarding.dart';
import 'package:tutoring_app/pages/register_credentials_page.dart';
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
      initialRoute: SplashPage.routeName, //prefs.ultimaPagina,
      routes: {
        SplashPage.routeName: (_) => const SplashPage(),
        '/onboarding': (_) => const OnboardingPage(),
        '/role-selector': (_) => const RoleSelectorPage(),
        LoginPage.routeName: (context) => LoginPage(),
        HomePage2.routeName: (Context) => HomePage2(),
        RegisterCredentialsPage.routeName: (_) =>
            const RegisterCredentialsPage(),
      },
    );
  }
}
