# Finanzas Familiares

Aplicación de finanzas personales con arquitectura **Offline-First**, diseñada para el contexto financiero colombiano.

## Características Principales

- **Offline-First**: Funciona sin conexión, sincroniza cuando hay red
- **Sincronización PowerSync**: Sync bidireccional con Supabase
- **Partida Doble**: Motor contable profesional oculto tras UI simple
- **Transacciones Recurrentes**: Pagos automáticos (servicios, suscripciones)
- **Presupuestos**: Control de gastos por categoría con semáforos visuales
- **Reportes Financieros**: Balance General, Estado de Resultados, Flujo de Efectivo
- **Gráficos Avanzados**: Pie chart de gastos, tendencias mensuales, comparativos
- **Metas de Ahorro**: Sistema gamificado con progreso visual y contribuciones
- **Asistente IA "Fina"**: Consejos financieros personalizados
- **Notificaciones**: Alertas de presupuesto y recordatorios
- **Firebase Crashlytics**: Monitoreo de errores en producción
- **Multi-plataforma**: Android, iOS

## Stack Tecnológico

| Componente | Tecnología |
|------------|------------|
| Framework | Flutter 3.x |
| Base de Datos Local | Drift (SQLite) |
| Sincronización | PowerSync + Supabase |
| Estado | Riverpod 3.0 |
| Auth | Google Sign-In + Supabase Auth |
| Monitoreo | Firebase Crashlytics + Analytics |
| Gráficos | fl_chart |
| Notificaciones | flutter_local_notifications |
| Export | Excel, CSV, PDF |

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

# Ejecutar app en modo debug
flutter run

# Build de release (Android)
flutter build apk --release
flutter build appbundle --release
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

### Firebase (Opcional)

1. Crea un proyecto en [Firebase Console](https://console.firebase.google.com)
2. Agrega una app Android con package name: `app.finanzasfamiliares`
3. Descarga `google-services.json` y colócalo en `android/app/`
4. Habilita Crashlytics en la consola de Firebase

## Build de Producción

### Android

```bash
# APK universal (para instalación directa)
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

# App Bundle (para Google Play)
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### Keystore de Producción

El keystore de producción debe configurarse en `android/key.properties`:

```properties
storePassword=your-store-password
keyPassword=your-key-password
keyAlias=finanzas_familiares
storeFile=keystore/finanzas-familiares.jks
```

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
│   └── services/        # Lógica de negocio (AccountingService)
├── application/
│   ├── providers/       # Riverpod providers
│   └── services/        # Export/Import services
├── presentation/
│   ├── screens/         # Pantallas
│   ├── widgets/         # Widgets reutilizables
│   └── theme/           # Material 3 theme
└── main.dart

android/
├── app/
│   ├── google-services.json  # Firebase config (no en repo)
│   ├── keystore/             # Release keystore (no en repo)
│   └── proguard-rules.pro    # ProGuard config
└── key.properties            # Keystore config (no en repo)

test/
├── unit/                # Tests unitarios
├── data/                # Tests de DAOs
├── integration/         # Tests de integración
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
| 24 | Preparación Store + Firebase | ✅ |
| 25 | Notificaciones Locales | ✅ |
| 26 | Gráficos Avanzados | ✅ |
| 27 | Metas de Ahorro | ✅ |

**Tests:** 447+ pasando | **Versión:** 1.3.0

## Changelog

### v1.3.0 (2026-01-09)
- Sistema de Metas de Ahorro completo:
  - CRUD de metas con nombre, monto objetivo, fecha límite
  - Contribuciones con historial y notas
  - Progress bar visual (lineal y circular)
  - Personalización con colores e iconos
  - Auto-completado al alcanzar meta
  - Estados: En Progreso, Completada, Pausada
- 35 tests nuevos (18 DAO + 17 screen)

### v1.2.0 (2026-01-09)
- Gráficos avanzados con fl_chart:
  - Pie chart de gastos por categoría
  - Line chart de tendencia mensual (ingresos vs gastos)
  - Comparativo mes actual vs anterior
- Pantalla de Estadísticas con 3 tabs
- Notificaciones locales (alertas de presupuesto, recordatorios)

### v1.1.0 (2026-01-09)
- Firebase Crashlytics y Analytics integrados
- Build de producción Android (APK + AAB)
- PowerSync completamente configurado
- Política de Privacidad y Términos de Servicio
- Ficha de tienda para Google Play y App Store
- App Icon personalizado

### v1.0.0 (2026-01-08)
- Release inicial con todas las funcionalidades core
- Sistema de partida doble completo
- Sincronización offline-first
- 21 fases de desarrollo completadas

## Contacto

- **Email:** soporte@finanzasfamiliares.app
- **GitHub Issues:** [Reportar problema](https://github.com/alvaretto/finanzasfamilia/issues)

## Licencia

Proyecto privado - Todos los derechos reservados.

---

Desarrollado con ❤️ en Colombia
