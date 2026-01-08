# Finanzas Familiares v2

App de finanzas personales y familiares multiplataforma con soporte offline-first.

**Moneda por defecto**: COP (Peso Colombiano)

## Quick Start

```bash
flutter pub get && flutter run
flutter test
flutter build apk --release
```

## Stack

| Tecnologia | Uso |
|------------|-----|
| Flutter 3.24+ | Framework UI |
| Riverpod | State management |
| Drift + SQLite | Base de datos local |
| Supabase | Backend (Auth, DB, Sync) |
| go_router | Navegacion |

## Estructura

```
lib/
├── core/           # Infraestructura (DB, network, theme)
├── features/       # Modulos por funcionalidad
└── shared/         # Widgets compartidos
```

## Principios

1. **Offline-First**: Guardar local primero, sincronizar despues
2. **Clean Architecture**: Separacion clara de capas
3. **Test-Driven**: Tests antes de implementar
