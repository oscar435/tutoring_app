import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Método para verificar si el correo institucional es válido
  Future<bool> isValidInstitutionalEmail(String email) async {
    try {
      // Extraer el código de estudiante del correo
      final regex = RegExp(r'^(\d{10})@unfv\.edu\.pe$');
      final match = regex.firstMatch(email);
      
      if (match == null) return false;
      
      final studentCode = match.group(1);
      
      // Verificar si el código existe en la colección de códigos válidos
      final doc = await _firestore
          .collection('valid_student_codes')
          .doc(studentCode)
          .get();
      
      return doc.exists;
    } catch (e) {
      print('Error verificando correo institucional: $e');
      return false;
    }
  }

  // Método para crear una cuenta nueva y enviar verificación
  Future<Map<String, dynamic>> createAccount(String correo, String contrasenia, {bool isTeacher = false}) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: correo, password: contrasenia);

      if (userCredential.user != null) {
        // Enviar correo de verificación
        await userCredential.user!.sendEmailVerification();

        // Guardar datos en Firestore
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': correo,
          'isTeacher': isTeacher,
          'createdAt': FieldValue.serverTimestamp(),
          'emailVerified': false,
        }, SetOptions(merge: true));

        return {
          'success': true,
          'user': userCredential.user?.uid,
          'message': 'Por favor, verifica tu correo electrónico'
        };
      }

      return {
        'success': false,
        'message': 'Error al crear la cuenta'
      };
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return {
          'success': false,
          'code': 1,
          'message': 'La contraseña es demasiado débil'
        };
      } else if (e.code == 'email-already-in-use') {
        return {
          'success': false,
          'code': 2,
          'message': 'El correo ya está en uso'
        };
      }
      return {
        'success': false,
        'message': 'Error: ${e.message}'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error inesperado: $e'
      };
    }
  }

  // Método para verificar si el correo está verificado
  Future<bool> isEmailVerified() async {
    User? user = _auth.currentUser;
    await user?.reload();
    return user?.emailVerified ?? false;
  }

  // Método para reenviar el correo de verificación
  Future<bool> resendVerificationEmail() async {
    try {
      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        return true;
      }
      return false;
    } catch (e) {
      print('Error al reenviar correo: $e');
      return false;
    }
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
        // Verificar si el correo está verificado
        if (!user!.emailVerified) {
          await _auth.signOut();
          return 4; // Código para correo no verificado
        }

        // Verificar el tipo de usuario en Firestore
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        
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
        return 1;
      } else if (e.code == 'wrong-password') {
        return 2;
      }
    }
    return null;
  }

  // Método para obtener el usuario actual
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}
