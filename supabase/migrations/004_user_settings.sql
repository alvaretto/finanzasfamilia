-- Migration: User Settings Table
-- Description: Persistent user preferences synchronized across devices
-- Author: Claude Code
-- Date: 2026-01-13

-- ================================================================
-- 1. CREATE TABLE user_settings
-- ================================================================

CREATE TABLE user_settings (
  user_id TEXT PRIMARY KEY,
  theme_mode TEXT NOT NULL DEFAULT 'system', -- 'light', 'dark', 'system'
  onboarding_completed BOOLEAN NOT NULL DEFAULT FALSE,
  notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  budget_alerts_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  recurring_reminders_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  daily_reminder_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  daily_reminder_hour INTEGER NOT NULL DEFAULT 20,
  currency TEXT NOT NULL DEFAULT 'COP',
  date_format TEXT NOT NULL DEFAULT 'dd/MM/yyyy',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ================================================================
-- 2. CREATE INDEXES
-- ================================================================

-- Index on user_id for faster lookups (already covered by PRIMARY KEY)

-- ================================================================
-- 3. ROW LEVEL SECURITY (RLS)
-- ================================================================

ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only read their own settings
CREATE POLICY user_settings_select_policy ON user_settings
  FOR SELECT
  USING (auth.uid()::TEXT = user_id);

-- Policy: Users can only insert their own settings
CREATE POLICY user_settings_insert_policy ON user_settings
  FOR INSERT
  WITH CHECK (auth.uid()::TEXT = user_id);

-- Policy: Users can only update their own settings
CREATE POLICY user_settings_update_policy ON user_settings
  FOR UPDATE
  USING (auth.uid()::TEXT = user_id)
  WITH CHECK (auth.uid()::TEXT = user_id);

-- Policy: Users cannot delete settings (only update)
-- No DELETE policy means no user can delete settings

-- ================================================================
-- 4. TRIGGER FOR updated_at
-- ================================================================

CREATE OR REPLACE FUNCTION update_user_settings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER user_settings_updated_at_trigger
  BEFORE UPDATE ON user_settings
  FOR EACH ROW
  EXECUTE FUNCTION update_user_settings_updated_at();

-- ================================================================
-- 5. COMMENTS
-- ================================================================

COMMENT ON TABLE user_settings IS 'User preferences synchronized across devices';
COMMENT ON COLUMN user_settings.theme_mode IS 'Theme preference: light, dark, system';
COMMENT ON COLUMN user_settings.onboarding_completed IS 'Whether user has completed onboarding flow';
COMMENT ON COLUMN user_settings.notifications_enabled IS 'Master switch for all notifications';
COMMENT ON COLUMN user_settings.budget_alerts_enabled IS 'Enable budget threshold alerts';
COMMENT ON COLUMN user_settings.recurring_reminders_enabled IS 'Enable recurring transaction reminders';
COMMENT ON COLUMN user_settings.daily_reminder_enabled IS 'Enable daily summary notification';
COMMENT ON COLUMN user_settings.daily_reminder_hour IS 'Hour (0-23) for daily reminder';
COMMENT ON COLUMN user_settings.currency IS 'User preferred currency code (ISO 4217)';
COMMENT ON COLUMN user_settings.date_format IS 'User preferred date format pattern';
