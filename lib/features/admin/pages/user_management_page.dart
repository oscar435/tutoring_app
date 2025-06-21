import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tutoring_app/core/models/admin_user.dart';
import 'package:tutoring_app/core/services/user_management_service.dart';
import 'package:tutoring_app/features/admin/pages/assign_students_page.dart';

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

  final _escuelaTutorController = TextEditingController();
  final _especialidadTutorController = TextEditingController();
  final _cursosTutorController = TextEditingController();

  UserRole _selectedFormRole = UserRole.student;
  
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
    _escuelaTutorController.dispose();
    _especialidadTutorController.dispose();
    _cursosTutorController.dispose();
    super.dispose();
  }

  // Añadiendo un comentario para forzar la actualización del archivo.
  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _userManagementService.getUsers(
        roleFilter: _selectedRoleFilter,
        isActiveFilter: _showInactive ? null : true,
        searchQuery: _searchQuery,
      );
      setState(() {
        _users = users;
        _isLoading = false;
      });
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
    final deletedBy = _auth.currentUser!.uid;
    try {
      if (currentStatus) {
        await _userManagementService.deleteUser(userId: userId, deletedBy: deletedBy);
      } else {
        await _userManagementService.updateUser(
          userId: userId,
          isActive: true,
          modifiedBy: deletedBy,
        );
      }
      _loadUsers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Usuario ${currentStatus ? 'desactivado' : 'activado'} exitosamente'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cambiar estado: $e')),
      );
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
              Permission.viewAuditLogs
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
            'cursos': _cursosTutorController.text.split(',').map((e) => e.trim()).toList(),
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
            'universidad': 'Universidad Nacional Federico Villarreal',
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

        // Si el rol ha cambiado, preparamos los datos para la nueva colección
        if (hasRoleChanged) {
          if (role == UserRole.student) {
            specificData = {
              'nombre': nombre,
              'apellidos': apellidos,
              'email': email,
              'codigo_estudiante': _codigoEstudianteController.text,
              'ciclo': _cicloController.text,
              'edad': int.tryParse(_edadController.text) ?? 0,
              'especialidad': _especialidadEstudianteController.text,
              'universidad': 'Universidad Nacional Federico Villarreal',
              'emailVerified': true,
            };
          } else if (role == UserRole.teacher) {
            specificData = {
              'nombre': nombre,
              'apellidos': apellidos,
              'email': email,
              'escuela': _escuelaTutorController.text,
              'especialidad': _especialidadTutorController.text,
              'cursos': _cursosTutorController.text.split(',').map((e) => e.trim()).toList(),
              'universidad': 'Universidad Nacional Federico Villarreal',
              'facultad': 'Facultad de Ingeniería Electrónica e Informática',
              'emailVerified': true,
            };
          }
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
        SnackBar(content: Text('Usuario ${isCreating ? 'creado' : 'actualizado'} exitosamente')),
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
        builder: (BuildContext context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final role = user!.role;
        if (role == UserRole.student || role == UserRole.teacher) {
          final collectionName = role == UserRole.student ? 'estudiantes' : 'tutores';
          final specificDoc = await _firestore.collection(collectionName).doc(user.id).get();
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
    _selectedFormRole = completeUserData['role'] ?? UserRole.student;

    _codigoEstudianteController.text = completeUserData['codigo_estudiante'] ?? '';
    _cicloController.text = completeUserData['ciclo'] ?? '';
    _edadController.text = completeUserData['edad']?.toString() ?? '';
    _especialidadEstudianteController.text = (completeUserData['role'] == UserRole.student) ? completeUserData['especialidad'] ?? '' : '';

    _escuelaTutorController.text = completeUserData['escuela'] ?? '';
    _especialidadTutorController.text = (completeUserData['role'] == UserRole.teacher) ? completeUserData['especialidad'] ?? '' : '';
    _cursosTutorController.text = (completeUserData['cursos'] as List<dynamic>?)?.join(', ') ?? '';

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isCreating ? 'Crear Nuevo Usuario' : 'Editar Usuario'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nombreController,
                        decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _apellidosController,
                        decoration: const InputDecoration(labelText: 'Apellidos', border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                        enabled: isCreating,
                        validator: (v) {
                          if (v!.isEmpty) return 'Campo requerido';
                          if (!v.endsWith('@unfv.edu.pe')) return 'Debe ser un correo institucional';
                          return null;
                        },
                      ),
                      if (isCreating) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder()),
                          validator: (v) {
                            if (isCreating && v!.isEmpty) return 'Campo requerido';
                            if (isCreating && v!.length < 6) return 'Mínimo 6 caracteres';
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      DropdownButtonFormField<UserRole>(
                        value: _selectedFormRole,
                        decoration: const InputDecoration(labelText: 'Rol', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: UserRole.student, child: Text('Estudiante')),
                          DropdownMenuItem(value: UserRole.teacher, child: Text('Tutor')),
                          DropdownMenuItem(value: UserRole.admin, child: Text('Administrador')),
                        ],
                        onChanged: (value) {
                          setDialogState(() => _selectedFormRole = value!);
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      if (_selectedFormRole == UserRole.student) ...[
                        const Divider(),
                        const Text('Datos de Estudiante', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _codigoEstudianteController,
                          decoration: const InputDecoration(labelText: 'Código de Estudiante', border: OutlineInputBorder()),
                          validator: (v) => _selectedFormRole == UserRole.student && v!.isEmpty ? 'Campo requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _cicloController,
                          decoration: const InputDecoration(labelText: 'Ciclo', border: OutlineInputBorder()),
                          validator: (v) => _selectedFormRole == UserRole.student && v!.isEmpty ? 'Campo requerido' : null,
                        ),
                         const SizedBox(height: 16),
                        TextFormField(
                          controller: _edadController,
                           decoration: const InputDecoration(labelText: 'Edad', border: OutlineInputBorder()),
                           keyboardType: TextInputType.number,
                           validator: (v) => _selectedFormRole == UserRole.student && v!.isEmpty ? 'Campo requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _especialidadEstudianteController,
                          decoration: const InputDecoration(labelText: 'Especialidad (Carrera)', border: OutlineInputBorder()),
                          validator: (v) => _selectedFormRole == UserRole.student && v!.isEmpty ? 'Campo requerido' : null,
                        ),
                      ],

                      if (_selectedFormRole == UserRole.teacher) ...[
                        const Divider(),
                        const Text('Datos de Tutor', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _escuelaTutorController,
                          decoration: const InputDecoration(labelText: 'Escuela Profesional', border: OutlineInputBorder()),
                           validator: (v) => _selectedFormRole == UserRole.teacher && v!.isEmpty ? 'Campo requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _especialidadTutorController,
                          decoration: const InputDecoration(labelText: 'Especialidad (Área)', border: OutlineInputBorder()),
                           validator: (v) => _selectedFormRole == UserRole.teacher && v!.isEmpty ? 'Campo requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _cursosTutorController,
                          decoration: const InputDecoration(labelText: 'Cursos (separados por coma)', border: OutlineInputBorder()),
                           validator: (v) => _selectedFormRole == UserRole.teacher && v!.isEmpty ? 'Campo requerido' : null,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                ElevatedButton(onPressed: () => _saveUser(user: user), child: Text(isCreating ? 'Crear' : 'Guardar')),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Row(
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
                DropdownMenuItem(value: UserRole.student, child: Text('Estudiantes')),
                DropdownMenuItem(value: UserRole.teacher, child: Text('Tutores')),
                DropdownMenuItem(value: UserRole.admin, child: Text('Administradores')),
              ],
              onChanged: (value) {
                setState(() => _selectedRoleFilter = value);
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
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
                Text(user.email ?? 'Sin email'),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    user.isActive ? Icons.block : Icons.check_circle_outline,
                    color: user.isActive ? Colors.red : Colors.green,
                  ),
                  onPressed: () => _toggleUserStatus(user.id, user.isActive),
                  tooltip: user.isActive ? 'Desactivar Usuario' : 'Activar Usuario',
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blueGrey),
                  onPressed: () => _showUserFormDialog(user: user),
                  tooltip: 'Editar Usuario',
                ),
                if (user.role == UserRole.teacher)
                  IconButton(
                    icon: const Icon(Icons.manage_accounts, color: Colors.purple),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AssignStudentsPage(
                            tutorId: user.id,
                            tutorName: '${user.nombre ?? ''} ${user.apellidos ?? ''}'.trim(),
                          ),
                        ),
                      );
                    },
                    tooltip: 'Asignar Estudiantes',
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
}