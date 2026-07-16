-- ============================================
-- Check Printer Pro — RBAC Migration
-- Run AFTER setup.sql in Supabase → SQL Editor
-- ============================================

-- 1. User profiles with roles
CREATE TABLE user_profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  display_name TEXT,
  role TEXT NOT NULL DEFAULT 'viewer'
    CHECK (role IN ('super_admin', 'admin', 'printer', 'viewer')),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  created_by UUID REFERENCES auth.users(id)
);

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- 2. Helper function to check caller's role (SECURITY DEFINER = runs with owner privileges)
CREATE OR REPLACE FUNCTION get_my_role()
RETURNS TEXT AS $$
  SELECT COALESCE(
    (SELECT role FROM user_profiles WHERE id = auth.uid() AND is_active = true),
    'none'
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- 3. RLS policies for user_profiles
CREATE POLICY "Users read own profile"
  ON user_profiles FOR SELECT
  USING (id = auth.uid() OR get_my_role() = 'super_admin');

CREATE POLICY "Super admin inserts profiles"
  ON user_profiles FOR INSERT
  WITH CHECK (get_my_role() = 'super_admin');

CREATE POLICY "Super admin updates profiles"
  ON user_profiles FOR UPDATE
  USING (get_my_role() = 'super_admin');

CREATE POLICY "Super admin deletes profiles"
  ON user_profiles FOR DELETE
  USING (get_my_role() = 'super_admin');

-- 4. Update checks table policies for role-based access
--    (Drop old permissive policies, replace with role-aware ones)
DROP POLICY IF EXISTS "Users insert own checks" ON checks;
DROP POLICY IF EXISTS "Users update own checks" ON checks;
DROP POLICY IF EXISTS "Users delete own checks" ON checks;
-- SELECT stays unchanged: users see own checks

CREATE POLICY "Authorized users insert checks"
  ON checks FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND get_my_role() IN ('super_admin', 'admin', 'printer')
  );

CREATE POLICY "Authorized users update checks"
  ON checks FOR UPDATE
  USING (
    auth.uid() = user_id
    AND get_my_role() IN ('super_admin', 'admin', 'printer')
  );

CREATE POLICY "Authorized users delete checks"
  ON checks FOR DELETE
  USING (
    auth.uid() = user_id
    AND get_my_role() IN ('super_admin', 'admin')
  );

-- ============================================
-- 5. SEED YOUR ACCOUNT AS SUPER ADMIN
--    Replace the email below with YOUR exact Supabase login email
-- ============================================
INSERT INTO user_profiles (id, email, role, display_name)
SELECT id, email, 'super_admin', 'Miguel Guanche'
FROM auth.users
WHERE email = 'mguanche@sabercollege.edu';
