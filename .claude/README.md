# Directorio .claude

Configuración de Claude Code para el proyecto Finanzas Familiares AS.

## Estructura

```
.claude/
├── settings.json         # Configuración principal (versionada)
├── settings.local.json   # Configuración local (no versionada)
├── commands/             # Slash commands personalizados
│   ├── run.md           # /run - Ejecutar app en emulador
│   ├── setup.md         # /setup - Configurar entorno
│   └── error-tracker.md # /error-tracker - Documentar errores
├── docs/                 # Documentación técnica
│   ├── ai_architecture.md
│   ├── schema_plan.md
│   └── ui_ux_flow.md
└── references/           # Documentos de referencia
    ├── GUIA_MODO_PERSONAL_nuevo.md
    └── nuevo-mermaid2.md
```

## settings.json

El archivo `settings.json` debe usar el schema oficial de SchemaStore:

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json"
}
```

**Importante:** URLs alternativas como `https://raw.githubusercontent.com/...` no son válidas y causarán que Claude Code ignore el archivo completo.

## Comandos Disponibles

| Comando | Descripción |
|---------|-------------|
| `/run` | Ejecutar la app en el emulador Android |
| `/setup` | Configurar entorno de desarrollo |
| `/error-tracker` | Documentar y resolver errores |

## Notas

- `settings.local.json` no debe incluirse en el control de versiones
- Los cambios en `settings.json` requieren reiniciar Claude Code para aplicarse
