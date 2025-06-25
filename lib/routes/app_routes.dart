import 'package:flutter/material.dart';
import '../features/dashboard/pages/inicio.dart';
import '../features/dashboard/pages/teacher_home_page.dart';
import '../features/dashboard/pages/RoleSelectorPage.dart';
import '../features/dashboard/pages/SplashPage.dart';
import '../features/auth/pages/login_pages.dart';
import '../features/auth/pages/login_teacher_page.dart';
import '../features/auth/pages/onboarding.dart';
import '../features/auth/pages/register_credentials_page.dart';
import '../features/calendario/pages/CalendarioPage.dart';
import '../features/materiales/pages/material_educativo_page.dart';
import '../features/tutorias/pages/TodasTutoriasPage.dart';
import '../features/perfil/pages/student_profile_page.dart';
import '../features/perfil/pages/tutor_profile_page.dart';
import '../features/admin/pages/admin_dashboard_page.dart';
import '../features/admin/pages/user_management_page.dart';
import '../features/admin/pages/audit_logs_page.dart';

class AppRoutes {
  // Rutas principales
  static const String splash = '/';
  static const String roleSelector = '/role-selector';
  static const String login = '/login';
  static const String home = '/home2';

  // Rutas de dashboard
  static const String teacherHome = '/teacher-home';
  static const String studentHome = '/student-home';
  static const String adminDashboard = '/admin-dashboard';

  // Rutas de funcionalidades
  static const String calendario = '/calendario';
  static const String calendar = '/calendar';
  static const String materials = '/materials';
  static const String scheduleTutoring = '/schedule-tutoring';
  static const String allTutoring = '/all-tutoring';
  static const String editAvailability = '/edit-availability';

  // Rutas de perfil
  static const String studentProfile = '/student-profile';
  static const String tutorProfile = '/tutor-profile';

  // Rutas de administración
  static const String userManagement = '/user-management';
  static const String auditLogs = '/audit-logs';

  // Rutas de autenticación específicas
  static const String loginTeacher = '/login-teacher';
  static const String onboarding = '/onboarding';
  static const String registerCredentials = '/register-credentials';

  static Map<String, Widget Function(BuildContext)> routes = {
    splash: (context) => const SplashPage(),
    roleSelector: (context) => const RoleSelectorPage(),
    login: (context) => LoginPage(),
    home: (context) => HomePage2(),
    onboarding: (context) => const OnboardingPage(),
    registerCredentials: (context) => const RegisterCredentialsPage(),
    calendario: (context) => const CalendarioPage(),
    loginTeacher: (context) => const LoginTeacherPage(),
    teacherHome: (context) => const TeacherHomePage(),
    studentHome: (context) => const HomePage2(),
    adminDashboard: (context) => const AdminDashboardPage(),
    calendar: (context) => const CalendarioPage(),
    materials: (context) => const MaterialEducativoPage(),
    scheduleTutoring: (context) => _buildErrorPage(
      'Agendar Tutoría',
      'Esta página requiere parámetros específicos (tutorId, estudianteId).\nUse la navegación desde la aplicación.',
    ),
    allTutoring: (context) => const TodasTutoriasPage(),
    editAvailability: (context) => _buildErrorPage(
      'Editar Disponibilidad',
      'Esta página requiere parámetros específicos (tutorId).\nUse la navegación desde la aplicación.',
    ),
    studentProfile: (context) => const StudentProfilePage(),
    tutorProfile: (context) => const TutorProfilePage(),
    userManagement: (context) => const UserManagementPage(),
    auditLogs: (context) => const AuditLogsPage(),
  };

  // Página de error para rutas que requieren parámetros
  static Widget _buildErrorPage(String title, String message) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
