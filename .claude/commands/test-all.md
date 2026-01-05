# /test-all

Ejecuta la suite completa de tests (500+) con reporte detallado por categoría.

## Proceso

1. **Pre-check**: Verificar que no hay errores de compilación
2. **Core Tests**: Modelos, servicios, filtros, providers (~80 tests)
3. **Widget Tests**: Componentes UI (~30 tests)
4. **Integration Tests**: Flujos de integración (~40 tests)
5. **E2E Tests**: End-to-end completos (~80 tests)
6. **Interdependencias**: Core, cross-feature, state, combinatorial, month (~210 tests)
7. **AI Chat Tests**: Fina con Gemini 2.0 (~80 tests)
8. **Security Tests**: API + RLS (~40 tests)
9. **PWA/Offline Tests**: Offline-first (~50 tests)
10. **Platform Tests**: Android compatibility (~30 tests)
11. **Performance Tests**: App + Chat (~30 tests)
12. **Supabase Tests**: Auth + Realtime (~40 tests)
13. **Production Tests**: Tests agresivos (~40 tests)

## Comandos

```bash
# 1. Verificar compilación
flutter analyze

# 2. Ejecutar todos los tests con reporte expandido
flutter test --reporter expanded

# 3. Con coverage
flutter test --coverage

# 4. Ver reporte HTML
genhtml coverage/lcov.info -o coverage/html
xdg-open coverage/html/index.html  # Linux
```

## Ejecución por Categoría

```bash
# Core (Unit)
echo "🧪 Core Tests..." && flutter test test/models/ test/services/ test/filters/ test/providers/

# Widgets
echo "🎨 Widget Tests..." && flutter test test/widget/ test/router/ test/initialization/

# Integration + E2E
echo "🔄 Integration + E2E..." && flutter test test/integration/ test/e2e/

# Interdependencias (NUEVO)
echo "🔗 Interdependencias..." && flutter test test/novedades/

# AI Chat
echo "🤖 AI Chat..." && flutter test test/ai_chat/

# Security
echo "🔒 Security..." && flutter test test/security/ test/supabase/security_rls_test.dart

# PWA
echo "🌐 PWA..." && flutter test test/pwa/

# Platform
echo "📱 Platform..." && flutter test test/android/

# Performance
echo "⚡ Performance..." && flutter test test/performance/

# Supabase
echo "☁️ Supabase..." && flutter test test/supabase/

# Production
echo "🚀 Production..." && flutter test test/production/
```

## Output Esperado

- Total tests ejecutados: **500+**
- Tests activos: **300+** (pasando)
- Tests pendientes: **210+** (test/novedades con TODOs)
- Tiempo de ejecución: ~3-5 minutos
- Coverage: > 60%

## Criterios de Éxito

- ✅ 0 tests fallidos en core/widget/integration
- ✅ < 5% tests fallidos en E2E (pueden fallar por timing)
- ✅ Tests de test/novedades/ muestran TODOs (pendientes de activación)
- ✅ Coverage > 60%
- ✅ Fina (AI Chat) funciona con Gemini 2.0 Flash
