-- =============================================================================
-- FINANZAS FAMILIARES - Schema Inicial para Supabase
-- Migración: 001_initial_schema.sql
-- Descripción: Crea las tablas principales para sincronización con PowerSync
-- =============================================================================

-- Habilitar extensión UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- TABLA: categories
-- Categorías jerárquicas para clasificación contable
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.categories (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL CHECK (length(name) >= 1 AND length(name) <= 100),
    icon TEXT CHECK (icon IS NULL OR length(icon) <= 10),
    type TEXT NOT NULL CHECK (type IN ('asset', 'liability', 'income', 'expense')),
    parent_id TEXT REFERENCES public.categories(id) ON DELETE SET NULL,
    level INTEGER NOT NULL DEFAULT 0,
    sort_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    is_system BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Campo para PowerSync
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Índices para categories
CREATE INDEX IF NOT EXISTS idx_categories_type ON public.categories(type);
CREATE INDEX IF NOT EXISTS idx_categories_parent_id ON public.categories(parent_id);
CREATE INDEX IF NOT EXISTS idx_categories_user_id ON public.categories(user_id);
CREATE INDEX IF NOT EXISTS idx_categories_is_active ON public.categories(is_active);

-- =============================================================================
-- TABLA: accounts
-- Cuentas/billeteras del usuario
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.accounts (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL CHECK (length(name) >= 1 AND length(name) <= 100),
    icon TEXT CHECK (icon IS NULL OR length(icon) <= 10),
    category_id TEXT NOT NULL REFERENCES public.categories(id) ON DELETE RESTRICT,
    balance DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    currency TEXT NOT NULL DEFAULT 'COP',
    color TEXT CHECK (color IS NULL OR length(color) <= 7),
    description TEXT,
    include_in_total BOOLEAN NOT NULL DEFAULT true,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Campo para PowerSync
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Índices para accounts
CREATE INDEX IF NOT EXISTS idx_accounts_category_id ON public.accounts(category_id);
CREATE INDEX IF NOT EXISTS idx_accounts_user_id ON public.accounts(user_id);
CREATE INDEX IF NOT EXISTS idx_accounts_is_active ON public.accounts(is_active);

-- =============================================================================
-- TABLA: places
-- Lugares donde se realizan transacciones
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.places (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL CHECK (length(name) >= 1 AND length(name) <= 100),
    icon TEXT CHECK (icon IS NULL OR length(icon) <= 10),
    address TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    is_favorite BOOLEAN NOT NULL DEFAULT false,
    visit_count INTEGER NOT NULL DEFAULT 0,
    last_visited_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Campo para PowerSync
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Índices para places
CREATE INDEX IF NOT EXISTS idx_places_user_id ON public.places(user_id);
CREATE INDEX IF NOT EXISTS idx_places_is_favorite ON public.places(is_favorite);

-- =============================================================================
-- TABLA: payment_methods
-- Métodos de pago
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.payment_methods (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL CHECK (length(name) >= 1 AND length(name) <= 100),
    icon TEXT CHECK (icon IS NULL OR length(icon) <= 10),
    type TEXT NOT NULL CHECK (type IN ('cash', 'debit', 'credit', 'transfer', 'digital_wallet', 'other')),
    account_id TEXT REFERENCES public.accounts(id) ON DELETE SET NULL,
    is_default BOOLEAN NOT NULL DEFAULT false,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Campo para PowerSync
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Índices para payment_methods
CREATE INDEX IF NOT EXISTS idx_payment_methods_user_id ON public.payment_methods(user_id);
CREATE INDEX IF NOT EXISTS idx_payment_methods_account_id ON public.payment_methods(account_id);

-- =============================================================================
-- TABLA: measurement_units
-- Unidades de medida para detalles de transacciones
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.measurement_units (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL CHECK (length(name) >= 1 AND length(name) <= 50),
    abbreviation TEXT NOT NULL CHECK (length(abbreviation) >= 1 AND length(abbreviation) <= 10),
    type TEXT NOT NULL CHECK (type IN ('weight', 'volume', 'length', 'unit', 'other')),
    conversion_factor DOUBLE PRECISION NOT NULL DEFAULT 1.0,
    base_unit_id TEXT REFERENCES public.measurement_units(id) ON DELETE SET NULL,
    is_system BOOLEAN NOT NULL DEFAULT false,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Campo para PowerSync
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Índices para measurement_units
CREATE INDEX IF NOT EXISTS idx_measurement_units_user_id ON public.measurement_units(user_id);
CREATE INDEX IF NOT EXISTS idx_measurement_units_type ON public.measurement_units(type);

-- =============================================================================
-- TABLA: transactions
-- Transacciones financieras (header)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.transactions (
    id TEXT PRIMARY KEY,
    type TEXT NOT NULL CHECK (type IN ('income', 'expense', 'transfer')),
    amount DOUBLE PRECISION NOT NULL,
    description TEXT,
    from_account_id TEXT REFERENCES public.accounts(id) ON DELETE SET NULL,
    to_account_id TEXT REFERENCES public.accounts(id) ON DELETE SET NULL,
    category_id TEXT NOT NULL REFERENCES public.categories(id) ON DELETE RESTRICT,
    place_id TEXT REFERENCES public.places(id) ON DELETE SET NULL,
    transaction_date TIMESTAMP WITH TIME ZONE NOT NULL,
    is_confirmed BOOLEAN NOT NULL DEFAULT true,
    has_details BOOLEAN NOT NULL DEFAULT false,
    item_count INTEGER NOT NULL DEFAULT 1,
    sync_status TEXT NOT NULL DEFAULT 'pending' CHECK (sync_status IN ('pending', 'synced', 'error')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Campo para PowerSync
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Índices para transactions
CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON public.transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_category_id ON public.transactions(category_id);
CREATE INDEX IF NOT EXISTS idx_transactions_transaction_date ON public.transactions(transaction_date);
CREATE INDEX IF NOT EXISTS idx_transactions_type ON public.transactions(type);
CREATE INDEX IF NOT EXISTS idx_transactions_from_account_id ON public.transactions(from_account_id);
CREATE INDEX IF NOT EXISTS idx_transactions_to_account_id ON public.transactions(to_account_id);

-- =============================================================================
-- TABLA: transaction_details
-- Detalles de transacciones (Shopping Cart / líneas)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.transaction_details (
    id TEXT PRIMARY KEY,
    transaction_id TEXT NOT NULL REFERENCES public.transactions(id) ON DELETE CASCADE,
    category_id TEXT NOT NULL REFERENCES public.categories(id) ON DELETE RESTRICT,
    description TEXT,
    quantity DOUBLE PRECISION NOT NULL DEFAULT 1.0,
    unit_id TEXT REFERENCES public.measurement_units(id) ON DELETE SET NULL,
    unit_price DOUBLE PRECISION NOT NULL,
    total_price DOUBLE PRECISION NOT NULL,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Campo para PowerSync
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Índices para transaction_details
CREATE INDEX IF NOT EXISTS idx_transaction_details_transaction_id ON public.transaction_details(transaction_id);
CREATE INDEX IF NOT EXISTS idx_transaction_details_category_id ON public.transaction_details(category_id);
CREATE INDEX IF NOT EXISTS idx_transaction_details_user_id ON public.transaction_details(user_id);

-- =============================================================================
-- TABLA: budgets
-- Presupuestos mensuales por categoría
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.budgets (
    id TEXT PRIMARY KEY,
    category_id TEXT NOT NULL REFERENCES public.categories(id) ON DELETE CASCADE,
    amount DOUBLE PRECISION NOT NULL,
    month INTEGER NOT NULL CHECK (month >= 1 AND month <= 12),
    year INTEGER NOT NULL CHECK (year >= 2020 AND year <= 2100),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Campo para PowerSync
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,

    -- Restricción única por categoría/mes/año/usuario
    UNIQUE (category_id, month, year, user_id)
);

-- Índices para budgets
CREATE INDEX IF NOT EXISTS idx_budgets_user_id ON public.budgets(user_id);
CREATE INDEX IF NOT EXISTS idx_budgets_category_id ON public.budgets(category_id);
CREATE INDEX IF NOT EXISTS idx_budgets_month_year ON public.budgets(month, year);

-- =============================================================================
-- TABLA: journal_entries
-- Asientos contables (Partida Doble)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.journal_entries (
    id TEXT PRIMARY KEY,
    transaction_id TEXT NOT NULL REFERENCES public.transactions(id) ON DELETE CASCADE,
    account_id TEXT NOT NULL REFERENCES public.accounts(id) ON DELETE RESTRICT,
    entry_type TEXT NOT NULL CHECK (entry_type IN ('debit', 'credit')),
    amount DOUBLE PRECISION NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Campo para PowerSync
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Índices para journal_entries
CREATE INDEX IF NOT EXISTS idx_journal_entries_transaction_id ON public.journal_entries(transaction_id);
CREATE INDEX IF NOT EXISTS idx_journal_entries_account_id ON public.journal_entries(account_id);
CREATE INDEX IF NOT EXISTS idx_journal_entries_user_id ON public.journal_entries(user_id);

-- =============================================================================
-- FUNCIONES AUXILIARES
-- =============================================================================

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Aplicar trigger a todas las tablas
DO $$
DECLARE
    t TEXT;
BEGIN
    FOR t IN
        SELECT table_name
        FROM information_schema.columns
        WHERE column_name = 'updated_at'
        AND table_schema = 'public'
    LOOP
        EXECUTE format('
            DROP TRIGGER IF EXISTS update_%I_updated_at ON public.%I;
            CREATE TRIGGER update_%I_updated_at
            BEFORE UPDATE ON public.%I
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
        ', t, t, t, t);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- COMENTARIOS DE DOCUMENTACIÓN
-- =============================================================================
COMMENT ON TABLE public.categories IS 'Categorías jerárquicas para clasificación contable (Activos, Pasivos, Ingresos, Gastos)';
COMMENT ON TABLE public.accounts IS 'Cuentas y billeteras del usuario (Nequi, DaviPlata, Efectivo, etc.)';
COMMENT ON TABLE public.transactions IS 'Transacciones financieras (ingresos, gastos, transferencias)';
COMMENT ON TABLE public.transaction_details IS 'Detalles de transacciones tipo carrito de compras';
COMMENT ON TABLE public.budgets IS 'Presupuestos mensuales por categoría para el semáforo';
COMMENT ON TABLE public.journal_entries IS 'Asientos contables de partida doble';
COMMENT ON TABLE public.places IS 'Lugares donde se realizan las transacciones';
COMMENT ON TABLE public.payment_methods IS 'Métodos de pago disponibles';
COMMENT ON TABLE public.measurement_units IS 'Unidades de medida para cantidades';
