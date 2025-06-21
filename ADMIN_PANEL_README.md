# 🎛️ Panel de Administración - Sistema de Tutorías UNFV

## 📋 Descripción General

El Panel de Administración es una aplicación web separada de la app móvil que permite gestionar usuarios, roles y permisos del sistema de tutorías. Está diseñado exclusivamente para administradores y super administradores.

## 🏗️ Arquitectura

### Separación de Aplicaciones
- **App Móvil**: Flutter (actual) - Solo para estudiantes y tutores
- **Panel Web**: Flutter Web - Solo para administradores
- **Base de Datos**: Firebase Firestore (compartida)

### Estructura de Carpetas
```
lib/
├── core/
│   ├── models/
│   │   ├── admin_user.dart          # Modelo de usuario administrador
│   │   └── audit_log.dart           # Modelo de auditoría
│   └── services/
│       ├── user_management_service.dart    # CRUD de usuarios
│       └── role_management_service.dart    # Gestión de roles
├── features/
│   └── admin/
│       ├── pages/
│       │   ├── admin_dashboard_page.dart   # Dashboard principal
│       │   └── user_management_page.dart   # Gestión de usuarios
│       └── widgets/
│           ├── stats_card.dart             # Tarjetas de estadísticas
│           └── user_table.dart             # Tabla de usuarios
└── scripts/
    └── migrate_users_to_admin_system.dart  # Script de migración
```

## 🎯 Funcionalidades Implementadas

### ✅ HU-13: Gestión de Usuarios
- [x] **Interfaz CRUD de usuarios** - Montes Oscar
  - Crear nuevos usuarios
  - Editar información de usuarios
  - Desactivar usuarios (eliminación lógica)
  - Ver detalles completos de usuarios
- [x] **Validación de datos y roles** - Yapias James
  - Validación de email único
  - Validación de permisos jerárquicos
  - Validación de datos requeridos
- [x] **Control de duplicados y errores** - Quispe David
  - Prevención de emails duplicados
  - Manejo de errores de Firebase
  - Validación de permisos antes de acciones
- [x] **Visualización filtrada por rol** - Leandro Gustavo
  - Filtros por rol (Estudiante, Tutor, Admin, SuperAdmin)
  - Filtros por estado (Activo/Inactivo)
  - Búsqueda por nombre, apellidos o email
  - Paginación de resultados

### ✅ HU-42: Gestión de Roles y Permisos
- [x] **Estructura jerárquica de roles y permisos** - Leandro Gustavo
  - 4 niveles de roles: Student → Teacher → Admin → SuperAdmin
  - Permisos granulares por funcionalidad
  - Jerarquía de permisos automática
- [x] **Módulo de asignación de permisos** - Yapias James
  - Asignación automática de permisos por rol
  - Validación de permisos para asignar roles
  - Interfaz visual de permisos
- [x] **Validar accesos en base al rol asignado** - Quispe David
  - Middleware de validación de permisos
  - Control de acceso a funcionalidades
  - Prevención de escalación de privilegios
- [x] **Auditoría de cambios en roles** - Montes Oscar
  - Registro de todos los cambios de roles
  - Historial de modificaciones
  - Trazabilidad completa de acciones
- [x] **Reporte de usuarios por rol** - Quispe David
  - Estadísticas por rol
  - Gráficos de distribución
  - Reportes exportables

## 🔐 Sistema de Roles y Permisos

### Roles Disponibles
1. **Student** (Estudiante)
   - Ver usuarios (solo estudiantes)
   - Acceso limitado a funcionalidades básicas

2. **Teacher** (Tutor)
   - Ver usuarios
   - Editar información de estudiantes
   - Gestión de tutorías

3. **Admin** (Administrador)
   - Ver usuarios
   - Crear usuarios
   - Editar usuarios
   - Asignar roles (estudiantes y tutores)
   - Ver auditoría

4. **SuperAdmin** (Super Administrador)
   - Todos los permisos
   - Gestionar administradores
   - Acceso completo al sistema

### Permisos Granulares
- `viewUsers`: Ver lista de usuarios
- `createUsers`: Crear nuevos usuarios
- `editUsers`: Editar información de usuarios
- `deleteUsers`: Desactivar usuarios
- `assignRoles`: Asignar roles a usuarios
- `viewAuditLogs`: Ver registros de auditoría
- `manageSystem`: Gestión completa del sistema

## 🚀 Instalación y Configuración

### 1. Preparar el Entorno
```bash
# Clonar el repositorio
git clone <repository-url>
cd tutoring_app

# Instalar dependencias
flutter pub get
```

### 2. Configurar Firebase
```bash
# Configurar Firebase para web
flutterfire configure --platforms=web
```

### 3. Migrar Usuarios Existentes
```bash
# Ejecutar script de migración
dart run lib/scripts/migrate_users_to_admin_system.dart
```

### 4. Crear Índices en Firebase Console
Crear los siguientes índices compuestos en Firestore:

| Colección | Campo 1 | Campo 2 | Orden |
|-----------|---------|---------|-------|
| users | role | createdAt | Ascending + Descending |
| users | isActive | createdAt | Ascending + Descending |
| users | email | - | Ascending |
| audit_logs | action | timestamp | Ascending + Descending |
| audit_logs | userId | timestamp | Ascending + Descending |

### 5. Ejecutar Panel Web
```bash
# Ejecutar en modo web
flutter run -d chrome --web-port=8080
```

## 📊 Dashboard de Administración

### Estadísticas Generales
- Total de usuarios
- Usuarios activos/inactivos
- Distribución por roles
- Actividad reciente

### Gestión de Usuarios
- Tabla con paginación
- Filtros avanzados
- Acciones CRUD
- Vista de detalles

### Auditoría
- Registro de cambios
- Historial de acciones
- Filtros por fecha y usuario

## 🔧 Configuración de Seguridad

### Reglas de Firestore
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Usuarios
    match /users/{userId} {
      allow read: if request.auth != null && 
        (resource.data.role == 'student' || 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.permissions.hasAny(['viewUsers', 'editUsers', 'createUsers']));
      
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.permissions.hasAny(['createUsers', 'editUsers', 'deleteUsers']);
    }
    
    // Auditoría
    match /audit_logs/{logId} {
      allow read: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.permissions.hasAny(['viewAuditLogs']);
      
      allow write: if request.auth != null;
    }
  }
}
```

## 👥 Usuarios por Defecto

### Super Administrador
- **Email**: admin@unfv.edu.pe
- **Password**: AdminUnfv2024!
- **Rol**: SuperAdmin
- **Permisos**: Todos

## 📱 Separación App Móvil vs Panel Web

### App Móvil
- Solo estudiantes y tutores
- Funcionalidades de tutorías
- Interfaz optimizada para móvil
- Sin acceso administrativo

### Panel Web
- Solo administradores
- Gestión de usuarios y roles
- Interfaz optimizada para desktop
- Funcionalidades administrativas completas

## 🧪 Pruebas

### Pruebas de Funcionalidad
```bash
# Ejecutar tests
flutter test

# Ejecutar tests específicos
flutter test test/admin/
```

### Pruebas de Integración
1. Crear usuario administrador
2. Asignar roles
3. Verificar permisos
4. Probar auditoría

## 📈 Métricas y Monitoreo

### Métricas Clave
- Usuarios activos por rol
- Cambios de roles por día
- Acciones de auditoría
- Errores del sistema

### Logs de Auditoría
- Todas las acciones administrativas
- Cambios de roles
- Creación/edición de usuarios
- Accesos al sistema

## 🔄 Mantenimiento

### Tareas Periódicas
- Revisar logs de auditoría
- Limpiar usuarios inactivos
- Actualizar permisos según necesidades
- Backup de configuración

### Actualizaciones
- Mantener dependencias actualizadas
- Revisar reglas de seguridad
- Actualizar documentación

## 🆘 Soporte

### Problemas Comunes
1. **Error de permisos**: Verificar rol del usuario
2. **Usuarios no aparecen**: Ejecutar script de migración
3. **Errores de Firebase**: Verificar configuración y reglas

### Contacto
- **Desarrollador**: Equipo de Desarrollo UNFV
- **Email**: desarrollo@unfv.edu.pe
- **Documentación**: [Link a documentación completa]

## 📄 Licencia

Este proyecto es propiedad de la Universidad Nacional Federico Villarreal (UNFV) y está destinado exclusivamente para uso interno de la institución.

---

**Versión**: 1.0.0  
**Última actualización**: Diciembre 2024  
**Equipo**: Montes Oscar, Yapias James, Quispe David, Leandro Gustavo 