import 'package:flutter/material.dart';

// Función original para compatibilidad con el código antiguo
void showSnackBar(BuildContext context, String mensaje) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(mensaje),
      duration: const Duration(milliseconds: 1500),
    ),
  );
}

// Nueva función para mensajes de éxito
void showSuccessSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.green[600],
    ),
  );
}

// Nueva función para mensajes de error
void showErrorSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red[600],
    ),
  );
}
