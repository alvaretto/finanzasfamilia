---
name: flutter-architecture
description: Implementa patrones Flutter + Riverpod para Finanzas Familiares. Incluye estructura de features, providers, widgets, y navegacion. Usar cuando se creen providers, widgets, o se maneje estado.
---

# Flutter Architecture

Patrones de arquitectura para Finanzas Familiares.

## Stack Tecnologico

- **Flutter 3.24+** - Framework UI
- **Riverpod 3.0** - State management
- **Drift** - Base de datos local (SQLite)
- **Supabase** - Backend (Auth, DB, Realtime)
- **go_router** - Navegacion
- **fl_chart** - Graficos

## Estructura de Features

```
lib/features/{feature}/
├── data/
│   ├── models/           # Modelos de datos
│   ├── repositories/     # Acceso a datos
│   └── datasources/      # Fuentes (local/remote)
├── domain/
│   └── entities/         # Entidades de dominio
├── presentation/
│   ├── providers/        # Riverpod providers
│   ├── screens/          # Pantallas
│   └── widgets/          # Widgets reutilizables
└── {feature}.dart        # Barrel export
```

## Patron de Provider (Riverpod)

```dart
/// Estado
class FeatureState {
  final List<Model> items;
  final bool isLoading;
  final bool isSyncing;
  final String? errorMessage;

  const FeatureState({...});

  FeatureState copyWith({...});
}

/// Notifier
class FeatureNotifier extends StateNotifier<FeatureState> {
  final Repository _repository;
  final String? _userId;

  FeatureNotifier(this._repository, this._userId)
    : super(const FeatureState(isLoading: true)) {
    if (_userId != null) _init();
  }

  void _init() {
    // Observar datos locales
    _repository.watch(_userId!).listen((data) {
      state = state.copyWith(items: data, isLoading: false);
    });
  }
}

/// Provider
final featureProvider = StateNotifierProvider<FeatureNotifier, FeatureState>((ref) {
  final repository = ref.watch(repositoryProvider);
  final auth = ref.watch(authProvider);
  return FeatureNotifier(repository, auth.user?.id);
});
```

## Navegacion (go_router)

```dart
final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const HomeScreen(),
      routes: [
        GoRoute(
          path: 'accounts',
          builder: (_, __) => const AccountsScreen(),
        ),
        GoRoute(
          path: 'transactions',
          builder: (_, __) => const TransactionsScreen(),
        ),
      ],
    ),
  ],
);
```

## Documentacion Detallada

- [PROVIDERS.md](PROVIDERS.md) - Patrones de providers
- [WIDGETS.md](WIDGETS.md) - Widgets reutilizables
- [NAVIGATION.md](NAVIGATION.md) - Navegacion y rutas
- [FORMS.md](FORMS.md) - Formularios y validacion

## Convenciones de Nombrado

| Tipo | Convencion | Ejemplo |
|------|------------|---------|
| Archivos | snake_case | `transaction_provider.dart` |
| Clases | PascalCase | `TransactionProvider` |
| Variables | camelCase | `transactionList` |
| Constantes | SCREAMING_SNAKE | `MAX_ITEMS` |
| Providers | camelCase + Provider | `transactionsProvider` |
