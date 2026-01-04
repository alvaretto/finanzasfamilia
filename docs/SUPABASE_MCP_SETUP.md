# Configuración MCP de Supabase (Permanente)

Este documento explica cómo se configuró el acceso permanente de Claude Code a Supabase para este proyecto.

## Estado Actual

✅ **MCP de Supabase configurado y funcionando**

Claude Code tiene acceso permanente a:
- Listar y gestionar proyectos
- Ejecutar queries SQL
- Ver logs de Postgres
- Gestionar migraciones
- Revisar tablas y datos

## Archivos de Configuración

### 1. `.vscode/mcp.json`

Define la configuración del servidor MCP de Supabase:

```json
{
  "mcpServers": {
    "supabase": {
      "command": "npx",
      "args": ["-y", "@supabase/mcp-server-supabase@latest"],
      "env": {
        "SUPABASE_ACCESS_TOKEN": "sbp_ea4b892af2f65e02de9637550e7463f9049369ab"
      }
    }
  }
}
```

**IMPORTANTE**: El token `sbp_*` es un **Personal Access Token** de Supabase, NO es la API key del proyecto.

### 2. `.claude/settings.local.json`

Define los permisos de herramientas MCP que Claude puede usar SIN solicitar aprobación del usuario:

```json
{
  "permissions": {
    "allow": [
      "mcp__supabase__search_docs",
      "mcp__supabase__list_organizations",
      "mcp__supabase__list_projects",
      "mcp__supabase__restore_project",
      "mcp__supabase__get_cost",
      "mcp__supabase__confirm_cost",
      "mcp__supabase__create_project",
      "mcp__supabase__get_project_url",
      "mcp__supabase__get_publishable_keys",
      "mcp__supabase__apply_migration",
      "mcp__supabase__list_tables",
      "mcp__supabase__list_migrations",
      "mcp__supabase__get_advisors",
      "mcp__supabase__get_project",
      "mcp__supabase__execute_sql",
      "mcp__supabase__get_logs"
    ]
  }
}
```

### 3. `.env`

Contiene las credenciales del proyecto Supabase (para la app Flutter):

```env
SUPABASE_URL=https://arawzleeiohoyhonisvo.supabase.co
SUPABASE_ANON_KEY=eyJhbGci...
GEMINI_API_KEY=AIzaSy...
```

**NOTA**: Este archivo NO es usado por Claude Code. Solo por la app Flutter.

## Proyectos Supabase Disponibles

Claude Code tiene acceso a 3 proyectos:

| Proyecto | Estado | Project ID | Region |
|----------|--------|------------|--------|
| **finanzas-familiares** | ACTIVE_HEALTHY | `arawzleeiohoyhonisvo` | us-east-1 |
| archivex | ACTIVE_HEALTHY | `satcazykhocpvpdzdcir` | us-west-2 |
| finanzas | INACTIVE | `wtaewwjqjorxthfsieez` | us-east-2 |

## Tablas del Proyecto `finanzas-familiares`

| Tabla | RLS | Filas | Descripción |
|-------|-----|-------|-------------|
| profiles | ✅ | 2 | Perfiles de usuario |
| categories | ✅ | 14 | Categorías del sistema |
| accounts | ✅ | 0 | Cuentas bancarias |
| transactions | ✅ | 0 | Transacciones |
| budgets | ✅ | 0 | Presupuestos |
| goals | ✅ | 0 | Metas de ahorro |
| families | ✅ | 0 | Grupos familiares |
| family_members | ✅ | 0 | Miembros de familias |
| recurring_transactions | ✅ | 0 | Transacciones recurrentes |

## Usuarios Registrados

1. **Alvaro Angel Molina** (alvaroangelm@gmail.com)
   - Último login: 2026-01-04 15:04
   - Currency: MXN

2. **Maria Conde** (condenada.marucha@gmail.com)
   - Último login: 2026-01-04 15:45
   - Currency: MXN

## Herramientas MCP Disponibles

Claude Code puede usar estas herramientas sin pedir permiso:

### Gestión de Proyectos
- `mcp__supabase__list_projects` - Listar proyectos
- `mcp__supabase__get_project` - Obtener detalles de un proyecto
- `mcp__supabase__create_project` - Crear nuevo proyecto
- `mcp__supabase__pause_project` - Pausar proyecto
- `mcp__supabase__restore_project` - Restaurar proyecto pausado

### Base de Datos
- `mcp__supabase__list_tables` - Listar tablas del schema público
- `mcp__supabase__execute_sql` - Ejecutar queries SQL
- `mcp__supabase__list_migrations` - Listar migraciones aplicadas
- `mcp__supabase__apply_migration` - Aplicar nueva migración (DDL)

### Monitoreo
- `mcp__supabase__get_logs` - Ver logs por servicio (api, postgres, auth, storage, etc.)
- `mcp__supabase__get_advisors` - Revisar avisos de seguridad y performance

### Configuración
- `mcp__supabase__get_project_url` - Obtener URL del proyecto
- `mcp__supabase__get_publishable_keys` - Obtener API keys públicas

### Documentación
- `mcp__supabase__search_docs` - Buscar en la documentación de Supabase

## Uso en Desarrollo

### Verificar Estado de Sync

```bash
# Desde Claude Code, ejecutar:
```

Claude puede ejecutar:
```sql
-- Ver transacciones en Supabase
SELECT COUNT(*) as total, user_id
FROM public.transactions
GROUP BY user_id;

-- Ver cuentas en Supabase
SELECT id, user_id, name, balance, currency
FROM public.accounts
ORDER BY created_at DESC;
```

### Verificar Logs de Postgres

Claude puede ejecutar:
```
mcp__supabase__get_logs(project_id: "arawzleeiohoyhonisvo", service: "postgres")
```

## Troubleshooting

### Problema: "No tengo acceso a Supabase"

**Solución**: Verificar que `.vscode/mcp.json` exista y tenga el token correcto.

### Problema: "Permission denied" al usar herramientas MCP

**Solución**: Agregar el permiso correspondiente en `.claude/settings.local.json`.

### Problema: "Invalid token"

**Solución**: Regenerar el Personal Access Token en Supabase Dashboard:
1. Ir a https://supabase.com/dashboard/account/tokens
2. Crear nuevo token
3. Actualizar `.vscode/mcp.json`

## Referencias

- [Supabase MCP Server](https://github.com/supabase/mcp-server-supabase)
- [Claude Code MCP Configuration](https://docs.anthropic.com/claude-code/mcp)
- [Supabase Dashboard](https://supabase.com/dashboard)

## Última Actualización

- **Fecha**: 2026-01-04
- **Verificado por**: Claude Opus 4.5
- **Estado**: ✅ Funcionando correctamente
