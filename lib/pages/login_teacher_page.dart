import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:tutoring_app/pages/inicio.dart';
import 'package:tutoring_app/service/auth.dart';
import 'package:tutoring_app/util/snackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginTeacherPage extends StatefulWidget {
  static const routeName = '/login-teacher';
  const LoginTeacherPage({super.key});

  @override
  State<LoginTeacherPage> createState() => _LoginTeacherPageState();
}

class _LoginTeacherPageState extends State<LoginTeacherPage> {
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
        showSnackBar(
          context,
          "No existe una cuenta con ese correo",
        );
      } else {
        showSnackBar(
          context,
          "Error al enviar el correo de restablecimiento",
        );
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
            labelText: 'Email Institucional',
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
      appBar: AppBar(title: const Text('Inicio de Sesión - Profesor')),
      body: Padding(
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
                  labelText: 'Email Institucional',
                  prefixIcon: Icon(Icons.email),
                ),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.email(),
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
                validator: FormBuilderValidators.required(),
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
                      requireTeacher: true,
                    );

                    if (result == 1) {
                      showSnackBar(
                        context,
                        "Usuario o contraseña incorrectos",
                      );
                    } else if (result == 2) {
                      showSnackBar(
                        context,
                        "Usuario o contraseña incorrectos",
                      );
                    } else if (result == 3) {
                      showSnackBar(
                        context,
                        "Esta cuenta no tiene permisos de profesor",
                      );
                    } else if (result != null) {
                      Navigator.popAndPushNamed(context, HomePage2.routeName);
                    }
                  }
                },
                child: const Text(
                  'INICIAR SESIÓN',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Si eres profesor y no tienes cuenta,\ncontacta con el administrador",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 