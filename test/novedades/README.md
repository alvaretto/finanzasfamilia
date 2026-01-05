# 🧪 Suite Completa de Tests - Finanzas Familiares AS

## 📋 Índice

1. [Visión General](#visión-general)
2. [Estructura de Tests](#estructura-de-tests)
3. [Tipos de Tests](#tipos-de-tests)
4. [Cómo Ejecutar](#cómo-ejecutar)
5. [Guía de Implementación](#guía-de-implementación)
6. [Mejores Prácticas](#mejores-prácticas)
7. [Cobertura de Tests](#cobertura-de-tests)

---

## 🎯 Visión General

Esta suite de tests está diseñada para verificar exhaustivamente las **dependencias e interacciones** entre todas las características del sistema de finanzas personales.

### Objetivos

✅ Verificar que los componentes interactúan correctamente  
✅ Detectar efectos en cascada no deseados  
✅ Validar transiciones de estado  
✅ Probar todas las combinaciones críticas  
✅ Simular escenarios de uso real  

### Estadísticas

- **Total de archivos de test:** 10+
- **Categorías de test:** 8
- **Casos de test estimados:** 200+
- **Cobertura objetivo:** 90%+

---

## 📁 Estructura de Tests

```
test/
├── helpers/
│   └── test_helpers.dart          # Utilidades comunes
├── fixtures/
│   └── test_fixtures.dart         # Datos de prueba predefinidos
├── mocks/
│   └── (generados por mockito)
├── integration/
│   └── core_integration_test.dart # Tests de integración básicos
├── cross_feature/
│   └── cross_feature_test.dart    # Tests de interdependencias
├── state_transition/
│   └── state_transition_test.dart # Tests de transiciones de estado
├── dependency/
│   └── dependency_test.dart       # Tests de dependencias
├── combinatorial/
│   └── combinatorial_test.dart    # Tests combinatorios
├── impact/
│   └── impact_analysis_test.dart  # Análisis de impacto
├── behavioral/
│   └── behavioral_test.dart       # Tests de comportamiento
├── e2e/
│   └── complete_month_scenario_test.dart # Escenario completo
└── README.md                      # Este archivo
```

---

## 🔬 Tipos de Tests

### 1. **Integration Tests** (`integration/`)

**Propósito:** Verificar que componentes principales interactúan correctamente.

**Cobertura:**
- ✅ Transacción → Cuenta
- ✅ Transacción → Presupuesto  
- ✅ Transacción → Meta
- ✅ Cuenta → Transacción → Reporte
- ✅ Flujos End-to-End básicos

**Ejemplo:**
```dart
test('Ingreso aumenta el saldo de la cuenta', () async {
  // Arrange: Crear cuenta
  final cuenta = await crearCuenta(saldo: 1000000);
  
  // Act: Registrar ingreso
  await registrarIngreso(cuenta.id, monto: 500000);
  
  // Assert: Saldo actualizado
  final actualizado = await obtenerCuenta(cuenta.id);
  expect(actualizado.saldo, 1500000);
});
```

### 2. **Cross-Feature Tests** (`cross_feature/`)

**Propósito:** Verificar interdependencias específicas entre features.

**Cobertura:**
- ✅ Cuenta × Transacción × Reporte
- ✅ Transacción × Presupuesto × Alerta
- ✅ Cuenta × Meta × Notificación
- ✅ Presupuesto × Categoría × Reporte
- ✅ Usuario × Configuración × Alertas

**Ejemplo:**
```dart
test('Gasto actualiza presupuesto y genera alerta', () async {
  // Arrange: Presupuesto cerca del límite
  final presupuesto = await crearPresupuesto(
    planeado: 500000,
    gastado: 450000, // 90%
  );
  
  // Act: Gasto que excede
  await registrarGasto(
    categoria: presupuesto.categoria,
    monto: 60000, // 102%
  );
  
  // Assert: Alerta generada
  final alertas = await obtenerAlertas();
  expect(alertas.first.tipo, 'presupuesto_excedido');
});
```

### 3. **State Transition Tests** (`state_transition/`)

**Propósito:** Validar transiciones de estado correctas.

**Cobertura:**
- ✅ Estados de Meta (nueva → en_progreso → completada)
- ✅ Estados de Presupuesto (normal → cerca_limite → excedido)
- ✅ Estados de Transacción (pendiente → procesada → completada)
- ✅ Estados de Cuenta (activa → inactiva → archivada)
- ✅ Estados de Alerta (nueva → leida → resuelta)

**Diagrama de Estados - Meta:**
```
   [nueva]
      ↓ (primer aporte)
[en_progreso]
      ↓ (aporte final)
 [completada]

Transiciones válidas:
- nueva → en_progreso ✅
- en_progreso → completada ✅
- en_progreso → pausada ✅
- pausada → en_progreso ✅
- completada → en_progreso ❌ (inválida)
```

### 4. **Dependency Tests** (`dependency/`)

**Propósito:** Verificar manejo correcto de dependencias.

**Cobertura:**
- ✅ Eliminar cuenta con transacciones → Error
- ✅ Eliminar categoría con presupuesto → Requiere confirmación
- ✅ Cambiar categoría → Actualiza transacciones y presupuestos
- ✅ Cascadas de eliminación

### 5. **Combinatorial Tests** (`combinatorial/`)

**Propósito:** Probar todas las combinaciones críticas.

**Cobertura:**
- ✅ Presupuesto × Alerta × Notificación (36 combinaciones)
- ✅ Tipo Transacción × Categoría × Cuenta
- ✅ Usuario × Configuración × Features
- ✅ Fechas × Recurrencia × Ejecución

**Matriz de Prueba:**
```
Estados Presupuesto: [normal, cerca_limite, excedido]
Config Alerta: [activa_80%, activa_90%, inactiva]
Config Notif: [push, email, ambos, ninguno]

Total combinaciones: 3 × 3 × 4 = 36 casos
```

### 6. **Impact Analysis Tests** (`impact/`)

**Propósito:** Analizar impacto de cambios.

**Cobertura:**
- ✅ Cambiar categoría de transacción
- ✅ Modificar presupuesto
- ✅ Eliminar cuenta
- ✅ Cambiar configuración de usuario

### 7. **Behavioral Tests** (`behavioral/`)

**Propósito:** Verificar comportamiento según configuración.

**Cobertura:**
- ✅ Sistema de alertas según configuración
- ✅ Notificaciones según preferencias
- ✅ Reportes según perfil de usuario

### 8. **End-to-End Tests** (`e2e/`)

**Propósito:** Simular uso real completo.

**Cobertura:**
- ✅ Mes completo de actividad de usuario
- ✅ Múltiples usuarios simultáneos
- ✅ Escenarios complejos realistas

---

## 🚀 Cómo Ejecutar

### Ejecutar todos los tests

```bash
flutter test
```

### Ejecutar categoría específica

```bash
# Integration tests
flutter test test/integration/

# Cross-feature tests
flutter test test/cross_feature/

# State transition tests
flutter test test/state_transition/

# E2E tests
flutter test test/e2e/
```

### Ejecutar archivo específico

```bash
flutter test test/e2e/complete_month_scenario_test.dart
```

### Con cobertura

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Modo verbose

```bash
flutter test --reporter=expanded
```

---

## 🛠️ Guía de Implementación

### Paso 1: Implementar Modelos y Servicios

Antes de activar los tests, implementa:

1. **Modelos de datos:**
   - `Usuario`
   - `Cuenta`
   - `Transaccion`
   - `Categoria`
   - `Presupuesto`
   - `Meta`

2. **Servicios:**
   - `TransaccionService`
   - `CuentaService`
   - `PresupuestoService`
   - `MetaService`
   - `ReporteService`
   - `NotificationService`

3. **Database:**
   - Implementar CRUD para cada entidad
   - Agregar soporte para transacciones
   - Implementar relaciones

### Paso 2: Descomentar y Adaptar Tests

Los tests actualmente tienen `TODO` y están deshabilitados con:

```dart
expect(true, true); // TODO
```

Para activarlos:

1. Reemplaza los `TODO` con implementación real
2. Importa tus servicios reales
3. Inicializa servicios en `setUp()`
4. Ejecuta y corrige errores

**Ejemplo de activación:**

```dart
// ANTES:
test('Ingreso aumenta el saldo', () async {
  // TODO: Implementar
  expect(true, true);
});

// DESPUÉS:
test('Ingreso aumenta el saldo', () async {
  final cuenta = await cuentaService.crear(
    Cuenta(nombre: 'Test', saldo: 1000000),
  );
  
  await transaccionService.registrar(
    Transaccion(
      tipo: TipoTransaccion.ingreso,
      cuentaId: cuenta.id,
      monto: 500000,
    ),
  );
  
  final actualizada = await cuentaService.obtener(cuenta.id);
  expect(actualizada.saldo, 1500000);
});
```

### Paso 3: Configurar Mocks

Si necesitas mocks para servicios externos:

```bash
# Instalar mockito
flutter pub add --dev mockito build_runner

# Generar mocks
flutter pub run build_runner build
```

Crear archivo de mocks:

```dart
// test/mocks/service_mocks.dart
import 'package:mockito/annotations.dart';

@GenerateMocks([
  TransaccionService,
  CuentaService,
  NotificationService,
])
void main() {}
```

### Paso 4: Verificar Cobertura

```bash
# Ejecutar con cobertura
flutter test --coverage

# Ver reporte
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

Objetivo: **90%+ de cobertura**

---

## ✅ Mejores Prácticas

### 1. **Nomenclatura Clara**

```dart
// ✅ BIEN
test('Gasto mayor al saldo lanza SaldoInsuficienteException', () {});

// ❌ MAL
test('test1', () {});
```

### 2. **Arrange-Act-Assert**

```dart
test('descripción', () async {
  // Arrange: Preparar datos
  final cuenta = await crearCuenta();
  
  // Act: Ejecutar acción
  await registrarGasto(cuenta.id, 100000);
  
  // Assert: Verificar resultado
  expect(cuenta.saldo, lessThan(saldoInicial));
});
```

### 3. **Un Assert por Concepto**

```dart
// ✅ BIEN
test('Transacción actualiza cuenta', () {
  expect(cuenta.saldo, nuevoSaldo);
});

test('Transacción actualiza presupuesto', () {
  expect(presupuesto.montoGastado, aumentado);
});

// ❌ MAL
test('Transacción actualiza todo', () {
  expect(cuenta.saldo, nuevoSaldo);
  expect(presupuesto.montoGastado, aumentado);
  expect(reporte.total, actualizado);
  // Muchos asserts dificultan identificar qué falló
});
```

### 4. **Limpiar Después de Cada Test**

```dart
tearDown(() async {
  await db.limpiar();
  await cacheService.limpiar();
});
```

### 5. **Usar Fixtures para Datos Comunes**

```dart
// En lugar de crear datos en cada test
final usuario = TestFixtures.usuarioBasico();
final cuentas = TestFixtures.cuentasBasicas();
```

### 6. **Tests Independientes**

Cada test debe poder ejecutarse solo, sin depender de otros.

```dart
// ❌ MAL: Depende de test anterior
var cuenta; // Variable global

test('crear cuenta', () {
  cuenta = await crearCuenta();
});

test('usar cuenta', () { // Falla si anterior falla
  await usarCuenta(cuenta);
});

// ✅ BIEN: Independiente
test('usar cuenta', () {
  final cuenta = await crearCuenta(); // Crea lo que necesita
  await usarCuenta(cuenta);
});
```

---

## 📊 Cobertura de Tests

### Objetivo por Módulo

| Módulo | Objetivo | Prioridad |
|--------|----------|-----------|
| Transacciones | 95% | 🔴 Alta |
| Cuentas | 95% | 🔴 Alta |
| Presupuestos | 90% | 🔴 Alta |
| Metas | 90% | 🟡 Media |
| Reportes | 85% | 🟡 Media |
| Notificaciones | 80% | 🟢 Baja |
| UI | 70% | 🟢 Baja |

### Checklist de Cobertura

- [ ] Todas las funciones públicas tienen test
- [ ] Todos los casos edge tienen test
- [ ] Todos los flujos críticos tienen E2E test
- [ ] Todas las interdependencias tienen cross-feature test
- [ ] Todas las transiciones de estado están cubiertas
- [ ] Todas las combinaciones críticas están probadas

---

## 🎯 Próximos Pasos

1. **Implementar modelos y servicios base**
2. **Activar integration tests básicos**
3. **Implementar cross-feature tests**
4. **Activar state transition tests**
5. **Completar E2E scenarios**
6. **Alcanzar 90% de cobertura**
7. **Integrar en CI/CD**

---

## 📚 Recursos Adicionales

- [Flutter Testing Guide](https://docs.flutter.dev/testing)
- [Mockito Documentation](https://pub.dev/packages/mockito)
- [Test-Driven Development](https://www.amazon.com/Test-Driven-Development-Kent-Beck/dp/0321146530)

---

## 🤝 Contribuir

Para agregar nuevos tests:

1. Identifica el tipo de test apropiado
2. Crea el archivo en la carpeta correspondiente
3. Sigue el patrón Arrange-Act-Assert
4. Usa fixtures cuando sea posible
5. Documenta casos especiales
6. Actualiza este README

---

**Última actualización:** 4 de enero de 2026  
**Versión:** 1.0  
**Mantenedor:** Equipo Finanzas Familiares AS
