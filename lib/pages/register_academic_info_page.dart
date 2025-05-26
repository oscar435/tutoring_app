import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:tutoring_app/pages/inicio.dart';
import 'package:tutoring_app/service/auth.dart';
import 'package:tutoring_app/util/snackbar.dart';

class RegisterAcademicInfoPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const RegisterAcademicInfoPage({super.key, required this.userData});

  @override
  State<RegisterAcademicInfoPage> createState() =>
      _RegisterAcademicInfoPageState();
}

class _RegisterAcademicInfoPageState extends State<RegisterAcademicInfoPage> {
  final _formKey = GlobalKey<FormBuilderState>();
  final AuthService _auth = AuthService();

  final List<String> especialidades = [
    'Ingeniería Informática',
    'Ingeniería Telecomunicaciones',
    'Ingeniería Electrónica',
    'Ingeniería Mecatrónica',
  ];

  final List<String> ciclos = List.generate(10, (index) => '${index + 1}');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f7f7),
      appBar: AppBar(title: const Text('Datos académicos')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: FormBuilder(
          key: _formKey,
          child: Column(
            children: [
              FormBuilderTextField(
                name: 'codigo_estudiante',
                decoration: const InputDecoration(
                  labelText: 'Código de estudiante',
                  prefixIcon: Icon(Icons.badge),
                ),
                keyboardType: TextInputType.number,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.numeric(),
                  FormBuilderValidators.minLength(
                    10,
                    errorText: 'Debe tener exactamente 10 dígitos',
                  ),
                  FormBuilderValidators.maxLength(
                    10,
                    errorText: 'Debe tener exactamente 10 dígitos',
                  ),
                ]),
              ),
              const SizedBox(height: 15),

              FormBuilderDropdown<String>(
                name: 'especialidad',
                decoration: const InputDecoration(
                  labelText: 'Especialidad',
                  prefixIcon: Icon(Icons.school),
                ),
                items: especialidades
                    .map(
                      (especialidad) => DropdownMenuItem(
                        value: especialidad,
                        child: Text(especialidad),
                      ),
                    )
                    .toList(),
                validator: FormBuilderValidators.required(),
              ),
              const SizedBox(height: 15),

              FormBuilderDropdown<String>(
                name: 'ciclo',
                decoration: const InputDecoration(
                  labelText: 'Ciclo académico',
                  prefixIcon: Icon(Icons.looks_one),
                ),
                items: ciclos
                    .map(
                      (ciclo) =>
                          DropdownMenuItem(value: ciclo, child: Text(ciclo)),
                    )
                    .toList(),
                validator: FormBuilderValidators.required(),
              ),
              const SizedBox(height: 15),

              FormBuilderTextField(
                name: 'universidad',
                decoration: const InputDecoration(
                  labelText: 'Universidad',
                  prefixIcon: Icon(Icons.location_city),
                ),
                validator: FormBuilderValidators.required(),
              ),
              const Spacer(),

              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.saveAndValidate() ?? false) {
                    final allData = {
                      ...widget.userData,
                      ..._formKey.currentState!.value,
                    };

                    var result = await _auth.createAccount(
                      allData['email'],
                      allData['password'],
                    );

                    if (result == 1) {
                      showSnackBar(context, "Error: Contraseña muy débil");
                    } else if (result == 2) {
                      showSnackBar(context, "Error: Email ya en uso");
                    } else if (result != null) {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(result)
                          .set({
                            'nombre': allData['nombre'],
                            'apellidos': allData['apellidos'],
                            'email': allData['email'],
                            'edad': allData['edad'],
                            'codigo_estudiante': allData['codigo_estudiante'],
                            'especialidad': allData['especialidad'],
                            'ciclo': allData['ciclo'],
                            'universidad': allData['universidad'],
                            'createdAt': FieldValue.serverTimestamp(),
                          });

                      Navigator.pushReplacementNamed(
                        context,
                        HomePage2.routeName,
                      );
                    }
                  }
                },
                child: const Text('Registrar y continuar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
