import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:tutoring_app/pages/inicio.dart';
import 'package:tutoring_app/pages/register_credentials_page.dart';
import 'package:tutoring_app/service/auth.dart';
import 'package:tutoring_app/util/snackbar.dart';

class LoginPage extends StatefulWidget {
  static const routeName = '/login';
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormBuilderState>();

  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f7f7),
      appBar: AppBar(title: const Text('Inicio de Sesión')),
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
                  labelText: 'Email',
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

                    if (result == 1) {
                      showSnackBar(
                        context,
                        "Usuario o contrasenia incorrectos",
                      );
                    } else if (result == 2) {
                      showSnackBar(
                        context,
                        "Usuario o contrasenia incorrectos",
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
              TextButton(
                onPressed: () => Navigator.pushReplacementNamed(
                  context,
                  RegisterCredentialsPage.routeName,
                ),
                child: const Text("¿No tienes cuenta? Crear nueva cuenta"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
