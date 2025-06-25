import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../core/models/admin_user.dart';
import '../core/services/role_management_service.dart';
import '../core/services/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase con la configuración específica para web
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(MigrationApp());
}

class MigrationApp extends StatelessWidget {
  const MigrationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Migración de Usuarios',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: MigrationPage(),
    );
  }
}

class MigrationPage extends StatefulWidget {
  const MigrationPage({super.key});

  @override
  _MigrationPageState createState() => _MigrationPageState();
}

class _MigrationPageState extends State<MigrationPage> {
  bool _isMigrating = false;
  String _status = 'Listo para migrar';
  final List<String> _logs = [];

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)}: $message');
    });
  }

  Future<void> _startMigration() async {
    setState(() {
      _isMigrating = true;
      _status = 'Iniciando migración...';
      _logs.clear();
    });

    try {
      await migrateUsersToAdminSystem();
      setState(() {
        _status = '✅ Migración completada exitosamente!';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Error durante la migración: $e';
      });
    } finally {
      setState(() {
        _isMigrating = false;
      });
    }
  }

  Future<void> migrateUsersToAdminSystem() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final RoleManagementService roleService = RoleManagementService();
    
    // Limpiar la colección users antes de migrar
    _addLog('🧹 Limpiando colección users...');
    final existingUsers = await firestore.collection('users').get();
    for (var doc in existingUsers.docs) {
      await doc.reference.delete();
    }
    _addLog('  ✅ Colección users limpiada');
    
    // 1. Migrar tutores primero
    _addLog('👨‍🏫 Migrando tutores...');
    final tutoresSnapshot = await firestore.collection('tutores').get();
    int tutoresMigrados = 0;
    
    for (var doc in tutoresSnapshot.docs) {
      try {
        final data = doc.data();
        final userId = doc.id;
        
        // Crear usuario en la colección users
        final user = AdminUser(
          id: userId,
          email: data['email'] ?? '',
          nombre: data['nombre'] ?? '',
          apellidos: data['apellidos'] ?? '',
          role: UserRole.teacher,
          permissions: roleService.getPermissionsForRole(UserRole.teacher),
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isActive: true,
          createdBy: 'system_migration',
        );
        
        await firestore.collection('users').doc(userId).set(user.toFirestore());
        tutoresMigrados++;
        _addLog('  ✅ ${user.fullName} migrado como tutor');
      } catch (e) {
        _addLog('  ❌ Error migrando tutor ${doc.id}: $e');
      }
    }
    
    _addLog('  📊 Total tutores migrados: $tutoresMigrados');
    
    // 2. Migrar estudiantes
    _addLog('📚 Migrando estudiantes...');
    final estudiantesSnapshot = await firestore.collection('estudiantes').get();
    int estudiantesMigrados = 0;
    
    for (var doc in estudiantesSnapshot.docs) {
      try {
        final data = doc.data();
        final userId = doc.id;
        
        // Crear usuario en la colección users
        final user = AdminUser(
          id: userId,
          email: data['email'] ?? '',
          nombre: data['nombre'] ?? '',
          apellidos: data['apellidos'] ?? '',
          role: UserRole.student,
          permissions: roleService.getPermissionsForRole(UserRole.student),
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isActive: true,
          createdBy: 'system_migration',
        );
        
        await firestore.collection('users').doc(userId).set(user.toFirestore());
        estudiantesMigrados++;
        _addLog('  ✅ ${user.fullName} migrado como estudiante');
      } catch (e) {
        _addLog('  ❌ Error migrando estudiante ${doc.id}: $e');
      }
    }
    
    _addLog('  📊 Total estudiantes migrados: $estudiantesMigrados');
    
    // 3. Crear super administrador inicial
    _addLog('👑 Creando super administrador inicial...');
    try {
      const superAdminEmail = 'admin@unfv.edu.pe';
      const superAdminPassword = 'AdminUnfv2024!';
      
      // Verificar si ya existe
      final existingAdmin = await firestore
          .collection('users')
          .where('email', isEqualTo: superAdminEmail)
          .get();
      
      if (existingAdmin.docs.isNotEmpty) {
        _addLog('  ⚠️  Super administrador ya existe');
      } else {
        // Crear super administrador
        final superAdmin = AdminUser(
          id: 'super_admin_001',
          email: superAdminEmail,
          nombre: 'Super',
          apellidos: 'Administrador',
          role: UserRole.superAdmin,
          permissions: roleService.getPermissionsForRole(UserRole.superAdmin),
          createdAt: DateTime.now(),
          isActive: true,
          createdBy: 'system_migration',
        );
        
        await firestore.collection('users').doc(superAdmin.id).set(superAdmin.toFirestore());
        _addLog('  ✅ Super administrador creado: ${superAdmin.fullName}');
        _addLog('  📧 Email: $superAdminEmail');
        _addLog('  🔑 Password: $superAdminPassword');
      }
    } catch (e) {
      _addLog('  ❌ Error creando super administrador: $e');
    }
    
    // 4. Crear índices compuestos necesarios
    _addLog('🔍 Creando índices compuestos...');
    _addLog('  ℹ️  Nota: Los índices deben crearse manualmente en Firebase Console');
    _addLog('  📋 Índices necesarios:');
    _addLog('    - users: role (Ascending) + createdAt (Descending)');
    _addLog('    - users: isActive (Ascending) + createdAt (Descending)');
    _addLog('    - users: email (Ascending)');
    _addLog('    - audit_logs: action (Ascending) + timestamp (Descending)');
    _addLog('    - audit_logs: userId (Ascending) + timestamp (Descending)');
    
    // 5. Generar reporte final
    _addLog('📊 Generando reporte final...');
    final stats = await _generateUserStatistics();
    
    _addLog('  📈 Estadísticas finales:');
    _addLog('    - Total usuarios: ${stats['total']}');
    _addLog('    - Estudiantes: ${stats['students']}');
    _addLog('    - Tutores: ${stats['teachers']}');
    _addLog('    - Administradores: ${stats['admins']}');
    _addLog('    - Usuarios activos: ${stats['active']}');
    _addLog('    - Usuarios inactivos: ${stats['inactive']}');
    
    _addLog('🎉 Migración completada!');
    _addLog('💡 Próximos pasos:');
    _addLog('   1. Crear los índices compuestos en Firebase Console');
    _addLog('   2. Probar el panel de administración web');
    _addLog('   3. Configurar reglas de seguridad de Firestore');
  }

  Future<Map<String, int>> _generateUserStatistics() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final usersSnapshot = await firestore.collection('users').get();
    
    Map<String, int> stats = {
      'total': 0,
      'students': 0,
      'teachers': 0,
      'admins': 0,
      'active': 0,
      'inactive': 0,
    };
    
    for (var doc in usersSnapshot.docs) {
      final data = doc.data();
      stats['total'] = (stats['total'] ?? 0) + 1;
      
      if (data['isActive'] == true) {
        stats['active'] = (stats['active'] ?? 0) + 1;
      } else {
        stats['inactive'] = (stats['inactive'] ?? 0) + 1;
      }
      
      switch (data['role']) {
        case 'student':
          stats['students'] = (stats['students'] ?? 0) + 1;
          break;
        case 'teacher':
          stats['teachers'] = (stats['teachers'] ?? 0) + 1;
          break;
        case 'admin':
        case 'superAdmin':
          stats['admins'] = (stats['admins'] ?? 0) + 1;
          break;
      }
    }
    
    return stats;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Migración de Usuarios al Sistema de Administración'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estado: $_status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _status.contains('✅') ? Colors.green : 
                               _status.contains('❌') ? Colors.red : Colors.blue,
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isMigrating ? null : _startMigration,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      child: _isMigrating 
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('Migrando...'),
                            ],
                          )
                        : Text('Iniciar Migración'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Logs de Migración:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Text(
                        log,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: log.contains('✅') ? Colors.green :
                                 log.contains('❌') ? Colors.red :
                                 log.contains('⚠️') ? Colors.orange :
                                 Colors.black87,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 