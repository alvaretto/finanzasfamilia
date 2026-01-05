# /test-suite

Suite de tests optimizada con ejecución por categorías y reporte unificado.

## Propósito

Ejecutar tests de manera organizada y eficiente, mostrando progreso en tiempo real y estadísticas por categoría.

## Ejecución

```bash
#!/bin/bash
# Test Suite Optimizado - Finanzas Familiares AS

echo "=================================="
echo "🧪 TEST SUITE - FINANZAS FAMILIARES"
echo "=================================="
echo ""

TOTAL_START=$(date +%s)
PASSED=0
FAILED=0

# Función para ejecutar tests
run_category() {
  local name=$1
  local path=$2
  local emoji=$3

  echo "${emoji} ${name}..."
  START=$(date +%s)

  if flutter test ${path} --no-pub --reporter compact 2>&1 | tee /tmp/test_output.txt; then
    END=$(date +%s)
    ELAPSED=$((END - START))
    COUNT=$(grep -c "All tests passed" /tmp/test_output.txt || echo "?")
    echo "   ✅ Completado en ${ELAPSED}s"
    PASSED=$((PASSED + 1))
  else
    END=$(date +%s)
    ELAPSED=$((END - START))
    echo "   ❌ Falló en ${ELAPSED}s"
    FAILED=$((FAILED + 1))
  fi
  echo ""
}

# 1. Core Tests
run_category "Core (Unit)" "test/models/ test/services/ test/filters/ test/providers/" "🧪"

# 2. Widget Tests
run_category "Widgets" "test/widget/ test/router/ test/initialization/" "🎨"

# 3. Integration Tests
run_category "Integration" "test/integration/" "🔄"

# 4. E2E Tests
run_category "E2E" "test/e2e/" "🎯"

# 5. Interdependencias (NUEVO)
run_category "Interdependencias" "test/novedades/" "🔗"

# 6. AI Chat
run_category "AI Chat (Fina)" "test/ai_chat/" "🤖"

# 7. Security
run_category "Security" "test/security/ test/supabase/security_rls_test.dart" "🔒"

# 8. PWA
run_category "PWA/Offline" "test/pwa/" "🌐"

# 9. Platform
run_category "Platform (Android)" "test/android/" "📱"

# 10. Performance
run_category "Performance" "test/performance/" "⚡"

# 11. Supabase
run_category "Supabase" "test/supabase/auth_test.dart test/supabase/realtime_test.dart" "☁️"

# 12. Production
run_category "Production" "test/production/" "🚀"

TOTAL_END=$(date +%s)
TOTAL_ELAPSED=$((TOTAL_END - TOTAL_START))
TOTAL_CATEGORIES=$((PASSED + FAILED))

echo "=================================="
echo "📊 RESUMEN"
echo "=================================="
echo "✅ Categorías pasadas: ${PASSED}/${TOTAL_CATEGORIES}"
echo "❌ Categorías fallidas: ${FAILED}/${TOTAL_CATEGORIES}"
echo "⏱️  Tiempo total: ${TOTAL_ELAPSED}s (~$((TOTAL_ELAPSED / 60))min)"
echo ""

if [ $FAILED -eq 0 ]; then
  echo "🎉 ¡Todos los tests pasaron!"
  exit 0
else
  echo "⚠️  Algunos tests fallaron. Revisa los logs arriba."
  exit 1
fi
```

## Uso Rápido

```bash
# Ejecutar suite completa
chmod +x run_test_suite.sh
./run_test_suite.sh

# Con coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
xdg-open coverage/html/index.html
```

## Ventajas

- ✅ **Progreso en tiempo real** - Muestra qué categoría se está ejecutando
- ✅ **Tiempos individuales** - Tiempo por categoría
- ✅ **Resumen final** - Estadísticas consolidadas
- ✅ **Exit code** - 0 si pasa, 1 si falla
- ✅ **Organizado** - Ejecución por categorías lógicas

## Output Ejemplo

```
==================================
🧪 TEST SUITE - FINANZAS FAMILIARES
==================================

🧪 Core (Unit)...
   ✅ Completado en 12s

🎨 Widgets...
   ✅ Completado en 8s

🔄 Integration...
   ✅ Completado en 15s

...

==================================
📊 RESUMEN
==================================
✅ Categorías pasadas: 11/12
❌ Categorías fallidas: 1/12
⏱️  Tiempo total: 180s (~3min)

⚠️  Algunos tests fallaron. Revisa los logs arriba.
```

## Integración con CI/CD

```yaml
# .github/workflows/tests.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: chmod +x run_test_suite.sh
      - run: ./run_test_suite.sh
```

## Ver También

- `/test-all` - Ejecuta todos los tests de una vez
- `/test-category [cat]` - Ejecuta solo una categoría
- `/quick-test` - Tests rápidos (unit + widget)
