import 'package:flutter/material.dart';

void showSnackBar(BuildContext context, String mensaje) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(mensaje),
      duration: const Duration(milliseconds: 1000),
    ),
  );
}
