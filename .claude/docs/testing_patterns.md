# Patrones de Testing - Finanzas Familiares AS

## Problemas Comunes y Soluciones

### 1. Tests con Animaciones Infinitas (CircularProgressIndicator)

**Problema:** `pumpAndSettle()` nunca termina cuando hay widgets con animaciones infinitas como `CircularProgressIndicator`.

**Síntoma:**
```
pumpAndSettle timed out
```

**Solución:** Usar `pump()` con duración específica en lugar de `pumpAndSettle()`:

```dart
// MAL - timeout con CircularProgressIndicator
await tester.tap(find.text('Comenzar'));
await tester.pumpAndSettle(); // TIMEOUT!

// BIEN - esperar tiempo específico
await tester.tap(find.text('Comenzar'));
await tester.pump(); // Procesar el tap
await tester.pump(const Duration(milliseconds: 50)); // Esperar async
```

### 2. Mock de Providers Asíncronos

**Problema:** Los providers que usan `SharedPreferences` o APIs asíncronas causan delays en tests.

**Solución:** Crear mocks que retornan inmediatamente:

```dart
/// Mock del OnboardingService que se completa inmediatamente
class MockOnboardingService extends OnboardingService {
  @override
  Future<void> completeOnboarding() async {
    // Se completa inmediatamente sin esperar SharedPreferences
    return;
  }
}

// En el test:
Widget createTestWidget() {
  return ProviderScope(
    overrides: [
      onboardingServiceProvider.overrideWithValue(MockOnboardingService()),
    ],
    child: MaterialApp(home: MyScreen()),
  );
}
```

### 3. SharedPreferences en Tests

**Setup requerido:**
```dart
setUp(() {
  SharedPreferences.setMockInitialValues({});
});
```

### 4. Tests de Formularios con Loading State

Cuando un formulario tiene botón con loading state:

```dart
// 1. El botón muestra loading mientras procesa
FilledButton(
  onPressed: _isLoading ? null : _save,
  child: _isLoading
      ? CircularProgressIndicator()
      : Text('Guardar'),
)

// 2. En el test, usar pump() después del tap
await tester.tap(find.text('Guardar'));
await tester.pump(); // Inicia el proceso
await tester.pump(const Duration(milliseconds: 100)); // Completa el Future
```

## Reglas de Testing

1. **NUNCA eliminar tests** que fallan sin investigar la causa raíz
2. **Usar mocks** para dependencias asíncronas
3. **Evitar pumpAndSettle()** cuando hay animaciones infinitas
4. **Documentar** cualquier uso de `pump()` con duración explicando por qué

## Métricas Objetivo

- Tests pasando: 100%
- Tests skipped: máximo 5%
- Cobertura: mínimo 80% en nuevos features

---

*Documento creado: 2026-01-09*
*Última actualización: 2026-01-09*
