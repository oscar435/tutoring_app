import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tutoring_app/core/models/admin_user.dart';
import 'package:tutoring_app/core/services/user_management_service.dart';
import 'package:tutoring_app/features/admin/pages/assign_students_page.dart';
import 'package:tutoring_app/features/admin/pages/admin_availability_page.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserManagementService _userManagementService = UserManagementService();
  bool _isLoading = true;
  List<AdminUser> _users = [];
  List<AdminUser> _allUsers = [];
  UserRole? _selectedRoleFilter;
  bool _showInactive = false;
  String _searchQuery = '';

  // Controladores para el formulario de creación/edición
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Controladores para campos específicos de rol
  final _codigoEstudianteController = TextEditingController();
  final _cicloController = TextEditingController();
  final _edadController = TextEditingController();
  final _especialidadEstudianteController = TextEditingController();
  final _universidadEstudianteController = TextEditingController();

  final _escuelaTutorController = TextEditingController();
  final _especialidadTutorController = TextEditingController();
  final _cursosTutorController = TextEditingController();
  final _universidadTutorController = TextEditingController();
  final _facultadTutorController = TextEditingController();

  UserRole _selectedFormRole = UserRole.student;

  // Variables para filtros
  TextEditingController _searchController = TextEditingController();
  String? _selectedSchool;
  List<String> _schoolOptions = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _codigoEstudianteController.dispose();
    _cicloController.dispose();
    _edadController.dispose();
    _especialidadEstudianteController.dispose();
    _universidadEstudianteController.dispose();
    _escuelaTutorController.dispose();
    _especialidadTutorController.dispose();
    _cursosTutorController.dispose();
    _universidadTutorController.dispose();
    _facultadTutorController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _userManagementService.getUsers(
        roleFilter: _selectedRoleFilter,
        isActiveFilter: _showInactive ? null : true,
        searchQuery: null, // No filtrar aquí
      );
      _allUsers = users;
      // Si el filtro de rol es tutor, obtener escuelas únicas desde Firestore
      if (_selectedRoleFilter == UserRole.teacher) {
        final snapshot = await FirebaseFirestore.instance
            .collection('tutores')
            .get();
        final schools = snapshot.docs
            .map((doc) => doc.data()['escuela'] ?? '')
            .where((e) => e != null && e.toString().isNotEmpty)
            .map((e) => e.toString())
            .toSet()
            .toList();
        schools.sort();
        setState(() {
          _schoolOptions = schools;
        });
      } else {
        setState(() {
          _schoolOptions = [];
          _selectedSchool = null;
        });
      }
      _applyFilters();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error al Cargar Usuarios'),
          content: SingleChildScrollView(
            child: SelectableText(
              'Ha ocurrido un error que requiere una acción manual. Por favor, copia el siguiente texto (que incluye un enlace) y sigue las instrucciones para crear el índice necesario en Firebase:\n\n$message',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleUserStatus(String userId, bool currentStatus) async {
    final adminUserId = _auth.currentUser!.uid;
    try {
      if (currentStatus) {
        // Desactivar usuario
        await _userManagementService.deleteUser(
          userId: userId,
          deletedBy: adminUserId,
        );
      } else {
        // Reactivar usuario
        await _userManagementService.reactivateUser(
          userId: userId,
          reactivatedBy: adminUserId,
        );
      }
      _loadUsers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Usuario ${currentStatus ? 'desactivado' : 'reactivado'} exitosamente',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cambiar estado: $e')));
    }
  }

  Future<void> _saveUser({AdminUser? user}) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    Navigator.of(context).pop(); // Cerrar el diálogo

    final adminUserId = _auth.currentUser!.uid;
    final isCreating = user == null;

    try {
      final String email = _emailController.text;
      final String password = _passwordController.text;
      final String nombre = _nombreController.text;
      final String apellidos = _apellidosController.text;
      final UserRole role = _selectedFormRole;

      List<Permission> getPermissionsForRole(UserRole role) {
        switch (role) {
          case UserRole.student:
            return [Permission.viewUsers];
          case UserRole.teacher:
            return [Permission.viewUsers, Permission.editUsers];
          case UserRole.admin:
            return [
              Permission.viewUsers,
              Permission.createUsers,
              Permission.editUsers,
              Permission.assignRoles,
              Permission.viewAuditLogs,
            ];
          default:
            return [];
        }
      }

      if (isCreating) {
        Map<String, dynamic>? specificData;
        if (role == UserRole.teacher) {
          specificData = {
            'nombre': nombre,
            'apellidos': apellidos,
            'email': email,
            'escuela': _escuelaTutorController.text,
            'especialidad': _especialidadTutorController.text,
            'cursos': _cursosTutorController.text
                .split(',')
                .map((e) => e.trim())
                .toList(),
            'universidad': 'Universidad Nacional Federico Villarreal',
            'facultad': 'Facultad de Ingeniería Electrónica e Informática',
            'emailVerified': true,
          };
        } else if (role == UserRole.student) {
          specificData = {
            'nombre': nombre,
            'apellidos': apellidos,
            'email': email,
            'codigo_estudiante': _codigoEstudianteController.text,
            'ciclo': _cicloController.text,
            'edad': int.tryParse(_edadController.text) ?? 0,
            'especialidad': _especialidadEstudianteController.text,
            'universidad': _universidadEstudianteController.text.isNotEmpty
                ? _universidadEstudianteController.text
                : 'Universidad Nacional Federico Villarreal',
            'emailVerified': true,
          };
        }

        await _userManagementService.createUser(
          email: email,
          password: password,
          nombre: nombre,
          apellidos: apellidos,
          role: role,
          permissions: getPermissionsForRole(role),
          createdBy: adminUserId,
          specificData: specificData,
        );
      } else {
        Map<String, dynamic>? specificData;
        final hasRoleChanged = user.role != role;

        // Siempre preparar los datos específicos para la actualización
        if (role == UserRole.student) {
          specificData = {
            'nombre': nombre,
            'apellidos': apellidos,
            'email': email,
            'codigo_estudiante': _codigoEstudianteController.text,
            'ciclo': _cicloController.text,
            'edad': int.tryParse(_edadController.text) ?? 0,
            'especialidad': _especialidadEstudianteController.text,
            'universidad': _universidadEstudianteController.text.isNotEmpty
                ? _universidadEstudianteController.text
                : 'Universidad Nacional Federico Villarreal',
            'emailVerified': true,
          };
        } else if (role == UserRole.teacher) {
          specificData = {
            'nombre': nombre,
            'apellidos': apellidos,
            'email': email,
            'escuela': _escuelaTutorController.text,
            'especialidad': _especialidadTutorController.text,
            'cursos': _cursosTutorController.text
                .split(',')
                .map((e) => e.trim())
                .toList(),
            'universidad': _universidadTutorController.text.isNotEmpty
                ? _universidadTutorController.text
                : 'Universidad Nacional Federico Villarreal',
            'facultad': _facultadTutorController.text.isNotEmpty
                ? _facultadTutorController.text
                : 'Facultad de Ingeniería Electrónica e Informática',
            'emailVerified': true,
          };
        }

        await _userManagementService.updateUser(
          userId: user.id,
          nombre: nombre,
          apellidos: apellidos,
          role: role,
          permissions: getPermissionsForRole(role),
          modifiedBy: adminUserId,
          specificData: specificData,
        );
      }

      await _loadUsers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Usuario ${isCreating ? 'creado' : 'actualizado'} exitosamente',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar usuario: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showUserFormDialog({AdminUser? user}) async {
    final isCreating = user == null;
    Map<String, dynamic> completeUserData = {};
    if (user != null) {
      completeUserData = user.toFirestore();
    }

    if (!isCreating) {
      // Mostrar un indicador de carga mientras se obtienen los datos.
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) =>
            const Center(child: CircularProgressIndicator()),
      );

      try {
        final role = user!.role;
        if (role == UserRole.student || role == UserRole.teacher) {
          final collectionName = role == UserRole.student
              ? 'estudiantes'
              : 'tutores';
          final specificDoc = await _firestore
              .collection(collectionName)
              .doc(user.id)
              .get();
          if (specificDoc.exists) {
            completeUserData.addAll(specificDoc.data()!);
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Cerrar el indicador de carga
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al cargar datos del usuario: $e')),
          );
        }
        return;
      }
      if (mounted) Navigator.pop(context); // Cerrar el indicador de carga
    }

    // Limpiar o llenar controladores con los datos completos.
    _nombreController.text = completeUserData['nombre'] ?? '';
    _apellidosController.text = completeUserData['apellidos'] ?? '';
    _emailController.text = completeUserData['email'] ?? '';
    _passwordController.clear();
    _selectedFormRole = UserRole.values.firstWhere(
      (e) =>
          e.toString().split('.').last ==
          (completeUserData['role'] ?? 'student'),
      orElse: () => UserRole.student,
    );

    // Cargar datos específicos según el rol
    _codigoEstudianteController.text =
        completeUserData['codigo_estudiante'] ?? '';
    _cicloController.text = completeUserData['ciclo'] ?? '';
    _edadController.text = completeUserData['edad']?.toString() ?? '';
    _especialidadEstudianteController.text =
        completeUserData['especialidad'] ?? '';
    _universidadEstudianteController.text =
        completeUserData['universidad'] ??
        'Universidad Nacional Federico Villarreal';

    _escuelaTutorController.text = completeUserData['escuela'] ?? '';
    _especialidadTutorController.text = completeUserData['especialidad'] ?? '';
    _cursosTutorController.text =
        (completeUserData['cursos'] as List<dynamic>?)?.join(', ') ?? '';
    _universidadTutorController.text =
        completeUserData['universidad'] ??
        'Universidad Nacional Federico Villarreal';
    _facultadTutorController.text =
        completeUserData['facultad'] ??
        'Facultad de Ingeniería Electrónica e Informática';

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isCreating ? 'Crear Nuevo Usuario' : 'Editar Usuario',
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _apellidosController,
                        decoration: const InputDecoration(
                          labelText: 'Apellidos',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        enabled: isCreating,
                        validator: (v) {
                          if (v!.isEmpty) return 'Campo requerido';
                          if (!v.endsWith('@unfv.edu.pe'))
                            return 'Debe ser un correo institucional';
                          return null;
                        },
                      ),
                      if (isCreating) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Contraseña',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (isCreating && v!.isEmpty)
                              return 'Campo requerido';
                            if (isCreating && v!.length < 6)
                              return 'Mínimo 6 caracteres';
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      DropdownButtonFormField<UserRole>(
                        value: _selectedFormRole,
                        decoration: const InputDecoration(
                          labelText: 'Rol',
                          border: OutlineInputBorder(),
                        ),
                        items: UserRole.values
                            .map(
                              (role) => DropdownMenuItem(
                                value: role,
                                child: Text(role.displayName),
                              ),
                            )
                            .toList(),
                        onChanged: (UserRole? newValue) {
                          if (newValue != null &&
                              newValue != _selectedFormRole) {
                            setDialogState(() {
                              _selectedFormRole = newValue;

                              // Limpiar todos los campos de roles para evitar conflictos de datos
                              _codigoEstudianteController.clear();
                              _cicloController.clear();
                              _edadController.clear();
                              _especialidadEstudianteController.clear();
                              _universidadEstudianteController.text = '';

                              _escuelaTutorController.clear();
                              _especialidadTutorController.clear();
                              _cursosTutorController.clear();
                              _universidadTutorController.text = '';
                              _facultadTutorController.clear();

                              // Aplicar valores por defecto al rol seleccionado
                              if (newValue == UserRole.student) {
                                _universidadEstudianteController.text =
                                    'Universidad Nacional Federico Villarreal';
                              } else if (newValue == UserRole.teacher) {
                                _universidadTutorController.text =
                                    'Universidad Nacional Federico Villarreal';
                                _facultadTutorController.text =
                                    'Facultad de Ingeniería Electrónica e Informática';
                              }
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      if (_selectedFormRole == UserRole.student) ...[
                        const Divider(),
                        const Text(
                          'Datos de Estudiante',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _codigoEstudianteController,
                          decoration: const InputDecoration(
                            labelText: 'Código de Estudiante',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (_selectedFormRole == UserRole.student) {
                              if (v!.isEmpty) return 'Campo requerido';
                              if (v.length != 10)
                                return 'Debe tener 10 dígitos';
                              if (!RegExp(r'^\d{10}$').hasMatch(v))
                                return 'Solo números permitidos';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _cicloController,
                          decoration: const InputDecoration(
                            labelText: 'Ciclo',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (_selectedFormRole == UserRole.student) {
                              if (v!.isEmpty) return 'Campo requerido';
                              final ciclo = int.tryParse(v);
                              if (ciclo == null || ciclo < 1 || ciclo > 10)
                                return 'Ciclo debe ser del 1 al 10';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _edadController,
                          decoration: const InputDecoration(
                            labelText: 'Edad',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (_selectedFormRole == UserRole.student) {
                              if (v!.isEmpty) return 'Campo requerido';
                              final edad = int.tryParse(v);
                              if (edad == null || edad < 16 || edad > 100)
                                return 'Edad debe ser entre 16 y 100';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _especialidadEstudianteController.text.isEmpty
                              ? null
                              : _especialidadEstudianteController.text,
                          decoration: const InputDecoration(
                            labelText: 'Especialidad (Carrera)',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Ingeniería Electrónica',
                              child: Text('Ingeniería Electrónica'),
                            ),
                            DropdownMenuItem(
                              value: 'Ingeniería Informática',
                              child: Text('Ingeniería Informática'),
                            ),
                            DropdownMenuItem(
                              value: 'Ingeniería Mecatrónica',
                              child: Text('Ingeniería Mecatrónica'),
                            ),
                            DropdownMenuItem(
                              value: 'Ingeniería de Telecomunicaciones',
                              child: Text('Ingeniería de Telecomunicaciones'),
                            ),
                          ],
                          onChanged: (value) {
                            setDialogState(
                              () => _especialidadEstudianteController.text =
                                  value!,
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _universidadEstudianteController.text,
                          decoration: const InputDecoration(
                            labelText: 'Universidad',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Universidad Nacional Federico Villarreal',
                              child: Text(
                                'Universidad Nacional Federico Villarreal',
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setDialogState(
                              () => _universidadEstudianteController.text =
                                  value!,
                            );
                          },
                        ),
                      ],

                      if (_selectedFormRole == UserRole.teacher) ...[
                        const Divider(),
                        const Text(
                          'Datos de Tutor',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _escuelaTutorController.text.isEmpty
                              ? null
                              : _escuelaTutorController.text,
                          decoration: const InputDecoration(
                            labelText: 'Escuela',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Escuela de Ingeniería Electrónica',
                              child: Text('Escuela de Ingeniería Electrónica'),
                            ),
                            DropdownMenuItem(
                              value: 'Escuela de Ingeniería Informática',
                              child: Text('Escuela de Ingeniería Informática'),
                            ),
                            DropdownMenuItem(
                              value: 'Escuela de Ingeniería Mecatrónica',
                              child: Text('Escuela de Ingeniería Mecatrónica'),
                            ),
                            DropdownMenuItem(
                              value:
                                  'Escuela de Ingeniería de Telecomunicaciones',
                              child: Text(
                                'Escuela de Ingeniería de Telecomunicaciones',
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setDialogState(
                              () => _escuelaTutorController.text = value!,
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _especialidadTutorController,
                          decoration: const InputDecoration(
                            labelText: 'Especialidad (Área)',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              _selectedFormRole == UserRole.teacher &&
                                  v!.isEmpty
                              ? 'Campo requerido'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _cursosTutorController,
                          decoration: const InputDecoration(
                            labelText: 'Cursos (separados por coma)',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              _selectedFormRole == UserRole.teacher &&
                                  v!.isEmpty
                              ? 'Campo requerido'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _universidadTutorController.text.isEmpty
                              ? 'Universidad Nacional Federico Villarreal'
                              : _universidadTutorController.text,
                          decoration: const InputDecoration(
                            labelText: 'Universidad',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Universidad Nacional Federico Villarreal',
                              child: Text(
                                'Universidad Nacional Federico Villarreal',
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setDialogState(
                              () => _universidadTutorController.text = value!,
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _facultadTutorController.text.isEmpty
                              ? 'Facultad de Ingeniería Electrónica e Informática'
                              : _facultadTutorController.text,
                          decoration: const InputDecoration(
                            labelText: 'Facultad',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value:
                                  'Facultad de Ingeniería Electrónica e Informática',
                              child: Text(
                                'Facultad de Ingeniería Electrónica e Informática',
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setDialogState(
                              () => _facultadTutorController.text = value!,
                            );
                          },
                        ),
                      ],

                      if (_selectedFormRole == UserRole.admin) ...[
                        const Divider(),
                        const Text(
                          'Datos de Administrador',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Los administradores tienen acceso completo al panel de administración.',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Permisos incluidos:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const Text(
                          '• Gestión de usuarios',
                          style: TextStyle(fontSize: 12),
                        ),
                        const Text(
                          '• Asignación de roles',
                          style: TextStyle(fontSize: 12),
                        ),
                        const Text(
                          '• Ver auditoría',
                          style: TextStyle(fontSize: 12),
                        ),
                        const Text(
                          '• Crear usuarios',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => _saveUser(user: user),
                  child: Text(isCreating ? 'Crear' : 'Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _applyFilters() {
    List<AdminUser> filtered = _allUsers;
    final query = _searchQuery.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered
          .where(
            (u) =>
                u.nombre.toLowerCase().contains(query) ||
                u.apellidos.toLowerCase().contains(query),
          )
          .toList();
    }
    if (_selectedRoleFilter == UserRole.teacher &&
        _selectedSchool != null &&
        _selectedSchool!.isNotEmpty) {
      filtered = filtered
          .where((u) => u.toFirestore()['escuela'] == _selectedSchool)
          .toList();
    }
    setState(() {
      _users = filtered;
    });
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<UserRole>(
                  value: _selectedRoleFilter,
                  decoration: const InputDecoration(
                    labelText: 'Filtrar por Rol',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Todos')),
                    DropdownMenuItem(
                      value: UserRole.student,
                      child: Text('Estudiantes'),
                    ),
                    DropdownMenuItem(
                      value: UserRole.teacher,
                      child: Text('Tutores'),
                    ),
                    DropdownMenuItem(
                      value: UserRole.admin,
                      child: Text('Administradores'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedRoleFilter = value);
                    _selectedSchool = null;
                    _loadUsers();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  Checkbox(
                    value: _showInactive,
                    onChanged: (value) {
                      setState(() => _showInactive = value!);
                      _loadUsers();
                    },
                  ),
                  const Text('Mostrar Inactivos'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Buscador de texto con debounce
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Buscar por nombre o apellidos',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              if (_debounce?.isActive ?? false) _debounce!.cancel();
              _debounce = Timer(const Duration(milliseconds: 200), () {
                setState(() => _searchQuery = value);
                _applyFilters();
              });
            },
          ),
          if (_selectedRoleFilter == UserRole.teacher &&
              _schoolOptions.isNotEmpty) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedSchool,
              decoration: const InputDecoration(
                labelText: 'Filtrar por Escuela',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Todas las escuelas'),
                ),
                ..._schoolOptions.map(
                  (school) =>
                      DropdownMenuItem(value: school, child: Text(school)),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedSchool = value);
                _applyFilters();
              },
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilterBar(),
                Expanded(child: _buildUserList()),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserFormDialog(),
        child: const Icon(Icons.add),
        tooltip: 'Crear Usuario',
      ),
    );
  }

  Widget _buildUserList() {
    if (_users.isEmpty) {
      return const Center(child: Text('No se encontraron usuarios.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80.0),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          elevation: 2.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getRoleColor(user.role).withOpacity(0.1),
              foregroundColor: _getRoleColor(user.role),
              child: _getRoleIcon(user.role),
            ),
            title: Text(
              '${user.nombre ?? ''} ${user.apellidos ?? ''}'.trim(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.email ?? 'Sin email',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getRoleColor(user.role).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.role.displayName,
                    style: TextStyle(
                      color: _getRoleColor(user.role),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Creado: ${DateFormat('dd/MM/yyyy').format(user.createdAt)}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                if (!user.isActive)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'INACTIVO',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility, color: Colors.blue),
                  onPressed: () => _showUserDetails(user),
                  tooltip: 'Ver Detalles',
                ),
                IconButton(
                  icon: Icon(
                    user.isActive ? Icons.block : Icons.check_circle_outline,
                    color: user.isActive ? Colors.red : Colors.green,
                  ),
                  onPressed: () => _toggleUserStatus(user.id, user.isActive),
                  tooltip: user.isActive
                      ? 'Desactivar Usuario'
                      : 'Activar Usuario',
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blueGrey),
                  onPressed: () => _showUserFormDialog(user: user),
                  tooltip: 'Editar Usuario',
                ),
                if (user.role == UserRole.teacher)
                  IconButton(
                    icon: const Icon(
                      Icons.manage_accounts,
                      color: Colors.purple,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AssignStudentsPage(
                            tutorId: user.id,
                            tutorName:
                                '${user.nombre ?? ''} ${user.apellidos ?? ''}'
                                    .trim(),
                          ),
                        ),
                      );
                    },
                    tooltip: 'Asignar Estudiantes',
                  ),
                if (user.role == UserRole.teacher)
                  IconButton(
                    icon: const Icon(Icons.access_time, color: Colors.teal),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminAvailabilityPage(
                            tutorId: user.id,
                            tutorName:
                                '${user.nombre ?? ''} ${user.apellidos ?? ''}'
                                    .trim(),
                          ),
                        ),
                      );
                    },
                    tooltip: 'Editar Disponibilidad',
                  ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.student:
        return Colors.blue.shade700;
      case UserRole.teacher:
        return Colors.green.shade700;
      case UserRole.admin:
        return Colors.purple.shade700;
      case UserRole.superAdmin:
        return Colors.orange.shade800;
      default:
        return Colors.grey.shade600;
    }
  }

  Icon _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.student:
        return const Icon(Icons.school);
      case UserRole.teacher:
        return const Icon(Icons.person_search);
      case UserRole.admin:
        return const Icon(Icons.admin_panel_settings);
      case UserRole.superAdmin:
        return const Icon(Icons.verified_user);
      default:
        return const Icon(Icons.person);
    }
  }

  void _showUserDetails(AdminUser user) async {
    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) =>
          const Center(child: CircularProgressIndicator()),
    );

    try {
      Map<String, dynamic> completeUserData = {};

      // Obtener datos específicos según el rol
      if (user.role == UserRole.student || user.role == UserRole.teacher) {
        final collectionName = user.role == UserRole.student
            ? 'estudiantes'
            : 'tutores';
        final specificDoc = await _firestore
            .collection(collectionName)
            .doc(user.id)
            .get();
        if (specificDoc.exists) {
          completeUserData.addAll(specificDoc.data()!);
        }
      }

      if (mounted) {
        Navigator.pop(context); // Cerrar indicador de carga

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Detalles de ${user.fullName}'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow('Nombre', user.nombre),
                  _buildDetailRow('Apellidos', user.apellidos),
                  _buildDetailRow('Email', user.email),
                  _buildDetailRow('Rol', user.roleDisplayName),
                  _buildDetailRow(
                    'Estado',
                    user.isActive ? 'Activo' : 'Inactivo',
                  ),
                  _buildDetailRow(
                    'Fecha de creación',
                    DateFormat('dd/MM/yyyy HH:mm').format(user.createdAt),
                  ),
                  if (user.lastLogin != null)
                    _buildDetailRow(
                      'Último acceso',
                      DateFormat('dd/MM/yyyy HH:mm').format(user.lastLogin!),
                    ),

                  if (user.role == UserRole.student) ...[
                    const Divider(),
                    const Text(
                      'Datos de Estudiante',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    _buildDetailRow(
                      'Código',
                      completeUserData['codigo_estudiante'] ?? '-',
                    ),
                    _buildDetailRow('Ciclo', completeUserData['ciclo'] ?? '-'),
                    _buildDetailRow(
                      'Edad',
                      completeUserData['edad']?.toString() ?? '-',
                    ),
                    _buildDetailRow(
                      'Especialidad',
                      completeUserData['especialidad'] ?? '-',
                    ),
                    _buildDetailRow(
                      'Universidad',
                      completeUserData['universidad'] ?? '-',
                    ),
                  ],

                  if (user.role == UserRole.teacher) ...[
                    const Divider(),
                    const Text(
                      'Datos de Tutor',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    _buildDetailRow(
                      'Escuela',
                      completeUserData['escuela'] ?? '-',
                    ),
                    _buildDetailRow(
                      'Especialidad',
                      completeUserData['especialidad'] ?? '-',
                    ),
                    _buildDetailRow(
                      'Cursos',
                      (completeUserData['cursos'] as List<dynamic>?)?.join(
                            ', ',
                          ) ??
                          '-',
                    ),
                    _buildDetailRow(
                      'Universidad',
                      completeUserData['universidad'] ?? '-',
                    ),
                    _buildDetailRow(
                      'Facultad',
                      completeUserData['facultad'] ?? '-',
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showUserFormDialog(user: user);
                },
                child: const Text('Editar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar indicador de carga
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar detalles: $e')));
      }
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}
