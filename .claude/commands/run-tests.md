---
name: run-tests
description: Ejecuta todos los tests del proyecto
---

# Run Tests

Ejecuta la suite completa de tests:

1. Tests unitarios:
```bash
flutter test test/unit/
```

2. Tests de widgets:
```bash
flutter test test/widget/
```

3. Tests de integracion:
```bash
flutter test test/integration/
```

4. Tests de produccion (agresivos):
```bash
flutter test test/production/
```

5. Mostrar resumen con numero de tests pasados/fallidos por categoria.

Si hay fallos, analizar y reportar los errores encontrados.
