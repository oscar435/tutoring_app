import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'register_academic_info_page.dart';

class RegisterPersonalInfoPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const RegisterPersonalInfoPage({super.key, required this.userData});

  @override
  State<RegisterPersonalInfoPage> createState() =>
      _RegisterPersonalInfoPageState();
}

class _RegisterPersonalInfoPageState extends State<RegisterPersonalInfoPage> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f7f7),
      appBar: AppBar(title: const Text('Datos personales')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: FormBuilder(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 30),
              FormBuilderTextField(
                name: 'nombre',
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: FormBuilderValidators.required(),
              ),
              const SizedBox(height: 20),
              FormBuilderTextField(
                name: 'apellidos',
                decoration: const InputDecoration(
                  labelText: 'Apellidos',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: FormBuilderValidators.required(),
              ),
              const SizedBox(height: 20),
              FormBuilderTextField(
                name: 'edad',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Edad',
                  prefixIcon: Icon(Icons.cake),
                ),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.numeric(),
                  FormBuilderValidators.min(15),
                  FormBuilderValidators.max(100),
                ]),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState?.saveAndValidate() ?? false) {
                      final combinedData = {
                        ...widget.userData,
                        ..._formKey.currentState!.value,
                      };
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              RegisterAcademicInfoPage(userData: combinedData),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Siguiente',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
