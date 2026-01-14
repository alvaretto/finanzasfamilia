-- =============================================================================
-- FINANZAS FAMILIARES - Tablas de Modo Familiar
-- Migración: 003_family_tables.sql
-- Descripción: Crea las tablas de familias, miembros, invitaciones y cuentas compartidas
-- =============================================================================

-- =============================================================================
-- TABLA: families
-- Grupos familiares que comparten finanzas
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.families (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL CHECK (length(name) >= 1 AND length(name) <= 100),
    description TEXT,
    icon TEXT CHECK (icon IS NULL OR length(icon) <= 10),
    color TEXT CHECK (color IS NULL OR length(color) <= 7),
    owner_id TEXT NOT NULL,
    invite_code TEXT CHECK (invite_code IS NULL OR (length(invite_code) >= 6 AND length(invite_code) <= 12)),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Campo para PowerSync RLS
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,

    -- El owner_id debe referenciar users pero Supabase Auth no permite FK directas
    CONSTRAINT unique_invite_code UNIQUE (invite_code)
);

-- Índices para families
CREATE INDEX IF NOT EXISTS idx_families_user_id ON public.families(user_id);
CREATE INDEX IF NOT EXISTS idx_families_owner_id ON public.families(owner_id);
CREATE INDEX IF NOT EXISTS idx_families_invite_code ON public.families(invite_code);
CREATE INDEX IF NOT EXISTS idx_families_is_active ON public.families(is_active);

-- =============================================================================
-- TABLA: family_members
-- Miembros de una familia con roles y permisos
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.family_members (
    id TEXT PRIMARY KEY,
    family_id TEXT NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL,
    user_email TEXT,
    display_name TEXT,
    avatar_url TEXT,
    role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('owner', 'admin', 'member', 'viewer')),
    is_active BOOLEAN NOT NULL DEFAULT true,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- user_id duplicado para PowerSync RLS (apunta al auth.users)
    -- El campo user_id de arriba es el ID del miembro, este es para RLS
    CONSTRAINT unique_family_user UNIQUE (family_id, user_id)
);

-- Índices para family_members
CREATE INDEX IF NOT EXISTS idx_family_members_family_id ON public.family_members(family_id);
CREATE INDEX IF NOT EXISTS idx_family_members_user_id ON public.family_members(user_id);
CREATE INDEX IF NOT EXISTS idx_family_members_is_active ON public.family_members(is_active);

-- =============================================================================
-- TABLA: family_invitations
-- Invitaciones pendientes a familias
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.family_invitations (
    id TEXT PRIMARY KEY,
    family_id TEXT NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
    invited_email TEXT NOT NULL,
    invited_by_user_id TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('admin', 'member', 'viewer')),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'expired', 'cancelled')),
    token TEXT NOT NULL UNIQUE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Campo para PowerSync RLS
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Índices para family_invitations
CREATE INDEX IF NOT EXISTS idx_family_invitations_family_id ON public.family_invitations(family_id);
CREATE INDEX IF NOT EXISTS idx_family_invitations_invited_email ON public.family_invitations(invited_email);
CREATE INDEX IF NOT EXISTS idx_family_invitations_token ON public.family_invitations(token);
CREATE INDEX IF NOT EXISTS idx_family_invitations_status ON public.family_invitations(status);
CREATE INDEX IF NOT EXISTS idx_family_invitations_user_id ON public.family_invitations(user_id);

-- =============================================================================
-- TABLA: shared_accounts
-- Cuentas compartidas en familias
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.shared_accounts (
    id TEXT PRIMARY KEY,
    family_id TEXT NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
    account_id TEXT NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
    owner_user_id TEXT NOT NULL,
    visible_to_all BOOLEAN NOT NULL DEFAULT true,
    members_can_transact BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Campo para PowerSync RLS
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,

    CONSTRAINT unique_family_account UNIQUE (family_id, account_id)
);

-- Índices para shared_accounts
CREATE INDEX IF NOT EXISTS idx_shared_accounts_family_id ON public.shared_accounts(family_id);
CREATE INDEX IF NOT EXISTS idx_shared_accounts_account_id ON public.shared_accounts(account_id);
CREATE INDEX IF NOT EXISTS idx_shared_accounts_owner_user_id ON public.shared_accounts(owner_user_id);
CREATE INDEX IF NOT EXISTS idx_shared_accounts_user_id ON public.shared_accounts(user_id);

-- =============================================================================
-- TRIGGERS: updated_at automático
-- =============================================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_families_updated_at BEFORE UPDATE ON public.families
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_family_members_updated_at BEFORE UPDATE ON public.family_members
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_family_invitations_updated_at BEFORE UPDATE ON public.family_invitations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
