import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:tutoring_app/features/auth/pages/register_credentials_page.dart';
import 'package:tutoring_app/core/utils/snackbar.dart';
import 'package:tutoring_app/features/auth/services/auth_service.dart';
import 'package:tutoring_app/features/dashboard/pages/RoleSelectorPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tutoring_app/routes/app_routes.dart';

class LoginPage extends StatefulWidget {
  static const routeName = '/login';
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormBuilderState>();
  final AuthService _auth = AuthService();

  Future<void> _resetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      showSnackBar(
        context,
        "Se ha enviado un correo para restablecer tu contraseña",
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        showSnackBar(context, "No existe una cuenta con ese correo");
      } else {
        showSnackBar(context, "Error al enviar el correo de restablecimiento");
      }
    }
  }

  void _showResetPasswordDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restablecer Contraseña'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'Correo electrónico',
            prefixIcon: Icon(Icons.email),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (emailController.text.isNotEmpty) {
                _resetPassword(emailController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f7f7),
      appBar: AppBar(title: const Text('Inicio de Sesión')),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: FormBuilder(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 30),
                Image.asset('assets/logo_transparente.png', height: 200),
                const SizedBox(height: 20),
                FormBuilderTextField(
                  name: 'email',
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(
                      errorText: 'El campo email es requerido',
                    ),
                    FormBuilderValidators.email(
                      errorText: 'Ingresa un email válido',
                    ),
                  ]),
                ),
                const SizedBox(height: 15),
                FormBuilderTextField(
                  name: 'password',
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: FormBuilderValidators.required(
                    errorText: 'El campo contraseña es requerido',
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showResetPasswordDialog,
                    child: const Text(
                      '¿Olvidaste tu contraseña?',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                  ),
                  onPressed: () async {
                    _formKey.currentState?.save();
                    if (_formKey.currentState?.validate() == true) {
                      final v = _formKey.currentState?.value;

                      var result = await _auth.signInEmailAndPassword(
                        v?['email'],
                        v?['password'],
                      );

                      if (mounted) {
                        if (result is int) {
                          if (result == 1) {
                            showSnackBar(
                              context,
                              "Correo o contraseña incorrectos",
                            );
                          } else if (result == 3) {
                            showSnackBar(
                              context,
                              "Esta cuenta no tiene permisos de estudiante",
                            );
                          } else if (result == 4) {
                            showSnackBar(
                              context,
                              "Debes verificar tu correo antes de continuar",
                            );
                          } else if (result == 5) {
                            showSnackBar(
                              context,
                              "Cuenta de profesor detectada. Inicie sesión desde el portal de profesores.",
                            );
                          } else if (result == 6) {
                            showSnackBar(
                              context,
                              "Demasiados intentos fallidos. Intenta más tarde",
                            );
                          } else if (result == 7) {
                            showSnackBar(context, "Formato de email inválido");
                          } else if (result == 8) {
                            showSnackBar(
                              context,
                              "Error de conexión. Verifica tu internet",
                            );
                          } else if (result == 9) {
                            showSnackBar(
                              context,
                              "Tu cuenta ha sido desactivada. Contacta al administrador.",
                            );
                          } else if (result == null) {
                            showSnackBar(
                              context,
                              "Error de conexión. Verifica tu internet e intenta nuevamente",
                            );
                          }
                        } else if (result is String) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            AppRoutes.splash,
                            (route) => false,
                          );
                        }
                      }
                    }
                  },
                  child: const Text(
                    'INICIAR SESIÓN',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterCredentialsPage(),
                    ),
                  ),
                  child: const Text("¿No tienes cuenta? Crear nueva cuenta"),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RoleSelectorPage(),
                    ),
                  ),
                  child: const Text("Volver a selección de rol"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
