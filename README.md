# Finanzas Familiares AS

Aplicación de finanzas personales con arquitectura **Offline-First**, diseñada para el contexto financiero colombiano.

## Características Principales

- **Offline-First**: Funciona sin conexión, sincroniza cuando hay red
- **Partida Doble**: Motor contable profesional oculto tras UI simple
- **Transacciones Recurrentes**: Pagos automáticos (EDEQ, Netflix, etc.)
- **Presupuestos**: Control de gastos por categoría con semáforos
- **Reportes Financieros**: Balance General, Estado de Resultados, Flujo de Efectivo
- **Asistente IA "Fina"**: Consejos financieros personalizados
- **Multi-plataforma**: Android, iOS, Web (Flutter)

## Stack Tecnológico

| Componente | Tecnología |
|------------|------------|
| Framework | Flutter 3.x |
| Base de Datos Local | Drift (SQLite) |
| Sincronización | PowerSync + Supabase |
| Estado | Riverpod 3.0 |
| Auth | Google Sign-In + Supabase Auth |

## Inicio Rápido

```bash
# Clonar repositorio
git clone <repo-url>
cd finanzas-familiares-as

# Usar versión correcta de Flutter (FVM)
fvm use

# Instalar dependencias
flutter pub get

# Generar código (Drift, Freezed, Riverpod)
dart run build_runner build --delete-conflicting-outputs

# Ejecutar tests
flutter test

# Ejecutar app
flutter run
```

## Documentación

| Documento | Descripción |
|-----------|-------------|
| [CLAUDE.md](CLAUDE.md) | Reglas de sesión para Claude Code |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Filosofía Offline-First |
| [docs/DATABASE.md](docs/DATABASE.md) | Esquema Drift documentado |
| [docs/TESTING.md](docs/TESTING.md) | Tests categorizados (363+) |
| [docs/SYNC.md](docs/SYNC.md) | Estrategia de sincronización |
| [docs/ERRORS.md](docs/ERRORS.md) | Errores comunes y soluciones |

## Estructura del Proyecto

```
lib/
├── core/                 # Utilidades, constantes, extensiones
├── data/
│   ├── local/           # Drift (tables, daos, database)
│   ├── remote/          # Supabase services
│   └── sync/            # PowerSync connector
├── domain/
│   ├── entities/        # Modelos de dominio (Freezed)
│   ├── repositories/    # Interfaces
│   └── services/        # Lógica de negocio
├── application/
│   └── providers/       # Riverpod providers
├── presentation/
│   ├── screens/         # Pantallas
│   ├── widgets/         # Widgets reutilizables
│   └── theme/           # Material 3 theme
└── main.dart

test/
├── unit/                # Tests unitarios
├── data/                # Tests de DAOs
└── presentation/        # Tests de widgets
```

## Fases Completadas

- [x] Fase 1-5: Arquitectura base, Schema, TDD, Import/Export, Backup
- [x] Fase 6-13: Dashboard, Cuentas, Formularios, Indicadores
- [x] Fase 14: Reportes Financieros
- [x] Fase 15: Asistente IA "Fina"
- [x] Fase 16: Auth Flow (Google Sign-In)
- [x] Fase 17: Onboarding
- [x] Fase 18: Transacciones Recurrentes

## Licencia

Proyecto privado - Todos los derechos reservados.
