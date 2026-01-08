# Finanzas Familiares v2

App de finanzas personales y familiares multiplataforma con soporte offline-first.

## Stack

- **Flutter 3.24+** - Framework UI
- **Riverpod** - State management
- **Drift + SQLite** - Base de datos local
- **Supabase** - Backend (Auth, DB, Sync)
- **go_router** - Navegacion

## Quick Start

```bash
flutter pub get
flutter run
```

## Estructura

```
lib/
├── core/           # Infraestructura
├── features/       # Modulos por funcionalidad
└── shared/         # Widgets compartidos
```
