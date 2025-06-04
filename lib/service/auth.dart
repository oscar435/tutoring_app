import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Método para crear una cuenta nueva
  Future createAccount(String correo, String contrasenia, {bool isTeacher = false}) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: correo, password: contrasenia);

      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': correo,
          'isTeacher': isTeacher,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      print("Usuario creado: ${userCredential.user}");
      return userCredential.user?.uid;
    } on FirebaseAuthException catch (e) {
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
    return null;
  }

  // Método para iniciar sesión con email y contraseña
  Future signInEmailAndPassword(String email, String password, {bool requireTeacher = false}) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user?.uid != null) {
        // Verificar el tipo de usuario en Firestore
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user!.uid).get();
        
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          bool isTeacher = userData['isTeacher'] ?? false;

          if (requireTeacher && !isTeacher) {
            await _auth.signOut();
            return 3; // Código de error para usuario no autorizado
          }
          
          return user.uid;
        }
      }
    } on FirebaseAuthException catch (e) {
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
    return null;
  }
}
