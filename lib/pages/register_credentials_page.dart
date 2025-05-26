import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'register_personal_info_page.dart';

class RegisterCredentialsPage extends StatefulWidget {
  static const routeName = '/register_credentials';
  const RegisterCredentialsPage({super.key});

  @override
  State<RegisterCredentialsPage> createState() =>
      _RegisterCredentialsPageState();
}

class _RegisterCredentialsPageState extends State<RegisterCredentialsPage> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f7f7),
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: FormBuilder(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 30),
              Image.asset('assets/logo_transparente.png', height: 250),
              const SizedBox(height: 30),

              FormBuilderTextField(
                name: 'email',
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.email),
                ),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.email(),
                ]),
              ),
              const SizedBox(height: 20),

              FormBuilderTextField(
                name: 'password',
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: FormBuilderValidators.minLength(6),
              ),
              const Spacer(),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.orange, // O prueba con Colors.deepOrange
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  shape: const StadiumBorder(),
                ),
                onPressed: () {
                  if (_formKey.currentState?.saveAndValidate() ?? false) {
                    final data = _formKey.currentState!.value;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            RegisterPersonalInfoPage(userData: data),
                      ),
                    );
                  }
                },
                child: const Text(
                  'Siguiente',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
