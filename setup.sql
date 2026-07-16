-- ============================================
-- Check Printer Pro — Supabase Schema
-- Run this in Supabase → SQL Editor → New Query
-- ============================================

CREATE TABLE checks (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  check_number SERIAL,
  date DATE,
  pay_to TEXT,
  amount NUMERIC(12,2),
  amount_words TEXT,
  address TEXT,
  memo TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending','printed','voided')),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Row Level Security
ALTER TABLE checks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users see own checks"
  ON checks FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users insert own checks"
  ON checks FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users update own checks"
  ON checks FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users delete own checks"
  ON checks FOR DELETE USING (auth.uid() = user_id);

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER checks_updated_at
  BEFORE UPDATE ON checks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
