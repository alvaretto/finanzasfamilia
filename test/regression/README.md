# Tests de Regresión

Tests generados automáticamente por el sistema de error-tracker para prevenir la reintroducción de bugs corregidos.

## Estructura

```
test/regression/
├── unit/              # Tests unitarios de regresión
│   └── {feature}/     # Agrupados por feature (accounts, transactions, etc.)
├── widget/            # Tests de widget de regresión
│   └── {feature}/
├── integration/       # Tests de integración de regresión
│   └── {feature}/
└── README.md          # Este archivo
```

## Generación de Tests

Los tests se generan automáticamente cuando se documenta un error:

```bash
# Generar test de regresión para un error
python .error-tracker/scripts/generate_test.py ERR-XXXX

# Especificar tipo de test
python .error-tracker/scripts/generate_test.py ERR-XXXX --type unit
python .error-tracker/scripts/generate_test.py ERR-XXXX --type widget
python .error-tracker/scripts/generate_test.py ERR-XXXX --type integration
```

## Nomenclatura

- Archivo: `err_xxxx_regression_test.dart`
- Grupo: `ERR-XXXX Regression`
- Test principal: `should not exhibit the original error behavior`

## Ejemplo de Test Generado

```dart
import 'package:flutter_test/flutter_test.dart';

/// Test de regresión para ERR-0001: RLS Recursion en family_members
/// 
/// Causa raíz: Policy referenciaba a sí misma
/// Archivo original: lib/features/accounts/providers/account_provider.dart
void main() {
  group('ERR-0001 Regression', () {
    test('should not exhibit the original error behavior', () {
      // Arrange
      // TODO: Preparar datos de prueba
      
      // Act
      // TODO: Ejecutar la acción que causaba el error
      
      // Assert
      // TODO: Verificar que el error no ocurre
    });
    
    test('should handle edge cases correctly', () {
      // Anti-patrones conocidos - NO hacer:
      // - Usar SECURITY DEFINER sin materializar vista
      // TODO: Agregar casos que verifiquen que no caemos en anti-patrones
    });
  });
}
```

## Ejecutar Tests de Regresión

```bash
# Todos los tests de regresión
flutter test test/regression/

# Solo unitarios
flutter test test/regression/unit/

# Solo de una feature
flutter test test/regression/unit/accounts/
```

## Workflow Completo

1. **Corregir error** en el código
2. **Documentar** con `add_error.py`
3. **Generar test** con `generate_test.py`
4. **Completar TODOs** en el test generado
5. **Ejecutar** para verificar
6. **Commit** junto con el fix

Ver [ERROR_TRACKER_GUIDE.md](../../docs/ERROR_TRACKER_GUIDE.md) para documentación completa.
