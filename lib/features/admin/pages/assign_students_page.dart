import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Un modelo simple para manejar los datos del estudiante en la UI
class Student {
  final String id;
  final String name;
  final String email;

  Student({required this.id, required this.name, required this.email});
}

class AssignStudentsPage extends StatefulWidget {
  final String tutorId;
  final String tutorName;

  const AssignStudentsPage({
    super.key,
    required this.tutorId,
    required this.tutorName,
  });

  @override
  State<AssignStudentsPage> createState() => _AssignStudentsPageState();
}

class _AssignStudentsPageState extends State<AssignStudentsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;

  List<Student> _assignedStudents = [];
  List<Student> _unassignedStudents = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Cargar todos los estudiantes
      final studentsSnapshot = await _firestore.collection('estudiantes').get();
      final allStudents = studentsSnapshot.docs.map((doc) {
        final data = doc.data();
        return Student(
          id: doc.id,
          name: '${data['nombre'] ?? ''} ${data['apellidos'] ?? ''}'.trim(),
          email: data['email'] ?? '',
        );
      }).toList();

      // 2. Cargar el documento del tutor para obtener la lista de IDs asignados
      final tutorDoc = await _firestore.collection('tutores').doc(widget.tutorId).get();
      final assignedStudentIds = tutorDoc.exists && tutorDoc.data()!.containsKey('estudiantes_asignados')
          ? List<String>.from(tutorDoc.data()!['estudiantes_asignados'])
          : <String>[];

      // 3. Separar los estudiantes en las dos listas
      final assigned = <Student>[];
      final unassigned = <Student>[];

      for (final student in allStudents) {
        if (assignedStudentIds.contains(student.id)) {
          assigned.add(student);
        } else {
          unassigned.add(student);
        }
      }

      setState(() {
        _assignedStudents = assigned;
        _unassignedStudents = unassigned;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar los datos: $e')),
        );
      }
    }
  }

  void _assignStudent(Student student) {
    setState(() {
      _unassignedStudents.remove(student);
      _assignedStudents.add(student);
    });
  }

  void _unassignStudent(Student student) {
    setState(() {
      _assignedStudents.remove(student);
      _unassignedStudents.add(student);
    });
  }

  Future<void> _saveChanges() async {
     setState(() => _isLoading = true);
     try {
       final newAssignedIds = _assignedStudents.map((s) => s.id).toList();
       await _firestore.collection('tutores').doc(widget.tutorId).set(
         {'estudiantes_asignados': newAssignedIds},
         SetOptions(merge: true),
       );

       if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Asignaciones guardadas correctamente'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
       }
     } catch (e) {
        setState(() => _isLoading = false);
        if(mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar los cambios: $e'), backgroundColor: Colors.red),
          );
        }
     }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Asignar a ${widget.tutorName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveChanges,
            tooltip: 'Guardar Cambios',
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStudentColumn('Estudiantes Asignados', _assignedStudents, _unassignStudent, Icons.remove_circle, Colors.red),
                const VerticalDivider(width: 1),
                _buildStudentColumn('Estudiantes Disponibles', _unassignedStudents, _assignStudent, Icons.add_circle, Colors.green),
              ],
            ),
    );
  }

  Widget _buildStudentColumn(String title, List<Student> students, ValueChanged<Student> onAction, IconData icon, Color iconColor) {
    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          const Divider(),
          if (students.isEmpty)
            const Expanded(
              child: Center(child: Text('No hay estudiantes en esta lista.'))
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];
                  return ListTile(
                    title: Text(student.name),
                    subtitle: Text(student.email, style: const TextStyle(fontSize: 12)),
                    trailing: IconButton(
                      icon: Icon(icon, color: iconColor),
                      onPressed: () => onAction(student),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
} 