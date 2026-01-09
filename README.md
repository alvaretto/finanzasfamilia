# Finanzas Familiares

Aplicación de finanzas personales con arquitectura **Offline-First**, diseñada para el contexto financiero colombiano.

## Características Principales

- **Offline-First**: Funciona sin conexión, sincroniza cuando hay red
- **Sincronización PowerSync**: Sync bidireccional con Supabase
- **Partida Doble**: Motor contable profesional oculto tras UI simple
- **Transacciones Recurrentes**: Pagos automáticos (servicios, suscripciones)
- **Presupuestos**: Control de gastos por categoría con semáforos
- **Reportes Financieros**: Balance General, Estado de Resultados, Flujo de Efectivo
- **Asistente IA "Fina"**: Consejos financieros personalizados
- **Multi-plataforma**: Android, iOS

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
git clone https://github.com/alvaretto/finanzasfamilia.git
cd finanzas-familiares-as

# Usar versión correcta de Flutter (FVM)
fvm use

# Instalar dependencias
flutter pub get

# Generar código (Drift, Freezed, Riverpod)
dart run build_runner build --delete-conflicting-outputs

# Configurar variables de entorno
cp .env.example .env
# Editar .env con tus credenciales de Supabase y PowerSync

# Ejecutar tests
flutter test

# Ejecutar app
flutter run
```

## Configuración

### Variables de Entorno

Crea un archivo `.env` basado en `.env.example`:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
POWERSYNC_URL=https://your-instance-id.powersync.journeyapps.com
```

### Supabase

1. Crea un proyecto en [Supabase](https://supabase.com)
2. Ejecuta las migraciones en `supabase/migrations/`
3. Configura las políticas RLS para cada tabla

### PowerSync

1. Crea un proyecto en [PowerSync](https://www.powersync.com)
2. Conecta tu base de datos Supabase
3. Configura las Sync Rules (ver `supabase/powersync/sync_rules.yaml`)
4. Configura Client Auth con Supabase JWT

## Documentación

| Documento | Descripción |
|-----------|-------------|
| [CLAUDE.md](CLAUDE.md) | Reglas de sesión para Claude Code |
| [docs/PRIVACY_POLICY.md](docs/PRIVACY_POLICY.md) | Política de Privacidad |
| [docs/TERMS_OF_SERVICE.md](docs/TERMS_OF_SERVICE.md) | Términos de Servicio |
| [docs/STORE_LISTING.md](docs/STORE_LISTING.md) | Ficha de tienda (Play/App Store) |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Filosofía Offline-First |
| [docs/DATABASE.md](docs/DATABASE.md) | Esquema Drift documentado |
| [docs/TESTING.md](docs/TESTING.md) | Tests categorizados |
| [docs/SYNC.md](docs/SYNC.md) | Estrategia de sincronización |

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

## Estado del Proyecto

| Fase | Descripción | Estado |
|------|-------------|--------|
| 1-5 | Arquitectura, Schema, TDD, Import/Export, Backup | ✅ |
| 6-13 | Dashboard, Cuentas, Formularios, Indicadores | ✅ |
| 14 | Reportes Financieros | ✅ |
| 15 | Asistente IA "Fina" | ✅ |
| 16 | Auth Flow (Google Sign-In) | ✅ |
| 17 | Onboarding | ✅ |
| 18 | Transacciones Recurrentes | ✅ |
| 19 | Selector Categorías Jerárquico | ✅ |
| 20 | Sistema de Presupuestos CRUD | ✅ |
| 21 | Edición/Eliminación Transacciones | ✅ |
| 22 | Pulido UI/UX (Pre-Release) | ✅ |
| 23 | Sincronización PowerSync | ✅ |
| **24** | **Preparación Store** | ✅ |

**Tests:** 394+ pasando

## Contacto

- **Email:** soporte@finanzasfamiliares.app
- **GitHub Issues:** [Reportar problema](https://github.com/alvaretto/finanzasfamilia/issues)

## Licencia

Proyecto privado - Todos los derechos reservados.

---

Desarrollado con ❤️ en Colombia
