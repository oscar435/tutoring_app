import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:tutoring_app/pages/inicio.dart';
import 'package:tutoring_app/pages/register_profile_photo_page.dart';
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
  bool _isLoading = false;

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

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 30,
                    ),
                  ),
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState?.saveAndValidate() ?? false) {
                            setState(() => _isLoading = true);

                            try {
                              final allData = {
                                ...widget.userData,
                                ..._formKey.currentState!.value,
                              };

                              // Obtener el usuario actual
                              final currentUser = _auth.getCurrentUser();
                              if (currentUser == null) {
                                showSnackBar(
                                    context, "Error: No se encontró el usuario");
                                return;
                              }

                              // Actualizar datos en la colección estudiantes
                              await FirebaseFirestore.instance
                                  .collection('estudiantes')
                                  .doc(currentUser.uid)
                                  .set({
                                'nombre': allData['nombre'],
                                'apellidos': allData['apellidos'],
                                'email': allData['email'],
                                'edad': allData['edad'],
                                'codigo_estudiante': allData['codigo_estudiante'],
                                'especialidad': allData['especialidad'],
                                'ciclo': allData['ciclo'],
                                'universidad': allData['universidad'],
                                'updatedAt': FieldValue.serverTimestamp(),
                              }, SetOptions(merge: true));

                              // Mantener solo los datos básicos en users
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(currentUser.uid)
                                  .set({
                                'email': allData['email'],
                                'isTeacher': false,
                                'createdAt': FieldValue.serverTimestamp(),
                              }, SetOptions(merge: true));

                              if (!mounted) return;

                              // Navegar a la página de subir foto de perfil
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => RegisterProfilePhotoPage(userData: allData),
                                ),
                              );
                            } catch (e) {
                              showSnackBar(context,
                                  "Error al guardar los datos: ${e.toString()}");
                            } finally {
                              if (mounted) {
                                setState(() => _isLoading = false);
                              }
                            }
                          }
                        },
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Finalizar registro'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
