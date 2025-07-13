# 🎮 Sistema de Gamificación

## Descripción
Sistema de gamificación simple para estudiantes que incluye logros, puntos, niveles y ranking.

## 🏗️ Arquitectura

### Modelos
- **`Logro`**: Define logros con iconos, descripciones y puntos de recompensa
- **`ProgresoEstudiante`**: Rastrea el progreso del estudiante (puntos, nivel, estadísticas)

### Servicios
- **`GamificationService`**: Maneja toda la lógica de gamificación

### Páginas
- **`StudentGamificationPage`**: Página principal con pestañas para progreso, logros y ranking

### Widgets
- **`ProgressCard`**: Muestra nivel, puntos y progreso
- **`LogroCard`**: Muestra logros con estado desbloqueado/bloqueado
- **`RankingCard`**: Muestra ranking de estudiantes

## 🎯 Logros Disponibles

| Logro | Descripción | Puntos | Meta |
|-------|-------------|--------|------|
| 🎯 Primera Sesión | Completa tu primera sesión | 50 | 1 sesión |
| 📚 Estudiante Dedicado | Completa 5 sesiones | 100 | 5 sesiones |
| 🏆 Estudiante Consistente | Completa 10 sesiones | 200 | 10 sesiones |
| 👑 Estudiante Experto | Completa 15 sesiones | 300 | 15 sesiones |
| 💎 Maestro del Aprendizaje | Completa 20 sesiones | 500 | 20 sesiones |
| ⭐ Asistencia Perfecta | Asiste a 5 sesiones consecutivas | 150 | 5 asistencias |
| 🚀 Nivel 5 | Alcanza el nivel 5 | 300 | Nivel 5 |
| 🌟 Nivel 10 | Alcanza el nivel 10 | 600 | Nivel 10 |

## 📊 Sistema de Puntos

- **Sesión completada**: +25 puntos
- **Nivel**: Cada 100 puntos = 1 nivel

## 🚀 Instalación y Configuración

### 1. Inicializar Logros
```bash
# Ejecutar script de inicialización
dart run lib/scripts/initialize_gamification.dart
```

### 2. Sincronizar Estudiantes Existentes
```bash
# Sincronizar progreso de todos los estudiantes
dart run lib/scripts/sync_all_students_gamification.dart
```

### 3. Probar Sistema
```bash
# Ejecutar pruebas
dart run lib/scripts/test_gamification.dart
```

## 🔧 Integración con Otras Funcionalidades

### Sesiones de Tutoría
El sistema está **integrado automáticamente** con el flujo de sesiones:

**Cuando se registra una post-sesión:**
1. Se actualiza el estado de la sesión a "completada"
2. Se llama automáticamente a `completarSesion()` del estudiante
3. Se suman 25 puntos al estudiante
4. Se verifica si se desbloquean nuevos logros
5. Se actualiza el nivel si es necesario

**Sincronización automática:**
- Al abrir la página de gamificación, se sincroniza automáticamente con sesiones existentes
- Los estudiantes que ya tienen sesiones completadas verán su progreso inmediatamente



## 📱 Navegación

Los estudiantes pueden acceder a la gamificación desde:
- **Menú lateral** → **Gamificación**
- **Ruta**: `/gamification`

## 🎨 Características de la UI

### Pestañas
1. **Progreso**: Nivel actual, puntos, barra de progreso, estadísticas
2. **Logros**: Grid de logros con estado visual
3. **Ranking**: Top 10 estudiantes con posiciones

### Diseño
- **Simple y limpio**: Diseño universitario, no complejo
- **Colores**: Azul como color principal
- **Iconos**: Emojis para logros, iconos Material Design
- **Responsive**: Funciona en móvil y web

## 🔄 Flujo de Datos

1. **Estudiante completa sesión**
2. **Servicio actualiza progreso** en Firestore
3. **Se verifica logros** automáticamente
4. **UI se actualiza** en tiempo real
5. **Ranking se recalcula** automáticamente

## 📈 Métricas Rastreadas

- Puntos totales
- Nivel actual
- Sesiones completadas
- Sesiones asistidas
- Logros desbloqueados
- Fecha de creación y última actualización

## 🛠️ Desarrollo

### Agregar Nuevo Logro
1. Agregar en `_logrosPredefinidos` en `GamificationService`
2. Definir tipo, meta y puntos
3. Ejecutar script de inicialización

### Modificar Puntos
Editar en `GamificationService`:
- `completarSesion()`: +25 puntos

### Agregar Nuevo Tipo de Logro
1. Agregar caso en `_verificarLogrosDesbloqueados()`
2. Definir lógica de verificación
3. Actualizar UI si es necesario

## 🎯 Próximas Mejoras

- [ ] Notificaciones push para logros desbloqueados
- [ ] Animaciones al desbloquear logros
- [ ] Más tipos de logros (tiempo de estudio, etc.)
- [ ] Exportar estadísticas
- [ ] Logros especiales por temporada 