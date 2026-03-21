-- ============================================
-- RLS Policies for profiles table
-- Run this in Supabase SQL Editor
-- ============================================
-- Fix: "new row violates row-level security policy"
-- Users must be able to INSERT and UPDATE their own profile row.

-- 1. Ensure RLS is enabled
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- 2. Drop existing policies (if any) to avoid conflicts
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can read own profile" ON profiles;

-- 3. Policy: Users can INSERT their own profile (new signup / upsert)
CREATE POLICY "Users can insert own profile"
ON profiles FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

-- 4. Policy: Users can UPDATE their own profile (e.g. theme changes)
CREATE POLICY "Users can update own profile"
ON profiles FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- 5. Policy: Users can SELECT their own profile (e.g. initFromSupabase)
CREATE POLICY "Users can read own profile"
ON profiles FOR SELECT
TO authenticated
USING (auth.uid() = id);
