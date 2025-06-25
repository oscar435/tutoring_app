import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/admin_user.dart';

class UserTable extends StatelessWidget {
  final List<AdminUser> users;
  final AdminUser currentAdmin;
  final Function(AdminUser) onEdit;
  final Function(AdminUser) onDelete;

  const UserTable({
    super.key,
    required this.users,
    required this.currentAdmin,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(
            label: Text(
              'Usuario',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
          DataColumn(
            label: Text(
              'Email',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
          DataColumn(
            label: Text(
              'Rol',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
          DataColumn(
            label: Text(
              'Estado',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
          DataColumn(
            label: Text(
              'Fecha Creación',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
          DataColumn(
            label: Text(
              'Acciones',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
        rows: users.map((user) => _buildUserRow(user, context)).toList(),
      ),
    );
  }

  DataRow _buildUserRow(AdminUser user, BuildContext context) {
    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: _getRoleColor(
                  user.role,
                ).withAlpha((0.1 * 255).toInt()),
                child: Text(
                  user.nombre.substring(0, 1).toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: _getRoleColor(user.role),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user.fullName,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'ID: ${user.id.substring(0, 8)}...',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        DataCell(Text(user.email, style: GoogleFonts.poppins())),
        DataCell(
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getRoleColor(user.role).withAlpha((0.1 * 255).toInt()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              user.roleDisplayName,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _getRoleColor(user.role),
              ),
            ),
          ),
        ),
        DataCell(
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: user.isActive
                  ? Colors.green.withAlpha((0.1 * 255).toInt())
                  : Colors.red.withAlpha((0.1 * 255).toInt()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  user.isActive ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: user.isActive ? Colors.green : Colors.red,
                ),
                SizedBox(width: 4),
                Text(
                  user.isActive ? 'Activo' : 'Inactivo',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: user.isActive ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ),
        DataCell(
          Text(
            _formatDate(user.createdAt),
            style: GoogleFonts.poppins(fontSize: 12),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botón Editar
              if (_canEditUser(user))
                IconButton(
                  onPressed: () => onEdit(user),
                  icon: Icon(Icons.edit, color: Colors.blue),
                  tooltip: 'Editar',
                ),
              // Botón Eliminar
              if (_canDeleteUser(user))
                IconButton(
                  onPressed: () => onDelete(user),
                  icon: Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Desactivar',
                ),
              // Botón Ver Detalles
              IconButton(
                onPressed: () => _showUserDetails(context, user),
                icon: Icon(Icons.visibility, color: Colors.grey),
                tooltip: 'Ver Detalles',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.student:
        return Colors.orange;
      case UserRole.teacher:
        return Colors.purple;
      case UserRole.admin:
        return Colors.blue;
      case UserRole.superAdmin:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  bool _canEditUser(AdminUser user) {
    // Un usuario no puede editarse a sí mismo
    if (user.id == currentAdmin.id) return false;

    // Verificar permisos del admin actual
    if (!currentAdmin.hasPermission(Permission.editUsers)) return false;

    // Un admin no puede editar super admins
    if (user.role == UserRole.superAdmin &&
        currentAdmin.role != UserRole.superAdmin) {
      return false;
    }

    return true;
  }

  bool _canDeleteUser(AdminUser user) {
    // Un usuario no puede eliminarse a sí mismo
    if (user.id == currentAdmin.id) return false;

    // Verificar permisos del admin actual
    if (!currentAdmin.hasPermission(Permission.deleteUsers)) return false;

    // Un admin no puede eliminar super admins
    if (user.role == UserRole.superAdmin &&
        currentAdmin.role != UserRole.superAdmin) {
      return false;
    }

    return true;
  }

  void _showUserDetails(BuildContext context, AdminUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles del Usuario'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Nombre', user.fullName),
              _buildDetailRow('Email', user.email),
              _buildDetailRow('Rol', user.roleDisplayName),
              _buildDetailRow('Estado', user.isActive ? 'Activo' : 'Inactivo'),
              _buildDetailRow('Fecha Creación', _formatDate(user.createdAt)),
              if (user.lastLogin != null)
                _buildDetailRow('Último Login', _formatDate(user.lastLogin!)),
              if (user.lastModified != null)
                _buildDetailRow(
                  'Última Modificación',
                  _formatDate(user.lastModified!),
                ),
              if (user.modifiedBy != null)
                _buildDetailRow('Modificado por', user.modifiedBy!),
              SizedBox(height: 16),
              Text(
                'Permisos:',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: user.permissions.map((permission) {
                  return Chip(
                    label: Text(_getPermissionDisplayName(permission)),
                    backgroundColor: Colors.blue.withAlpha((0.1 * 255).toInt()),
                    labelStyle: GoogleFonts.poppins(fontSize: 12),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.poppins(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  String _getPermissionDisplayName(Permission permission) {
    switch (permission) {
      case Permission.viewUsers:
        return 'Ver Usuarios';
      case Permission.createUsers:
        return 'Crear Usuarios';
      case Permission.editUsers:
        return 'Editar Usuarios';
      case Permission.deleteUsers:
        return 'Eliminar Usuarios';
      case Permission.assignRoles:
        return 'Asignar Roles';
      case Permission.viewAuditLogs:
        return 'Ver Auditoría';
      case Permission.manageSystem:
        return 'Gestionar Sistema';
    }
  }
}
