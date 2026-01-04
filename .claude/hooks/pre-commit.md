# Hook: Pre Commit

## Trigger
Antes de ejecutar `git commit`

## Acciones

1. **Ejecutar quick tests**
   ```bash
   flutter test test/unit/ test/widget/ --concurrency=4
   ```

2. **Verificar formato**
   ```bash
   dart format --set-exit-if-changed lib/ test/
   ```

3. **Verificar analisis**
   ```bash
   flutter analyze --no-fatal-infos
   ```

## Bloquear Si

- Tests unitarios fallan
- Errores de formato
- Errores de analisis

## Bypass (usar con precaucion)

```bash
git commit --no-verify
```

## Mensaje de Commit

Sugerir formato:
```
<type>(<scope>): <description>

[body]

[footer]
```

Types: feat, fix, docs, style, refactor, test, chore
