# Registro de Errores y Soluciones - Sesión 2026-01-09

## Resumen de la Sesión
Testing de la aplicación Finanzas Familiares AS en emulador Android (Pixel_6_API_34).

---

## Error 1: `ref.listen` fuera de `build()`

### Descripción
Al intentar hacer login con Google, la pantalla quedaba en blanco.

### Mensaje de Error
```
The following assertion was thrown during a scheduler callback:
ref.listen can only be used within the build method of a ConsumerWidget
'package:flutter_riverpod/src/consumer.dart':
Failed assertion: line 600 pos 7: 'debugDoingBuild'
```

### Archivo Afectado
`lib/presentation/screens/login_screen.dart:30`

### Causa Raíz
Se estaba llamando `ref.listen()` dentro de `initState()` usando `addPostFrameCallback`, lo cual no es permitido en Riverpod. `ref.listen` solo puede usarse dentro del método `build()`.

### Solución Fallida
N/A - Se identificó correctamente a la primera.

### Solución Definitiva
Mover `ref.listen()` al inicio del método `build()`:

**Antes (incorrecto):**
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.listen(authStateProvider, (previous, next) {
      if (next == AuthStatus.authenticated && mounted) {
        _navigateToHome();
      }
    });
  });
}
```

**Después (correcto):**
```dart
@override
Widget build(BuildContext context) {
  // Escuchar cambios de autenticación para navegación automática
  ref.listen(authStateProvider, (previous, next) {
    if (next == AuthStatus.authenticated && mounted) {
      _navigateToHome();
    }
  });

  // ... resto del build
}
```

### Estado
✅ **SOLUCIONADO**

---

## Error 2: Selector de Categorías Vacío

### Descripción
Al abrir el selector de categorías en el formulario de nueva transacción, aparecía solo el campo de búsqueda pero no se mostraban las categorías.

### Mensaje de Error
Sin error en consola - la lista simplemente estaba vacía.

### Archivos Afectados
- `lib/main.dart`
- `lib/application/providers/database_provider.dart`

### Causa Raíz
Desincronización de instancias de base de datos:

1. En `main.dart` se creaba una instancia `AppDatabase()` y se sembraban las categorías
2. Se hacía override de un provider interno `_databaseProvider`
3. Pero `appDatabaseProvider` (el que usan los DAOs) creaba su **propia instancia** de `AppDatabase()`
4. Resultado: las categorías estaban en una DB, pero los providers leían de otra DB vacía

### Solución Fallida
N/A - Se identificó correctamente el problema de las dos instancias.

### Solución Definitiva
Hacer override del provider correcto (`appDatabaseProvider`) en lugar del provider interno:

**Antes (incorrecto):**
```dart
// main.dart
final _databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('Debe ser overrideado');
});

runApp(
  ProviderScope(
    overrides: [
      _databaseProvider.overrideWithValue(db),  // Provider incorrecto
    ],
    child: const FinanzasFamiliaresApp(),
  ),
);
```

**Después (correcto):**
```dart
// main.dart
import 'application/providers/database_provider.dart';

runApp(
  ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),  // Provider correcto
    ],
    child: const FinanzasFamiliaresApp(),
  ),
);
```

También se simplificó `appDatabaseProvider`:
```dart
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  // Este provider debe ser overrideado desde main.dart
  return AppDatabase();  // Fallback
}
```

### Estado
✅ **SOLUCIONADO**

---

## Error 3: Dropdown de Cuentas Vacío

### Descripción
El dropdown "Cuenta" en el formulario de transacción no mostraba opciones.

### Mensaje de Error
Sin error - simplemente no había cuentas disponibles.

### Causa Raíz
No existía un seeder de cuentas. Solo se sembraban categorías, pero las cuentas (Nequi, Efectivo, Bancolombia, etc.) no se creaban automáticamente.

### Solución Definitiva
Crear seeder de cuentas basado en el diagrama `nuevo-mermaid2.md`:

1. **Crear archivo:** `lib/data/local/seeders/accounts_seeder.dart`
2. **Cuentas sembradas:**
   - Efectivo: Billetera Personal, Caja Menor Casa, Alcancía
   - Bancos: Davivienda, Bancolombia
   - Billeteras Digitales: DaviPlata, Nequi, DollarApp, PayPal
   - Inversiones: CDT/Fiducias, Propiedades (no incluidas en balance diario)

3. **Actualizar exports:** `lib/data/local/seeders/seeders.dart`
4. **Llamar desde main.dart:**
```dart
final accountsDao = AccountsDao(db);
await seedCategories(categoriesDao);
await seedAccounts(accountsDao, categoriesDao);
```

### Estado
✅ **SOLUCIONADO**

---

## Error 4: "Error al completar" en Onboarding

### Descripción
Al presionar "Comenzar" en la última página del onboarding, aparece el error "Error al completar. Intenta de nuevo."

### Mensaje de Error (con debug)
```
Bad state: Cannot use "ref" after the widget was disposed.
#0 ConsumerStatefulElement._assertNotDisposed
#3 _SplashScreenState._onOnboardingComplete (splash_screen.dart:85)
#5 _OnboardingScreenState._completeOnboarding (onboarding_screen.dart:103)
```

### Causa Raíz
El flujo de navegación tenía un bug de ciclo de vida de widgets:

1. `SplashScreen` navegaba a `OnboardingScreen` usando `pushReplacement`
2. Esto **reemplazaba** el SplashScreen en la pila de navegación, causando su dispose
3. Cuando OnboardingScreen terminaba, llamaba `widget.onComplete()` que era un callback del SplashScreen
4. El callback intentaba usar `ref.read(authStateProvider)` pero el SplashScreen ya estaba disposed
5. El error era capturado por el try-catch y mostraba el SnackBar

### Solución Definitiva
Mover la lógica de navegación post-onboarding al propio `OnboardingScreen` en lugar de depender de un callback del widget parent disposed.

**Archivos modificados:**

1. **`lib/presentation/screens/onboarding_screen.dart`:**
   - Agregados imports de `auth_provider.dart`, `login_screen.dart`, `main_shell.dart`
   - Método `_navigateBasedOnAuth()` ahora está en OnboardingScreen
   - `_completeOnboarding()` navega directamente después de guardar SharedPreferences

2. **`lib/presentation/screens/splash_screen.dart`:**
   - `_onOnboardingComplete()` ahora está vacío (solo comentario explicativo)
   - `_navigateBasedOnAuth()` tiene guard `if (!mounted) return`

3. **`test/presentation/screens/onboarding_screen_test.dart`:**
   - Actualizado para mockear `authStateProvider`
   - Tests cambiados para verificar loading indicator en lugar de callback

### Estado
✅ **SOLUCIONADO** - El onboarding ahora navega correctamente al LoginScreen

---

## Error 5: Google Sign-In no funciona

### Descripción
Al intentar "Continuar con Google", el navegador muestra "This site can't be reached" para la URL de Supabase Auth.

### Mensaje de Error
```
ERR_ADDRESS_UNREACHABLE
https://arawzleeiohoyhonisvo.supabase.co/auth/v1/authorize?...
```

### Causa Raíz
Múltiples posibles causas:
1. OAuth de Google no configurado en Supabase Dashboard
2. Redirect URL incorrecto en configuración de OAuth
3. Problema de conectividad del emulador

### Estado
⏳ **PENDIENTE** - No crítico para testing local. Se puede usar "Continuar sin cuenta" (modo offline).

---

## Error 6: Resumen Mensual muestra 0$ (RESUELTO)

### Descripción
El dashboard muestra "Mis Ahorros Netos: 436.000$" correctamente, pero el "Resumen de Enero 2026" muestra:
- Ingresos: 0$
- Gastos: 0$
- Balance: 0$
- "No hay gastos este mes"

### Causa Raíz Identificada
El problema **NO era un bug de código**, sino un problema de **datos de prueba**:
- Las transacciones creadas en sesiones anteriores tenían fechas fuera del mes actual
- O la base de datos estaba vacía después de reinstalar la app
- Los balances de cuentas se mostraban correctos porque se inicializaban con valores del seeder

### Debug Ejecutado
```
[DASHBOARD] Total transacciones en BD: 2
[DASHBOARD] ALL TX: expense | $14000.0 | date: 2026-01-09 15:59:30.000 | isUTC: false
[DASHBOARD] ALL TX: income | $450000.0 | date: 2026-01-09 15:59:30.000 | isUTC: false
[DASHBOARD] startOfMonth: 2026-01-01 00:00:00.000 | isUTC: false
[DASHBOARD] endOfMonth: 2026-01-31 23:59:59.000 | isUTC: false
[DASHBOARD] Transacciones en periodo: 2
```

### Verificación
- **Fechas consistentes**: Todas usan hora local (isUTC: false)
- **Filtro funciona**: `isBetweenValues()` de Drift opera correctamente
- **Dashboard correcto**: Ingresos 450.000$, Gastos 14.000$, Balance 436.000$

### Solución
No se requirió cambio de código. El sistema funciona correctamente cuando hay transacciones con fechas dentro del mes actual.

### Estado
✅ **SOLUCIONADO** - No era bug de código, era ausencia de datos de prueba válidos

---

## Comandos Útiles de la Sesión

```bash
# Listar emuladores
emulator -list-avds

# Abrir emulador
emulator -avd Pixel_6_API_34 &

# Ejecutar app
flutter run

# Hot restart (en consola de flutter run)
R

# Limpiar y reinstalar
flutter clean && flutter run

# Ver logs de Android
adb logcat -d | grep -i -E "(flutter|error|exception)" | tail -40
```

---

## Lecciones Aprendidas

1. **Riverpod:** `ref.listen()` SOLO dentro de `build()`, nunca en `initState()`
2. **Database Providers:** Asegurar que el override sea del provider que realmente usan los DAOs
3. **Seeders:** Crear seeders para todos los datos necesarios (categorías Y cuentas)
4. **Testing:** Siempre tener `flutter run` activo para ver errores en tiempo real

---

---

## Infraestructura de Testing Creada

### Patrol + Golden Tests + Self-Healing

Se implementó un framework completo de Visual Regression Testing con las siguientes capacidades:

#### Archivos Creados

| Archivo | Descripción |
|---------|-------------|
| `integration_test/patrol_test_config.dart` | Configuración base + SelfHealingFinders extension |
| `integration_test/app_test.dart` | Tests básicos de la aplicación |
| `integration_test/autonomous/screen_explorer.dart` | Explorador autónomo de pantallas |
| `integration_test/autonomous/exploration_test.dart` | Tests de exploración autónoma |
| `integration_test/golden/visual_regression_test.dart` | Golden Tests para regresión visual |
| `integration_test/patrol.yaml` | Configuración de Patrol |
| `scripts/run_patrol_tests.sh` | Script para ejecutar tests |

#### Self-Healing Tests
```dart
// Busca widget por múltiples estrategias, fallback automático
final finder = await $.findWithHealing(
  byText: 'Inicio',
  byKey: 'dashboard_key',
  byType: 'NavigationDestination',
);
```

#### Exploración Autónoma
```dart
final explorer = AutonomousExplorer($, config: ExplorerConfig(
  maxDepth: 3,
  screenshotOnEveryStep: true,
));
final report = await explorer.explore();
report.print();
```

#### Ejecución
```bash
# Tests básicos
./scripts/run_patrol_tests.sh app

# Exploración autónoma
./scripts/run_patrol_tests.sh explore

# Golden Tests
./scripts/run_patrol_tests.sh golden

# Todos los tests
./scripts/run_patrol_tests.sh all
```

---

**Última actualización:** 2026-01-09 05:30
