-- Run in Supabase SQL Editor (or via migration).
-- Adds AI Strategist visibility toggles on public.profiles.
-- Defaults keep current behaviour (everything visible).

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS ai_strategist_disabled boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS ai_strategist_hide_teambattle boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS ai_strategist_hide_coach_corner boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS ai_strategist_hide_team_vibe boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN public.profiles.ai_strategist_disabled IS
  'When true, the AI Strategist card is hidden entirely on the Circuits home screen.';
COMMENT ON COLUMN public.profiles.ai_strategist_hide_teambattle IS
  'When true, hide the Teammate Battle section inside the AI Strategist card.';
COMMENT ON COLUMN public.profiles.ai_strategist_hide_coach_corner IS
  'When true, hide Coach''s Corner inside the AI Strategist card.';
COMMENT ON COLUMN public.profiles.ai_strategist_hide_team_vibe IS
  'When true, hide the Team Vibe / sentiment section inside the AI Strategist card.';

-- RLS: no change needed if you already allow users to UPDATE their own profile row
-- for other columns (e.g. favorite_team). The new columns are updated the same way.
-- If profiles are readable only by owner, ensure SELECT includes these columns (it will by default).
