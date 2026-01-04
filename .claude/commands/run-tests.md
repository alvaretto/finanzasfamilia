---
name: run-tests
description: Ejecuta la suite completa de tests (300+)
---

# Run Tests

Ejecuta la suite completa de tests en orden:

1. **Tests Unitarios** (rapidos, logica pura):
```bash
flutter test test/unit/
```

2. **Tests de Widgets** (UI components):
```bash
flutter test test/widget/
```

3. **Tests de Integracion** (flujos completos):
```bash
flutter test test/integration/
```

4. **Tests AI Chat** (servicio Gemini, mensajes):
```bash
flutter test test/ai_chat/
```

5. **Tests de Seguridad** (validacion, RLS, API):
```bash
flutter test test/security/
```

6. **Tests de Performance** (tiempos, memoria):
```bash
flutter test test/performance/
```

7. **Tests PWA/Offline** (sync, cache):
```bash
flutter test test/pwa/
```

8. **Tests Android** (pantallas, orientacion):
```bash
flutter test test/android/
```

9. **Tests de Produccion** (edge cases, stress):
```bash
flutter test test/production/
```

## Resumen

Mostrar resumen con numero de tests pasados/fallidos por categoria.

| Categoria | Esperados |
|-----------|-----------|
| Unit | ~29 |
| Widget | ~28 |
| Integration | ~28 |
| AI Chat | ~41 |
| Security | ~20 |
| Performance | ~18 |
| PWA/Offline | ~17 |
| Android | ~12 |
| Production | ~40 |
| **Total** | **~300** |

Si hay fallos, analizar y reportar los errores encontrados.

**Nota**: Los tests E2E (`test/e2e/`) requieren Supabase inicializado y se ejecutan por separado.
