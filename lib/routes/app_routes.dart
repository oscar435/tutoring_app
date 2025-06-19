import 'package:flutter/material.dart';
import 'package:tutoring_app/features/calendario/pages/CalendarioPage.dart';
import 'package:tutoring_app/features/dashboard/pages/RoleSelectorPage.dart';
import 'package:tutoring_app/features/dashboard/pages/SplashPage.dart';
import 'package:tutoring_app/features/dashboard/pages/inicio.dart';
import 'package:tutoring_app/features/auth/pages/login_pages.dart';
import 'package:tutoring_app/features/auth/pages/login_teacher_page.dart';
import 'package:tutoring_app/features/auth/pages/onboarding.dart';
import 'package:tutoring_app/features/auth/pages/register_credentials_page.dart';
import 'package:tutoring_app/features/dashboard/pages/teacher_home_page.dart';

class AppRoutes {
  static const String splash = 'Splash';
  static const String onboarding = '/onboarding';
  static const String roleSelector = '/role-selector';
  static const String login = '/login';
  static const String home = '/home2';
  static const String registerCredentials = '/register_credentials';
  static const String calendario = '/calendario';
  static const String loginTeacher = '/login-teacher';
  static const String teacherHome = '/teacher-home';

  static Map<String, Widget Function(BuildContext)> routes = {
    splash: (_) => const SplashPage(),
    onboarding: (_) => const OnboardingPage(),
    roleSelector: (_) => const RoleSelectorPage(),
    login: (context) => LoginPage(),
    home: (context) => HomePage2(),
    registerCredentials: (_) => const RegisterCredentialsPage(),
    calendario: (context) => const CalendarioPage(),
    loginTeacher: (context) => const LoginTeacherPage(),
    teacherHome: (context) => const TeacherHomePage(),
  };
} 