import 'package:shared_preferences/shared_preferences.dart';

class PreferenciasUsuario {
  //generar instancia

  static late SharedPreferences _prefs;

  //inicializar preferencias
  static Future init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String get ultimaPagina {
    return _prefs.getString('ultimaPagina') ?? 'Splash';
  }

  set ultimaPagina(String value) {
    _prefs.setString('ultimaPagina', value);
  }

  // Preferencia para saber si el onboarding ya fue completado
  bool get onboardingCompletado {
    return _prefs.getBool('onboardingCompletado') ?? false;
  }

  set onboardingCompletado(bool value) {
    _prefs.setBool('onboardingCompletado', value);
  }

  // Guardar y obtener el rol del usuario
  String get userRole {
    return _prefs.getString('userRole') ?? '';
  }

  Future<void> setUserRole(String role) async {
    await _prefs.setString('userRole', role);
  }

  // Limpiar todas las preferencias de la sesión de usuario
  Future<void> clearUserSession() async {
    // No borramos 'onboardingCompletado' para que no se muestre de nuevo
    await _prefs.remove('ultimaPagina');
    await _prefs.remove('userRole');
    // Añadir aquí cualquier otra preferencia de usuario que se deba limpiar al cerrar sesión
  }
}
