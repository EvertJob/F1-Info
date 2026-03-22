-- Run in Supabase SQL Editor.
-- Lets logged-in users hide placeholder “cancelled” races from the Circuits calendar.

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS hide_cancelled_calendar_races boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN public.profiles.hide_cancelled_calendar_races IS
  'When true, app hides Bahrain & Saudi Arabian GP rows from the 2026 calendar (logged-in users only).';
