---
description: Verifica la versión actual del APK y compara con la última conocida
---

# Check Version

Verificar versión actual del proyecto Finanzas Familiares AS.

## Pasos:

1. Leer versión de pubspec.yaml:
```bash
grep "^version:" pubspec.yaml
```

2. Mostrar historial de versiones recientes (si existe git):
```bash
git log --oneline -5 --all -- pubspec.yaml | head -5
```

3. Comparar con versión cacheada:
```bash
bash .claude/hooks/version-check.sh
```

## Output esperado:
- Versión actual: X.Y.Z+N
- Últimos cambios de versión
- Notificación si hubo cambio reciente
