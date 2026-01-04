-- Fix para Recursión Infinita en RLS de family_members
-- Ejecutar en: https://supabase.com/dashboard/project/gxezvqqbxgycmaqpgfpe/sql/new

-- PASO 1: Eliminar políticas recursivas actuales
DROP POLICY IF EXISTS "Family admins can manage members" ON family_members;
DROP POLICY IF EXISTS "Users can view members of their families" ON family_members;

-- PASO 2: Crear políticas simplificadas sin recursión

-- Política 1: Los usuarios pueden ver sus propios registros de membresía
CREATE POLICY "Users can view their own memberships"
  ON family_members
  FOR SELECT
  USING (user_id = auth.uid());

-- Política 2: Los usuarios pueden insertar registros solo para sí mismos
CREATE POLICY "Users can insert their own memberships"
  ON family_members
  FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- Política 3: Los usuarios pueden actualizar sus propios registros
CREATE POLICY "Users can update their own memberships"
  ON family_members
  FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Política 4: Los usuarios pueden eliminar sus propios registros
CREATE POLICY "Users can delete their own memberships"
  ON family_members
  FOR DELETE
  USING (user_id = auth.uid());

-- VERIFICACIÓN: Listar todas las políticas de family_members
SELECT
  policyname,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'family_members';
