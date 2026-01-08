# Guía de Configuración: Supabase + PowerSync

## Requisitos Previos

1. Cuenta en [Supabase](https://supabase.com)
2. Cuenta en [PowerSync](https://powersync.com)
3. Flutter SDK configurado

---

## Paso 1: Configurar Supabase

### 1.1 Crear Proyecto

1. Ir a [Supabase Dashboard](https://app.supabase.com)
2. Click en "New Project"
3. Configurar:
   - **Name**: `finanzas-familiares`
   - **Database Password**: (guardar en lugar seguro)
   - **Region**: Seleccionar el más cercano (ej: `South America (São Paulo)`)

### 1.2 Ejecutar Migraciones

En el SQL Editor de Supabase, ejecutar en orden:

```sql
-- 1. Primero: Schema inicial
-- Copiar contenido de: supabase/migrations/001_initial_schema.sql

-- 2. Después: Políticas RLS
-- Copiar contenido de: supabase/migrations/002_rls_policies.sql
```

### 1.3 Habilitar Autenticación

1. Ir a **Authentication** > **Providers**
2. Habilitar **Google** (opcional pero recomendado):
   - Obtener Client ID y Secret de Google Cloud Console
   - Configurar URLs de callback

### 1.4 Obtener Credenciales

Ir a **Settings** > **API** y copiar:
- **Project URL**: `https://xxxxx.supabase.co`
- **anon/public key**: `eyJhbGciOiJIUzI1NiIs...`

---

## Paso 2: Configurar PowerSync

### 2.1 Crear Instancia

1. Ir a [PowerSync Dashboard](https://powersync.com)
2. Crear nueva instancia
3. Conectar con Supabase:
   - **Connection Type**: Supabase
   - **Host**: (del Project URL de Supabase)
   - **Database**: `postgres`
   - **User**: `postgres`
   - **Password**: (la contraseña del proyecto)
   - **Port**: `5432`

### 2.2 Configurar Sync Rules

1. En PowerSync Dashboard, ir a **Sync Rules**
2. Pegar el contenido de: `supabase/powersync/sync_rules.yaml`
3. Click en **Deploy**

### 2.3 Obtener Credenciales PowerSync

- **PowerSync URL**: `https://xxxxx.powersync.journeyapps.com`

---

## Paso 3: Configurar la App Flutter

### 3.1 Crear archivo de configuración

Crear `lib/core/constants/supabase_config.dart`:

```dart
/// Configuración de Supabase y PowerSync
///
/// IMPORTANTE: En producción, usar variables de entorno
/// o flutter_dotenv para manejar estas credenciales
class SupabaseConfig {
  // Supabase
  static const String supabaseUrl = 'https://xxxxx.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIs...';

  // PowerSync
  static const String powerSyncUrl = 'https://xxxxx.powersync.journeyapps.com';
}
```

### 3.2 Alternativa segura con .env

1. Agregar `flutter_dotenv` al `pubspec.yaml`:
```yaml
dependencies:
  flutter_dotenv: ^5.1.0
```

2. Crear `.env` en la raíz del proyecto:
```env
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIs...
POWERSYNC_URL=https://xxxxx.powersync.journeyapps.com
```

3. Agregar `.env` a `.gitignore`

---

## Paso 4: Inicializar en la App

### 4.1 Provider de PowerSync

El archivo `lib/data/sync/powersync_connector.dart` ya está configurado.
Verificar que use las credenciales correctas.

### 4.2 Flujo de Autenticación

```
Usuario abre app
    ↓
¿Tiene sesión? ────No────→ Pantalla Login
    │                           ↓
   Sí                    Auth con Supabase
    │                           ↓
    ↓                    Obtener JWT token
PowerSync.connect()             ↓
    ↓              PowerSync.connect(token)
Sincronizar datos              ↓
    ↓              Sincronizar datos
App lista                       ↓
                           App lista
```

---

## Verificación

### Checklist de Configuración

- [ ] Proyecto Supabase creado
- [ ] Migraciones SQL ejecutadas (001, 002)
- [ ] RLS habilitado en todas las tablas
- [ ] PowerSync instancia creada
- [ ] PowerSync conectado a Supabase
- [ ] Sync rules desplegadas
- [ ] Credenciales configuradas en Flutter
- [ ] App compila sin errores

### Probar Sincronización

1. Iniciar sesión en la app
2. Crear una categoría o cuenta
3. Verificar en Supabase Dashboard que el registro aparece
4. Cerrar app y volver a abrir
5. Verificar que los datos persisten

---

## Troubleshooting

### Error: "Permission denied" en Supabase

- Verificar que RLS está habilitado
- Verificar que las políticas están creadas
- Verificar que el usuario está autenticado

### Error: "Sync failed" en PowerSync

- Verificar que las sync rules están desplegadas
- Verificar que las columnas coinciden entre SQL y sync_rules.yaml
- Revisar logs en PowerSync Dashboard

### Error: "Column not found"

Los schemas deben coincidir exactamente:
1. `supabase/migrations/001_initial_schema.sql`
2. `supabase/powersync/sync_rules.yaml`
3. `lib/data/sync/powersync_schema.dart`

---

## Arquitectura de Sincronización

```
┌─────────────────────────────────────────────────────────────┐
│                        FLUTTER APP                          │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────────┐ │
│  │   Riverpod  │───▶│    Drift    │───▶│   SQLite Local  │ │
│  │  Providers  │    │    DAOs     │    │    Database     │ │
│  └─────────────┘    └─────────────┘    └────────┬────────┘ │
│                                                  │          │
│                                        ┌─────────▼────────┐ │
│                                        │    PowerSync     │ │
│                                        │     Schema       │ │
│                                        └─────────┬────────┘ │
└──────────────────────────────────────────────────┼──────────┘
                                                   │
                                          Sync (Bidireccional)
                                                   │
┌──────────────────────────────────────────────────▼──────────┐
│                       POWERSYNC                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                   Sync Rules                         │   │
│  │    (user_data bucket - filtrado por user_id)        │   │
│  └──────────────────────────┬──────────────────────────┘   │
└─────────────────────────────┼───────────────────────────────┘
                              │
                     Replicación en tiempo real
                              │
┌─────────────────────────────▼───────────────────────────────┐
│                        SUPABASE                             │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────────┐ │
│  │    Auth     │    │  PostgreSQL │    │   Row Level     │ │
│  │  (JWT)      │    │   Database  │    │   Security      │ │
│  └─────────────┘    └─────────────┘    └─────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

## Notas de Seguridad

1. **Nunca** commitear credenciales al repositorio
2. Usar variables de entorno en producción
3. Las políticas RLS aseguran que cada usuario solo vea sus datos
4. El `user_id` se asigna automáticamente via trigger
5. PowerSync usa JWT de Supabase para autenticación
