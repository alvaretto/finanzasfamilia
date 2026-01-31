# Supabase Keep Alive - Prevención de Pausa por Inactividad

## Problema

Supabase **pausa automáticamente** los proyectos del plan gratuito (Free Tier) después de **7 días sin actividad**. Esto significa:

- La base de datos se detiene
- Las Edge Functions dejan de responder
- La app móvil pierde conectividad con el backend
- Se requiere restauración manual desde el dashboard

## Solución Implementada

### 1. Función RPC `ping()`

Se creó una función PostgreSQL simple que responde "pong":

```sql
-- Ubicación: Supabase > SQL Editor > Migrations
CREATE OR REPLACE FUNCTION public.ping()
RETURNS text
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT 'pong'::text;
$$;

GRANT EXECUTE ON FUNCTION public.ping() TO anon;
GRANT EXECUTE ON FUNCTION public.ping() TO authenticated;
```

### 2. GitHub Action Automatizado

Archivo: `.github/workflows/keep-supabase-alive.yml`

- **Frecuencia:** Cada 3 días (margen amplio vs. límite de 7 días)
- **Hora:** 00:00 UTC
- **Acción:** Llama a la función `ping()` vía REST API

## Configuración Requerida

### Paso 1: Obtener credenciales de Supabase

1. Ir a [Supabase Dashboard](https://supabase.com/dashboard)
2. Seleccionar proyecto `finanzas-familiares`
3. Ir a **Settings** > **API**
4. Copiar:
   - **Project URL:** `https://arawzleeiohoyhonisvo.supabase.co`
   - **anon public key:** (la clave que empieza con `eyJ...`)

### Paso 2: Configurar GitHub Secrets

1. Ir al repositorio en GitHub
2. **Settings** > **Secrets and variables** > **Actions**
3. Crear dos secrets:

| Secret Name | Valor |
|-------------|-------|
| `SUPABASE_URL` | `https://arawzleeiohoyhonisvo.supabase.co` |
| `SUPABASE_ANON_KEY` | `eyJ...` (tu anon key completa) |

### Paso 3: Verificar el workflow

1. Ir a **Actions** en el repositorio
2. Seleccionar "Keep Supabase Alive"
3. Click en **Run workflow** para probar manualmente

## Verificación

### Probar localmente con curl

```bash
curl -X POST "https://arawzleeiohoyhonisvo.supabase.co/rest/v1/rpc/ping" \
  -H "apikey: TU_ANON_KEY" \
  -H "Authorization: Bearer TU_ANON_KEY" \
  -H "Content-Type: application/json"
```

Respuesta esperada:
```
"pong"
```

### Ver logs del workflow

1. GitHub > Actions > Keep Supabase Alive
2. Click en la ejecución más reciente
3. Expandir "Ping Supabase Database"

## Restauración Manual (si el proyecto ya está pausado)

### Opción A: Dashboard de Supabase

1. Ir a [Supabase Dashboard](https://supabase.com/dashboard)
2. Seleccionar el proyecto pausado
3. Click en **Restore Project**
4. Esperar ~2 minutos

### Opción B: Supabase CLI / MCP

```bash
# Con Supabase CLI
supabase projects restore arawzleeiohoyhonisvo

# Con Claude Code (MCP Supabase)
# Ya configurado - solo pedir restauración
```

## Costos

- **GitHub Actions:** Gratuito (repositorios públicos) o ~0.008 USD/ejecución (privados)
- **Supabase:** Sin costo adicional (la función `ping()` es trivial)

## Alternativas Consideradas

| Alternativa | Por qué no se usó |
|-------------|-------------------|
| Cron externo (cron-job.org) | Dependencia de terceros |
| Upgrade a plan Pro | $25/mes innecesario para proyecto personal |
| Cloudflare Workers | Complejidad adicional |

## Troubleshooting

### Error: "Project is paused"

El proyecto se pausó antes de que el workflow pudiera ejecutarse. Solución:
1. Restaurar manualmente desde el dashboard
2. Verificar que los secrets estén configurados
3. Ejecutar el workflow manualmente para confirmar

### Error: "Invalid API key"

Los secrets no están configurados correctamente. Verificar:
1. Que `SUPABASE_ANON_KEY` sea la clave **anon** (no la service_role)
2. Que no haya espacios en blanco al inicio/final
3. Que la clave esté completa (empieza con `eyJ` y es muy larga)

### Error: "Function not found"

La función `ping()` no existe. Ejecutar la migración SQL desde el dashboard de Supabase.

---

**Fecha de implementación:** 2026-01-31
**Migración Supabase:** `create_ping_function`
**Workflow:** `.github/workflows/keep-supabase-alive.yml`
