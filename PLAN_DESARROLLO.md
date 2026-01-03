# Plan de Desarrollo - Finanzas Familiares AS

## Vision General

Desarrollar una aplicacion de finanzas personales y familiares de nivel profesional con:
- Soporte multiplataforma (Android, Linux Desktop)
- Funcionamiento offline-first con sincronizacion inteligente
- Gestion familiar compartida con permisos granulares
- Analytics avanzados e insights financieros

---

## Fase 0: Fundamentos (Semana 1)

### Objetivos
- [ ] Configurar proyecto Flutter con estructura limpia
- [ ] Configurar Supabase (auth, database, RLS)
- [ ] Implementar base de datos local con Drift
- [ ] Setup de CI/CD basico

### Entregables
1. **Proyecto Flutter inicializado** con dependencias core
2. **Proyecto Supabase** con esquema inicial
3. **Esquema Drift** con tablas base
4. **GitHub Actions** para build automatico

### Dependencias Core
```yaml
dependencies:
  flutter:
    sdk: flutter
  # State Management
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1
  # Database
  drift: ^2.22.1
  drift_flutter: ^0.2.4
  sqlite3_flutter_libs: ^0.5.28
  # Backend
  supabase_flutter: ^2.8.3
  # Navigation
  go_router: ^14.6.2
  # Models
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0
  # Charts
  fl_chart: ^0.70.0
  # Utils
  intl: ^0.19.0
  uuid: ^4.5.1
  connectivity_plus: ^6.1.1
  flutter_secure_storage: ^9.2.2
  local_auth: ^2.3.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  build_runner: ^2.4.13
  riverpod_generator: ^2.6.3
  freezed: ^2.5.7
  json_serializable: ^6.8.0
  drift_dev: ^2.22.1
```

---

## Fase 1: Core MVP (Semanas 2-4)

### Modulo: Autenticacion
- [ ] Pantalla de login/registro
- [ ] Integracion Supabase Auth
- [ ] Persistencia de sesion local
- [ ] Autenticacion biometrica (opcional)

### Modulo: Cuentas
- [ ] CRUD de cuentas (banco, efectivo, tarjeta)
- [ ] Balance por cuenta
- [ ] Sincronizacion offline-first

### Modulo: Transacciones
- [ ] Registro de ingresos y gastos
- [ ] Categorias predefinidas + personalizadas
- [ ] Busqueda y filtros
- [ ] Transacciones recurrentes

### Modulo: Dashboard
- [ ] Resumen de balance total
- [ ] Grafico de gastos por categoria (pie chart)
- [ ] Flujo de efectivo mensual (bar chart)
- [ ] Ultimas transacciones

---

## Fase 2: Presupuestos y Metas (Semanas 5-6)

### Modulo: Presupuestos
- [ ] Crear presupuestos mensuales por categoria
- [ ] Seguimiento de progreso visual
- [ ] Alertas al 80% y 100% del limite
- [ ] Historial de cumplimiento

### Modulo: Metas de Ahorro
- [ ] Definir metas con monto objetivo
- [ ] Contribuciones manuales o automaticas
- [ ] Visualizacion de progreso
- [ ] Fecha estimada de logro

---

## Fase 3: Gestion Familiar (Semanas 7-8)

### Modulo: Familia
- [ ] Crear grupo familiar
- [ ] Invitar miembros por email/codigo
- [ ] Roles y permisos (admin, miembro, solo lectura)
- [ ] Cuentas compartidas vs individuales

### Modulo: Colaboracion
- [ ] Transacciones compartidas
- [ ] Presupuestos familiares
- [ ] Vista consolidada de finanzas
- [ ] Notificaciones de actividad

---

## Fase 4: Analytics Avanzados (Semanas 9-10)

### Modulo: Reportes
- [ ] Reporte mensual/anual
- [ ] Comparativa entre periodos
- [ ] Tendencias de gasto
- [ ] Exportar a PDF/CSV

### Modulo: Insights
- [ ] Deteccion de gastos inusuales
- [ ] Sugerencias de ahorro
- [ ] Prediccion de gastos futuros
- [ ] Analisis de habitos

---

## Fase 5: Polish y Lanzamiento (Semanas 11-12)

### Calidad
- [ ] Cobertura de tests > 80%
- [ ] Optimizacion de rendimiento
- [ ] Accesibilidad (a11y)
- [ ] Internacionalizacion (i18n) - ES, EN

### Lanzamiento
- [ ] Build firmado para Play Store
- [ ] Package para Linux (AppImage, Flatpak)
- [ ] Landing page
- [ ] Documentacion de usuario

---

## Arquitectura de Sincronizacion

```
┌─────────────────────────────────────────────────────────────┐
│                        FLUTTER APP                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    │
│  │   UI Layer  │───▶│  Providers  │───▶│ Repository  │    │
│  │  (Screens)  │    │ (Riverpod)  │    │  Pattern    │    │
│  └─────────────┘    └─────────────┘    └──────┬──────┘    │
│                                               │            │
│                          ┌────────────────────┼───────┐    │
│                          ▼                    ▼       │    │
│                   ┌─────────────┐      ┌─────────────┐│    │
│                   │ Local Data  │      │ Remote Data ││    │
│                   │   Source    │      │   Source    ││    │
│                   │  (Drift)    │      │ (Supabase)  ││    │
│                   └──────┬──────┘      └──────┬──────┘│    │
│                          │                    │       │    │
│                          ▼                    │       │    │
│                   ┌─────────────┐             │       │    │
│                   │   SQLite    │             │       │    │
│                   │  Database   │◀────────────┘       │    │
│                   └─────────────┘    Sync Service     │    │
│                                                       │    │
└───────────────────────────────────────────────────────┴────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                        SUPABASE                             │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │    Auth     │  │  Database   │  │  Realtime   │        │
│  │   Service   │  │ (PostgreSQL)│  │   (Sync)    │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
└─────────────────────────────────────────────────────────────┘
```

---

## Esquema de Base de Datos

### Supabase (PostgreSQL)

```sql
-- Usuarios (manejado por Supabase Auth)
-- profiles extiende auth.users

CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  display_name TEXT,
  avatar_url TEXT,
  currency TEXT DEFAULT 'MXN',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ
);

-- Familias
CREATE TABLE families (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  owner_id UUID REFERENCES profiles(id),
  invite_code TEXT UNIQUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Miembros de familia
CREATE TABLE family_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID REFERENCES families(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'member' CHECK (role IN ('owner', 'admin', 'member', 'viewer')),
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(family_id, user_id)
);

-- Cuentas financieras
CREATE TABLE accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id),
  family_id UUID REFERENCES families(id),
  name TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('cash', 'bank', 'credit_card', 'savings', 'investment')),
  currency TEXT DEFAULT 'MXN',
  initial_balance DECIMAL(15,2) DEFAULT 0,
  current_balance DECIMAL(15,2) DEFAULT 0,
  is_shared BOOLEAN DEFAULT FALSE,
  icon TEXT,
  color TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ
);

-- Categorias
CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id),
  family_id UUID REFERENCES families(id),
  name TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
  icon TEXT,
  color TEXT,
  parent_id UUID REFERENCES categories(id),
  is_system BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Transacciones
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id),
  account_id UUID REFERENCES accounts(id) ON DELETE CASCADE,
  category_id UUID REFERENCES categories(id),
  amount DECIMAL(15,2) NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('income', 'expense', 'transfer')),
  description TEXT,
  date DATE NOT NULL,
  notes TEXT,
  tags TEXT[],
  transfer_to_account_id UUID REFERENCES accounts(id),
  recurring_id UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ
);

-- Presupuestos
CREATE TABLE budgets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id),
  family_id UUID REFERENCES families(id),
  category_id UUID REFERENCES categories(id),
  amount DECIMAL(15,2) NOT NULL,
  period TEXT DEFAULT 'monthly' CHECK (period IN ('weekly', 'monthly', 'yearly')),
  start_date DATE NOT NULL,
  end_date DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Metas de ahorro
CREATE TABLE goals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id),
  family_id UUID REFERENCES families(id),
  name TEXT NOT NULL,
  target_amount DECIMAL(15,2) NOT NULL,
  current_amount DECIMAL(15,2) DEFAULT 0,
  target_date DATE,
  icon TEXT,
  color TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

-- Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE families ENABLE ROW LEVEL SECURITY;
ALTER TABLE family_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE goals ENABLE ROW LEVEL SECURITY;
```

---

## Checklist Pre-Lanzamiento

### Seguridad
- [ ] Encriptacion de BD local habilitada
- [ ] RLS configurado en todas las tablas
- [ ] Tokens JWT con expiracion corta
- [ ] Datos sensibles en secure storage
- [ ] FLAG_SECURE en pantallas financieras

### Rendimiento
- [ ] Lazy loading de listas largas
- [ ] Caching de imagenes
- [ ] Queries optimizados con indices
- [ ] Build release con tree shaking

### UX
- [ ] Onboarding para nuevos usuarios
- [ ] Empty states informativos
- [ ] Loading states consistentes
- [ ] Error handling amigable
- [ ] Haptic feedback en acciones

### Legal
- [ ] Politica de privacidad
- [ ] Terminos de servicio
- [ ] Aviso sobre almacenamiento de datos
