import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Método para crear una cuenta nueva
  Future createAccount(String correo, String contrasenia) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: correo, password: contrasenia);

      // Puedes enviar verificación al correo si lo deseas:
      // await userCredential.user?.sendEmailVerification();

      print("Usuario creado: ${userCredential.user}");
      return userCredential.user?.uid; // Retorna el UID del usuario
    } on FirebaseAuthException catch (e) {
      // Control de errores específicos
      if (e.code == 'weak-password') {
        print('La contraseña es demasiado débil');
        return 1;
      } else if (e.code == 'email-already-in-use') {
        print('El correo ya está en uso');
        return 2;
      } else {
        print('Error de Firebase desconocido: ${e.code}');
      }
    } catch (e) {
      print('Error inesperado: $e');
    }

    // Retorno en caso de error no controlado
    return null;
  }

  // Método para iniciar sesión con email y contraseña
  Future signInEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user?.uid != null) {
        return user?.uid;
      }
    } on FirebaseAuthException catch (e) {
      // Control de errores específicos
      if (e.code == 'user-not-found') {
        print('No existe un usuario con ese correo');
        return 1;
      } else if (e.code == 'wrong-password') {
        print('Contraseña incorrecta');
        return 2;
      } else {
        print('Error de inicio de sesión: ${e.code}');
      }
    } catch (e) {
      print('Error inesperado durante el login: $e');
    }

    // Retorno en caso de error no controlado
    return null;
  }
}
