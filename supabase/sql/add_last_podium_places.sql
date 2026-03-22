-- Run in Supabase SQL Editor.
-- How many recent completed races (1–3) to show a "Last podium" card for on Circuits home (logged-in users).

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS last_podium_places smallint NOT NULL DEFAULT 3;

ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_last_podium_places_check;

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_last_podium_places_check
  CHECK (last_podium_places >= 1 AND last_podium_places <= 3);

COMMENT ON COLUMN public.profiles.last_podium_places IS
  'How many most recent completed GPs (1–3) get a podium summary card on Circuits home; default 3.';
