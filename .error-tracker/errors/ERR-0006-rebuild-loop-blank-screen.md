# ERR-0006: Pantalla blanca/negra por rebuild loop en AddTransactionSheet

**Categoría**: flutter-rendering
**Severidad**: critical
**Estado**: solved
**Fecha**: 2026-01-07
**Versión detectada**: 1.9.11
**Versión corregida**: 1.9.12

## Descripción del Error

La aplicación se pone en blanco o negro (pantalla en blanco con ruido gráfico) durante interacciones en el formulario de transacciones (`AddTransactionSheet`). El emulador muestra errores de GPU:

```
ERROR | eglMakeCurrent failed
ERROR | 0x55effdc07bc0: Draw context is NULL
```

### Síntomas

- Pantalla se torna completamente blanca o negra
- Ocurre al abrir "Movimientos → Agregar Transacción"
- La app trata de bloquearse
- No hay crash de Flutter, solo fallo de rendering
- El emulador muestra errores consecutivos de contexto GPU nulo

## Causa Raíz

**Anti-patrón Flutter crítico**: Modificación directa de estado dentro del método `build()`.

### Código Problemático

```dart
// ❌ lib/features/transactions/presentation/widgets/add_transaction_sheet.dart:90-95
@override
Widget build(BuildContext context) {
  final accounts = ref.watch(activeAccountsProvider);

  // ❌ NUNCA modificar estado directamente en build()
  if (_selectedAccountId == null && accounts.isNotEmpty) {
    _selectedAccountId = DefaultAccountSelector.selectDefaultAccount(
      accounts: accounts,
      transactionType: _selectedType,
    );
  }

  return ...;
}
```

### ¿Por qué causa pantalla blanca?

1. `build()` se ejecuta y modifica `_selectedAccountId`
2. La modificación de estado puede causar que el widget se marque como "dirty"
3. Flutter programa otro rebuild
4. El nuevo `build()` vuelve a modificar el estado
5. **Loop infinito de rebuilds**
6. Sobrecarga del rendering pipeline
7. El contexto de dibujo de OpenGL/GPU falla (`eglMakeCurrent failed`)
8. Pantalla en blanco/negro

## Solución Implementada

### Cambio 1: Agregar flag de inicialización

```dart
// ✅ lib/features/transactions/presentation/widgets/add_transaction_sheet.dart:42
bool _hasInitializedDefaultAccount = false; // Flag para evitar múltiples selecciones
```

### Cambio 2: Usar PostFrameCallback

```dart
// ✅ lib/features/transactions/presentation/widgets/add_transaction_sheet.dart:90-103
@override
Widget build(BuildContext context) {
  final accounts = ref.watch(activeAccountsProvider);

  // ✅ FIX: Seleccionar cuenta predeterminada POST-frame (evita rebuild loop)
  if (!_hasInitializedDefaultAccount && _selectedAccountId == null && accounts.isNotEmpty) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _selectedAccountId == null) {
        setState(() {
          _selectedAccountId = DefaultAccountSelector.selectDefaultAccount(
            accounts: accounts,
            transactionType: _selectedType,
          );
          _hasInitializedDefaultAccount = true;
        });
      }
    });
  }

  return ...;
}
```

### ¿Por qué funciona?

1. `addPostFrameCallback()` programa la ejecución DESPUÉS del frame actual
2. No modifica estado durante `build()`
3. `setState()` se llama en el momento correcto (fuera de build)
4. El flag `_hasInitializedDefaultAccount` evita múltiples ejecuciones
5. Check de `mounted` previene setState después de dispose

## Archivos Modificados

```
lib/features/transactions/presentation/widgets/add_transaction_sheet.dart
├── +1 línea: _hasInitializedDefaultAccount flag (línea 42)
└── ~14 líneas: PostFrameCallback logic (líneas 90-103)
```

## Lecciones Aprendidas

### ❌ Anti-Patrones Flutter

1. **NUNCA modificar estado directamente en build()**
   ```dart
   // ❌ MAL
   Widget build(BuildContext context) {
     _someValue = calculateValue(); // ❌ Causa rebuild loop
     return ...;
   }
   ```

2. **NUNCA llamar setState() dentro de build()**
   ```dart
   // ❌ MAL
   Widget build(BuildContext context) {
     setState(() { ... }); // ❌ Assertion error
     return ...;
   }
   ```

### ✅ Buenas Prácticas

1. **Usar WidgetsBinding.instance.addPostFrameCallback()**
   ```dart
   // ✅ BIEN
   Widget build(BuildContext context) {
     WidgetsBinding.instance.addPostFrameCallback((_) {
       setState(() { ... }); // ✅ Fuera de build
     });
     return ...;
   }
   ```

2. **Inicializar estado en initState() o didChangeDependencies()**
   ```dart
   // ✅ BIEN
   @override
   void initState() {
     super.initState();
     _someValue = calculateInitialValue(); // ✅ Lugar correcto
   }
   ```

3. **Usar flags para evitar múltiples ejecuciones**
   ```dart
   // ✅ BIEN
   bool _hasInitialized = false;

   Widget build(BuildContext context) {
     if (!_hasInitialized) {
       WidgetsBinding.instance.addPostFrameCallback((_) {
         setState(() {
           _value = calculate();
           _hasInitialized = true; // ✅ Solo una vez
         });
       });
     }
     return ...;
   }
   ```

## Testing

### Test de Regresión

Creado en `test/regression/err_0006_rebuild_loop_test.dart`:

```dart
testWidgets('AddTransactionSheet no causa rebuild loop', (tester) async {
  int buildCount = 0;

  await tester.pumpWidget(
    ProviderScope(
      overrides: testProviderOverrides,
      child: MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            buildCount++;
            return AddTransactionSheet(initialType: TransactionType.expense);
          },
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();

  // Verificar que no hay rebuild loop (max 3-4 builds es normal)
  expect(buildCount, lessThan(10),
    reason: 'Rebuild loop detectado: $buildCount builds');
});
```

### Comando de Test

```bash
flutter test test/regression/err_0006_rebuild_loop_test.dart
```

## Prevención Futura

### Hook Pre-Commit

Agregado check en `.claude/hooks/pre-provider-edit.sh`:

```bash
# Detectar modificación de estado en build()
if grep -n "Widget build(" "$FILE" | grep -A 20 "_.*="; then
  echo "⚠️  Posible modificación de estado en build()"
  echo "   Verificar que no haya asignaciones directas a variables de estado"
fi
```

### Lint Rule (Opcional)

Considerar agregar custom lint:

```yaml
# analysis_options.yaml
custom_lint:
  rules:
    - avoid_state_modification_in_build
```

## Referencias

- [Flutter Best Practices - State Management](https://docs.flutter.dev/development/data-and-backend/state-mgmt/intro)
- [WidgetsBinding.addPostFrameCallback](https://api.flutter.dev/flutter/scheduler/SchedulerBinding/addPostFrameCallback.html)
- [Flutter Performance Best Practices](https://docs.flutter.dev/perf/best-practices)

## APK

- **v1.9.12**: `finanzas-familiares-v1.9.12-fix-rebuild-loop.apk` (70MB)
- **Fix verificado en**: Android Emulator Pixel 6 API 34

## Tags

`flutter` `rendering` `rebuild-loop` `state-management` `gpu-crash` `critical` `performance`
