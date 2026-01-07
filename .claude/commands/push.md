---
name: push
description: Commit detallado automático y push a rama principal
---

# Push - Commit Inteligente & Push

Comando automatizado que genera un commit detallado basado en los cambios y hace push a la rama principal.

## Ejecución

```bash
./smart_push.sh
```

O usando el comando slash:
```bash
/push
```

## Qué hace el script

1. **Verificar Estado de Git**:
   - Comprueba que estás en un repositorio git
   - Verifica la rama actual
   - Muestra archivos modificados y sin rastrear

2. **Análisis de Cambios**:
   - Detecta tipos de cambios (features, fixes, docs, tests)
   - Identifica archivos principales modificados
   - Cuenta líneas agregadas/eliminadas

3. **Generar Mensaje de Commit**:
   - Formato: `type(scope): descripción`
   - Incluye lista de archivos modificados
   - Estadísticas de cambios
   - Co-authored-by automático

4. **Mostrar Preview**:
   - Muestra el mensaje de commit generado
   - Lista los archivos que se commitearán
   - Pide confirmación antes de proceder

5. **Commit & Push**:
   - Stage de todos los cambios
   - Commit con mensaje generado
   - Push a la rama principal
   - Opción de force push si es necesario

## Detección Automática de Tipos

El script detecta automáticamente el tipo de commit:

| Tipo | Detecta | Ejemplo |
|------|---------|---------|
| `feat` | Nuevos archivos, nuevas features | Nuevos widgets, comandos |
| `fix` | Correcciones en archivos existentes | Bug fixes, ajustes |
| `docs` | Archivos .md, documentación | README, guides |
| `test` | Archivos en test/ | Tests unitarios, E2E |
| `refactor` | Cambios en estructura | Reorganización |
| `style` | Cambios de formato | Linting, formatting |
| `chore` | Cambios de configuración | pubspec, config |

## Opciones de Push

El script pregunta si quieres hacer:
- **Push normal**: `git push origin main`
- **Force push**: `git push --force origin main` ⚠️

### ⚠️ Advertencia sobre Force Push

**SOLO** usa force push si:
- ✅ Trabajas solo en el proyecto
- ✅ Necesitas sobrescribir historial remoto
- ✅ Estás seguro de que no perderás trabajo

**NUNCA** uses force push si:
- ❌ Otras personas están trabajando en el repo
- ❌ No estás seguro de lo que haces
- ❌ Hay trabajo sin respaldar

## Ejemplo de Mensaje Generado

```
feat(widgets): Implementar teclado numérico mejorado

## Archivos Modificados (5)
- lib/features/accounts/presentation/widgets/add_account_sheet.dart
- lib/features/transactions/presentation/widgets/add_transaction_sheet.dart
- lib/main.dart
- pubspec.yaml
- test/regression/widget/numeric_keyboard_test.dart

## Archivos Nuevos (2)
- .claude/skills/flutter-architecture/NUMERIC_KEYBOARD_PATTERN.md
- test/regression/widget/numeric_keyboard_test.dart

## Estadísticas
+245 -87 líneas modificadas

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

## Flujo Interactivo

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 SMART PUSH - Finanzas Familiares
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Estado del Repositorio
   Rama: main
   Archivos modificados: 10
   Archivos nuevos: 7

🔍 Analizando cambios...
   ✓ Detectado: feat (nuevos archivos + features)
   ✓ Scope: widgets
   ✓ Descripción: Implementar teclado numérico mejorado

📝 Mensaje de commit generado:

[Muestra el mensaje completo]

❓ ¿Commitear estos cambios? (s/n): s

✅ Cambios commiteados (commit: abc1234)

❓ ¿Hacer push a origin/main? (s/n): s
❓ ¿Push forzoso? ⚠️  (s/N): n

🚀 Pusheando a origin/main...
✅ Push completado exitosamente
```

## Configuración Personalizada

Puedes editar el script para personalizar:
- Tipos de commit preferidos
- Formato del mensaje
- Reglas de detección
- Branch destino (default: main)

## Comandos Útiles

```bash
# Ver el último commit
git log -1 --oneline

# Ver commits recientes
git log --oneline -5

# Deshacer último commit (mantiene cambios)
git reset --soft HEAD~1

# Ver diferencias antes de commit
git diff

# Ver estado detallado
git status
```

## Notas

- El script hace staging de **todos** los cambios (tracked y untracked)
- Genera mensajes siguiendo Conventional Commits
- Incluye estadísticas automáticas
- Pide confirmación antes de cada acción destructiva
- Force push requiere confirmación explícita
