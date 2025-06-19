import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:tutoring_app/features/auth/pages/email_verification_page.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tutoring_app/core/storage/preferencias_usuario.dart';
import 'package:tutoring_app/features/auth/pages/login_pages.dart';
import 'package:tutoring_app/features/dashboard/pages/RoleSelectorPage.dart';
import 'package:tutoring_app/features/auth/services/auth_service.dart';
import 'package:tutoring_app/core/utils/snackbar.dart';
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
  final _auth = AuthService();
  bool _isLoading = false;

  String? _validateInstitutionalEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El correo es requerido';
    }
    if (!value.endsWith('@unfv.edu.pe')) {
      return 'Debe ser un correo institucional (@unfv.edu.pe)';
    }
    // Validar formato de correo
    final emailRegex = RegExp(r'^[\w-\.]+@unfv\.edu\.pe$');
    if (!emailRegex.hasMatch(value)) {
      return 'Formato de correo inválido';
    }
    return null;
  }

  Future<void> _handleRegistration() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() => _isLoading = true);

      final data = _formKey.currentState!.value;
      final result = await _auth.createAccount(data['email'], data['password']);

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (result['success']) {
        // Navegar a la página de verificación con email y contraseña
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EmailVerificationPage(
              email: data['email'],
              userData: {'email': data['email'], 'password': data['password']},
            ),
          ),
        );
      } else {
        showSnackBar(context, result['message']);
      }
    }
  }

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
                  labelText: 'Correo institucional',
                  prefixIcon: Icon(Icons.email),
                  hintText: 'ejemplo@unfv.edu.pe',
                  helperText: 'Usa tu correo institucional (@unfv.edu.pe)',
                ),
                validator: _validateInstitutionalEmail,
                keyboardType: TextInputType.emailAddress,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(height: 20),

              FormBuilderTextField(
                name: 'password',
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock),
                  helperText: 'Mínimo 6 caracteres',
                ),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(
                    errorText: 'La contraseña es requerida',
                  ),
                  FormBuilderValidators.minLength(
                    6,
                    errorText: 'La contraseña debe tener al menos 6 caracteres',
                  ),
                ]),
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: _isLoading ? null : _handleRegistration,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Siguiente',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginPage(),
                  ),
                ),
                child: const Text("¿Ya tienes cuenta? Iniciar sesión"),
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
    );
  }
}
