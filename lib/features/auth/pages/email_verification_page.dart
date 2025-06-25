import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tutoring_app/features/auth/pages/register_personal_info_page.dart';
import 'package:tutoring_app/features/auth/services/auth_service.dart';
import 'package:tutoring_app/core/utils/snackbar.dart';

class EmailVerificationPage extends StatefulWidget {
  final String email;
  final Map<String, dynamic> userData;

  const EmailVerificationPage({
    super.key,
    required this.email,
    required this.userData,
  });

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final AuthService _auth = AuthService();
  Timer? _timer;
  bool _isVerified = false;
  bool _canResendEmail = true;
  int _resendCooldown = 0;

  @override
  void initState() {
    super.initState();
    _checkEmailVerification();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkEmailVerification() async {
    _timer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final isVerified = await _auth.isEmailVerified();
      if (isVerified) {
        setState(() => _isVerified = true);
        _timer?.cancel();
        // Navegar a la página de registro de información personal con todos los datos
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => RegisterPersonalInfoPage(userData: widget.userData),
          ),
        );
      }
    });
  }

  Future<void> _resendVerificationEmail() async {
    if (!_canResendEmail) return;

    setState(() {
      _canResendEmail = false;
      _resendCooldown = 60;
    });

    final result = await _auth.resendVerificationEmail();
    if (result) {
      showSnackBar(context, 'Correo de verificación reenviado');
    } else {
      showSnackBar(context, 'Error al reenviar el correo');
    }

    // Iniciar countdown para permitir reenvío
    Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCooldown > 0) {
          _resendCooldown--;
        } else {
          _canResendEmail = true;
          timer.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f7f7),
      appBar: AppBar(title: const Text('Verificar correo')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.mark_email_unread_outlined,
              size: 100,
              color: Colors.orange,
            ),
            const SizedBox(height: 20),
            const Text(
              'Verifica tu correo',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              'Hemos enviado un correo de verificación a:\n${widget.email}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            const Text(
              'Por favor, revisa tu bandeja de entrada y sigue las instrucciones.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _canResendEmail ? _resendVerificationEmail : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                shape: const StadiumBorder(),
              ),
              child: Text(
                _canResendEmail
                    ? 'Reenviar correo'
                    : 'Reenviar en $_resendCooldown s',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                _timer?.cancel();
                Navigator.of(context).pop();
              },
              child: const Text('Volver al inicio de sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
