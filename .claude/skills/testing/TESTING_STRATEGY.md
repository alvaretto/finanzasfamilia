# Testing Strategy - Finanzas Familiares

## Overview
Estrategia integral de testing para PWA Flutter + Supabase Android.

## Test Categories

### 1. Unit Tests (`test/unit/`)
Tests de logica de negocio aislada:
- Modelos de datos (serialization/deserialization)
- Validaciones
- Calculos financieros
- Funciones puras

```bash
flutter test test/unit/
```

### 2. Widget Tests (`test/widget/`)
Tests de UI individual:
- Renderizado correcto
- Interacciones basicas
- Estados de widgets

```bash
flutter test test/widget/
```

### 3. Integration Tests (`test/integration/`)
Tests de flujo completo:
- Navegacion entre pantallas
- Formularios end-to-end
- Interaccion con providers

```bash
flutter test test/integration/
```

### 4. E2E Tests (`test/e2e/`)
Tests agresivos de produccion:
- Flujos criticos de usuario
- Edge cases
- Estados de error

```bash
flutter test test/e2e/
```

### 5. PWA/Offline Tests (`test/pwa/`)
Tests de comportamiento offline-first:
- Operaciones sin conexion
- Sincronizacion
- Persistencia local
- Cola de sync

```bash
flutter test test/pwa/
```

### 6. Supabase Tests (`test/supabase/`)
Tests de integracion con backend:
- Autenticacion (login, logout, registro)
- Seguridad RLS
- Realtime subscriptions
- Manejo de sesiones

```bash
flutter test test/supabase/
```

### 7. Performance Tests (`test/performance/`)
Tests de rendimiento:
- Tiempos de respuesta
- Operaciones bulk
- Eficiencia de queries
- Memory leaks

```bash
flutter test test/performance/
```

### 8. Android Compatibility (`test/android/`)
Tests de compatibilidad:
- Diferentes tamanos de pantalla
- Orientaciones
- Font scaling
- System UI (notch, nav bar)

```bash
flutter test test/android/
```

### 9. Production Tests (`test/production/`)
Tests de robustez para produccion:
- Valores extremos
- Caracteres especiales
- Stress tests
- Division por cero

```bash
flutter test test/production/
```

## Commands

### Run All Tests
```bash
flutter test
```

### Run with Coverage
```bash
flutter test --coverage
```

### Run Specific Category
```bash
flutter test test/<category>/
```

### Run Single File
```bash
flutter test test/path/to/test.dart
```

## Best Practices

1. **Test Isolation**: Cada test debe ser independiente
2. **Setup/Teardown**: Usar `setUpAll()` y `tearDownAll()` para Supabase test mode
3. **Naming**: Descripcion clara de lo que se testea
4. **Assertions**: Un expect principal por test
5. **Mocking**: Usar test mode para Supabase, no mocks complejos

## CI/CD Integration

Tests se ejecutan automaticamente en:
- Push a main
- Pull requests
- Pre-release

Ver `.github/workflows/` para configuracion.
