-- ============================================
-- Check Printer Pro — Auto-Profile Trigger
-- Run AFTER setup_rbac.sql in Supabase SQL Editor
-- ============================================
-- This trigger auto-creates a user_profiles entry
-- when a new user signs up via the app.
-- The FIRST user ever becomes super_admin.
-- All subsequent users start as 'viewer'.
-- Domain whitelist is enforced in the frontend.
-- ============================================

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  user_count INTEGER;
  new_role TEXT;
BEGIN
  SELECT COUNT(*) INTO user_count FROM public.user_profiles;
  IF user_count = 0 THEN
    new_role := 'super_admin';
  ELSE
    new_role := 'viewer';
  END IF;
  INSERT INTO public.user_profiles (id, email, role, is_active)
  VALUES (NEW.id, NEW.email, new_role, true)
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger on auth.users insert
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();
