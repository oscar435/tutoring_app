import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutoring_app/features/notificaciones/services/notificacion_service.dart';

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

        // Datos básicos del usuario
        final userData = {
          'email': correo,
          'createdAt': FieldValue.serverTimestamp(),
          'emailVerified': false,
        };

        // Guardar en la colección correspondiente
        if (isTeacher) {
          await _firestore.collection('tutores').doc(userCredential.user!.uid).set(userData);
        } else {
          await _firestore.collection('estudiantes').doc(userCredential.user!.uid).set(userData);
        }

        // También guardar referencia en users
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': correo,
          'isTeacher': isTeacher,
          'createdAt': FieldValue.serverTimestamp(),
        });

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

  // Método para iniciar sesión con email y contraseña
  Future signInEmailAndPassword(String email, String password, {bool requireTeacher = false}) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      
      if (user?.uid != null) {
        // Primero verificar el tipo de usuario
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user!.uid).get();
        
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          bool isTeacher = (userData['role'] == 'teacher');
          bool isActive = (userData['isActive'] ?? true); // Por defecto activo

          // Verificar si el usuario está activo
          if (!isActive) {
            await _auth.signOut();
            return 9; // Nuevo código de error: "Cuenta desactivada"
          }

          // Si se requiere ser profesor pero no lo es, denegar acceso.
          if (requireTeacher && !isTeacher) {
            await _auth.signOut();
            return 3; // Código de error para rol incorrecto (no es profesor)
          }

          // Si NO se requiere ser profesor (login de estudiante) pero el rol SÍ es de profesor, denegar.
          if (!requireTeacher && isTeacher) {
            await _auth.signOut();
            return 5; // Nuevo código de error: "Debe iniciar sesión como profesor"
          }

          // Obtener datos específicos según el tipo de usuario
          DocumentSnapshot specificDoc;
          if (isTeacher) {
            specificDoc = await _firestore.collection('tutores').doc(user.uid).get();
          } else {
            specificDoc = await _firestore.collection('estudiantes').doc(user.uid).get();
          }

          if (!specificDoc.exists) {
            await _auth.signOut();
            return null;
          }

          final bool isVerifiedInDb = (specificDoc.data() as Map<String, dynamic>?)?['emailVerified'] ?? false;

          // Solo verificar email si NO es profesor.
          // Permitir el acceso si el correo está verificado en Firebase Auth O en nuestra base de datos (por un admin).
          if (!isTeacher && !user.emailVerified && !isVerifiedInDb) {
            await _auth.signOut();
            return 4; // Código para correo no verificado
          }
          
          // ✅ ACTUALIZAR FCM TOKEN DESPUÉS DEL LOGIN EXITOSO
          try {
            await NotificacionService().updateFCMTokenAfterLogin();
          } catch (e) {
            print('⚠️ Error actualizando FCM token después del login: $e');
            // No fallar el login por este error
          }
          
          return user.uid;
        } else {
          await _auth.signOut();
          return null;
        }
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
        return 1;
        case 'user-disabled':
          return 5; // Cuenta deshabilitada
        case 'too-many-requests':
          return 6; // Demasiados intentos
        case 'invalid-email':
          return 7; // Email inválido
        case 'network-request-failed':
          return 8; // Error de red
        default:
          return null; // Error no manejado
      }
    } catch (e) {
      return null; // Error general
    }
  }

  // Método para obtener el usuario actual
  User? getCurrentUser() {
    return _auth.currentUser;
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

  // Método para cerrar sesión
  Future<void> signOut() async {
    try {
      // Limpiar FCM token antes de hacer logout
      await NotificacionService().clearFCMTokenOnLogout();
      
      // Hacer logout de Firebase Auth
      await _auth.signOut();
      print('✅ Logout exitoso');
    } catch (e) {
      print('❌ Error durante logout: $e');
      // Intentar logout de Firebase Auth aunque falle la limpieza del token
      await _auth.signOut();
    }
  }
}
