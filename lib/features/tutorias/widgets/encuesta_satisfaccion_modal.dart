import 'package:flutter/material.dart';

class EncuestaSatisfaccionModal extends StatefulWidget {
  final void Function(int calificacion, String comentario) onSubmit;
  final VoidCallback? onCancel;

  const EncuestaSatisfaccionModal({
    Key? key,
    required this.onSubmit,
    this.onCancel,
  }) : super(key: key);

  @override
  State<EncuestaSatisfaccionModal> createState() =>
      _EncuestaSatisfaccionModalState();
}

class _EncuestaSatisfaccionModalState extends State<EncuestaSatisfaccionModal> {
  int _calificacion = 0;
  final TextEditingController _comentarioController = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: SingleChildScrollView(
        child: AlertDialog(
          title: const Text(
            '¿Cómo calificarías tu experiencia en esta tutoría?',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => IconButton(
                    icon: Icon(
                      _calificacion > index ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () {
                      setState(() {
                        _calificacion = index + 1;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _comentarioController,
                decoration: const InputDecoration(
                  labelText: 'Comentario (opcional)',
                  border: OutlineInputBorder(),
                ),
                minLines: 2,
                maxLines: 4,
              ),
            ],
          ),
          actions: [
            if (widget.onCancel != null)
              TextButton(
                onPressed: _enviando ? null : widget.onCancel,
                child: const Text('Omitir'),
              ),
            ElevatedButton(
              onPressed: _enviando || _calificacion == 0
                  ? null
                  : () {
                      setState(() => _enviando = true);
                      widget.onSubmit(
                        _calificacion,
                        _comentarioController.text.trim(),
                      );
                      if (mounted) Navigator.of(context).pop();
                    },
              child: _enviando
                  ? const CircularProgressIndicator()
                  : const Text('Enviar'),
            ),
          ],
        ),
      ),
    );
  }
}
