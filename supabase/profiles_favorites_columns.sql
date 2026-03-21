-- ============================================
-- Add favorite columns to profiles table
-- Run this in Supabase SQL Editor after profiles_rls_policies.sql
-- ============================================

ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS favorite_team text,
ADD COLUMN IF NOT EXISTS favorite_driver text,
ADD COLUMN IF NOT EXISTS favorite_circuit text;
