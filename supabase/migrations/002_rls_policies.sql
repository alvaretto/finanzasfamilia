-- =============================================================================
-- FINANZAS FAMILIARES - Row Level Security Policies
-- Migración: 002_rls_policies.sql
-- Descripción: Configura RLS para que cada usuario solo vea sus datos
-- =============================================================================

-- Habilitar RLS en todas las tablas
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transaction_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.journal_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.places ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.measurement_units ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- POLÍTICAS PARA categories
-- =============================================================================
DROP POLICY IF EXISTS "Users can view own categories" ON public.categories;
CREATE POLICY "Users can view own categories"
    ON public.categories FOR SELECT
    USING (
        user_id = auth.uid()
        OR is_system = true  -- Categorías del sistema visibles para todos
    );

DROP POLICY IF EXISTS "Users can insert own categories" ON public.categories;
CREATE POLICY "Users can insert own categories"
    ON public.categories FOR INSERT
    WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can update own categories" ON public.categories;
CREATE POLICY "Users can update own categories"
    ON public.categories FOR UPDATE
    USING (user_id = auth.uid() AND is_system = false)
    WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can delete own categories" ON public.categories;
CREATE POLICY "Users can delete own categories"
    ON public.categories FOR DELETE
    USING (user_id = auth.uid() AND is_system = false);

-- =============================================================================
-- POLÍTICAS PARA accounts
-- =============================================================================
DROP POLICY IF EXISTS "Users can view own accounts" ON public.accounts;
CREATE POLICY "Users can view own accounts"
    ON public.accounts FOR SELECT
    USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can insert own accounts" ON public.accounts;
CREATE POLICY "Users can insert own accounts"
    ON public.accounts FOR INSERT
    WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can update own accounts" ON public.accounts;
CREATE POLICY "Users can update own accounts"
    ON public.accounts FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can delete own accounts" ON public.accounts;
CREATE POLICY "Users can delete own accounts"
    ON public.accounts FOR DELETE
    USING (user_id = auth.uid());

-- =============================================================================
-- POLÍTICAS PARA transactions
-- =============================================================================
DROP POLICY IF EXISTS "Users can view own transactions" ON public.transactions;
CREATE POLICY "Users can view own transactions"
    ON public.transactions FOR SELECT
    USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can insert own transactions" ON public.transactions;
CREATE POLICY "Users can insert own transactions"
    ON public.transactions FOR INSERT
    WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can update own transactions" ON public.transactions;
CREATE POLICY "Users can update own transactions"
    ON public.transactions FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can delete own transactions" ON public.transactions;
CREATE POLICY "Users can delete own transactions"
    ON public.transactions FOR DELETE
    USING (user_id = auth.uid());

-- =============================================================================
-- POLÍTICAS PARA transaction_details
-- =============================================================================
DROP POLICY IF EXISTS "Users can view own transaction_details" ON public.transaction_details;
CREATE POLICY "Users can view own transaction_details"
    ON public.transaction_details FOR SELECT
    USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can insert own transaction_details" ON public.transaction_details;
CREATE POLICY "Users can insert own transaction_details"
    ON public.transaction_details FOR INSERT
    WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can update own transaction_details" ON public.transaction_details;
CREATE POLICY "Users can update own transaction_details"
    ON public.transaction_details FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can delete own transaction_details" ON public.transaction_details;
CREATE POLICY "Users can delete own transaction_details"
    ON public.transaction_details FOR DELETE
    USING (user_id = auth.uid());

-- =============================================================================
-- POLÍTICAS PARA budgets
-- =============================================================================
DROP POLICY IF EXISTS "Users can view own budgets" ON public.budgets;
CREATE POLICY "Users can view own budgets"
    ON public.budgets FOR SELECT
    USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can insert own budgets" ON public.budgets;
CREATE POLICY "Users can insert own budgets"
    ON public.budgets FOR INSERT
    WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can update own budgets" ON public.budgets;
CREATE POLICY "Users can update own budgets"
    ON public.budgets FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can delete own budgets" ON public.budgets;
CREATE POLICY "Users can delete own budgets"
    ON public.budgets FOR DELETE
    USING (user_id = auth.uid());

-- =============================================================================
-- POLÍTICAS PARA journal_entries
-- =============================================================================
DROP POLICY IF EXISTS "Users can view own journal_entries" ON public.journal_entries;
CREATE POLICY "Users can view own journal_entries"
    ON public.journal_entries FOR SELECT
    USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can insert own journal_entries" ON public.journal_entries;
CREATE POLICY "Users can insert own journal_entries"
    ON public.journal_entries FOR INSERT
    WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can update own journal_entries" ON public.journal_entries;
CREATE POLICY "Users can update own journal_entries"
    ON public.journal_entries FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can delete own journal_entries" ON public.journal_entries;
CREATE POLICY "Users can delete own journal_entries"
    ON public.journal_entries FOR DELETE
    USING (user_id = auth.uid());

-- =============================================================================
-- POLÍTICAS PARA places
-- =============================================================================
DROP POLICY IF EXISTS "Users can view own places" ON public.places;
CREATE POLICY "Users can view own places"
    ON public.places FOR SELECT
    USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can insert own places" ON public.places;
CREATE POLICY "Users can insert own places"
    ON public.places FOR INSERT
    WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can update own places" ON public.places;
CREATE POLICY "Users can update own places"
    ON public.places FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can delete own places" ON public.places;
CREATE POLICY "Users can delete own places"
    ON public.places FOR DELETE
    USING (user_id = auth.uid());

-- =============================================================================
-- POLÍTICAS PARA payment_methods
-- =============================================================================
DROP POLICY IF EXISTS "Users can view own payment_methods" ON public.payment_methods;
CREATE POLICY "Users can view own payment_methods"
    ON public.payment_methods FOR SELECT
    USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can insert own payment_methods" ON public.payment_methods;
CREATE POLICY "Users can insert own payment_methods"
    ON public.payment_methods FOR INSERT
    WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can update own payment_methods" ON public.payment_methods;
CREATE POLICY "Users can update own payment_methods"
    ON public.payment_methods FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can delete own payment_methods" ON public.payment_methods;
CREATE POLICY "Users can delete own payment_methods"
    ON public.payment_methods FOR DELETE
    USING (user_id = auth.uid());

-- =============================================================================
-- POLÍTICAS PARA measurement_units
-- =============================================================================
DROP POLICY IF EXISTS "Users can view own measurement_units" ON public.measurement_units;
CREATE POLICY "Users can view own measurement_units"
    ON public.measurement_units FOR SELECT
    USING (
        user_id = auth.uid()
        OR is_system = true  -- Unidades del sistema visibles para todos
    );

DROP POLICY IF EXISTS "Users can insert own measurement_units" ON public.measurement_units;
CREATE POLICY "Users can insert own measurement_units"
    ON public.measurement_units FOR INSERT
    WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can update own measurement_units" ON public.measurement_units;
CREATE POLICY "Users can update own measurement_units"
    ON public.measurement_units FOR UPDATE
    USING (user_id = auth.uid() AND is_system = false)
    WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can delete own measurement_units" ON public.measurement_units;
CREATE POLICY "Users can delete own measurement_units"
    ON public.measurement_units FOR DELETE
    USING (user_id = auth.uid() AND is_system = false);

-- =============================================================================
-- FUNCIÓN PARA ASIGNAR user_id AUTOMÁTICAMENTE
-- =============================================================================
CREATE OR REPLACE FUNCTION set_user_id()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.user_id IS NULL THEN
        NEW.user_id = auth.uid();
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql' SECURITY DEFINER;

-- Aplicar trigger a todas las tablas con user_id
DO $$
DECLARE
    t TEXT;
BEGIN
    FOR t IN
        SELECT table_name
        FROM information_schema.columns
        WHERE column_name = 'user_id'
        AND table_schema = 'public'
    LOOP
        EXECUTE format('
            DROP TRIGGER IF EXISTS set_%I_user_id ON public.%I;
            CREATE TRIGGER set_%I_user_id
            BEFORE INSERT ON public.%I
            FOR EACH ROW EXECUTE FUNCTION set_user_id();
        ', t, t, t, t);
    END LOOP;
END;
$$ LANGUAGE plpgsql;
