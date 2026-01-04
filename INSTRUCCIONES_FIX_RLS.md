# Instrucciones para Arreglar RLS Recursivo en family_members

## Problema
Las políticas RLS en la tabla `family_members` tienen **recursión infinita**, lo que está bloqueando toda la sincronización de datos desde la app Flutter a Supabase.

## Solución: Ejecutar Script SQL en Supabase

### Paso 1: Abrir el SQL Editor
1. Ve a: https://supabase.com/dashboard/project/gxezvqqbxgycmaqpgfpe/sql/new
2. Espera a que cargue completamente el editor SQL

### Paso 2: Copiar el Script
1. Abre el archivo `fix_rls_recursion.sql` en este mismo directorio
2. Copia TODO el contenido del archivo (Ctrl+A, Ctrl+C)

### Paso 3: Ejecutar en Supabase
1. Pega el script en el editor SQL de Supabase
2. Haz clic en el botón "Run" (Ejecutar) en la esquina inferior derecha
3. Espera a que se ejecute completamente

### Paso 4: Verificar que Funcionó
El script incluye una consulta de verificación al final que mostrará las nuevas políticas:
- "Users can view their own memberships"
- "Users can insert their own memberships"
- "Users can update their own memberships"
- "Users can delete their own memberships"

Deberías ver 4 políticas en total (en lugar de las 2 recursivas anteriores).

### Paso 5: Probar Sincronización
1. Vuelve a la app Flutter en el simulador
2. Ve a "Configuración" → "Importar Datos de Prueba"
3. Genera 200 transacciones nuevamente
4. Espera a que termine la generación
5. Verifica en Supabase que ahora sí aparecen los datos:
   - Tabla `accounts`: Debería tener 1 cuenta
   - Tabla `transactions`: Debería tener 200 transacciones

## ¿Qué Hace el Fix?

### Antes (Políticas Recursivas)
```sql
-- ❌ Esta política se consulta a sí misma → recursión infinita
"Family admins can manage members"
  WHERE family_id IN (
    SELECT family_id FROM family_members  -- Se consulta a sí misma!
    WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
  )
```

### Después (Políticas Simples)
```sql
-- ✅ Solo verifica el user_id directamente, sin subqueries recursivas
"Users can view their own memberships"
  USING (user_id = auth.uid())
```

## Notas Importantes
- Las nuevas políticas son más simples pero **seguras**
- Cada usuario solo puede ver/modificar sus propios registros
- La funcionalidad de "admin puede gestionar otros miembros" se puede implementar más adelante usando funciones `SECURITY DEFINER` si es necesario
- Por ahora, la prioridad es que la sincronización funcione correctamente

## Si Algo Sale Mal
Si después de ejecutar el script sigues teniendo problemas:
1. Verifica los logs de Postgres en Supabase
2. Asegúrate de que las 4 nuevas políticas se crearon correctamente
3. Verifica que las 2 políticas antiguas se eliminaron
